import { useState } from 'react'
import { PageHeader } from '../components/PageHeader'
import { Card } from '../components/Card'
import { StatusBadge } from '../components/StatusBadge'
import { GradientButton } from '../components/GradientButton'
import { Download } from 'lucide-react'

const tabs = ['Salon Admins', 'Sub Admins', 'End Users'] as const

const users = {
  'Salon Admins': [
    { name: 'Anita Desai', email: 'anita@serenityspa.in', salon: 'Serenity Spa & Salon', lastLogin: '2026-06-20', status: 'Active' },
    { name: 'Kavitha Reddy', email: 'kavitha@blushbeauty.in', salon: 'Blush Beauty Lounge', lastLogin: '2026-06-19', status: 'Active' },
    { name: 'Vikram Iyer', email: 'vikram@classiccuts.in', salon: 'Classic Cuts', lastLogin: '2026-06-15', status: 'Active' },
  ],
  'Sub Admins': [
    { name: 'Ravi Kumar', email: 'ravi@serenityspa.in', salon: 'Serenity Spa — Bandra', lastLogin: '2026-06-18', status: 'Active' },
    { name: 'Priya N', email: 'priya@blushbeauty.in', salon: 'Blush — Koramangala', lastLogin: '2026-06-17', status: 'Active' },
  ],
  'End Users': [
    { name: 'Riya P.', email: 'r***a@email.com', salon: '—', lastLogin: '2026-06-20', status: 'Active' },
    { name: 'Arun K.', email: 'a***n@email.com', salon: '—', lastLogin: '2026-06-19', status: 'Active' },
    { name: 'Spam Account', email: 'spam@test.com', salon: '—', lastLogin: '2026-06-10', status: 'Suspended' },
  ],
}

export function UserAccessPage() {
  const [activeTab, setActiveTab] = useState<(typeof tabs)[number]>('Salon Admins')
  const list = users[activeTab]

  return (
    <div>
      <PageHeader
        title="User Access Control"
        description="View and manage Salon Admins, Sub Admins, and End Users."
        actions={
          <GradientButton variant="outline" size="sm">
            <span className="flex items-center gap-2"><Download className="h-4 w-4" /> Export</span>
          </GradientButton>
        }
      />

      <div className="mb-6 flex gap-2">
        {tabs.map((tab) => (
          <button
            key={tab}
            type="button"
            onClick={() => setActiveTab(tab)}
            className={`rounded-full px-5 py-2 text-sm font-medium transition ${
              activeTab === tab ? 'gradient-brand text-white glow-purple' : 'bg-white text-gray-600 border border-gray-200 hover:border-purple-200'
            }`}
          >
            {tab}
          </button>
        ))}
      </div>

      <Card noPadding>
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-gray-100 bg-gray-50/50">
                {['Name', 'Email', activeTab === 'End Users' ? 'Linked Salon' : 'Organization / Branch', 'Last Login', 'Status', 'Actions'].map((h) => (
                  <th key={h} className="px-6 py-3 text-left text-xs font-semibold uppercase text-gray-500">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50">
              {list.map((u) => (
                <tr key={u.email} className="hover:bg-purple-50/20">
                  <td className="px-6 py-4 font-semibold">{u.name}</td>
                  <td className="px-6 py-4 text-gray-600">{u.email}</td>
                  <td className="px-6 py-4 text-gray-600">{u.salon}</td>
                  <td className="px-6 py-4 text-gray-500">{u.lastLogin}</td>
                  <td className="px-6 py-4"><StatusBadge status={u.status} dot /></td>
                  <td className="px-6 py-4">
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
