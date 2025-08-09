# RapidTriageME Enhanced Test Page Guide

## 🚀 Quick Start

### Access the Test Page

#### Option 1: Direct File Access (Local Testing)
```bash
# Open directly in browser
open test-rapidtriage-enhanced.html
```

#### Option 2: Local Server (Recommended)
```bash
# Using Python server with CORS support
python3 serve-test-page.py
# Then visit: http://localhost:8080/test-rapidtriage-enhanced.html
```

#### Option 3: Production Access
- Deploy the test page to your web server
- Access via: `https://rapidtriage.me/test-rapidtriage-enhanced.html`

## 🎯 Features Overview

### 1. Connection Status Monitoring
The header shows real-time connection status for:
- **Local Service**: http://localhost:3025
- **Production Worker**: https://rapidtriage.me
- **Backend Service**: https://rapidtriage-backend-u72y6ntcwa-uc.a.run.app
- **MCP Endpoint**: Authentication status

### 2. Console & Debugging Tests
- **Console Messages**: Test log, info, debug output
- **Console Groups**: Test grouped console output
- **Warnings**: Generate warning messages
- **Errors**: Trigger and catch errors
- **Stack Traces**: Generate full stack traces
- **Performance Timers**: Test console.time() functionality

### 3. Network & API Tests
- **Custom Requests**: Test any API endpoint
- **Health Checks**: Test all service health endpoints
- **CORS Testing**: Verify CORS configuration
- **WebSocket**: Test WebSocket connectivity
- **Slow Requests**: Test timeout handling
- **Failed Requests**: Test error handling

### 4. Browser Automation Tests
- **Screenshot Capture**: Take screenshots of any URL
- **Page Metrics**: Get DOM statistics
- **DOM Manipulation**: Test element creation/modification
- **Form Automation**: Auto-fill form fields
- **Script Injection**: Test script execution

### 5. MCP Protocol Tests
- **Tools List**: Get available MCP tools
- **Authentication**: Test token validation
- **Command Execution**: Execute MCP commands
- **Invalid Requests**: Test error handling

### 6. Performance Metrics
- **Page Metrics**: Load time, DOM nodes, heap size
- **Memory Analysis**: JS heap usage and limits
- **Timing Analysis**: DNS, TCP, request timings
- **Resource Analysis**: Track loaded resources

### 7. Advanced Testing
- **Stress Testing**: Run multiple concurrent requests
- **XSS Protection**: Test security measures
- **CSP Headers**: Verify content security policy

## 📊 Test Scenarios

### Basic Health Check
1. Open the test page
2. Check connection status badges (should show green for connected services)
3. Click "Test Health Endpoints" in Network section
4. Verify all endpoints return healthy status

### Console Error Tracking
1. Click "Trigger Errors" in Console section
2. Open browser DevTools Console
3. Verify errors are logged properly
4. Check if RapidTriage captures the errors

### Network Performance Testing
1. Enter a test URL in the API URL field
2. Click "Test Request"
3. Note the response time
4. Run "Test Slow Request" to compare

### MCP Authentication Test
1. Ensure MCP token is entered (default provided)
2. Click "Test Authentication"
3. Should show success with valid token
4. Should show 401 with invalid/missing token

### Stress Test
1. Enter number of requests (e.g., 50)
2. Click "Run Stress Test"
3. Monitor success rate and average response time
4. Check for any failed requests

### Browser Automation
1. Enter a URL for screenshot
2. Click "Take Screenshot"
3. Wait for simulated screenshot
4. Test DOM manipulation features

## 🔧 Configuration

### Modify Endpoints
Edit the CONFIG object in the HTML file:
```javascript
const CONFIG = {
    localUrl: 'http://localhost:3025',
    productionUrl: 'https://rapidtriage.me',
    backendUrl: 'https://rapidtriage-backend-u72y6ntcwa-uc.a.run.app',
    mcpToken: 'KskHe6x5tkS4CgLrwfeZvbXsSDmZUjR8'
};
```

### Custom Tests
Add your own test functions:
```javascript
function customTest() {
    const output = document.getElementById('consoleOutput');
    // Your test code here
    addLogEntry(output, 'Custom test completed', 'success');
}
```

## 🎨 UI Features

### Visual Indicators
- **Green**: Success/Connected
- **Yellow**: Warning/Pending
- **Red**: Error/Disconnected
- **Blue**: Information

### Interactive Elements
- **Tabs**: Switch between metric views
- **Progress Bars**: Visual representation of memory usage
- **Spinners**: Loading indicators for async operations
- **Tooltips**: Hover for additional information

### Output Panels
- Each test section has its own output panel
- Timestamps for all log entries
- Color-coded messages by type
- Auto-scroll to latest entries

## 📱 Responsive Design
- Fully responsive layout
- Mobile-friendly interface
- Touch-optimized buttons
- Adaptive grid layout

## 🔍 Debugging Tips

### Check Console
Always have browser DevTools open to see:
- Console messages
- Network requests
- JavaScript errors
- Performance metrics

### Monitor Network Tab
Watch for:
- Failed requests (red entries)
- Slow requests (long duration)
- CORS errors
- Authentication failures

### Use Performance Tab
- Record page load
- Analyze memory usage
- Check for memory leaks
- Monitor CPU usage

## 🚨 Common Issues

### Connection Status Shows "Offline"
- Ensure services are running
- Check network connectivity
- Verify URLs in CONFIG
- Check for CORS issues

### MCP Tests Failing
- Verify authentication token
- Check if MCP endpoint is enabled
- Ensure proper Authorization header

### Screenshot Not Working
- Backend automation service required
- Check if Puppeteer is configured
- Verify backend is accessible

### Performance Metrics Not Available
- Some metrics require HTTPS
- Check browser compatibility
- Enable performance APIs in browser

## 📈 Production Deployment

1. **Upload to Server**:
```bash
scp test-rapidtriage-enhanced.html user@server:/var/www/html/
```

2. **Configure Web Server**:
Add to nginx/Apache config:
```nginx
location /test {
    alias /var/www/html/test-rapidtriage-enhanced.html;
    add_header Cache-Control "no-cache, no-store, must-revalidate";
}
```

3. **Secure Access** (Optional):
Add basic authentication for production test page

4. **Monitor Usage**:
Track test page access in your analytics

## 🎯 Test Automation

### Automated Testing Script
```javascript
// Run all tests automatically
async function runAllTests() {
    testConsoleMessages();
    await testHealthEndpoints();
    await testMCPToolsList();
    analyzePerformance();
    
    // Get results
    const results = window.getRapidTriageTestResults();
    console.log('Test Results:', results);
}
```

### CI/CD Integration
Use headless browser to run tests:
```bash
# With Puppeteer
node run-tests.js

# With Playwright
npx playwright test test-rapidtriage.spec.js
```

## 📝 Test Reporting

The test page tracks all results in `testResults` array. Access via:
```javascript
window.getRapidTriageTestResults()
```

Export results for analysis:
```javascript
const results = window.getRapidTriageTestResults();
const json = JSON.stringify(results, null, 2);
console.log(json);
```

## 🔗 Related Resources

- [RapidTriageME Documentation](https://github.com/yourusername/rapidtriage)
- [MCP Protocol Specification](https://modelcontextprotocol.io)
- [Browser DevTools Guide](https://developer.chrome.com/docs/devtools)
- [Web Performance Best Practices](https://web.dev/performance)

## 💡 Tips & Tricks

1. **Keyboard Shortcuts**:
   - `Ctrl+Shift+I`: Open DevTools
   - `Ctrl+Shift+J`: Open Console
   - `Ctrl+R`: Refresh page

2. **Quick Tests**:
   - Bookmark frequently used test combinations
   - Use browser profiles for different test scenarios
   - Create custom bookmarklets for quick testing

3. **Performance Testing**:
   - Clear cache before performance tests
   - Use incognito mode for clean state
   - Test on different network speeds (DevTools throttling)

4. **Debugging**:
   - Use `debugger;` statements in test code
   - Set breakpoints in DevTools
   - Use console.trace() for call stacks

---

Happy Testing! 🎉 If you find any issues or have suggestions, please report them.