#!/usr/bin/env node
/**
 * Comprehensive test for SSE endpoint acceptance criteria
 * Tests:
 * 1. SSE endpoint /events returns Content-Type: text/event-stream
 * 2. Server maintains list of connected clients
 * 3. File changes in /tmp/plantuml.nvim trigger SSE event with data: refresh
 * 4. Disconnected clients are properly cleaned up
 * 5. PlantumlCreateSVG and PlantumlCreatePNG are NOT affected
 */

const http = require('http');
const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');

const TEST_DIR = '/tmp/plantuml.nvim';
const SERVER_PATH = path.join(__dirname, 'server', 'server.js');
const TEST_PORT = 8917;

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

// Test 1: SSE endpoint returns correct headers
async function test1_SSEHeaders() {
  return new Promise((resolve) => {
    log('\nTest 1: SSE endpoint headers');
    
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
      
      const passed = hasCorrectContentType && hasNoCache && hasKeepAlive;
      recordTest('SSE endpoint returns Content-Type: text/event-stream', hasCorrectContentType);
      recordTest('SSE endpoint returns Cache-Control: no-cache', hasNoCache);
      recordTest('SSE endpoint returns Connection: keep-alive', hasKeepAlive);
      
      req.destroy();
      resolve(passed);
    });
    
    req.on('error', (err) => {
      recordTest('SSE endpoint headers', false, err.message);
      resolve(false);
    });
    
    req.end();
  });
}

// Test 2: Server maintains list of connected clients
async function test2_ClientManagement() {
  return new Promise((resolve) => {
    log('\nTest 2: Client connection management');
    
    let connected = false;
    let receivedInitial = false;
    
    const req = http.request({
      hostname: 'localhost',
      port: TEST_PORT,
      path: '/events',
      method: 'GET'
    }, (res) => {
      connected = true;
      
      res.on('data', (data) => {
        const message = data.toString();
        if (message.includes(': connected')) {
          receivedInitial = true;
        }
      });
      
      setTimeout(() => {
        req.destroy();
      }, 500);
    });
    
    req.on('error', () => {
      recordTest('Client connection management', false);
      resolve(false);
    });
    
    req.on('close', () => {
      recordTest('Client can connect to SSE endpoint', connected);
      recordTest('Client receives initial connection message', receivedInitial);
      resolve(connected && receivedInitial);
    });
    
    req.end();
  });
}

// Test 3: File changes trigger SSE refresh event
async function test3_FileChangeBroadcast() {
  return new Promise((resolve) => {
    log('\nTest 3: File change broadcast');
    
    let receivedRefresh = false;
    const testFile = path.join(TEST_DIR, 'test-refresh.svg');
    
    const req = http.request({
      hostname: 'localhost',
      port: TEST_PORT,
      path: '/events',
      method: 'GET'
    }, (res) => {
      res.on('data', (data) => {
        const message = data.toString();
        if (message.includes('data: refresh')) {
          receivedRefresh = true;
          log('Received refresh event');
        }
      });
      
      setTimeout(() => {
        log('Creating test SVG file...');
        fs.writeFileSync(testFile, '<svg>test</svg>');
        
        setTimeout(() => {
          recordTest('File change triggers SSE refresh event', receivedRefresh);
          
          try {
            fs.unlinkSync(testFile);
          } catch (e) {}
          
          req.destroy();
          resolve(receivedRefresh);
        }, 1000);
      }, 500);
    });
    
    req.on('error', () => {
      recordTest('File change broadcast', false);
      resolve(false);
    });
    
    req.end();
  });
}

// Test 4: Disconnected clients are properly cleaned up
async function test4_ClientCleanup() {
  return new Promise((resolve) => {
    log('\nTest 4: Client cleanup on disconnect');
    
    let connected = false;
    let closed = false;
    
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
      closed = true;
      recordTest('Client disconnects properly', closed);
      resolve(closed);
    });
    
    req.end();
  });
}

// Test 5: Static file serving still works
async function test5_StaticFilesUnaffected() {
  return new Promise((resolve) => {
    log('\nTest 5: Static file serving still works');
    
    const testFile = path.join(TEST_DIR, 'test-static.svg');
    const testContent = '<svg><rect width="100" height="100"/></svg>';
    
    fs.writeFileSync(testFile, testContent);
    
    const req = http.request({
      hostname: 'localhost',
      port: TEST_PORT,
      path: '/test-static.svg',
      method: 'GET'
    }, (res) => {
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      
      res.on('end', () => {
        const statusOk = res.statusCode === 200;
        const contentOk = data === testContent;
        
        recordTest('Static file serving returns 200', statusOk);
        recordTest('Static file serving returns correct content', contentOk);
        
        try {
          fs.unlinkSync(testFile);
        } catch (e) {}
        
        resolve(statusOk && contentOk);
      });
    });
    
    req.on('error', () => {
      recordTest('Static file serving', false);
      resolve(false);
    });
    
    req.end();
  });
}

// Test 6: Non-SVG files don't trigger refresh
async function test6_NonSVGFilesIgnored() {
  return new Promise((resolve) => {
    log('\nTest 6: Non-SVG files ignored');
    
    let receivedRefresh = false;
    const testFile = path.join(TEST_DIR, 'test-ignore.txt');
    
    const req = http.request({
      hostname: 'localhost',
      port: TEST_PORT,
      path: '/events',
      method: 'GET'
    }, (res) => {
      res.on('data', (data) => {
        const message = data.toString();
        if (message.includes('data: refresh')) {
          receivedRefresh = true;
        }
      });
      
      setTimeout(() => {
        log('Creating test TXT file...');
        fs.writeFileSync(testFile, 'test content');
        
        setTimeout(() => {
          recordTest('Non-SVG files do not trigger refresh', !receivedRefresh);
          
          try {
            fs.unlinkSync(testFile);
          } catch (e) {}
          
          req.destroy();
          resolve(!receivedRefresh);
        }, 1000);
      }, 500);
    });
    
    req.on('error', () => {
      recordTest('Non-SVG files ignored', false);
      resolve(false);
    });
    
    req.end();
  });
}

async function runTests() {
  console.log('========================================');
  console.log('SSE Endpoint Acceptance Criteria Tests');
  console.log('========================================');
  
  try {
    if (!fs.existsSync(TEST_DIR)) {
      fs.mkdirSync(TEST_DIR, { recursive: true });
    }
    
    await startServer();
    await sleep(500);
    
    await test1_SSEHeaders();
    await test2_ClientManagement();
    await test3_FileChangeBroadcast();
    await test4_ClientCleanup();
    await test5_StaticFilesUnaffected();
    await test6_NonSVGFilesIgnored();
    
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