#!/usr/bin/env node
/**
 * HTTP notification server for PlantUML preview
 * 
 * This server provides:
 * - HTML page with SVG preview at GET /
 * - Cached SVG content at GET /svg
 * - Real-time updates via SSE at GET /events
 * - Update notifications via POST /update
 * - Shutdown notifications via POST /shutdown
 * 
 * Architecture: HTTP notification instead of file watching
 */

const http = require('http');
const fs = require('fs');
const path = require('path');

const SERVE_DIR = '/tmp/plantuml.nvim';
const DEFAULT_PORT = 8912;
const MAX_PORT = 8940; // Allow trying up to 28 ports (8912-8940)

// MIME types for common file formats
const MIME_TYPES = {
  '.svg': 'image/svg+xml',
  '.png': 'image/png',
  '.html': 'text/html',
  '.css': 'text/css',
  '.js': 'application/javascript',
  '.json': 'application/json',
  '.txt': 'text/plain',
  '.utxt': 'text/plain',
};

// Connected SSE clients
const sseClients = new Set();

// Server state
const state = {
  filename: null,
  svgContent: '',
  lastUpdate: null
};

// Get port from command line argument
let port = DEFAULT_PORT;
const portIndex = process.argv.indexOf('--port');
if (portIndex !== -1 && process.argv[portIndex + 1]) {
  port = parseInt(process.argv[portIndex + 1], 10);
}

/**
 * Get MIME type for a file extension
 * @param {string} ext - File extension (with dot)
 * @returns {string} MIME type
 */
function getMimeType(ext) {
  return MIME_TYPES[ext.toLowerCase()] || 'application/octet-stream';
}

/**
 * Generate HTML page with filename title, centered SVG container, time display, and save reminder
 * @returns {string} HTML content
 */
function generateHTML() {
  const filename = state.filename || 'PlantUML Preview';
  
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${filename}</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      margin: 0;
      padding: 20px;
      background-color: #f5f5f5;
    }
    .header {
      text-align: center;
      margin-bottom: 20px;
    }
    .filename {
      font-size: 24px;
      font-weight: bold;
      color: #333;
      margin-bottom: 10px;
    }
    .time-display {
      font-size: 14px;
      color: #666;
      margin-bottom: 10px;
    }
    .reminder {
      font-size: 14px;
      color: #888;
      font-style: italic;
    }
    #svg-container {
      text-align: center;
      margin-top: 20px;
    }
    #svg-container svg {
      max-width: 100%;
      height: auto;
      background-color: white;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    }
  </style>
</head>
<body>
  <div class="header">
    <div class="filename">${filename}</div>
    <div class="time-display" id="last-update">Last update: <span id="time-value">Never</span></div>
    <div class="reminder">💾 Save your buffer to automatically update the diagram</div>
  </div>
  <div id="svg-container">
    ${state.svgContent}
  </div>
  
  <script>
    // Connect to SSE endpoint for real-time updates
    const eventSource = new EventSource('/events');
    
    eventSource.addEventListener('connected', function(e) {
      console.log('SSE connected');
    });
    
    eventSource.addEventListener('update', function(e) {
      console.log('Update event received');
      // Fetch updated SVG content
      fetch('/svg')
        .then(response => response.text())
        .then(svg => {
          document.getElementById('svg-container').innerHTML = svg;
          updateTime();
        })
        .catch(err => console.error('Failed to fetch SVG:', err));
    });
    
    eventSource.addEventListener('shutdown', function(e) {
      console.log('Shutdown event received');
      // Display friendly close message
      document.body.innerHTML = `
        <div style="display:flex;flex-direction:column;align-items:center;justify-content:center;height:100vh;background:#f5f5f5;font-family:Arial,sans-serif;">
          <div style="text-align:center;padding:40px;background:white;border-radius:10px;box-shadow:0 2px 10px rgba(0,0,0,0.1);">
            <h1 style="color:#333;margin-bottom:20px;">Preview Closed</h1>
            <p style="color:#666;margin-bottom:30px;">The Neovim preview has been stopped.</p>
            <p style="color:#999;font-size:14px;">You can safely close this tab.</p>
          </div>
        </div>
      `;
      // Try to close the window (may not work if not opened by script)
      setTimeout(function() {
        window.close();
      }, 100);
    });
    
    eventSource.onerror = function(e) {
      console.error('SSE error:', e);
    };
    
    function updateTime() {
      const now = new Date();
      const timeString = now.toLocaleTimeString();
      document.getElementById('time-value').textContent = timeString;
    }
    
    // Update time display every second
    setInterval(updateTime, 1000);
    updateTime();
  </script>
</body>
</html>`;
}

/**
 * Handle SSE client connection
 * @param {http.ServerResponse} res - HTTP response object
 */
function handleSSEConnection(res) {
  // Set SSE headers
  res.writeHead(200, {
    'Content-Type': 'text/event-stream',
    'Cache-Control': 'no-cache',
    'Connection': 'keep-alive',
    'Access-Control-Allow-Origin': '*',
  });

  // Send initial connection event
  res.write('event: connected\ndata: connected\n\n');

  // Add client to set
  sseClients.add(res);

  console.log(`SSE client connected. Total clients: ${sseClients.size}`);

  // Handle client disconnect
  res.on('close', () => {
    sseClients.delete(res);
    console.log(`SSE client disconnected. Total clients: ${sseClients.size}`);
  });
}

/**
 * Broadcast event to all connected SSE clients
 * @param {string} eventType - Event type (update or shutdown)
 * @param {string} data - Event data
 */
function broadcastEvent(eventType, data = '') {
  if (sseClients.size === 0) {
    return;
  }

  console.log(`Broadcasting ${eventType} to ${sseClients.size} clients`);

  const message = `event: ${eventType}\ndata: ${data}\n\n`;

  sseClients.forEach((client) => {
    try {
      client.write(message);
    } catch (err) {
      // Client might have disconnected, remove it
      sseClients.delete(client);
    }
  });
}

/**
 * Handle POST /update request to update state and notify clients
 * @param {http.IncomingMessage} req - HTTP request object
 * @param {http.ServerResponse} res - HTTP response object
 */
function handleUpdateRequest(req, res) {
  // Set CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  // Handle OPTIONS preflight
  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  // Only accept POST
  if (req.method !== 'POST') {
    res.writeHead(405);
    res.end('Method Not Allowed');
    return;
  }

  // Read request body
  let body = '';
  req.on('data', (chunk) => {
    body += chunk.toString();
  });

  req.on('end', () => {
    try {
      const data = JSON.parse(body);
      
      // Validate required fields
      if (!data.filename || !data.filepath) {
        res.writeHead(400);
        res.end('Bad Request: filename and filepath are required');
        return;
      }

      // Check if file exists
      if (!fs.existsSync(data.filepath)) {
        res.writeHead(404);
        res.end('Not Found: file does not exist');
        return;
      }

      // Read SVG content from file
      const svgContent = fs.readFileSync(data.filepath, 'utf8');
      
      // Update server state
      state.filename = data.filename;
      state.svgContent = svgContent;
      state.lastUpdate = Date.now();

      console.log(`State updated: ${data.filename}`);

      // Broadcast update event to all connected SSE clients
      broadcastEvent('update', data.filename);

      res.writeHead(200);
      res.end('OK');
    } catch (err) {
      console.error('Error handling update request:', err);
      res.writeHead(500);
      res.end('Internal Server Error');
    }
  });
}

/**
 * Handle POST /shutdown request to notify all clients
 * @param {http.IncomingMessage} req - HTTP request object
 * @param {http.ServerResponse} res - HTTP response object
 */
function handleShutdownRequest(req, res) {
  // Set CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  // Handle OPTIONS preflight
  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  // Only accept POST
  if (req.method !== 'POST') {
    res.writeHead(405);
    res.end('Method Not Allowed');
    return;
  }

  console.log('Shutdown request received');

  // Broadcast shutdown event to all connected SSE clients
  broadcastEvent('shutdown', 'server shutdown');

  res.writeHead(200);
  res.end('OK');
}

/**
 * Handle static file requests
 * @param {string} urlPath - URL path
 * @param {http.IncomingMessage} req - HTTP request object
 * @param {http.ServerResponse} res - HTTP response object
 */
function handleStaticFile(urlPath, req, res) {
  // Decode URL-encoded characters
  try {
    urlPath = decodeURIComponent(urlPath);
  } catch (e) {
    res.writeHead(400);
    res.end('Bad Request');
    return;
  }

  // Security: prevent directory traversal
  if (urlPath.includes('..')) {
    res.writeHead(403);
    res.end('Forbidden');
    return;
  }

  // Build file path
  let filePath = path.join(SERVE_DIR, urlPath);

  // If path is a directory, try index.html or return 404
  const stat = fs.statSync(filePath, { throwIfNoEntry: false });
  if (stat && stat.isDirectory()) {
    filePath = path.join(filePath, 'index.html');
  }

  // Check if file exists
  fs.access(filePath, fs.constants.R_OK, (err) => {
    if (err) {
      res.writeHead(404);
      res.end('Not Found');
      return;
    }

    // Get file extension and MIME type
    const ext = path.extname(filePath);
    const mimeType = getMimeType(ext);

    // Set CORS headers for local development
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

    // Handle OPTIONS preflight request
    if (req.method === 'OPTIONS') {
      res.writeHead(204);
      res.end();
      return;
    }

    // Set content type
    res.setHeader('Content-Type', mimeType);

    // Read and serve the file
    fs.readFile(filePath, (err, data) => {
      if (err) {
        res.writeHead(500);
        res.end('Internal Server Error');
        return;
      }

      res.writeHead(200);
      res.end(data);
    });
  });
}

/**
 * Create HTTP server with routing for special endpoints
 * @param {number} port - Port to listen on
 * @returns {http.Server} HTTP server instance
 */
function createServer(port) {
  const server = http.createServer((req, res) => {
    // Parse URL path (remove query string)
    const urlPath = req.url.split('?')[0];

    // Route to appropriate handler
    if (urlPath === '/' && req.method === 'GET') {
      // Serve HTML page
      res.setHeader('Content-Type', 'text/html');
      res.setHeader('Access-Control-Allow-Origin', '*');
      res.writeHead(200);
      res.end(generateHTML());
      return;
    }

    if (urlPath === '/svg' && req.method === 'GET') {
      // Serve cached SVG content from state
      res.setHeader('Content-Type', 'image/svg+xml');
      res.setHeader('Access-Control-Allow-Origin', '*');
      res.writeHead(200);
      res.end(state.svgContent);
      return;
    }

    if (urlPath === '/events' && req.method === 'GET') {
      // Handle SSE connection
      handleSSEConnection(res);
      return;
    }

    if (urlPath === '/update') {
      // Handle update notification
      handleUpdateRequest(req, res);
      return;
    }

    if (urlPath === '/shutdown') {
      // Handle shutdown notification
      handleShutdownRequest(req, res);
      return;
    }

    // Serve static files from SERVE_DIR
    handleStaticFile(urlPath, req, res);
  });

  return server;
}

/**
 * Try to start server on a port, with fallback to next ports
 * @param {number} startPort - Initial port to try
 * @param {number} maxPort - Maximum port to try
 * @param {function} callback - Called with (server, actualPort) on success
 */
function tryStartServer(startPort, maxPort, callback) {
  const server = createServer(startPort);

  server.on('error', (err) => {
    if (err.code === 'EADDRINUSE' && startPort < maxPort) {
      // Port in use, try next port
      server.close();
      tryStartServer(startPort + 1, maxPort, callback);
    } else {
      // Other error or max port reached
      console.error(`Failed to start server: ${err.message}`);
      process.exit(1);
    }
  });

  server.listen(startPort, () => {
    console.log(`Server started on port ${startPort}`);
    callback(server, startPort);
  });
}

// Ensure temp directory exists
if (!fs.existsSync(SERVE_DIR)) {
  fs.mkdirSync(SERVE_DIR, { recursive: true });
  console.log(`Created directory: ${SERVE_DIR}`);
}

// Start the server
tryStartServer(port, MAX_PORT, (server, actualPort) => {
  // Output port for parent process to read
  console.log(`PORT:${actualPort}`);
});

// Handle graceful shutdown
process.on('SIGTERM', () => {
  console.log('Received SIGTERM, shutting down...');
  broadcastEvent('shutdown', 'server shutdown');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('Received SIGINT, shutting down...');
  broadcastEvent('shutdown', 'server shutdown');
  process.exit(0);
});