// Create RapidTriage DevTools panel
console.log('[RapidTriage] DevTools script starting...');

// Create the main panel immediately
chrome.devtools.panels.create(
    "RapidTriage",
    null, // no icon for now
    "panel.html",
    function(panel) {
        if (chrome.runtime.lastError) {
            console.error('[RapidTriage] Panel creation error:', chrome.runtime.lastError);
        } else {
            console.log('[RapidTriage] Panel created successfully!');
            
            // Store panel reference if needed
            window.rapidTriagePanel = panel;
        }
    }
);

// Also create a sidebar in Elements panel for quick access
chrome.devtools.panels.elements.createSidebarPane(
    "RapidTriage",
    function(sidebar) {
        if (chrome.runtime.lastError) {
            console.error('[RapidTriage] Sidebar error:', chrome.runtime.lastError);
        } else {
            console.log('[RapidTriage] Elements sidebar created!');
            sidebar.setPage("panel.html");
        }
    }
);

console.log('[RapidTriage] DevTools script completed');