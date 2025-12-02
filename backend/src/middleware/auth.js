const { admin } = require('../config/firebase');

/**
 * Authentication middleware to verify Firebase tokens
 * Extracts and verifies the Firebase ID token from the Authorization header
 * Attaches the decoded user information to req.user
 */
const authMiddleware = async (req, res, next) => {
  try {
    // Extract token from Authorization header
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ 
        error: 'Unauthorized', 
        message: 'No token provided. Authorization header must be in format: Bearer <token>' 
      });
    }

    const token = authHeader.split('Bearer ')[1];

    if (!token) {
      return res.status(401).json({ 
        error: 'Unauthorized', 
        message: 'Token is empty' 
      });
    }

    // Verify the Firebase ID token
    const decodedToken = await admin.auth().verifyIdToken(token);
    
    // Attach user information to request object
    req.user = {
      uid: decodedToken.uid,
      email: decodedToken.email,
      emailVerified: decodedToken.email_verified,
      name: decodedToken.name,
      picture: decodedToken.picture,
    };

    next();
  } catch (error) {
    console.error('Authentication error:', error.message);
    
    // Handle specific Firebase auth errors
    if (error.code === 'auth/id-token-expired') {
      return res.status(401).json({ 
        error: 'Unauthorized', 
        message: 'Token has expired. Please sign in again.' 
      });
    }
    
    if (error.code === 'auth/id-token-revoked') {
      return res.status(401).json({ 
        error: 'Unauthorized', 
        message: 'Token has been revoked. Please sign in again.' 
      });
    }
    
    if (error.code === 'auth/invalid-id-token' || error.code === 'auth/argument-error') {
      return res.status(401).json({ 
        error: 'Unauthorized', 
        message: 'Invalid token format or signature' 
      });
    }

    // Generic authentication error
    return res.status(401).json({ 
      error: 'Unauthorized', 
      message: 'Authentication failed' 
    });
  }
};

module.exports = authMiddleware;
