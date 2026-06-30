import { useState } from 'react'
import { CheckCircle, XCircle, MessageSquare, Filter, Download } from 'lucide-react'
import { PageHeader } from '../components/PageHeader'
import { Card } from '../components/Card'
import { GradientButton } from '../components/GradientButton'
import { StatusBadge } from '../components/StatusBadge'
import { salonLeads } from '../data/mockData'

export function SalonApprovalsPage() {
  const [selected, setSelected] = useState<string | null>('SL-1042')
  const [commission, setCommission] = useState(8)
  const lead = salonLeads.find((l) => l.id === selected)

  return (
    <div>
      <PageHeader
        title="Salon Approvals"
        description="Review new subscription leads and onboard salon owners."
        actions={
          <>
            <GradientButton variant="outline" size="sm">
              <span className="flex items-center gap-2"><Filter className="h-4 w-4" /> Filters</span>
            </GradientButton>
            <GradientButton variant="outline" size="sm">
              <span className="flex items-center gap-2"><Download className="h-4 w-4" /> Export</span>
            </GradientButton>
          </>
        }
      />

      <div className="grid grid-cols-1 gap-6 xl:grid-cols-5">
        <Card className="xl:col-span-2" noPadding>
          <div className="border-b border-gray-50 px-6 py-4">
            <div className="flex gap-2">
              {['All', 'Pending', 'Awaiting Info', 'Approved', 'Rejected'].map((tab) => (
                <button
                  key={tab}
                  type="button"
                  className={`rounded-full px-3 py-1 text-xs font-medium transition ${
                    tab === 'Pending' ? 'gradient-brand text-white' : 'text-gray-500 hover:bg-gray-100'
                  }`}
                >
                  {tab}
                </button>
              ))}
            </div>
          </div>
          <div className="divide-y divide-gray-50">
            {salonLeads.map((item) => (
              <button
                key={item.id}
                type="button"
                onClick={() => {
                  setSelected(item.id)
                  setCommission(item.commission ?? 8)
                }}
                className={`w-full px-6 py-4 text-left transition hover:bg-purple-50/30 ${
                  selected === item.id ? 'bg-purple-50/50 border-l-4 border-purple-500' : ''
                }`}
              >
                <div className="flex items-start justify-between">
                  <div>
                    <p className="font-semibold text-gray-900">{item.businessName}</p>
                    <p className="text-sm text-gray-500">{item.ownerName} · {item.city}</p>
                    <p className="mt-1 text-xs text-gray-400">{item.plan} · {item.submittedAt}</p>
                  </div>
                  <StatusBadge status={item.status} dot />
                </div>
              </button>
            ))}
          </div>
        </Card>

        {lead && (
          <Card className="xl:col-span-3" title={`Review — ${lead.businessName}`}>
            <div className="grid grid-cols-1 gap-6 md:grid-cols-2">
              <div>
                <h4 className="mb-3 text-xs font-semibold uppercase tracking-wider text-gray-400">Business Details</h4>
                <dl className="space-y-2 text-sm">
                  <div className="flex justify-between"><dt className="text-gray-500">Owner</dt><dd className="font-medium">{lead.ownerName}</dd></div>
                  <div className="flex justify-between"><dt className="text-gray-500">Email</dt><dd className="font-medium">{lead.email}</dd></div>
                  <div className="flex justify-between"><dt className="text-gray-500">Phone</dt><dd className="font-medium">{lead.phone}</dd></div>
                  <div className="flex justify-between"><dt className="text-gray-500">Address</dt><dd className="font-medium text-right max-w-[200px]">{lead.address}</dd></div>
                </dl>
              </div>
              <div>
                <h4 className="mb-3 text-xs font-semibold uppercase tracking-wider text-gray-400">Subscription</h4>
                <dl className="space-y-2 text-sm">
                  <div className="flex justify-between"><dt className="text-gray-500">Plan</dt><dd className="font-medium">{lead.plan}</dd></div>
                  <div className="flex justify-between"><dt className="text-gray-500">Payment</dt><dd><StatusBadge status={lead.paymentStatus} dot /></dd></div>
                  <div className="flex justify-between"><dt className="text-gray-500">Lead ID</dt><dd className="font-mono text-xs">{lead.id}</dd></div>
                </dl>
              </div>
            </div>

            <div className="mt-8 rounded-xl border border-purple-100 bg-purple-50/30 p-5">
              <label htmlFor="commission" className="block text-sm font-semibold text-gray-900">
                Commission Percentage
              </label>
              <p className="mt-1 text-xs text-gray-500">GlowTap's share on each end-user payment to this salon (1%–25%)</p>
              <div className="mt-3 flex items-center gap-4">
                <input
                  id="commission"
                  type="range"
                  min={1}
                  max={25}
                  value={commission}
                  onChange={(e) => setCommission(Number(e.target.value))}
                  className="flex-1 accent-purple-600"
                />
                <span className="gradient-brand rounded-lg px-3 py-1 text-lg font-bold text-white">{commission}%</span>
              </div>
            </div>

            <div className="mt-8 flex flex-wrap gap-3">
              <GradientButton>
                <span className="flex items-center gap-2"><CheckCircle className="h-4 w-4" /> Approve & Onboard</span>
              </GradientButton>
              <GradientButton variant="outline">
                <span className="flex items-center gap-2"><MessageSquare className="h-4 w-4" /> Request More Info</span>
              </GradientButton>
              <GradientButton variant="danger">
                <span className="flex items-center gap-2"><XCircle className="h-4 w-4" /> Reject</span>
              </GradientButton>
            </div>
          </Card>
        )}
      </div>
    </div>
  )
}
