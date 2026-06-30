import { PageHeader } from '../components/PageHeader'
import { Card } from '../components/Card'
import { MetricCard } from '../components/MetricCard'
import { Building2, IndianRupee, Calendar, CreditCard, MapPin } from 'lucide-react'
import { revenueChart, planDistribution } from '../data/mockData'
import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart, Pie, Cell } from 'recharts'

const usageData = [
  { month: 'Jan', appointments: 12400, gmv: 8200000 },
  { month: 'Feb', appointments: 13800, gmv: 9100000 },
  { month: 'Mar', appointments: 15200, gmv: 9800000 },
  { month: 'Apr', appointments: 16100, gmv: 10500000 },
  { month: 'May', appointments: 17800, gmv: 11800000 },
  { month: 'Jun', appointments: 19200, gmv: 12800000 },
]

const geoData = [
  { city: 'Mumbai', salons: 68, revenue: 4200000 },
  { city: 'Bangalore', salons: 54, revenue: 3800000 },
  { city: 'Delhi', salons: 42, revenue: 2900000 },
  { city: 'Hyderabad', salons: 35, revenue: 2100000 },
  { city: 'Chennai', salons: 28, revenue: 1800000 },
]

export function AnalyticsPage() {
  return (
    <div>
      <PageHeader
        title="Platform Analytics"
        description="Strategic KPIs, trends, and usage insights."
      />

      <div className="mb-8 grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <MetricCard label="Active Salons" value="248" change="Churn rate: 2.1%" icon={Building2} accent="purple" changeType="neutral" />
        <MetricCard label="MRR / ARR" value="₹18.5L / ₹2.2Cr" change="+8.4% MRR growth" icon={IndianRupee} accent="green" />
        <MetricCard label="Appointments (MTD)" value="19,200" change="+7.8% vs last month" icon={Calendar} accent="pink" />
        <MetricCard label="Transaction GMV" value="₹1.28Cr" change="ARPU: ₹334" icon={CreditCard} accent="blue" />
      </div>

      <div className="grid grid-cols-1 gap-6 xl:grid-cols-2">
        <Card title="Combined Revenue Trend">
          <div className="h-64">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={revenueChart}>
                <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                <XAxis dataKey="month" tick={{ fontSize: 12, fill: '#9ca3af' }} />
                <YAxis tick={{ fontSize: 12, fill: '#9ca3af' }} tickFormatter={(v) => `₹${v / 1000}K`} />
                <Tooltip formatter={(v) => `₹${Number(v).toLocaleString()}`} />
                <Area type="monotone" dataKey="subscription" stackId="1" stroke="#7c3aed" fill="#7c3aed" fillOpacity={0.6} />
                <Area type="monotone" dataKey="commission" stackId="1" stroke="#ec4899" fill="#ec4899" fillOpacity={0.6} />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </Card>

        <Card title="Plan Distribution">
          <div className="flex items-center gap-8">
            <div className="h-56 w-56">
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie data={planDistribution} dataKey="count" nameKey="plan" cx="50%" cy="50%" innerRadius={50} outerRadius={80} paddingAngle={3}>
                    {planDistribution.map((entry) => (
                      <Cell key={entry.plan} fill={entry.color} />
                    ))}
                  </Pie>
                  <Tooltip />
                </PieChart>
              </ResponsiveContainer>
            </div>
            <div className="space-y-2">
              {planDistribution.map((p) => (
                <div key={p.plan} className="flex items-center gap-2 text-sm">
                  <span className="h-3 w-3 rounded-full" style={{ backgroundColor: p.color }} />
                  <span className="text-gray-600">{p.plan}</span>
                  <span className="font-semibold">{p.count}</span>
                </div>
              ))}
            </div>
          </div>
        </Card>

        <Card title="Usage — Appointments & GMV">
          <div className="h-64">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={usageData}>
                <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                <XAxis dataKey="month" tick={{ fontSize: 12, fill: '#9ca3af' }} />
                <YAxis yAxisId="left" tick={{ fontSize: 12, fill: '#9ca3af' }} />
                <YAxis yAxisId="right" orientation="right" tick={{ fontSize: 12, fill: '#9ca3af' }} tickFormatter={(v) => `₹${v / 100000}L`} />
                <Tooltip />
                <Area yAxisId="left" type="monotone" dataKey="appointments" stroke="#8b5cf6" fill="#8b5cf6" fillOpacity={0.2} name="Appointments" />
                <Area yAxisId="right" type="monotone" dataKey="gmv" stroke="#ec4899" fill="#ec4899" fillOpacity={0.2} name="GMV" />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </Card>

        <Card title="Geographic Performance">
          <div className="space-y-3">
            {geoData.map((g) => (
              <div key={g.city} className="flex items-center gap-4">
                <MapPin className="h-4 w-4 shrink-0 text-purple-500" />
                <div className="flex-1">
                  <div className="flex justify-between text-sm">
                    <span className="font-medium">{g.city}</span>
                    <span className="text-gray-500">{g.salons} salons · ₹{(g.revenue / 100000).toFixed(1)}L</span>
                  </div>
                  <div className="mt-1 h-2 overflow-hidden rounded-full bg-gray-100">
                    <div
                      className="h-full rounded-full gradient-brand"
                      style={{ width: `${(g.revenue / geoData[0].revenue) * 100}%` }}
                    />
                  </div>
                </div>
              </div>
            ))}
          </div>
        </Card>
      </div>
    </div>
  )
}
