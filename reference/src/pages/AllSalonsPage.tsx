import { useState } from 'react'
import { Eye, Pause, Play, XOctagon, Download } from 'lucide-react'
import { PageHeader } from '../components/PageHeader'
import { Card } from '../components/Card'
import { GradientButton } from '../components/GradientButton'
import { StatusBadge } from '../components/StatusBadge'
import { salons } from '../data/mockData'

function formatCurrency(n: number) {
  return `₹${n.toLocaleString('en-IN')}`
}

export function AllSalonsPage() {
  const [selected, setSelected] = useState<string | null>(null)
  const salon = salons.find((s) => s.id === selected)

  return (
    <div>
      <PageHeader
        title="All Salons"
        description="Central registry of all onboarded salon organizations."
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
                {['Salon', 'City', 'Status', 'Plan', 'Branches', 'Commission', 'Total Earnings', 'Actions'].map((h) => (
                  <th key={h} className="px-6 py-3 text-left text-xs font-semibold uppercase tracking-wider text-gray-500">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50">
              {salons.map((s) => (
                <tr key={s.id} className="transition hover:bg-purple-50/20">
                  <td className="px-6 py-4">
                    <p className="font-semibold text-gray-900">{s.name}</p>
                    <p className="text-xs text-gray-400">{s.owner}</p>
                  </td>
                  <td className="px-6 py-4 text-gray-600">{s.city}</td>
                  <td className="px-6 py-4"><StatusBadge status={s.status} dot /></td>
                  <td className="px-6 py-4 text-gray-600">{s.plan}</td>
                  <td className="px-6 py-4 text-gray-600">{s.branchCount}</td>
                  <td className="px-6 py-4"><span className="font-semibold text-purple-600">{s.commission}%</span></td>
                  <td className="px-6 py-4 font-medium">{formatCurrency(s.subscriptionRevenue + s.commissionRevenue)}</td>
                  <td className="px-6 py-4">
                    <button
                      type="button"
                      onClick={() => setSelected(s.id)}
                      className="rounded-lg p-2 text-purple-600 transition hover:bg-purple-50"
                    >
                      <Eye className="h-4 w-4" />
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </Card>

      {salon && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4 backdrop-blur-sm" onClick={() => setSelected(null)}>
          <div className="max-h-[90vh] w-full max-w-2xl overflow-y-auto rounded-2xl bg-white p-8 shadow-2xl" onClick={(e) => e.stopPropagation()}>
            <div className="flex items-start justify-between">
              <div>
                <h2 className="text-xl font-bold text-gray-900">{salon.name}</h2>
                <p className="text-sm text-gray-500">{salon.id} · {salon.city}</p>
              </div>
              <StatusBadge status={salon.status} dot />
            </div>

            <div className="mt-6 grid grid-cols-2 gap-4">
              <div className="rounded-xl border border-violet-100 bg-violet-50/50 p-4">
                <p className="text-xs font-semibold uppercase text-violet-600">Subscription Revenue</p>
                <p className="mt-1 text-2xl font-bold text-gray-900">{formatCurrency(salon.subscriptionRevenue)}</p>
              </div>
              <div className="rounded-xl border border-pink-100 bg-pink-50/50 p-4">
                <p className="text-xs font-semibold uppercase text-pink-600">Commission Revenue</p>
                <p className="mt-1 text-2xl font-bold text-gray-900">{formatCurrency(salon.commissionRevenue)}</p>
              </div>
            </div>

            <dl className="mt-6 grid grid-cols-2 gap-4 text-sm">
              <div><dt className="text-gray-400">Owner</dt><dd className="font-medium">{salon.owner}</dd></div>
              <div><dt className="text-gray-400">Email</dt><dd className="font-medium">{salon.email}</dd></div>
              <div><dt className="text-gray-400">Plan</dt><dd className="font-medium">{salon.plan}</dd></div>
              <div><dt className="text-gray-400">Renewal</dt><dd className="font-medium">{salon.renewalDate}</dd></div>
              <div><dt className="text-gray-400">Commission</dt><dd className="font-semibold text-purple-600">{salon.commission}%</dd></div>
              <div><dt className="text-gray-400">Branches</dt><dd className="font-medium">{salon.branchCount}</dd></div>
            </dl>

            <div className="mt-8 flex flex-wrap gap-3">
              {salon.status === 'Active' ? (
                <GradientButton variant="outline" size="sm"><span className="flex items-center gap-2"><Pause className="h-4 w-4" /> Suspend</span></GradientButton>
              ) : (
                <GradientButton size="sm"><span className="flex items-center gap-2"><Play className="h-4 w-4" /> Resume</span></GradientButton>
              )}
              <GradientButton variant="danger" size="sm"><span className="flex items-center gap-2"><XOctagon className="h-4 w-4" /> Terminate</span></GradientButton>
              <GradientButton variant="outline" size="sm" onClick={() => setSelected(null)}>Close</GradientButton>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
