// Kudlit — Quiz screen (multiple-choice)
// Active quiz with lives, progress, and options.

function QuizScreen({ onNavigate }) {
  const [selected, setSelected] = React.useState(null);
  const [lives] = React.useState(3);
  const correct = 1; // index of correct answer
  const options = [
    { text: 'bahay',  bayb: 'ᜊᜑᜌ᜔' },
    { text: 'buhay',  bayb: 'ᜊᜓᜑᜌ᜔' },
    { text: 'bahaw',  bayb: 'ᜊᜑᜏ᜔' },
    { text: 'buhok',  bayb: 'ᜊᜓᜑᜓᜃ᜔' },
  ];

  return (
    <div style={{
      flex: 1, overflowY: 'auto', background: K.blue900,
      fontFamily: K.font, display: 'flex', flexDirection: 'column',
    }}>
      {/* Top bar — progress + lives */}
      <div style={{
        padding: '12px 16px', background: K.paper,
        borderBottom: `1px solid ${K.grey400}`,
        display: 'flex', alignItems: 'center', gap: 12,
      }}>
        <i data-lucide="x" style={{ width: 20, height: 20, color: K.grey200 }}></i>
        <div style={{ flex: 1, height: 8, background: K.grey400, borderRadius: 4, overflow: 'hidden' }}>
          <div style={{ width: '40%', height: '100%', background: K.success, borderRadius: 4 }} />
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 4, color: K.danger, fontWeight: 700, fontSize: 14 }}>
          <i data-lucide="heart" style={{ width: 16, height: 16, fill: K.danger }}></i>
          {lives}
        </div>
      </div>

      {/* Question */}
      <div style={{ padding: '20px 16px 10px' }}>
        <div style={{ fontSize: 11, color: K.grey300, textTransform: 'uppercase', letterSpacing: '0.04em', fontWeight: 600, marginBottom: 8 }}>Question 2 of 5</div>
        <h2 style={{ fontSize: 20, fontWeight: 700, color: K.blue300, margin: 0, lineHeight: 1.25 }}>What does this Baybayin word read as?</h2>
      </div>

      {/* Glyph card */}
      <div style={{ padding: '4px 16px 16px' }}>
        <div style={{
          background: K.paper, borderRadius: K.r.xl,
          border: `1.25px solid ${K.blue400}`, padding: '28px 20px',
          boxShadow: K.shadowCard, textAlign: 'center',
        }}>
          <div style={{
            fontFamily: K.bayb, fontSize: 72, color: K.blue300,
            lineHeight: 1, letterSpacing: 4,
          }}>ᜊᜓᜑᜌ᜔</div>
          <div style={{ fontSize: 11, color: K.grey300, marginTop: 12, letterSpacing: '0.04em', textTransform: 'uppercase' }}>Tap the correct romanization</div>
        </div>
      </div>

      {/* Options */}
      <div style={{ padding: '0 16px', display: 'flex', flexDirection: 'column', gap: 8 }}>
        {options.map((o, i) => {
          const isSelected = selected === i;
          const isCorrect = selected !== null && i === correct;
          const isWrong = isSelected && i !== correct;
          let bg = K.paper, fg = K.blue300, border = K.grey400;
          if (isCorrect) { bg = 'hsl(120, 60%, 94%)'; border = K.success; }
          if (isWrong) { bg = 'hsl(0, 60%, 94%)'; border = K.danger; }
          return (
            <div key={i} onClick={() => selected === null && setSelected(i)} style={{
              background: bg, borderRadius: K.r.lg,
              border: `1.25px solid ${border}`, padding: '12px 14px',
              display: 'flex', alignItems: 'center', gap: 12,
              cursor: selected === null ? 'pointer' : 'default',
              boxShadow: K.shadowSm,
              transition: 'all 300ms cubic-bezier(.16,1,.3,1)',
            }}>
              <div style={{
                width: 28, height: 28, borderRadius: K.r.md,
                background: K.blue900, color: K.blue400,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                fontSize: 12, fontWeight: 700,
              }}>{['A','B','C','D'][i]}</div>
              <div style={{ flex: 1, fontSize: 15, fontWeight: 500, color: fg }}>{o.text}</div>
              {isCorrect && <i data-lucide="check-circle-2" style={{ width: 20, height: 20, color: K.success }}></i>}
              {isWrong && <i data-lucide="x-circle" style={{ width: 20, height: 20, color: K.danger }}></i>}
            </div>
          );
        })}
      </div>

      {/* Footer */}
      <div style={{ padding: '16px', marginTop: 'auto' }}>
        {selected === null ? (
          <KBtn full disabled>Select an answer</KBtn>
        ) : selected === correct ? (
          <div style={{
            background: 'hsl(120, 60%, 94%)', padding: 12,
            borderRadius: K.r.lg, display: 'flex', alignItems: 'center', gap: 10,
          }}>
            <img src="../../assets/ButtyThumbsUp.webp" onError={e => e.target.src = '../../assets/user.profile/butty.thumbsup.webp'} style={{ width: 40, height: 40 }} />
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 14, fontWeight: 700, color: K.success }}>Correct!</div>
              <div style={{ fontSize: 11, color: K.grey200 }}>"buhay" means "life" in Filipino.</div>
            </div>
            <KBtn variant="primary">Continue</KBtn>
          </div>
        ) : (
          <div style={{
            background: 'hsl(0, 60%, 94%)', padding: 12,
            borderRadius: K.r.lg, display: 'flex', alignItems: 'center', gap: 10,
          }}>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 14, fontWeight: 700, color: K.danger }}>Not quite.</div>
              <div style={{ fontSize: 11, color: K.grey200 }}>The correct answer is "buhay".</div>
            </div>
            <KBtn variant="primary">Continue</KBtn>
          </div>
        )}
      </div>
    </div>
  );
}

Object.assign(window, { QuizScreen });
