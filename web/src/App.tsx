import { AnimatePresence } from 'motion/react'
import { useEffect, useState } from 'react'
import { Crosshair } from './components/hud/Crosshair'
import { VehicleWidget } from './components/hud/VehicleWidget'
import { useNuiEvent } from './hooks/useNuiEvent'
import type { SetSettingsData, Units } from './types/nui'
import type { ScannedVehicle, ScannerState, SetScannerData, SetWidgetData, VibrateData } from './types/scanner'
import { debugData } from './utils/debugData'
import { fetchNui } from './utils/fetchNui'
import { isEnvBrowser } from './utils/nui'

const DEMO_VEHICLE: ScannedVehicle = {
  brand: 'Imponte',
  model: "'77 Phoenix",
  plate: '46EEK572',
  owner: 'Lucas Martin',
  locked: true,
  performance: { speed: 0.72, acceleration: 0.64, braking: 0.38, traction: 0.55, maxSpeed: 50.5 },
  details: { class: 'Muscle', seats: 2, fuel: 64, engine: 18 },
}

export default function App() {
  const [active, setActive] = useState(false)
  const [state, setState] = useState<ScannerState>('idle')
  const [progress, setProgress] = useState(0)
  const [vehicle, setVehicle] = useState<ScannedVehicle | null>(null)
  const [keyHint, setKeyHint] = useState<string | undefined>('R')
  const [units, setUnits] = useState<Units>('metric')
  const [vibration, setVibration] = useState({ id: 0, pulses: 1 })

  useNuiEvent<SetScannerData>('setScanner', (data) => {
    setActive(data.active)
    setState(data.state ?? 'idle')
    setProgress(data.progress ?? 0)
  })

  useNuiEvent<SetWidgetData>('setWidget', (data) => {
    setVehicle(data.visible ? (data.vehicle ?? null) : null)
    if (data.key !== undefined) setKeyHint(data.key || undefined)
  })

  useNuiEvent<VibrateData>('vibrate', (data) => {
    setVibration((current) => ({ id: current.id + 1, pulses: data.pulses ?? 1 }))
  })

  useNuiEvent<SetSettingsData>('setSettings', (data) => {
    if (data.units === 'metric' || data.units === 'imperial') setUnits(data.units)
  })

  useEffect(() => {
    void fetchNui('nuiReady', { ok: true })
  }, [])

  useEffect(() => {
    if (!import.meta.env.DEV || !isEnvBrowser()) return

    const params = new URLSearchParams(window.location.search)
    const locale = params.get('lang') ?? 'en'
    void import('virtual:dev-translations').then(({ default: languages }) => {
      debugData([
        { action: 'setTranslations', data: { locale, translations: { ...languages.en, ...languages[locale] } } },
        { action: 'setSettings', data: { units: params.get('units') === 'imperial' ? 'imperial' : 'metric' } },
      ])
    })

    document.body.style.background = 'linear-gradient(180deg,#6d7a86 0%,#3d4651 55%,#2a2f36 100%)'

    const preview = params.get('preview') as ScannerState | null
    const page = Number(params.get('page') ?? 0)
    if (preview) {
      if (page) debugData([{ action: 'widgetPage', data: { page } }], 50)
      setActive(true)
      setState(preview)
      setProgress(preview === 'scanning' ? 0.62 : preview === 'locked' ? 1 : 0)
      if (preview === 'locked') setVehicle(DEMO_VEHICLE)
      return
    }

    let raf = 0
    const run = () => {
      setActive(true)
      setState('idle')
      setProgress(0)
      setVehicle(null)
      window.setTimeout(() => setState('target'), 900)
      window.setTimeout(() => {
        setState('scanning')
        const start = performance.now()
        const step = (now: number) => {
          const p = Math.min((now - start) / 1600, 1)
          setProgress(p)
          if (p < 1) raf = requestAnimationFrame(step)
          else {
            setState('locked')
            setVehicle({ ...DEMO_VEHICLE, locked: Math.random() > 0.4 })
          }
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
    <>
      <AnimatePresence>{active && <Crosshair key="crosshair" state={state} progress={progress} vibration={vibration} />}</AnimatePresence>
      <AnimatePresence>
        {vehicle && (
          <VehicleWidget
            key={`${vehicle.plate}-${vehicle.locked}`}
            vehicle={vehicle}
            units={units}
            keyHint={keyHint}
          />
        )}
      </AnimatePresence>
    </>
  )
}
