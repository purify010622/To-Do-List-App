# Todo App with Offline Sync

A full-stack todo application with offline-first architecture, built with Flutter (mobile) and Node.js/Express (backend).

## 🚀 Features

- ✅ Offline-first architecture with local SQLite storage
- ✅ Real-time sync with cloud backend
- ✅ Firebase authentication
- ✅ Push notifications for task reminders
- ✅ Cross-platform (Android, iOS)
- ✅ Material Design UI
- ✅ BLoC state management

## 📁 Project Structure

```
todo-app/
├── backend/                    # Node.js/Express API
│   ├── src/                   # Source code
│   ├── __tests__/             # Backend tests
│   ├── .env.example           # Environment template
│   └── README.md              # Backend documentation
│
└── todo_app_offline_sync/     # Flutter mobile app
    ├── lib/                   # Dart source code
    ├── test/                  # Unit tests
    ├── integration_test/      # Integration tests
    └── README.md              # Flutter app documentation
```

## 🛠️ Tech Stack

### Backend
- Node.js + Express
- MongoDB Atlas (database)
- Firebase Admin SDK (authentication)
- Mongoose (ODM)

### Mobile App
- Flutter 3.x
- Dart
- SQLite (local storage)
- BLoC (state management)
- Firebase Auth

## 📋 Prerequisites

- Node.js 18+ (for backend)
- Flutter SDK 3.x+ (for mobile app)
- MongoDB Atlas account (free tier)
- Firebase project
- Android Studio / Xcode (for mobile development)

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/YOUR_USERNAME/todo-app.git
cd todo-app
```

### 2. Backend Setup

```bash
cd backend
npm install

# Create .env file from template
copy .env.example .env

# Edit .env with your credentials
# - MongoDB connection string
# - Firebase credentials
# - CORS origins

# Start development server
npm run dev
```

See [backend/README.md](backend/README.md) for detailed setup instructions.

### 3. Flutter App Setup

```bash
cd todo_app_offline_sync
flutter pub get

# Run on connected device/emulator
flutter run
```

See [todo_app_offline_sync/README.md](todo_app_offline_sync/README.md) for detailed setup instructions.

## 🔐 Security

**IMPORTANT:** Never commit sensitive credentials to version control.

- All secrets should be in `.env` files (which are gitignored)
- See [SECURITY.md](SECURITY.md) for security guidelines
- Use `.env.example` as a template

## 📚 Documentation

- [Backend Deployment Guide](backend/DEPLOYMENT_GUIDE.md)
- [MongoDB Atlas Setup](backend/MONGODB_ATLAS_SETUP.md)
- [Flutter Production Deployment](todo_app_offline_sync/PRODUCTION_DEPLOYMENT.md)
- [Release Build Checklist](todo_app_offline_sync/RELEASE_BUILD_CHECKLIST.md)
- [Deployment Summary](DEPLOYMENT_SUMMARY.md)

## 🧪 Testing

### Backend Tests
```bash
cd backend
npm test
```

### Flutter Tests
```bash
cd todo_app_offline_sync
flutter test                    # Unit tests
flutter test integration_test/  # Integration tests
```

## 🚀 Deployment

### Backend
Deploy to Render, Railway, or Fly.io (free tiers available)
- See [backend/DEPLOYMENT_GUIDE.md](backend/DEPLOYMENT_GUIDE.md)

### Mobile App
Build release APK for Android
- See [todo_app_offline_sync/RELEASE_BUILD_CHECKLIST.md](todo_app_offline_sync/RELEASE_BUILD_CHECKLIST.md)

## 📝 Environment Variables

### Backend (.env)
```
PORT=3000
NODE_ENV=development
MONGODB_URI=your_mongodb_connection_string
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_PRIVATE_KEY=your_private_key
FIREBASE_CLIENT_EMAIL=your_client_email
ALLOWED_ORIGINS=http://localhost:*,capacitor://localhost
```

### Flutter (lib/config/app_config.dart)
```dart
static const Environment environment = Environment.development;
static String get apiBaseUrl => 'http://localhost:3000/api';
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🐛 Known Issues

- See GitHub Issues for current bugs and feature requests

## 📞 Support

For questions or issues:
- Open a GitHub Issue
- Check documentation in `/docs` folder
- Review troubleshooting sections in deployment guides

## ✨ Acknowledgments

- Flutter team for the amazing framework
- Firebase for authentication and cloud services
- MongoDB Atlas for database hosting

---

**Made with ❤️ using Flutter and Node.js**
