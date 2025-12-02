const rateLimit = require('express-rate-limit');

/**
 * Rate limiter configuration
 * Limits requests to 100 per 15 minutes per user
 */
const createRateLimiter = () => {
  return rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100, // Limit each user to 100 requests per windowMs
    message: {
      error: 'Too many requests',
      message: 'You have exceeded the rate limit. Please try again later.',
      retryAfter: '15 minutes',
    },
    standardHeaders: true, // Return rate limit info in the `RateLimit-*` headers
    legacyHeaders: false, // Disable the `X-RateLimit-*` headers
    
    // Use user ID as key if authenticated, otherwise use IP
    keyGenerator: (req) => {
      return req.user?.uid || req.ip;
    },
    
    // Skip rate limiting for health check
    skip: (req) => {
      return req.path === '/health';
    },
    
    // Custom handler for rate limit exceeded
    handler: (req, res) => {
      res.status(429).json({
        error: 'Too many requests',
        message: 'Rate limit exceeded. Please try again later.',
        retryAfter: Math.ceil(req.rateLimit.resetTime / 1000),
      });
    },
  });
};

/**
 * Stricter rate limiter for authentication endpoints
 * Limits to 10 requests per 15 minutes
 */
const createAuthRateLimiter = () => {
  return rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 10, // Limit to 10 auth attempts per windowMs
    message: {
      error: 'Too many authentication attempts',
      message: 'Please try again later.',
    },
    standardHeaders: true,
    legacyHeaders: false,
    keyGenerator: (req) => req.ip,
    handler: (req, res) => {
      res.status(429).json({
        error: 'Too many authentication attempts',
        message: 'Please try again later.',
        retryAfter: Math.ceil(req.rateLimit.resetTime / 1000),
      });
    },
  });
};

module.exports = {
  createRateLimiter,
  createAuthRateLimiter,
};
