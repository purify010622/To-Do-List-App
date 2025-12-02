const express = require('express');
const { body, validationResult } = require('express-validator');
const { admin } = require('../config/firebase');

const router = express.Router();

/**
 * POST /api/auth/verify
 * Verify Firebase ID token
 * This endpoint can be used by the client to verify their token is still valid
 */
router.post(
  '/verify',
  [
    body('token').notEmpty().withMessage('Token is required'),
  ],
  async (req, res) => {
    try {
      // Validate request
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { token } = req.body;

      // Verify the token
      const decodedToken = await admin.auth().verifyIdToken(token);

      res.status(200).json({
        valid: true,
        uid: decodedToken.uid,
        email: decodedToken.email,
        expiresAt: new Date(decodedToken.exp * 1000).toISOString(),
      });
    } catch (error) {
      console.error('Token verification error:', error.message);
      
      if (error.code === 'auth/id-token-expired') {
        return res.status(401).json({ 
          valid: false, 
          error: 'Token expired' 
        });
      }
      
      res.status(401).json({ 
        valid: false, 
        error: 'Invalid token' 
      });
    }
  }
);

module.exports = router;
