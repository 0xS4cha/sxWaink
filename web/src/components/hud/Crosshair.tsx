import { motion } from 'motion/react'
import type { ScannerState } from '../../types/scanner'

interface CrosshairProps {
  state: ScannerState
  progress: number
}

const PETAL = 'M20 15.6 C 22.9 12.6, 22.9 7.2, 20 4 C 17.1 7.2, 17.1 12.6, 20 15.6 Z'
const PETAL_ANGLES = [0, 60, 120, 180, 240, 300]
const WHITE = '#ffffff'
const ACCENT = '#3ee6ff'
const BLOCKED = '#ff5d6c'

export function Crosshair({ state, progress }: CrosshairProps) {
  const engaged = state !== 'idle'
  const scanning = state === 'scanning'
  const locked = state === 'locked'
  const blocked = state === 'blocked'
  const filled = locked ? PETAL_ANGLES.length : Math.floor(Math.min(Math.max(progress, 0), 1) * PETAL_ANGLES.length)

  return (
    <div className="pointer-events-none fixed inset-0 flex items-center justify-center">
      <motion.svg
        viewBox="0 0 40 40"
        className="size-[32px] overflow-visible"
        initial={{ opacity: 0, scale: 0.5 }}
        animate={{ opacity: 1, scale: 1 }}
        exit={{ opacity: 0, scale: 0.5 }}
        transition={{ duration: 0.2, ease: [0.22, 1, 0.36, 1] }}
      >
        <motion.g
          style={{ transformOrigin: '20px 20px' }}
          animate={
            scanning
              ? { rotate: 360, scale: 1 }
              : locked
                ? { rotate: 0, scale: [1.18, 1] }
                : { rotate: 0, scale: engaged ? 1.06 : 1 }
          }
          transition={
            scanning
              ? { rotate: { duration: 2.4, ease: 'linear', repeat: Infinity }, scale: { duration: 0.2 } }
              : { type: 'spring', stiffness: 300, damping: 18 }
          }
        >
          {PETAL_ANGLES.map((angle, index) => (
            <g key={angle} transform={`rotate(${angle} 20 20)`}>
              <motion.path
                d={PETAL}
                stroke="#000000"
                strokeWidth={1.9}
                strokeLinejoin="round"
                paintOrder="stroke"
                initial={false}
                animate={{
                  y: engaged ? -1.4 : 0,
                  fill: index < filled ? ACCENT : blocked ? BLOCKED : WHITE,
                }}
                transition={{ type: 'spring', stiffness: 380, damping: 22 }}
              />
            </g>
          ))}
        </motion.g>
      </motion.svg>
    </div>
  )
}
