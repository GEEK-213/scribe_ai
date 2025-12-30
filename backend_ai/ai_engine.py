import os
import time
import asyncio
import json
import re
from dotenv import load_dotenv
from supabase import create_client, Client
import google.generativeai as genai
from PyPDF2 import PdfReader

# 1. SETUP
load_dotenv()
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")
GEMINI_KEY = os.getenv("GEMINI_API_KEY")

if not GEMINI_KEY:
    print("❌ ERROR: GEMINI_API_KEY is missing from .env file!")
    exit()

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
genai.configure(api_key=GEMINI_KEY)
model = genai.GenerativeModel("gemini-2.5-flash") 

print("🟢 Lumen AI Engine V5 (Mind Maps + Speakers) is Ready...")

# --- HELPER FUNCTIONS ---
def extract_text_from_pdf(file_path):
    try:
        reader = PdfReader(file_path)
        text = ""
        for page in reader.pages:
            text += page.extract_text() + "\n"
        return text
    except Exception as e:
        return f"Error reading PDF: {e}"

def clean_and_parse_json(raw_text):
    if not raw_text: return []
    text = raw_text.replace("```json", "").replace("```", "").strip()
    try:
        return json.loads(text)
    except:
        try:
            # Try to find the first JSON-like structure (Array or Object)
            match = re.search(r'(\{.*\}|\[.*\])', text, re.DOTALL)
            if match: return json.loads(match.group())
        except: pass
    return []

# --- CORE PROCESSES ---
async def process_new_uploads():
    """Handles heavy file processing with Mind Map & Speaker logic."""
    response = supabase.table('notes').select("*").eq('status', 'Processing').execute()
    if not response.data: return

    for note in response.data:
        print(f"📄 Processing Upload: {note['audio_path']}") 
        temp_filename = f"temp_{note['id']}"
        
        try:
            # 1. Download
            try:
                data = supabase.storage.from_('Lectures').download(note['audio_path'])
            except:
                data = supabase.storage.from_('Lectures').download(note['audio_path'])
            
            ext = note['audio_path'].split('.')[-1].lower()
            temp_filename += f".{ext}"
            with open(temp_filename, "wb") as f: f.write(data)

            # 2. Prepare Gemini Input
            gemini_inputs = []
            
            # --- UPDATED PROMPT FOR V5 ---
            prompt = """
            You are an expert academic tutor. Analyze the provided content.
            
            1. TRANSCRIPT: Convert audio to text. IMPORTANT: Label speakers as "Speaker A:", "Speaker B:" if multiple voices are heard.
            2. SUMMARY: Create a concise bullet-point summary.
            3. QUIZ: Generate 5 multiple-choice questions.
            4. FLASHCARDS: Identify 5-10 key terms and their definitions.
            5. TASKS: Extract any homework/deadlines (e.g. "Assignment due Friday").
            6. MIND_MAP: Generate a hierarchical JSON tree representing the topic structure.

            Output format (Strict JSON blocks):
            TRANSCRIPT_START
            [Transcript text with Speaker Labels]
            TRANSCRIPT_END
            
            SUMMARY_START
            [Summary text]
            SUMMARY_END
            
            QUIZ_START
            [{"question": "...", "options": ["A", "B"], "answer": "A"}]
            QUIZ_END
            
            FLASHCARDS_START
            [{"front": "Term", "back": "Definition"}]
            FLASHCARDS_END
            
            TASKS_START
            [{"title": "Task", "due_date": "2025-01-01"}]
            TASKS_END

            MIND_MAP_START
            {"id": "root", "label": "Main Topic", "children": [{"id": "1", "label": "Subtopic", "children": []}]}
            MIND_MAP_END
            """

            if ext in ['pdf', 'txt']:
                text_content = extract_text_from_pdf(temp_filename)
                gemini_inputs = [prompt, text_content]
            else:
                audio_file = genai.upload_file(temp_filename)
                while audio_file.state.name == "PROCESSING":
                    await asyncio.sleep(1)
                    audio_file = genai.get_file(audio_file.name)
                gemini_inputs = [prompt, audio_file]

            # 3. Generate (With Retry)
            text = ""
            for attempt in range(3):
                try:
                    result = model.generate_content(gemini_inputs)
                    text = result.text
                    break
                except Exception as e:
                    if "429" in str(e):
                        print(f"   ⏳ Upload Rate Limit. Waiting 20s... (Attempt {attempt+1}/3)")
                        await asyncio.sleep(20)
                    else: raise e

            # 4. Parse Data
            def extract_block(tag_start, tag_end):
                try: return text.split(tag_start)[1].split(tag_end)[0].strip()
                except: return None

            transcript = extract_block("TRANSCRIPT_START", "TRANSCRIPT_END") or "No transcript."
            summary = extract_block("SUMMARY_START", "SUMMARY_END") or "No summary."

            q_json = clean_and_parse_json(extract_block("QUIZ_START", "QUIZ_END"))
            f_json = clean_and_parse_json(extract_block("FLASHCARDS_START", "FLASHCARDS_END"))
            t_json = clean_and_parse_json(extract_block("TASKS_START", "TASKS_END"))
            
            # NEW: Mind Map Parsing
            mm_json = clean_and_parse_json(extract_block("MIND_MAP_START", "MIND_MAP_END"))
            if not mm_json: mm_json = {} # Safe fallback

            # Save Sub-Data
            for c in f_json: supabase.table('flashcards').insert({'note_id': note['id'], 'front': c['front'], 'back': c['back']}).execute()
            for t in t_json: supabase.table('study_tasks').insert({'user_id': note['user_id'], 'title': t['title'], 'due_date': t.get('due_date'), 'origin_note_id': note['id']}).execute()

            # Final Update (With Mind Map!)
            supabase.table('notes').update({
                "transcript": transcript, 
                "summary": summary, 
                "quiz": q_json, 
                "mind_map": mm_json, # <--- The New Feature
                "status": "Done"
            }).eq("id", note['id']).execute()
            
            print("   ✅ Upload Processed (with Mind Map)!")

        except Exception as e:
            print(f"   ❌ Upload Error: {e}")
            supabase.table('notes').update({"status": "Error"}).eq("id", note['id']).execute()
        
        finally:
            if os.path.exists(temp_filename): os.remove(temp_filename)

async def process_chat_queue():
    """Handles chat messages."""
    response = supabase.table('chat_messages').select("*").is_('response', 'null').execute()
    if not response.data: return

    for msg in response.data:
        print(f"💬 Chatting: {msg['question']}")
        
        try:
            # 1. Get Context
            note = supabase.table('notes').select("transcript").eq("id", msg['note_id']).single().execute()
            if not note.data: continue
            
            transcript = note.data['transcript']
            prompt = f"Context: {transcript[:15000]}\nStudent Question: {msg['question']}\n\nAnswer cleanly and concisely:"

            # 2. Generate Answer
            answer = ""
            for attempt in range(3):
                try:
                    result = model.generate_content(prompt)
                    answer = result.text
                    break
                except Exception as e:
                    if "429" in str(e):
                        await asyncio.sleep(5)
                    else: raise e
            
            if not answer: answer = "I'm having trouble connecting to the AI right now."

            # 3. Send Answer
            supabase.table('chat_messages').update({"response": answer}).eq("id", msg['id']).execute()
            print("   ✅ Answer Sent!")

        except Exception as e:
            print(f"   ⚠️ Chat Error: {e}")

# --- MAIN LOOP ---
async def main_loop():
    while True:
        await asyncio.gather(process_new_uploads(), process_chat_queue())
        await asyncio.sleep(1)

if __name__ == "__main__":
    asyncio.run(main_loop())