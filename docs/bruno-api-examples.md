# RapidTriageME API Examples for Bruno

## Console Logs API

The Console Logs API allows you to store and retrieve browser console logs for debugging purposes.

### 1. Store Console Logs

**Endpoint:** `POST /api/console-logs`

**Headers:**
```
Content-Type: application/json
X-Extension-Id: bruno-test
```

**Body:**
```json
{
  "url": "https://example.com",
  "logs": [
    {
      "level": "error",
      "message": "Failed to load resource: net::ERR_BLOCKED_BY_CLIENT",
      "timestamp": "2024-01-01T00:00:00Z"
    },
    {
      "level": "warn",
      "message": "Deprecation warning: Feature X is deprecated",
      "timestamp": "2024-01-01T00:00:01Z"
    },
    {
      "level": "info",
      "message": "Page loaded successfully",
      "timestamp": "2024-01-01T00:00:02Z"
    }
  ],
  "sessionId": "bruno-session-123"
}
```

**Expected Response:**
```json
{
  "content": [
    {
      "type": "text",
      "text": "Stored 3 console logs"
    }
  ]
}
```

### 2. Retrieve Console Logs

**Endpoint:** `POST /api/console-logs`

**Headers:**
```
Content-Type: application/json
X-Extension-Id: bruno-test
```

**Body:**
```json
{
  "sessionId": "bruno-session-123",
  "level": "all",
  "limit": 100
}
```

**Expected Response:**
```json
{
  "content": [
    {
      "type": "text",
      "text": "[ERROR] Failed to load resource: net::ERR_BLOCKED_BY_CLIENT\n[WARN] Deprecation warning: Feature X is deprecated\n[INFO] Page loaded successfully"
    }
  ],
  "logs": [
    {
      "id": "log_xxx",
      "timestamp": "2024-01-01T00:00:00Z",
      "level": "error",
      "message": "Failed to load resource: net::ERR_BLOCKED_BY_CLIENT",
      "url": "https://example.com",
      "sessionId": "bruno-session-123"
    },
    // ... more logs
  ],
  "sessionId": "bruno-session-123",
  "count": 3
}
```

### 3. Filter Logs by Level

**Body:**
```json
{
  "sessionId": "bruno-session-123",
  "level": "error",
  "limit": 50
}
```

This will return only error-level logs.

## Network Logs API

### 1. Store Network Logs

**Endpoint:** `POST /api/network-logs`

**Headers:**
```
Content-Type: application/json
X-Extension-Id: bruno-test
```

**Body:**
```json
{
  "url": "https://example.com",
  "logs": [
    {
      "method": "GET",
      "url": "https://api.example.com/data",
      "status": 200,
      "statusText": "OK",
      "responseTime": 234,
      "size": 1024,
      "type": "xhr",
      "timestamp": "2024-01-01T00:00:00Z"
    },
    {
      "method": "POST",
      "url": "https://api.example.com/submit",
      "status": 404,
      "statusText": "Not Found",
      "responseTime": 456,
      "size": 256,
      "type": "fetch",
      "timestamp": "2024-01-01T00:00:01Z"
    }
  ],
  "sessionId": "bruno-network-session-123"
}
```

### 2. Retrieve Network Logs

**Endpoint:** `POST /api/network-logs`

**Headers:**
```
Content-Type: application/json
X-Extension-Id: bruno-test
```

**Body:**
```json
{
  "sessionId": "bruno-network-session-123",
  "status": "error",
  "limit": 100
}
```

## Authentication Options

### Option 1: Extension Mode (No Auth Required)
Use the `X-Extension-Id` header to simulate a browser extension:
```
X-Extension-Id: your-extension-id
```

### Option 2: API Key Authentication
Use a valid API key in the Authorization header:
```
Authorization: Bearer rtm_your_api_key_here
```

### Option 3: JWT Authentication
Use a JWT token obtained from login:
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIs...
```

## Testing Workflow

1. **First, store some test logs** using the store endpoint
2. **Then retrieve them** using the same sessionId
3. **Filter by level or status** to get specific logs
4. **Use different sessionIds** to separate different debugging sessions

## Important Notes

- The API stores logs temporarily (24 hours by default)
- Each session can store up to 1000 logs
- Logs are stored in Cloudflare KV storage
- The `url` parameter in the store request is for reference only - it doesn't fetch logs from that URL
- To capture real browser logs, you need a browser extension that sends logs to this API

## CURL Examples

### Store logs:
```bash
curl -X POST http://localhost:8787/api/console-logs \
  -H "Content-Type: application/json" \
  -H "X-Extension-Id: test" \
  -d '{
    "url": "https://example.com",
    "logs": [
      {"level": "error", "message": "Test error"}
    ],
    "sessionId": "test-123"
  }'
```

### Retrieve logs:
```bash
curl -X POST http://localhost:8787/api/console-logs \
  -H "Content-Type: application/json" \
  -H "X-Extension-Id: test" \
  -d '{
    "sessionId": "test-123"
  }'
```