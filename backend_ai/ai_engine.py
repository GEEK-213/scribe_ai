import os
import time
import asyncio
from dotenv import load_dotenv
from supabase import create_client, Client
import google.generativeai as genai

# 1. SETUP
load_dotenv()
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")
GEMINI_KEY = os.getenv("GEMINI_API_KEY")

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
genai.configure(api_key=GEMINI_KEY)
model = genai.GenerativeModel("gemini-2.5-flash")

print("🟢 AI Engine V2 (Tutor Mode) is Ready...")

async def process_new_uploads():
    """Listens for new audio files to transcribe."""
    response = supabase.table('notes').select("*").eq('status', 'Processing').execute()
    notes = response.data

    for note in notes:
        print(f"🎤 Found new audio: {note['audio_path']}")
        try:
            # 1. Download Audio
            audio_data = supabase.storage.from_('lectures').download(note['audio_path'])
            temp_filename = f"temp_{note['id']}.mp3"
            with open(temp_filename, "wb") as f:
                f.write(audio_data)

            # 2. Transcribe & Summarize (Gemini)
            print("   Thinking...")
            audio_file = genai.upload_file(temp_filename)
            
            # Wait for processing
            while audio_file.state.name == "PROCESSING":
                time.sleep(1)
                audio_file = genai.get_file(audio_file.name)

            prompt = """
            You are an expert tutor. 
            1. Generate a clear Transcript.
            2. Create a Summary with bullet points.
            3. Generate a Quiz with 5 questions in JSON format: 
               [{"question": "...", "options": ["A", "B", "C", "D"], "answer": "Option A"}]
            Output format: 
            TRANSCRIPT_START
            ...
            TRANSCRIPT_END
            SUMMARY_START
            ...
            SUMMARY_END
            QUIZ_START
            ...
            QUIZ_END
            """
            result = model.generate_content([prompt, audio_file])
            text = result.text

            # 3. Parse Response
            transcript = text.split("TRANSCRIPT_START")[1].split("TRANSCRIPT_END")[0].strip()
            summary = text.split("SUMMARY_START")[1].split("SUMMARY_END")[0].strip()
            import json
            raw_quiz = text.split("QUIZ_START")[1].split("QUIZ_END")[0].strip()
            # Clean up json string if needed (remove ```json marks)
            raw_quiz = raw_quiz.replace("```json", "").replace("```", "").strip()
            quiz_json = json.loads(raw_quiz)

            # 4. Save to DB
            supabase.table('notes').update({
                "transcript": transcript,
                "summary": summary,
                "quiz": quiz_json,
                "status": "Done"
            }).eq("id", note['id']).execute()

            print(" Note Processed!")
            
            # Cleanup
            os.remove(temp_filename)

        except Exception as e:
            print(f" Error: {e}")
            supabase.table('notes').update({"status": "Error"}).eq("id", note['id']).execute()

async def process_chat_queue():
    """Listens for new chat questions."""
    # Find messages where response is NULL
    response = supabase.table('chat_messages').select("*").is_('response', 'null').execute()
    messages = response.data

    for msg in messages:
        print(f"💬 New Question: {msg['question']}")
        try:
            # 1. Get the Context (Transcript) from the Note
            note_response = supabase.table('notes').select("transcript").eq("id", msg['note_id']).execute()
            if not note_response.data:
                print("   Note not found!")
                continue
                
            transcript = note_response.data[0]['transcript']

            # 2. Ask Gemini
            prompt = f"""
            Context (Lecture Transcript):
            {transcript}

            Student Question: {msg['question']}

            Task: Answer the question based ONLY on the transcript above. 
            If the answer isn't in the transcript, say "I couldn't find that in the lecture."
            Keep it simple and encouraging.
            """
            
            ai_response = model.generate_content(prompt).text

            # 3. Save Answer
            supabase.table('chat_messages').update({
                "response": ai_response
            }).eq("id", msg['id']).execute()
            
            print("    Answer Sent!")

        except Exception as e:
            print(f" Chat Error: {e}")

async def main_loop():
    while True:
        await process_new_uploads()
        await process_chat_queue()
        time.sleep(2)

if __name__ == "__main__":
    asyncio.run(main_loop())