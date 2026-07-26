/**
 * GlowTap Super Admin — Apply Active org selection to page content.
 * Mirrors Salon Admin branch-scope-filter for organizations.
 *
 * Markup: data-org="serenity" | data-orgs="serenity,blush" | data-org="platform"
 */
(function () {
  var LABELS = {
    serenity: 'Serenity Spa & Salon',
    blush: 'Blush Beauty Lounge',
    classic: 'Classic Cuts',
    radiance: 'Radiance Hair Studio',
    glow: 'Glow Studio',
    urban: 'Urban Edge Salon'
  };

  var NAME_ORDER = [
    ['Serenity Spa & Salon', 'serenity'],
    ['Blush Beauty Lounge', 'blush'],
    ['Radiance Hair Studio', 'radiance'],
    ['Urban Edge Salon', 'urban'],
    ['Classic Cuts', 'classic'],
    ['Glow Studio', 'glow'],
    ['Serenity', 'serenity'],
    ['Blush Beauty', 'blush'],
    ['Radiance', 'radiance'],
    ['Urban Edge', 'urban'],
    ['Classic Cuts', 'classic'],
    ['Glow Studio', 'glow'],
    ['ORG-001', 'serenity'],
    ['ORG-002', 'blush'],
    ['ORG-003', 'classic'],
    ['ORG-004', 'radiance'],
    ['ORG-005', 'glow'],
    ['ORG-006', 'urban']
  ];

  if (!document.getElementById('org-scope-filter-style')) {
    var style = document.createElement('style');
    style.id = 'org-scope-filter-style';
    style.textContent =
      '[data-org][hidden], [data-orgs][hidden], .org-card[hidden], tr[data-org][hidden] { display: none !important; }' +
      '.scope-empty { display:none; padding:28px 20px; text-align:center; color:var(--muted); font-size:0.875rem; }' +
      '.scope-empty.is-visible { display:block; }' +
      '.scope-banner { display:none; margin-bottom:14px; padding:10px 14px; border-radius:10px; border:1px solid color-mix(in srgb, var(--brand,#7B00FF) 25%, var(--border)); background: color-mix(in srgb, var(--surface-purple,#F3EEFF) 70%, white); font-size:0.8rem; color:var(--ink,#1A1A2E); }' +
      '.scope-banner.is-visible { display:flex; align-items:center; gap:12px; }';
    document.head.appendChild(style);
  }

  function inferIdFromText(text) {
    if (!text) return null;
    for (var i = 0; i < NAME_ORDER.length; i++) {
      if (text.indexOf(NAME_ORDER[i][0]) !== -1) return NAME_ORDER[i][1];
    }
    return null;
  }

  function parseIds(el) {
    if (el.hasAttribute('data-orgs')) {
      return el.getAttribute('data-orgs').split(',').map(function (s) { return s.trim(); }).filter(Boolean);
    }
    if (el.hasAttribute('data-org')) {
      var v = (el.getAttribute('data-org') || '').trim();
      return v ? [v] : [];
    }
    return null;
  }

  function ensureTagged(el) {
    var parsed = parseIds(el);
    if (parsed) return parsed;
    var id = inferIdFromText(el.textContent || '');
    if (id) {
      el.setAttribute('data-org', id);
      return [id];
    }
    return null;
  }

  function collectItems() {
    var set = [];
    var seen = typeof WeakSet !== 'undefined' ? new WeakSet() : null;
    function add(el) {
      if (!el || (seen && seen.has(el))) return;
      if (seen) seen.add(el);
      if (el.closest && el.closest('[data-org-scope]')) return;
      set.push(el);
    }
    document.querySelectorAll('[data-org], [data-orgs]').forEach(add);
    document.querySelectorAll('.data-table tbody tr, #org-cards .org-card, a.org-card, .ticket-row').forEach(add);
    return set;
  }

  function matches(ids, state) {
    if (!ids || !ids.length) return true;
    if (ids.indexOf('platform') !== -1 || ids.indexOf('org') !== -1 || ids.indexOf('*') !== -1) return true;
    if (!state || state.all || !state.ids || !state.ids.length) return true;
    for (var i = 0; i < ids.length; i++) {
      if (state.ids.indexOf(ids[i]) !== -1) return true;
    }
    return false;
  }

  function scopeLabel(state) {
    if (!state || state.all || !state.ids || !state.ids.length) return 'All Orgs';
    if (state.ids.length === 1) return LABELS[state.ids[0]] || state.ids[0];
    return state.ids.length + ' orgs';
  }

  function updateTitles(state) {
    var label = scopeLabel(state);
    document.querySelectorAll('[data-scope-title]').forEach(function (el) {
      var base = el.getAttribute('data-scope-title') || el.textContent.split(' · ')[0];
      el.setAttribute('data-scope-title', base);
      el.textContent = (!state || state.all || !state.ids || !state.ids.length) ? base : (base + ' · ' + label);
    });
    document.querySelectorAll('[data-scope-meta]').forEach(function (el) {
      var template = el.getAttribute('data-scope-meta');
      if (template) el.textContent = template.replace('{scope}', label);
    });
  }

  function listRoots() {
    var roots = Array.prototype.slice.call(document.querySelectorAll('[data-scope-list]'));
    document.querySelectorAll('.table-wrap, #org-cards, .cards-scroll').forEach(function (el) {
      if (roots.indexOf(el) === -1) roots.push(el);
    });
    return roots;
  }

  function ensureEmptyStates() {
    listRoots().forEach(function (list) {
      if (list.querySelector('.scope-empty')) return;
      if (!list.querySelector('[data-org], tbody tr, .org-card')) return;
      var empty = document.createElement('div');
      empty.className = 'scope-empty';
      empty.textContent = 'No records for the selected organization(s). Switch Active org or choose All Orgs.';
      list.appendChild(empty);
    });
  }

  function updateEmptyStates() {
    listRoots().forEach(function (list) {
      var rows = list.querySelectorAll('tbody tr, .org-card');
      if (!rows.length) return;
      var visible = 0;
      rows.forEach(function (r) { if (!r.hidden) visible += 1; });
      var empty = list.querySelector('.scope-empty');
      if (empty) empty.classList.toggle('is-visible', visible === 0);
    });
  }

  function updateBanner(state) {
    var main = document.querySelector('.app-content');
    if (!main) return;
    var banner = document.getElementById('scope-filter-banner');
    if (!banner) {
      banner = document.createElement('div');
      banner.id = 'scope-filter-banner';
      banner.className = 'scope-banner';
      banner.innerHTML = '<span data-scope-banner-text></span>';
      var hero = main.querySelector('.dashboard-hero');
      if (hero && hero.nextSibling) main.insertBefore(banner, hero.nextSibling);
      else main.insertBefore(banner, main.firstChild);
    }
    var filtered = state && !state.all && state.ids && state.ids.length;
    banner.classList.toggle('is-visible', !!filtered);
    var text = banner.querySelector('[data-scope-banner-text]');
    if (text && filtered) {
      text.textContent = 'Showing data for: ' + state.ids.map(function (id) { return LABELS[id] || id; }).join(', ') + '.';
    }
  }

  function apply(state) {
    ensureEmptyStates();
    collectItems().forEach(function (el) {
      el.hidden = !matches(ensureTagged(el), state);
    });
    updateTitles(state);
    updateEmptyStates();
    updateBanner(state);
    document.dispatchEvent(new CustomEvent('glowtap:org-scope-applied', { detail: state }));
  }

  document.addEventListener('glowtap:org-scope', function (e) {
    apply(e.detail || { all: true, ids: [] });
  });

  function boot() {
    var root = document.querySelector('[data-org-scope]');
    if (root) {
      var all = root.getAttribute('data-scope-all') === '1';
      var idsAttr = root.getAttribute('data-scope-ids') || '';
      var ids = idsAttr ? idsAttr.split(',').filter(Boolean) : [];
      apply({ all: all || !ids.length, ids: ids });
      return;
    }
    try {
      var raw = localStorage.getItem('glowtap.orgScope');
      if (raw) {
        var data = JSON.parse(raw);
        apply(data && data.all ? { all: true, ids: [] } : data);
        return;
      }
    } catch (err) {}
    apply({ all: true, ids: [] });
  }

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', boot);
  else boot();
})();
