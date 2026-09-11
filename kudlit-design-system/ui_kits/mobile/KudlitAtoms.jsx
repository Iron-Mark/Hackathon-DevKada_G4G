// Kudlit mobile UI kit — shared atoms

const K = {
  // colors
  bg: 'hsl(226, 91%, 91%)',
  ink: 'hsl(224, 45%, 10%)',
  paper: 'hsl(226, 91%, 91%)',
  blue900: 'hsl(227, 92%, 95%)',
  blue800: 'hsl(224, 100%, 85%)',
  blue500: 'hsl(225, 39%, 53%)',
  blue400: 'hsl(225, 36%, 39%)',
  blue300: 'hsl(226, 65%, 25%)',
  blue200: 'hsl(225, 65%, 20%)',
  grey100: 'hsl(231, 15%, 20%)',
  grey200: 'hsl(231, 15%, 45%)',
  grey300: 'hsla(230, 18%, 50%, 1)',
  grey400: 'hsl(233, 21%, 85%)',
  grey500: 'hsl(225, 25%, 94%)',
  border: 'hsl(226, 65%, 25%)',
  danger: 'hsl(5, 80%, 50%)',
  dangerBg: 'hsl(0, 60%, 94%)',
  success: 'hsl(120, 48%, 59%)',
  warning: 'hsl(41, 60%, 55%)',
  info: 'hsl(204, 80%, 58%)',
  // fonts
  font: "'Geist', ui-sans-serif, system-ui, sans-serif",
  mono: "'Geist Mono', ui-monospace, monospace",
  bayb: "'Baybayin Simple TAWBID', serif",
  // tokens
  r: { sm: 4, md: 8, lg: 10, xl: 14, xxl: 16, full: 9999 },
  shadowCard: '0 4px 4px 0 rgba(0,0,0,0.25)',
  shadowSm: '0 1px 2px 0 rgba(14,20,37,0.06)',
  shadowMd: '0 4px 8px -2px rgba(14,20,37,0.10)',
};

// Top app bar used across Kudlit app screens
function KudlitTopbar({ title, showBurger = true, right }) {
  return (
    <div style={{
      height: 56, background: K.blue500,
      borderBottom: `1.25px solid ${K.blue400}`,
      boxShadow: K.shadowMd,
      display: 'flex', alignItems: 'center', padding: '0 12px',
      position: 'relative', fontFamily: K.font, color: 'white',
      flexShrink: 0,
    }}>
      {showBurger && (
        <div style={{
          width: 32, height: 32, borderRadius: 8, background: K.paper,
          color: K.blue300, display: 'flex', alignItems: 'center',
          justifyContent: 'center', border: `1.25px solid ${K.blue400}`,
          fontSize: 18,
        }}>☰</div>
      )}
      <div style={{
        position: 'absolute', left: '50%', transform: 'translateX(-50%)',
        width: 38, height: 38, borderRadius: 10, overflow: 'hidden',
        boxShadow: K.shadowCard,
      }}>
        <img src="../../assets/BaybayInscribe-AppIcon.webp"
          style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
      </div>
      <div style={{ flex: 1 }} />
      {right || (
        <div style={{
          width: 32, height: 32, borderRadius: '50%', overflow: 'hidden',
          border: `1.25px solid ${K.blue400}`,
        }}>
          <img src="../../assets/user.profile/butty.stand.webp"
            style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
        </div>
      )}
      {title && !right && (
        <span style={{ position:'absolute', left: 54, fontSize: 13, opacity: .8 }}>{title}</span>
      )}
    </div>
  );
}

// Bottom tab bar (Flutter BottomNavigationBar analog)
function KudlitBottomNav({ active = 'home', onTab }) {
  const tabs = [
    { id: 'home', label: 'Home', icon: 'home' },
    { id: 'scan', label: 'Scan', icon: 'scan-text' },
    { id: 'learn', label: 'Learn', icon: 'book-open-text' },
    { id: 'profile', label: 'Profile', icon: 'user' },
  ];
  return (
    <div style={{
      height: 62, background: K.paper,
      borderTop: `1px solid ${K.border}`,
      display: 'flex', alignItems: 'center',
      fontFamily: K.font, flexShrink: 0,
    }}>
      {tabs.map(t => (
        <div key={t.id} onClick={() => onTab && onTab(t.id)}
          style={{
            flex: 1, display: 'flex', flexDirection: 'column',
            alignItems: 'center', gap: 2, cursor: 'pointer',
            color: active === t.id ? K.blue300 : K.grey300,
            fontWeight: active === t.id ? 600 : 400,
          }}>
          <i data-lucide={t.icon} style={{ width: 22, height: 22, strokeWidth: 1.5 }}></i>
          <span style={{ fontSize: 11 }}>{t.label}</span>
        </div>
      ))}
    </div>
  );
}

// Kudlit-brand primary button
function KBtn({ children, variant = 'primary', full, icon, onClick, disabled }) {
  const styles = {
    primary: { bg: K.blue300, fg: K.blue900 },
    secondary: { bg: K.blue900, fg: K.blue400 },
    ghost: { bg: 'transparent', fg: K.blue300 },
    danger: { bg: K.danger, fg: 'white' },
  }[variant] || { bg: K.blue300, fg: K.blue900 };
  return (
    <div onClick={!disabled && onClick}
      style={{
        background: disabled ? 'hsla(225,39%,53%,.6)' : styles.bg,
        color: disabled ? 'hsla(227,92%,95%,.6)' : styles.fg,
        padding: '10px 16px', borderRadius: 8, fontFamily: K.font,
        fontSize: 14, fontWeight: 500, cursor: disabled ? 'not-allowed' : 'pointer',
        display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
        gap: 6, width: full ? '100%' : 'auto', userSelect: 'none',
        transition: 'all 300ms cubic-bezier(.16,1,.3,1)',
      }}>
      {icon && <i data-lucide={icon} style={{ width: 16, height: 16 }}></i>}
      {children}
    </div>
  );
}

// A home-style navigation card (illustrated lesson tile)
function KLessonCard({ title, description, image, onClick }) {
  return (
    <div onClick={onClick} style={{
      background: K.paper, borderRadius: K.r.lg,
      border: `1px solid ${K.grey400}`, boxShadow: K.shadowSm,
      overflow: 'hidden', display: 'flex', flexDirection: 'column',
      fontFamily: K.font, cursor: 'pointer',
      transition: 'all 500ms cubic-bezier(.16,1,.3,1)',
    }}>
      <div style={{
        height: 120, background: K.blue900,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        <img src={image} alt="" style={{ maxHeight: 90, maxWidth: '80%', objectFit: 'contain' }} />
      </div>
      <div style={{ padding: '12px 14px 4px' }}>
        <div style={{ fontSize: 15, fontWeight: 600, color: K.blue300, marginBottom: 4 }}>{title}</div>
        <div style={{ fontSize: 12, color: K.grey300, lineHeight: 1.4 }}>{description}</div>
      </div>
      <div style={{ padding: '8px 14px 14px' }}>
        <div style={{
          background: K.blue300, color: K.blue900,
          padding: '8px', borderRadius: K.r.md, textAlign: 'center',
          fontSize: 13, fontWeight: 500,
        }}>Start Learning <i data-lucide="chevron-right" style={{ width: 14, height: 14, verticalAlign: 'middle' }}></i></div>
      </div>
    </div>
  );
}

// Quiz card (warmer "dbe3fa" treatment)
function KQuizCard({ name, difficulty, time, date, onClick }) {
  const diffColor = { Easy: K.success, Moderate: K.warning, Hard: K.danger }[difficulty] || K.grey200;
  return (
    <div onClick={onClick} style={{
      background: '#dbe3fa', borderRadius: K.r.lg,
      border: `1px solid ${K.grey400}`, padding: 12,
      fontFamily: K.font, cursor: 'pointer', display: 'flex',
      flexDirection: 'column', gap: 8, boxShadow: K.shadowSm,
    }}>
      <div style={{ fontWeight: 700, fontSize: 15, color: K.blue300 }}>{name}</div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', fontSize: 11, color: K.grey200 }}>
        <span style={{ background: diffColor, color: 'white', padding: '2px 10px', borderRadius: K.r.full }}>{difficulty}</span>
        <span style={{ display: 'inline-flex', alignItems: 'center', gap: 3 }}>
          <i data-lucide="clock" style={{ width: 12, height: 12 }}></i> {time}
        </span>
        <span>{date}</span>
      </div>
      <div style={{ background: K.blue500, color: 'white', padding: '8px', borderRadius: K.r.md, textAlign: 'center', fontSize: 13, fontWeight: 500 }}>Take Quiz</div>
    </div>
  );
}

// Section header (home "Guide to Baybayin" / "see more")
function KSection({ title, seeMore, children }) {
  return (
    <div style={{ padding: '18px 16px 8px', fontFamily: K.font }}>
      <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginBottom: 10 }}>
        <h2 style={{ fontSize: 18, fontWeight: 700, color: K.blue300, margin: 0, letterSpacing: '-0.01em' }}>{title}</h2>
        {seeMore && (
          <span style={{ fontSize: 12, color: K.blue400, fontWeight: 500 }}>{seeMore} ›</span>
        )}
      </div>
      {children}
    </div>
  );
}

Object.assign(window, { K, KudlitTopbar, KudlitBottomNav, KBtn, KLessonCard, KQuizCard, KSection });
