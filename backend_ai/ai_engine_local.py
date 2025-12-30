import os
import time
import asyncio
import json
import re
from dotenv import load_dotenv
from supabase import create_client, Client
import ollama  # <--- The Local Hero
from PyPDF2 import PdfReader

# 1. SETUP
load_dotenv()
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# CONFIG: Choose your model (llama3.2 is fast, mistral is smart)
LOCAL_MODEL = "llama3.2" 

print(f"🦁 Lumen LOCAL Engine (Powered by {LOCAL_MODEL}) is Ready...")
print("⚠️  Warning: This runs on YOUR hardware. Speed depends on your GPU/CPU.")

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
            match = re.search(r'(\{.*\}|\[.*\])', text, re.DOTALL)
            if match: return json.loads(match.group())
        except: pass
    return []

def extract_block(full_text, tag_start, tag_end):
    if not full_text: return None
    try:
        parts = full_text.split(tag_start)
        if len(parts) < 2: return None 
        content = parts[1]
        if tag_end in content:
            content = content.split(tag_end)[0]
        return content.strip()
    except:
        return None

# --- CORE PROCESSES ---
async def process_new_uploads():
    """Handles file processing locally."""
    response = supabase.table('notes').select("*").eq('status', 'Processing').execute()
    if not response.data: return

    for note in response.data:
        print(f"📄 Processing Upload Locally: {note['audio_path']}") 
        temp_filename = f"temp_{note['id']}"
        
        try:
            # 1. Download
            try:
                data = supabase.storage.from_('Lectures').download(note['audio_path'])
            except:
                await asyncio.sleep(2)
                data = supabase.storage.from_('Lectures').download(note['audio_path'])
            
            ext = note['audio_path'].split('.')[-1].lower()
            temp_filename += f".{ext}"
            with open(temp_filename, "wb") as f: f.write(data)

            # 2. Extract Text (Local models can't hear audio directly easily yet)
            # We assume it's a PDF/Text for now. If audio, we need Whisper (later).
            text_content = ""
            if ext in ['pdf', 'txt']:
                text_content = extract_text_from_pdf(temp_filename)
            else:
                print("   ⚠️ Local Audio Transcribing requires Whisper (Skipping for now)")
                text_content = "Audio transcription not supported in simple local mode yet."

            # Limit text size (Local models have smaller memory)
            # Llama 3.2 can handle ~8k tokens. Truncating to ~20k chars to be safe.
            if len(text_content) > 20000:
                print("   ✂️ Text too long for local model, truncating...")
                text_content = text_content[:20000]

            # 3. Generate with Ollama
            prompt = f"""
            Analyze this academic content. Output specific blocks.
            1. SUMMARY: A concise bullet-point summary.
            2. QUIZ: 5 multiple-choice questions (JSON).
            3. FLASHCARDS: 5 definitions (JSON).
            4. MIND_MAP: A hierarchical JSON tree (root -> children).

            CONTENT:
            {text_content}

            OUTPUT FORMAT (Strict):
            SUMMARY_START
            [Text here]
            SUMMARY_END
            
            QUIZ_START
            [{{"question": "...", "options": ["A", "B"], "answer": "A"}}]
            QUIZ_END
            
            FLASHCARDS_START
            [{{"front": "Term", "back": "Definition"}}]
            FLASHCARDS_END

            MIND_MAP_START
            {{"id": "root", "label": "Main Topic", "children": []}}
            MIND_MAP_END
            """

            print("   🧠 Local Brain is Thinking... (This might take a minute)")
            
            # --- THE LOCAL CALL ---
            response = ollama.chat(model=LOCAL_MODEL, messages=[
                {'role': 'user', 'content': prompt},
            ])
            text = response['message']['content']
            # ----------------------

            # 4. Parse & Save
            summary = extract_block(text, "SUMMARY_START", "SUMMARY_END") or "Summary unavailable."
            q_json = clean_and_parse_json(extract_block(text, "QUIZ_START", "QUIZ_END"))
            f_json = clean_and_parse_json(extract_block(text, "FLASHCARDS_START", "FLASHCARDS_END"))
            mm_json = clean_and_parse_json(extract_block(text, "MIND_MAP_START", "MIND_MAP_END"))
            if not mm_json: mm_json = {}

            # Save Sub-Data
            if f_json:
                for c in f_json: 
                    supabase.table('flashcards').insert({'note_id': note['id'], 'front': c['front'], 'back': c['back']}).execute()
            
            # Final Update
            supabase.table('notes').update({
                "transcript": text_content, # We just use raw text for local
                "summary": summary, 
                "quiz": q_json, 
                "mind_map": mm_json,
                "status": "Done"
            }).eq("id", note['id']).execute()
            
            print("   ✅ Local Processing Complete!")

        except Exception as e:
            print(f"   ❌ Local Error: {e}")
            supabase.table('notes').update({"status": "Error"}).eq("id", note['id']).execute()
        
        finally:
            if os.path.exists(temp_filename): os.remove(temp_filename)

async def process_chat_queue():
    """Handles chat messages locally."""
    response = supabase.table('chat_messages').select("*").is_('response', 'null').execute()
    if not response.data: return

    for msg in response.data:
        print(f"💬 Local Chat: {msg['question']}")
        
        try:
            note = supabase.table('notes').select("transcript").eq("id", msg['note_id']).single().execute()
            if not note.data: continue
            
            context = note.data['transcript'][:5000] # Limit context for speed
            
            # --- THE LOCAL CALL ---
            response = ollama.chat(model=LOCAL_MODEL, messages=[
                {'role': 'system', 'content': f"Context: {context}"},
                {'role': 'user', 'content': msg['question']},
            ])
            answer = response['message']['content']
            # ----------------------

            supabase.table('chat_messages').update({"response": answer}).eq("id", msg['id']).execute()
            print("   ✅ Answer Sent!")

        except Exception as e:
            print(f"   ⚠️ Local Chat Error: {e}")

# --- MAIN LOOP ---
async def main_loop():
    while True:
        await asyncio.gather(process_new_uploads(), process_chat_queue())
        await asyncio.sleep(2)

if __name__ == "__main__":
    try:
        asyncio.run(main_loop())
    except KeyboardInterrupt:
        print("\n🔴 Local Engine Stopped.")