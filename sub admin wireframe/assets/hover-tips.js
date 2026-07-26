/**
 * GlowTap Sub Admin — hover tips for nav + Active branch
 */
(function () {
  var NAV_TIPS = {
    'dashboard.html': {
      title: 'Dashboard',
      body: 'Assigned-salon overview — KPIs, branch cards, alerts, and today’s ops. Multi-salon Sub Admins can filter with Active branch.'
    },
    'branches.html': {
      title: 'Branches',
      body: 'Your assigned salon locations only — status and profile.'
    },
    'branch-profile.html': {
      title: 'Branch Profile',
      body: 'Edit details for an assigned branch (if Branch Profile module is ON).'
    },
    'employees.html': {
      title: 'Employees',
      body: 'Staff on your assigned salons — add, edit, weekly offs.'
    },
    'leave-holidays.html': {
      title: 'Leave & Holidays',
      body: 'Leave and holidays for assigned salons.'
    },
    'attendance.html': {
      title: 'Attendance',
      body: 'Mark and review attendance for assigned salons.'
    },
    'services.html': {
      title: 'Services',
      body: 'Service catalog for assigned salons — price, specialists, slots.'
    },
    'appointments.html': {
      title: 'Appointments',
      body: 'Bookings for assigned salons only.'
    },
    'reports.html': {
      title: 'Reports',
      body: 'Branch-level reports for assigned salons (no org-level reports).'
    },
    'support.html': {
      title: 'Support',
      body: 'Raise and track your own support tickets.'
    },
    'login.html': {
      title: 'Sign out',
      body: 'End this Sub Admin session.'
    },
    'change-password.html': {
      title: 'Change Password',
      body: 'Update your Sub Admin login password.'
    }
  };

  var EXTRA_SELECTORS = [
    {
      sel: '[data-branch-scope]',
      title: 'Active branch',
      body: 'Filters this screen to your assigned salon(s). Default is All Assigned. Multi-select is supported.'
    },
    {
      sel: '.branch-scope-trigger',
      title: 'Active branch',
      body: 'Choose All Assigned or one/more of your assigned salons.'
    },
    {
      sel: '.sidebar-user-card',
      title: 'Signed-in Sub Admin',
      body: 'Your role and assigned-salon scope for this session.'
    }
  ];

  function fileKey(href) {
    if (!href) return '';
    var clean = href.split('#')[0].split('?')[0];
    var parts = clean.split('/');
    return parts[parts.length - 1] || '';
  }

  var tip = document.createElement('div');
  tip.className = 'hover-tip';
  tip.setAttribute('role', 'tooltip');
  tip.hidden = true;
  document.body.appendChild(tip);

  var hideTimer = null;

  function place(x, y) {
    var pad = 12;
    tip.style.left = '0px';
    tip.style.top = '0px';
    tip.hidden = false;
    tip.classList.add('is-on');
    var w = tip.offsetWidth;
    var h = tip.offsetHeight;
    var left = x + 14;
    var top = y + 14;
    if (left + w > window.innerWidth - pad) left = x - w - 12;
    if (top + h > window.innerHeight - pad) top = y - h - 12;
    if (left < pad) left = pad;
    if (top < pad) top = pad;
    tip.style.left = left + 'px';
    tip.style.top = top + 'px';
  }

  function show(title, body, x, y) {
    clearTimeout(hideTimer);
    tip.innerHTML =
      '<span class="hover-tip-title"></span><span class="hover-tip-body"></span>';
    tip.querySelector('.hover-tip-title').textContent = title;
    tip.querySelector('.hover-tip-body').textContent = body;
    place(x, y);
  }

  function hide() {
    hideTimer = setTimeout(function () {
      tip.classList.remove('is-on');
      tip.hidden = true;
    }, 80);
  }

  function bind(el, title, body) {
    if (!el || el.getAttribute('data-tip-bound') === '1') return;
    el.setAttribute('data-tip-bound', '1');
    el.addEventListener('mouseenter', function (e) {
      show(title, body, e.clientX, e.clientY);
    });
    el.addEventListener('mousemove', function (e) {
      if (!tip.hidden) place(e.clientX, e.clientY);
    });
    el.addEventListener('mouseleave', hide);
    el.addEventListener('focus', function () {
      var r = el.getBoundingClientRect();
      show(title, body, r.right, r.top);
    });
    el.addEventListener('blur', hide);
  }

  document.querySelectorAll('.nav a[href]').forEach(function (a) {
    var key = fileKey(a.getAttribute('href'));
    var info = NAV_TIPS[key];
    if (!info) {
      var label = (a.textContent || '').replace(/\s+/g, ' ').trim();
      if (!label) return;
      info = { title: label, body: 'Open the ' + label + ' section.' };
    }
    bind(a, info.title, info.body);
  });

  EXTRA_SELECTORS.forEach(function (item) {
    document.querySelectorAll(item.sel).forEach(function (el) {
      bind(el, item.title, item.body);
    });
  });

  document.querySelectorAll('[data-tip]').forEach(function (el) {
    var title = el.getAttribute('data-tip-title') || 'Details';
    var body = el.getAttribute('data-tip') || '';
    if (body) bind(el, title, body);
  });
})();
