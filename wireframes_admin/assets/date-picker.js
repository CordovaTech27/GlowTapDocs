/**
 * GlowTap branded date picker — replaces native browser calendar popup.
 * Auto-enhances input[type="date"] (skips disabled).
 * Popover uses position:fixed + viewport fit (escapes modal overflow).
 */
(function () {
  if (window.GlowTapDatePicker) return;

  var MONTHS = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  var DOW = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];
  var PAD = 8;

  function injectStyles() {
    if (document.getElementById('gt-datepicker-css')) return;
    var css = document.createElement('style');
    css.id = 'gt-datepicker-css';
    css.textContent = [
      'input[type="date"].gt-dp-ready::-webkit-calendar-picker-indicator { opacity: 0; display: none; }',
      'input[type="date"].gt-dp-ready { color-scheme: light; cursor: pointer; }',
      '.gt-dp-wrap { position: relative; display: block; }',
      '.gt-dp-wrap > input[type="date"] { width: 100%; }',
      '.gt-dp-pop {',
      '  position: fixed; z-index: 10050; box-sizing: border-box;',
      '  width: min(300px, calc(100vw - 16px)); padding: 14px; border-radius: 16px;',
      '  background: #fff; border: 1px solid rgba(123,0,255,0.12);',
      '  box-shadow: 0 16px 40px rgba(91,33,182,0.16);',
      '  font-family: Outfit, DM Sans, sans-serif; color: #1E2A32;',
      '  max-height: calc(100vh - 16px); overflow: auto;',
      '  scrollbar-width: thin; scrollbar-color: rgba(123,0,255,0.35) transparent;',
      '}',
      '.gt-dp-pop[hidden] { display: none !important; }',
      '.gt-dp-head { display: flex; align-items: center; justify-content: space-between; gap: 8px; margin-bottom: 12px; }',
      '.gt-dp-title { font-size: 0.95rem; font-weight: 700; color: #1E2A32; }',
      '.gt-dp-nav { display: flex; gap: 6px; }',
      '.gt-dp-nav button {',
      '  width: 32px; height: 32px; border-radius: 10px; border: 1px solid rgba(123,0,255,0.12);',
      '  background: linear-gradient(145deg, #fff, #F8F5FF); color: #7B00FF;',
      '  display: inline-flex; align-items: center; justify-content: center;',
      '  cursor: pointer; font-size: 0.85rem; font-weight: 700; line-height: 1;',
      '}',
      '.gt-dp-nav button:hover { border-color: rgba(123,0,255,0.35); background: #F3EEFF; }',
      '.gt-dp-dow {',
      '  display: grid; grid-template-columns: repeat(7, 1fr); gap: 2px; margin-bottom: 4px;',
      '}',
      '.gt-dp-dow span {',
      '  text-align: center; font-size: 0.68rem; font-weight: 700; color: #6B7A88;',
      '  text-transform: uppercase; letter-spacing: 0.04em; padding: 6px 0;',
      '}',
      '.gt-dp-grid { display: grid; grid-template-columns: repeat(7, 1fr); gap: 2px; }',
      '.gt-dp-day {',
      '  height: 34px; border: none; border-radius: 10px; background: transparent;',
      '  font-size: 0.84rem; font-weight: 600; color: #1E2A32; cursor: pointer;',
      '  font-family: inherit;',
      '}',
      '.gt-dp-day:hover:not(:disabled) { background: #F3EEFF; color: #7B00FF; }',
      '.gt-dp-day.muted { color: #B0B8C2; font-weight: 500; }',
      '.gt-dp-day.today { box-shadow: inset 0 0 0 1.5px rgba(123,0,255,0.35); }',
      '.gt-dp-day.selected {',
      '  background: linear-gradient(135deg, #7B00FF 0%, #9B2FD9 55%, #FF03C8 100%);',
      '  color: #fff; font-weight: 700; box-shadow: 0 4px 12px rgba(123,0,255,0.28);',
      '}',
      '.gt-dp-day.selected:hover { color: #fff; }',
      '.gt-dp-foot {',
      '  display: flex; justify-content: space-between; align-items: center;',
      '  margin-top: 12px; padding-top: 10px; border-top: 1px solid rgba(123,0,255,0.08);',
      '}',
      '.gt-dp-foot button {',
      '  border: none; background: transparent; color: #7B00FF; font-weight: 700;',
      '  font-size: 0.8rem; cursor: pointer; font-family: inherit; padding: 6px 8px; border-radius: 8px;',
      '}',
      '.gt-dp-foot button:hover { background: #F3EEFF; }',
      '.gt-dp-foot .gt-dp-today-btn {',
      '  background: linear-gradient(135deg, #7B00FF, #9B2FD9); color: #fff; padding: 6px 12px;',
      '}',
      '.gt-dp-foot .gt-dp-today-btn:hover { opacity: 0.92; background: linear-gradient(135deg, #7B00FF, #9B2FD9); color: #fff; }'
    ].join('\n');
    document.head.appendChild(css);
  }

  function fitToViewport(anchor, pop) {
    var rect = anchor.getBoundingClientRect();
    var vw = window.innerWidth;
    var vh = window.innerHeight;
    pop.style.visibility = 'hidden';
    pop.hidden = false;
    pop.style.left = '0px';
    pop.style.top = '0px';
    pop.style.maxHeight = '';
    pop.style.width = '';

    var popW = Math.min(300, vw - PAD * 2);
    pop.style.width = popW + 'px';

    var spaceBelow = vh - rect.bottom - PAD;
    var spaceAbove = rect.top - PAD;
    var preferBelow = spaceBelow >= 220 || spaceBelow >= spaceAbove;
    var avail = preferBelow ? spaceBelow : spaceAbove;
    var maxH = Math.max(180, Math.min(avail - 4, vh - PAD * 2));
    pop.style.maxHeight = maxH + 'px';

    var popH = pop.offsetHeight;
    var top = preferBelow ? (rect.bottom + PAD) : (rect.top - popH - PAD);
    if (top < PAD) top = PAD;
    if (top + popH > vh - PAD) top = Math.max(PAD, vh - PAD - popH);

    var left = rect.left;
    if (left + popW > vw - PAD) left = vw - PAD - popW;
    if (left < PAD) left = PAD;

    pop.style.top = Math.round(top) + 'px';
    pop.style.left = Math.round(left) + 'px';
    pop.style.visibility = '';
  }

  function parseISO(v) {
    if (!v || !/^\d{4}-\d{2}-\d{2}$/.test(v)) return null;
    var p = v.split('-').map(Number);
    return new Date(p[0], p[1] - 1, p[2]);
  }

  function toISO(d) {
    var y = d.getFullYear();
    var m = String(d.getMonth() + 1).padStart(2, '0');
    var day = String(d.getDate()).padStart(2, '0');
    return y + '-' + m + '-' + day;
  }

  function sameDay(a, b) {
    return a && b && a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
  }

  function enhance(input) {
    if (!input || input.type !== 'date' || input.dataset.gtDp === '1' || input.disabled) return;
    input.dataset.gtDp = '1';
    input.classList.add('gt-dp-ready');
    input.setAttribute('autocomplete', 'off');

    var wrap = document.createElement('div');
    wrap.className = 'gt-dp-wrap';
    input.parentNode.insertBefore(wrap, input);
    wrap.appendChild(input);

    var pop = document.createElement('div');
    pop.className = 'gt-dp-pop';
    pop.hidden = true;
    pop.setAttribute('role', 'dialog');
    pop.setAttribute('aria-label', 'Choose date');
    document.body.appendChild(pop);

    var view = parseISO(input.value) || new Date();
    view = new Date(view.getFullYear(), view.getMonth(), 1);

    function close() { pop.hidden = true; }
    function open() {
      document.querySelectorAll('.gt-dp-pop:not([hidden])').forEach(function (el) {
        if (el !== pop) el.hidden = true;
      });
      var sel = parseISO(input.value);
      view = new Date((sel || new Date()).getFullYear(), (sel || new Date()).getMonth(), 1);
      render();
      fitToViewport(input, pop);
    }

    function reposition() {
      if (!pop.hidden) fitToViewport(input, pop);
    }

    function pick(d) {
      input.value = toISO(d);
      input.dispatchEvent(new Event('input', { bubbles: true }));
      input.dispatchEvent(new Event('change', { bubbles: true }));
      close();
    }

    function render() {
      var selected = parseISO(input.value);
      var today = new Date();
      var y = view.getFullYear();
      var m = view.getMonth();
      var firstDow = new Date(y, m, 1).getDay();
      var daysInMonth = new Date(y, m + 1, 0).getDate();
      var prevDays = new Date(y, m, 0).getDate();

      var html = '';
      html += '<div class="gt-dp-head">';
      html += '<div class="gt-dp-title">' + MONTHS[m] + ' ' + y + '</div>';
      html += '<div class="gt-dp-nav">';
      html += '<button type="button" data-nav="-1" aria-label="Previous month">‹</button>';
      html += '<button type="button" data-nav="1" aria-label="Next month">›</button>';
      html += '</div></div>';
      html += '<div class="gt-dp-dow">' + DOW.map(function (d) { return '<span>' + d + '</span>'; }).join('') + '</div>';
      html += '<div class="gt-dp-grid">';

      var cells = [];
      var i;
      for (i = 0; i < firstDow; i++) {
        cells.push({ day: prevDays - firstDow + 1 + i, monthOffset: -1 });
      }
      for (i = 1; i <= daysInMonth; i++) {
        cells.push({ day: i, monthOffset: 0 });
      }
      var nextDay = 1;
      while (cells.length % 7 !== 0) {
        cells.push({ day: nextDay++, monthOffset: 1 });
      }

      cells.forEach(function (c) {
        var d = new Date(y, m + c.monthOffset, c.day);
        var cls = ['gt-dp-day'];
        if (c.monthOffset !== 0) cls.push('muted');
        if (sameDay(d, today)) cls.push('today');
        if (sameDay(d, selected)) cls.push('selected');
        html += '<button type="button" class="' + cls.join(' ') + '" data-iso="' + toISO(d) + '">' + c.day + '</button>';
      });
      html += '</div>';
      html += '<div class="gt-dp-foot">';
      html += '<button type="button" data-action="clear">Clear</button>';
      html += '<button type="button" class="gt-dp-today-btn" data-action="today">Today</button>';
      html += '</div>';
      pop.innerHTML = html;
    }

    pop.addEventListener('click', function (e) {
      e.stopPropagation();
      var t = e.target.closest('button');
      if (!t) return;
      if (t.dataset.nav) {
        view = new Date(view.getFullYear(), view.getMonth() + Number(t.dataset.nav), 1);
        render();
        fitToViewport(input, pop);
        return;
      }
      if (t.dataset.action === 'clear') {
        input.value = '';
        input.dispatchEvent(new Event('input', { bubbles: true }));
        input.dispatchEvent(new Event('change', { bubbles: true }));
        close();
        return;
      }
      if (t.dataset.action === 'today') {
        pick(new Date());
        return;
      }
      if (t.dataset.iso) pick(parseISO(t.dataset.iso));
    });

    input.addEventListener('click', function (e) {
      e.preventDefault();
      if (pop.hidden) open(); else close();
    });
    input.addEventListener('keydown', function (e) {
      if (e.key === 'Escape') close();
      if (e.key === 'Enter' || e.key === ' ') {
        e.preventDefault();
        if (pop.hidden) open(); else close();
      }
    });
    input.addEventListener('mousedown', function (e) {
      if (e.detail) e.preventDefault();
    });

    window.addEventListener('resize', reposition);
    window.addEventListener('scroll', reposition, true);
  }

  function init(root) {
    injectStyles();
    (root || document).querySelectorAll('input[type="date"]').forEach(enhance);
  }

  document.addEventListener('click', function (e) {
    if (e.target.closest('.gt-dp-wrap') || e.target.closest('.gt-dp-pop')) return;
    document.querySelectorAll('.gt-dp-pop:not([hidden])').forEach(function (el) { el.hidden = true; });
  });

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function () { init(); });
  } else {
    init();
  }

  window.GlowTapDatePicker = { init: init, enhance: enhance };
})();
