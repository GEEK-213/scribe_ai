import os
import time
from dotenv import load_dotenv
from supabase import create_client, Client
import google.generativeai as genai

# 1. Load Secrets
load_dotenv()
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")

# 2. Configure Services
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
genai.configure(api_key=GEMINI_API_KEY)

# Use Gemini 1.5 Flash (Fast & Cheap) or Pro (Smarter)
model = genai.GenerativeModel('gemini-flash-latest')

def download_audio(filename):
    print(f"⬇️  Downloading {filename} from Supabase...")
    try:
        # Download file from 'Lectures' bucket
        data = supabase.storage.from_("Lectures").download(filename)
        
        # Save it locally on your laptop so Python can use it
        local_path = f"temp_{filename}"
        with open(local_path, "wb") as f:
            f.write(data)
        return local_path
    except Exception as e:
        print(f"❌ Error downloading: {e}")
        return None

def analyze_audio(local_file_path):
    print("🧠 Sending audio to Gemini (this may take a moment)...")
    
    # Upload the file to Gemini's temp storage
    audio_file = genai.upload_file(path=local_file_path)
    
    # Wait for Gemini to process the audio file
    while audio_file.state.name == "PROCESSING":
        print('.', end='', flush=True)
        time.sleep(2)
        audio_file = genai.get_file(audio_file.name)

    # The Prompt: This is where we ask for the features from your Synopsis
    prompt = """
    Listen to this lecture audio carefully.
    1. **Transcription**: Write down the spoken text word-for-word.
    2. **Summary**: Provide a concise bullet-point summary of the key concepts.
    3. **Key Deadlines**: List any homework or exam dates mentioned.
    4. **Quiz**: Create 3 Multiple Choice Questions based on this content.
    """

    # Generate Content
    response = model.generate_content([prompt, audio_file])
    
    # Clean up (Delete file from Gemini cloud to save space)
    genai.delete_file(audio_file.name)
    
    return response.text

# --- MAIN EXECUTION ---
if __name__ == "__main__":
    # TODO: Replace this with the ACTUAL filename you see in your Supabase Dashboard
    # Example: "lecture_1708823.m4a"
    test_filename = "harvard.wav" 

    print("--- ScribeAI Brain Starting ---")
    
    # 1. Download
    local_path = download_audio(test_filename)
    
    if local_path:
        # 2. Analyze
        result = analyze_audio(local_path)
        
        print("\n\n" + "="*40)
        print("🤖 AI ANALYSIS RESULT:")
        print("="*40)
        print(result)
        
        # 3. Cleanup local file
        os.remove(local_path)