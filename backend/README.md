Backend Run Commands

Development (auto reload):
cd /Users/user/fixmate/backend && source /Users/user/fixmate/backend/venv/bin/activate && uvicorn app.main:app --reload

Production-style local run:
cd /Users/user/fixmate/backend && source /Users/user/fixmate/backend/venv/bin/activate && uvicorn app.main:app --host 0.0.0.0 --port 8000

Demo Accounts:

Admin (for category & service management):
Email: admin@fixmate.dev
Password: Admin1234

Customer: 
Email: demo.login@fixmate.dev
Password: Pass1234

Technician: 
Email: demo.tech@fixmate.dev
Password: Pass1234