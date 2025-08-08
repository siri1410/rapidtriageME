// Centralized project configuration
// This file reads from .project and provides configuration to all parts of the application

const fs = require('fs');
const path = require('path');

// Read .project file
function loadProjectConfig() {
  const projectFile = path.join(__dirname, '..', '.project');
  const content = fs.readFileSync(projectFile, 'utf8');
  const config = {};
  
  content.split('\n').forEach(line => {
    const [key, value] = line.split('=');
    if (key && value) {
      config[key.trim()] = value.trim();
    }
  });
  
  return config;
}

const projectConfig = loadProjectConfig();

// Export configuration
module.exports = {
  // Project Info
  projectName: projectConfig.PROJECT_NAME || 'RapidTriageME',
  repositoryUrl: projectConfig.REPOSITORY_URL || 'https://github.com/YarlisAISolutions/rapidtriageME',
  
  // Repository parts
  githubOrg: projectConfig.REPOSITORY_URL?.split('/')[3] || 'YarlisAISolutions',
  githubRepo: projectConfig.REPOSITORY_URL?.split('/')[4] || 'rapidtriageME',
  
  // Infrastructure
  provider: projectConfig.PROVIDER || 'CLOUDFLARE',
  region: projectConfig.REGION || 'GLOBAL',
  domain: projectConfig.DOMAIN || 'rapidtriage.me',
  
  // Documentation
  docsUrl: `https://docs.${projectConfig.DOMAIN || 'rapidtriage.me'}`,
  
  // Description
  description: projectConfig.DESCRIPTION || 'Remote Browser Tools MCP Platform',
  
  // Utility functions
  getGitCloneUrl: function() {
    return `${this.repositoryUrl}.git`;
  },
  
  getIssuesUrl: function() {
    return `${this.repositoryUrl}/issues`;
  },
  
  getRawContentUrl: function(branch = 'main', filepath = '') {
    return `https://raw.githubusercontent.com/${this.githubOrg}/${this.githubRepo}/${branch}/${filepath}`;
  }
};