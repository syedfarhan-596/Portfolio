import { useRef, useMemo, useState, useEffect, Suspense } from 'react'
import { Canvas, useFrame, useThree } from '@react-three/fiber'
import { Points, PointMaterial, Float, MeshDistortMaterial } from '@react-three/drei'
import * as random from 'maath/random/dist/maath-random.esm'

const prefersReducedMotion =
  typeof window !== 'undefined' &&
  window.matchMedia('(prefers-reduced-motion: reduce)').matches

function useIsMobile() {
  const [mobile, setMobile] = useState(
    typeof window !== 'undefined' && window.innerWidth < 768,
  )
  useEffect(() => {
    const onResize = () => setMobile(window.innerWidth < 768)
    window.addEventListener('resize', onResize)
    return () => window.removeEventListener('resize', onResize)
  }, [])
  return mobile
}

function ParticleField({ count }) {
  const ref = useRef()
  const positions = useMemo(
    () => random.inSphere(new Float32Array(count * 3), { radius: 14 }),
    [count],
  )
  useFrame((state, delta) => {
    if (prefersReducedMotion || !ref.current) return
    ref.current.rotation.x -= delta / 30
    ref.current.rotation.y -= delta / 40
  })
  return (
    <group rotation={[0, 0, Math.PI / 4]}>
      <Points key={count} ref={ref} positions={positions} stride={3} frustumCulled={false}>
        <PointMaterial
          transparent
          color="#8b7cff"
          size={0.035}
          sizeAttenuation
          depthWrite={false}
          opacity={0.7}
        />
      </Points>
    </group>
  )
}

function HeroOrb({ mobile }) {
  const group = useRef()
  const { pointer } = useThree()
  useFrame((state, delta) => {
    if (!group.current) return
    // Fade the orb out as the user scrolls past the hero
    const fade = Math.max(0, 1 - window.scrollY / (window.innerHeight * 0.9))
    group.current.scale.setScalar((mobile ? 0.62 : 1) * (0.6 + 0.4 * fade))
    group.current.visible = fade > 0.02
    if (prefersReducedMotion) return
    group.current.rotation.y += delta * 0.15
    // Gentle parallax toward the pointer
    group.current.position.x +=
      ((mobile ? 0 : 3.4) + pointer.x * 0.4 - group.current.position.x) * 0.04
    group.current.position.y +=
      ((mobile ? 1.6 : 0.5) + pointer.y * 0.3 - group.current.position.y) * 0.04
  })
  return (
    <group ref={group} position={[mobile ? 0 : 3.4, mobile ? 1.6 : 0.5, 0]}>
      <Float speed={1.6} rotationIntensity={0.6} floatIntensity={1.2}>
        <mesh>
          <icosahedronGeometry args={[1.5, 24]} />
          <MeshDistortMaterial
            color="#6d4aff"
            emissive="#2a1670"
            roughness={0.18}
            metalness={0.55}
            distort={0.38}
            speed={prefersReducedMotion ? 0 : 1.8}
          />
        </mesh>
        <mesh scale={1.85} rotation={[Math.PI / 5, 0, Math.PI / 7]}>
          <torusGeometry args={[1.35, 0.012, 12, 96]} />
          <meshBasicMaterial color="#22d3ee" transparent opacity={0.55} />
        </mesh>
        <mesh scale={2.15} rotation={[-Math.PI / 3, Math.PI / 6, 0]}>
          <torusGeometry args={[1.35, 0.008, 12, 96]} />
          <meshBasicMaterial color="#8b7cff" transparent opacity={0.35} />
        </mesh>
      </Float>
    </group>
  )
}

export default function Scene3D() {
  const mobile = useIsMobile()
  return (
    <div className="scene3d" aria-hidden="true">
      <Canvas
        dpr={[1, mobile ? 1.5 : 1.75]}
        camera={{ position: [0, 0, 8], fov: 55 }}
        gl={{ antialias: !mobile, alpha: true, powerPreference: 'high-performance' }}
        frameloop={prefersReducedMotion ? 'demand' : 'always'}
      >
        <Suspense fallback={null}>
          <ambientLight intensity={0.6} />
          <directionalLight position={[4, 6, 5]} intensity={1.4} color="#c4b5fd" />
          <pointLight position={[-6, -4, -2]} intensity={0.8} color="#22d3ee" />
          <ParticleField count={mobile ? 1600 : 4200} />
          <HeroOrb mobile={mobile} />
        </Suspense>
      </Canvas>
    </div>
  )
}
