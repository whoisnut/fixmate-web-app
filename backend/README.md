Backend Run Commands

Development (auto reload):
cd /Users/user/fixmate/backend && source /Users/user/fixmate/backend/venv/bin/activate && uvicorn app.main:app --reload

Production-style local run:
cd /Users/user/fixmate/backend && source /Users/user/fixmate/backend/venv/bin/activate && uvicorn app.main:app --host 0.0.0.0 --port 8000

Demo account:
demo.login@fixmate.dev / Pass1234