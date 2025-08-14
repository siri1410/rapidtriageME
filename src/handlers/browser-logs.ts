/**
 * Browser Logs Handler for RapidTriageME
 * Handles storing and retrieving browser console and network logs
 */

interface ConsoleLog {
  id: string;
  timestamp: string;
  level: 'log' | 'info' | 'warn' | 'error' | 'debug';
  message: string;
  url: string;
  source?: string;
  lineNumber?: number;
  columnNumber?: number;
  stack?: string;
  sessionId?: string;
  userId?: string;
}

interface NetworkLog {
  id: string;
  timestamp: string;
  method: string;
  url: string;
  status: number;
  statusText: string;
  responseTime: number;
  size: number;
  type: string;
  sessionId?: string;
  userId?: string;
}

export class BrowserLogsHandler {
  private env: any;

  constructor(env: any) {
    this.env = env;
  }

  /**
   * Store console logs from browser
   */
  async storeConsoleLogs(request: Request): Promise<Response> {
    try {
      const body = await request.json() as any;
      const { url, logs, sessionId } = body;

      if (!url || !logs || !Array.isArray(logs)) {
        return new Response(JSON.stringify({
          error: 'Invalid request',
          message: 'URL and logs array are required'
        }), {
          status: 400,
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
          }
        });
      }

      // Get user ID from auth token if provided
      let userId: string | null = null;
      const authHeader = request.headers.get('Authorization');
      if (authHeader && authHeader.startsWith('Bearer ')) {
        // Validate token and extract user ID
        // For now, we'll use the token as a simple identifier
        userId = authHeader.replace('Bearer ', '').substring(0, 20);
      }

      const storedLogs: ConsoleLog[] = [];
      const timestamp = new Date().toISOString();

      // Store each log entry
      for (const log of logs) {
        const logEntry: ConsoleLog = {
          id: `log_${Date.now()}_${Math.random().toString(36).substring(7)}`,
          timestamp: log.timestamp || timestamp,
          level: log.level || 'log',
          message: log.message || log.text || '',
          url,
          source: log.source,
          lineNumber: log.lineNumber,
          columnNumber: log.columnNumber,
          stack: log.stack,
          sessionId: sessionId || `session_${Date.now()}`,
          userId: userId || undefined
        };

        // Store in KV if available
        if (this.env.SESSIONS) {
          const key = `console:${logEntry.sessionId}:${logEntry.id}`;
          await this.env.SESSIONS.put(key, JSON.stringify(logEntry), {
            expirationTtl: 86400 // 24 hours
          });

          // Also store in a list for the session
          const sessionKey = `console:session:${logEntry.sessionId}`;
          const existingLogs = await this.env.SESSIONS.get(sessionKey);
          const logsList = existingLogs ? JSON.parse(existingLogs) : [];
          logsList.push(logEntry.id);
          
          // Keep only last 1000 logs per session
          if (logsList.length > 1000) {
            logsList.shift();
          }
          
          await this.env.SESSIONS.put(sessionKey, JSON.stringify(logsList), {
            expirationTtl: 86400
          });
        }

        storedLogs.push(logEntry);
      }

      return new Response(JSON.stringify({
        success: true,
        message: `Stored ${storedLogs.length} console logs`,
        sessionId: storedLogs[0]?.sessionId,
        logs: storedLogs
      }), {
        status: 200,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        }
      });

    } catch (error) {
      console.error('Error storing console logs:', error);
      return new Response(JSON.stringify({
        error: 'Internal Server Error',
        message: 'Failed to store console logs'
      }), {
        status: 500,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        }
      });
    }
  }

  /**
   * Retrieve console logs
   */
  async getConsoleLogs(request: Request): Promise<Response> {
    try {
      const url = new URL(request.url);
      const targetUrl = url.searchParams.get('url');
      const sessionId = url.searchParams.get('sessionId');
      const level = url.searchParams.get('level');
      const limit = parseInt(url.searchParams.get('limit') || '100');

      // If we have a sessionId, retrieve logs for that session
      if (sessionId && this.env.SESSIONS) {
        const sessionKey = `console:session:${sessionId}`;
        const logsList = await this.env.SESSIONS.get(sessionKey);
        
        if (logsList) {
          const logIds = JSON.parse(logsList);
          const logs: ConsoleLog[] = [];
          
          // Retrieve each log entry
          for (const logId of logIds.slice(-limit)) {
            const key = `console:${sessionId}:${logId}`;
            const logData = await this.env.SESSIONS.get(key);
            if (logData) {
              const log = JSON.parse(logData);
              
              // Filter by level if specified
              if (!level || level === 'all' || log.level === level) {
                logs.push(log);
              }
            }
          }

          return new Response(JSON.stringify({
            content: [{
              type: "text",
              text: logs.length > 0 
                ? logs.map(l => `[${l.level.toUpperCase()}] ${l.message}`).join('\n')
                : "No console logs found for this session"
            }],
            logs,
            sessionId,
            count: logs.length
          }), {
            status: 200,
            headers: {
              'Content-Type': 'application/json',
              'Access-Control-Allow-Origin': '*'
            }
          });
        }
      }

      // If no stored logs found, return a message indicating the extension needs to be installed
      return new Response(JSON.stringify({
        content: [{
          type: "text",
          text: "No console logs captured. Please ensure:\n1. The RapidTriageME browser extension is installed\n2. You are on the target page\n3. The extension is actively capturing logs\n\nAlternatively, send logs directly to POST /api/console-logs with the format:\n{\n  \"url\": \"https://example.com\",\n  \"logs\": [\n    {\"level\": \"error\", \"message\": \"Error message\", \"timestamp\": \"2024-01-01T00:00:00Z\"}\n  ]\n}"
        }],
        info: "Browser extension required for automatic log capture",
        extensionUrl: "https://chrome.google.com/webstore/detail/rapidtriageme"
      }), {
        status: 200,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        }
      });

    } catch (error) {
      console.error('Error retrieving console logs:', error);
      return new Response(JSON.stringify({
        error: 'Internal Server Error',
        message: 'Failed to retrieve console logs'
      }), {
        status: 500,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        }
      });
    }
  }

  /**
   * Store network logs from browser
   */
  async storeNetworkLogs(request: Request): Promise<Response> {
    try {
      const body = await request.json() as any;
      const { url, logs, sessionId } = body;

      if (!url || !logs || !Array.isArray(logs)) {
        return new Response(JSON.stringify({
          error: 'Invalid request',
          message: 'URL and logs array are required'
        }), {
          status: 400,
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
          }
        });
      }

      const storedLogs: NetworkLog[] = [];
      const timestamp = new Date().toISOString();

      // Store each network request
      for (const log of logs) {
        const logEntry: NetworkLog = {
          id: `net_${Date.now()}_${Math.random().toString(36).substring(7)}`,
          timestamp: log.timestamp || timestamp,
          method: log.method || 'GET',
          url: log.url || '',
          status: log.status || 0,
          statusText: log.statusText || '',
          responseTime: log.responseTime || 0,
          size: log.size || 0,
          type: log.type || 'xhr',
          sessionId: sessionId || `session_${Date.now()}`
        };

        // Store in KV if available
        if (this.env.SESSIONS) {
          const key = `network:${logEntry.sessionId}:${logEntry.id}`;
          await this.env.SESSIONS.put(key, JSON.stringify(logEntry), {
            expirationTtl: 86400 // 24 hours
          });

          // Also store in a list for the session
          const sessionKey = `network:session:${logEntry.sessionId}`;
          const existingLogs = await this.env.SESSIONS.get(sessionKey);
          const logsList = existingLogs ? JSON.parse(existingLogs) : [];
          logsList.push(logEntry.id);
          
          // Keep only last 1000 logs per session
          if (logsList.length > 1000) {
            logsList.shift();
          }
          
          await this.env.SESSIONS.put(sessionKey, JSON.stringify(logsList), {
            expirationTtl: 86400
          });
        }

        storedLogs.push(logEntry);
      }

      return new Response(JSON.stringify({
        success: true,
        message: `Stored ${storedLogs.length} network logs`,
        sessionId: storedLogs[0]?.sessionId,
        logs: storedLogs
      }), {
        status: 200,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        }
      });

    } catch (error) {
      console.error('Error storing network logs:', error);
      return new Response(JSON.stringify({
        error: 'Internal Server Error',
        message: 'Failed to store network logs'
      }), {
        status: 500,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        }
      });
    }
  }

  /**
   * Retrieve network logs
   */
  async getNetworkLogs(request: Request): Promise<Response> {
    try {
      const url = new URL(request.url);
      const sessionId = url.searchParams.get('sessionId');
      const status = url.searchParams.get('status');
      const limit = parseInt(url.searchParams.get('limit') || '100');

      // If we have a sessionId, retrieve logs for that session
      if (sessionId && this.env.SESSIONS) {
        const sessionKey = `network:session:${sessionId}`;
        const logsList = await this.env.SESSIONS.get(sessionKey);
        
        if (logsList) {
          const logIds = JSON.parse(logsList);
          const logs: NetworkLog[] = [];
          
          // Retrieve each log entry
          for (const logId of logIds.slice(-limit)) {
            const key = `network:${sessionId}:${logId}`;
            const logData = await this.env.SESSIONS.get(key);
            if (logData) {
              const log = JSON.parse(logData);
              
              // Filter by status if specified
              if (!status || (status === 'error' && log.status >= 400) || (status === 'success' && log.status < 400)) {
                logs.push(log);
              }
            }
          }

          // Calculate statistics
          const totalRequests = logs.length;
          const failedRequests = logs.filter(l => l.status >= 400).length;
          const avgResponseTime = logs.reduce((sum, l) => sum + l.responseTime, 0) / (totalRequests || 1);

          return new Response(JSON.stringify({
            content: [{
              type: "text",
              text: `Network Analysis:\nTotal Requests: ${totalRequests}\nFailed Requests: ${failedRequests}\nAverage Response Time: ${avgResponseTime.toFixed(2)}ms\n\nTop requests:\n${logs.slice(0, 10).map(l => `${l.method} ${l.url} - ${l.status} (${l.responseTime}ms)`).join('\n')}`
            }],
            logs,
            sessionId,
            statistics: {
              totalRequests,
              failedRequests,
              avgResponseTime
            }
          }), {
            status: 200,
            headers: {
              'Content-Type': 'application/json',
              'Access-Control-Allow-Origin': '*'
            }
          });
        }
      }

      // If no stored logs found, return a message
      return new Response(JSON.stringify({
        content: [{
          type: "text",
          text: "No network logs captured. Please ensure:\n1. The RapidTriageME browser extension is installed\n2. You are on the target page\n3. The extension is actively capturing network requests"
        }],
        info: "Browser extension required for automatic network capture"
      }), {
        status: 200,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        }
      });

    } catch (error) {
      console.error('Error retrieving network logs:', error);
      return new Response(JSON.stringify({
        error: 'Internal Server Error',
        message: 'Failed to retrieve network logs'
      }), {
        status: 500,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        }
      });
    }
  }
}