/**
 * Centralized Error Handler Middleware
 */

const errorHandler = (err, req, res, next) => {
  // Log error for debugging
  console.error('Error occurred:', {
    message: err.message,
    stack: err.stack,
    path: req.path,
    method: req.method,
    timestamp: new Date().toISOString()
  });

  // Default error status and message
  let status = err.status || 500;
  let message = err.message || 'Internal Server Error';
  let error = process.env.NODE_ENV === 'development' ? err.stack : undefined;

  // Handle specific error types
  if (err.name === 'ValidationError') {
    status = 400;
    message = 'Validation Error';
  }

  if (err.name === 'UnauthorizedError') {
    status = 401;
    message = 'Unauthorized';
  }

  if (err.code === '23505') { // PostgreSQL unique violation
    status = 409;
    message = 'Resource already exists';
  }

  if (err.code === 'ECONNREFUSED') {
    status = 503;
    message = 'Service unavailable';
  }

  // Send error response
  res.status(status).json({
    error: http.STATUS_CODES[status] || 'Error',
    message: message,
    ...(error && { stack: error }),
    timestamp: new Date().toISOString(),
    path: req.path
  });
};

// Import http for status codes
const http = require('http');

module.exports = errorHandler;