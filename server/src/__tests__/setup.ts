import dotenv from 'dotenv';
import path from 'path';

// Load environment variables from .env file
dotenv.config();

// Set up test environment variables
process.env.NODE_ENV = 'test';

// Define global test constants
global.__TEST_DATA_DIR__ = path.join(__dirname, 'data');