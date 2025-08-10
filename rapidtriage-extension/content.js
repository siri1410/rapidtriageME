// Content script to help DevTools extension communication
(function() {
    'use strict';
    
    // Mark page as having RapidTriage extension
    if (!window.__RAPIDTRIAGE__) {
        window.__RAPIDTRIAGE__ = {
            version: '2.3.0',
            ready: true
        };
        
        // Signal to DevTools that content script is loaded
        console.log('[RapidTriage] Content script loaded');
    }
})();