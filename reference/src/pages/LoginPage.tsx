import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import salonBg from '../assets/salon-bg.png'
import tornWhite from '../assets/torn-white.png'
import tornShadow from '../assets/torn-edge.png'

export function LoginPage() {
  const navigate = useNavigate()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    navigate('/dashboard')
  }

  const paperMask = `
    linear-gradient(#fff 0 0),
    url(${tornWhite})
  `

  return (
    <div className="login-shell">
      <div className="login-frame">
        <div className="login-bg" style={{ backgroundImage: `url(${salonBg})` }} />

        {/* Soft white glow shadow behind paper (Figma rgba 255,255,255,0.24) */}
        <div
          className="login-paper-shadow-glow"
          style={{
            WebkitMaskImage: `url(${tornWhite})`,
            maskImage: `url(${tornWhite})`,
          }}
          aria-hidden
        />

        {/* Gray depth shadow (Group 10) */}
        <img src={tornShadow} alt="" className="login-paper-shadow" aria-hidden />

        {/* Single unified white paper — no seam */}
        <div
          className="login-paper-white"
          style={{
            WebkitMaskImage: paperMask,
            maskImage: paperMask,
          }}
          aria-hidden
        />

        {/* Sign-in content on top of paper */}
        <section className="login-signin">
          <div className="login-signin-inner">
            <h1 className="login-heading">Log in</h1>
            <p className="login-sub">Welcome back — sign in to manage your appointments.</p>

            <form onSubmit={handleSubmit}>
              <div className="login-field">
                <label htmlFor="email" className="login-label">
                  Login, email or phone number
                </label>
                <input
                  id="email"
                  type="text"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="you@example.com"
                  className="login-input"
                />
              </div>

              <div className="login-field">
                <label htmlFor="password" className="login-label">
                  Password
                </label>
                <input
                  id="password"
                  type="password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="Enter password"
                  className="login-input"
                />
              </div>

              <button type="submit" className="login-btn">
                Log in
              </button>
            </form>

            <div className="login-divider">
              <span className="login-divider-line" />
              <span className="login-divider-text">or log in with</span>
              <span className="login-divider-line" />
            </div>

            <div className="login-social-row">
              <button type="button" className="login-social-btn" aria-label="Log in with Google">
                <svg width="24" height="24" viewBox="0 0 24 24" aria-hidden>
                  <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" />
                  <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" />
                  <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" />
                  <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" />
                </svg>
              </button>
              <button type="button" className="login-social-btn" aria-label="Log in with Microsoft">
                <svg width="24" height="24" viewBox="0 0 24 24" aria-hidden>
                  <path fill="#F25022" d="M1 1h10v10H1z" />
                  <path fill="#00A4EF" d="M13 1h10v10H13z" />
                  <path fill="#7FBA00" d="M1 13h10v10H1z" />
                  <path fill="#FFB900" d="M13 13h10v10H13z" />
                </svg>
              </button>
            </div>

            <button type="button" className="login-forgot">
              Forgot login or password?
            </button>
          </div>
        </section>

        {/* Right-side promo — card + tags stacked with gap */}
        <div className="login-right-content">
          <div className="login-info-card">
            <p className="login-info-title">Your unisex salon, one tap away.</p>
            <p className="login-info-body">
              Book haircuts, colour, grooming and chair time — pick a stylist, choose your slot, and walk in glowing.
            </p>
            <ul className="login-info-list">
              <li>Live chair availability</li>
              <li>Stylist profiles &amp; reviews</li>
              <li>Instant booking confirmation</li>
            </ul>
          </div>

          <div className="login-tags">
            <span className="login-tag">Hair Styling</span>
            <span className="login-tag">Color &amp; Care</span>
            <span className="login-tag">Grooming</span>
          </div>
        </div>
      </div>
    </div>
  )
}
