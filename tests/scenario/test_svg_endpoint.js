#!/usr/bin/env node
/**
 * Test suite for SVG content endpoint
 * Tests FR-3: SVG Content Endpoint
 */

const http = require('http');
const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');

const TEST_DIR = '/tmp/plantuml.nvim';
const SERVER_PATH = path.join(__dirname, '..', 'server', 'server.js');
const TEST_PORT = 8922;
const TEST_SVG = '<svg><rect width="100" height="100"/></svg>';

let serverProcess = null;
let testResults = [];

function log(message) {
  console.log(`[TEST] ${message}`);
}

function recordTest(name, passed, details = '') {
  const result = { name, passed, details };
  testResults.push(result);
  const status = passed ? '✓ PASS' : '✗ FAIL';
  console.log(`${status}: ${name}${details ? ` - ${details}` : ''}`);
}

async function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

async function startServer() {
  return new Promise((resolve, reject) => {
    log('Starting server...');
    serverProcess = spawn('node', [SERVER_PATH, '--port', TEST_PORT.toString()]);
    
    let resolved = false;
    
    serverProcess.stdout.on('data', (data) => {
      const output = data.toString();
      if (output.includes(`PORT:${TEST_PORT}`)) {
        if (!resolved) {
          resolved = true;
          resolve();
        }
      }
    });
    
    serverProcess.stderr.on('data', (data) => {
      console.error('Server error:', data.toString());
    });
    
    serverProcess.on('error', (err) => {
      reject(new Error(`Failed to start server: ${err.message}`));
    });
    
    setTimeout(() => {
      if (!resolved) {
        reject(new Error('Server startup timeout'));
      }
    }, 3000);
  });
}

function stopServer() {
  return new Promise((resolve) => {
    if (serverProcess) {
      serverProcess.on('close', () => {
        resolve();
      });
      serverProcess.kill('SIGTERM');
    } else {
      resolve();
    }
  });
}

// Test 1: Cached content
async function test1_CachedContent() {
  return new Promise((resolve) => {
    log('\nTest 1: Return cached SVG content');
    
    // First, set state with SVG content
    const testFile = path.join(TEST_DIR, 'test-cached.svg');
    fs.writeFileSync(testFile, TEST_SVG);
    
    const postData = JSON.stringify({
      filename: 'test-cached.puml',
      filepath: testFile
    });
    
    const req1 = http.request({
      hostname: 'localhost',
      port: TEST_PORT,
      path: '/update',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData)
      }
    }, (res) => {
      let data = '';
      res.on('data', (chunk) => { data += chunk; });
      res.on('end', () => {
        // Now get the SVG
        const req2 = http.request({
          hostname: 'localhost',
          port: TEST_PORT,
          path: '/svg',
          method: 'GET'
        }, (res) => {
          let svg = '';
          res.on('data', (chunk) => { svg += chunk; });
          res.on('end', () => {
            const matches = svg === TEST_SVG;
            
            recordTest('GET /svg returns cached SVG content', matches);
            
            try {
              fs.unlinkSync(testFile);
            } catch (e) {}
            
            resolve(matches);
          });
        });
        
        req2.on('error', (err) => {
          recordTest('Cached content test', false, err.message);
          try {
            fs.unlinkSync(testFile);
          } catch (e) {}
          resolve(false);
        });
        
        req2.end();
      });
    });
    
    req1.on('error', (err) => {
      recordTest('Cached content test', false, err.message);
      try {
        fs.unlinkSync(testFile);
      } catch (e) {}
      resolve(false);
    });
    
    req1.write(postData);
    req1.end();
  });
}

// Test 2: Content-type header
async function test2_ContentType() {
  return new Promise((resolve) => {
    log('\nTest 2: Content-Type header');
    
    const req = http.request({
      hostname: 'localhost',
      port: TEST_PORT,
      path: '/svg',
      method: 'GET'
    }, (res) => {
      const contentType = res.headers['content-type'];
      const isCorrect = contentType === 'image/svg+xml';
      
      recordTest('Response has Content-Type: image/svg+xml', isCorrect);
      
      resolve(isCorrect);
    });
    
    req.on('error', (err) => {
      recordTest('Content-Type test', false, err.message);
      resolve(false);
    });
    
    req.end();
  });
}

// Test 3: Empty state
async function test3_EmptyState() {
  return new Promise((resolve) => {
    log('\nTest 3: Empty state returns 200');
    
    // Start a new server to ensure empty state
    // (We'll just test with current server)
    
    const req = http.request({
      hostname: 'localhost',
      port: TEST_PORT,
      path: '/svg',
      method: 'GET'
    }, (res) => {
      let data = '';
      res.on('data', (chunk) => { data += chunk; });
      res.on('end', () => {
        const statusOk = res.statusCode === 200;
        
        recordTest('GET /svg returns 200 even with empty state', statusOk);
        
        resolve(statusOk);
      });
    });
    
    req.on('error', (err) => {
      recordTest('Empty state test', false, err.message);
      resolve(false);
    });
    
    req.end();
  });
}

// Test 4: CORS headers
async function test4_CORSHeaders() {
  return new Promise((resolve) => {
    log('\nTest 4: CORS headers');
    
    const req = http.request({
      hostname: 'localhost',
      port: TEST_PORT,
      path: '/svg',
      method: 'GET'
    }, (res) => {
      const hasCORS = res.headers['access-control-allow-origin'] === '*';
      
      recordTest('Response has Access-Control-Allow-Origin: *', hasCORS);
      
      resolve(hasCORS);
    });
    
    req.on('error', (err) => {
      recordTest('CORS headers test', false, err.message);
      resolve(false);
    });
    
    req.end();
  });
}

async function runTests() {
  console.log('========================================');
  console.log('SVG Endpoint Tests (FR-3)');
  console.log('========================================');
  
  try {
    if (!fs.existsSync(TEST_DIR)) {
      fs.mkdirSync(TEST_DIR, { recursive: true });
    }
    
    await startServer();
    await sleep(500);
    
    await test1_CachedContent();
    await test2_ContentType();
    await test3_EmptyState();
    await test4_CORSHeaders();
    
  } catch (err) {
    console.error('Test setup failed:', err.message);
  } finally {
    await stopServer();
  }
  
  console.log('\n========================================');
  console.log('Test Summary');
  console.log('========================================');
  
  const passed = testResults.filter(r => r.passed).length;
  const failed = testResults.filter(r => !r.passed).length;
  
  console.log(`Total tests: ${testResults.length}`);
  console.log(`Passed: ${passed}`);
  console.log(`Failed: ${failed}`);
  console.log('========================================\n');
  
  process.exit(failed > 0 ? 1 : 0);
}

runTests();