const express = require('express');
const { body, param, validationResult } = require('express-validator');
const Task = require('../models/Task');
const authMiddleware = require('../middleware/auth');

const router = express.Router();

// Apply authentication middleware to all routes
router.use(authMiddleware);

/**
 * GET /api/tasks
 * Get all tasks for the authenticated user
 */
router.get('/', async (req, res) => {
  try {
    const tasks = await Task.findByUserId(req.user.uid);
    
    res.status(200).json({
      success: true,
      count: tasks.length,
      tasks: tasks,
    });
  } catch (error) {
    console.error('Error fetching tasks:', error);
    res.status(500).json({ 
      success: false,
      error: 'Failed to fetch tasks' 
    });
  }
});

/**
 * POST /api/tasks/sync
 * Sync tasks - upload local tasks and download remote tasks
 * Implements merge logic with conflict resolution
 */
router.post(
  '/sync',
  [
    body('tasks').isArray().withMessage('Tasks must be an array'),
    body('tasks.*.taskId').notEmpty().withMessage('Task ID is required'),
    body('tasks.*.title').notEmpty().trim().withMessage('Title is required'),
    body('tasks.*.priority').isInt({ min: 1, max: 5 }).withMessage('Priority must be between 1 and 5'),
    body('tasks.*.completed').isBoolean().withMessage('Completed must be a boolean'),
  ],
  async (req, res) => {
    try {
      // Validate request
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const localTasks = req.body.tasks || [];
      const userId = req.user.uid;

      // Get all remote tasks for this user
      const remoteTasks = await Task.findByUserId(userId);
      
      // Create maps for efficient lookup
      const remoteTaskMap = new Map();
      remoteTasks.forEach(task => {
        remoteTaskMap.set(task.taskId, task);
      });

      const localTaskMap = new Map();
      localTasks.forEach(task => {
        localTaskMap.set(task.taskId, task);
      });

      const tasksToUpdate = [];
      const tasksToCreate = [];
      const mergedTasks = [];

      // Process local tasks
      for (const localTask of localTasks) {
        const remoteTask = remoteTaskMap.get(localTask.taskId);
        
        if (remoteTask) {
          // Task exists on both sides - resolve conflict
          const localUpdatedAt = new Date(localTask.updatedAt);
          const remoteUpdatedAt = new Date(remoteTask.updatedAt);
          
          if (localUpdatedAt > remoteUpdatedAt) {
            // Local is newer - update remote
            tasksToUpdate.push({
              taskId: localTask.taskId,
              data: { ...localTask, userId },
            });
            mergedTasks.push({ ...localTask, userId });
          } else {
            // Remote is newer or same - keep remote
            mergedTasks.push(remoteTask.toJSON());
          }
        } else {
          // Task only exists locally - create on remote
          tasksToCreate.push({ ...localTask, userId });
          mergedTasks.push({ ...localTask, userId });
        }
      }

      // Add remote tasks that don't exist locally
      for (const remoteTask of remoteTasks) {
        if (!localTaskMap.has(remoteTask.taskId)) {
          mergedTasks.push(remoteTask.toJSON());
        }
      }

      // Execute database operations
      const bulkOps = [];

      // Create new tasks
      for (const task of tasksToCreate) {
        bulkOps.push({
          insertOne: {
            document: task,
          },
        });
      }

      // Update existing tasks
      for (const { taskId, data } of tasksToUpdate) {
        bulkOps.push({
          updateOne: {
            filter: { taskId, userId },
            update: { $set: data },
            upsert: false,
          },
        });
      }

      // Execute bulk operations if there are any
      if (bulkOps.length > 0) {
        await Task.bulkWrite(bulkOps);
      }

      res.status(200).json({
        success: true,
        message: 'Sync completed successfully',
        stats: {
          created: tasksToCreate.length,
          updated: tasksToUpdate.length,
          total: mergedTasks.length,
        },
        tasks: mergedTasks,
      });
    } catch (error) {
      console.error('Sync error:', error);
      res.status(500).json({ 
        success: false,
        error: 'Sync failed',
        message: error.message,
      });
    }
  }
);

/**
 * PUT /api/tasks/:id
 * Update a specific task
 */
router.put(
  '/:id',
  [
    param('id').notEmpty().withMessage('Task ID is required'),
    body('title').optional().notEmpty().trim().withMessage('Title cannot be empty'),
    body('priority').optional().isInt({ min: 1, max: 5 }).withMessage('Priority must be between 1 and 5'),
    body('completed').optional().isBoolean().withMessage('Completed must be a boolean'),
    body('dueDate').optional().isISO8601().withMessage('Due date must be a valid date'),
  ],
  async (req, res) => {
    try {
      // Validate request
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const taskId = req.params.id;
      const userId = req.user.uid;
      const updates = req.body;

      // Find and update the task
      const task = await Task.findOne({ taskId, userId });
      
      if (!task) {
        return res.status(404).json({ 
          success: false,
          error: 'Task not found' 
        });
      }

      // Apply updates
      Object.keys(updates).forEach(key => {
        if (updates[key] !== undefined) {
          task[key] = updates[key];
        }
      });

      await task.save();

      res.status(200).json({
        success: true,
        message: 'Task updated successfully',
        task: task.toJSON(),
      });
    } catch (error) {
      console.error('Update error:', error);
      res.status(500).json({ 
        success: false,
        error: 'Failed to update task' 
      });
    }
  }
);

/**
 * DELETE /api/tasks/:id
 * Delete a specific task
 */
router.delete(
  '/:id',
  [
    param('id').notEmpty().withMessage('Task ID is required'),
  ],
  async (req, res) => {
    try {
      // Validate request
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const taskId = req.params.id;
      const userId = req.user.uid;

      const result = await Task.deleteByTaskId(taskId, userId);

      if (result.deletedCount === 0) {
        return res.status(404).json({ 
          success: false,
          error: 'Task not found' 
        });
      }

      res.status(200).json({
        success: true,
        message: 'Task deleted successfully',
      });
    } catch (error) {
      console.error('Delete error:', error);
      res.status(500).json({ 
        success: false,
        error: 'Failed to delete task' 
      });
    }
  }
);

module.exports = router;
