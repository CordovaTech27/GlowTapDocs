import { Download, Phone, Mail, AlertTriangle } from 'lucide-react'
import { PageHeader } from '../components/PageHeader'
import { Card } from '../components/Card'
import { GradientButton } from '../components/GradientButton'
import { StatusBadge } from '../components/StatusBadge'

const defaulters = [
  { salon: 'Classic Cuts', owner: 'Vikram Iyer', email: 'vikram@classiccuts.in', phone: '+91 98765 00001', outstanding: 833, daysOverdue: 12, plan: 'Growth 6M', lastPayment: '2026-06-08', action: 'Call' },
  { salon: 'Style Hub', owner: 'Meera Nair', email: 'meera@stylehub.in', phone: '+91 98765 00002', outstanding: 750, daysOverdue: 8, plan: 'Professional 12M', lastPayment: '2026-06-12', action: 'Send Reminder' },
  { salon: 'Fade Factory', owner: 'Dev Patel', email: 'dev@fadefactory.in', phone: '+91 98765 00003', outstanding: 999, daysOverdue: 21, plan: 'Starter 1M', lastPayment: '2026-05-30', action: 'Suspend Warning' },
]

const reportTypes = [
  { name: 'Daily Defaulter Report', desc: 'Salons with outstanding subscription payments', primary: true },
  { name: 'Revenue Summary', desc: 'MRR, ARR, subscription & commission revenue' },
  { name: 'Commission Report', desc: 'Commission by salon, city, and period' },
  { name: 'Salon Growth', desc: 'Onboardings, approvals, rejection rate' },
  { name: 'Branch Activity', desc: 'Branch additions and utilization by plan' },
  { name: 'Transaction Volume', desc: 'End-user transaction trends' },
  { name: 'Churn & Retention', desc: 'Non-renewals and downgrade patterns' },
  { name: 'Support SLA', desc: 'Ticket volume and resolution times' },
  { name: 'Plan Distribution', desc: 'Salons by tier and upgrade funnel' },
  { name: 'Geographic Performance', desc: 'Salons and revenue by city/region' },
]

export function ReportsPage() {
  return (
    <div>
      <PageHeader
        title="Reports"
        description="Daily defaulter report and platform analytics exports."
        actions={
          <GradientButton variant="outline" size="sm">
            <span className="flex items-center gap-2"><Download className="h-4 w-4" /> Export All</span>
          </GradientButton>
        }
      />

      <Card title="Daily Defaulter Report — Primary" className="mb-6">
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-gray-100">
                {['Salon', 'Contact', 'Outstanding', 'Days Overdue', 'Plan', 'Last Payment', 'Recommended Action', 'Actions'].map((h) => (
                  <th key={h} className="px-4 py-3 text-left text-xs font-semibold uppercase text-gray-500">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50">
              {defaulters.map((d) => (
                <tr key={d.salon} className="hover:bg-amber-50/30">
                  <td className="px-4 py-3">
                    <p className="font-semibold">{d.salon}</p>
                    <p className="text-xs text-gray-400">{d.owner}</p>
                  </td>
                  <td className="px-4 py-3">
                    <div className="flex gap-2">
                      <button type="button" className="text-purple-600"><Phone className="h-4 w-4" /></button>
                      <button type="button" className="text-purple-600"><Mail className="h-4 w-4" /></button>
                    </div>
                  </td>
                  <td className="px-4 py-3 font-semibold text-red-600">₹{d.outstanding}</td>
                  <td className="px-4 py-3">
                    <span className="flex items-center gap-1 text-amber-600">
                      <AlertTriangle className="h-3.5 w-3.5" /> {d.daysOverdue}d
                    </span>
                  </td>
                  <td className="px-4 py-3">{d.plan}</td>
                  <td className="px-4 py-3 text-gray-500">{d.lastPayment}</td>
                  <td className="px-4 py-3"><StatusBadge status={d.action === 'Call' ? 'High' : d.action === 'Send Reminder' ? 'Medium' : 'Critical'} /></td>
                  <td className="px-4 py-3">
                    <GradientButton size="sm" variant="outline">Log Call</GradientButton>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </Card>

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {reportTypes.slice(1).map((r) => (
          <Card key={r.name}>
            <h4 className="font-semibold text-gray-900">{r.name}</h4>
            <p className="mt-1 text-sm text-gray-500">{r.desc}</p>
            <GradientButton variant="outline" size="sm" className="mt-4">
              <span className="flex items-center gap-2"><Download className="h-3.5 w-3.5" /> Generate</span>
            </GradientButton>
          </Card>
        ))}
      </div>
    </div>
  )
}
