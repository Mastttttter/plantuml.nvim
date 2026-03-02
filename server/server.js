#!/usr/bin/env node
/**
 * Simple static file server for PlantUML preview
 * Serves files from /tmp/plantuml.nvim/ with CORS headers
 */

const http = require('http');
const fs = require('fs');
const path = require('path');

const SERVE_DIR = '/tmp/plantuml.nvim';
const DEFAULT_PORT = 8080;
const MAX_PORT = 8099;

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
 * Create HTTP server
 * @param {number} port - Port to listen on
 * @returns {http.Server} HTTP server instance
 */
function createServer(port) {
  const server = http.createServer((req, res) => {
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