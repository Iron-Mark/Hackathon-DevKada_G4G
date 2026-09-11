// Kudlit — Home screen (dashboard)
// Lessons grid + quiz row + Butty mascot welcome banner.

function HomeScreen({ onNavigate }) {
  const lessons = [
    { id: 'vowels', title: 'Vowels', description: 'Learn the three foundational Baybayin vowels: A, E/I, O/U.', image: '../../assets/baybayin.vowels.webp' },
    { id: 'consonants', title: 'Consonants', description: '14 base consonants that carry a default "a" vowel sound.', image: '../../assets/baybayin.consonant.webp' },
    { id: 'kudlit', title: 'Kudlit Marks', description: 'Small marks that shift consonants to "e/i" or "o/u" sounds.', image: '../../assets/baybayin.kudlit.webp' },
    { id: 'soon', title: 'Coming Soon', description: 'More Baybayin lessons on the way. Stay tuned!', image: '../../assets/baybayin.comingsoon.webp' },
  ];
  const quizzes = [
    { id: 'q1', name: 'Multiple Choice', difficulty: 'Easy', time: '3 min', date: 'Daily', image: '../../assets/baybayin.multiplechoice.webp' },
    { id: 'q2', name: 'Fill in the Blanks', difficulty: 'Moderate', time: '5 min', date: 'Weekly', image: '../../assets/baybayin.fillinblanks.webp' },
    { id: 'q3', name: 'Shuffle', difficulty: 'Hard', time: '7 min', date: 'New', image: '../../assets/baybayin.shuffle.webp' },
    { id: 'q4', name: 'Sketch Quiz', difficulty: 'Hard', time: '10 min', date: 'New', image: '../../assets/baybayin.sketchquiz.webp' },
  ];

  return (
    <div style={{
      flex: 1, overflowY: 'auto', background: K.blue900,
      fontFamily: K.font,
      backgroundImage: `url('../../assets/BaybayInscribe-BackgroundImage.webp')`,
      backgroundSize: 'cover', backgroundPosition: 'center',
      backgroundBlendMode: 'luminosity',
    }}>
      {/* Hero banner */}
      <div style={{
        margin: 16, padding: '16px 14px',
        background: `linear-gradient(135deg, ${K.blue500} 0%, ${K.blue400} 100%)`,
        borderRadius: K.r.xl, boxShadow: K.shadowCard,
        color: K.blue900, display: 'flex', alignItems: 'center', gap: 14,
        position: 'relative', overflow: 'hidden',
      }}>
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 11, opacity: .8, fontWeight: 500, letterSpacing: '0.04em', textTransform: 'uppercase' }}>Mabuhay</div>
          <div style={{ fontSize: 22, fontWeight: 700, lineHeight: 1.15, marginTop: 2, marginBottom: 6 }}>Learn Baybayin with Butty</div>
          <div style={{ fontSize: 12, opacity: .9, lineHeight: 1.45 }}>Scan, transliterate, and learn the pre-colonial script of the Philippines — offline.</div>
        </div>
        <img src="../../assets/ButtyWave.webp" style={{ width: 84, height: 84, objectFit: 'contain', flexShrink: 0 }} />
      </div>

      {/* Guide to Baybayin */}
      <KSection title="Guide to Baybayin" seeMore="See more">
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
          {lessons.map(l => (
            <KLessonCard key={l.id} {...l} onClick={() => onNavigate && onNavigate('lesson')} />
          ))}
        </div>
      </KSection>

      {/* Quizzes */}
      <KSection title="Baybayin Quizzes and Challenges" seeMore="See more">
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
          {quizzes.map(q => (
            <KQuizCard key={q.id} {...q} onClick={() => onNavigate && onNavigate('quiz')} />
          ))}
        </div>
      </KSection>

      {/* Tools row */}
      <KSection title="Tools">
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
          <div onClick={() => onNavigate && onNavigate('scan')} style={{
            background: K.paper, borderRadius: K.r.lg, padding: 14,
            border: `1px solid ${K.grey400}`, boxShadow: K.shadowSm, cursor: 'pointer',
            display: 'flex', flexDirection: 'column', gap: 8,
          }}>
            <div style={{ width: 36, height: 36, borderRadius: K.r.md, background: K.blue900, color: K.blue300, display:'flex',alignItems:'center',justifyContent:'center' }}>
              <i data-lucide="scan-text" style={{ width: 20, height: 20 }}></i>
            </div>
            <div style={{ fontSize: 14, fontWeight: 600, color: K.blue300 }}>Baybayin Scanner</div>
            <div style={{ fontSize: 11, color: K.grey300, lineHeight: 1.4 }}>Point your camera at handwritten Baybayin.</div>
          </div>
          <div onClick={() => onNavigate && onNavigate('transliterate')} style={{
            background: K.paper, borderRadius: K.r.lg, padding: 14,
            border: `1px solid ${K.grey400}`, boxShadow: K.shadowSm, cursor: 'pointer',
            display: 'flex', flexDirection: 'column', gap: 8,
          }}>
            <div style={{ width: 36, height: 36, borderRadius: K.r.md, background: K.blue900, color: K.blue300, display:'flex',alignItems:'center',justifyContent:'center' }}>
              <i data-lucide="languages" style={{ width: 20, height: 20 }}></i>
            </div>
            <div style={{ fontSize: 14, fontWeight: 600, color: K.blue300 }}>Transliterator</div>
            <div style={{ fontSize: 11, color: K.grey300, lineHeight: 1.4 }}>Type Latin, read Baybayin — and back.</div>
          </div>
        </div>
      </KSection>

      <div style={{ height: 20 }} />
    </div>
  );
}

Object.assign(window, { HomeScreen });
