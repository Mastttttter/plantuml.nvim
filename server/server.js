#!/usr/bin/env node
/**
 * Simple static file server for PlantUML preview
 * Serves files from /tmp/plantuml.nvim/ with CORS headers
 * Provides SSE endpoint for real-time refresh notifications
 */

const http = require('http');
const fs = require('fs');
const path = require('path');

const SERVE_DIR = '/tmp/plantuml.nvim';
const DEFAULT_PORT = 8912;
const MAX_PORT = 8099;

// Connected SSE clients
const sseClients = new Set();

// File watcher instance
let fileWatcher = null;

// Get port from command line argument
let port = DEFAULT_PORT;
const portIndex = process.argv.indexOf('--port');
if (portIndex !== -1 && process.argv[portIndex + 1]) {
  port = parseInt(process.argv[portIndex + 1], 10);
}

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

/**
 * Get MIME type for a file extension
 * @param {string} ext - File extension (with dot)
 * @returns {string} MIME type
 */
function getMimeType(ext) {
  return MIME_TYPES[ext.toLowerCase()] || 'application/octet-stream';
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

  // Send initial keep-alive comment
  res.write(': connected\n\n');

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
 * Broadcast refresh event to all connected SSE clients
 * @param {string} filename - Name of the changed file
 */
function broadcastRefresh(filename) {
  if (sseClients.size === 0) {
    return;
  }

  console.log(`Broadcasting refresh to ${sseClients.size} clients for file: ${filename}`);

  const message = 'data: refresh\n\n';

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
 * Start file watcher for the serve directory
 */
function startFileWatcher() {
  // Ensure directory exists
  if (!fs.existsSync(SERVE_DIR)) {
    fs.mkdirSync(SERVE_DIR, { recursive: true });
    console.log(`Created directory: ${SERVE_DIR}`);
  }

  // Watch for file changes
  fileWatcher = fs.watch(SERVE_DIR, (eventType, filename) => {
    if (!filename) {
      return;
    }

    // Only broadcast for SVG files
    if (filename.endsWith('.svg')) {
      broadcastRefresh(filename);
    }
  });

  fileWatcher.on('error', (err) => {
    console.error(`File watcher error: ${err.message}`);
  });

  console.log(`File watcher started on ${SERVE_DIR}`);
}

/**
 * Create HTTP server
 * @param {number} port - Port to listen on
 * @returns {http.Server} HTTP server instance
 */
function createServer(port) {
  const server = http.createServer((req, res) => {
    // Handle SSE endpoint
    if (req.url.split('?')[0] === '/events' && req.method === 'GET') {
      handleSSEConnection(res);
      return;
    }

    // Parse URL and remove query string
    let urlPath = req.url.split('?')[0];

    // Decode URL-encoded characters
    try {
      urlPath = decodeURIComponent(urlPath);
    } catch (e) {
      // Invalid URL encoding
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

// Start the server
tryStartServer(port, MAX_PORT, (server, actualPort) => {
  // Start file watcher
  startFileWatcher();

  // Output port for parent process to read
  console.log(`PORT:${actualPort}`);
});

// Handle graceful shutdown
process.on('SIGTERM', () => {
  console.log('Received SIGTERM, shutting down...');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('Received SIGINT, shutting down...');
  process.exit(0);
});
