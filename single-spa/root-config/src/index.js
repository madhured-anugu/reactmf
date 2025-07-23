import { registerApplication, unregisterApplication, start } from 'single-spa';

// Make singleSpa globally available for dynamic loading
window.singleSpa = { 
  registerApplication, 
  unregisterApplication, 
  start 
};

// Start single-spa without any pre-registered applications
start({
  urlRerouteOnly: true,
});

console.log('Single-SPA root config initialized. Ready for dynamic micro-frontend loading.');
