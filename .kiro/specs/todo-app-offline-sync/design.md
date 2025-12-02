# Design Document

## Overview

The TodoApp is a Flutter-based mobile application implementing an offline-first architecture with optional cloud synchronization. The system uses a three-tier architecture: a Flutter frontend with local SQLite storage, Firebase Authentication for Google OAuth, and a Node.js/Express backend with MongoDB for cloud data persistence. The application prioritizes offline functionality, ensuring all core features work without internet connectivity, while providing seamless synchronization when users authenticate and connect online.

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────┐
│         Flutter Mobile App              │
│  ┌───────────────────────────────────┐  │
│  │     Presentation Layer            │  │
│  │  (Widgets, Animations, UI/UX)     │  │
│  └───────────────┬───────────────────┘  │
│                  │                       │
│  ┌───────────────▼───────────────────┐  │
│  │     Business Logic Layer          │  │
│  │  (BLoC/Provider State Management) │  │
│  └───────┬───────────────┬───────────┘  │
│          │               │               │
│  ┌───────▼──────┐ ┌─────▼──────────┐   │
│  │ Local Storage│ │ Sync Manager   │   │
│  │   (SQLite)   │ │ (Queue/Merge)  │   │
│  └──────────────┘ └────────┬────────┘   │
└──────────────────────────────┼───────────┘
                               │
                    ┌──────────▼──────────┐
                    │  Firebase Auth      │
                    │  (Google OAuth)     │
                    └──────────┬──────────┘
                               │
                    ┌──────────▼──────────┐
                    │  Backend API        │
                    │  (Node.js/Express)  │
                    └──────────┬──────────┘
                               │
                    ┌──────────▼──────────┐
                    │  MongoDB Database   │
                    └─────────────────────┘
```

### Architectural Principles

1. **Offline-First**: All operations work locally first, sync happens asynchronously
2. **Single Source of Truth**: LocalStorage is the primary data source for the app
3. **Eventual Consistency**: Cloud sync resolves conflicts using last-write-wins with timestamps
4. **Separation of Concerns**: Clear boundaries between UI, business logic, and data layers
5. **Minimal Dependencies**: Keep app size small by using only essential packages

## Components and Interfaces

### Flutter Application Components

#### 1. Presentation Layer

**HomeScreen Widget**
- Displays task list with Material Design 3 styling
- Implements smooth scroll animations and list transitions
- Shows task cards with priority indicators and due date badges
- Provides swipe gestures for quick actions (complete, delete)

**TaskFormScreen Widget**
- Handles task creation and editing
- Provides input validation with real-time feedback
- Includes priority picker (1-5) and date picker for due dates
- Displays creative animations for form interactions

**AuthScreen Widget**
- Manages Google OAuth sign-in flow
- Displays authentication status and user profile
- Provides sign-out functionality

**SyncScreen Widget**
- Shows sync status and progress
- Displays conflict resolution options when needed
- Provides manual sync trigger

#### 2. Business Logic Layer (BLoC Pattern)

**TaskBloc**
```dart
class TaskBloc {
  // Events
  - AddTask(title, description, priority, dueDate)
  - UpdateTask(id, updates)
  - DeleteTask(id)
  - ToggleTaskCompletion(id)
  - LoadTasks()
  
  // States
  - TasksLoaded(tasks)
  - TasksLoading()
  - TaskError(message)
}
```

**AuthBloc**
```dart
class AuthBloc {
  // Events
  - SignInWithGoogle()
  - SignOut()
  - CheckAuthStatus()
  
  // States
  - Authenticated(user)
  - Unauthenticated()
  - AuthLoading()
  - AuthError(message)
}
```

**SyncBloc**
```dart
class SyncBloc {
  // Events
  - SyncToCloud()
  - SyncFromCloud()
  - ResolveSyncConflict(taskId, resolution)
  
  // States
  - SyncIdle()
  - SyncInProgress(progress)
  - SyncComplete()
  - SyncConflict(conflicts)
  - SyncError(message)
}
```

#### 3. Data Layer

**TaskRepository**
```dart
interface TaskRepository {
  Future<List<Task>> getAllTasks()
  Future<Task> getTaskById(String id)
  Future<void> createTask(Task task)
  Future<void> updateTask(Task task)
  Future<void> deleteTask(String id)
  Stream<List<Task>> watchTasks()
}
```

**LocalStorageService (SQLite)**
```dart
class LocalStorageService implements TaskRepository {
  // SQLite database operations
  // Table: tasks (id, title, description, priority, dueDate, completed, createdAt, updatedAt)
}
```

**CloudSyncService**
```dart
class CloudSyncService {
  Future<void> uploadTasks(List<Task> tasks, String authToken)
  Future<List<Task>> downloadTasks(String authToken)
  Future<List<Task>> mergeTasks(List<Task> local, List<Task> remote)
}
```

**NotificationService**
```dart
class NotificationService {
  Future<void> scheduleNotification(Task task)
  Future<void> cancelNotification(String taskId)
  Future<void> handleNotificationTap(String taskId)
}
```

### Backend Components (Node.js/Express)

#### API Endpoints

```
POST   /api/auth/verify          - Verify Firebase token
GET    /api/tasks                - Get all tasks for authenticated user
POST   /api/tasks/sync           - Sync tasks (upload/download)
PUT    /api/tasks/:id            - Update specific task
DELETE /api/tasks/:id            - Delete specific task
```

#### Middleware

- **authMiddleware**: Verifies Firebase JWT tokens
- **errorHandler**: Centralized error handling
- **rateLimiter**: Prevents API abuse

#### MongoDB Schema

```javascript
TaskSchema {
  _id: ObjectId,
  userId: String (Firebase UID),
  taskId: String (client-generated UUID),
  title: String,
  description: String,
  priority: Number (1-5),
  dueDate: Date,
  completed: Boolean,
  createdAt: Date,
  updatedAt: Date
}
```

## Data Models

### Task Model

```dart
class Task {
  final String id;              // UUID
  final String title;           // Required, non-empty
  final String? description;    // Optional
  final int priority;           // 1-5, default 3
  final DateTime? dueDate;      // Optional
  final bool completed;         // Default false
  final DateTime createdAt;     // Auto-generated
  final DateTime updatedAt;     // Auto-updated
  
  Task copyWith({...})
  Map<String, dynamic> toJson()
  factory Task.fromJson(Map<String, dynamic> json)
}
```

### User Model

```dart
class User {
  final String uid;             // Firebase UID
  final String email;
  final String? displayName;
  final String? photoUrl;
  
  Map<String, dynamic> toJson()
  factory User.fromJson(Map<String, dynamic> json)
}
```

### SyncQueueItem Model

```dart
class SyncQueueItem {
  final String taskId;
  final SyncOperation operation;  // CREATE, UPDATE, DELETE
  final DateTime timestamp;
  final Map<String, dynamic> data;
}
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Task creation increases local count
*For any* valid task with non-empty title, creating the task should increase the total task count in LocalStorage by exactly one.
**Validates: Requirements 1.1**

### Property 2: Empty title rejection preserves state
*For any* string composed entirely of whitespace or empty string, attempting to create a task with that title should be rejected and the task list should remain unchanged.
**Validates: Requirements 1.2, 4.5**

### Property 3: Task unique identifier assignment
*For any* created task, the TodoApp should assign a unique identifier that does not collide with any existing task identifier in LocalStorage.
**Validates: Requirements 1.4**

### Property 4: Priority level bounds validation
*For any* task creation or update, if a priority value outside the range 1-5 is provided, the TodoApp should either reject the operation or clamp the value to the valid range.
**Validates: Requirements 2.1**

### Property 5: Past due date rejection
*For any* due date set in the past (before current time), the TodoApp should reject the date and require a future date or no date.
**Validates: Requirements 2.3**

### Property 6: Task sorting consistency
*For any* list of tasks, the displayed order should always be sorted first by priority (5 to 1) and then by due date (earliest to latest), with this ordering remaining consistent across app restarts.
**Validates: Requirements 3.4**

### Property 7: Task update preserves identity
*For any* task update operation, the task ID should remain unchanged after the update, and only the specified fields should be modified.
**Validates: Requirements 4.2, 4.3, 4.4**

### Property 8: Completion toggle idempotence
*For any* task, toggling completion status twice should return the task to its original completion state.
**Validates: Requirements 5.1, 5.4**

### Property 9: Deletion removes task completely
*For any* task in LocalStorage, after deletion is confirmed, querying for that task by ID should return null or not found.
**Validates: Requirements 6.2**

### Property 10: Notification cancellation on completion
*For any* task with a scheduled notification, marking the task as completed should result in the notification being cancelled and not delivered.
**Validates: Requirements 5.5, 7.4**

### Property 11: Notification cancellation on deletion
*For any* task with a scheduled notification, deleting the task should result in the notification being cancelled and not delivered.
**Validates: Requirements 6.4, 7.4**

### Property 12: Authentication token persistence
*For any* successful authentication, the auth token should be stored securely and persist across app restarts until explicit sign-out.
**Validates: Requirements 8.2, 8.4**

### Property 13: Sync merge without duplicates
*For any* set of local tasks and remote tasks with overlapping IDs, merging should result in each unique task ID appearing exactly once in the final merged list.
**Validates: Requirements 9.4**

### Property 14: Conflict resolution preserves latest
*For any* sync conflict where the same task was modified on multiple devices, the version with the most recent updatedAt timestamp should be kept after resolution.
**Validates: Requirements 9.5**

### Property 15: Offline operation completeness
*For any* task operation (create, update, delete, toggle completion) performed while offline, the operation should complete successfully using LocalStorage without requiring network connectivity.
**Validates: Requirements 11.1, 11.2, 11.3**

### Property 16: Data persistence across restarts
*For any* task in LocalStorage, after the app is closed and reopened, the task should be retrievable with all fields identical to their values before the app was closed.
**Validates: Requirements 12.2, 12.3**

### Property 17: Sync queue ordering preservation
*For any* sequence of offline operations, when connectivity is restored and sync executes, the operations should be applied to the cloud in the same order they were performed locally.
**Validates: Requirements 11.4, 11.5**

## Error Handling

### Local Storage Errors

- **Database Connection Failure**: Retry with exponential backoff (3 attempts), then display error to user
- **Write Operation Failure**: Rollback transaction, notify user, and preserve previous state
- **Corruption Detection**: Attempt recovery from backup, or reset to empty state with user confirmation

### Network Errors

- **Authentication Failure**: Display specific error message (invalid credentials, network timeout, etc.)
- **Sync Failure**: Queue operations for retry, display sync status indicator
- **API Rate Limiting**: Implement exponential backoff, inform user of temporary unavailability

### Validation Errors

- **Invalid Input**: Display inline validation messages with clear guidance
- **Constraint Violations**: Prevent submission and highlight problematic fields
- **Date/Time Errors**: Provide date picker with valid range constraints

### Conflict Resolution

- **Sync Conflicts**: Present user with both versions, allow manual selection or auto-resolve with latest timestamp
- **Duplicate Detection**: Merge based on task ID, prefer version with most recent update

## Testing Strategy

### Unit Testing

The application will use the following unit testing approach:

**Framework**: Flutter's built-in `flutter_test` package

**Coverage Areas**:
- Task model serialization/deserialization (toJson/fromJson)
- Business logic in BLoCs (state transitions, event handling)
- Validation functions (empty title, priority bounds, past dates)
- Sync merge logic (duplicate detection, conflict resolution)
- Notification scheduling logic

**Example Unit Tests**:
- Test that Task.fromJson correctly parses valid JSON
- Test that empty title validation rejects whitespace-only strings
- Test that priority values outside 1-5 are handled correctly
- Test that sync merge removes duplicates based on task ID

### Property-Based Testing

The application will use property-based testing to verify universal correctness properties:

**Framework**: `faker` package for data generation + custom property test harness

**Configuration**: Each property test will run a minimum of 100 iterations with randomly generated inputs

**Test Tagging**: Each property-based test will include a comment in this format:
```dart
// Feature: todo-app-offline-sync, Property 1: Task creation increases local count
```

**Property Test Coverage**:
- Generate random valid tasks and verify creation increases count by 1
- Generate random whitespace strings and verify rejection
- Generate random task updates and verify ID preservation
- Generate random task lists and verify sorting consistency
- Generate random sync scenarios and verify merge correctness
- Generate random offline operation sequences and verify completion

### Integration Testing

**Framework**: `integration_test` package

**Test Scenarios**:
- End-to-end task lifecycle (create → edit → complete → delete)
- Authentication flow (sign in → sync → sign out)
- Offline-to-online transition with queued sync operations
- Notification delivery and tap handling

### UI/Animation Testing

**Framework**: `flutter_test` with golden tests

**Coverage**:
- Widget rendering correctness
- Animation smoothness (verify no jank)
- Responsive layout across different screen sizes
- Material Design 3 compliance

## Technology Stack

### Frontend (Flutter)

- **Framework**: Flutter 3.x (Dart)
- **State Management**: flutter_bloc (BLoC pattern)
- **Local Database**: sqflite (SQLite)
- **Authentication**: firebase_auth
- **Notifications**: flutter_local_notifications
- **HTTP Client**: dio (for API calls)
- **UUID Generation**: uuid package
- **Date Handling**: intl package
- **Animations**: Built-in Flutter animations + flutter_animate

### Backend (Node.js)

- **Runtime**: Node.js 18+ LTS
- **Framework**: Express.js
- **Database**: MongoDB with Mongoose ODM
- **Authentication**: firebase-admin (token verification)
- **Validation**: express-validator
- **Security**: helmet, cors
- **Environment**: dotenv

### Infrastructure

- **Authentication**: Firebase Authentication (Google OAuth)
- **Database**: MongoDB Atlas (free tier)
- **Hosting**: Backend can be deployed on free tier services (Render, Railway, or Fly.io)

## UI/UX Design Principles

### Material Design 3

- Use Material You dynamic color schemes
- Implement elevation and shadows for depth
- Apply consistent spacing (8dp grid system)
- Use typography scale for hierarchy

### Animation Guidelines

- **Duration**: 200-300ms for micro-interactions, 400-600ms for screen transitions
- **Curves**: Use easeInOut for natural motion
- **Types**:
  - Fade + Scale for task creation/deletion
  - Slide for screen transitions
  - Ripple for button presses
  - Shimmer for loading states
  - Confetti/celebration for task completion

### Color Scheme

- **Priority Indicators**:
  - Priority 5: Red (urgent)
  - Priority 4: Orange (high)
  - Priority 3: Yellow (medium)
  - Priority 2: Blue (low)
  - Priority 1: Gray (minimal)

### Accessibility

- Minimum touch target size: 48x48dp
- Color contrast ratio: 4.5:1 for text
- Screen reader support for all interactive elements
- Haptic feedback for important actions

## Performance Optimization

### App Size Reduction

- Use `--split-per-abi` flag for platform-specific builds
- Enable code shrinking and obfuscation
- Optimize images and assets (use vector graphics where possible)
- Lazy load non-critical features
- Target app size: < 15MB

### Runtime Performance

- Implement pagination for large task lists (50 items per page)
- Use `const` constructors for immutable widgets
- Debounce search/filter operations (300ms)
- Cache frequently accessed data
- Optimize database queries with proper indexing

### Battery Optimization

- Batch notification scheduling
- Use WorkManager for background sync (not continuous polling)
- Minimize wake locks
- Efficient animation frame rates (60fps target)

## Security Considerations

### Data Protection

- Encrypt sensitive data in SQLite using `sqflite_sqlcipher`
- Store auth tokens in secure storage (flutter_secure_storage)
- Never log sensitive information

### API Security

- Validate Firebase tokens on every backend request
- Implement rate limiting (100 requests per 15 minutes per user)
- Use HTTPS only for all network communication
- Sanitize all user inputs to prevent injection attacks

### Authentication

- Token expiration: 1 hour (refresh automatically)
- Secure token storage on device
- Logout clears all auth data

## Deployment Strategy

### Flutter App

1. Build release APK with code signing
2. Test on multiple Android versions (API 21+)
3. Optimize with R8 code shrinking
4. Generate app bundle for Play Store

### Backend

1. Deploy to free tier hosting (Render/Railway)
2. Configure environment variables
3. Set up MongoDB Atlas connection
4. Enable CORS for mobile app origin
5. Configure Firebase Admin SDK

### Monitoring

- Use Firebase Crashlytics for crash reporting
- Log sync errors for debugging
- Monitor API response times
- Track user engagement metrics (optional, privacy-respecting)
