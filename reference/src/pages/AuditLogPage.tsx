import { PageHeader } from '../components/PageHeader'
import { Card } from '../components/Card'
import { GradientButton } from '../components/GradientButton'
import { Download } from 'lucide-react'

const auditEntries = [
  { id: 1, user: 'Super Admin', action: 'Salon Approved', target: 'Luxe Curls Studio (SL-1042)', before: 'Pending Review', after: 'Active · Commission 8%', timestamp: '2026-06-20 09:14:32', ip: '103.21.45.88' },
  { id: 2, user: 'Super Admin', action: 'Commission Updated', target: 'Blush Beauty Lounge', before: '8%', after: '10%', timestamp: '2026-06-19 16:42:11', ip: '103.21.45.88' },
  { id: 3, user: 'Ops Team A', action: 'Ticket Status Changed', target: 'TKT-4412', before: 'Created', after: 'In Progress', timestamp: '2026-06-19 14:20:05', ip: '103.21.45.92' },
  { id: 4, user: 'Super Admin', action: 'Salon Suspended', target: 'Classic Cuts', before: 'Active', after: 'Suspended · Non-payment', timestamp: '2026-06-18 11:05:44', ip: '103.21.45.88' },
  { id: 5, user: 'Super Admin', action: 'Plan Discount Applied', target: 'Radiance Hair Studio', before: 'RC: ₹750/mo', after: 'RC: ₹600/mo (20% RC discount)', timestamp: '2026-06-17 10:30:22', ip: '103.21.45.88' },
  { id: 6, user: 'Super Admin', action: 'User Disabled', target: 'Sub Admin: spam@test.com', before: 'Active', after: 'Disabled · Fraud detected', timestamp: '2026-06-16 08:15:00', ip: '103.21.45.88' },
]

export function AuditLogPage() {
  return (
    <div>
      <PageHeader
        title="Audit Log"
        description="Immutable record of all Super Admin actions — retention minimum 2 years."
        actions={
          <GradientButton variant="outline" size="sm">
            <span className="flex items-center gap-2"><Download className="h-4 w-4" /> Export</span>
          </GradientButton>
        }
      />

      <Card noPadding>
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-gray-100 bg-gray-50/50">
                {['Timestamp', 'User', 'Action', 'Target', 'Before', 'After', 'IP Address'].map((h) => (
                  <th key={h} className="px-4 py-3 text-left text-xs font-semibold uppercase text-gray-500">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50">
              {auditEntries.map((e) => (
                <tr key={e.id} className="hover:bg-purple-50/20">
                  <td className="whitespace-nowrap px-4 py-3 font-mono text-xs text-gray-500">{e.timestamp}</td>
                  <td className="px-4 py-3 font-medium">{e.user}</td>
                  <td className="px-4 py-3">
                    <span className="rounded-lg bg-purple-50 px-2 py-1 text-xs font-medium text-purple-700">{e.action}</span>
                  </td>
                  <td className="px-4 py-3 text-gray-600">{e.target}</td>
                  <td className="px-4 py-3 text-gray-400 line-through">{e.before}</td>
                  <td className="px-4 py-3 font-medium text-gray-900">{e.after}</td>
                  <td className="px-4 py-3 font-mono text-xs text-gray-400">{e.ip}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </Card>
    </div>
  )
}
