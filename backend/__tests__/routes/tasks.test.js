const request = require('supertest');
const mongoose = require('mongoose');
const app = require('../../src/app');
const Task = require('../../src/models/Task');
const { admin } = require('../../src/config/firebase');

describe('Task API Endpoints', () => {
  const mockUserId = 'test-user-123';
  const validToken = 'valid-test-token';

  beforeAll(async () => {
    // Connect to test database
    if (mongoose.connection.readyState === 0) {
      await mongoose.connect(process.env.MONGODB_URI);
    }
  });

  beforeEach(async () => {
    // Clear tasks collection
    await Task.deleteMany({});

    // Mock Firebase token verification
    admin.auth().verifyIdToken.mockResolvedValue({
      uid: mockUserId,
      email: 'test@example.com',
      email_verified: true,
    });
  });

  afterAll(async () => {
    await mongoose.connection.close();
  });

  describe('GET /api/tasks', () => {
    test('should return empty array when no tasks exist', async () => {
      const response = await request(app)
        .get('/api/tasks')
        .set('Authorization', `Bearer ${validToken}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.tasks).toEqual([]);
      expect(response.body.count).toBe(0);
    });

    test('should return all tasks for authenticated user', async () => {
      // Create test tasks
      await Task.create([
        {
          userId: mockUserId,
          taskId: 'task-1',
          title: 'Task 1',
          priority: 3,
          completed: false,
        },
        {
          userId: mockUserId,
          taskId: 'task-2',
          title: 'Task 2',
          priority: 5,
          completed: true,
        },
      ]);

      const response = await request(app)
        .get('/api/tasks')
        .set('Authorization', `Bearer ${validToken}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.count).toBe(2);
      expect(response.body.tasks).toHaveLength(2);
    });

    test('should not return tasks from other users', async () => {
      await Task.create([
        {
          userId: 'other-user',
          taskId: 'task-other',
          title: 'Other Task',
          priority: 3,
          completed: false,
        },
      ]);

      const response = await request(app)
        .get('/api/tasks')
        .set('Authorization', `Bearer ${validToken}`);

      expect(response.status).toBe(200);
      expect(response.body.count).toBe(0);
    });

    test('should require authentication', async () => {
      const response = await request(app).get('/api/tasks');

      expect(response.status).toBe(401);
    });
  });

  describe('POST /api/tasks/sync', () => {
    test('should create new tasks from sync', async () => {
      const localTasks = [
        {
          taskId: 'task-1',
          title: 'New Task',
          description: 'Description',
          priority: 4,
          completed: false,
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString(),
        },
      ];

      const response = await request(app)
        .post('/api/tasks/sync')
        .set('Authorization', `Bearer ${validToken}`)
        .send({ tasks: localTasks });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.stats.created).toBe(1);
      expect(response.body.tasks).toHaveLength(1);

      // Verify task was created in database
      const dbTask = await Task.findOne({ taskId: 'task-1' });
      expect(dbTask).toBeTruthy();
      expect(dbTask.title).toBe('New Task');
    });

    test('should resolve conflicts using latest timestamp', async () => {
      const oldDate = new Date('2024-01-01');
      const newDate = new Date('2024-01-02');

      // Create existing task with old timestamp
      await Task.create({
        userId: mockUserId,
        taskId: 'task-1',
        title: 'Old Title',
        priority: 3,
        completed: false,
        updatedAt: oldDate,
      });

      // Sync with newer version
      const localTasks = [
        {
          taskId: 'task-1',
          title: 'New Title',
          priority: 5,
          completed: true,
          createdAt: oldDate.toISOString(),
          updatedAt: newDate.toISOString(),
        },
      ];

      const response = await request(app)
        .post('/api/tasks/sync')
        .set('Authorization', `Bearer ${validToken}`)
        .send({ tasks: localTasks });

      expect(response.status).toBe(200);
      expect(response.body.stats.updated).toBe(1);

      // Verify newer version was kept
      const mergedTask = response.body.tasks.find(t => t.taskId === 'task-1');
      expect(mergedTask.title).toBe('New Title');
      expect(mergedTask.priority).toBe(5);
    });

    test('should merge local and remote tasks without duplicates', async () => {
      // Create remote task
      await Task.create({
        userId: mockUserId,
        taskId: 'remote-task',
        title: 'Remote Task',
        priority: 3,
        completed: false,
      });

      // Sync with local task
      const localTasks = [
        {
          taskId: 'local-task',
          title: 'Local Task',
          priority: 4,
          completed: false,
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString(),
        },
      ];

      const response = await request(app)
        .post('/api/tasks/sync')
        .set('Authorization', `Bearer ${validToken}`)
        .send({ tasks: localTasks });

      expect(response.status).toBe(200);
      expect(response.body.tasks).toHaveLength(2);
      
      const taskIds = response.body.tasks.map(t => t.taskId);
      expect(taskIds).toContain('remote-task');
      expect(taskIds).toContain('local-task');
    });

    test('should validate task data', async () => {
      const invalidTasks = [
        {
          taskId: 'task-1',
          title: '', // Empty title
          priority: 3,
          completed: false,
        },
      ];

      const response = await request(app)
        .post('/api/tasks/sync')
        .set('Authorization', `Bearer ${validToken}`)
        .send({ tasks: invalidTasks });

      expect(response.status).toBe(400);
      expect(response.body.errors).toBeDefined();
    });
  });

  describe('PUT /api/tasks/:id', () => {
    test('should update existing task', async () => {
      await Task.create({
        userId: mockUserId,
        taskId: 'task-1',
        title: 'Original Title',
        priority: 3,
        completed: false,
      });

      const response = await request(app)
        .put('/api/tasks/task-1')
        .set('Authorization', `Bearer ${validToken}`)
        .send({
          title: 'Updated Title',
          priority: 5,
        });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.task.title).toBe('Updated Title');
      expect(response.body.task.priority).toBe(5);
    });

    test('should return 404 for non-existent task', async () => {
      const response = await request(app)
        .put('/api/tasks/non-existent')
        .set('Authorization', `Bearer ${validToken}`)
        .send({ title: 'Updated' });

      expect(response.status).toBe(404);
    });

    test('should not update tasks from other users', async () => {
      await Task.create({
        userId: 'other-user',
        taskId: 'task-1',
        title: 'Other User Task',
        priority: 3,
        completed: false,
      });

      const response = await request(app)
        .put('/api/tasks/task-1')
        .set('Authorization', `Bearer ${validToken}`)
        .send({ title: 'Hacked' });

      expect(response.status).toBe(404);
    });
  });

  describe('DELETE /api/tasks/:id', () => {
    test('should delete existing task', async () => {
      await Task.create({
        userId: mockUserId,
        taskId: 'task-1',
        title: 'Task to Delete',
        priority: 3,
        completed: false,
      });

      const response = await request(app)
        .delete('/api/tasks/task-1')
        .set('Authorization', `Bearer ${validToken}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);

      // Verify task was deleted
      const dbTask = await Task.findOne({ taskId: 'task-1' });
      expect(dbTask).toBeNull();
    });

    test('should return 404 for non-existent task', async () => {
      const response = await request(app)
        .delete('/api/tasks/non-existent')
        .set('Authorization', `Bearer ${validToken}`);

      expect(response.status).toBe(404);
    });

    test('should not delete tasks from other users', async () => {
      await Task.create({
        userId: 'other-user',
        taskId: 'task-1',
        title: 'Other User Task',
        priority: 3,
        completed: false,
      });

      const response = await request(app)
        .delete('/api/tasks/task-1')
        .set('Authorization', `Bearer ${validToken}`);

      expect(response.status).toBe(404);

      // Verify task still exists
      const dbTask = await Task.findOne({ taskId: 'task-1' });
      expect(dbTask).toBeTruthy();
    });
  });
});
