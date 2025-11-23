/**
 * Gateway Service - Entry Point
 * Node.js/Express API Gateway with Authentication and Rate Limiting
 */

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const authRoutes = require('./routes/auth.routes');
const proxyRoutes = require('./routes/proxy.routes');
const errorHandler = require('./middleware/errorHandler');
const { testDatabaseConnection } = require('./config/database');
const { testRedisConnection } = require('./config/redis');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet()); // Security headers
app.use(cors()); // CORS
app.use(morgan('combined')); // Logging
app.use(express.json()); // JSON body parser
app.use(express.urlencoded({ extended: true })); // URL-encoded body parser

// Health check endpoint
app.get('/health', async (req, res) => {
  const health = {
    status: 'UP',
    timestamp: new Date().toISOString(),
    service: 'gateway-service',
    checks: {
      postgres: false,
      redis: false
    }
  };

  try {
    await testDatabaseConnection();
    health.checks.postgres = true;
  } catch (error) {
    console.error('PostgreSQL health check failed:', error.message);
  }

  try {
    await testRedisConnection();
    health.checks.redis = true;
  } catch (error) {
    console.error('Redis health check failed:', error.message);
  }

  const allHealthy = Object.values(health.checks).every(check => check);
  res.status(allHealthy ? 200 : 503).json(health);
});

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/analyzer', proxyRoutes);

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    error: 'Not Found',
    message: 'The requested endpoint does not exist',
    path: req.path
  });
});

// Error handler (must be last)
app.use(errorHandler);

// Start server
const startServer = async () => {
  try {
    // Test database connection
    await testDatabaseConnection();
    console.log('✓ PostgreSQL connected');

    // Test Redis connection
    await testRedisConnection();
    console.log('✓ Redis connected');

    // Start listening
    app.listen(PORT, () => {
      console.log('');
      console.log('================================================');
      console.log(`  Gateway Service running on port ${PORT}`);
      console.log(`  Environment: ${process.env.NODE_ENV || 'development'}`);
      console.log('================================================');
      console.log(`  Health:  http://localhost:${PORT}/health`);
      console.log(`  Auth:    http://localhost:${PORT}/api/auth`);
      console.log(`  Proxy:   http://localhost:${PORT}/api/analyzer`);
      console.log('================================================');
      console.log('');
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
};

// Handle uncaught exceptions
process.on('uncaughtException', (error) => {
  console.error('Uncaught Exception:', error);
  process.exit(1);
});

// Handle unhandled promise rejections
process.on('unhandledRejection', (error) => {
  console.error('Unhandled Rejection:', error);
  process.exit(1);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully...');
  process.exit(0);
});

startServer();

module.exports = app;