import waveBg from '../assets/wave-bg.webp'

export function LightGlowBackground() {
  return (
    <div className="pointer-events-none fixed inset-0 -z-10 overflow-hidden" aria-hidden>
      {/* Base */}
      <div className="absolute inset-0 bg-gradient-to-br from-[#fafbff] via-[#f8f9fc] to-[#fdf4ff]" />

      {/* Soft wave texture */}
      <img
        src={waveBg}
        alt=""
        className="absolute inset-0 h-full w-full object-cover opacity-[0.07] mix-blend-multiply"
      />

      {/* Glow orbs — login brand colors */}
      <div className="absolute -top-[20%] -right-[10%] h-[65%] w-[55%] rounded-full bg-[#7B00FF]/[0.10] blur-[90px]" />
      <div className="absolute top-[20%] -left-[8%] h-[45%] w-[40%] rounded-full bg-[#FF03C8]/[0.08] blur-[80px]" />
      <div className="absolute bottom-[5%] right-[20%] h-[40%] w-[45%] rounded-full bg-[#9B2FD9]/[0.07] blur-[70px]" />

      {/* Top wave accent */}
      <svg
        className="absolute -top-1 left-0 w-full opacity-[0.06]"
        viewBox="0 0 1440 120"
        preserveAspectRatio="none"
        fill="none"
      >
        <path
          d="M0,60 C240,100 480,20 720,60 C960,100 1200,30 1440,60 L1440,0 L0,0 Z"
          fill="url(#topWave)"
        />
        <defs>
          <linearGradient id="topWave" x1="0" y1="0" x2="1440" y2="0">
            <stop offset="0%" stopColor="#7B00FF" />
            <stop offset="50%" stopColor="#9B2FD9" />
            <stop offset="100%" stopColor="#FF03C8" />
          </linearGradient>
        </defs>
      </svg>

      {/* Bottom wave accent */}
      <svg
        className="absolute bottom-0 left-0 w-full opacity-[0.07]"
        viewBox="0 0 1440 200"
        preserveAspectRatio="none"
        fill="none"
      >
        <path
          d="M0,120 C360,200 720,40 1080,120 C1260,160 1380,140 1440,120 L1440,200 L0,200 Z"
          fill="url(#bottomWave)"
        />
        <defs>
          <linearGradient id="bottomWave" x1="0" y1="0" x2="1440" y2="0">
            <stop offset="0%" stopColor="#7B00FF" />
            <stop offset="50%" stopColor="#9B2FD9" />
            <stop offset="100%" stopColor="#FF03C8" />
          </linearGradient>
        </defs>
      </svg>

      {/* Subtle dot grid */}
      <div
        className="absolute inset-0 opacity-[0.35]"
        style={{
          backgroundImage: 'radial-gradient(circle, rgba(123,0,255,0.12) 1px, transparent 1px)',
          backgroundSize: '28px 28px',
        }}
      />
    </div>
  )
}
