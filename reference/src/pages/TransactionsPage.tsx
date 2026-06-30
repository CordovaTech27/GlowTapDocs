import { Download, Flag } from 'lucide-react'
import { PageHeader } from '../components/PageHeader'
import { Card } from '../components/Card'
import { GradientButton } from '../components/GradientButton'
import { StatusBadge } from '../components/StatusBadge'
import { transactions } from '../data/mockData'

function formatCurrency(n: number) {
  return `₹${n.toLocaleString('en-IN')}`
}

export function TransactionsPage() {
  return (
    <div>
      <PageHeader
        title="Transactions"
        description="End-user payments to salons — B2C transaction history."
        actions={
          <GradientButton variant="outline" size="sm">
            <span className="flex items-center gap-2"><Download className="h-4 w-4" /> Export CSV</span>
          </GradientButton>
        }
      />

      <Card noPadding>
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-gray-100 bg-gray-50/50">
                {['Transaction ID', 'Date', 'End User', 'Salon / Branch', 'Description', 'Gross', 'Commission', 'Net to Salon', 'Method', 'Status', ''].map((h) => (
                  <th key={h} className="whitespace-nowrap px-4 py-3 text-left text-xs font-semibold uppercase tracking-wider text-gray-500">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50">
              {transactions.map((tx) => (
                <tr key={tx.id} className="transition hover:bg-purple-50/20">
                  <td className="whitespace-nowrap px-4 py-3 font-mono text-xs text-purple-600">{tx.id}</td>
                  <td className="whitespace-nowrap px-4 py-3 text-gray-600">{tx.date}</td>
                  <td className="px-4 py-3">{tx.endUser}</td>
                  <td className="px-4 py-3">
                    <p className="font-medium">{tx.salon}</p>
                    <p className="text-xs text-gray-400">{tx.branch}</p>
                  </td>
                  <td className="px-4 py-3 text-gray-600">{tx.description}</td>
                  <td className="px-4 py-3 font-medium">{formatCurrency(tx.grossAmount)}</td>
                  <td className="px-4 py-3">
                    <span className="text-purple-600">{tx.commissionPct}%</span>
                    <span className="text-gray-400"> · </span>
                    {formatCurrency(tx.commissionAmount)}
                  </td>
                  <td className="px-4 py-3 font-medium text-emerald-600">{formatCurrency(tx.netToSalon)}</td>
                  <td className="px-4 py-3 text-gray-500">{tx.paymentMethod}</td>
                  <td className="px-4 py-3"><StatusBadge status={tx.status} dot /></td>
                  <td className="px-4 py-3">
                    <button type="button" className="rounded-lg p-1.5 text-gray-400 transition hover:bg-gray-100 hover:text-purple-600" title="Flag dispute">
                      <Flag className="h-4 w-4" />
                    </button>
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
