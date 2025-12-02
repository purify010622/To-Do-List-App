require('dotenv').config();
const mongoose = require('mongoose');

// Use environment variable instead of hardcoded credentials
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/todoDB';

mongoose.connect(MONGODB_URI)
  .then(() => {
    console.log('✅ Successfully connected to MongoDB!');
    console.log('Database:', mongoose.connection.name);
    mongoose.connection.close();
  })
  .catch((err) => {
    console.error('❌ Connection failed:', err.message);
  });
