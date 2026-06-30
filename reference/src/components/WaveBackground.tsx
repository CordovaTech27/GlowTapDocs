import waveBg from '../assets/wave-bg.webp'

export function WaveBackground() {
  return (
    <div className="pointer-events-none fixed inset-0 -z-10 overflow-hidden" aria-hidden>
      <div className="absolute inset-0 bg-[#0f0a18]" />
      <img
        src={waveBg}
        alt=""
        className="absolute inset-0 h-full w-full object-cover opacity-[0.18] mix-blend-screen"
      />
      <div className="absolute -top-[20%] -right-[10%] h-[70%] w-[70%] rounded-full bg-[#7B00FF]/12 blur-[100px]" />
      <div className="absolute -bottom-[15%] -left-[10%] h-[55%] w-[55%] rounded-full bg-[#FF03C8]/10 blur-[90px]" />
      <div className="absolute top-[30%] left-[40%] h-[40%] w-[40%] rounded-full bg-[#9B2FD9]/8 blur-[80px]" />
      <svg
        className="absolute bottom-0 left-0 w-full opacity-[0.07]"
        viewBox="0 0 1440 320"
        preserveAspectRatio="none"
        fill="none"
      >
        <path
          d="M0,192L48,197.3C96,203,192,213,288,229.3C384,245,480,267,576,250.7C672,235,768,181,864,181.3C960,181,1056,235,1152,234.7C1248,235,1344,181,1392,154.7L1440,128L1440,320L1392,320C1344,320,1248,320,1152,320C1056,320,960,320,864,320C768,320,672,320,576,320C480,320,384,320,288,320C192,320,96,320,48,320L0,320Z"
          fill="url(#waveGrad)"
        />
        <defs>
          <linearGradient id="waveGrad" x1="0" y1="0" x2="1440" y2="0">
            <stop offset="0%" stopColor="#7B00FF" />
            <stop offset="50%" stopColor="#9B2FD9" />
            <stop offset="100%" stopColor="#FF03C8" />
          </linearGradient>
        </defs>
      </svg>
    </div>
  )
}
