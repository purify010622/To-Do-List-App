<div align="center">

# 📝 CodSoft ToDoList App

### Offline-First Task Management with Cloud Sync

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.38.3-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase" />
  <img src="https://img.shields.io/badge/Node.js-339933?style=for-the-badge&logo=nodedotjs&logoColor=white" alt="Node.js" />
  <img src="https://img.shields.io/badge/MongoDB-47A248?style=for-the-badge&logo=mongodb&logoColor=white" alt="MongoDB" />
</p>

<p align="center">
  <strong>A powerful, production-ready task management app built with Flutter & Node.js</strong>
</p>

<p align="center">
  <a href="#-features">Features</a> •
  <a href="#-quick-start">Quick Start</a> •
  <a href="#-setup-guide">Setup Guide</a> •
  <a href="#-building">Building</a> •
  <a href="#-troubleshooting">Troubleshooting</a>
</p>

</div>

---

## 📸 Demo

> 🎥 **Demo video coming soon on LinkedIn!**
> 
> Follow [@sarthak-yerpude](https://linkedin.com/in/sarthak-yerpude) for updates

---

## ✨ Features

<table>
<tr>
<td width="50%">

### 🎯 Core Features
- ✅ **Offline-First** - Works without internet
- � **Claoud Sync** - Automatic synchronization
- 🔐 **Firebase Auth** - Secure Google Sign-In
- 🔔 **Notifications** - Due date reminders
- 📱 **Material Design** - Beautiful UI
- 🎨 **Priority Levels** - 5 color-coded priorities

</td>
<td width="50%">

### 🚀 Advanced
- 📊 **Full CRUD** - Create, edit, delete, complete
- 💾 **SQLite Storage** - Local database
- 🔍 **Conflict Resolution** - Smart sync merging
- 📈 **Crashlytics** - Error tracking
- 🎭 **Animations** - Smooth transitions
- 🌐 **RESTful API** - Node.js backend

</td>
</tr>
</table>

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Flutter App (Mobile)                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │   UI Layer   │  │  BLoC Layer  │  │ Data Layer   │  │
│  │  (Screens)   │→ │  (Business)  │→ │(Repositories)│  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
│         ↓                  ↓                  ↓          │
│  ┌──────────────────────────────────────────────────┐  │
│  │         Local Storage (SQLite) + Sync Queue      │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
                            ↕ HTTP/REST
┌─────────────────────────────────────────────────────────┐
│                   Backend (Node.js/Express)              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │   Routes     │→ │ Controllers  │→ │   Models     │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
│         ↓                                      ↓          │
│  ┌──────────────┐                  ┌──────────────┐    │
│  │   Firebase   │                  │   MongoDB    │    │
│  │    Auth      │                  │    Atlas     │    │
│  └──────────────┘                  └──────────────┘    │
└─────────────────────────────────────────────────────────┘
```

---

## 🛠️ Tech Stack

**Frontend:** Flutter 3.38.3 • BLoC Pattern • SQLite • Firebase Auth • Dio • flutter_animate

**Backend:** Node.js • Express.js • MongoDB Atlas • Firebase Admin SDK • express-validator

---

## � Prere quisites

Before starting, install:

- ✅ [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.38.3+)
- ✅ [Node.js](https://nodejs.org/) (16.x+)
- ✅ [Android Studio](https://developer.android.com/studio) or [VS Code](https://code.visualstudio.com/)
- ✅ [Git](https://git-scm.com/)

You'll also need accounts for:
- ✅ [Firebase](https://console.firebase.google.com/)
- ✅ [MongoDB Atlas](https://www.mongodb.com/cloud/atlas)

---

## 🚀 Quick Start

### 1️⃣ Clone Repository

```bash
git clone https://github.com/yerpudesarthak1221-source/codsoft-todolist-app.git
cd codsoft-todolist-app
```

---

## 📱 Complete Setup Guide

### Part 1: Firebase Setup (5 minutes)

#### Step 1: Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Add project"** → Name it `CodSoft-TodoList`
3. Disable Google Analytics (optional) → Click **"Create project"**

#### Step 2: Enable Authentication
1. Go to **Authentication** → Click **"Get started"**
2. Enable **"Google"** sign-in method
3. Add your email as test user → Click **"Save"**

#### Step 3: Add Android App
1. Click **"Add app"** → Select **Android**
2. Package name: `com.todoapp.todo_app_offline_sync`
3. Download `google-services.json`
4. Place it in: `todo_app_offline_sync/android/app/`

#### Step 4: Enable Crashlytics
1. Go to **Crashlytics** → Click **"Enable Crashlytics"**

#### Step 5: Get Admin SDK
1. Go to **Project Settings** → **Service Accounts**
2. Click **"Generate new private key"** → Save the JSON file

---

### Part 2: MongoDB Setup (3 minutes)

#### Step 1: Create Cluster
1. Go to [MongoDB Atlas](https://www.mongodb.com/cloud/atlas)
2. Click **"Build a Database"** → Choose **"FREE"** tier (M0)
3. Select a region → Click **"Create"**

#### Step 2: Create Database User
1. Go to **Database Access** → Click **"Add New Database User"**
2. Username: `todoapp_user`
3. Generate a strong password → **Save it!**
4. **Important:** Set privileges to **"Read and write to any database"**
5. Click **"Add User"**

#### Step 3: Allow Network Access
1. Go to **Network Access** → Click **"Add IP Address"**
2. Click **"Allow Access from Anywhere"** (for development)
3. Click **"Confirm"**

#### Step 4: Get Connection String
1. Go to **Database** → Click **"Connect"**
2. Choose **"Connect your application"**
3. Copy the connection string
4. Replace `<password>` with your database user password

---

### Part 3: Backend Setup (3 minutes)

```bash
cd backend

# Install dependencies
npm install

# Create environment file
cp .env.example .env
```

#### Edit `.env` file:

```env
PORT=3000
NODE_ENV=development

# MongoDB Atlas connection string
MONGODB_URI=mongodb+srv://todoapp_user:YOUR_PASSWORD@cluster.mongodb.net/todoDB

# Firebase credentials (from Admin SDK JSON)
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@your-project.iam.gserviceaccount.com

# CORS
ALLOWED_ORIGINS=http://localhost:*,capacitor://localhost,ionic://localhost
```

**Get Firebase credentials from the Admin SDK JSON:**
- `project_id` → `FIREBASE_PROJECT_ID`
- `private_key` → `FIREBASE_PRIVATE_KEY`
- `client_email` → `FIREBASE_CLIENT_EMAIL`

#### Start Backend:

```bash
npm run dev
```

✅ You should see: `Server running on port 3000`

---

### Part 4: Flutter App Setup (4 minutes)

```bash
cd todo_app_offline_sync

# Install dependencies
flutter pub get
```

#### Configure API URL

Edit `lib/config/app_config.dart`:

**For Android Emulator:**
```dart
class AppConfig {
  static const Environment environment = Environment.development;
  
  static String get apiBaseUrl {
    switch (environment) {
      case Environment.development:
        return 'http://10.0.2.2:3000/api'; // Emulator
      case Environment.production:
        return 'https://your-backend.com/api';
    }
  }
}
```

**For Physical Device:**
1. Find your computer's IP:
   ```bash
   ipconfig  # Windows
   ifconfig  # Mac/Linux
   ```
2. Update URL:
   ```dart
   return 'http://192.168.1.X:3000/api'; // Replace X with your IP
   ```

#### Run the App:

```bash
# Launch emulator
flutter emulators --launch <emulator_name>

# Or connect physical device via USB

# Run app
flutter run
```

---

## ✅ Verification Checklist

Test these features:

- [ ] App launches successfully
- [ ] Can sign in with Google
- [ ] Can create a task
- [ ] Can edit a task (tap on task)
- [ ] Can delete a task (edit task → scroll down → Delete button)
- [ ] Can mark task as complete
- [ ] Can see user name (tap account icon in top right)
- [ ] Sync works (Sync Management → Upload to Cloud)

---

## 📦 Building for Production

### Generate Signing Key (One-time)

```bash
keytool -genkey -v -keystore C:\Users\YOUR_NAME\upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Save the password securely!

### Create `android/key.properties`:

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=C:\\Users\\YOUR_NAME\\upload-keystore.jks
```

### Build Release APK:

```bash
cd todo_app_offline_sync

# Build optimized APKs
flutter build apk --split-per-abi --release

# APKs location: build/app/outputs/flutter-apk/
# - app-armeabi-v7a-release.apk (18.6 MB) - Older devices
# - app-arm64-v8a-release.apk (20.8 MB) - Modern devices ⭐
# - app-x86_64-release.apk (22.2 MB) - Emulators
```

### Install on Device:

```bash
# Via ADB
adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk

# Or copy APK to phone and install manually
```

---

## 🌐 Backend Deployment

### Deploy to Render (Recommended)

1. Go to [Render](https://render.com/)
2. Create **New Web Service**
3. Connect your GitHub repository
4. Configure:
   - **Build Command:** `cd backend && npm install`
   - **Start Command:** `cd backend && npm start`
5. Add Environment Variables (from your `.env`)
6. Click **"Create Web Service"**

### Update App with Production URL

Edit `lib/config/app_config.dart`:

```dart
case Environment.production:
  return 'https://your-app.onrender.com/api';
```

Rebuild the app and you're live! 🎉

---

## 🐛 Troubleshooting

### ❌ "App can't connect to backend"

**Solutions:**
- ✅ Check backend is running: `npm run dev`
- ✅ Verify API URL in `app_config.dart`
- ✅ For emulator: Use `10.0.2.2` not `localhost`
- ✅ For device: Use computer's local IP (e.g., `192.168.1.5`)
- ✅ Check firewall isn't blocking port 3000

### ❌ "Sync fails: user is not allowed to do action [insert]"

**Solution:**
1. Go to MongoDB Atlas
2. **Database Access** → Edit your user
3. Change role to **"Read and write to any database"**
4. Wait 1-2 minutes for changes to apply

### ❌ "Firebase authentication failed"

**Solutions:**
- ✅ Verify `google-services.json` is in `android/app/`
- ✅ Check Google Sign-In is enabled in Firebase Console
- ✅ For release builds, add SHA-1 fingerprint to Firebase

### ❌ "Build failed"

**Solutions:**
```bash
flutter clean
flutter pub get
flutter run
```

### ❌ "Error loading tasks" or "Failed to add task"

**Solutions:**
- ✅ Run `flutter clean`
- ✅ Delete app from device/emulator
- ✅ Rebuild: `flutter run`

---

## 📱 How to Use the App

### Creating Tasks
1. Tap the **+** button
2. Enter title and description
3. Set priority (1-5)
4. Set due date (optional)
5. Tap **"Create"**

### Editing Tasks
1. Tap on any task
2. Modify details
3. Tap **"Save"**

### Deleting Tasks
1. Tap on a task to edit
2. Scroll down
3. Tap **"Delete Task"** button
4. Confirm deletion

### Syncing
1. Tap the sync icon (top right)
2. Go to **Sync Management**
3. Tap **"Upload to Cloud"** or **"Download from Cloud"**

### Viewing Profile
1. Tap the account icon (top right)
2. See your name and email
3. Tap **"Sign Out"** to logout

---

## 🗂️ Project Structure

```
codsoft-todolist-app/
├── backend/                    # Node.js Backend
│   ├── src/
│   │   ├── config/            # Configuration
│   │   ├── middleware/        # Auth & validation
│   │   ├── models/            # MongoDB schemas
│   │   ├── routes/            # API endpoints
│   │   └── server.js          # Entry point
│   ├── .env.example           # Environment template
│   └── package.json
│
├── todo_app_offline_sync/     # Flutter App
│   ├── lib/
│   │   ├── blocs/             # State management
│   │   ├── models/            # Data models
│   │   ├── repositories/      # Data layer
│   │   ├── screens/           # UI screens
│   │   ├── services/          # Business logic
│   │   ├── config/            # Configuration
│   │   └── main.dart          # Entry point
│   ├── android/               # Android config
│   └── pubspec.yaml           # Dependencies
│
└── README.md                  # This file
```

---

## 🎯 Key Features Explained

### Offline-First Architecture
- All tasks stored locally in SQLite
- Works completely without internet
- Changes queued when offline
- Auto-sync when connection restored
- Smart conflict resolution

### Cloud Synchronization
- Manual sync via Sync Management
- Automatic background sync
- Upload local changes
- Download remote changes
- "Last write wins" conflict resolution

### Smart Notifications
- Reminders 1 hour before due date
- Only for tasks due within 24 hours
- Tap notification to open task
- Timezone-aware

### Security
- Firebase Authentication
- Secure token management
- Environment-based configuration
- No hardcoded credentials
- ProGuard code obfuscation

---

## 🧪 Testing

### Run Tests

```bash
# Flutter tests
cd todo_app_offline_sync
flutter test

# Backend tests
cd backend
npm test
```

---

## 🤝 Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create feature branch: `git checkout -b feature/AmazingFeature`
3. Commit changes: `git commit -m 'Add AmazingFeature'`
4. Push to branch: `git push origin feature/AmazingFeature`
5. Open a Pull Request

### Code Style
- **Flutter:** Follow [Effective Dart](https://dart.dev/guides/language/effective-dart)
- **Node.js:** Use ES6+ features
- Run `flutter format` before committing
- Use meaningful commit messages

---

## 📊 Project Stats

- **Total Lines of Code:** ~15,000+
- **Flutter Packages:** 20+ dependencies
- **API Endpoints:** 6 routes
- **Screens:** 5 main screens
- **Development Time:** 4-6 weeks
- **APK Size:** 18-22 MB (optimized)

---

## 🎓 What I Learned

### Technical Skills
- Flutter framework & BLoC pattern
- RESTful API design
- MongoDB database design
- Firebase integration
- Offline-first architecture
- Release build configuration
- Code signing & ProGuard

### Best Practices
- Clean architecture
- Error handling
- State management
- API integration
- Security practices
- Documentation

---

## 🔮 Future Enhancements

- [ ] Task categories/tags
- [ ] Task search & filter
- [ ] Recurring tasks
- [ ] Task sharing
- [ ] Dark mode
- [ ] Multiple themes
- [ ] Task attachments
- [ ] Voice input
- [ ] Widget support
- [ ] iOS version

---

## 📄 License

This project is open source and available for educational purposes.

---

## 👨‍💻 Author

**sarthak yerpude**

- GitHub: [@yerpudesarthak1221-source](https://github.com/yerpudesarthak1221-source)
- LinkedIn: [Demo coming soon!](https://linkedin.com/in/sarthak-yerpude)

---

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for authentication and crashlytics
- MongoDB for the database
- Node.js and Express.js communities
- All open-source contributors

---

## 📞 Support

Need help?

- 🐛 [Open an issue](https://github.com/yerpudesarthak1221-source/codsoft-todolist-app/issues)
- 📧 Contact via GitHub profile
- 💬 Check existing issues for solutions

---

<div align="center">

### ⭐ Star this repo if you find it helpful!

**Built with ❤️ for CodSoft Internship**

*Demonstrating modern mobile app development practices*

Made with Flutter • Node.js • MongoDB • Firebase

</div>
