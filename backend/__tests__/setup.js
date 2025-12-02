// Test setup and teardown
const mongoose = require('mongoose');

// Mock Firebase Admin
jest.mock('firebase-admin', () => {
  const mockAuth = {
    verifyIdToken: jest.fn(),
  };

  return {
    apps: [],
    initializeApp: jest.fn(),
    credential: {
      cert: jest.fn(),
    },
    auth: jest.fn(() => mockAuth),
  };
});

// Set test environment variables
process.env.NODE_ENV = 'test';
process.env.MONGODB_URI = 'mongodb://localhost:27017/todo-app-test';
process.env.FIREBASE_PROJECT_ID = 'test-project';
process.env.FIREBASE_PRIVATE_KEY = 'test-key';
process.env.FIREBASE_CLIENT_EMAIL = 'test@test.com';
process.env.ALLOWED_ORIGINS = 'http://localhost:*';

// Close database connection after all tests
afterAll(async () => {
  if (mongoose.connection.readyState !== 0) {
    await mongoose.connection.close();
  }
});
