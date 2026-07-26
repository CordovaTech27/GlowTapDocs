/**
 * GlowTap Salon Admin — Branch scope (Active branch)
 * Default: All Assigned Salons (label from checkbox span). Supports multi-select. Persists in localStorage.
 * Closes when clicking anywhere outside the control.
 */
(function () {
  var STORAGE_KEY = 'glowtap.branchScope';

  // Ensure [hidden] wins over .branch-scope-menu { display: flex }
  if (!document.getElementById('branch-scope-hidden-fix')) {
    var style = document.createElement('style');
    style.id = 'branch-scope-hidden-fix';
    style.textContent =
      '.branch-scope-menu[hidden]{display:none!important;}' +
      '.branch-scope-menu.is-open{display:flex;}';
    document.head.appendChild(style);
  }

  function loadSaved() {
    try {
      var raw = localStorage.getItem(STORAGE_KEY);
      if (!raw) return { all: true, ids: [] };
      var data = JSON.parse(raw);
      if (data && data.all) return { all: true, ids: [] };
      if (data && Array.isArray(data.ids) && data.ids.length) return { all: false, ids: data.ids };
    } catch (e) {}
    return { all: true, ids: [] };
  }

  function save(state) {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
    } catch (e) {}
  }

  function summaryText(root, state) {
    var allLabel = 'All Salons';
    var allInput = root.querySelector('input[data-branch-all]');
    if (allInput) {
      var allSpan = allInput.closest('label') && allInput.closest('label').querySelector('span');
      if (allSpan) allLabel = allSpan.textContent.trim() || allLabel;
    }
    if (state.all || !state.ids.length) return allLabel;
    var labels = [];
    state.ids.forEach(function (id) {
      var input = root.querySelector('input[data-branch-id][value="' + id + '"]');
      if (input) {
        var lab = input.closest('label');
        var span = lab && lab.querySelector('span');
        if (span) labels.push(span.textContent.trim());
      }
    });
    if (labels.length === 1) return labels[0];
    if (labels.length > 1) return labels.length + ' salons';
    return allLabel;
  }

  function applyState(root, state) {
    var allInput = root.querySelector('input[data-branch-all]');
    var branchInputs = root.querySelectorAll('input[data-branch-id]');
    if (allInput) allInput.checked = !!state.all;
    branchInputs.forEach(function (input) {
      input.checked = !state.all && state.ids.indexOf(input.value) !== -1;
    });
    var text = root.querySelector('.branch-scope-text');
    if (text) text.textContent = summaryText(root, state);
    root.setAttribute('data-scope-all', state.all ? '1' : '0');
    root.setAttribute('data-scope-ids', state.all ? '' : state.ids.join(','));
    document.dispatchEvent(new CustomEvent('glowtap:branch-scope', { detail: state }));
  }

  function readState(root) {
    var allInput = root.querySelector('input[data-branch-all]');
    var branchInputs = Array.prototype.slice.call(root.querySelectorAll('input[data-branch-id]'));
    if (allInput && allInput.checked) return { all: true, ids: [] };
    var ids = branchInputs.filter(function (i) { return i.checked; }).map(function (i) { return i.value; });
    if (!ids.length) return { all: true, ids: [] };
    return { all: false, ids: ids };
  }

  function setOpen(root, open) {
    var menu = root.querySelector('.branch-scope-menu');
    var btn = root.querySelector('.branch-scope-trigger');
    if (menu) {
      menu.hidden = !open;
      menu.classList.toggle('is-open', !!open);
    }
    if (btn) btn.setAttribute('aria-expanded', open ? 'true' : 'false');
  }

  function closeAll(except) {
    document.querySelectorAll('[data-branch-scope]').forEach(function (root) {
      if (except && root === except) return;
      setOpen(root, false);
    });
  }

  function isOpen(root) {
    var menu = root.querySelector('.branch-scope-menu');
    return !!(menu && !menu.hidden);
  }

  function initRoot(root) {
    var trigger = root.querySelector('.branch-scope-trigger');
    var menu = root.querySelector('.branch-scope-menu');
    if (!trigger || !menu) return;

    setOpen(root, false);

    var saved = loadSaved();
    var available = Array.prototype.map.call(root.querySelectorAll('input[data-branch-id]'), function (i) { return i.value; });
    if (!saved.all) {
      saved.ids = saved.ids.filter(function (id) { return available.indexOf(id) !== -1; });
      if (!saved.ids.length) saved = { all: true, ids: [] };
    }
    applyState(root, saved);

    trigger.addEventListener('click', function (e) {
      e.preventDefault();
      e.stopPropagation();
      var willOpen = !isOpen(root);
      closeAll();
      setOpen(root, willOpen);
    });

    menu.addEventListener('click', function (e) {
      e.stopPropagation();
    });

    root.querySelectorAll('input[data-branch-all], input[data-branch-id]').forEach(function (input) {
      input.addEventListener('change', function () {
        if (input.hasAttribute('data-branch-all') && input.checked) {
          root.querySelectorAll('input[data-branch-id]').forEach(function (b) { b.checked = false; });
        } else if (input.hasAttribute('data-branch-id') && input.checked) {
          var all = root.querySelector('input[data-branch-all]');
          if (all) all.checked = false;
        }
        var state = readState(root);
        if (state.all) {
          var allInput = root.querySelector('input[data-branch-all]');
          if (allInput) allInput.checked = true;
        }
        save(state);
        applyState(root, state);
      });
    });
  }

  function onOutsidePointer(e) {
    var target = e.target;
    if (target && target.closest && target.closest('[data-branch-scope]')) return;
    closeAll();
  }

  // Capture phase so it still closes even if something stops bubbling
  document.addEventListener('pointerdown', onOutsidePointer, true);
  document.addEventListener('click', onOutsidePointer, true);
  document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape') closeAll();
  });

  document.querySelectorAll('[data-branch-scope]').forEach(initRoot);
})();
