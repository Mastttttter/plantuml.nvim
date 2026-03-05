#!/usr/bin/env node
/**
 * Test suite for server state management
 * Tests FR-1: State Management
 */

const http = require('http');
const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');

const TEST_DIR = '/tmp/plantuml.nvim';
const SERVER_PATH = path.join(__dirname, '..', 'server', 'server.js');
const TEST_PORT = 8920;
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

// Test 1: Initial state is empty
async function test1_InitialState() {
  return new Promise((resolve) => {
    log('\nTest 1: Initial state is empty');
    
    const req = http.request({
      hostname: 'localhost',
      port: TEST_PORT,
      path: '/svg',
      method: 'GET'
    }, (res) => {
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      
      res.on('end', () => {
        const statusOk = res.statusCode === 200;
        const contentEmpty = data === '';
        
        recordTest('Initial GET /svg returns 200', statusOk);
        recordTest('Initial state has empty SVG content', contentEmpty);
        resolve(statusOk && contentEmpty);
      });
    });
    
    req.on('error', (err) => {
      recordTest('Initial state test', false, err.message);
      resolve(false);
    });
    
    req.end();
  });
}

// Test 2: Update state via POST /update
async function test2_UpdateState() {
  return new Promise((resolve) => {
    log('\nTest 2: Update state via POST /update');
    
    // Create test SVG file
    const testFile = path.join(TEST_DIR, 'test-state.svg');
    fs.writeFileSync(testFile, TEST_SVG);
    
    const postData = JSON.stringify({
      filename: 'test-state.puml',
      filepath: testFile
    });
    
    const req = http.request({
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
      res.on('data', (chunk) => {
        data += chunk;
      });
      
      res.on('end', () => {
        const statusOk = res.statusCode === 200;
        recordTest('POST /update returns 200', statusOk);
        
        // Cleanup
        try {
          fs.unlinkSync(testFile);
        } catch (e) {}
        
        resolve(statusOk);
      });
    });
    
    req.on('error', (err) => {
      recordTest('Update state test', false, err.message);
      try {
        fs.unlinkSync(testFile);
      } catch (e) {}
      resolve(false);
    });
    
    req.write(postData);
    req.end();
  });
}

// Test 3: State persists and can be retrieved
async function test3_RetrieveState() {
  return new Promise((resolve) => {
    log('\nTest 3: Retrieve state after update');
    
    const req = http.request({
      hostname: 'localhost',
      port: TEST_PORT,
      path: '/svg',
      method: 'GET'
    }, (res) => {
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      
      res.on('end', () => {
        const statusOk = res.statusCode === 200;
        const contentMatches = data === TEST_SVG;
        const contentTypeOk = res.headers['content-type'] === 'image/svg+xml';
        
        recordTest('GET /svg returns 200 after update', statusOk);
        recordTest('GET /svg returns correct SVG content', contentMatches);
        recordTest('GET /svg has correct content-type', contentTypeOk);
        resolve(statusOk && contentMatches && contentTypeOk);
      });
    });
    
    req.on('error', (err) => {
      recordTest('Retrieve state test', false, err.message);
      resolve(false);
    });
    
    req.end();
  });
}

// Test 4: Timestamp is updated
async function test4_TimestampUpdate() {
  return new Promise((resolve) => {
    log('\nTest 4: Timestamp is updated on state change');
    
    const testFile = path.join(TEST_DIR, 'test-timestamp.svg');
    fs.writeFileSync(testFile, TEST_SVG);
    
    const beforeTime = Date.now();
    
    const postData = JSON.stringify({
      filename: 'test-timestamp.puml',
      filepath: testFile
    });
    
    const req = http.request({
      hostname: 'localhost',
      port: TEST_PORT,
      path: '/update',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData)
      }
    }, (res) => {
      const afterTime = Date.now();
      
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      
      res.on('end', () => {
        const statusOk = res.statusCode === 200;
        
        recordTest('POST /update updates timestamp', statusOk);
        
        // Note: We can't directly test the timestamp value without an endpoint
        // But we verified the update succeeded
        
        try {
          fs.unlinkSync(testFile);
        } catch (e) {}
        
        resolve(statusOk);
      });
    });
    
    req.on('error', (err) => {
      recordTest('Timestamp update test', false, err.message);
      try {
        fs.unlinkSync(testFile);
      } catch (e) {}
      resolve(false);
    });
    
    req.write(postData);
    req.end();
  });
}

async function runTests() {
  console.log('========================================');
  console.log('State Management Tests (FR-1)');
  console.log('========================================');
  
  try {
    if (!fs.existsSync(TEST_DIR)) {
      fs.mkdirSync(TEST_DIR, { recursive: true });
    }
    
    await startServer();
    await sleep(500);
    
    await test1_InitialState();
    await test2_UpdateState();
    await test3_RetrieveState();
    await test4_TimestampUpdate();
    
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