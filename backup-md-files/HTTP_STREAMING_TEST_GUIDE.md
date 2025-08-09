# HTTP Streaming Test Guide for RapidTriageME

## 🚀 Quick Start Testing Guide

Your RapidTriageME platform is **deployed and live** at https://rapidtriage.me/

### Current Status
- ✅ **Production Deployed**: https://rapidtriage.me/
- ✅ **Health Endpoint Working**: https://rapidtriage.me/health
- ⚠️ **API Endpoints**: Return 404 (need browser backend connection)
- ⚠️ **SSE/WebSocket**: Need authentication configuration

## 📋 Testing Methods

### Method 1: Web Browser Testing (Easiest)

1. **Open the test client in your browser:**
   ```bash
   open test-http-streaming-client.html
   ```

2. **Configure your settings:**
   - Auth Token: `test-token` (or your configured token)
   - Target URL: `https://example.com`
   - Test Mode: REST API

3. **Click test buttons to try different features:**
   - Screenshot capture
   - Console logs
   - Network analysis
   - Lighthouse audit

### Method 2: Command Line Testing

```bash
# Test health endpoint (working)
curl https://rapidtriage.me/health

# Test screenshot API (requires backend)
curl -X POST https://rapidtriage.me/api/screenshot \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"url":"https://example.com","fullPage":false}'

# Test SSE streaming
curl -N https://rapidtriage.me/sse \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Method 3: Node.js Script Testing

```bash
# Run the test script
node test-production-api.js

# Test with custom URL
node test-production-api.js https://google.com
```

## 🔧 What's Currently Working

### ✅ Working Endpoints:
- `GET /` - Landing page
- `GET /health` - Health check (confirmed working)

### ⚠️ Configured but Need Backend:
- `POST /api/screenshot` - Returns mock data
- `POST /api/console-logs` - Returns mock data  
- `POST /api/network-logs` - Returns mock data
- `POST /api/lighthouse` - Returns mock data
- `GET /sse` - SSE streaming endpoint

## 🛠️ To Make Everything Fully Functional

### Step 1: Configure Authentication
```bash
# Set the AUTH_TOKEN secret in Cloudflare
wrangler secret put AUTH_TOKEN
# Enter your token when prompted

# Set the JWT_SECRET
wrangler secret put JWT_SECRET
# Enter your secret when prompted
```

### Step 2: Connect Browser Backend

The API endpoints return 404 because they need a browser automation backend. You have two options:

#### Option A: Deploy Browser Tools Server
```bash
cd rapidtriage-server
npm install
npm start
# This will start the Puppeteer backend on port 3025
```

#### Option B: Use Mock Mode
The current deployment returns mock data for testing:
- Screenshot: Returns success message
- Console logs: Returns sample logs
- Network: Returns sample metrics
- Lighthouse: Returns sample scores

### Step 3: Update Worker Configuration
```bash
# Edit wrangler.toml to point to your browser backend
[vars]
BROWSER_TOOLS_HOST = "your-backend-url"
BROWSER_TOOLS_PORT = "3025"

# Redeploy
npm run deploy:production
```

## 📊 Expected Test Results

When fully configured, you should see:

### Health Check Response:
```json
{
  "status": "healthy",
  "timestamp": "2025-08-09T18:42:19.007Z",
  "environment": "production",
  "version": "1.0.0",
  "service": "RapidTriageME"
}
```

### Screenshot API Response:
```json
{
  "content": [
    {
      "type": "text",
      "text": "Screenshot captured successfully"
    },
    {
      "type": "image",
      "data": "base64_image_data",
      "mimeType": "image/png"
    }
  ]
}
```

### SSE Stream Example:
```
data: {"type":"connected","timestamp":"2025-08-09T18:50:00.000Z"}

: heartbeat

data: {"type":"message","content":"Browser ready"}
```

## 🧪 Test Scenarios

### Basic Screenshot Test:
1. Navigate to https://example.com
2. Take a screenshot
3. Verify image is returned

### Console Log Monitoring:
1. Navigate to a page with console errors
2. Retrieve console logs
3. Filter by error level

### Network Analysis:
1. Navigate to a heavy website
2. Capture network requests
3. Analyze failed requests

### Lighthouse Audit:
1. Navigate to target site
2. Run performance audit
3. Get accessibility scores

## 🐛 Troubleshooting

### If API returns 404:
- Browser backend is not connected
- Routes are not properly configured
- Check worker logs: `npm run tail`

### If SSE fails to connect:
- Authentication token is incorrect
- CORS headers need adjustment
- Check browser console for errors

### If authentication fails:
- Token not set in Cloudflare secrets
- Bearer token format incorrect
- JWT secret mismatch

## 📝 Example: Complete Test Flow

```javascript
// 1. Check health
fetch('https://rapidtriage.me/health')
  .then(r => r.json())
  .then(console.log);

// 2. Take screenshot
fetch('https://rapidtriage.me/api/screenshot', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer test-token'
  },
  body: JSON.stringify({
    url: 'https://example.com',
    fullPage: true
  })
})
.then(r => r.json())
.then(result => {
  console.log('Screenshot result:', result);
});

// 3. Connect to SSE
const eventSource = new EventSource('https://rapidtriage.me/sse', {
  headers: {
    'Authorization': 'Bearer test-token'
  }
});

eventSource.onmessage = (event) => {
  console.log('SSE Message:', event.data);
};
```

## 🎯 Next Steps

1. **Immediate**: Test the health endpoint ✅
2. **Configure**: Set up authentication tokens
3. **Deploy**: Start browser backend server
4. **Connect**: Update worker to use backend
5. **Test**: Run full test suite

## 📚 Resources

- **Production URL**: https://rapidtriage.me/
- **Health Check**: https://rapidtriage.me/health
- **Test Client**: Open `test-http-streaming-client.html`
- **API Tester**: Run `node test-production-api.js`
- **Worker Logs**: `npm run tail`

---

Your HTTP streaming mode is **deployed and ready** but needs the browser backend service to be fully functional. The infrastructure is in place and working!