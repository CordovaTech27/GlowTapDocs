import { Link } from 'react-router-dom'
import {
  Store,
  GitBranch,
  Ticket,
  CircleDollarSign,
  Building2,
  IndianRupee,
  Users,
  CreditCard,
  FileText,
  TicketPlus,
  ClipboardCheck,
} from 'lucide-react'
import { PageHeader } from '../components/PageHeader'
import { MetricCard } from '../components/MetricCard'
import { Card } from '../components/Card'
import { GradientButton } from '../components/GradientButton'
import { StatusBadge } from '../components/StatusBadge'
import { dashboardMetrics, alerts, revenueChart, tickets } from '../data/mockData'
import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts'
import { ChartTooltip } from '../components/ChartTooltip'

function formatCurrency(n: number) {
  if (n >= 100000) return `₹${(n / 100000).toFixed(1)}L`
  return `₹${n.toLocaleString('en-IN')}`
}

export function DashboardPage() {
  const pendingActions = [
    { label: 'Salon Approvals', count: dashboardMetrics.pendingSalonApprovals, icon: Store, path: '/dashboard/salon-approvals', color: 'text-purple-600 bg-purple-50' },
    { label: 'Branch Approvals', count: dashboardMetrics.pendingBranchApprovals, icon: GitBranch, path: '/dashboard/branch-approvals', color: 'text-pink-600 bg-pink-50' },
    { label: 'Open Tickets', count: dashboardMetrics.openTickets, icon: Ticket, path: '/dashboard/support', color: 'text-blue-600 bg-blue-50' },
    { label: 'Defaulters', count: dashboardMetrics.defaulterCount, icon: CircleDollarSign, path: '/dashboard/reports', color: 'text-amber-600 bg-amber-50' },
  ]

  return (
    <div>
      <PageHeader
        title="Platform Dashboard"
        description="At-a-glance view of platform health and pending actions."
        actions={
          <>
            <GradientButton variant="outline" size="sm">
              <span className="flex items-center gap-2">
                <FileText className="h-4 w-4" /> Export Report
              </span>
            </GradientButton>
            <GradientButton size="sm">
              <span className="flex items-center gap-2">
                <TicketPlus className="h-4 w-4" /> Create Ticket
              </span>
            </GradientButton>
          </>
        }
      />

      {/* Pending Actions */}
      <div className="mb-8 grid grid-cols-2 gap-4 lg:grid-cols-4">
        {pendingActions.map(({ label, count, icon: Icon, path, color }) => (
          <Link
            key={label}
            to={path}
            className="group flex flex-col gap-3 rounded-2xl border border-[#E2E8F0] bg-white p-5 shadow-[0_4px_20px_rgba(123,0,255,0.04)] transition hover:border-[#7B00FF]/25 hover:shadow-[0_8px_32px_rgba(123,0,255,0.1)]"
          >
            <div className={`self-start rounded-xl p-3 ${color}`}>
              <Icon className="h-5 w-5" />
            </div>
            <div>
              <p className="text-2xl font-bold text-[#1E2A32]">{count}</p>
              <p className="mt-0.5 text-[15px] font-semibold text-[#6B7A88] group-hover:text-[#7B00FF]">{label}</p>
            </div>
          </Link>
        ))}
      </div>

      {/* Key Metrics */}
      <div className="mb-8 grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-5">
        <MetricCard label="Active Salons" value={String(dashboardMetrics.activeSalons)} change="+12 this month" icon={Building2} accent="purple" />
        <MetricCard label="Total Branches" value={String(dashboardMetrics.totalBranches)} change="+28 this month" icon={GitBranch} accent="pink" />
        <MetricCard label="MRR" value={formatCurrency(dashboardMetrics.mrr)} change="+8.4% vs last month" icon={IndianRupee} accent="green" />
        <MetricCard label="Active End Users" value={dashboardMetrics.activeEndUsers.toLocaleString()} change="+1,240 this week" icon={Users} accent="blue" />
        <MetricCard label="Today's Volume" value={formatCurrency(dashboardMetrics.todayVolume)} change="142 transactions" icon={CreditCard} accent="purple" />
      </div>

      <div className="grid grid-cols-1 gap-6 xl:grid-cols-3">
        {/* Revenue Chart */}
        <Card title="Revenue Overview" className="xl:col-span-2">
          <div className="h-72">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={revenueChart}>
                <defs>
                  <linearGradient id="subGrad" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stopColor="#7B00FF" stopOpacity={0.2} />
                    <stop offset="100%" stopColor="#7B00FF" stopOpacity={0} />
                  </linearGradient>
                  <linearGradient id="comGrad" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stopColor="#FF03C8" stopOpacity={0.15} />
                    <stop offset="100%" stopColor="#FF03C8" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="#E2E8F0" vertical={false} />
                <XAxis dataKey="month" tick={{ fontSize: 12, fill: '#6B7A88' }} axisLine={false} tickLine={false} />
                <YAxis tick={{ fontSize: 12, fill: '#6B7A88' }} axisLine={false} tickLine={false} tickFormatter={(v) => `₹${v / 1000}K`} />
                <Tooltip content={<ChartTooltip />} />
                <Area type="monotone" dataKey="subscription" stroke="#7B00FF" fill="url(#subGrad)" strokeWidth={2.5} name="Subscription" />
                <Area type="monotone" dataKey="commission" stroke="#FF03C8" fill="url(#comGrad)" strokeWidth={2.5} name="Commission" />
              </AreaChart>
            </ResponsiveContainer>
          </div>
          <div className="mt-4 flex gap-6 text-sm text-[#6B7A88]">
            <div className="flex items-center gap-2">
              <span className="h-3 w-3 rounded-full bg-[#7B00FF]" /> Subscription Revenue
            </div>
            <div className="flex items-center gap-2">
              <span className="h-3 w-3 rounded-full bg-[#FF03C8]" /> Commission Revenue
            </div>
          </div>
        </Card>

        {/* Alerts */}
        <Card title="Alerts">
          <div className="space-y-3">
            {alerts.map((alert, i) => (
              <div
                key={i}
                className={`rounded-xl border p-4 ${
                  alert.type === 'danger'
                    ? 'border-red-100 bg-red-50/50'
                    : alert.type === 'warning'
                      ? 'border-amber-100 bg-amber-50/50'
                      : 'border-blue-100 bg-blue-50/50'
                }`}
              >
                <p className="text-sm text-gray-700">{alert.message}</p>
                <button type="button" className="mt-2 text-xs font-semibold text-purple-600 hover:text-purple-700">
                  {alert.action} →
                </button>
              </div>
            ))}
          </div>
        </Card>
      </div>

      {/* Quick Actions + Recent Tickets */}
      <div className="mt-6 grid grid-cols-1 gap-6 lg:grid-cols-2">
        <Card title="Quick Actions">
          <div className="grid grid-cols-2 gap-3">
            {[
              { label: 'Approve Salon', icon: ClipboardCheck, path: '/dashboard/salon-approvals' },
              { label: 'Defaulter Report', icon: CircleDollarSign, path: '/dashboard/reports' },
              { label: 'View Transactions', icon: CreditCard, path: '/dashboard/transactions' },
              { label: 'Create Ticket', icon: TicketPlus, path: '/dashboard/support' },
            ].map(({ label, icon: Icon, path }) => (
              <Link
                key={label}
                to={path}
                className="flex items-center gap-3 rounded-xl border border-[#E2E8F0] bg-[#f8f9fc] p-4 transition hover:border-[#7B00FF]/25 hover:bg-violet-50/50"
              >
                <Icon className="h-5 w-5 text-[#7B00FF]" />
                <span className="text-sm font-medium text-[#1E2A32]">{label}</span>
              </Link>
            ))}
          </div>
        </Card>

        <Card title="Recent Tickets">
          <div className="space-y-3">
            {tickets.map((ticket) => (
              <div key={ticket.id} className="flex items-center justify-between rounded-xl border border-gray-100 bg-[#f8f9fc] p-3">
                <div>
                  <p className="text-sm font-medium text-[#1E2A32]">{ticket.subject}</p>
                  <p className="text-xs text-[#6B7A88]">{ticket.id} · {ticket.salon}</p>
                </div>
                <StatusBadge status={ticket.priority} dot />
              </div>
            ))}
          </div>
        </Card>
      </div>
    </div>
  )
}
