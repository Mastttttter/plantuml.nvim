#!/usr/bin/env node
/**
 * Comprehensive test for new server architecture
 * Tests all functional requirements: FR-1 through FR-7
 */

const http = require('http');
const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');

const TEST_DIR = '/tmp/plantuml.nvim';
const SERVER_PATH = path.join(__dirname, '..', '..', 'server', 'server.js');
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
      console.log('Server stdout:', output);
      if (output.includes(`PORT:${TEST_PORT}`)) {
        if (!resolved) {
          resolved = true;
          resolve();
        }
      }
    });
    
    serverProcess.stderr.on('data', (data) => {
      console.error('Server stderr:', data.toString());
    });
    
    serverProcess.on('error', (err) => {
      reject(new Error(`Failed to start server: ${err.message}`));
    });
    
    setTimeout(() => {
      if (!resolved) {
        reject(new Error('Server startup timeout'));
      }
    }, 5000);
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

function makeRequest(options, body = null) {
  return new Promise((resolve, reject) => {
    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => { data += chunk; });
      res.on('end', () => {
        resolve({ statusCode: res.statusCode, headers: res.headers, body: data });
      });
    });
    
    req.on('error', reject);
    
    if (body) {
      req.write(body);
    }
    req.end();
  });
}

// FR-1: State Management Tests
async function testStateManagement() {
  log('\n=== FR-1: State Management ===');
  
  // Test 1: Initial state is empty
  const res1 = await makeRequest({
    hostname: 'localhost',
    port: TEST_PORT,
    path: '/svg',
    method: 'GET'
  });
  recordTest('FR-1.1: Initial GET /svg returns 200', res1.statusCode === 200);
  recordTest('FR-1.2: Initial state has empty SVG content', res1.body === '');
  
  // Test 2: Update state via POST /update
  const testFile = path.join(TEST_DIR, 'test-state.svg');
  fs.writeFileSync(testFile, TEST_SVG);
  
  const postData = JSON.stringify({
    filename: 'test-state.puml',
    filepath: testFile
  });
  
  const res2 = await makeRequest({
    hostname: 'localhost',
    port: TEST_PORT,
    path: '/update',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(postData)
    }
  }, postData);
  
  recordTest('FR-1.3: POST /update returns 200', res2.statusCode === 200);
  
  // Test 3: State persists and can be retrieved
  const res3 = await makeRequest({
    hostname: 'localhost',
    port: TEST_PORT,
    path: '/svg',
    method: 'GET'
  });
  
  recordTest('FR-1.4: GET /svg returns updated SVG content', res3.body === TEST_SVG);
  
  try {
    fs.unlinkSync(testFile);
  } catch (e) {}
}

// FR-2: HTML Template Tests
async function testHTMLTemplate() {
  log('\n=== FR-2: HTML Template ===');
  
  const res = await makeRequest({
    hostname: 'localhost',
    port: TEST_PORT,
    path: '/',
    method: 'GET'
  });
  
  recordTest('FR-2.1: GET / returns 200', res.statusCode === 200);
  recordTest('FR-2.2: Response has content-type text/html', res.headers['content-type'] === 'text/html');
  recordTest('FR-2.3: HTML has DOCTYPE', res.body.includes('<!DOCTYPE html>'));
  recordTest('FR-2.4: HTML has title element', res.body.includes('<title>'));
  recordTest('FR-2.5: HTML has SVG container', res.body.includes('svg-container'));
  recordTest('FR-2.6: HTML has time display', res.body.includes('time') || res.body.includes('update'));
  recordTest('FR-2.7: HTML has save reminder text', res.body.toLowerCase().includes('save'));
  recordTest('FR-2.8: HTML has EventSource code', res.body.includes('EventSource') || res.body.includes('/events'));
}

// FR-3: SVG Endpoint Tests
async function testSVGEndpoint() {
  log('\n=== FR-3: SVG Endpoint ===');
  
  const res = await makeRequest({
    hostname: 'localhost',
    port: TEST_PORT,
    path: '/svg',
    method: 'GET'
  });
  
  recordTest('FR-3.1: GET /svg returns correct content-type', res.headers['content-type'] === 'image/svg+xml');
  recordTest('FR-3.2: GET /svg has CORS headers', res.headers['access-control-allow-origin'] === '*');
}

// FR-4: SSE Events Tests
async function testSSEEvents() {
  log('\n=== FR-4: SSE Events ===');
  
  // Test SSE connection
  let sseConnected = false;
  let receivedInitial = false;
  let receivedUpdate = false;
  
  const sseReq = http.request({
    hostname: 'localhost',
    port: TEST_PORT,
    path: '/events',
    method: 'GET'
  }, (res) => {
    sseConnected = true;
    
    // Check headers
    const hasCorrectContentType = res.headers['content-type'] === 'text/event-stream';
    const hasNoCache = res.headers['cache-control'] === 'no-cache';
    const hasKeepAlive = res.headers['connection'] === 'keep-alive';
    
    recordTest('FR-4.1: SSE has correct content-type', hasCorrectContentType);
    recordTest('FR-4.2: SSE has no-cache header', hasNoCache);
    recordTest('FR-4.3: SSE has keep-alive header', hasKeepAlive);
    
    res.on('data', (data) => {
      const message = data.toString();
      if (message.includes('connected')) {
        receivedInitial = true;
      }
      if (message.includes('update')) {
        receivedUpdate = true;
      }
    });
  });
  
  sseReq.on('error', (err) => {
    log('SSE connection error: ' + err.message);
  });
  
  sseReq.end();
  
  await sleep(500);
  recordTest('FR-4.4: SSE client can connect', sseConnected);
  recordTest('FR-4.5: SSE client receives initial message', receivedInitial);
  
  // Test update event broadcast
  const testFile = path.join(TEST_DIR, 'test-sse-update.svg');
  fs.writeFileSync(testFile, TEST_SVG);
  
  const postData = JSON.stringify({
    filename: 'test-sse-update.puml',
    filepath: testFile
  });
  
  await makeRequest({
    hostname: 'localhost',
    port: TEST_PORT,
    path: '/update',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(postData)
    }
  }, postData);
  
  await sleep(500);
  recordTest('FR-4.6: POST /update broadcasts update event', receivedUpdate);
  
  try {
    fs.unlinkSync(testFile);
  } catch (e) {}
  
  sseReq.destroy();
}

// FR-5: Update Notification Tests
async function testUpdateNotification() {
  log('\n=== FR-5: Update Notification ===');
  
  const testFile = path.join(TEST_DIR, 'test-notification.svg');
  fs.writeFileSync(testFile, TEST_SVG);
  
  // Test with valid data
  const postData = JSON.stringify({
    filename: 'test-notification.puml',
    filepath: testFile
  });
  
  const res1 = await makeRequest({
    hostname: 'localhost',
    port: TEST_PORT,
    path: '/update',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(postData)
    }
  }, postData);
  
  recordTest('FR-5.1: POST /update accepts JSON body', res1.statusCode === 200);
  
  // Test with missing fields
  const res2 = await makeRequest({
    hostname: 'localhost',
    port: TEST_PORT,
    path: '/update',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': 2
    }
  }, '{}');
  
  recordTest('FR-5.2: POST /update returns 400 for missing fields', res2.statusCode === 400);
  
  // Test with non-existent file
  const res3 = await makeRequest({
    hostname: 'localhost',
    port: TEST_PORT,
    path: '/update',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(JSON.stringify({
        filename: 'nonexistent.puml',
        filepath: '/tmp/nonexistent.svg'
      }))
    }
  }, JSON.stringify({
    filename: 'nonexistent.puml',
    filepath: '/tmp/nonexistent.svg'
  }));
  
  recordTest('FR-5.3: POST /update returns 404 for non-existent file', res3.statusCode === 404);
  
  try {
    fs.unlinkSync(testFile);
  } catch (e) {}
}

// FR-6: Shutdown Notification Tests
async function testShutdownNotification() {
  log('\n=== FR-6: Shutdown Notification ===');
  
  let receivedShutdown = false;
  
  // Connect SSE client
  const sseReq = http.request({
    hostname: 'localhost',
    port: TEST_PORT,
    path: '/events',
    method: 'GET'
  }, (res) => {
    res.on('data', (data) => {
      const message = data.toString();
      if (message.includes('shutdown')) {
        receivedShutdown = true;
      }
    });
  });
  
  sseReq.on('error', () => {});
  sseReq.end();
  
  await sleep(500);
  
  // Trigger shutdown
  const res = await makeRequest({
    hostname: 'localhost',
    port: TEST_PORT,
    path: '/shutdown',
    method: 'POST'
  });
  
  recordTest('FR-6.1: POST /shutdown returns 200', res.statusCode === 200);
  
  await sleep(500);
  recordTest('FR-6.2: POST /shutdown broadcasts shutdown event', receivedShutdown);
  
  sseReq.destroy();
}

// FR-7: Remove File Watcher Tests
async function testRemoveFileWatcher() {
  log('\n=== FR-7: Remove File Watcher ===');
  
  // Read server.js content
  const serverContent = fs.readFileSync(SERVER_PATH, 'utf8');
  
  recordTest('FR-7.1: No fs.watch in server.js', !serverContent.includes('fs.watch(') && !serverContent.includes('fs.watchFile('));
  recordTest('FR-7.2: No startFileWatcher function', !serverContent.includes('function startFileWatcher'));
  recordTest('FR-7.3: No fileWatcher variable', !serverContent.includes('let fileWatcher') && !serverContent.includes('var fileWatcher'));
}

async function runTests() {
  console.log('========================================');
  console.log('Server Architecture Tests');
  console.log('Testing FR-1 through FR-7');
  console.log('========================================');
  
  try {
    if (!fs.existsSync(TEST_DIR)) {
      fs.mkdirSync(TEST_DIR, { recursive: true });
    }
    
    await startServer();
    await sleep(1000);
    
    await testStateManagement();
    await testHTMLTemplate();
    await testSVGEndpoint();
    await testSSEEvents();
    await testUpdateNotification();
    await testShutdownNotification();
    await testRemoveFileWatcher();
    
  } catch (err) {
    console.error('Test setup failed:', err.message);
    console.error(err.stack);
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
  
  if (failed > 0) {
    console.log('\nFailed tests:');
    testResults.filter(r => !r.passed).forEach(r => {
      console.log(`  - ${r.name}${r.details ? `: ${r.details}` : ''}`);
    });
  }
  
  console.log('========================================\n');
  
  process.exit(failed > 0 ? 1 : 0);
}

runTests();