// DevTools script - try multiple approaches for Chrome 138 compatibility
console.log('[RapidTriage] DevTools initializing...');

// Approach 1: Standard panel creation
setTimeout(() => {
    try {
        chrome.devtools.panels.create(
            "RapidTriage",
            null,
            "panel.html",
            function(panel) {
                if (chrome.runtime.lastError) {
                    console.error('[RapidTriage] Panel creation failed:', chrome.runtime.lastError.message);
                } else {
                    console.log('[RapidTriage] Main panel created successfully');
                }
            }
        );
    } catch (e) {
        console.error('[RapidTriage] Exception creating panel:', e);
    }
}, 100);

// Approach 2: Sidebar as primary option
setTimeout(() => {
    try {
        chrome.devtools.panels.elements.createSidebarPane(
            "RapidTriage",
            function(sidebar) {
                if (chrome.runtime.lastError) {
                    console.error('[RapidTriage] Sidebar creation failed:', chrome.runtime.lastError.message);
                } else {
                    console.log('[RapidTriage] Sidebar created successfully');
                    sidebar.setPage("panel.html");
                }
            }
        );
    } catch (e) {
        console.error('[RapidTriage] Exception creating sidebar:', e);
    }
}, 200);

// Approach 3: Sources panel extension
setTimeout(() => {
    try {
        chrome.devtools.panels.sources.createSidebarPane(
            "RapidTriage",
            function(sidebar) {
                if (chrome.runtime.lastError) {
                    console.error('[RapidTriage] Sources sidebar failed:', chrome.runtime.lastError.message);
                } else {
                    console.log('[RapidTriage] Sources sidebar created');
                    sidebar.setPage("panel.html");
                }
            }
        );
    } catch (e) {
        console.error('[RapidTriage] Exception creating sources sidebar:', e);
    }
}, 300);

console.log('[RapidTriage] DevTools script loaded');