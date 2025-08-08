#!/usr/bin/env python3
"""
Centralized project configuration for Python/MkDocs
Reads from .project file and provides configuration
"""

import os
from pathlib import Path

def load_project_config():
    """Load configuration from .project file"""
    project_file = Path(__file__).parent.parent / '.project'
    config = {}
    
    if project_file.exists():
        with open(project_file, 'r') as f:
            for line in f:
                if '=' in line:
                    key, value = line.strip().split('=', 1)
                    config[key] = value
    
    return config

# Load configuration
_config = load_project_config()

# Project configuration
PROJECT_NAME = _config.get('PROJECT_NAME', 'RapidTriageME')
REPOSITORY_URL = _config.get('REPOSITORY_URL', 'https://github.com/YarlisAISolutions/rapidtriageME')
PROVIDER = _config.get('PROVIDER', 'CLOUDFLARE')
REGION = _config.get('REGION', 'GLOBAL')
DOMAIN = _config.get('DOMAIN', 'rapidtriage.me')
DESCRIPTION = _config.get('DESCRIPTION', 'Remote Browser Tools MCP Platform')

# Derived values
GITHUB_ORG = REPOSITORY_URL.split('/')[3] if '/' in REPOSITORY_URL else 'YarlisAISolutions'
GITHUB_REPO = REPOSITORY_URL.split('/')[4] if '/' in REPOSITORY_URL else 'rapidtriageME'
DOCS_URL = f'https://docs.{DOMAIN}'
ISSUES_URL = f'{REPOSITORY_URL}/issues'

# MkDocs specific configuration
MKDOCS_CONFIG = {
    'site_name': f'{PROJECT_NAME} Documentation',
    'site_url': DOCS_URL,
    'repo_url': REPOSITORY_URL,
    'repo_name': f'{GITHUB_ORG}/{GITHUB_REPO}',
    'site_description': f'{DESCRIPTION} - Complete Documentation',
    'site_author': GITHUB_ORG,
    'edit_uri': 'edit/main/docs/',
    'copyright': f'&copy; 2025 <a href="https://yarlis.ai" target="_blank" rel="noopener">{GITHUB_ORG}</a>'
}

if __name__ == '__main__':
    # Print configuration when run directly
    print("Project Configuration:")
    print(f"  Name: {PROJECT_NAME}")
    print(f"  Repository: {REPOSITORY_URL}")
    print(f"  Domain: {DOMAIN}")
    print(f"  Docs URL: {DOCS_URL}")
    print(f"  GitHub Org: {GITHUB_ORG}")
    print(f"  GitHub Repo: {GITHUB_REPO}")