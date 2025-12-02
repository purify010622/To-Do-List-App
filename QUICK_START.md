# Quick Start Guide 🚀

## Before You Push to GitHub

### ⚠️ CRITICAL STEP: Delete Sensitive File

You have a Firebase service account key file that must be deleted:

```bash
del backend\todolist-409ad-firebase-adminsdk-fbsvc-a6384e4726.json
```

This file contains your private key and should NEVER be on GitHub!

## Setup for Development

### 1. Backend Setup

```bash
cd backend
npm install

# Create your .env file
copy .env.example .env

# Edit .env with your actual credentials:
# - MongoDB connection string
# - Firebase credentials
# - CORS origins

npm run dev
```

### 2. Flutter App Setup

```bash
cd todo_app_offline_sync
flutter pub get
flutter run
```

## Push to GitHub

### First Time Setup

```bash
# Initialize git
git init

# Add all files
git add .

# Verify no sensitive files are included
git status

# Commit
git commit -m "Initial commit: Todo app with offline sync"

# Create repository on GitHub, then:
git remote add origin https://github.com/YOUR_USERNAME/todo-app.git
git branch -M main
git push -u origin main
```

### Verify Before Pushing

Run this command to check for sensitive data:

```bash
# On Windows CMD
findstr /s /i "kashish pandeykashish" *.*

# Should return NO results in tracked files
```

## What's Been Done

✅ Created root `.gitignore` to exclude sensitive files
✅ Updated `backend/.gitignore` to exclude Firebase keys
✅ Updated `backend/.env.example` with placeholders
✅ Fixed `backend/test-connection.js` to use environment variables
✅ Created comprehensive documentation
✅ Added GitHub Actions workflows
✅ Created SECURITY.md with guidelines

## Next Steps

1. Delete the Firebase service account JSON file
2. Verify `.gitignore` is working
3. Push to GitHub
4. Set up MongoDB Atlas (if not done)
5. Deploy backend to Render/Railway/Fly.io
6. Build Flutter app

## Documentation

- [README.md](README.md) - Project overview
- [SECURITY.md](SECURITY.md) - Security guidelines
- [CONTRIBUTING.md](CONTRIBUTING.md) - How to contribute
- [GITHUB_READY_CHECKLIST.md](GITHUB_READY_CHECKLIST.md) - Complete checklist
- [backend/DEPLOYMENT_GUIDE.md](backend/DEPLOYMENT_GUIDE.md) - Backend deployment
- [DEPLOYMENT_SUMMARY.md](DEPLOYMENT_SUMMARY.md) - Full deployment overview

## Need Help?

Check the documentation files or open an issue on GitHub (never include secrets in issues!).
