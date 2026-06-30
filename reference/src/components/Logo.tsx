import clsx from 'clsx'

interface LogoProps {
  size?: 'sm' | 'md' | 'lg'
  className?: string
}

export function Logo({ size = 'md', className }: LogoProps) {
  const iconSize = { sm: 32, md: 38, lg: 48 }[size]

  return (
    <div className={clsx('flex items-center gap-2.5', className)}>
      {/* GT monogram */}
      <svg
        width={iconSize}
        height={iconSize}
        viewBox="0 0 48 48"
        fill="none"
        aria-hidden
        className="shrink-0"
      >
        <defs>
          <linearGradient id="gtGrad" x1="4" y1="44" x2="44" y2="4">
            <stop offset="0%" stopColor="#7B00FF" />
            <stop offset="55%" stopColor="#9B2FD9" />
            <stop offset="100%" stopColor="#FF03C8" />
          </linearGradient>
        </defs>
        {/* G outer arc + T stem */}
        <path
          d="M28 8 C18 8 10 16 10 26 C10 36 18 42 26 42 C32 42 36 39 38 35"
          stroke="url(#gtGrad)"
          strokeWidth="5.5"
          strokeLinecap="round"
          fill="none"
        />
        <path
          d="M26 26 L26 14 M26 26 L38 26"
          stroke="url(#gtGrad)"
          strokeWidth="5.5"
          strokeLinecap="round"
          strokeLinejoin="round"
        />
        {/* Sparkle */}
        <path
          d="M36 10 L37.5 13.5 L41 15 L37.5 16.5 L36 20 L34.5 16.5 L31 15 L34.5 13.5 Z"
          fill="#FF03C8"
        />
      </svg>

      <div className="min-w-0">
        <div className="flex items-baseline leading-none">
          <span
            className={clsx('font-bold tracking-tight', {
              'text-lg': size === 'sm',
              'text-xl': size === 'md',
              'text-2xl': size === 'lg',
            })}
            style={{
              background: 'linear-gradient(135deg, #7B00FF 0%, #9B2FD9 60%)',
              WebkitBackgroundClip: 'text',
              WebkitTextFillColor: 'transparent',
              backgroundClip: 'text',
            }}
          >
            Glow
          </span>
          <span
            className={clsx('font-bold tracking-tight', {
              'text-lg': size === 'sm',
              'text-xl': size === 'md',
              'text-2xl': size === 'lg',
            })}
            style={{
              background: 'linear-gradient(135deg, #C026D3 0%, #FF03C8 100%)',
              WebkitBackgroundClip: 'text',
              WebkitTextFillColor: 'transparent',
              backgroundClip: 'text',
            }}
          >
            Tap
          </span>
        </div>
      </div>
    </div>
  )
}
