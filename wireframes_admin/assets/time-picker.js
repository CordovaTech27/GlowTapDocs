/**
 * GlowTap branded time picker — replaces native misaligned browser time UI.
 * Auto-enhances input[type="time"] (skips disabled).
 * 12-hour UI with aligned Hour / Minute / AM·PM columns; stores 24h value.
 */
(function () {
  if (window.GlowTapTimePicker) return;

  var HOURS = ['12', '01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11'];
  var MINS = [];
  for (var m = 0; m < 60; m++) MINS.push(String(m).padStart(2, '0'));

  function injectStyles() {
    if (document.getElementById('gt-timepicker-css')) return;
    var css = document.createElement('style');
    css.id = 'gt-timepicker-css';
    css.textContent = [
      'input[type="time"].gt-tp-ready::-webkit-calendar-picker-indicator { opacity: 0; display: none; }',
      'input[type="time"].gt-tp-ready { color-scheme: light; cursor: pointer; }',
      '.gt-tp-wrap { position: relative; display: block; width: 100%; }',
      '.gt-tp-wrap > input[type="time"] { width: 100%; }',
      '.gt-tp-pop {',
      '  position: fixed; z-index: 10050; box-sizing: border-box;',
      '  width: min(280px, calc(100vw - 16px)); padding: 12px; border-radius: 16px;',
      '  background: #fff; border: 1px solid rgba(123,0,255,0.12);',
      '  box-shadow: 0 16px 40px rgba(91,33,182,0.16);',
      '  font-family: Outfit, DM Sans, sans-serif; color: #1E2A32;',
      '  animation: gtTpIn .16s ease; max-height: calc(100vh - 16px); overflow: auto;',
      '}',
      '.gt-tp-pop[hidden] { display: none !important; }',
      '@keyframes gtTpIn { from { opacity:0; transform:translateY(-6px) scale(.98);} to { opacity:1; transform:none; } }',
      '.gt-tp-display {',
      '  display: grid; grid-template-columns: 1fr auto 1fr auto 1fr; gap: 6px; align-items: center;',
      '  margin-bottom: 12px; padding: 10px 12px; border-radius: 12px;',
      '  background: linear-gradient(135deg, #F3EEFF, #FDF2F8);',
      '  border: 1px solid rgba(123,0,255,0.10); text-align: center;',
      '}',
      '.gt-tp-display strong {',
      '  font-size: 1.15rem; font-weight: 700; color: #5B21B6;',
      '  font-variant-numeric: tabular-nums;',
      '}',
      '.gt-tp-display .sep { color: #9B2FD9; font-weight: 700; font-size: 1.1rem; }',
      '.gt-tp-cols {',
      '  display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 8px;',
      '}',
      '.gt-tp-col {',
      '  display: flex; flex-direction: column; min-width: 0;',
      '  border: 1px solid rgba(123,0,255,0.10); border-radius: 12px;',
      '  overflow: hidden; background: #FBF9FF;',
      '}',
      '.gt-tp-col-label {',
      '  text-align: center; font-size: 0.65rem; font-weight: 700; text-transform: uppercase;',
      '  letter-spacing: 0.05em; color: #6B7A88; padding: 8px 4px 6px;',
      '  background: rgba(255,255,255,0.85); border-bottom: 1px solid rgba(123,0,255,0.08);',
      '}',
      '.gt-tp-list {',
      '  max-height: 180px; overflow-y: auto; overflow-x: hidden; padding: 4px;',
      '  scrollbar-width: thin; scrollbar-color: rgba(123,0,255,0.35) transparent;',
      '}',
      '.gt-tp-list::-webkit-scrollbar { width: 5px; }',
      '.gt-tp-list::-webkit-scrollbar-thumb { background: rgba(123,0,255,0.28); border-radius: 999px; }',
      '.gt-tp-opt {',
      '  display: flex; align-items: center; justify-content: center;',
      '  width: 100%; height: 34px; border: none; border-radius: 8px;',
      '  background: transparent; color: #1E2A32;',
      '  font-size: 0.85rem; font-weight: 600; font-family: inherit;',
      '  font-variant-numeric: tabular-nums; cursor: pointer;',
      '  transition: background .12s, color .12s;',
      '}',
      '.gt-tp-opt:hover { background: #F3EEFF; color: #7B00FF; }',
      '.gt-tp-opt.active {',
      '  background: linear-gradient(135deg, #7B00FF 0%, #9B2FD9 60%, #FF03C8 100%);',
      '  color: #fff; box-shadow: 0 3px 10px rgba(123,0,255,0.25);',
      '}',
      '.gt-tp-foot {',
      '  display: flex; justify-content: space-between; gap: 8px;',
      '  margin-top: 12px; padding-top: 10px; border-top: 1px solid rgba(123,0,255,0.08);',
      '}',
      '.gt-tp-foot button {',
      '  border: none; background: transparent; color: #7B00FF; font-weight: 700;',
      '  font-size: 0.8rem; cursor: pointer; font-family: inherit; padding: 7px 10px; border-radius: 8px;',
      '}',
      '.gt-tp-foot button:hover { background: #F3EEFF; }',
      '.gt-tp-foot .gt-tp-ok {',
      '  background: linear-gradient(135deg, #7B00FF, #9B2FD9); color: #fff;',
      '}',
      '.gt-tp-foot .gt-tp-ok:hover { opacity: .92; color: #fff; background: linear-gradient(135deg, #7B00FF, #9B2FD9); }'
    ].join('\n');
    document.head.appendChild(css);
  }

  var PAD = 8;

  function fitToViewport(anchor, pop) {
    var rect = anchor.getBoundingClientRect();
    var vw = window.innerWidth;
    var vh = window.innerHeight;
    pop.style.visibility = 'hidden';
    pop.hidden = false;
    pop.style.left = '0px';
    pop.style.top = '0px';
    pop.style.maxHeight = '';
    var popW = Math.min(280, vw - PAD * 2);
    pop.style.width = popW + 'px';
    var spaceBelow = vh - rect.bottom - PAD;
    var spaceAbove = rect.top - PAD;
    var preferBelow = spaceBelow >= 260 || spaceBelow >= spaceAbove;
    var avail = preferBelow ? spaceBelow : spaceAbove;
    pop.style.maxHeight = Math.max(200, Math.min(avail - 4, vh - PAD * 2)) + 'px';
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

  function parseValue(v) {
    if (!v || !/^\d{1,2}:\d{2}/.test(v)) return { h12: 10, min: 0, ampm: 'AM' };
    var parts = v.split(':');
    var h24 = parseInt(parts[0], 10);
    var min = parseInt(parts[1], 10) || 0;
    var ampm = h24 >= 12 ? 'PM' : 'AM';
    var h12 = h24 % 12;
    if (h12 === 0) h12 = 12;
    return { h12: h12, min: min, ampm: ampm };
  }

  function toValue(state) {
    var h12 = state.h12;
    var h24 = h12 % 12;
    if (state.ampm === 'PM') h24 += 12;
    if (state.ampm === 'AM' && h12 === 12) h24 = 0;
    return String(h24).padStart(2, '0') + ':' + String(state.min).padStart(2, '0');
  }

  function fmt12(state) {
    return String(state.h12).padStart(2, '0') + ':' + String(state.min).padStart(2, '0') + ' ' + state.ampm;
  }

  function enhance(input) {
    if (!input || input.type !== 'time' || input.dataset.gtTp === '1' || input.disabled) return;
    input.dataset.gtTp = '1';
    input.classList.add('gt-tp-ready');
    input.setAttribute('autocomplete', 'off');

    var wrap = document.createElement('div');
    wrap.className = 'gt-tp-wrap';
    input.parentNode.insertBefore(wrap, input);
    wrap.appendChild(input);

    var pop = document.createElement('div');
    pop.className = 'gt-tp-pop';
    pop.hidden = true;
    pop.setAttribute('role', 'dialog');
    pop.setAttribute('aria-label', 'Choose time');
    document.body.appendChild(pop);

    var state = parseValue(input.value);

    function close() { pop.hidden = true; }
    function open() {
      document.querySelectorAll('.gt-tp-pop:not([hidden])').forEach(function (el) {
        if (el !== pop) el.hidden = true;
      });
      state = parseValue(input.value || '10:00');
      render();
      fitToViewport(input, pop);
      scrollActive();
    }
    function reposition() {
      if (!pop.hidden) fitToViewport(input, pop);
    }

    function commit() {
      input.value = toValue(state);
      input.dispatchEvent(new Event('input', { bubbles: true }));
      input.dispatchEvent(new Event('change', { bubbles: true }));
    }

    function scrollActive() {
      pop.querySelectorAll('.gt-tp-list').forEach(function (list) {
        var active = list.querySelector('.gt-tp-opt.active');
        if (active) {
          list.scrollTop = Math.max(0, active.offsetTop - list.clientHeight / 2 + active.clientHeight / 2);
        }
      });
    }

    function render() {
      var hourBtns = HOURS.map(function (h) {
        var n = parseInt(h, 10);
        return '<button type="button" class="gt-tp-opt' + (n === state.h12 ? ' active' : '') + '" data-part="h" data-val="' + n + '">' + h + '</button>';
      }).join('');
      var minBtns = MINS.map(function (mm) {
        var n = parseInt(mm, 10);
        return '<button type="button" class="gt-tp-opt' + (n === state.min ? ' active' : '') + '" data-part="m" data-val="' + n + '">' + mm + '</button>';
      }).join('');
      var ampmBtns = ['AM', 'PM'].map(function (p) {
        return '<button type="button" class="gt-tp-opt' + (p === state.ampm ? ' active' : '') + '" data-part="p" data-val="' + p + '">' + p + '</button>';
      }).join('');

      pop.innerHTML =
        '<div class="gt-tp-display">' +
          '<strong data-disp="h">' + String(state.h12).padStart(2, '0') + '</strong>' +
          '<span class="sep">:</span>' +
          '<strong data-disp="m">' + String(state.min).padStart(2, '0') + '</strong>' +
          '<span class="sep"></span>' +
          '<strong data-disp="p">' + state.ampm + '</strong>' +
        '</div>' +
        '<div class="gt-tp-cols">' +
          '<div class="gt-tp-col"><div class="gt-tp-col-label">Hour</div><div class="gt-tp-list" data-list="h">' + hourBtns + '</div></div>' +
          '<div class="gt-tp-col"><div class="gt-tp-col-label">Min</div><div class="gt-tp-list" data-list="m">' + minBtns + '</div></div>' +
          '<div class="gt-tp-col"><div class="gt-tp-col-label">Period</div><div class="gt-tp-list" data-list="p">' + ampmBtns + '</div></div>' +
        '</div>' +
        '<div class="gt-tp-foot">' +
          '<button type="button" data-action="now">Now</button>' +
          '<button type="button" class="gt-tp-ok" data-action="ok">Done</button>' +
        '</div>';
    }

    pop.addEventListener('click', function (e) {
      e.stopPropagation();
      var t = e.target.closest('button');
      if (!t) return;
      if (t.dataset.action === 'ok') { commit(); close(); return; }
      if (t.dataset.action === 'now') {
        var d = new Date();
        var h24 = d.getHours();
        state.ampm = h24 >= 12 ? 'PM' : 'AM';
        state.h12 = h24 % 12; if (state.h12 === 0) state.h12 = 12;
        state.min = d.getMinutes();
        commit();
        render();
        fitToViewport(input, pop);
        scrollActive();
        return;
      }
      if (t.dataset.part === 'h') state.h12 = Number(t.dataset.val);
      if (t.dataset.part === 'm') state.min = Number(t.dataset.val);
      if (t.dataset.part === 'p') state.ampm = t.dataset.val;
      commit();
      render();
      fitToViewport(input, pop);
      scrollActive();
    });

    input.addEventListener('click', function (e) {
      e.preventDefault();
      if (pop.hidden) open(); else close();
    });
    input.addEventListener('mousedown', function (e) {
      if (e.detail) e.preventDefault();
    });
    input.addEventListener('keydown', function (e) {
      if (e.key === 'Escape') close();
      if (e.key === 'Enter' || e.key === ' ') {
        e.preventDefault();
        if (pop.hidden) open(); else close();
      }
    });

    window.addEventListener('resize', reposition);
    window.addEventListener('scroll', reposition, true);
  }

  function init(root) {
    injectStyles();
    (root || document).querySelectorAll('input[type="time"]').forEach(enhance);
  }

  document.addEventListener('click', function (e) {
    if (e.target.closest('.gt-tp-wrap') || e.target.closest('.gt-tp-pop')) return;
    document.querySelectorAll('.gt-tp-pop:not([hidden])').forEach(function (el) { el.hidden = true; });
  });

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function () { init(); });
  } else {
    init();
  }

  window.GlowTapTimePicker = { init: init, enhance: enhance };
})();
