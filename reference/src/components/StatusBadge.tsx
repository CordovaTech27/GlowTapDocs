import clsx from 'clsx'

const statusStyles: Record<string, string> = {
  Active: 'bg-emerald-50 text-emerald-700 border-emerald-200',
  Approved: 'bg-emerald-50 text-emerald-700 border-emerald-200',
  Success: 'bg-emerald-50 text-emerald-700 border-emerald-200',
  Suspended: 'bg-amber-50 text-amber-700 border-amber-200',
  Pending: 'bg-amber-50 text-amber-700 border-amber-200',
  'Pending Review': 'bg-amber-50 text-amber-700 border-amber-200',
  Failed: 'bg-red-50 text-red-700 border-red-200',
  Rejected: 'bg-red-50 text-red-700 border-red-200',
  Terminated: 'bg-red-50 text-red-700 border-red-200',
  Disputed: 'bg-orange-50 text-orange-700 border-orange-200',
  Refunded: 'bg-slate-50 text-slate-600 border-slate-200',
  'Awaiting Info': 'bg-blue-50 text-blue-700 border-blue-200',
  'Upgrade Required': 'bg-purple-50 text-purple-700 border-purple-200',
  Created: 'bg-slate-50 text-slate-600 border-slate-200',
  'In Progress': 'bg-blue-50 text-blue-700 border-blue-200',
  Resolved: 'bg-emerald-50 text-emerald-700 border-emerald-200',
  Critical: 'bg-red-50 text-red-700 border-red-200 ring-1 ring-red-300',
  High: 'bg-orange-50 text-orange-700 border-orange-200',
  Medium: 'bg-amber-50 text-amber-700 border-amber-200',
  Low: 'bg-slate-50 text-slate-600 border-slate-200',
  Paid: 'bg-emerald-50 text-emerald-700 border-emerald-200',
}

interface StatusBadgeProps {
  status: string
  dot?: boolean
}

export function StatusBadge({ status, dot }: StatusBadgeProps) {
  return (
    <span
      className={clsx(
        'inline-flex items-center gap-1.5 rounded-full border px-2.5 py-0.5 text-xs font-medium',
        statusStyles[status] ?? 'bg-gray-50 text-gray-600 border-gray-200',
      )}
    >
      {dot && (
        <span
          className={clsx('h-1.5 w-1.5 rounded-full', {
            'bg-emerald-500 shadow-[0_0_6px_rgba(16,185,129,0.8)]': ['Active', 'Approved', 'Success', 'Paid', 'Resolved'].includes(status),
            'bg-amber-500 shadow-[0_0_6px_rgba(245,158,11,0.8)]': ['Pending', 'Pending Review', 'Suspended', 'Medium'].includes(status),
            'bg-red-500 shadow-[0_0_6px_rgba(239,68,68,0.8)]': ['Failed', 'Rejected', 'Terminated', 'Critical', 'High'].includes(status),
            'bg-purple-500 shadow-[0_0_6px_rgba(168,85,247,0.8)]': status === 'Upgrade Required',
            'bg-blue-500 shadow-[0_0_6px_rgba(59,130,246,0.8)]': ['Awaiting Info', 'In Progress'].includes(status),
            'bg-gray-400': !statusStyles[status],
          })}
        />
      )}
      {status}
    </span>
  )
}
