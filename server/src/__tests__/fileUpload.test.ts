import request from 'supertest';
import path from 'path';
import { app } from '../app';
import { AIModel } from '@interfaces/ModelConfig';

describe('File Upload Tests', () => {
  const testDataDir = path.join(__dirname, 'data');
  const validModels = {
    openai: ['gpt-4-vision-preview'],
    anthropic: ['claude-3-opus-20240229'],
    perplexity: ['pplx-70b-online']
  };

  // Helper function to test file upload with a specific model
  async function testFileUpload(filePath: string, model: string, provider: string, expectedStatus: number = 200) {
    const response = await request(app)
      .post('/api/chat')
      .field('model', model)
      .field('provider', provider)
      .field('message', 'Please analyze this file and tell me its contents.')
      .attach('file', path.join(testDataDir, filePath));

    expect(response.status).toBe(expectedStatus);
    if (expectedStatus === 200) {
      expect(response.body).toHaveProperty('response');
      expect(typeof response.body.response).toBe('string');
      return response.body.response;
    }
    return null;
  }

  describe('Text Documents', () => {
    test('should handle .txt files correctly', async () => {
      for (const [provider, models] of Object.entries(validModels)) {
        for (const model of models) {
          const response = await testFileUpload('sample.txt', model, provider);
          expect(response).toContain('text file');
          expect(response).toContain('multiple lines');
        }
      }
    });

    // Add tests for .docx and .pdf when sample files are available
  });

  describe('Code Files', () => {
    test('should handle .py files correctly', async () => {
      for (const [provider, models] of Object.entries(validModels)) {
        for (const model of models) {
          const response = await testFileUpload('sample.py', model, provider);
          expect(response).toContain('function');
          expect(response).toContain('greet');
          expect(response).toContain('Python');
        }
      }
    });

    // Add tests for .js and .ts when sample files are available
  });

  describe('Spreadsheets', () => {
    test('should handle .csv files correctly', async () => {
      for (const [provider, models] of Object.entries(validModels)) {
        for (const model of models) {
          const response = await testFileUpload('sample.csv', model, provider);
          expect(response).toContain('John Doe');
          expect(response).toContain('New York');
          expect(response).toContain('table');
        }
      }
    });

    // Add tests for .xlsx when sample files are available
  });

  describe('Images', () => {
    test('should handle .png files correctly', async () => {
      for (const [provider, models] of Object.entries(validModels)) {
        for (const model of models) {
          const response = await testFileUpload('sample.png', model, provider);
          expect(response).toContain('square');
          expect(response).toContain('red');
          expect(response).toContain('blue');
        }
      }
    });

    test('should handle .jpg files correctly', async () => {
      for (const [provider, models] of Object.entries(validModels)) {
        for (const model of models) {
          const response = await testFileUpload('sample.jpg', model, provider);
          expect(response).toContain('square');
          expect(response).toContain('red');
          expect(response).toContain('blue');
        }
      }
    });

    test('should handle non-animated .gif files correctly', async () => {
      for (const [provider, models] of Object.entries(validModels)) {
        for (const model of models) {
          const response = await testFileUpload('sample.gif', model, provider);
          expect(response).toContain('square');
          expect(response).toContain('red');
          expect(response).toContain('blue');
        }
      }
    });
  });

  describe('Invalid Files', () => {
    test('should reject video files', async () => {
      for (const [provider, models] of Object.entries(validModels)) {
        for (const model of models) {
          const response = await request(app)
            .post('/api/chat')
            .field('model', model)
            .field('provider', provider)
            .field('message', 'Please analyze this video.')
            .attach('file', path.join(testDataDir, 'sample.mp4'));

          expect(response.status).toBe(400);
          expect(response.body).toHaveProperty('error');
          expect(response.body.error).toContain('video');
        }
      }
    });

    test('should reject files that are too large', async () => {
      for (const [provider, models] of Object.entries(validModels)) {
        for (const model of models) {
          const response = await request(app)
            .post('/api/chat')
            .field('model', model)
            .field('provider', provider)
            .field('message', 'Please analyze this file.')
            .attach('file', path.join(testDataDir, 'large_file.bin'));

          expect(response.status).toBe(400);
          expect(response.body).toHaveProperty('error');
          expect(response.body.error).toContain('size');
        }
      }
    });

    test('should reject unsupported file types', async () => {
      const unsupportedFiles = ['sample.exe', 'sample.zip'];
      
      for (const [provider, models] of Object.entries(validModels)) {
        for (const model of models) {
          for (const file of unsupportedFiles) {
            const response = await request(app)
              .post('/api/chat')
              .field('model', model)
              .field('provider', provider)
              .field('message', 'Please analyze this file.')
              .attach('file', path.join(testDataDir, file));

            expect(response.status).toBe(400);
            expect(response.body).toHaveProperty('error');
            expect(response.body.error).toContain('unsupported');
          }
        }
      }
    });
  });

  describe('Concurrent Uploads', () => {
    test('should handle multiple concurrent file uploads', async () => {
      const files = ['sample.txt', 'sample.py', 'sample.csv', 'sample.png'];
      const [provider, models] = Object.entries(validModels)[0];
      const model = models[0];

      const uploadPromises = files.map(file =>
        testFileUpload(file, model, provider)
      );

      const responses = await Promise.all(uploadPromises);
      
      // Verify each response contains appropriate content
      expect(responses[0]).toContain('text file');
      expect(responses[1]).toContain('function');
      expect(responses[2]).toContain('John Doe');
      expect(responses[3]).toContain('square');
    });
  });

  describe('Error Handling', () => {
    test('should handle missing files gracefully', async () => {
      const response = await request(app)
        .post('/api/chat')
        .field('model', validModels.openai[0])
        .field('provider', 'openai')
        .field('message', 'Please analyze this file.');

      expect(response.status).toBe(400);
      expect(response.body).toHaveProperty('error');
    });

    test('should handle invalid model/provider combinations', async () => {
      const response = await request(app)
        .post('/api/chat')
        .field('model', 'invalid-model')
        .field('provider', 'invalid-provider')
        .field('message', 'Please analyze this file.')
        .attach('file', path.join(testDataDir, 'sample.txt'));

      expect(response.status).toBe(400);
      expect(response.body).toHaveProperty('error');
    });
  });
});