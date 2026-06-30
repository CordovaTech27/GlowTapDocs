import type { LucideIcon } from 'lucide-react'
import clsx from 'clsx'

interface MetricCardProps {
  label: string
  value: string
  change?: string
  changeType?: 'up' | 'down' | 'neutral'
  icon: LucideIcon
  accent?: 'purple' | 'pink' | 'blue' | 'green'
}

const accentMap = {
  purple: 'border-violet-100 bg-gradient-to-br from-violet-50/80 to-white',
  pink: 'border-pink-100 bg-gradient-to-br from-pink-50/80 to-white',
  blue: 'border-blue-100 bg-gradient-to-br from-blue-50/80 to-white',
  green: 'border-emerald-100 bg-gradient-to-br from-emerald-50/80 to-white',
}

const iconMap = {
  purple: 'text-violet-600 bg-violet-100',
  pink: 'text-pink-600 bg-pink-100',
  blue: 'text-blue-600 bg-blue-100',
  green: 'text-emerald-600 bg-emerald-100',
}

export function MetricCard({ label, value, change, changeType = 'up', icon: Icon, accent = 'purple' }: MetricCardProps) {
  return (
    <div
      className={clsx(
        'rounded-2xl border p-5 shadow-[0_4px_20px_rgba(123,0,255,0.05)] transition-all hover:-translate-y-0.5 hover:shadow-[0_8px_32px_rgba(123,0,255,0.1)]',
        accentMap[accent],
      )}
    >
      <div className="flex items-start justify-between">
        <div>
          <p className="text-sm font-medium text-[#6B7A88]">{label}</p>
          <p className="mt-2 text-2xl font-bold tracking-tight text-[#1E2A32]">{value}</p>
          {change && (
            <p
              className={clsx('mt-1 text-xs font-medium', {
                'text-emerald-600': changeType === 'up',
                'text-red-500': changeType === 'down',
                'text-[#6B7A88]': changeType === 'neutral',
              })}
            >
              {change}
            </p>
          )}
        </div>
        <div className={clsx('rounded-xl p-2.5', iconMap[accent])}>
          <Icon className="h-5 w-5" />
        </div>
      </div>
    </div>
  )
}
