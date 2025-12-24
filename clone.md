git clone [https://github.com/your-username/scribe_ai.git](https://github.com/your-username/scribe_ai.git)
cd scribe_ai
flutter pub get
cd backend_ai
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install google-generativeai supabase python-dotenv
SUPABASE_URL=your_supabase_url
SUPABASE_KEY=your_supabase_service_role_key  # Use Service Role for backend!
GOOGLE_API_KEY=your_gemini_api_key
python backend_ai/ai_engine.py
flutter run
