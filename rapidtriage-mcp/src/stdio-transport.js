#!/usr/bin/env node

/**
 * Stdio Transport Implementation for RapidTriageME MCP Server
 * Enables communication via standard input/output streams
 */

const { Server } = require('@modelcontextprotocol/sdk/server/index.js');
const { StdioServerTransport } = require('@modelcontextprotocol/sdk/server/stdio.js');

// Import tool implementations
const tools = require('./tools');

/**
 * Create and configure the MCP server with stdio transport
 */
async function createStdioServer() {
    // Create server instance
    const server = new Server(
        {
            name: "rapidtriage-mcp",
            version: "1.0.0"
        },
        {
            capabilities: {
                tools: {}
            }
        }
    );

    // Register tool handlers
    server.setRequestHandler('tools/list', async () => {
        return {
            tools: Object.values(tools).map(tool => tool.definition)
        };
    });

    server.setRequestHandler('tools/call', async (request) => {
        const { name, arguments: args } = request.params;
        
        const tool = Object.values(tools).find(t => t.definition.name === name);
        if (!tool) {
            throw new Error(`Unknown tool: ${name}`);
        }

        try {
            const result = await tool.handler(args);
            return {
                content: [{
                    type: "text",
                    text: typeof result === 'string' ? result : JSON.stringify(result, null, 2)
                }]
            };
        } catch (error) {
            return {
                content: [{
                    type: "text",
                    text: `Error: ${error.message}`
                }],
                isError: true
            };
        }
    });

    return server;
}

/**
 * Main entry point for stdio mode
 */
async function main() {
    try {
        const server = await createStdioServer();
        const transport = new StdioServerTransport();
        
        await server.connect(transport);
        console.error('MCP Server running in stdio mode');
    } catch (error) {
        console.error('Failed to start server:', error);
        process.exit(1);
    }
}

// Handle process termination
process.on('SIGINT', () => {
    console.error('Server shutting down');
    process.exit(0);
});

process.on('SIGTERM', () => {
    console.error('Server shutting down');
    process.exit(0);
});

// Start server
if (require.main === module) {
    main();
}

module.exports = { createStdioServer };