import { useRef, useEffect } from 'react'
import { Canvas, useFrame } from '@react-three/fiber'
import { Float, ContactShadows } from '@react-three/drei'

const prefersReducedMotion =
  typeof window !== 'undefined' &&
  window.matchMedia('(prefers-reduced-motion: reduce)').matches

/* Palette — tuned to read as a clean, professional 3D character */
const C = {
  skin: '#cf9468',
  skinDark: '#b97f54',
  beard: '#2e2119',
  hair: '#231711',
  brow: '#2a1d15',
  eyeWhite: '#f5f3ef',
  iris: '#3c2a1e',
  shirt: '#2f3a5f',
  collar: '#27314f',
  glasses: '#1f232e',
  lens: '#8fb6d9',
  phones: '#171a23',
  mouth: '#7a4a3a',
}

function Avatar() {
  const head = useRef()
  const body = useRef()
  const eyes = useRef()
  const mouse = useRef({ x: 0, y: 0 })

  useEffect(() => {
    const onMove = (e) => {
      mouse.current.x = (e.clientX / window.innerWidth) * 2 - 1
      mouse.current.y = (e.clientY / window.innerHeight) * 2 - 1
    }
    window.addEventListener('mousemove', onMove, { passive: true })
    return () => window.removeEventListener('mousemove', onMove)
  }, [])

  useFrame(({ clock }) => {
    if (prefersReducedMotion) return
    const t = clock.getElapsedTime()
    const canHover = window.matchMedia('(hover: hover)').matches

    // head tracks the cursor (or sways gently on touch devices)
    const ty = canHover ? mouse.current.x * 0.5 : Math.sin(t * 0.6) * 0.25
    const tx = canHover ? mouse.current.y * 0.25 : Math.sin(t * 0.4) * 0.06
    if (head.current) {
      head.current.rotation.y += (ty - head.current.rotation.y) * 0.07
      head.current.rotation.x += (tx - head.current.rotation.x) * 0.07
    }
    // body turns a little less than the head — feels natural
    if (body.current) {
      body.current.rotation.y += (ty * 0.35 - body.current.rotation.y) * 0.05
      body.current.scale.y = 1 + Math.sin(t * 1.6) * 0.008 // breathing
    }
    // blink every ~3.6s
    if (eyes.current) {
      const phase = t % 3.6
      eyes.current.scale.y = phase > 3.45 ? Math.max(0.08, 1 - (phase - 3.45) * 14) : 1
    }
  })

  return (
    <group position={[0, -0.55, 0]}>
      {/* ---- torso ---- */}
      <group ref={body}>
        <mesh position={[0, -1.42, 0]} scale={[1.25, 0.95, 0.62]}>
          <sphereGeometry args={[1, 48, 32]} />
          <meshStandardMaterial color={C.shirt} roughness={0.75} />
        </mesh>
        {/* collar */}
        <mesh position={[-0.22, -0.78, 0.4]} rotation={[0.25, 0.35, -0.5]}>
          <boxGeometry args={[0.4, 0.16, 0.06]} />
          <meshStandardMaterial color={C.collar} roughness={0.7} />
        </mesh>
        <mesh position={[0.22, -0.78, 0.4]} rotation={[0.25, -0.35, 0.5]}>
          <boxGeometry args={[0.4, 0.16, 0.06]} />
          <meshStandardMaterial color={C.collar} roughness={0.7} />
        </mesh>
        {/* buttons */}
        {[-1.0, -1.25, -1.5].map((y) => (
          <mesh key={y} position={[0, y, 0.585]}>
            <sphereGeometry args={[0.035, 12, 12]} />
            <meshStandardMaterial color="#aeb6cf" roughness={0.4} />
          </mesh>
        ))}
        {/* headphones resting around the neck */}
        <mesh position={[0, -0.88, 0.12]} rotation={[1.25, 0, 0]}>
          <torusGeometry args={[0.5, 0.062, 14, 40]} />
          <meshStandardMaterial color={C.phones} roughness={0.5} metalness={0.3} />
        </mesh>
        <mesh position={[-0.5, -0.95, 0.3]} rotation={[0, 0.5, 0]}>
          <cylinderGeometry args={[0.13, 0.13, 0.09, 20]} />
          <meshStandardMaterial color={C.phones} roughness={0.45} metalness={0.35} />
        </mesh>
        <mesh position={[0.5, -0.95, 0.3]} rotation={[0, -0.5, 0]}>
          <cylinderGeometry args={[0.13, 0.13, 0.09, 20]} />
          <meshStandardMaterial color={C.phones} roughness={0.45} metalness={0.35} />
        </mesh>
        {/* neck */}
        <mesh position={[0, -0.62, 0]}>
          <cylinderGeometry args={[0.3, 0.34, 0.55, 24]} />
          <meshStandardMaterial color={C.skinDark} roughness={0.8} />
        </mesh>
      </group>

      {/* ---- head ---- */}
      <group ref={head} position={[0, 0.45, 0]}>
        {/* skull */}
        <mesh scale={[0.92, 1.04, 0.9]}>
          <sphereGeometry args={[0.85, 48, 32]} />
          <meshStandardMaterial color={C.skin} roughness={0.8} />
        </mesh>
        {/* trimmed beard — lower face shell */}
        <mesh position={[0, -0.3, 0.02]} scale={[0.875, 0.68, 0.86]}>
          <sphereGeometry args={[0.95, 40, 28]} />
          <meshStandardMaterial color={C.beard} roughness={0.95} />
        </mesh>
        {/* hair — back cap + quiff */}
        <mesh position={[0, 0.28, -0.1]} scale={[0.95, 0.92, 0.92]}>
          <sphereGeometry args={[0.88, 40, 28]} />
          <meshStandardMaterial color={C.hair} roughness={0.95} />
        </mesh>
        <mesh position={[0.1, 0.86, 0.32]} rotation={[0.5, 0, -0.15]} scale={[0.55, 0.3, 0.45]}>
          <sphereGeometry args={[0.8, 28, 20]} />
          <meshStandardMaterial color={C.hair} roughness={0.95} />
        </mesh>
        <mesh position={[-0.25, 0.8, 0.28]} rotation={[0.4, 0, 0.25]} scale={[0.45, 0.26, 0.4]}>
          <sphereGeometry args={[0.8, 28, 20]} />
          <meshStandardMaterial color={C.hair} roughness={0.95} />
        </mesh>
        {/* ears */}
        <mesh position={[-0.78, -0.02, 0]} scale={[0.4, 1, 0.7]}>
          <sphereGeometry args={[0.14, 20, 16]} />
          <meshStandardMaterial color={C.skinDark} roughness={0.8} />
        </mesh>
        <mesh position={[0.78, -0.02, 0]} scale={[0.4, 1, 0.7]}>
          <sphereGeometry args={[0.14, 20, 16]} />
          <meshStandardMaterial color={C.skinDark} roughness={0.8} />
        </mesh>
        {/* brows */}
        <mesh position={[-0.3, 0.28, 0.74]} rotation={[0, 0, 0.06]}>
          <boxGeometry args={[0.3, 0.06, 0.06]} />
          <meshStandardMaterial color={C.brow} roughness={0.9} />
        </mesh>
        <mesh position={[0.3, 0.28, 0.74]} rotation={[0, 0, -0.06]}>
          <boxGeometry args={[0.3, 0.06, 0.06]} />
          <meshStandardMaterial color={C.brow} roughness={0.9} />
        </mesh>
        {/* eyes (blink via scale) */}
        <group ref={eyes}>
          <mesh position={[-0.3, 0.1, 0.72]} scale={[1, 1, 0.55]}>
            <sphereGeometry args={[0.13, 24, 18]} />
            <meshStandardMaterial color={C.eyeWhite} roughness={0.35} />
          </mesh>
          <mesh position={[0.3, 0.1, 0.72]} scale={[1, 1, 0.55]}>
            <sphereGeometry args={[0.13, 24, 18]} />
            <meshStandardMaterial color={C.eyeWhite} roughness={0.35} />
          </mesh>
          <mesh position={[-0.3, 0.09, 0.79]}>
            <sphereGeometry args={[0.058, 16, 12]} />
            <meshStandardMaterial color={C.iris} roughness={0.3} />
          </mesh>
          <mesh position={[0.3, 0.09, 0.79]}>
            <sphereGeometry args={[0.058, 16, 12]} />
            <meshStandardMaterial color={C.iris} roughness={0.3} />
          </mesh>
        </group>
        {/* glasses — thin professional frames with a faint tint */}
        <group position={[0, 0.1, 0.78]}>
          <mesh position={[-0.3, 0, 0]}>
            <torusGeometry args={[0.18, 0.022, 12, 32]} />
            <meshStandardMaterial color={C.glasses} roughness={0.35} metalness={0.5} />
          </mesh>
          <mesh position={[0.3, 0, 0]}>
            <torusGeometry args={[0.18, 0.022, 12, 32]} />
            <meshStandardMaterial color={C.glasses} roughness={0.35} metalness={0.5} />
          </mesh>
          <mesh position={[-0.3, 0, 0.001]}>
            <circleGeometry args={[0.17, 24]} />
            <meshStandardMaterial color={C.lens} transparent opacity={0.22} roughness={0.1} metalness={0.2} />
          </mesh>
          <mesh position={[0.3, 0, 0.001]}>
            <circleGeometry args={[0.17, 24]} />
            <meshStandardMaterial color={C.lens} transparent opacity={0.22} roughness={0.1} metalness={0.2} />
          </mesh>
          <mesh position={[0, 0.02, 0]}>
            <boxGeometry args={[0.26, 0.025, 0.025]} />
            <meshStandardMaterial color={C.glasses} roughness={0.35} metalness={0.5} />
          </mesh>
          {/* temple arms back to the ears */}
          <mesh position={[-0.62, 0.02, -0.38]} rotation={[0, -1.1, 0]}>
            <boxGeometry args={[0.55, 0.022, 0.022]} />
            <meshStandardMaterial color={C.glasses} roughness={0.35} metalness={0.5} />
          </mesh>
          <mesh position={[0.62, 0.02, -0.38]} rotation={[0, 1.1, 0]}>
            <boxGeometry args={[0.55, 0.022, 0.022]} />
            <meshStandardMaterial color={C.glasses} roughness={0.35} metalness={0.5} />
          </mesh>
        </group>
        {/* nose */}
        <mesh position={[0, -0.08, 0.84]} scale={[0.8, 1.1, 0.9]}>
          <sphereGeometry args={[0.095, 20, 16]} />
          <meshStandardMaterial color={C.skinDark} roughness={0.8} />
        </mesh>
        {/* confident subtle smile */}
        <mesh position={[0, -0.38, 0.74]} rotation={[0.1, 0, 0]}>
          <torusGeometry args={[0.14, 0.022, 10, 24, Math.PI * 0.75]} />
          <meshStandardMaterial color={C.mouth} roughness={0.7} />
        </mesh>
      </group>
    </group>
  )
}

export default function Avatar3D() {
  return (
    <div className="avatar3d">
      <Canvas
        dpr={[1, 2]}
        camera={{ position: [0, 0.1, 4.4], fov: 42 }}
        gl={{ antialias: true, alpha: true, powerPreference: 'high-performance' }}
        frameloop={prefersReducedMotion ? 'demand' : 'always'}
      >
        <ambientLight intensity={0.75} />
        <directionalLight position={[3, 4, 5]} intensity={1.5} color="#fff6ec" />
        <directionalLight position={[-4, 1, 2]} intensity={0.4} color="#c4b5fd" />
        <pointLight position={[0, 1, -4]} intensity={1.1} color="#22d3ee" />
        <Float
          speed={prefersReducedMotion ? 0 : 1.4}
          rotationIntensity={0}
          floatIntensity={prefersReducedMotion ? 0 : 0.25}
        >
          <Avatar />
        </Float>
        <ContactShadows position={[0, -2.35, 0]} opacity={0.45} scale={6} blur={2.6} far={3} color="#000020" />
      </Canvas>
      <div className="photo-ring" />
    </div>
  )
}
