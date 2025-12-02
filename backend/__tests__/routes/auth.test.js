const request = require('supertest');
const app = require('../../src/app');
const { admin } = require('../../src/config/firebase');

describe('Auth API Endpoints', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('POST /api/auth/verify', () => {
    test('should verify valid token', async () => {
      const mockDecodedToken = {
        uid: 'user123',
        email: 'test@example.com',
        exp: Math.floor(Date.now() / 1000) + 3600, // Expires in 1 hour
      };

      admin.auth().verifyIdToken.mockResolvedValue(mockDecodedToken);

      const response = await request(app)
        .post('/api/auth/verify')
        .send({ token: 'valid-token' });

      expect(response.status).toBe(200);
      expect(response.body.valid).toBe(true);
      expect(response.body.uid).toBe('user123');
      expect(response.body.email).toBe('test@example.com');
      expect(response.body.expiresAt).toBeDefined();
    });

    test('should reject expired token', async () => {
      const error = new Error('Token expired');
      error.code = 'auth/id-token-expired';
      admin.auth().verifyIdToken.mockRejectedValue(error);

      const response = await request(app)
        .post('/api/auth/verify')
        .send({ token: 'expired-token' });

      expect(response.status).toBe(401);
      expect(response.body.valid).toBe(false);
      expect(response.body.error).toContain('expired');
    });

    test('should reject invalid token', async () => {
      const error = new Error('Invalid token');
      error.code = 'auth/invalid-id-token';
      admin.auth().verifyIdToken.mockRejectedValue(error);

      const response = await request(app)
        .post('/api/auth/verify')
        .send({ token: 'invalid-token' });

      expect(response.status).toBe(401);
      expect(response.body.valid).toBe(false);
    });

    test('should require token in request body', async () => {
      const response = await request(app)
        .post('/api/auth/verify')
        .send({});

      expect(response.status).toBe(400);
      expect(response.body.errors).toBeDefined();
    });

    test('should handle generic verification errors', async () => {
      admin.auth().verifyIdToken.mockRejectedValue(new Error('Unknown error'));

      const response = await request(app)
        .post('/api/auth/verify')
        .send({ token: 'some-token' });

      expect(response.status).toBe(401);
      expect(response.body.valid).toBe(false);
    });
  });
});
