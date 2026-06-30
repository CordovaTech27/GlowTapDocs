import type { ReactNode } from 'react'
import clsx from 'clsx'

interface CardProps {
  children: ReactNode
  className?: string
  title?: string
  action?: ReactNode
  noPadding?: boolean
}

export function Card({ children, className, title, action, noPadding }: CardProps) {
  return (
    <div
      className={clsx(
        'rounded-2xl border border-[#E2E8F0] bg-white shadow-[0_4px_24px_rgba(123,0,255,0.04)]',
        className,
      )}
    >
      {(title || action) && (
        <div className="flex items-center justify-between border-b border-gray-100 px-6 py-4">
          {title && <h3 className="font-semibold text-[#1E2A32]">{title}</h3>}
          {action}
        </div>
      )}
      <div className={noPadding ? undefined : 'p-6'}>{children}</div>
    </div>
  )
}
