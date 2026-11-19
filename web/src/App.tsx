import { AnimatePresence } from 'motion/react'
import { useEffect, useState } from 'react'
import { Crosshair } from './components/hud/Crosshair'
import { useNuiEvent } from './hooks/useNuiEvent'
import type { ScannerState, SetScannerData, VibrateData } from './types/scanner'
import { fetchNui } from './utils/fetchNui'
import { isEnvBrowser } from './utils/nui'

export default function App() {
  const [active, setActive] = useState(false)
  const [state, setState] = useState<ScannerState>('idle')
  const [progress, setProgress] = useState(0)
  const [vibration, setVibration] = useState({ id: 0, pulses: 1 })

  useNuiEvent<SetScannerData>('setScanner', (data) => {
    setActive(data.active)
    setState(data.state ?? 'idle')
    setProgress(data.progress ?? 0)
  })

  useNuiEvent<VibrateData>('vibrate', (data) => {
    setVibration((current) => ({ id: current.id + 1, pulses: data.pulses ?? 1 }))
  })

  useEffect(() => {
    void fetchNui('nuiReady', { ok: true })
  }, [])

  useEffect(() => {
    if (!import.meta.env.DEV || !isEnvBrowser()) return

    document.body.style.background = 'linear-gradient(180deg,#6d7a86 0%,#3d4651 55%,#2a2f36 100%)'

    const preview = new URLSearchParams(window.location.search).get('preview') as ScannerState | null
    if (preview) {
      setActive(true)
      setState(preview)
      setProgress(preview === 'scanning' ? 0.62 : preview === 'locked' ? 1 : 0)
      return
    }

    let raf = 0
    const run = () => {
      setActive(true)
      setState('idle')
      setProgress(0)
      window.setTimeout(() => setState('target'), 900)
      window.setTimeout(() => {
        setState('scanning')
        const start = performance.now()
        const step = (now: number) => {
          const p = Math.min((now - start) / 1600, 1)
          setProgress(p)
          if (p < 1) raf = requestAnimationFrame(step)
          else setState('locked')
        }
        raf = requestAnimationFrame(step)
      }, 1800)
    }

    run()
    const loop = window.setInterval(run, 8000)
    return () => {
      window.clearInterval(loop)
      cancelAnimationFrame(raf)
    }
  }, [])

  return (
    <AnimatePresence>
      {active && <Crosshair key="crosshair" state={state} progress={progress} vibration={vibration} />}
    </AnimatePresence>
  )
}
