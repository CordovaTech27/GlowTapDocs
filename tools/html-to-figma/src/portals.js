/**
 * Portal folder map for GlowTapDocs wireframes.
 */
const path = require('path');

const REPO_ROOT = path.resolve(__dirname, '..', '..', '..');

const PORTALS = {
  subadmin: {
    id: 'subadmin',
    name: 'Sub Admin',
    figmaPage: 'Sub Admin',
    dir: path.join(REPO_ROOT, 'sub admin wireframe'),
    urlPrefix: '/subadmin',
  },
  admin: {
    id: 'admin',
    name: 'Salon Admin',
    figmaPage: 'Salon Admin',
    dir: path.join(REPO_ROOT, 'wireframes_admin'),
    urlPrefix: '/admin',
  },
  super: {
    id: 'super',
    name: 'Super Admin',
    figmaPage: 'Super Admin',
    dir: path.join(REPO_ROOT, 'wireframes'),
    urlPrefix: '/super',
  },
};

const SKIP_FILES = new Set([
  'index.html',
  'login-figma.html',
]);

const SKIP_PREFIXES = ['login', 'forgot', 'reset', 'change-password', 'access-denied'];

function listHtmlFiles(portal, { includeAuth = false } = {}) {
  const fs = require('fs');
  const dir = portal.dir;
  if (!fs.existsSync(dir)) return [];
  return fs
    .readdirSync(dir)
    .filter((f) => f.endsWith('.html'))
    .filter((f) => {
      if (SKIP_FILES.has(f)) return false;
      if (includeAuth) return true;
      const base = f.replace(/\.html$/i, '');
      return !SKIP_PREFIXES.some((p) => base === p || base.startsWith(p + '-'));
    })
    .sort();
}

function resolvePortal(key) {
  const k = String(key || '').toLowerCase();
  if (PORTALS[k]) return PORTALS[k];
  if (k === 'sub' || k === 'sub-admin' || k === 'sub_admin') return PORTALS.subadmin;
  if (k === 'salon' || k === 'wireframes_admin') return PORTALS.admin;
  if (k === 'superadmin' || k === 'wireframes') return PORTALS.super;
  return null;
}

module.exports = {
  REPO_ROOT,
  PORTALS,
  listHtmlFiles,
  resolvePortal,
  EXPORT_ROOT: path.join(REPO_ROOT, 'figma-export'),
};
