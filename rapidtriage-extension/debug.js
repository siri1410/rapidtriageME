// Debug script to verify extension is updated
console.log('🚀 RapidTriage Extension Debug Info');
console.log('Version: 2.3.0-enhanced');
console.log('Last Updated:', new Date().toISOString());

// Check if functions exist
console.log('Functions check:');
console.log('- setButtonLoading:', typeof setButtonLoading);
console.log('- showPreview:', typeof showPreview);
console.log('- testServer:', typeof testServer);

// Check if animations are present
const hasSpinnerCSS = !!document.querySelector('style')?.textContent?.includes('@keyframes spin');
console.log('- Spinner CSS:', hasSpinnerCSS ? '✅ Present' : '❌ Missing');

// Check if buttons have correct onclick
const testButton = document.querySelector('button[onclick*="testServer"]');
const hasThisParam = testButton?.getAttribute('onclick')?.includes('this');
console.log('- Button passes "this":', hasThisParam ? '✅ Yes' : '❌ No');

// Test animation
console.log('\n📊 Testing animations...');
setTimeout(() => {
    const firstButton = document.querySelector('button');
    if (firstButton) {
        console.log('Adding loading class to first button...');
        firstButton.classList.add('loading');
        setTimeout(() => {
            firstButton.classList.remove('loading');
            console.log('Loading class removed');
        }, 2000);
    }
}, 1000);