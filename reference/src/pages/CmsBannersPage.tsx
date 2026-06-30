import { useState } from 'react'
import { Plus, Globe, Smartphone } from 'lucide-react'
import { PageHeader } from '../components/PageHeader'
import { Card } from '../components/Card'
import { GradientButton } from '../components/GradientButton'
import { StatusBadge } from '../components/StatusBadge'

const cmsPages = [
  { title: 'About Us', slug: '/about', status: 'Published', updated: '2026-06-01' },
  { title: 'Pricing', slug: '/pricing', status: 'Published', updated: '2026-06-10' },
  { title: 'Features', slug: '/features', status: 'Published', updated: '2026-05-28' },
  { title: 'FAQ', slug: '/faq', status: 'Draft', updated: '2026-06-15' },
  { title: 'Terms of Service', slug: '/terms', status: 'Published', updated: '2026-01-15' },
]

const banners = [
  { title: 'Upgrade to 12M — Save 20%', audience: 'Plan = 1M, tenure > 3 months', priority: 1, status: 'Active', dates: 'Jun 1 – Aug 31' },
  { title: 'Renew 12M — Get 1 Month Free', audience: 'Plan = 12M, expiry within 30 days', priority: 2, status: 'Active', dates: 'Jun 1 – Jul 31' },
  { title: 'Add More Locations', audience: 'Branch count = plan max', priority: 3, status: 'Scheduled', dates: 'Jul 1 – Sep 30' },
]

export function CmsBannersPage() {
  const [tab, setTab] = useState<'cms' | 'banners'>('cms')

  return (
    <div>
      <PageHeader
        title="CMS & Banner Management"
        description="Website content and in-app promotional banners for salon admins."
        actions={
          <GradientButton size="sm">
            <span className="flex items-center gap-2"><Plus className="h-4 w-4" /> {tab === 'cms' ? 'New Page' : 'New Banner'}</span>
          </GradientButton>
        }
      />

      <div className="mb-6 flex gap-2">
        <button
          type="button"
          onClick={() => setTab('cms')}
          className={`flex items-center gap-2 rounded-full px-5 py-2 text-sm font-medium transition ${
            tab === 'cms' ? 'gradient-brand text-white' : 'bg-white border border-gray-200 text-gray-600'
          }`}
        >
          <Globe className="h-4 w-4" /> Website CMS
        </button>
        <button
          type="button"
          onClick={() => setTab('banners')}
          className={`flex items-center gap-2 rounded-full px-5 py-2 text-sm font-medium transition ${
            tab === 'banners' ? 'gradient-brand text-white' : 'bg-white border border-gray-200 text-gray-600'
          }`}
        >
          <Smartphone className="h-4 w-4" /> In-App Banners
        </button>
      </div>

      {tab === 'cms' ? (
        <Card noPadding>
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-gray-100 bg-gray-50/50">
                {['Page', 'Slug', 'Status', 'Last Updated', 'Actions'].map((h) => (
                  <th key={h} className="px-6 py-3 text-left text-xs font-semibold uppercase text-gray-500">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50">
              {cmsPages.map((p) => (
                <tr key={p.slug} className="hover:bg-purple-50/20">
                  <td className="px-6 py-4 font-semibold">{p.title}</td>
                  <td className="px-6 py-4 font-mono text-xs text-gray-500">{p.slug}</td>
                  <td className="px-6 py-4"><StatusBadge status={p.status === 'Published' ? 'Active' : 'Pending'} dot /></td>
                  <td className="px-6 py-4 text-gray-500">{p.updated}</td>
                  <td className="px-6 py-4"><GradientButton variant="outline" size="sm">Edit</GradientButton></td>
                </tr>
              ))}
            </tbody>
          </table>
        </Card>
      ) : (
        <div className="space-y-4">
          {banners.map((b) => (
            <Card key={b.title}>
              <div className="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
                <div>
                  <div className="flex items-center gap-3">
                    <h3 className="font-semibold text-gray-900">{b.title}</h3>
                    <StatusBadge status={b.status === 'Active' ? 'Active' : 'Pending'} dot />
                  </div>
                  <p className="mt-1 text-sm text-gray-500">Target: {b.audience}</p>
                  <p className="text-xs text-gray-400">Priority {b.priority} · {b.dates}</p>
                </div>
                <GradientButton variant="outline" size="sm">Configure</GradientButton>
              </div>
            </Card>
          ))}
        </div>
      )}
    </div>
  )
}
