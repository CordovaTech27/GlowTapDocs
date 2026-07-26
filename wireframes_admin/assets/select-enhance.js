/**
 * GlowTap branded select — replaces basic native dropdown popups.
 * Auto-enhances <select> (skips multiple / size / disabled / data-gt-native).
 */
(function () {
  if (window.GlowTapSelect) return;

  function injectStyles() {
    if (document.getElementById('gt-select-css')) return;
    var css = document.createElement('style');
    css.id = 'gt-select-css';
    css.textContent = [
      '.gt-sel { position: relative; display: block; width: 100%; }',
      '.gt-sel > select.gt-sel-native {',
      '  position: absolute !important; opacity: 0 !important; pointer-events: none !important;',
      '  width: 1px !important; height: 1px !important; margin: 0 !important; padding: 0 !important;',
      '  border: 0 !important; clip: rect(0 0 0 0) !important;',
      '}',
      '.gt-sel-trigger {',
      '  display: flex; align-items: center; justify-content: space-between; gap: 10px;',
      '  width: 100%; min-height: 40px; padding: 0 12px;',
      '  border: 1px solid var(--border, rgba(123,0,255,0.08)); border-radius: 10px;',
      '  background: rgba(255,255,255,0.72); color: var(--text, #1E2A32);',
      '  font-size: 0.85rem; font-weight: 600; font-family: inherit; cursor: pointer;',
      '  box-shadow: var(--shadow-card, 0 1px 2px rgba(26,26,46,0.04));',
      '  transition: border-color .15s, box-shadow .15s, background .15s, transform .12s;',
      '}',
      '.gt-sel-trigger:hover {',
      '  border-color: rgba(123,0,255,0.28); background: #fff;',
      '}',
      '.gt-sel.open .gt-sel-trigger,',
      '.gt-sel-trigger:focus {',
      '  outline: none; border-color: rgba(123,0,255,0.45);',
      '  box-shadow: 0 0 0 3px rgba(123,0,255,0.12);',
      '}',
      '.gt-sel-trigger .gt-sel-label {',
      '  overflow: hidden; text-overflow: ellipsis; white-space: nowrap; text-align: left;',
      '}',
      '.gt-sel-caret {',
      '  width: 16px; height: 16px; flex-shrink: 0; color: #7B00FF; opacity: 0.7;',
      '  transition: transform .2s ease;',
      '}',
      '.gt-sel.open .gt-sel-caret { transform: rotate(180deg); opacity: 1; }',
      '.gt-sel-menu {',
      '  position: fixed; z-index: 10050; box-sizing: border-box;',
      '  min-width: 140px; max-width: calc(100vw - 16px);',
      '  max-height: min(280px, calc(100vh - 16px)); overflow-y: auto; overflow-x: hidden;',
      '  padding: 8px; border-radius: 14px;',
      '  background: #fff; border: 1px solid rgba(123,0,255,0.12);',
      '  box-shadow: 0 16px 40px rgba(91,33,182,0.16);',
      '  scrollbar-width: thin; scrollbar-color: rgba(123,0,255,0.35) transparent;',
      '  animation: gtSelIn .16s ease;',
      '}',
      '.gt-sel-menu[hidden] { display: none !important; }',
      '@keyframes gtSelIn {',
      '  from { opacity: 0; transform: translateY(-6px) scale(0.98); }',
      '  to { opacity: 1; transform: translateY(0) scale(1); }',
      '}',
      '.gt-sel-menu::-webkit-scrollbar { width: 6px; }',
      '.gt-sel-menu::-webkit-scrollbar-thumb { background: rgba(123,0,255,0.28); border-radius: 999px; }',
      '.gt-sel-option {',
      '  display: flex; align-items: center; gap: 10px;',
      '  width: 100%; padding: 10px 12px; border: none; border-radius: 10px;',
      '  background: transparent; color: var(--text, #1E2A32);',
      '  font-size: 0.84rem; font-weight: 600; font-family: inherit; text-align: left;',
      '  cursor: pointer; transition: background .12s, color .12s, transform .12s;',
      '}',
      '.gt-sel-option:hover {',
      '  background: linear-gradient(135deg, #F3EEFF, #FDF2F8); color: #7B00FF;',
      '}',
      '.gt-sel-option.active {',
      '  background: linear-gradient(135deg, #7B00FF 0%, #9B2FD9 60%, #FF03C8 100%);',
      '  color: #fff; box-shadow: 0 4px 14px rgba(123,0,255,0.25);',
      '}',
      '.gt-sel-option.active:hover { color: #fff; }',
      '.gt-sel-option .gt-sel-check {',
      '  width: 14px; height: 14px; flex-shrink: 0; opacity: 0;',
      '}',
      '.gt-sel-option.active .gt-sel-check { opacity: 1; }',
      '.gt-sel.disabled .gt-sel-trigger { opacity: 0.55; cursor: not-allowed; }'
    ].join('\n');
    document.head.appendChild(css);
  }

  var PAD = 8;

  function optionLabel(opt) {
    return (opt && (opt.label || opt.textContent) || '').trim();
  }

  function fitToViewport(anchor, menu) {
    var rect = anchor.getBoundingClientRect();
    var vw = window.innerWidth;
    var vh = window.innerHeight;
    menu.style.visibility = 'hidden';
    menu.hidden = false;
    menu.style.left = '0px';
    menu.style.top = '0px';
    menu.style.width = '';
    menu.style.maxHeight = '';
    var width = Math.max(rect.width, 140);
    width = Math.min(width, vw - PAD * 2);
    menu.style.width = width + 'px';
    var spaceBelow = vh - rect.bottom - PAD;
    var spaceAbove = rect.top - PAD;
    var preferBelow = spaceBelow >= 160 || spaceBelow >= spaceAbove;
    var avail = preferBelow ? spaceBelow : spaceAbove;
    menu.style.maxHeight = Math.max(120, Math.min(280, avail - 4, vh - PAD * 2)) + 'px';
    var menuH = menu.offsetHeight;
    var top = preferBelow ? (rect.bottom + PAD) : (rect.top - menuH - PAD);
    if (top < PAD) top = PAD;
    if (top + menuH > vh - PAD) top = Math.max(PAD, vh - PAD - menuH);
    var left = rect.left;
    if (left + width > vw - PAD) left = vw - PAD - width;
    if (left < PAD) left = PAD;
    menu.style.top = Math.round(top) + 'px';
    menu.style.left = Math.round(left) + 'px';
    menu.style.visibility = '';
  }

  function enhance(select) {
    if (!select || select.tagName !== 'SELECT') return;
    if (select.dataset.gtSel === '1') return;
    if (select.multiple || select.size > 1) return;
    if (select.disabled) return;
    if (select.hasAttribute('data-gt-native')) return;
    if (select.closest('.gt-sel')) return;

    select.dataset.gtSel = '1';
    select.classList.add('gt-sel-native');

    var wrap = document.createElement('div');
    wrap.className = 'gt-sel';
    select.parentNode.insertBefore(wrap, select);
    wrap.appendChild(select);

    var trigger = document.createElement('button');
    trigger.type = 'button';
    trigger.className = 'gt-sel-trigger';
    trigger.setAttribute('aria-haspopup', 'listbox');
    trigger.setAttribute('aria-expanded', 'false');
    trigger.innerHTML =
      '<span class="gt-sel-label"></span>' +
      '<svg class="gt-sel-caret" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" aria-hidden="true"><path d="m6 9 6 6 6-6"/></svg>';
    wrap.appendChild(trigger);

    var menu = document.createElement('div');
    menu.className = 'gt-sel-menu';
    menu.hidden = true;
    menu.setAttribute('role', 'listbox');
    document.body.appendChild(menu);

    var labelEl = trigger.querySelector('.gt-sel-label');

    function selectedOpt() {
      return select.options[select.selectedIndex] || select.options[0];
    }

    function syncLabel() {
      labelEl.textContent = optionLabel(selectedOpt()) || 'Select';
    }

    function close() {
      menu.hidden = true;
      wrap.classList.remove('open');
      trigger.setAttribute('aria-expanded', 'false');
    }

    function open() {
      document.querySelectorAll('.gt-sel.open').forEach(function (el) {
        if (el !== wrap) {
          el.classList.remove('open');
          var t = el.querySelector('.gt-sel-trigger');
          if (t) t.setAttribute('aria-expanded', 'false');
        }
      });
      document.querySelectorAll('.gt-sel-menu:not([hidden])').forEach(function (m) {
        if (m !== menu) m.hidden = true;
      });
      renderMenu();
      fitToViewport(trigger, menu);
      wrap.classList.add('open');
      trigger.setAttribute('aria-expanded', 'true');
    }

    function reposition() {
      if (!menu.hidden) fitToViewport(trigger, menu);
    }

    function renderMenu() {
      var html = '';
      Array.prototype.forEach.call(select.options, function (opt, idx) {
        if (opt.hidden) return;
        var active = idx === select.selectedIndex;
        html +=
          '<button type="button" class="gt-sel-option' + (active ? ' active' : '') + '"' +
          ' role="option" data-index="' + idx + '" aria-selected="' + (active ? 'true' : 'false') + '"' +
          (opt.disabled ? ' disabled' : '') + '>' +
          '<svg class="gt-sel-check" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><path d="M20 6 9 17l-5-5"/></svg>' +
          '<span>' + optionLabel(opt).replace(/</g, '&lt;') + '</span>' +
          '</button>';
      });
      menu.innerHTML = html;
    }

    function pick(idx) {
      if (idx < 0 || idx >= select.options.length) return;
      if (select.options[idx].disabled) return;
      select.selectedIndex = idx;
      syncLabel();
      select.dispatchEvent(new Event('input', { bubbles: true }));
      select.dispatchEvent(new Event('change', { bubbles: true }));
      close();
    }

    trigger.addEventListener('click', function (e) {
      e.preventDefault();
      e.stopPropagation();
      if (menu.hidden) open(); else close();
    });

    menu.addEventListener('click', function (e) {
      e.stopPropagation();
      var btn = e.target.closest('.gt-sel-option');
      if (!btn) return;
      pick(Number(btn.dataset.index));
    });

    select.addEventListener('change', syncLabel);
    syncLabel();

    window.addEventListener('resize', reposition);
    window.addEventListener('scroll', reposition, true);
  }

  function init(root) {
    injectStyles();
    (root || document).querySelectorAll('select').forEach(enhance);
  }

  function closeAll() {
    document.querySelectorAll('.gt-sel.open').forEach(function (el) {
      el.classList.remove('open');
      var t = el.querySelector('.gt-sel-trigger');
      if (t) t.setAttribute('aria-expanded', 'false');
    });
    document.querySelectorAll('.gt-sel-menu:not([hidden])').forEach(function (m) {
      m.hidden = true;
    });
  }

  document.addEventListener('click', function (e) {
    if (e.target.closest('.gt-sel') || e.target.closest('.gt-sel-menu')) return;
    closeAll();
  });

  document.addEventListener('keydown', function (e) {
    if (e.key !== 'Escape') return;
    closeAll();
  });

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function () { init(); });
  } else {
    init();
  }

  window.GlowTapSelect = { init: init, enhance: enhance };
})();
