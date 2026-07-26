/**
 * GlowTap Salon Admin — Apply Active branch selection to page content.
 * Works on every screen that includes this file after branch-scope.js.
 *
 * Shows only rows/cards/sections for the selected salon(s).
 * All Salons → everything visible.
 *
 * Markup:
 *   data-branch="bandra"              → one salon
 *   data-branches="bandra,koramangala" → any of these
 *   data-branch="org"                 → always visible (org-wide)
 *   data-branch-item                  → opt-in when auto-infer is off for a block
 *
 * Also auto-infers salon from known names inside:
 *   table tbody tr, .branch-card, .ticket-row, .cal-slot, [data-scope-row]
 */
(function () {
  var LABELS = {
    bandra: 'Bandra West',
    koramangala: 'Koramangala',
    andheri: 'Andheri East',
    powai: 'Powai Studio',
    juhu: 'Juhu Wave',
    indiranagar: 'Indiranagar',
    colaba: 'Colaba Pier'
  };

  // Mock per-salon KPIs for any page with [data-kpi] hooks
  // Sub Admin: only assigned salons (never Andheri / Powai / Colaba)
  var ASSIGNED = ['bandra', 'koramangala', 'juhu', 'indiranagar'];
  var KPI = {
    bandra: { apptsToday: 26, apptsWeek: 78, revToday: 31200, revWeek: 128000, revMonth: 510000, employees: 12, pending: 6 },
    koramangala: { apptsToday: 16, apptsWeek: 50, revToday: 17400, revWeek: 86000, revMonth: 330000, employees: 9, pending: 1 },
    juhu: { apptsToday: 11, apptsWeek: 34, revToday: 9800, revWeek: 42000, revMonth: 165000, employees: 6, pending: 1 },
    indiranagar: { apptsToday: 9, apptsWeek: 28, revToday: 8100, revWeek: 38000, revMonth: 148000, employees: 5, pending: 1 }
  };

  function money(n) {
    if (!isFinite(n) || n <= 0) return '₹0';
    if (n >= 100000) {
      var l = n / 100000;
      return '₹' + (l >= 10 ? l.toFixed(1) : String(Math.round(l * 100) / 100)) + 'L';
    }
    if (n >= 1000) return '₹' + (Math.round(n / 100) / 10) + 'K';
    return '₹' + Math.round(n).toLocaleString('en-IN');
  }

  function moneyFull(n) {
    return '₹' + Math.round(n || 0).toLocaleString('en-IN');
  }

  function applyKpis(state) {
    if (!document.querySelector('[data-kpi]')) return;
    var ids = (!state || state.all || !state.ids || !state.ids.length)
      ? ASSIGNED.slice()
      : state.ids.filter(function (id) { return ASSIGNED.indexOf(id) !== -1 && !!KPI[id]; });
    if (!ids.length) ids = ASSIGNED.slice();
    var sum = { apptsToday: 0, apptsWeek: 0, revToday: 0, revWeek: 0, revMonth: 0, employees: 0, pending: 0 };
    ids.forEach(function (id) {
      var k = KPI[id];
      if (!k) return;
      sum.apptsToday += k.apptsToday;
      sum.apptsWeek += k.apptsWeek;
      sum.revToday += k.revToday;
      sum.revWeek += k.revWeek;
      sum.revMonth += k.revMonth;
      sum.employees += k.employees;
      sum.pending += k.pending;
    });
    function set(key, val) {
      document.querySelectorAll('[data-kpi="' + key + '"]').forEach(function (el) {
        el.textContent = val;
      });
    }
    set('appts-today', String(sum.apptsToday));
    set('appts-week', String(sum.apptsWeek));
    set('rev-today', moneyFull(sum.revToday));
    set('rev-week', money(sum.revWeek));
    set('rev-month', money(sum.revMonth));
    set('employees', String(sum.employees));
    set('pending', String(sum.pending));
    var all = !state || state.all || !state.ids || !state.ids.length;
    var note = all ? 'On assigned salons' : (ids.length === 1 ? ('At ' + (LABELS[ids[0]] || ids[0])) : ('Across ' + ids.length + ' selected salons'));
    set('employees-note', note);
  }

  // Longer names first so "Andheri East" wins over partials
  var NAME_ORDER = [
    ['Andheri East', 'andheri'],
    ['Powai Studio', 'powai'],
    ['Bandra West', 'bandra'],
    ['Colaba Pier', 'colaba'],
    ['Juhu Wave', 'juhu'],
    ['Koramangala', 'koramangala'],
    ['Indiranagar', 'indiranagar'],
    ['Andheri', 'andheri'],
    ['Powai', 'powai'],
    ['Bandra', 'bandra'],
    ['Colaba', 'colaba'],
    ['Juhu', 'juhu']
  ];

  var STYLE_ID = 'branch-scope-filter-style';
  if (!document.getElementById(STYLE_ID)) {
    var style = document.createElement('style');
    style.id = STYLE_ID;
    style.textContent =
      '[data-branch][hidden], [data-branches][hidden], [data-scope-row][hidden], .branch-card[hidden], .ticket-row[hidden], .cal-slot[hidden], tr[data-branch][hidden] { display: none !important; }' +
      '.scope-empty { display:none; padding:28px 20px; text-align:center; color:var(--muted); font-size:0.875rem; }' +
      '.scope-empty.is-visible { display:block; }' +
      '.scope-banner { display:none; margin-bottom:14px; padding:10px 14px; border-radius:10px; border:1px solid color-mix(in srgb, var(--brand) 25%, var(--border)); background: color-mix(in srgb, var(--surface-purple) 70%, white); font-size:0.8rem; color:var(--ink); }' +
      '.scope-banner.is-visible { display:flex; align-items:center; justify-content:space-between; gap:12px; }';
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
    if (el.hasAttribute('data-branches')) {
      return el.getAttribute('data-branches').split(',').map(function (s) { return s.trim(); }).filter(Boolean);
    }
    if (el.hasAttribute('data-branch')) {
      var v = (el.getAttribute('data-branch') || '').trim();
      return v ? [v] : [];
    }
    return null;
  }

  function ensureTagged(el) {
    var parsed = parseIds(el);
    if (parsed) return parsed;
    var id = inferIdFromText(el.textContent || '');
    if (id) {
      el.setAttribute('data-branch', id);
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
      // Skip controls inside Active branch picker
      if (el.closest && el.closest('[data-branch-scope]')) return;
      set.push(el);
    }

    document.querySelectorAll('[data-branch], [data-branches], [data-scope-row]').forEach(add);
    document.querySelectorAll(
      '.data-table tbody tr, table.data-table tbody tr, #branch-cards .branch-card, a.branch-card, .ticket-row, .cal-slot.has, [data-scope-row]'
    ).forEach(add);

    return set;
  }

  function matches(ids, state) {
    if (!ids || !ids.length) return true; // untagged / org content
    if (ids.indexOf('org') !== -1 || ids.indexOf('*') !== -1) return true;
    if (!state || state.all || !state.ids || !state.ids.length) return true;
    for (var i = 0; i < ids.length; i++) {
      if (state.ids.indexOf(ids[i]) !== -1) return true;
    }
    return false;
  }

  function scopeLabel(state) {
    if (!state || state.all || !state.ids || !state.ids.length) return 'All Assigned';
    if (state.ids.length === 1) return LABELS[state.ids[0]] || state.ids[0];
    return state.ids.length + ' salons';
  }

  function updateTitles(state) {
    var label = scopeLabel(state);
    document.querySelectorAll('[data-scope-title]').forEach(function (el) {
      var base = el.getAttribute('data-scope-title') || el.textContent.split(' · ')[0];
      el.setAttribute('data-scope-title', base);
      if (!state || state.all || !state.ids || !state.ids.length) {
        el.textContent = base;
      } else {
        el.textContent = base + ' · ' + label;
      }
    });

    document.querySelectorAll('[data-scope-meta]').forEach(function (el) {
      var template = el.getAttribute('data-scope-meta');
      if (!template) return;
      el.textContent = template.replace('{scope}', label);
    });
  }

  function listRoots() {
    var roots = Array.prototype.slice.call(document.querySelectorAll('[data-scope-list]'));
    document.querySelectorAll('.table-wrap, #branch-cards, .branch-cards-scroll').forEach(function (el) {
      if (roots.indexOf(el) === -1) roots.push(el);
    });
    return roots;
  }

  function ensureEmptyStates() {
    listRoots().forEach(function (list) {
      var empty = list.querySelector('.scope-empty, [data-scope-empty]');
      if (!empty) {
        empty = document.createElement('div');
        empty.className = 'scope-empty';
        empty.setAttribute('data-scope-empty', '');
        empty.textContent = 'No records for the selected salon(s). Switch Active branch or choose All Salons.';
        list.appendChild(empty);
      }
    });
  }

  function updateEmptyStates() {
    listRoots().forEach(function (list) {
      var rows = list.querySelectorAll('tbody tr, .branch-card, .ticket-row, [data-scope-row]');
      var visible = 0;
      rows.forEach(function (r) {
        if (r.classList && r.classList.contains('scope-empty')) return;
        if (!r.hidden) visible += 1;
      });
      var empty = list.querySelector('.scope-empty, [data-scope-empty]');
      if (empty) empty.classList.toggle('is-visible', visible === 0);
    });
  }

  function updateBanner(state) {
    var main = document.querySelector('.main .content, .content, main');
    if (!main) return;
    var banner = document.getElementById('scope-filter-banner');
    if (!banner) {
      banner = document.createElement('div');
      banner.id = 'scope-filter-banner';
      banner.className = 'scope-banner';
      banner.innerHTML = '<span data-scope-banner-text></span>';
      var anchor = main.querySelector('.page-head, .hero, h1, .section-title');
      if (anchor && anchor.parentNode) {
        anchor.parentNode.insertBefore(banner, anchor.nextSibling);
      } else {
        main.insertBefore(banner, main.firstChild);
      }
    }
    var text = banner.querySelector('[data-scope-banner-text]');
    var filtered = state && !state.all && state.ids && state.ids.length;
    banner.classList.toggle('is-visible', !!filtered);
    if (text && filtered) {
      var names = state.ids.map(function (id) { return LABELS[id] || id; });
      text.textContent = 'Showing data for: ' + names.join(', ') + '. Change Active branch to adjust.';
    }
  }

  function apply(state) {
    ensureEmptyStates();
    var items = collectItems();
    items.forEach(function (el) {
      var ids = ensureTagged(el);
      // If still no ids after infer, keep visible (org / unlabeled)
      var show = matches(ids, state);
      el.hidden = !show;
    });
    updateTitles(state);
    updateEmptyStates();
    updateBanner(state);
    applyKpis(state);

    document.dispatchEvent(new CustomEvent('glowtap:branch-scope-applied', { detail: state }));
  }

  document.addEventListener('glowtap:branch-scope', function (e) {
    apply(e.detail || { all: true, ids: [] });
  });

  // If branch-scope already fired before this script loaded, read from DOM/storage
  function boot() {
    var root = document.querySelector('[data-branch-scope]');
    if (root) {
      var all = root.getAttribute('data-scope-all') === '1';
      var idsAttr = root.getAttribute('data-scope-ids') || '';
      var ids = idsAttr ? idsAttr.split(',').filter(Boolean) : [];
      apply({ all: all || !ids.length, ids: ids });
      return;
    }
    try {
      var raw = localStorage.getItem('glowtap.branchScope');
      if (raw) {
        var data = JSON.parse(raw);
        apply(data && data.all ? { all: true, ids: [] } : data);
        return;
      }
    } catch (err) {}
    apply({ all: true, ids: [] });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', boot);
  } else {
    boot();
  }
})();
