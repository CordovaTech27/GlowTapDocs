import { Plus, Edit } from 'lucide-react'
import { PageHeader } from '../components/PageHeader'
import { Card } from '../components/Card'
import { MetricCard } from '../components/MetricCard'
import { GradientButton } from '../components/GradientButton'
import { StatusBadge } from '../components/StatusBadge'
import { planDistribution } from '../data/mockData'
import { Receipt, HandCoins, Package, Calendar } from 'lucide-react'
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts'

const plans = [
  { name: 'Starter 1M', code: 'STARTER_1M', duration: '1 month', nrc: 999, rc: 999, maxBranches: 1, status: 'Active' },
  { name: 'Growth 6M', code: 'GROWTH_6M', duration: '6 months', nrc: 4999, rc: 833, maxBranches: 3, status: 'Active' },
  { name: 'Professional 12M', code: 'PRO_12M', duration: '12 months', nrc: 8999, rc: 750, maxBranches: 10, status: 'Active' },
  { name: 'Enterprise 24M', code: 'ENT_24M', duration: '24 months', nrc: 14999, rc: 625, maxBranches: 999, status: 'Active' },
]

export function SubscriptionPage() {
  return (
    <div>
      <PageHeader
        title="Subscription Management"
        description="Plans, discounts, salon billing, and commission configuration."
        actions={
          <GradientButton size="sm">
            <span className="flex items-center gap-2"><Plus className="h-4 w-4" /> Create Plan</span>
          </GradientButton>
        }
      />

      <div className="mb-8 grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <MetricCard label="Total MRR" value="₹18.5L" change="+8.4% this month" icon={Receipt} accent="purple" />
        <MetricCard label="Upcoming Renewals (30d)" value="34" change="7 at churn risk" icon={Calendar} accent="pink" />
        <MetricCard label="Active Subscriptions" value="248" icon={Package} accent="blue" />
        <MetricCard label="Commission Revenue" value="₹2.4L" change="This month" icon={HandCoins} accent="green" />
      </div>

      <div className="grid grid-cols-1 gap-6 xl:grid-cols-3">
        <Card title="Salons by Plan" className="xl:col-span-1">
          <div className="h-56">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={planDistribution} layout="vertical">
                <CartesianGrid strokeDasharray="3 3" horizontal={false} stroke="#f0f0f0" />
                <XAxis type="number" tick={{ fontSize: 11, fill: '#9ca3af' }} axisLine={false} tickLine={false} />
                <YAxis type="category" dataKey="plan" width={100} tick={{ fontSize: 11, fill: '#6b7280' }} axisLine={false} tickLine={false} />
                <Tooltip />
                <Bar dataKey="count" fill="#8b5cf6" radius={[0, 6, 6, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </Card>

        <Card title="Plan Configuration" className="xl:col-span-2" noPadding>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-gray-100 bg-gray-50/50">
                  {['Plan', 'Code', 'Duration', 'NRC', 'RC/mo', 'Max Branches', 'Status', ''].map((h) => (
                    <th key={h} className="px-4 py-3 text-left text-xs font-semibold uppercase text-gray-500">{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-50">
                {plans.map((p) => (
                  <tr key={p.code} className="hover:bg-purple-50/20">
                    <td className="px-4 py-3 font-semibold">{p.name}</td>
                    <td className="px-4 py-3 font-mono text-xs text-gray-500">{p.code}</td>
                    <td className="px-4 py-3">{p.duration}</td>
                    <td className="px-4 py-3">₹{p.nrc.toLocaleString()}</td>
                    <td className="px-4 py-3">₹{p.rc}</td>
                    <td className="px-4 py-3">{p.maxBranches === 999 ? 'Unlimited' : p.maxBranches}</td>
                    <td className="px-4 py-3"><StatusBadge status={p.status} dot /></td>
                    <td className="px-4 py-3">
                      <button type="button" className="text-purple-600 hover:text-purple-700"><Edit className="h-4 w-4" /></button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </Card>
      </div>

      <Card title="Revenue Model" className="mt-6">
        <div className="grid grid-cols-1 gap-6 md:grid-cols-2">
          <div className="rounded-xl border border-violet-100 bg-gradient-to-br from-violet-50 to-purple-50 p-6">
            <h4 className="font-semibold text-violet-900">Subscription Revenue</h4>
            <p className="mt-2 text-sm text-violet-700">Salon → GlowTap fixed/recurring fees from plan purchase, renewals, upgrades, and discounts (RC/NRC).</p>
          </div>
          <div className="rounded-xl border border-pink-100 bg-gradient-to-br from-pink-50 to-rose-50 p-6">
            <h4 className="font-semibold text-pink-900">Commission Revenue</h4>
            <p className="mt-2 text-sm text-pink-700">End User → Salon → GlowTap variable % per B2C transaction. Set at approval, editable per salon.</p>
          </div>
        </div>
      </Card>
    </div>
  )
}
