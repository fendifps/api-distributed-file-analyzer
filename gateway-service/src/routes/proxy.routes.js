/**
 * Proxy Routes to Analyzer Service
 * Forwards authenticated requests to FastAPI service
 */

const express = require('express');
const router = express.Router();
const axios = require('axios');
const FormData = require('form-data');
const multer = require('multer');
const { authenticate } = require('../middleware/auth');
const { uploadLimiter } = require('../middleware/rateLimiter');

// Configure multer for file uploads (in-memory storage)
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB limit
  }
});

// Analyzer service base URL
const ANALYZER_URL = process.env.ANALYZER_SERVICE_URL || 'http://localhost:8000';

/**
 * @route   POST /api/analyzer/upload
 * @desc    Upload file for analysis
 * @access  Private
 */
router.post('/upload', authenticate, uploadLimiter, upload.single('file'), async (req, res, next) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'No file uploaded'
      });
    }

    // Create form data to forward to analyzer service
    const formData = new FormData();
    formData.append('file', req.file.buffer, {
      filename: req.file.originalname,
      contentType: req.file.mimetype
    });
    formData.append('user_id', req.user.id);

    // Forward request to analyzer service
    const response = await axios.post(
      `${ANALYZER_URL}/api/v1/upload`,
      formData,
      {
        headers: {
          ...formData.getHeaders(),
        },
        maxContentLength: Infinity,
        maxBodyLength: Infinity
      }
    );

    res.status(response.status).json(response.data);
  } catch (error) {
    if (error.response) {
      // Forward error from analyzer service
      return res.status(error.response.status).json(error.response.data);
    }
    next(error);
  }
});

/**
 * @route   GET /api/analyzer/tasks/:taskId
 * @desc    Get task status and result
 * @access  Private
 */
router.get('/tasks/:taskId', authenticate, async (req, res, next) => {
  try {
    const { taskId } = req.params;

    // Forward request to analyzer service
    const response = await axios.get(
      `${ANALYZER_URL}/api/v1/tasks/${taskId}`,
      {
        params: {
          user_id: req.user.id
        }
      }
    );

    res.status(response.status).json(response.data);
  } catch (error) {
    if (error.response) {
      return res.status(error.response.status).json(error.response.data);
    }
    next(error);
  }
});

/**
 * @route   GET /api/analyzer/tasks
 * @desc    Get all tasks for current user
 * @access  Private
 */
router.get('/tasks', authenticate, async (req, res, next) => {
  try {
    // Forward request to analyzer service
    const response = await axios.get(
      `${ANALYZER_URL}/api/v1/tasks`,
      {
        params: {
          user_id: req.user.id
        }
      }
    );

    res.status(response.status).json(response.data);
  } catch (error) {
    if (error.response) {
      return res.status(error.response.status).json(error.response.data);
    }
    next(error);
  }
});

module.exports = router;