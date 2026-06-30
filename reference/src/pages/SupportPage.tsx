import { Clock, User, Ticket, ClockAlert, Timer, TicketPlus } from 'lucide-react'
import { PageHeader } from '../components/PageHeader'
import { Card } from '../components/Card'
import { GradientButton } from '../components/GradientButton'
import { StatusBadge } from '../components/StatusBadge'
import { MetricCard } from '../components/MetricCard'
import { tickets, dashboardMetrics } from '../data/mockData'

export function SupportPage() {
  return (
    <div>
      <PageHeader
        title="Support & Ticketing"
        description="Platform-level and salon-raised support tickets."
        actions={
          <GradientButton size="sm">
            <span className="flex items-center gap-2"><TicketPlus className="h-4 w-4" /> Create Ticket</span>
          </GradientButton>
        }
      />

      <div className="mb-8 grid grid-cols-1 gap-4 sm:grid-cols-3">
        <MetricCard label="Open Tickets" value={String(dashboardMetrics.openTickets)} icon={Ticket} accent="purple" />
        <MetricCard label="Avg Resolution" value="6.2 hrs" change="-12% vs last month" icon={Timer} accent="blue" changeType="up" />
        <MetricCard label="Overdue SLA" value="3" change="Critical priority" icon={ClockAlert} accent="pink" changeType="down" />
      </div>

      <Card noPadding>
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-gray-100 bg-gray-50/50">
                {['Ticket ID', 'Subject', 'Salon', 'Priority', 'Status', 'Assignee', 'Created', 'SLA', 'Actions'].map((h) => (
                  <th key={h} className="px-4 py-3 text-left text-xs font-semibold uppercase text-gray-500">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50">
              {tickets.map((t) => (
                <tr key={t.id} className="hover:bg-purple-50/20">
                  <td className="px-4 py-3 font-mono text-xs text-purple-600">{t.id}</td>
                  <td className="px-4 py-3 font-medium max-w-[200px] truncate">{t.subject}</td>
                  <td className="px-4 py-3 text-gray-600">{t.salon ?? '—'}</td>
                  <td className="px-4 py-3"><StatusBadge status={t.priority} dot /></td>
                  <td className="px-4 py-3"><StatusBadge status={t.status} /></td>
                  <td className="px-4 py-3">
                    {t.assignee ? (
                      <span className="flex items-center gap-1 text-gray-600"><User className="h-3.5 w-3.5" /> {t.assignee}</span>
                    ) : (
                      <span className="text-gray-400">Unassigned</span>
                    )}
                  </td>
                  <td className="px-4 py-3 text-gray-500">{t.createdAt}</td>
                  <td className="px-4 py-3">
                    <span className="flex items-center gap-1 text-gray-500"><Clock className="h-3.5 w-3.5" /> {t.slaHours}h</span>
                  </td>
                  <td className="px-4 py-3">
                    <GradientButton variant="outline" size="sm">View</GradientButton>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </Card>
    </div>
  )
}
