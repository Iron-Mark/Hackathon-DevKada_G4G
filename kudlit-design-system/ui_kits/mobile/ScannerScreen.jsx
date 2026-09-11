// Kudlit — Scanner screen
// Camera viewport with detected Baybayin glyphs + "Butty reading" result panel.

function ScannerScreen({ onNavigate }) {
  const [state, setState] = React.useState('scanning'); // 'scanning' | 'detected' | 'empty'
  const [confidence] = React.useState(0.87);

  return (
    <div style={{
      flex: 1, display: 'flex', flexDirection: 'column',
      background: '#0E1425', fontFamily: K.font, color: 'white',
      position: 'relative', overflow: 'hidden',
    }}>
      {/* Camera viewport */}
      <div style={{
        flex: 1, position: 'relative',
        background: `radial-gradient(ellipse at center, #2a3450 0%, #0E1425 80%)`,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        overflow: 'hidden',
      }}>
        {/* fake camera feed texture */}
        <div style={{
          position: 'absolute', inset: 0, opacity: 0.15,
          backgroundImage: `repeating-linear-gradient(45deg, transparent 0 10px, rgba(255,255,255,0.03) 10px 11px)`,
        }} />
        {/* sample Baybayin glyphs */}
        <div style={{
          fontFamily: K.bayb, fontSize: 92, color: 'rgba(255,255,255,0.95)',
          letterSpacing: 8, textShadow: '0 2px 12px rgba(0,0,0,0.5)',
        }}>ᜋᜊᜓᜑᜌ᜔</div>

        {/* detection box overlay */}
        {state !== 'empty' && (
          <>
            <div style={{
              position: 'absolute', left: '18%', top: '38%', width: '64%', height: '24%',
              border: `2px solid ${K.success}`, borderRadius: 6,
              boxShadow: `0 0 0 3000px rgba(14,20,37,0.55)`,
            }}>
              <div style={{
                position: 'absolute', top: -22, left: 0,
                background: K.success, color: '#0E1425',
                fontSize: 10, fontWeight: 700, padding: '2px 6px',
                borderRadius: 4, letterSpacing: '0.04em',
              }}>MABUHAY · {Math.round(confidence*100)}%</div>
            </div>
          </>
        )}

        {/* corner frame */}
        {[['top:24;left:24','border-top','border-left'],['top:24;right:24','border-top','border-right'],['bottom:120;left:24','border-bottom','border-left'],['bottom:120;right:24','border-bottom','border-right']].map((c,i)=>{
          const [pos] = c;
          const [k,v] = pos.split(';');
          const [k2,v2] = v.split(':');
          const style = { position:'absolute', width:24, height:24, borderColor: 'rgba(255,255,255,0.7)', borderStyle:'solid', borderWidth: 0 };
          style[k.split(':')[0]] = Number(k.split(':')[1]);
          style[k2] = Number(v2);
          if (c[1]==='border-top') style.borderTopWidth=3;
          if (c[1]==='border-bottom') style.borderBottomWidth=3;
          if (c[2]==='border-left') style.borderLeftWidth=3;
          if (c[2]==='border-right') style.borderRightWidth=3;
          return <div key={i} style={style} />;
        })}

        {/* top chrome */}
        <div style={{
          position: 'absolute', top: 12, left: 12, right: 12,
          display: 'flex', justifyContent: 'space-between', alignItems: 'center',
        }}>
          <div onClick={() => onNavigate && onNavigate('home')} style={{
            width: 36, height: 36, borderRadius: '50%',
            background: 'rgba(14,20,37,0.7)', backdropFilter: 'blur(4px)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            cursor: 'pointer',
          }}>
            <i data-lucide="x" style={{ width: 18, height: 18 }}></i>
          </div>
          <div style={{ display: 'flex', gap: 8 }}>
            {['zap-off','flashlight','rotate-cw'].map(ic => (
              <div key={ic} style={{
                width: 36, height: 36, borderRadius: '50%',
                background: 'rgba(14,20,37,0.7)',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>
                <i data-lucide={ic} style={{ width: 18, height: 18 }}></i>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Result panel */}
      <div style={{
        background: K.paper, color: K.blue300,
        borderTopLeftRadius: 18, borderTopRightRadius: 18,
        padding: '16px 16px 8px', boxShadow: '0 -8px 20px rgba(0,0,0,0.2)',
      }}>
        <div style={{
          width: 36, height: 4, background: K.grey400, borderRadius: 2,
          margin: '0 auto 12px',
        }} />
        <div style={{ display: 'flex', alignItems: 'flex-start', gap: 12 }}>
          <img src="../../assets/ButtyTextBubble.webp" style={{ width: 54, height: 54, objectFit: 'contain', flexShrink: 0 }} />
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 11, color: K.grey200, textTransform: 'uppercase', letterSpacing: '0.04em', fontWeight: 500 }}>Butty reads</div>
            <div style={{ fontSize: 22, fontWeight: 700, color: K.blue300, marginTop: 2, lineHeight: 1.2 }}>mabuhay</div>
            <div style={{ fontSize: 12, color: K.grey200, marginTop: 4, lineHeight: 1.4 }}>
              Wow! I can read Baybayin!
            </div>
          </div>
          <div style={{
            background: K.success, color: 'white',
            padding: '4px 10px', borderRadius: K.r.full,
            fontSize: 11, fontWeight: 700, flexShrink: 0,
          }}>{Math.round(confidence*100)}%</div>
        </div>

        {/* alternatives */}
        <div style={{ marginTop: 12, paddingTop: 12, borderTop: `1px dashed ${K.grey400}` }}>
          <div style={{ fontSize: 10, color: K.grey300, marginBottom: 6, textTransform: 'uppercase', letterSpacing: '0.04em' }}>Alternatives</div>
          <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
            {['mabohay','mebohey','mabuhai'].map(a => (
              <div key={a} style={{
                fontSize: 12, padding: '4px 10px', borderRadius: K.r.full,
                background: K.blue900, color: K.blue400,
                border: `1px solid ${K.grey400}`,
              }}>{a}</div>
            ))}
          </div>
        </div>

        <div style={{ display: 'flex', gap: 8, marginTop: 12 }}>
          <KBtn variant="secondary" full icon="copy">Copy</KBtn>
          <KBtn variant="primary" full icon="book-open-text">Save</KBtn>
        </div>
        <div style={{ fontSize: 10, color: K.grey300, textAlign: 'center', marginTop: 8, lineHeight: 1.4 }}>
          The AI model may not be 100% accurate. Expect occasional misreads and always verify the output.
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { ScannerScreen });
