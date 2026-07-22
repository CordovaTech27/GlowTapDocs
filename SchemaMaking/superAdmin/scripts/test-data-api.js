/**
 * Sign in via Neon Auth, fetch a JWT, and query the Data API.
 *
 * Prerequisites:
 * 1. Neon Auth enabled on the branch (neon_auth schema exists)
 * 2. Data API enabled with Neon Auth + public schema exposed
 * 3. Migration 012 applied
 * 4. .env has NEON_AUTH_URL, NEON_DATA_API_URL, and optional test credentials
 *
 * Usage:
 *   node SchemaMaking/superAdmin/scripts/test-data-api.js
 */
const fs = require('fs');
const path = require('path');

function loadEnvFile() {
  const envPath = path.join(__dirname, '..', '.env');
  if (!fs.existsSync(envPath)) return;

  for (const line of fs.readFileSync(envPath, 'utf8').split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;
    const eq = trimmed.indexOf('=');
    if (eq === -1) continue;
    const key = trimmed.slice(0, eq).trim();
    const value = trimmed.slice(eq + 1).trim();
    if (!process.env[key]) process.env[key] = value;
  }
}

loadEnvFile();

const authUrl = process.env.NEON_AUTH_URL;
const dataApiUrl = process.env.NEON_DATA_API_URL;
const email = process.env.NEON_AUTH_TEST_EMAIL || 'api-test@glowtap.com';
const password = process.env.NEON_AUTH_TEST_PASSWORD || 'GlowTap-Test-2026!';
const origin = process.env.NEON_AUTH_ORIGIN || 'http://localhost:3000';

if (!authUrl || !dataApiUrl) {
  console.error(
    'Set NEON_AUTH_URL and NEON_DATA_API_URL in SchemaMaking/superAdmin/.env\n' +
      'Copy both URLs from the Neon Console (Auth page + Data API page).'
  );
  process.exit(1);
}

function normalizeBase(url) {
  return url.replace(/\/$/, '');
}

async function signIn() {
  const base = normalizeBase(authUrl);
  const signUpUrl = `${base}/sign-up/email`;
  const signInUrl = `${base}/sign-in/email`;

  const body = JSON.stringify({
    email,
    password,
    name: 'API Test User',
    callbackURL: origin,
  });

  const headers = {
    'Content-Type': 'application/json',
    Origin: origin,
  };

  let res = await fetch(signInUrl, {
    method: 'POST',
    headers,
    body: JSON.stringify({ email, password }),
  });

  if (!res.ok && res.status === 404) {
    throw new Error(`Auth endpoint not found: ${signInUrl}`);
  }

  if (!res.ok) {
    res = await fetch(signUpUrl, { method: 'POST', headers, body });
  }

  if (!res.ok) {
    const text = await res.text();
    throw new Error(`Auth failed (${res.status}): ${text}`);
  }

  const setCookie = res.headers.getSetCookie?.() || [];
  const cookie = setCookie.map((c) => c.split(';')[0]).join('; ');
  if (!cookie) {
    throw new Error('No session cookie returned from Neon Auth sign-in');
  }

  return cookie;
}

async function getJwt(cookie) {
  const base = normalizeBase(authUrl);
  const res = await fetch(`${base}/get-session`, {
    headers: { Origin: origin, Cookie: cookie },
  });

  if (!res.ok) {
    const text = await res.text();
    throw new Error(`get-session failed (${res.status}): ${text}`);
  }

  const jwt =
    res.headers.get('set-auth-jwt') ||
    res.headers.get('Set-Auth-Jwt') ||
    res.headers.get('x-neon-jwt');

  if (!jwt) {
    throw new Error('No JWT in response headers (expected set-auth-jwt)');
  }

  return jwt;
}

async function queryOrganizations(jwt) {
  const base = normalizeBase(dataApiUrl);
  const url = `${base}/organizations?select=id,name,slug,status&limit=5`;

  const res = await fetch(url, {
    headers: {
      Authorization: `Bearer ${jwt}`,
      Accept: 'application/json',
    },
  });

  const text = await res.text();
  if (!res.ok) {
    throw new Error(`Data API failed (${res.status}): ${text}`);
  }

  return JSON.parse(text);
}

function printCurlExamples(jwt) {
  const base = normalizeBase(dataApiUrl);
  const auth = normalizeBase(authUrl);
  const authHeader = `Authorization: Bearer ${jwt}`;

  const queries = [
    ['organizations', `${base}/organizations?select=id,name,slug,status&limit=10`],
    ['branches', `${base}/branches?select=id,name,slug,status,is_primary&limit=10`],
    ['subscription_plans', `${base}/subscription_plans?select=id,name,max_branches`],
  ];

  console.log('\n--- curl (PowerShell: use curl.exe, one line each) ---\n');
  for (const [name, url] of queries) {
    console.log(`# ${name}`);
    console.log(
      `curl.exe "${url}" -H "${authHeader}" -H "Accept: application/json"`
    );
    console.log('');
  }

  console.log('# refresh JWT (~15 min expiry)');
  console.log(
    `curl.exe -X POST "${auth}/sign-in/email" -H "Content-Type: application/json" -H "Origin: ${origin}" -c cookies.txt -d "{\\"email\\":\\"${email}\\",\\"password\\":\\"${password}\\"}"`
  );
  console.log(
    `curl.exe "${auth}/get-session" -H "Origin: ${origin}" -b cookies.txt -D - -o NUL`
  );
}

async function main() {
  console.log('Neon Auth URL:', authUrl);
  console.log('Data API URL:', dataApiUrl);
  console.log('Test user:', email);

  const cookie = await signIn();
  console.log('Signed in OK');

  const jwt = await getJwt(cookie);
  console.log('JWT obtained (first 40 chars):', jwt.slice(0, 40) + '...');

  const orgs = await queryOrganizations(jwt);
  console.log('\norganizations (sample):');
  console.table(orgs);

  printCurlExamples(jwt);
}

main().catch((err) => {
  console.error(err.message);
  process.exit(1);
});
