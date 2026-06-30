import { PageHeader } from '../components/PageHeader'
import { Card } from '../components/Card'
import { GradientButton } from '../components/GradientButton'
import { Settings, Bell, Receipt, Shield, CreditCard, Percent } from 'lucide-react'

const sections = [
  {
    icon: Shield,
    title: 'Reason Codes',
    desc: 'Suspend, terminate, reject, and ticket reason codes with sub-reasons',
    items: ['Non-payment suspension', 'Policy violation', 'Incomplete KYC', 'Payment gateway error'],
  },
  {
    icon: Receipt,
    title: 'Pricing Rules',
    desc: 'Reason code → fee/penalty mapping for early termination and disputes',
    items: ['Early termination fee: ₹2,000', 'Forfeiture of discount on breach', 'Grace period: 7 days'],
  },
  {
    icon: Bell,
    title: 'Notification Templates',
    desc: 'Email/SMS templates for onboarding, renewal, suspension, and more',
    items: ['Welcome email with credentials', 'Renewal reminder (30/15/7 days)', 'Suspension notice', 'Approval rejection'],
  },
  {
    icon: Percent,
    title: 'Tax / GST Settings',
    desc: 'Regional tax rates and invoice configuration',
    items: ['GST: 18% (default)', 'IGST for inter-state', 'Tax-inclusive pricing: Yes'],
  },
  {
    icon: Settings,
    title: 'Feature Entitlements',
    desc: 'Plan → feature matrix for appointments, manpower, services, analytics',
    items: ['Starter: Basic appointments', 'Growth: + Manpower module', 'Pro: + Advanced analytics'],
  },
  {
    icon: CreditCard,
    title: 'Payment Gateway',
    desc: 'Active gateways, retry rules, and commission defaults',
    items: ['Default commission: 8%', 'Min/Max: 1% – 25%', 'Razorpay + Stripe active', 'Retry: 3 attempts over 72h'],
  },
]

export function MasterConfigPage() {
  return (
    <div>
      <PageHeader
        title="Master Configuration"
        description="Centralized platform settings managed by Super Admin."
      />

      <div className="grid grid-cols-1 gap-6 md:grid-cols-2 xl:grid-cols-3">
        {sections.map(({ icon: Icon, title, desc, items }) => (
          <Card key={title}>
            <div className="flex items-start gap-4">
              <div className="rounded-xl bg-purple-50 p-3">
                <Icon className="h-5 w-5 text-purple-600" />
              </div>
              <div className="flex-1">
                <h3 className="font-semibold text-gray-900">{title}</h3>
                <p className="mt-1 text-sm text-gray-500">{desc}</p>
                <ul className="mt-4 space-y-1.5">
                  {items.map((item) => (
                    <li key={item} className="flex items-center gap-2 text-sm text-gray-600">
                      <span className="h-1.5 w-1.5 rounded-full bg-purple-400" />
                      {item}
                    </li>
                  ))}
                </ul>
                <GradientButton variant="outline" size="sm" className="mt-4">Configure</GradientButton>
              </div>
            </div>
          </Card>
        ))}
      </div>
    </div>
  )
}
