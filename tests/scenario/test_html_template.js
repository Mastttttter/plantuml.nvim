#!/usr/bin/env node
/**
 * Test suite for HTML template with UI elements
 * Tests FR-2: HTML Template with UI Elements
 */

const http = require('http');
const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');

const TEST_DIR = '/tmp/plantuml.nvim';
const SERVER_PATH = path.join(__dirname, '..', 'server', 'server.js');
const TEST_PORT = 8921;

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

// Test 1: HTML structure
async function test1_HTMLStructure() {
  return new Promise((resolve) => {
    log('\nTest 1: HTML structure');
    
    const req = http.request({
      hostname: 'localhost',
      port: TEST_PORT,
      path: '/',
      method: 'GET'
    }, (res) => {
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      
      res.on('end', () => {
        const statusOk = res.statusCode === 200;
        const hasDoctype = data.includes('<!DOCTYPE html>');
        const hasHtmlTag = data.includes('<html');
        const hasHeadTag = data.includes('<head>');
        const hasBodyTag = data.includes('<body>');
        const hasContentType = res.headers['content-type'] === 'text/html';
        
        recordTest('GET / returns 200', statusOk);
        recordTest('Response has DOCTYPE html', hasDoctype);
        recordTest('Response has html tag', hasHtmlTag);
        recordTest('Response has head tag', hasHeadTag);
        recordTest('Response has body tag', hasBodyTag);
        recordTest('Response has content-type text/html', hasContentType);
        
        resolve(statusOk && hasDoctype && hasHtmlTag && hasHeadTag && hasBodyTag);
      });
    });
    
    req.on('error', (err) => {
      recordTest('HTML structure test', false, err.message);
      resolve(false);
    });
    
    req.end();
  });
}

// Test 2: Title element with filename
async function test2_TitleElement() {
  return new Promise((resolve) => {
    log('\nTest 2: Title element with filename');
    
    // First, set state with a filename
    const testFile = path.join(TEST_DIR, 'test-title.svg');
    fs.writeFileSync(testFile, '<svg>test</svg>');
    
    const postData = JSON.stringify({
      filename: 'test-title.puml',
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
        // Now get the HTML
        const req2 = http.request({
          hostname: 'localhost',
          port: TEST_PORT,
          path: '/',
          method: 'GET'
        }, (res) => {
          let html = '';
          res.on('data', (chunk) => { html += chunk; });
          res.on('end', () => {
            const hasTitleTag = html.includes('<title>');
            const hasFilename = html.includes('test-title.puml');
            
            recordTest('HTML has title tag', hasTitleTag);
            recordTest('Title contains filename', hasFilename);
            
            try {
              fs.unlinkSync(testFile);
            } catch (e) {}
            
            resolve(hasTitleTag && hasFilename);
          });
        });
        
        req2.on('error', (err) => {
          recordTest('Title element test', false, err.message);
          try {
            fs.unlinkSync(testFile);
          } catch (e) {}
          resolve(false);
        });
        
        req2.end();
      });
    });
    
    req1.on('error', (err) => {
      recordTest('Title element test', false, err.message);
      try {
        fs.unlinkSync(testFile);
      } catch (e) {}
      resolve(false);
    });
    
    req1.write(postData);
    req1.end();
  });
}

// Test 3: SVG container
async function test3_SVGContainer() {
  return new Promise((resolve) => {
    log('\nTest 3: Centered SVG container');
    
    const req = http.request({
      hostname: 'localhost',
      port: TEST_PORT,
      path: '/',
      method: 'GET'
    }, (res) => {
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      
      res.on('end', () => {
        const hasSvgContainer = data.includes('id="svg-container"') || data.includes('id=\'svg-container\'');
        const hasCenteringStyle = data.includes('text-align: center') || data.includes('align-items: center') || data.includes('margin: auto');
        
        recordTest('HTML has SVG container element', hasSvgContainer);
        recordTest('SVG container has centering styles', hasCenteringStyle);
        
        resolve(hasSvgContainer && hasCenteringStyle);
      });
    });
    
    req.on('error', (err) => {
      recordTest('SVG container test', false, err.message);
      resolve(false);
    });
    
    req.end();
  });
}

// Test 4: Time display
async function test4_TimeDisplay() {
  return new Promise((resolve) => {
    log('\nTest 4: Time display');
    
    const req = http.request({
      hostname: 'localhost',
      port: TEST_PORT,
      path: '/',
      method: 'GET'
    }, (res) => {
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      
      res.on('end', () => {
        const hasTimeElement = data.includes('id="time-display"') || data.includes('id=\'time-display\'') || data.includes('id="last-update"');
        
        recordTest('HTML has time display element', hasTimeElement);
        
        resolve(hasTimeElement);
      });
    });
    
    req.on('error', (err) => {
      recordTest('Time display test', false, err.message);
      resolve(false);
    });
    
    req.end();
  });
}

// Test 5: Save reminder
async function test5_SaveReminder() {
  return new Promise((resolve) => {
    log('\nTest 5: Save reminder text');
    
    const req = http.request({
      hostname: 'localhost',
      port: TEST_PORT,
      path: '/',
      method: 'GET'
    }, (res) => {
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      
      res.on('end', () => {
        const hasSaveText = data.toLowerCase().includes('save') && (data.toLowerCase().includes('buffer') || data.toLowerCase().includes('update'));
        
        recordTest('HTML has save reminder text', hasSaveText);
        
        resolve(hasSaveText);
      });
    });
    
    req.on('error', (err) => {
      recordTest('Save reminder test', false, err.message);
      resolve(false);
    });
    
    req.end();
  });
}

// Test 6: EventSource connection
async function test6_EventSourceConnection() {
  return new Promise((resolve) => {
    log('\nTest 6: EventSource connection code');
    
    const req = http.request({
      hostname: 'localhost',
      port: TEST_PORT,
      path: '/',
      method: 'GET'
    }, (res) => {
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      
      res.on('end', () => {
        const hasEventSource = data.includes('EventSource') || data.includes('/events');
        const hasScriptTag = data.includes('<script>');
        
        recordTest('HTML has JavaScript code', hasScriptTag);
        recordTest('JavaScript includes EventSource or /events endpoint', hasEventSource);
        
        resolve(hasEventSource && hasScriptTag);
      });
    });
    
    req.on('error', (err) => {
      recordTest('EventSource connection test', false, err.message);
      resolve(false);
    });
    
    req.end();
  });
}

async function runTests() {
  console.log('========================================');
  console.log('HTML Template Tests (FR-2)');
  console.log('========================================');
  
  try {
    if (!fs.existsSync(TEST_DIR)) {
      fs.mkdirSync(TEST_DIR, { recursive: true });
    }
    
    await startServer();
    await sleep(500);
    
    await test1_HTMLStructure();
    await test2_TitleElement();
    await test3_SVGContainer();
    await test4_TimeDisplay();
    await test5_SaveReminder();
    await test6_EventSourceConnection();
    
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