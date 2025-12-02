const authMiddleware = require('../../src/middleware/auth');
const { admin } = require('../../src/config/firebase');

describe('Authentication Middleware', () => {
  let req, res, next;

  beforeEach(() => {
    req = {
      headers: {},
    };
    res = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn(),
    };
    next = jest.fn();
    jest.clearAllMocks();
  });

  test('should reject request without authorization header', async () => {
    await authMiddleware(req, res, next);

    expect(res.status).toHaveBeenCalledWith(401);
    expect(res.json).toHaveBeenCalledWith(
      expect.objectContaining({
        error: 'Unauthorized',
      })
    );
    expect(next).not.toHaveBeenCalled();
  });

  test('should reject request with invalid authorization format', async () => {
    req.headers.authorization = 'InvalidFormat token123';

    await authMiddleware(req, res, next);

    expect(res.status).toHaveBeenCalledWith(401);
    expect(res.json).toHaveBeenCalledWith(
      expect.objectContaining({
        error: 'Unauthorized',
      })
    );
    expect(next).not.toHaveBeenCalled();
  });

  test('should reject request with empty token', async () => {
    req.headers.authorization = 'Bearer ';

    await authMiddleware(req, res, next);

    expect(res.status).toHaveBeenCalledWith(401);
    expect(next).not.toHaveBeenCalled();
  });

  test('should verify valid token and attach user to request', async () => {
    const mockDecodedToken = {
      uid: 'user123',
      email: 'test@example.com',
      email_verified: true,
      name: 'Test User',
      picture: 'https://example.com/photo.jpg',
    };

    req.headers.authorization = 'Bearer valid-token';
    admin.auth().verifyIdToken.mockResolvedValue(mockDecodedToken);

    await authMiddleware(req, res, next);

    expect(admin.auth().verifyIdToken).toHaveBeenCalledWith('valid-token');
    expect(req.user).toEqual({
      uid: 'user123',
      email: 'test@example.com',
      emailVerified: true,
      name: 'Test User',
      picture: 'https://example.com/photo.jpg',
    });
    expect(next).toHaveBeenCalled();
    expect(res.status).not.toHaveBeenCalled();
  });

  test('should handle expired token error', async () => {
    req.headers.authorization = 'Bearer expired-token';
    const error = new Error('Token expired');
    error.code = 'auth/id-token-expired';
    admin.auth().verifyIdToken.mockRejectedValue(error);

    await authMiddleware(req, res, next);

    expect(res.status).toHaveBeenCalledWith(401);
    expect(res.json).toHaveBeenCalledWith(
      expect.objectContaining({
        message: expect.stringContaining('expired'),
      })
    );
    expect(next).not.toHaveBeenCalled();
  });

  test('should handle revoked token error', async () => {
    req.headers.authorization = 'Bearer revoked-token';
    const error = new Error('Token revoked');
    error.code = 'auth/id-token-revoked';
    admin.auth().verifyIdToken.mockRejectedValue(error);

    await authMiddleware(req, res, next);

    expect(res.status).toHaveBeenCalledWith(401);
    expect(res.json).toHaveBeenCalledWith(
      expect.objectContaining({
        message: expect.stringContaining('revoked'),
      })
    );
    expect(next).not.toHaveBeenCalled();
  });

  test('should handle invalid token error', async () => {
    req.headers.authorization = 'Bearer invalid-token';
    const error = new Error('Invalid token');
    error.code = 'auth/invalid-id-token';
    admin.auth().verifyIdToken.mockRejectedValue(error);

    await authMiddleware(req, res, next);

    expect(res.status).toHaveBeenCalledWith(401);
    expect(res.json).toHaveBeenCalledWith(
      expect.objectContaining({
        error: 'Unauthorized',
      })
    );
    expect(next).not.toHaveBeenCalled();
  });
});
