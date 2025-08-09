#!/usr/bin/env python3
"""
Simple HTTP server to serve the RapidTriageME test page locally
Supports CORS for testing cross-origin requests
"""

import http.server
import socketserver
import os
from http.server import SimpleHTTPRequestHandler

class CORSRequestHandler(SimpleHTTPRequestHandler):
    def end_headers(self):
        # Add CORS headers
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
        self.send_header('Cache-Control', 'no-store, no-cache, must-revalidate')
        return super().end_headers()
    
    def do_OPTIONS(self):
        self.send_response(200)
        self.end_headers()

PORT = 8080
DIRECTORY = os.path.dirname(os.path.abspath(__file__))

os.chdir(DIRECTORY)

with socketserver.TCPServer(("", PORT), CORSRequestHandler) as httpd:
    print(f"🚀 RapidTriageME Test Server")
    print(f"📍 Serving at: http://localhost:{PORT}")
    print(f"📄 Test page: http://localhost:{PORT}/test-rapidtriage-enhanced.html")
    print(f"🛑 Press Ctrl+C to stop")
    print("-" * 50)
    
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n✅ Server stopped")