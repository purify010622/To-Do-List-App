const mongoose = require('mongoose');

/**
 * Task Schema for MongoDB
 * Stores task data with user association for cloud sync
 */
const taskSchema = new mongoose.Schema(
  {
    // User association
    userId: {
      type: String,
      required: true,
      index: true,
    },
    
    // Client-generated UUID for task identification
    taskId: {
      type: String,
      required: true,
      unique: true,
      index: true,
    },
    
    // Task details
    title: {
      type: String,
      required: true,
      trim: true,
      maxlength: 500,
    },
    
    description: {
      type: String,
      trim: true,
      maxlength: 5000,
      default: '',
    },
    
    priority: {
      type: Number,
      required: true,
      min: 1,
      max: 5,
      default: 3,
      index: true,
    },
    
    dueDate: {
      type: Date,
      default: null,
      index: true,
    },
    
    completed: {
      type: Boolean,
      required: true,
      default: false,
    },
  },
  {
    // Automatically manage createdAt and updatedAt timestamps
    timestamps: true,
  }
);

// Compound index for efficient querying by user and sorting
taskSchema.index({ userId: 1, priority: -1, dueDate: 1 });

// Compound index for user and completion status
taskSchema.index({ userId: 1, completed: 1 });

// Instance methods
taskSchema.methods.toJSON = function() {
  const task = this.toObject();
  
  // Remove MongoDB-specific fields
  delete task._id;
  delete task.__v;
  
  return task;
};

// Static methods
taskSchema.statics.findByUserId = function(userId) {
  return this.find({ userId }).sort({ priority: -1, dueDate: 1 });
};

taskSchema.statics.findByTaskId = function(taskId) {
  return this.findOne({ taskId });
};

taskSchema.statics.deleteByTaskId = function(taskId, userId) {
  return this.deleteOne({ taskId, userId });
};

const Task = mongoose.model('Task', taskSchema);

module.exports = Task;
