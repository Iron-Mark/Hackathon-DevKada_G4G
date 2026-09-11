// Kudlit — Login / splash screen

function LoginScreen({ onLogin }) {
  return (
    <div style={{
      flex: 1, display: 'flex', flexDirection: 'column',
      background: K.blue300, fontFamily: K.font,
      backgroundImage: `url('../../assets/bg.login.webp')`,
      backgroundSize: 'cover', backgroundPosition: 'center',
      position: 'relative',
    }}>
      <div style={{ position: 'absolute', inset: 0, background: 'linear-gradient(180deg, rgba(14,20,37,0.15) 0%, rgba(14,20,37,0.85) 100%)' }} />

      {/* Top logo + title */}
      <div style={{ position: 'relative', padding: '60px 24px 0', textAlign: 'center' }}>
        <img src="../../assets/BaybayInscribe-AppIcon.webp" style={{
          width: 92, height: 92, borderRadius: 22, boxShadow: K.shadowCard,
        }} />
        <div style={{ color: 'white', fontSize: 32, fontWeight: 700, marginTop: 16, letterSpacing: '-0.02em' }}>Kudlit</div>
        <div style={{ color: 'rgba(255,255,255,0.85)', fontSize: 14, marginTop: 4, lineHeight: 1.4 }}>
          Learn Baybayin, the pre-colonial<br/>script of the Philippines.
        </div>
      </div>

      {/* Butty */}
      <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', position: 'relative' }}>
        <img src="../../assets/ButtyRead.webp" style={{ width: 200, height: 200, objectFit: 'contain' }} />
      </div>

      {/* Bottom sheet */}
      <div style={{
        position: 'relative', background: K.paper,
        borderTopLeftRadius: 22, borderTopRightRadius: 22,
        padding: '22px 20px 28px',
      }}>
        <KBtn variant="primary" full icon="mail" onClick={onLogin}>Continue with Email</KBtn>
        <div style={{ height: 8 }} />
        <div onClick={onLogin} style={{
          padding: '10px 16px', borderRadius: 8,
          background: K.paper, color: K.blue300,
          border: `1.25px solid ${K.grey400}`,
          display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
          fontSize: 14, fontWeight: 500, cursor: 'pointer',
        }}>
          <img src="../../assets/google.icon.webp" style={{ width: 16, height: 16 }} />
          Continue with Google
        </div>
        <div style={{ textAlign: 'center', fontSize: 11, color: K.grey300, marginTop: 16, lineHeight: 1.5 }}>
          By continuing you agree to the Terms of Service<br/>and Privacy Policy.
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { LoginScreen });
