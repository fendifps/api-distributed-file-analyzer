/**
 * Redis Configuration
 */

const { createClient } = require('redis');

// Create Redis client
const redisClient = createClient({
  socket: {
    host: process.env.REDIS_HOST || 'localhost',
    port: parseInt(process.env.REDIS_PORT) || 6379,
    reconnectStrategy: (retries) => {
      if (retries > 10) {
        console.error('Redis: Too many retries, giving up');
        return new Error('Too many retries');
      }
      return retries * 100; // Exponential backoff
    }
  }
});

// Error handling
redisClient.on('error', (err) => {
  console.error('Redis Client Error:', err);
});

redisClient.on('connect', () => {
  console.log('Redis client connected');
});

redisClient.on('ready', () => {
  console.log('Redis client ready');
});

// Connect to Redis
const connectRedis = async () => {
  if (!redisClient.isOpen) {
    await redisClient.connect();
  }
};

// Test Redis connection
const testRedisConnection = async () => {
  try {
    await connectRedis();
    await redisClient.ping();
    return true;
  } catch (error) {
    console.error('Redis connection error:', error);
    throw error;
  }
};

// Initialize connection
connectRedis().catch(console.error);

module.exports = {
  redisClient,
  connectRedis,
  testRedisConnection
};