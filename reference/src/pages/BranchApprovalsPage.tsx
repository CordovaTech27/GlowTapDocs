import { CheckCircle, XCircle, AlertTriangle } from 'lucide-react'
import { PageHeader } from '../components/PageHeader'
import { Card } from '../components/Card'
import { GradientButton } from '../components/GradientButton'
import { StatusBadge } from '../components/StatusBadge'
import { branchRequests } from '../data/mockData'

export function BranchApprovalsPage() {
  return (
    <div>
      <PageHeader
        title="Branch Approvals"
        description="Review additional branch requests from onboarded salons."
      />

      <div className="space-y-4">
        {branchRequests.map((req) => (
          <Card key={req.id}>
            <div className="flex flex-col gap-6 lg:flex-row lg:items-start lg:justify-between">
              <div className="flex-1">
                <div className="flex items-center gap-3">
                  <h3 className="text-lg font-semibold text-gray-900">{req.branchName}</h3>
                  <StatusBadge status={req.status} dot />
                </div>
                <p className="mt-1 text-sm text-gray-500">{req.salonName} · {req.id}</p>

                <div className="mt-4 grid grid-cols-2 gap-4 text-sm md:grid-cols-4">
                  <div><p className="text-gray-400">Address</p><p className="font-medium">{req.address}</p></div>
                  <div><p className="text-gray-400">Contact</p><p className="font-medium">{req.contact}</p></div>
                  <div><p className="text-gray-400">Plan</p><p className="font-medium">{req.plan}</p></div>
                  <div><p className="text-gray-400">Branches</p><p className="font-medium">{req.currentBranches} / {req.branchLimit}</p></div>
                </div>

                {req.status === 'Upgrade Required' && (
                  <div className="mt-4 flex items-center gap-2 rounded-xl border border-amber-200 bg-amber-50 p-3 text-sm text-amber-800">
                    <AlertTriangle className="h-4 w-4 shrink-0" />
                    Branch limit reached. Approve with plan upgrade or reject with upgrade prompt.
                  </div>
                )}
              </div>

              <div className="flex gap-2">
                <GradientButton size="sm">
                  <span className="flex items-center gap-2"><CheckCircle className="h-4 w-4" /> Approve</span>
                </GradientButton>
                <GradientButton variant="danger" size="sm">
                  <span className="flex items-center gap-2"><XCircle className="h-4 w-4" /> Reject</span>
                </GradientButton>
              </div>
            </div>
          </Card>
        ))}
      </div>
    </div>
  )
}
