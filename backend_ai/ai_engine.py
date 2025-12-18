import os
import time
import asyncio
import json
from dotenv import load_dotenv
from supabase import create_client, Client
import google.generativeai as genai
from PyPDF2 import PdfReader 

# 1. SETUP
load_dotenv()
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")
GEMINI_KEY = os.getenv("GEMINI_API_KEY")

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
genai.configure(api_key=GEMINI_KEY)
model = genai.GenerativeModel("gemini-2.5-flash") 

print("🟢 AI Engine V3 (Multi-Modal + Chat) is Ready...")

def extract_text_from_pdf(file_path):
    """Helper to read text from PDF files"""
    try:
        reader = PdfReader(file_path)
        text = ""
        for page in reader.pages:
            text += page.extract_text() + "\n"
        return text
    except Exception as e:
        return f"Error reading PDF: {e}"

async def process_new_uploads():
    """Listens for new files (Audio OR PDF) to process."""
    # Fetch 'Processing' notes
    response = supabase.table('notes').select("*").eq('status', 'Processing').execute()
    notes = response.data

    for note in notes:
        print(f"📄 Found new upload: {note['audio_path']}") # 'audio_path' stores filename for both
        try:
            # 1. Download File (Audio or PDF)
            file_path = note['audio_path']
            data = supabase.storage.from_('Lectures').download(file_path) # Changed bucket to lowercase 'Lectures' if needed
            
            # Determine extension
            ext = file_path.split('.')[-1].lower()
            temp_filename = f"temp_{note['id']}.{ext}"
            
            with open(temp_filename, "wb") as f:
                f.write(data)

            # 2. Prepare Input for Gemini
            gemini_inputs = []
            print("   Thinking...")

            # --- BRANCH: PDF HANDLING ---
            if ext in ['pdf', 'txt']:
                print("   (Processing as Document)")
                extracted_text = extract_text_from_pdf(temp_filename)
                
                # We feed the text directly to the prompt
                gemini_inputs = [extracted_text]
                
                # Modified prompt for Text
                base_prompt = """
                You are an expert tutor analyzing this document.
                1. FORMAT the text inside TRANSCRIPT_START and TRANSCRIPT_END.
                2. Create a Summary with bullet points.
                3. Generate a Quiz with 5 questions in JSON format.
                """

            # --- BRANCH: AUDIO HANDLING ---
            else:
                print("   (Processing as Audio)")
                audio_file = genai.upload_file(temp_filename)
                
                # Wait for audio processing
                while audio_file.state.name == "PROCESSING":
                    await asyncio.sleep(1) # Async sleep to not block chat
                    audio_file = genai.get_file(audio_file.name)
                
                gemini_inputs = [audio_file]
                
                # Modified prompt for Audio
                base_prompt = """
                You are an expert tutor listening to this audio.
                1. Generate a clear Transcript.
                2. Create a Summary with bullet points.
                3. Generate a Quiz with 5 questions in JSON format.
                """

            # 3. Unified Output Instructions (Keep Parser Happy)
            final_prompt = base_prompt + """
            Output format (STRICTLY FOLLOW THIS):
            TRANSCRIPT_START
            [The Full Text or Transcript Here]
            TRANSCRIPT_END
            SUMMARY_START
            [Bullet points here]
            SUMMARY_END
            QUIZ_START
            [{"question": "...", "options": ["A", "B", "C", "D"], "answer": "Option A"}]
            QUIZ_END
            """
            
            # Add prompt to inputs
            gemini_inputs.insert(0, final_prompt)

            # 4. Generate Content
            result = model.generate_content(gemini_inputs)
            text = result.text

            # 5. Parse Response (Same logic for both!)
            transcript = text.split("TRANSCRIPT_START")[1].split("TRANSCRIPT_END")[0].strip()
            summary = text.split("SUMMARY_START")[1].split("SUMMARY_END")[0].strip()
            
            raw_quiz = text.split("QUIZ_START")[1].split("QUIZ_END")[0].strip()
            raw_quiz = raw_quiz.replace("```json", "").replace("```", "").strip()
            quiz_json = json.loads(raw_quiz)

            # 6. Save to DB
            supabase.table('notes').update({
                "transcript": transcript,
                "summary": summary,
                "quiz": quiz_json,
                "status": "Done"
            }).eq("id", note['id']).execute()

            print("   ✅ Note Processed Successfully!")
            
            # Cleanup
            if os.path.exists(temp_filename):
                os.remove(temp_filename)

        except Exception as e:
            print(f"   ❌ Error: {e}")
            supabase.table('notes').update({"status": "Error"}).eq("id", note['id']).execute()
            # Cleanup on error too
            if os.path.exists(temp_filename):
                os.remove(temp_filename)

async def process_chat_queue():
    """Listens for new chat questions."""
    try:
        response = supabase.table('chat_messages').select("*").is_('response', 'null').execute()
        messages = response.data

        for msg in messages:
            print(f"💬 Chat Question: {msg['question']}")
            
            # Get Context
            note_response = supabase.table('notes').select("transcript").eq("id", msg['note_id']).execute()
            if not note_response.data:
                continue
                
            transcript = note_response.data[0]['transcript']

            # Ask Gemini
            prompt = f"""
            Context: {transcript[:20000]} 
            Question: {msg['question']}
            Answer the question based ONLY on the context. Keep it short and helpful.
            """
            
            ai_response = model.generate_content(prompt).text

            # Save Answer
            supabase.table('chat_messages').update({
                "response": ai_response
            }).eq("id", msg['id']).execute()
            
            print("   ✅ Answer Sent!")
            
    except Exception as e:
        print(f"   ⚠️ Chat Error: {e}")

async def main_loop():
    while True:
        await process_new_uploads()
        await process_chat_queue()
        await asyncio.sleep(2)

if __name__ == "__main__":
    asyncio.run(main_loop())