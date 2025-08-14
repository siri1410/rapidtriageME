/**
 * Console Log Formatter Utility
 * Provides formatted display of console logs with various output options
 */

export interface LogEntry {
  id: string;
  timestamp: string;
  level: 'log' | 'info' | 'warn' | 'error' | 'debug';
  message: string;
  url?: string;
  source?: string;
  lineNumber?: number;
  columnNumber?: number;
  stack?: string;
  sessionId?: string;
}

export class ConsoleFormatter {
  /**
   * Format logs as plain text with line breaks
   */
  static toPlainText(logs: LogEntry[]): string {
    return logs.map(log => `[${log.level.toUpperCase()}] ${log.message}`).join('\n');
  }

  /**
   * Format logs as HTML with styling
   */
  static toHTML(logs: LogEntry[]): string {
    const styles = `
      <style>
        .console-logs { font-family: monospace; padding: 10px; background: #f8f9fa; border-radius: 8px; }
        .log-entry { padding: 8px; margin: 4px 0; border-radius: 4px; border-left: 4px solid; }
        .log-error { background: #fed7d7; color: #742a2a; border-left-color: #fc8181; }
        .log-warn { background: #fef5c7; color: #744210; border-left-color: #f6ad55; }
        .log-info { background: #bee3f8; color: #2c5282; border-left-color: #4299e1; }
        .log-log { background: #e2e8f0; color: #4a5568; border-left-color: #a0aec0; }
        .log-debug { background: #e6fffa; color: #234e52; border-left-color: #38b2ac; }
        .log-time { color: #718096; font-size: 0.85em; }
      </style>
    `;

    const logsHTML = logs.map(log => {
      const time = new Date(log.timestamp).toLocaleTimeString();
      return `
        <div class="log-entry log-${log.level}">
          <strong>[${log.level.toUpperCase()}]</strong>
          <span class="log-time">${time}</span><br>
          ${this.escapeHtml(log.message)}
          ${log.source ? `<br><small>Source: ${this.escapeHtml(log.source)}:${log.lineNumber || 0}</small>` : ''}
        </div>
      `;
    }).join('');

    return `${styles}<div class="console-logs">${logsHTML}</div>`;
  }

  /**
   * Format logs as Markdown
   */
  static toMarkdown(logs: LogEntry[]): string {
    const header = '## Console Logs\n\n';
    const logLines = logs.map(log => {
      const time = new Date(log.timestamp).toISOString();
      const emoji = this.getLogEmoji(log.level);
      return `${emoji} **[${log.level.toUpperCase()}]** \`${time}\`\n${log.message}`;
    }).join('\n\n');
    
    return header + logLines;
  }

  /**
   * Format logs as JSON with pretty printing
   */
  static toJSON(logs: LogEntry[], pretty: boolean = true): string {
    return pretty ? JSON.stringify(logs, null, 2) : JSON.stringify(logs);
  }

  /**
   * Format logs as CSV
   */
  static toCSV(logs: LogEntry[]): string {
    const headers = 'Timestamp,Level,Message,URL,Source,Line,Column\n';
    const rows = logs.map(log => {
      return [
        log.timestamp,
        log.level,
        `"${log.message.replace(/"/g, '""')}"`,
        log.url || '',
        log.source || '',
        log.lineNumber || '',
        log.columnNumber || ''
      ].join(',');
    }).join('\n');
    
    return headers + rows;
  }

  /**
   * Format logs for terminal/console output with ANSI colors
   */
  static toTerminal(logs: LogEntry[]): string {
    const colors = {
      error: '\x1b[31m',   // Red
      warn: '\x1b[33m',    // Yellow
      info: '\x1b[36m',    // Cyan
      debug: '\x1b[35m',   // Magenta
      log: '\x1b[0m',      // Default
      reset: '\x1b[0m'
    };

    return logs.map(log => {
      const color = colors[log.level] || colors.log;
      const time = new Date(log.timestamp).toLocaleTimeString();
      return `${color}[${log.level.toUpperCase()}] ${time} - ${log.message}${colors.reset}`;
    }).join('\n');
  }

  /**
   * Group logs by level
   */
  static groupByLevel(logs: LogEntry[]): Record<string, LogEntry[]> {
    return logs.reduce((grouped, log) => {
      if (!grouped[log.level]) {
        grouped[log.level] = [];
      }
      grouped[log.level].push(log);
      return grouped;
    }, {} as Record<string, LogEntry[]>);
  }

  /**
   * Filter logs by level
   */
  static filterByLevel(logs: LogEntry[], levels: string[]): LogEntry[] {
    return logs.filter(log => levels.includes(log.level));
  }

  /**
   * Get statistics about logs
   */
  static getStatistics(logs: LogEntry[]) {
    const grouped = this.groupByLevel(logs);
    return {
      total: logs.length,
      errors: grouped.error?.length || 0,
      warnings: grouped.warn?.length || 0,
      info: grouped.info?.length || 0,
      debug: grouped.debug?.length || 0,
      logs: grouped.log?.length || 0,
      timeRange: logs.length > 0 ? {
        start: logs[0].timestamp,
        end: logs[logs.length - 1].timestamp
      } : null
    };
  }

  /**
   * Helper function to escape HTML
   */
  private static escapeHtml(text: string): string {
    // Worker-compatible HTML escaping without DOM
    return text
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;');
  }

  /**
   * Get emoji for log level
   */
  private static getLogEmoji(level: string): string {
    const emojis: Record<string, string> = {
      error: '❌',
      warn: '⚠️',
      info: 'ℹ️',
      debug: '🔍',
      log: '📝'
    };
    return emojis[level] || '📝';
  }
}