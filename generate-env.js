// Runs at build time (Vercel/Netlify build command) to turn the
// SUPABASE_URL / SUPABASE_ANON_KEY environment variables set in the
// hosting dashboard into a small browser-readable config file.
// This is the only place process.env is read — never inline env vars
// directly into committed source files.

const fs = require('fs');
const path = require('path');

const url = process.env.SUPABASE_URL;
const anonKey = process.env.SUPABASE_ANON_KEY;

if (!url || !anonKey) {
  console.error('SUPABASE_URL and SUPABASE_ANON_KEY must be set in your hosting provider\'s environment variables.');
  process.exit(1);
}

const output = `window.__ENV__ = ${JSON.stringify({ SUPABASE_URL: url, SUPABASE_ANON_KEY: anonKey })};\n`;

fs.writeFileSync(path.join(__dirname, '..', 'assets', 'js', 'env-config.js'), output);
console.log('Generated assets/js/env-config.js');
