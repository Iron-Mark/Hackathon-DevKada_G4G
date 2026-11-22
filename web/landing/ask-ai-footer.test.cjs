const assert = require('assert');
const fs = require('fs');
const path = require('path');

const html = fs.readFileSync(path.join(__dirname, 'index.html'), 'utf8');

assert.match(html, /Ask your AI/);

for (const host of [
  'chatgpt.com',
  'claude.ai',
  'gemini.google.com',
  'www.perplexity.ai',
  'grok.com',
]) {
  assert.ok(html.includes(host), `missing provider host ${host}`);
}

assert.equal(/<h[1-6]\b[^>]*>\s*FAQ\b/i.test(html), false);
assert.match(html, /https%3A%2F%2Facsadians\.github\.io%2Fkudlit-app%2F/);
assert.equal(html.includes('__PUBLIC_SITE_URL__%2F'), false);

console.log('kudlit landing ask-ai footer ok');
