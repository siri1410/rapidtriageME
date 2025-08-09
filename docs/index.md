# 📚 RapidTriageME Documentation

Welcome to the comprehensive documentation for RapidTriageME - YarlisAISolutions' browser triage and debugging platform.

## 📖 Documentation Structure

### Getting Started
- [01 - Quick Start Guide](01-quickstart.md) - Get up and running in 5 minutes
- [02 - IDE Configuration](02-ide-configuration.md) - Setup for 10+ IDEs (Claude, Cursor, VS Code, etc.)
- [03 - Local Testing](03-local-testing.md) - Test locally before deployment

### Deployment & Infrastructure
- [04 - Deployment Guide](04-deployment.md) - Complete deployment instructions (local, staging, production)
- [05 - Publish Checklist](05-publish-checklist.md) - Pre-deployment checklist
- [11 - Remote Browser Solution](11-remote-browser-solution.md) - Cloud infrastructure setup

### Technical Documentation
- [06 - Project Structure](06-project-structure.md) - Repository organization
- [09 - MCP Protocol](09-mcp-protocol.md) - Model Context Protocol implementation
- [10 - MCP Documentation](10-mcp-documentation.md) - Detailed MCP specification
- [13 - MCP Usage Guide](13-mcp-usage-guide.md) - How to use MCP features

### Testing & Validation
- [12 - Testing Guide](12-testing.md) - Comprehensive testing procedures and results

### Reference
- [07 - Improvements Summary](07-improvements-summary.md) - Recent updates and fixes
- [08 - Final Status](08-final-status.md) - Current deployment status
- [14 - Quick Reference](14-quick-reference.md) - Commands and API reference

## 🚀 Quick Links

- **Production Site**: https://rapidtriage.me
- **Backend API**: https://rapidtriage-backend-u72y6ntcwa-uc.a.run.app
- **GitHub Repository**: https://github.com/YarlisAISolutions/rapidtriageME
- **NPM Packages**:
  - [@yarlisai/rapidtriage-mcp](https://www.npmjs.com/package/@yarlisai/rapidtriage-mcp)
  - [@yarlisai/rapidtriage-server](https://www.npmjs.com/package/@yarlisai/rapidtriage-server)

## 🎯 Key Features

- **Real-time Browser Monitoring** - Capture console logs, network requests, DOM changes
- **Advanced Screenshot Capture** - Full-page and viewport screenshots
- **Lighthouse Audits** - Performance, accessibility, SEO analysis
- **Remote Debugging** - Debug browsers from anywhere
- **Multi-IDE Support** - Works with 10+ IDEs and AI assistants
- **Secure** - Token-based authentication and rate limiting
- **Cloud Ready** - Deployable to Cloudflare Workers

## 📦 Components

1. **Chrome Extension** - Browser DevTools integration
2. **MCP Server** - IDE integration via Model Context Protocol
3. **Browser Server** - Local Node.js middleware
4. **Cloudflare Worker** - Production deployment
5. **Backend API** - Google Cloud Run service

## 🔧 Available MCP Tools

1. `remote_browser_navigate` - Navigate to URLs
2. `remote_capture_screenshot` - Capture screenshots
3. `remote_get_console_logs` - Retrieve console logs
4. `remote_get_network_logs` - Get network requests
5. `remote_run_lighthouse_audit` - Run performance audits
6. `remote_inspect_element` - Inspect DOM elements
7. `remote_execute_javascript` - Execute JS code
8. `remote_generate_triage_report` - Generate reports

## 📊 API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/health` | GET | Health check |
| `/sse` | POST | MCP protocol (JSON-RPC) |
| `/api/screenshot` | POST | Capture screenshots |
| `/api/console-logs` | POST | Get console logs |
| `/api/network-logs` | POST | Get network logs |
| `/api/lighthouse` | POST | Run Lighthouse audits |
| `/api/execute-js` | POST | Execute JavaScript |
| `/api/inspect-element` | POST | Inspect DOM elements |
| `/api/navigate` | POST | Navigate browser |
| `/api/triage-report` | POST | Generate triage reports |

## 🔐 Authentication

All API endpoints (except `/health`) require Bearer token authentication:

```bash
Authorization: Bearer KskHe6x5tkS4CgLrwfeZvbXsSDmZUjR8
```

## 📈 Performance

- **Cloudflare Worker**: ~47ms response time
- **Backend API**: ~96ms response time
- **Rate Limiting**: 100 requests/minute
- **Lighthouse Scores**: Performance 97/100, Accessibility 80/100

## 🤝 Support

- **GitHub Issues**: [Report issues](https://github.com/YarlisAISolutions/rapidtriageME/issues)
- **Documentation**: [This site](https://yarlisaisolutions.github.io/rapidtriageME/)
- **Email**: support@yarlisai.com

---

**Last Updated**: August 9, 2025  
**Version**: 1.1.0  
**Status**: Production Ready