import { lazy, Suspense } from 'react'
import Navbar from './components/Navbar.jsx'
import { ScrollProgress, CursorGlow } from './components/ui.jsx'
import {
  Hero,
  About,
  Experience,
  Projects,
  Skills,
  Education,
  Contact,
  Footer,
} from './components/Sections.jsx'

// Lazy-load the 3D scene so first paint isn't blocked by three.js
const Scene3D = lazy(() => import('./components/Scene3D.jsx'))

export default function App() {
  return (
    <>
      <Suspense fallback={null}>
        <Scene3D />
      </Suspense>
      <CursorGlow />
      <ScrollProgress />
      <Navbar />
      <main>
        <Hero />
        <About />
        <Experience />
        <Projects />
        <Skills />
        <Education />
        <Contact />
      </main>
      <Footer />
    </>
  )
}
