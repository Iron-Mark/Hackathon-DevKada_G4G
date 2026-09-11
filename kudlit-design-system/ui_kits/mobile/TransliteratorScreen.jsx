// Kudlit — Transliterator screen
// Type Latin → read Baybayin, with swap control.

function TransliteratorScreen({ onNavigate }) {
  const [latin, setLatin] = React.useState('mabuhay');
  const [direction, setDirection] = React.useState('latin-to-bayb');

  // Simple latin → bayb substitution for display
  const toBaybayin = (s) => s.toLowerCase()
    .replace(/ma/g, 'ᜋ').replace(/bu/g, 'ᜊᜓ').replace(/ha/g, 'ᜑ').replace(/y/g, 'ᜌ᜔')
    .replace(/ka/g, 'ᜃ').replace(/ta/g, 'ᜆ').replace(/sa/g, 'ᜐ').replace(/na/g, 'ᜈ')
    .replace(/la/g, 'ᜎ').replace(/pa/g, 'ᜉ').replace(/ga/g, 'ᜄ').replace(/da/g, 'ᜇ')
    .replace(/a/g, 'ᜀ').replace(/e|i/g, 'ᜁ').replace(/o|u/g, 'ᜂ');

  return (
    <div style={{
      flex: 1, overflowY: 'auto', background: K.blue900,
      fontFamily: K.font, display: 'flex', flexDirection: 'column',
    }}>
      {/* Header banner */}
      <div style={{
        margin: 16, borderRadius: K.r.xl, overflow: 'hidden',
        background: K.paper, boxShadow: K.shadowSm,
        border: `1px solid ${K.grey400}`,
      }}>
        <div style={{
          height: 96, background: K.blue800,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          backgroundImage: `url('../../assets/TransliteratorHeader.webp')`,
          backgroundSize: 'cover', backgroundPosition: 'center',
        }} />
        <div style={{ padding: 14 }}>
          <div style={{ fontSize: 18, fontWeight: 700, color: K.blue300, marginBottom: 4 }}>Baybayin Transliterator</div>
          <div style={{ fontSize: 12, color: K.grey300, lineHeight: 1.4 }}>
            Convert between Latin script and Baybayin. Type below and see the result instantly.
          </div>
        </div>
      </div>

      {/* Direction toggle */}
      <div style={{ padding: '0 16px 12px', display: 'flex', justifyContent: 'center' }}>
        <div style={{
          display: 'inline-flex', background: K.paper,
          borderRadius: K.r.full, padding: 3,
          border: `1px solid ${K.grey400}`,
        }}>
          {[['latin-to-bayb','Latin → Baybayin'],['bayb-to-latin','Baybayin → Latin']].map(([id,lbl]) => (
            <div key={id} onClick={() => setDirection(id)} style={{
              padding: '6px 14px', fontSize: 12, fontWeight: 500,
              borderRadius: K.r.full, cursor: 'pointer',
              background: direction === id ? K.blue300 : 'transparent',
              color: direction === id ? K.blue900 : K.grey200,
              transition: 'all 300ms cubic-bezier(.16,1,.3,1)',
            }}>{lbl}</div>
          ))}
        </div>
      </div>

      {/* Input card */}
      <div style={{ padding: '0 16px' }}>
        <div style={{
          background: K.paper, borderRadius: K.r.lg,
          border: `1px solid ${K.grey400}`, padding: 14,
          boxShadow: K.shadowSm, marginBottom: 10,
        }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 8 }}>
            <span style={{ fontSize: 11, color: K.grey300, textTransform: 'uppercase', letterSpacing: '0.04em', fontWeight: 500 }}>Latin (Filipino)</span>
            <span style={{ fontSize: 11, color: K.grey300 }}>🇵🇭 PH</span>
          </div>
          <textarea value={latin} onChange={e => setLatin(e.target.value)} style={{
            width: '100%', border: 'none', outline: 'none',
            fontFamily: K.font, fontSize: 22, fontWeight: 500,
            color: K.blue300, background: 'transparent', resize: 'none',
            minHeight: 50,
          }} />
          <div style={{ fontSize: 10, color: K.grey300, marginTop: 4 }}>{latin.length} characters</div>
        </div>

        {/* Swap button */}
        <div style={{ display: 'flex', justifyContent: 'center', margin: '-4px 0' }}>
          <div style={{
            width: 38, height: 38, borderRadius: '50%',
            background: K.blue300, color: K.blue900,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            boxShadow: K.shadowCard, cursor: 'pointer', position: 'relative', zIndex: 1,
          }}>
            <i data-lucide="arrow-up-down" style={{ width: 18, height: 18 }}></i>
          </div>
        </div>

        {/* Output card */}
        <div style={{
          background: K.blue800, borderRadius: K.r.lg,
          border: `1.25px solid ${K.blue400}`, padding: 14,
          boxShadow: K.shadowSm, marginTop: 10,
        }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 8 }}>
            <span style={{ fontSize: 11, color: K.blue300, textTransform: 'uppercase', letterSpacing: '0.04em', fontWeight: 500 }}>Baybayin</span>
            <i data-lucide="copy" style={{ width: 14, height: 14, color: K.blue300 }}></i>
          </div>
          <div style={{
            fontFamily: K.bayb, fontSize: 44, lineHeight: 1.1,
            color: K.blue300, minHeight: 56, letterSpacing: 2,
          }}>{toBaybayin(latin)}</div>
        </div>
      </div>

      {/* History */}
      <div style={{ padding: '20px 16px 16px' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 10 }}>
          <h3 style={{ fontSize: 14, fontWeight: 700, color: K.blue300, margin: 0 }}>Recent</h3>
          <span style={{ fontSize: 11, color: K.blue400 }}>Clear History</span>
        </div>
        {[['salamat','ᜐᜎᜋᜆ᜔'],['kumusta','ᜃᜓᜋᜓᜐ᜔ᜆ'],['bayan','ᜊᜌᜈ᜔']].map(([l,b]) => (
          <div key={l} style={{
            display: 'flex', alignItems: 'center', gap: 10,
            padding: '10px 12px', background: K.paper,
            borderRadius: K.r.md, border: `1px solid ${K.grey400}`,
            marginBottom: 6,
          }}>
            <div style={{ flex: 1, fontSize: 13, color: K.blue300, fontWeight: 500 }}>{l}</div>
            <div style={{ fontFamily: K.bayb, fontSize: 20, color: K.blue400 }}>{b}</div>
            <i data-lucide="chevron-right" style={{ width: 14, height: 14, color: K.grey300 }}></i>
          </div>
        ))}
      </div>
    </div>
  );
}

Object.assign(window, { TransliteratorScreen });
