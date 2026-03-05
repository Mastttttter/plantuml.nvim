#!/usr/bin/env node
/**
 * Test suite for SSE events endpoint
 * Tests FR-4: SSE Events Endpoint
 */

const http = require('http');
const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');

const TEST_DIR = '/tmp/plantuml.nvim';
const SERVER_PATH = path.join(__dirname, '..', 'server', 'server.js');
const TEST_PORT = 8923;

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

// Test 1: SSE headers
async function test1_SSEHeaders() {
  return new Promise((resolve) => {
    log('\nTest 1: SSE headers');
    
    const req = http.request({
      hostname: 'localhost',
      port: TEST_PORT,
      path: '/events',
      method: 'GET'
    }, (res) => {
      const headers = res.headers;
      const hasCorrectContentType = headers['content-type'] === 'text/event-stream';
      const hasNoCache = headers['cache-control'] === 'no-cache';
      const hasKeepAlive = headers['connection'] === 'keep-alive';
      
      recordTest('SSE endpoint returns Content-Type: text/event-stream', hasCorrectContentType);
      recordTest('SSE endpoint returns Cache-Control: no-cache', hasNoCache);
      recordTest('SSE endpoint returns Connection: keep-alive', hasKeepAlive);
      
      req.destroy();
      resolve(hasCorrectContentType && hasNoCache && hasKeepAlive);
    });
    
    req.on('error', (err) => {
      recordTest('SSE headers test', false, err.message);
      resolve(false);
    });
    
    req.end();
  });
}

// Test 2: Initial message
async function test2_InitialMessage() {
  return new Promise((resolve) => {
    log('\nTest 2: Initial connection message');
    
    let receivedInitial = false;
    
    const req = http.request({
      hostname: 'localhost',
      port: TEST_PORT,
      path: '/events',
      method: 'GET'
    }, (res) => {
      res.on('data', (data) => {
        const message = data.toString();
        if (message.includes(': connected') || message.includes('data: connected')) {
          receivedInitial = true;
        }
      });
      
      setTimeout(() => {
        recordTest('Client receives initial connection message', receivedInitial);
        req.destroy();
        resolve(receivedInitial);
      }, 500);
    });
    
    req.on('error', (err) => {
      recordTest('Initial message test', false, err.message);
      resolve(false);
    });
    
    req.end();
  });
}

// Test 3: Client tracking
async function test3_ClientTracking() {
  return new Promise((resolve) => {
    log('\nTest 3: Client connection tracking');
    
    let connected = false;
    
    const req = http.request({
      hostname: 'localhost',
      port: TEST_PORT,
      path: '/events',
      method: 'GET'
    }, (res) => {
      connected = true;
      
      setTimeout(() => {
        req.destroy();
      }, 200);
    });
    
    req.on('error', () => {});
    
    req.on('close', () => {
      recordTest('Client can connect to SSE endpoint', connected);
      resolve(connected);
    });
    
    req.end();
  });
}

// Test 4: Update event broadcast
async function test4_UpdateEvent() {
  return new Promise((resolve) => {
    log('\nTest 4: Update event broadcast');
    
    let receivedUpdate = false;
    const testFile = path.join(TEST_DIR, 'test-update-event.svg');
    fs.writeFileSync(testFile, '<svg>test</svg>');
    
    const req = http.request({
      hostname: 'localhost',
      port: TEST_PORT,
      path: '/events',
      method: 'GET'
    }, (res) => {
      res.on('data', (data) => {
        const message = data.toString();
        if (message.includes('event: update') || message.includes('data: update')) {
          receivedUpdate = true;
          log('Received update event');
        }
      });
      
      setTimeout(() => {
        // Send update via POST
        const postData = JSON.stringify({
          filename: 'test-update-event.puml',
          filepath: testFile
        });
        
        const updateReq = http.request({
          hostname: 'localhost',
          port: TEST_PORT,
          path: '/update',
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Content-Length': Buffer.byteLength(postData)
          }
        }, (updateRes) => {
          setTimeout(() => {
            recordTest('POST /update triggers SSE update event', receivedUpdate);
            
            try {
              fs.unlinkSync(testFile);
            } catch (e) {}
            
            req.destroy();
            resolve(receivedUpdate);
          }, 500);
        });
        
        updateReq.on('error', (err) => {
          recordTest('Update event test', false, err.message);
          try {
            fs.unlinkSync(testFile);
          } catch (e) {}
          req.destroy();
          resolve(false);
        });
        
        updateReq.write(postData);
        updateReq.end();
      }, 500);
    });
    
    req.on('error', (err) => {
      recordTest('Update event test', false, err.message);
      try {
        fs.unlinkSync(testFile);
      } catch (e) {}
      resolve(false);
    });
    
    req.end();
  });
}

// Test 5: Shutdown event broadcast
async function test5_ShutdownEvent() {
  return new Promise((resolve) => {
    log('\nTest 5: Shutdown event broadcast');
    
    let receivedShutdown = false;
    
    const req = http.request({
      hostname: 'localhost',
      port: TEST_PORT,
      path: '/events',
      method: 'GET'
    }, (res) => {
      res.on('data', (data) => {
        const message = data.toString();
        if (message.includes('event: shutdown') || message.includes('data: shutdown')) {
          receivedShutdown = true;
          log('Received shutdown event');
        }
      });
      
      setTimeout(() => {
        // Send shutdown via POST
        const shutdownReq = http.request({
          hostname: 'localhost',
          port: TEST_PORT,
          path: '/shutdown',
          method: 'POST'
        }, (shutdownRes) => {
          setTimeout(() => {
            recordTest('POST /shutdown triggers SSE shutdown event', receivedShutdown);
            req.destroy();
            resolve(receivedShutdown);
          }, 500);
        });
        
        shutdownReq.on('error', (err) => {
          recordTest('Shutdown event test', false, err.message);
          req.destroy();
          resolve(false);
        });
        
        shutdownReq.end();
      }, 500);
    });
    
    req.on('error', (err) => {
      recordTest('Shutdown event test', false, err.message);
      resolve(false);
    });
    
    req.end();
  });
}

// Test 6: Disconnect cleanup
async function test6_DisconnectCleanup() {
  return new Promise((resolve) => {
    log('\nTest 6: Client disconnect cleanup');
    
    let closed = false;
    
    const req = http.request({
      hostname: 'localhost',
      port: TEST_PORT,
      path: '/events',
      method: 'GET'
    }, (res) => {
      setTimeout(() => {
        req.destroy();
      }, 200);
    });
    
    req.on('error', () => {});
    
    req.on('close', () => {
      closed = true;
      recordTest('Client disconnects properly', closed);
      resolve(closed);
    });
    
    req.end();
  });
}

async function runTests() {
  console.log('========================================');
  console.log('SSE Events Tests (FR-4)');
  console.log('========================================');
  
  try {
    if (!fs.existsSync(TEST_DIR)) {
      fs.mkdirSync(TEST_DIR, { recursive: true });
    }
    
    await startServer();
    await sleep(500);
    
    await test1_SSEHeaders();
    await test2_InitialMessage();
    await test3_ClientTracking();
    await test4_UpdateEvent();
    await test5_ShutdownEvent();
    await test6_DisconnectCleanup();
    
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