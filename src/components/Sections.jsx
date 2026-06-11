import { lazy, Suspense } from 'react'
import { profile, experience, projects, skills, education } from '../data.js'
import { Reveal, TiltCard, SectionTitle, Icon } from './ui.jsx'

// Lazy so three.js stays out of the main bundle; the plain photo is the fallback
const Avatar3D = lazy(() => import('./Avatar3D.jsx'))

/* ---------- Hero ---------- */
export function Hero() {
  return (
    <section id="home" className="hero">
      <div className="container hero-inner">
        <Reveal>
          <p className="hero-hello">
            <span className="pulse-dot" /> Hi, my name is
          </p>
        </Reveal>
        <Reveal delay={100}>
          <h1 className="hero-name">
            Syed <span className="gradient-text">Farhan</span>.
          </h1>
        </Reveal>
        <Reveal delay={200}>
          <h2 className="hero-role">
            I build things for the <span className="gradient-text-alt">web</span>.
          </h2>
        </Reveal>
        <Reveal delay={300}>
          <p className="hero-tagline">
            Full Stack Developer from {profile.location}, specializing in the{' '}
            <strong>MERN stack</strong>. {profile.tagline}
          </p>
        </Reveal>
        <Reveal delay={400}>
          <div className="hero-cta">
            <a className="btn btn-primary" href="#projects">
              View my work
            </a>
            <a className="btn btn-ghost" href={profile.resume} download>
              {Icon.download} Download Resume
            </a>
          </div>
        </Reveal>
        <Reveal delay={500}>
          <div className="hero-socials">
            <a href={profile.socials.github} target="_blank" rel="noreferrer" aria-label="GitHub">
              {Icon.github}
            </a>
            <a href={profile.socials.linkedin} target="_blank" rel="noreferrer" aria-label="LinkedIn">
              {Icon.linkedin}
            </a>
            <a href={profile.socials.twitter} target="_blank" rel="noreferrer" aria-label="X (Twitter)">
              {Icon.twitter}
            </a>
            <a href={`mailto:${profile.email}`} aria-label="Email">
              {Icon.mail}
            </a>
          </div>
        </Reveal>
      </div>
      <a href="#about" className="scroll-hint" aria-label="Scroll down">
        <span />
      </a>
    </section>
  )
}

/* ---------- About ---------- */
export function About() {
  return (
    <section id="about" className="section">
      <div className="container">
        <SectionTitle kicker="01 · Who I am" title="About Me" />
        <div className="about-grid">
          <Reveal className="about-text">
            {profile.about.map((p, i) => (
              <p key={i}>{p}</p>
            ))}
            <div className="stats">
              {profile.stats.map((s) => (
                <div className="stat" key={s.label}>
                  <span className="stat-value gradient-text">{s.value}</span>
                  <span className="stat-label">{s.label}</span>
                </div>
              ))}
            </div>
          </Reveal>
          <Reveal delay={150} className="about-photo-wrap">
            <div className="about-photo">
              <Suspense
                fallback={
                  <>
                    <img src="/syed.jpg" alt="Syed Farhan" loading="lazy" />
                    <div className="photo-ring" />
                  </>
                }
              >
                <Avatar3D />
              </Suspense>
            </div>
          </Reveal>
        </div>
      </div>
    </section>
  )
}

/* ---------- Experience ---------- */
export function Experience() {
  return (
    <section id="experience" className="section">
      <div className="container">
        <SectionTitle kicker="02 · Where I've worked" title="Work Experience" />
        <div className="timeline">
          {experience.map((job, i) => (
            <Reveal key={job.company} delay={i * 120} className="timeline-item">
              <div className="timeline-node" />
              <TiltCard className="job-card" glowColor={i === 0 ? '#7c5cff' : '#22d3ee'}>
                <div className="job-head">
                  <div>
                    <h3>{job.role}</h3>
                    <span className="job-company">@ {job.company}</span>
                  </div>
                  <div className="job-meta">
                    <span className="job-period">{job.period}</span>
                    <span className="job-location">{Icon.pin} {job.location}</span>
                  </div>
                </div>
                <ul className="job-points">
                  {job.points.map((p, j) => (
                    <li key={j}>{p}</li>
                  ))}
                </ul>
                <div className="tags">
                  {job.tech.map((t) => (
                    <span className="tag" key={t}>{t}</span>
                  ))}
                </div>
              </TiltCard>
            </Reveal>
          ))}
        </div>
      </div>
    </section>
  )
}

/* ---------- Projects ---------- */
const projectGlyphs = {
  platform: '▣', search: '◎', ai: '✦', cloud: '☁', cart: '◈', bolt: '⚡', wand: '✎', music: '♫',
}

export function Projects() {
  return (
    <section id="projects" className="section">
      <div className="container">
        <SectionTitle kicker="03 · What I've built" title="Featured Projects" />
        <div className="projects-grid">
          {projects.map((p, i) => (
            <Reveal key={p.title} delay={(i % 3) * 100}>
              <TiltCard className="project-card" glowColor={p.accent}>
                <div className="project-top">
                  <span className="project-glyph" style={{ color: p.accent }}>
                    {projectGlyphs[p.icon] ?? '◆'}
                  </span>
                  <div className="project-links">
                    {p.repo && (
                      <a href={p.repo} target="_blank" rel="noreferrer" aria-label={`${p.title} on GitHub`}>
                        {Icon.github}
                      </a>
                    )}
                    {p.live && (
                      <a href={p.live} target="_blank" rel="noreferrer" aria-label={`${p.title} live demo`}>
                        {Icon.external}
                      </a>
                    )}
                  </div>
                </div>
                <h3>{p.title}</h3>
                <p>{p.description}</p>
                <div className="tags">
                  {p.tech.map((t) => (
                    <span className="tag" key={t}>{t}</span>
                  ))}
                </div>
              </TiltCard>
            </Reveal>
          ))}
        </div>
      </div>
    </section>
  )
}

/* ---------- Skills ---------- */
export function Skills() {
  return (
    <section id="skills" className="section">
      <div className="container">
        <SectionTitle kicker="04 · What I work with" title="Skills & Technologies" />
        <div className="skills-grid">
          {skills.map((group, i) => (
            <Reveal key={group.group} delay={i * 80}>
              <TiltCard className="skill-card" glowColor="#8b7cff">
                <h3>{group.group}</h3>
                <div className="tags tags-lg">
                  {group.items.map((s) => (
                    <span className="tag" key={s}>{s}</span>
                  ))}
                </div>
              </TiltCard>
            </Reveal>
          ))}
        </div>
      </div>
    </section>
  )
}

/* ---------- Education ---------- */
export function Education() {
  return (
    <section id="education" className="section">
      <div className="container">
        <SectionTitle kicker="05 · Where I studied" title="Education" />
        <div className="education-grid">
          {education.map((e, i) => (
            <Reveal key={e.school} delay={i * 120}>
              <TiltCard className="edu-card" glowColor="#34d399">
                <span className="edu-glyph">🎓</span>
                <h3>{e.school}</h3>
                <p className="edu-degree">{e.degree}</p>
                <p className="edu-meta">
                  {e.period} · {e.location}
                </p>
              </TiltCard>
            </Reveal>
          ))}
        </div>
      </div>
    </section>
  )
}

/* ---------- Contact ---------- */
export function Contact() {
  return (
    <section id="contact" className="section contact">
      <div className="container">
        <SectionTitle kicker="06 · What's next" title="Get In Touch" />
        <Reveal>
          <p className="contact-text">
            I'm currently open to new opportunities and interesting projects. Whether
            you have a role in mind, a question, or just want to say hi — my inbox is
            always open.
          </p>
        </Reveal>
        <Reveal delay={150}>
          <div className="hero-cta contact-cta">
            <a className="btn btn-primary btn-lg" href={`mailto:${profile.email}`}>
              {Icon.mail} Say Hello
            </a>
            <a className="btn btn-ghost btn-lg" href={profile.resume} download>
              {Icon.download} Grab my Resume
            </a>
          </div>
        </Reveal>
        <Reveal delay={250}>
          <div className="hero-socials contact-socials">
            <a href={profile.socials.github} target="_blank" rel="noreferrer" aria-label="GitHub">{Icon.github}</a>
            <a href={profile.socials.linkedin} target="_blank" rel="noreferrer" aria-label="LinkedIn">{Icon.linkedin}</a>
            <a href={profile.socials.twitter} target="_blank" rel="noreferrer" aria-label="X (Twitter)">{Icon.twitter}</a>
          </div>
        </Reveal>
      </div>
    </section>
  )
}

/* ---------- Footer ---------- */
export function Footer() {
  return (
    <footer className="footer">
      <p>
        Designed & built by <span className="gradient-text">Syed Farhan</span> · ©{' '}
        {new Date().getFullYear()}
      </p>
    </footer>
  )
}
