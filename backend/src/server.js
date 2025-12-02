require('dotenv').config();
const app = require('./app');
const connectDatabase = require('./config/database');
const { initializeFirebase } = require('./config/firebase');

const PORT = process.env.PORT || 3000;

/**
 * Start the server
 */
const startServer = async () => {
  try {
    // Initialize Firebase
    initializeFirebase();
    
    // Connect to MongoDB
    await connectDatabase();
    
    // Start Express server
    app.listen(PORT, () => {
      console.log(`Server running on port ${PORT}`);
      console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
      console.log(`Health check: http://localhost:${PORT}/health`);
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
};

startServer();
