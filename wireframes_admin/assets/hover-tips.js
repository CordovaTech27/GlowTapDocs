/**
 * GlowTap Salon Admin — hover details for nav + key controls
 */
(function () {
  var NAV_TIPS = {
    'dashboard.html': {
      title: 'Dashboard',
      body: 'Org overview — KPIs, branch cards, alerts, and today’s operations.'
    },
    'organization.html': {
      title: 'Organization Profile',
      body: 'Business details, subscription, entitlements, invoices, and plan changes.'
    },
    'branches.html': {
      title: 'Branches',
      body: 'All salon locations — status, profile, and request a new branch.'
    },
    'sub-admins.html': {
      title: 'Sub Admins',
      body: 'Create and manage staff managers with branch + module access.'
    },
    'employees.html': {
      title: 'Employees',
      body: 'Salon staff — onboard, edit roles, weekly offs, activate or deactivate.'
    },
    'leave-holidays.html': {
      title: 'Leave & Holidays',
      body: 'Weekly offs, leave requests, and branch holiday calendar.'
    },
    'attendance.html': {
      title: 'Attendance',
      body: 'Mark and review staff in/out for the selected salon(s).'
    },
    'services.html': {
      title: 'Services',
      body: 'Service catalog — price, duration, specialists, slots, and availability.'
    },
    'appointments.html': {
      title: 'Appointments',
      body: 'Bookings list/calendar — confirm, reschedule, cancel, complete, refunds.'
    },
    'transactions.html': {
      title: 'Transactions',
      body: 'B2C payment history for the selected salon scope.'
    },
    'reports.html': {
      title: 'Reports',
      body: 'Business reports — appointments, revenue, staff, and more.'
    },
    'support.html': {
      title: 'Support',
      body: 'Raise and track support tickets with GlowTap.'
    },
    'login.html': {
      title: 'Sign out',
      body: 'End this admin session and return to the login screen.'
    },
    'branch-profile.html': {
      title: 'Branch Profile',
      body: 'Edit one salon’s address, hours, contact, and gallery.'
    },
    'request-branch.html': {
      title: 'Request Branch',
      body: 'Submit a new salon location for Super Admin approval.'
    },
    'change-plan.html': {
      title: 'Change Plan',
      body: 'Upgrade or change the organization subscription plan.'
    },
    'booking-history.html': {
      title: 'Booking History',
      body: 'Past appointments and booking timeline.'
    }
  };

  var EXTRA_SELECTORS = [
    {
      sel: '[data-branch-scope]',
      title: 'Active branch',
      body: 'Filters this screen’s data. Default is All Salons. Pick one or more salons to narrow the view.'
    },
    {
      sel: '.branch-scope-trigger',
      title: 'Active branch',
      body: 'Open to choose All Salons or specific salon(s). Multi-select is supported.'
    },
    {
      sel: '.sidebar-user-card',
      title: 'Signed-in admin',
      body: 'Your role and login email for this salon organization.'
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
    el.addEventListener('focus', function (e) {
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

  // Any element already marked in HTML
  document.querySelectorAll('[data-tip]').forEach(function (el) {
    var title = el.getAttribute('data-tip-title') || 'Details';
    var body = el.getAttribute('data-tip') || '';
    if (body) bind(el, title, body);
  });
})();
