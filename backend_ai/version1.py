import os
import time
import json
from dotenv import load_dotenv
from supabase import create_client, Client
import google.generativeai as genai

# --- CONFIGURATION ---
load_dotenv()
gemini_key = os.getenv("GEMINI_API_KEY")
supabase_url = os.getenv("SUPABASE_URL")
supabase_key = os.getenv("SUPABASE_KEY")

# Force Set Keys
os.environ["GOOGLE_API_KEY"] = gemini_key
genai.configure(api_key=gemini_key)

# Connect to Services
supabase: Client = create_client(supabase_url, supabase_key)
model = genai.GenerativeModel('gemini-flash-latest') # Using the stable model

def process_lecture(note):
    print(f"\n🚀 Processing Note ID: {note['id']} ({note['audio_path']})")
    
    # 1. Download Audio
    try:
        data = supabase.storage.from_("Lectures").download(note['audio_path'])
        local_path = f"temp_{note['audio_path']}"
        with open(local_path, "wb") as f:
            f.write(data)
        print("   ✅ Audio Downloaded")
    except Exception as e:
        print(f"   ❌ Download Error: {e}")
        return

    # 2. Send to Gemini
    print("   🧠 Analyzing with AI...")
    try:
        audio_file = genai.upload_file(path=local_path)
        while audio_file.state.name == "PROCESSING":
            time.sleep(1)
            audio_file = genai.get_file(audio_file.name)

        # The Prompt: Ask for JSON so we can easily save it
        prompt = """
        Analyze this lecture. Return the result in valid JSON format with these fields:
        {
            "transcript": "Full word-for-word text...",
            "summary": "Key bullet points...",
            "quiz": [
                {"question": "...", "options": ["A", "B", "C", "D"], "answer": "A"}
            ],
            "glossary": "List of hard words and definitions..."
        }
        """
        response = model.generate_content([prompt, audio_file], generation_config={"response_mime_type": "application/json"})
        
        # 3. Parse and Save to DB
        ai_data = json.loads(response.text)
        
        supabase.table("notes").update({
            "transcript": ai_data.get("transcript"),
            "summary": ai_data.get("summary"),
            "quiz": ai_data.get("quiz"),
            "glossary": ai_data.get("glossary"),
            "status": "Done"  # <--- Mark as Done!
        }).eq("id", note['id']).execute()

        print("   ✅ Database Updated!")
        
        # Cleanup
        genai.delete_file(audio_file.name)
        os.remove(local_path)

    except Exception as e:
        print(f"   ❌ AI Error: {e}")
        supabase.table("notes").update({"status": "Error"}).eq("id", note['id']).execute()

# --- MAIN LOOP ---
print("--- ScribeAI Brain is Listening ---")
while True:
    try:
        # Ask DB: "Give me 1 row where status is 'Processing'"
        response = supabase.table("notes").select("*").eq("status", "Processing").limit(1).execute()
        
        if response.data and len(response.data) > 0:
            # Found work!
            process_lecture(response.data[0])
        else:
            # No work, wait 5 seconds
            print(".", end="", flush=True)
            time.sleep(5)
            
    except Exception as e:
        print(f"Loop Error: {e}")
        time.sleep(5)