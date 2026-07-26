/**
 * GlowTap Super Admin — hover tips for nav + Active org
 */
(function () {
  var NAV_TIPS = {
    'dashboard.html': {
      title: 'Dashboard',
      body: 'Platform health — alerts, KPIs, revenue, and pending actions.'
    },
    'salon-approvals.html': {
      title: 'Salon Approvals',
      body: 'Review and approve or reject new salon organization requests.'
    },
    'branch-approvals.html': {
      title: 'Branch Approvals',
      body: 'Review branch add requests from existing salon organizations.'
    },
    'all-salons.html': {
      title: 'All Salons',
      body: 'Browse every org/salon — status, plan, branches, and detail.'
    },
    'subscriptions.html': {
      title: 'Subscriptions',
      body: 'Plans, renewals, failed payments, and subscription lifecycle.'
    },
    'transactions.html': {
      title: 'Transactions',
      body: 'Platform payment and settlement activity across salons.'
    },
    'reports.html': {
      title: 'Reports',
      body: 'Platform reports — GMV, commissions, salon performance.'
    },
    'analytics.html': {
      title: 'Analytics',
      body: 'User growth, retention, and platform trend charts.'
    },
    'cms-banners.html': {
      title: 'CMS / Banners',
      body: 'Configure in-app banners and offers shown to salon admins.'
    },
    'master-config.html': {
      title: 'Master Config',
      body: 'Platform configuration — plans, limits, and master data.'
    },
    'notifications.html': {
      title: 'Notifications',
      body: 'Platform notification templates and delivery settings.'
    },
    'audit-log.html': {
      title: 'Audit Log',
      body: 'Immutable trail of Super Admin and system actions.'
    },
    'user-access.html': {
      title: 'User Access',
      body: 'Manage Super Admin users and access roles.'
    },
    'support.html': {
      title: 'Support',
      body: 'Platform support tickets raised by salon admins.'
    },
    'login.html': {
      title: 'Sign out',
      body: 'End this Super Admin session and return to login.'
    }
  };

  var EXTRA_SELECTORS = [
    {
      sel: '[data-org-scope]',
      title: 'Active org',
      body: 'Filters this screen’s data. Default is All Orgs. Pick one or more organizations to narrow the view.'
    },
    {
      sel: '.branch-scope-trigger',
      title: 'Active org',
      body: 'Open to choose All Orgs or specific organization(s). Multi-select is supported.'
    },
    {
      sel: '.sidebar-user-card',
      title: 'Signed-in Super Admin',
      body: 'Your platform role and login email.'
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
