import { NavLink, Outlet, useNavigate } from 'react-router-dom'
import {
  LayoutDashboard,
  Store,
  GitBranch,
  Building2,
  CreditCard,
  Receipt,
  BarChart3,
  Image,
  LineChart,
  LifeBuoy,
  Settings,
  ScrollText,
  Bell,
  Search,
  LogOut,
  ChevronDown,
  UserCog,
} from 'lucide-react'
import clsx from 'clsx'
import { LightGlowBackground } from '../components/LightGlowBackground'
import { dashboardMetrics } from '../data/mockData'

const navItems = [
  { label: 'Dashboard', path: '/dashboard', icon: LayoutDashboard },
  { label: 'Salon Approvals', path: '/dashboard/salon-approvals', icon: Store, badge: dashboardMetrics.pendingSalonApprovals },
  { label: 'Branch Approvals', path: '/dashboard/branch-approvals', icon: GitBranch, badge: dashboardMetrics.pendingBranchApprovals },
  { label: 'All Salons', path: '/dashboard/salons', icon: Building2 },
  { label: 'Transactions', path: '/dashboard/transactions', icon: CreditCard },
  { label: 'Subscription Management', path: '/dashboard/subscriptions', icon: Receipt },
  { label: 'Reports', path: '/dashboard/reports', icon: BarChart3 },
  { label: 'User Access Control', path: '/dashboard/users', icon: UserCog },
  { label: 'CMS & Banners', path: '/dashboard/cms', icon: Image },
  { label: 'Platform Analytics', path: '/dashboard/analytics', icon: LineChart },
  { label: 'Support & Ticketing', path: '/dashboard/support', icon: LifeBuoy, badge: dashboardMetrics.openTickets },
  { label: 'Master Configuration', path: '/dashboard/config', icon: Settings },
  { label: 'Audit Log', path: '/dashboard/audit', icon: ScrollText },
]

export function DashboardLayout() {
  const navigate = useNavigate()

  return (
    <div className="relative flex h-screen overflow-hidden bg-[#f8f9fc]">
      <LightGlowBackground />

      <aside className="relative z-10 flex w-[280px] shrink-0 flex-col border-r border-[#E2E8F0] bg-white shadow-[4px_0_24px_rgba(123,0,255,0.04)]">
        <nav className="flex-1 overflow-y-auto px-3 py-4 scrollbar-thin">
          <ul className="space-y-0.5">
            {navItems.map(({ label, path, icon: Icon, badge }) => (
              <li key={path}>
                <NavLink
                  to={path}
                  end={path === '/dashboard'}
                  className={({ isActive }) =>
                    clsx(
                      'group flex items-center gap-3 rounded-xl px-3.5 py-3 text-[15px] font-semibold transition-all',
                      isActive
                        ? 'gradient-brand text-white glow-purple'
                        : 'text-[#4A5568] hover:bg-violet-50 hover:text-[#7B00FF]',
                    )
                  }
                >
                  <Icon className="h-5 w-5 shrink-0" />
                  <span className="flex-1 truncate leading-snug">{label}</span>
                  {badge !== undefined && badge > 0 && (
                    <span className="rounded-full bg-[#FF03C8] px-2 py-0.5 text-[11px] font-bold text-white">
                      {badge}
                    </span>
                  )}
                </NavLink>
              </li>
            ))}
          </ul>
        </nav>

        <div className="border-t border-gray-100 p-4">
          <div className="flex items-center gap-3 rounded-xl bg-gray-50 px-3 py-2.5 ring-1 ring-gray-100">
            <div className="flex h-9 w-9 items-center justify-center rounded-full gradient-brand text-sm font-bold text-white">
              SA
            </div>
            <div className="min-w-0 flex-1">
              <p className="truncate text-sm font-medium text-[#1E2A32]">Super Admin</p>
              <p className="truncate text-xs text-[#6B7A88]">admin@glowtap.com</p>
            </div>
            <ChevronDown className="h-4 w-4 text-gray-400" />
          </div>
        </div>
      </aside>

      <div className="relative z-10 flex flex-1 flex-col overflow-hidden">
        <header className="flex h-16 shrink-0 items-center justify-between border-b border-[#E2E8F0]/80 bg-white/70 px-8 backdrop-blur-md">
          <div className="relative w-full max-w-md">
            <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-[#B0BAC4]" />
            <input
              type="search"
              placeholder="Search salons, transactions, tickets..."
              className="w-full rounded-full border border-[#E2E8F0] bg-[#f8f9fc] py-2 pl-10 pr-4 text-sm text-[#1E2A32] outline-none transition placeholder:text-[#B0BAC4] focus:border-[#7B00FF]/40 focus:bg-white focus:ring-2 focus:ring-[#7B00FF]/10"
            />
          </div>
          <div className="flex items-center gap-3">
            <button type="button" className="relative rounded-full p-2 text-[#6B7A88] transition hover:bg-violet-50 hover:text-[#7B00FF]">
              <Bell className="h-5 w-5" />
              <span className="absolute right-1.5 top-1.5 h-2 w-2 rounded-full bg-[#FF03C8] ring-2 ring-white" />
            </button>
            <button
              type="button"
              onClick={() => navigate('/login')}
              className="flex items-center gap-2 rounded-full px-3 py-2 text-sm text-[#6B7A88] transition hover:bg-violet-50 hover:text-[#7B00FF]"
            >
              <LogOut className="h-4 w-4" />
              Sign out
            </button>
          </div>
        </header>

        <main className="relative flex-1 overflow-y-auto bg-transparent p-8 scrollbar-thin">
          <Outlet />
        </main>
      </div>
    </div>
  )
}
