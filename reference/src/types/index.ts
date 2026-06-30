export type SalonStatus = 'Active' | 'Suspended' | 'Terminated' | 'Pending Review' | 'Approved' | 'Rejected' | 'Awaiting Info'
export type PlanTier = 'Starter 1M' | 'Growth 6M' | 'Professional 12M' | 'Enterprise 24M'
export type TicketPriority = 'Low' | 'Medium' | 'High' | 'Critical'
export type TransactionStatus = 'Success' | 'Failed' | 'Refunded' | 'Disputed'

export interface SalonLead {
  id: string
  businessName: string
  ownerName: string
  email: string
  phone: string
  city: string
  address: string
  plan: PlanTier
  paymentStatus: 'Paid' | 'Pending' | 'Failed'
  status: SalonStatus
  submittedAt: string
  commission?: number
}

export interface Salon {
  id: string
  name: string
  city: string
  status: 'Active' | 'Suspended' | 'Terminated'
  plan: PlanTier
  branchCount: number
  commission: number
  subscriptionRevenue: number
  commissionRevenue: number
  owner: string
  email: string
  renewalDate: string
}

export interface BranchRequest {
  id: string
  salonName: string
  branchName: string
  address: string
  contact: string
  plan: PlanTier
  branchLimit: number
  currentBranches: number
  status: 'Pending' | 'Upgrade Required' | 'Approved' | 'Rejected'
  submittedAt: string
}

export interface Transaction {
  id: string
  date: string
  endUser: string
  salon: string
  branch: string
  description: string
  grossAmount: number
  commissionPct: number
  commissionAmount: number
  netToSalon: number
  paymentMethod: string
  status: TransactionStatus
}

export interface Ticket {
  id: string
  subject: string
  salon?: string
  priority: TicketPriority
  status: 'Created' | 'In Progress' | 'On Hold' | 'Awaiting User Confirmation' | 'Resolved'
  assignee?: string
  createdAt: string
  slaHours: number
}

export interface NavItem {
  label: string
  path: string
  icon: string
  badge?: number
}
