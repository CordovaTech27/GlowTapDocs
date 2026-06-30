import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { LoginPage } from './pages/LoginPage'
import { DashboardLayout } from './layouts/DashboardLayout'
import { DashboardPage } from './pages/DashboardPage'
import { SalonApprovalsPage } from './pages/SalonApprovalsPage'
import { BranchApprovalsPage } from './pages/BranchApprovalsPage'
import { AllSalonsPage } from './pages/AllSalonsPage'
import { TransactionsPage } from './pages/TransactionsPage'
import { SubscriptionPage } from './pages/SubscriptionPage'
import { ReportsPage } from './pages/ReportsPage'
import { UserAccessPage } from './pages/UserAccessPage'
import { CmsBannersPage } from './pages/CmsBannersPage'
import { AnalyticsPage } from './pages/AnalyticsPage'
import { SupportPage } from './pages/SupportPage'
import { MasterConfigPage } from './pages/MasterConfigPage'
import { AuditLogPage } from './pages/AuditLogPage'

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<LoginPage />} />
        <Route path="/dashboard" element={<DashboardLayout />}>
          <Route index element={<DashboardPage />} />
          <Route path="salon-approvals" element={<SalonApprovalsPage />} />
          <Route path="branch-approvals" element={<BranchApprovalsPage />} />
          <Route path="salons" element={<AllSalonsPage />} />
          <Route path="transactions" element={<TransactionsPage />} />
          <Route path="subscriptions" element={<SubscriptionPage />} />
          <Route path="reports" element={<ReportsPage />} />
          <Route path="users" element={<UserAccessPage />} />
          <Route path="cms" element={<CmsBannersPage />} />
          <Route path="analytics" element={<AnalyticsPage />} />
          <Route path="support" element={<SupportPage />} />
          <Route path="config" element={<MasterConfigPage />} />
          <Route path="audit" element={<AuditLogPage />} />
        </Route>
        <Route path="*" element={<Navigate to="/login" replace />} />
      </Routes>
    </BrowserRouter>
  )
}
