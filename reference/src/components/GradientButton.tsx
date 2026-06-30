import clsx from 'clsx'
import type { ReactNode } from 'react'

interface GradientButtonProps {
  children: ReactNode
  onClick?: () => void
  type?: 'button' | 'submit'
  variant?: 'primary' | 'outline' | 'ghost' | 'danger'
  size?: 'sm' | 'md' | 'lg'
  className?: string
  disabled?: boolean
}

export function GradientButton({
  children,
  onClick,
  type = 'button',
  variant = 'primary',
  size = 'md',
  className,
  disabled,
}: GradientButtonProps) {
  const sizeClasses = {
    sm: 'px-4 py-2 text-sm',
    md: 'px-6 py-3 text-sm',
    lg: 'px-8 py-3.5 text-base',
  }

  if (variant === 'primary') {
    return (
      <button
        type={type}
        onClick={onClick}
        disabled={disabled}
        className={clsx(
          'gradient-brand rounded-full font-semibold text-white transition-all hover:opacity-90 hover:scale-[1.02] active:scale-[0.98] glow-purple disabled:cursor-not-allowed disabled:opacity-50',
          sizeClasses[size],
          className,
        )}
      >
        {children}
      </button>
    )
  }

  const variants = {
    outline: 'border border-[#7B00FF]/25 text-[#7B00FF] hover:bg-violet-50 bg-white',
    ghost: 'text-[#7B00FF] hover:bg-violet-50',
    danger: 'border border-red-200 bg-red-50 text-red-600 hover:bg-red-100',
  }

  return (
    <button
      type={type}
      onClick={onClick}
      disabled={disabled}
      className={clsx(
        'rounded-full font-medium transition-all disabled:opacity-50',
        sizeClasses[size],
        variants[variant],
        className,
      )}
    >
      {children}
    </button>
  )
}
