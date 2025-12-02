const request = require('supertest');
const app = require('../src/app');

describe('Application Error Handling', () => {
  describe('Health Check', () => {
    test('should return 200 for health check', async () => {
      const response = await request(app).get('/health');

      expect(response.status).toBe(200);
      expect(response.body.status).toBe('ok');
      expect(response.body.timestamp).toBeDefined();
    });
  });

  describe('404 Handler', () => {
    test('should return 404 for non-existent routes', async () => {
      const response = await request(app).get('/non-existent-route');

      expect(response.status).toBe(404);
      expect(response.body.error).toBe('Route not found');
    });
  });

  describe('CORS', () => {
    test('should handle CORS preflight requests', async () => {
      const response = await request(app)
        .options('/api/tasks')
        .set('Origin', 'http://localhost:3000')
        .set('Access-Control-Request-Method', 'GET');

      expect(response.status).toBe(204);
    });
  });

  describe('Request Body Parsing', () => {
    test('should parse JSON request bodies', async () => {
      const response = await request(app)
        .post('/api/auth/verify')
        .send({ token: 'test-token' })
        .set('Content-Type', 'application/json');

      // Should not fail due to parsing error
      expect(response.status).not.toBe(500);
    });
  });
});
