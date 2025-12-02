# Implementation Plan

- [x] 1. Set up Flutter project structure and dependencies
  - Initialize Flutter project with proper package name
  - Add required dependencies: flutter_bloc, sqflite, firebase_auth, firebase_core, flutter_local_notifications, dio, uuid, intl, flutter_animate
  - Configure Android manifest for notifications and internet permissions
  - Set up Firebase project and add configuration files (google-services.json)
  - Create folder structure: lib/models, lib/blocs, lib/repositories, lib/services, lib/screens, lib/widgets
  - _Requirements: 11.1, 12.1_

- [x] 2. Implement core data models
  - [x] 2.1 Create Task model with all fields
    - Implement Task class with id, title, description, priority, dueDate, completed, createdAt, updatedAt
    - Add toJson() and fromJson() methods for serialization
    - Implement copyWith() method for immutable updates
    - Add validation methods (isValidTitle, isValidPriority, isValidDueDate)
    - _Requirements: 1.1, 1.3, 2.1, 2.3_
  
  - [x] 2.2 Write property test for Task model serialization
    - **Property 1: Task serialization round-trip**
    - **Validates: Requirements 1.1, 1.3**
  
  - [x] 2.3 Create User model for authentication
    - Implement User class with uid, email, displayName, photoUrl
    - Add toJson() and fromJson() methods
    - _Requirements: 8.2_
  
  - [x] 2.4 Create SyncQueueItem model
    - Implement SyncQueueItem class with taskId, operation, timestamp, data
    - Add serialization methods
    - _Requirements: 11.4_

- [x] 3. Implement local storage service with SQLite
  - [x] 3.1 Create database helper and schema
    - Set up SQLite database with tasks table
    - Define schema: id TEXT PRIMARY KEY, title TEXT NOT NULL, description TEXT, priority INTEGER, dueDate INTEGER, completed INTEGER, createdAt INTEGER, updatedAt INTEGER
    - Implement database initialization and migration logic
    - Add indexes for priority and dueDate for efficient sorting
    - _Requirements: 1.1, 12.1_
  
  - [x] 3.2 Implement TaskRepository with CRUD operations
    - Create TaskRepository interface
    - Implement LocalStorageService class
    - Add methods: getAllTasks(), getTaskById(), createTask(), updateTask(), deleteTask()
    - Implement watchTasks() stream for reactive updates
    - _Requirements: 1.1, 4.2, 6.2, 12.2_
  
  - [x] 3.3 Write property test for task creation
    - **Property 2: Task creation increases local count**
    - **Validates: Requirements 1.1**
  
  - [x] 3.4 Write property test for unique ID assignment
    - **Property 3: Task unique identifier assignment**
    - **Validates: Requirements 1.4**
  
  - [x] 3.5 Write property test for data persistence
    - **Property 16: Data persistence across restarts**
    - **Validates: Requirements 12.2, 12.3**

- [x] 4. Implement input validation logic
  - [x] 4.1 Create validation utilities
    - Implement validateTitle() function to reject empty/whitespace strings
    - Implement validatePriority() function to enforce 1-5 range
    - Implement validateDueDate() function to reject past dates
    - Add error message constants for each validation type
    - _Requirements: 1.2, 2.1, 2.3, 4.5_
  
  - [x] 4.2 Write property test for empty title rejection
    - **Property 2: Empty title rejection preserves state**
    - **Validates: Requirements 1.2, 4.5**
  
  - [x] 4.3 Write property test for priority bounds
    - **Property 4: Priority level bounds validation**
    - **Validates: Requirements 2.1**
  
  - [x] 4.4 Write property test for past due date rejection
    - **Property 5: Past due date rejection**
    - **Validates: Requirements 2.3**

- [x] 5. Implement TaskBloc for state management
  - [x] 5.1 Define TaskBloc events and states
    - Create TaskEvent classes: AddTask, UpdateTask, DeleteTask, ToggleTaskCompletion, LoadTasks
    - Create TaskState classes: TasksLoading, TasksLoaded, TaskError
    - _Requirements: 1.1, 4.2, 5.1, 6.2_
  
  - [x] 5.2 Implement TaskBloc business logic
    - Handle AddTask event with validation and default values (priority=3, completed=false)
    - Handle UpdateTask event with field updates
    - Handle DeleteTask event with confirmation
    - Handle ToggleTaskCompletion event
    - Handle LoadTasks event with sorting (priority desc, dueDate asc)
    - Emit appropriate states for each operation
    - _Requirements: 1.1, 1.5, 2.4, 3.4, 4.2, 5.1, 6.2_
  
  - [x] 5.3 Write property test for default values
    - **Property related to default completion status and priority**
    - **Validates: Requirements 1.5, 2.4**
  
  - [x] 5.4 Write property test for task sorting
    - **Property 6: Task sorting consistency**
    - **Validates: Requirements 3.4**
  
  - [x] 5.5 Write property test for update preserves identity
    - **Property 7: Task update preserves identity**
    - **Validates: Requirements 4.2, 4.3, 4.4**
  
  - [x] 5.6 Write property test for completion toggle idempotence
    - **Property 8: Completion toggle idempotence**
    - **Validates: Requirements 5.1, 5.4**
  
  - [x] 5.7 Write property test for deletion removes task
    - **Property 9: Deletion removes task completely**
    - **Validates: Requirements 6.2**

- [x] 6. Implement notification service
  - [x] 6.1 Set up flutter_local_notifications
    - Initialize notification plugin with Android configuration
    - Request notification permissions
    - Set up notification channels
    - Configure notification tap handling
    - _Requirements: 7.1, 7.3_
  
  - [x] 6.2 Implement NotificationService class
    - Create scheduleNotification() method to schedule notifications for tasks with due dates within 24 hours
    - Create cancelNotification() method to cancel by task ID
    - Implement handleNotificationTap() to navigate to specific task
    - Add logic to schedule notification 1 hour before due date
    - _Requirements: 2.5, 7.1, 7.2, 7.3_
  
  - [x] 6.3 Integrate notifications with TaskBloc
    - Call scheduleNotification() when task with due date is created/updated
    - Call cancelNotification() when task is completed
    - Call cancelNotification() when task is deleted
    - _Requirements: 5.5, 6.4, 7.4_
  
  - [x] 6.4 Write property test for notification cancellation on completion
    - **Property 10: Notification cancellation on completion**
    - **Validates: Requirements 5.5, 7.4**
  
  - [x] 6.5 Write property test for notification cancellation on deletion
    - **Property 11: Notification cancellation on deletion**
    - **Validates: Requirements 6.4, 7.4**

- [x] 7. Implement Firebase authentication
  - [x] 7.1 Set up Firebase in Flutter app
    - Initialize Firebase in main.dart
    - Configure Firebase Authentication for Google Sign-In
    - Add google_sign_in package dependency
    - _Requirements: 8.1_
  
  - [x] 7.2 Create AuthBloc for authentication state
    - Define AuthEvent classes: SignInWithGoogle, SignOut, CheckAuthStatus
    - Define AuthState classes: Authenticated, Unauthenticated, AuthLoading, AuthError
    - _Requirements: 8.1, 8.5_
  
  - [x] 7.3 Implement authentication logic
    - Implement signInWithGoogle() using Firebase Auth and Google Sign-In
    - Implement signOut() to clear auth state
    - Implement checkAuthStatus() to verify token on app start
    - Store auth token securely using flutter_secure_storage
    - _Requirements: 8.1, 8.2, 8.4, 8.5_
  
  - [x] 7.4 Write property test for token persistence
    - **Property 12: Authentication token persistence**
    - **Validates: Requirements 8.2, 8.4**

- [x] 8. Implement cloud sync functionality
  - [x] 8.1 Create CloudSyncService class
    - Implement uploadTasks() method using dio to POST tasks to backend
    - Implement downloadTasks() method to GET tasks from backend
    - Implement mergeTasks() method to combine local and remote tasks
    - Add conflict resolution logic (keep version with latest updatedAt)
    - Handle duplicate detection by task ID
    - _Requirements: 9.2, 9.4, 9.5_
  
  - [x] 8.2 Create SyncBloc for sync state management
    - Define SyncEvent classes: SyncToCloud, SyncFromCloud, ResolveSyncConflict
    - Define SyncState classes: SyncIdle, SyncInProgress, SyncComplete, SyncConflict, SyncError
    - Implement sync logic with progress tracking
    - _Requirements: 9.1, 9.2, 9.3_
  
  - [x] 8.3 Implement sync queue for offline operations
    - Create SyncQueueService to store operations when offline
    - Add operations to queue when authenticated but offline
    - Implement automatic queue processing when connectivity restored
    - Ensure operations execute in order
    - _Requirements: 11.4, 11.5_
  
  - [x] 8.4 Write property test for sync merge without duplicates
    - **Property 13: Sync merge without duplicates**
    - **Validates: Requirements 9.4**
  
  - [x] 8.5 Write property test for conflict resolution
    - **Property 14: Conflict resolution preserves latest**
    - **Validates: Requirements 9.5**
  
  - [x] 8.6 Write property test for sync queue ordering
    - **Property 17: Sync queue ordering preservation**
    - **Validates: Requirements 11.4, 11.5**

- [x] 9. Build UI screens and widgets
  - [x] 9.1 Create HomeScreen with task list
    - Build AppBar with title and sync/auth buttons
    - Implement task list using ListView.builder
    - Display task cards with title, description preview, priority indicator, due date badge
    - Show completion status with checkbox
    - Implement swipe-to-delete and swipe-to-complete gestures
    - Add FloatingActionButton for creating new tasks
    - Display empty state when no tasks exist
    - _Requirements: 3.1, 3.2, 3.3, 5.1, 6.1_
  
  - [x] 9.2 Create TaskFormScreen for create/edit
    - Build form with TextFormFields for title and description
    - Add priority selector (1-5) with visual indicators
    - Add date picker for due date
    - Implement real-time validation with error messages
    - Add save and cancel buttons
    - Show loading state during save
    - _Requirements: 1.1, 1.2, 2.1, 2.2, 4.1, 4.5_
  
  - [x] 9.3 Create AuthScreen for sign-in
    - Display app branding and welcome message
    - Add "Sign in with Google" button
    - Show loading state during authentication
    - Display error messages if auth fails
    - _Requirements: 8.1, 8.3_
  
  - [x] 9.4 Create SyncScreen for sync management
    - Display sync status (last synced time, pending operations)
    - Add manual sync button
    - Show sync progress indicator
    - Display conflict resolution UI when conflicts occur
    - Show sync history/log
    - _Requirements: 9.1, 9.3_

- [x] 10. Implement animations and UI polish
  - [x] 10.1 Add task list animations
    - Implement fade + scale animation for task creation
    - Add slide animation for task deletion
    - Create confetti/celebration animation for task completion
    - Add shimmer loading animation for initial load
    - Implement smooth list reordering animations
    - _Requirements: 3.5, 5.2, 6.3, 10.1_
  
  - [x] 10.2 Add screen transition animations
    - Implement hero animations for task cards to detail screen
    - Add slide transitions between screens
    - Create engaging splash screen animation
    - _Requirements: 10.1, 10.4_
  
  - [x] 10.3 Apply Material Design 3 theming
    - Set up dynamic color scheme
    - Configure typography scale
    - Apply elevation and shadows
    - Implement priority color indicators (red, orange, yellow, blue, gray)
    - Ensure 48x48dp minimum touch targets
    - Add haptic feedback for important actions
    - _Requirements: 10.2, 10.3_

- [x] 11. Implement offline-first functionality
  - [x] 11.1 Add connectivity monitoring
    - Integrate connectivity_plus package
    - Monitor network status changes
    - Update UI to show offline/online indicator
    - _Requirements: 11.3, 11.5_
  
  - [x] 11.2 Ensure all operations work offline
    - Test task creation, editing, deletion offline
    - Verify completion toggle works offline
    - Ensure task list loads from local storage when offline
    - _Requirements: 11.1, 11.2, 11.3_
  
  - [x] 11.3 Write property test for offline operation completeness
    - **Property 15: Offline operation completeness**
    - **Validates: Requirements 11.1, 11.2, 11.3**

- [x] 12. Build Node.js backend API
  - [x] 12.1 Set up Express server
    - Initialize Node.js project with Express
    - Add dependencies: express, mongoose, firebase-admin, cors, helmet, dotenv, express-validator
    - Configure environment variables
    - Set up MongoDB connection using Mongoose
    - Configure CORS for mobile app
    - Add security middleware (helmet)
    - _Requirements: 9.2_
  
  - [x] 12.2 Implement authentication middleware
    - Set up Firebase Admin SDK
    - Create authMiddleware to verify Firebase tokens
    - Extract user ID from verified token
    - Handle authentication errors
    - _Requirements: 8.1, 8.2_
  
  - [x] 12.3 Create Task schema and model
    - Define Mongoose schema with all task fields plus userId
    - Add indexes for userId, priority, dueDate
    - Add timestamps (createdAt, updatedAt)
    - _Requirements: 9.2_
  
  - [x] 12.4 Implement API endpoints
    - POST /api/auth/verify - Verify Firebase token
    - GET /api/tasks - Get all tasks for authenticated user
    - POST /api/tasks/sync - Sync tasks (upload/download)
    - PUT /api/tasks/:id - Update specific task
    - DELETE /api/tasks/:id - Delete specific task
    - Add input validation using express-validator
    - Implement error handling middleware
    - _Requirements: 9.2, 9.3_
  
  - [x] 12.5 Add rate limiting
    - Implement rate limiting (100 requests per 15 minutes per user)
    - Add rate limit headers to responses
    - _Requirements: 9.2_
  
  - [x] 12.6 Write unit tests for backend endpoints
    - Test authentication middleware
    - Test task CRUD operations
    - Test sync endpoint with merge logic
    - Test error handling

- [x] 13. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 14. Integrate all components and test end-to-end flows
  - [x] 14.1 Wire up BLoCs with UI
    - Provide TaskBloc, AuthBloc, SyncBloc at app root
    - Connect HomeScreen to TaskBloc
    - Connect TaskFormScreen to TaskBloc
    - Connect AuthScreen to AuthBloc
    - Connect SyncScreen to SyncBloc
    - _Requirements: All_
  
  - [x] 14.2 Implement navigation and routing
    - Set up named routes for all screens
    - Implement navigation from notifications to specific tasks
    - Add back button handling
    - _Requirements: 7.3_
  
  - [x] 14.3 Test complete user flows
    - Test guest user flow: create → edit → complete → delete tasks
    - Test authenticated user flow: sign in → sync → sign out
    - Test offline-to-online transition with sync
    - Test notification delivery and tap handling
    - _Requirements: All_

- [x] 15. Optimize performance and app size
  - [x] 15.1 Optimize build configuration
    - Enable code shrinking and obfuscation in build.gradle
    - Use --split-per-abi flag for release builds
    - Optimize images and use vector graphics
    - Remove unused resources
    - _Requirements: 10.5_
  
  - [x] 15.2 Implement performance optimizations
    - Add pagination for large task lists (50 items per page)
    - Use const constructors for immutable widgets
    - Optimize database queries with proper indexes
    - Implement debouncing for search/filter (300ms)
    - _Requirements: 10.5_
  
  - [x] 15.3 Test app size and performance
    - Build release APK and verify size < 15MB
    - Test on multiple Android versions (API 21+)
    - Verify 60fps animation performance
    - Test battery usage
    - _Requirements: 10.5_

- [x] 16. Deploy backend and finalize app
  - [x] 16.1 Deploy backend to hosting service
    - Set up MongoDB Atlas free tier
    - Deploy Express server to Render/Railway/Fly.io free tier
    - Configure environment variables in hosting service
    - Test API endpoints from deployed URL
    - _Requirements: 9.2_
  
  - [x] 16.2 Update Flutter app with production backend URL
    - Replace localhost URLs with production API URL
    - Test authentication and sync with production backend
    - _Requirements: 9.2_
  
  - [x] 16.3 Build release APK
    - Generate signing key
    - Configure signing in build.gradle
    - Build release APK with code signing
    - Test release build on physical device
    - _Requirements: All_
  
  - [x] 16.4 Set up crash reporting
    - Integrate Firebase Crashlytics
    - Test crash reporting
    - _Requirements: All_

- [x] 17. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.
