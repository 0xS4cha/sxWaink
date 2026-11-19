import { ChevronLeft, ChevronRight, KeyRound, LockOpen, Radar, Trash2, UserRound } from 'lucide-react'
import { AnimatePresence, motion } from 'motion/react'
import { useCallback, useEffect, useMemo, useState } from 'react'
import { WainkLogo } from '../components/WainkLogo'
import { useNuiEvent } from '../hooks/useNuiEvent'
import { setGlobalTranslations, useTranslation } from '../hooks/useTranslation'
import type { PhoneInitialState, ScannedVehicle, SetPhoneStateData } from '../types/scanner'
import { debugData } from '../utils/debugData'
import { fetchNui } from '../utils/fetchNui'
import { formatRelativeTime } from '../utils/format'
import { isEnvBrowser } from '../utils/nui'
import { mockHistory } from './mock'

type T = ReturnType<typeof useTranslation>['t']

const DEFAULT_HISTORY_LIMIT = 30

function LockBadge({ locked, size = 'sm' }: { locked: boolean; size?: 'sm' | 'lg' }) {
  const Icon = locked ? KeyRound : LockOpen
  const dim = size === 'lg' ? 'size-11' : 'size-8'
  return (
    <span
      className={`flex ${dim} shrink-0 items-center justify-center rounded-full ring-1 ${
        locked
          ? 'bg-waink-danger/12 text-waink-danger ring-waink-danger/35'
          : 'bg-waink-safe/10 text-waink-safe ring-waink-safe/30'
      }`}
    >
      <Icon size={size === 'lg' ? 20 : 15} strokeWidth={2.4} />
    </span>
  )
}

function ScanButton({ active, onToggle, t }: { active: boolean; onToggle: () => void; t: T }) {
  return (
    <div className="flex flex-col items-center">
      <button
        type="button"
        onClick={onToggle}
        className="group relative flex size-[156px] items-center justify-center rounded-full outline-none"
      >
        {active &&
          [0, 1, 2].map((i) => (
            <motion.span
              key={i}
              className="absolute inset-0 rounded-full border border-waink-accent/50"
              initial={{ scale: 0.7, opacity: 0.8 }}
              animate={{ scale: 1.35, opacity: 0 }}
              transition={{ duration: 2.2, repeat: Infinity, delay: i * 0.73, ease: 'easeOut' }}
            />
          ))}
        <span
          className={`absolute inset-0 rounded-full border transition-colors duration-300 ${
            active ? 'border-waink-accent/60' : 'border-white/10'
          }`}
        />
        <motion.span
          className={`relative flex size-[118px] flex-col items-center justify-center rounded-full transition-colors duration-300 ${
            active
              ? 'bg-waink-accent text-[#08131a] shadow-[0_0_40px_rgba(62,230,255,0.45)]'
              : 'bg-white/[0.06] text-white ring-1 ring-white/10 group-hover:bg-white/[0.09]'
          }`}
          whileTap={{ scale: 0.94 }}
        >
          <Radar size={34} strokeWidth={2} className={active ? 'animate-[spin_3s_linear_infinite]' : ''} />
          <span className="mt-1.5 font-waink text-[15px] font-bold uppercase tracking-[0.14em]">
            {active ? t('scanner_toggle_on') : t('scanner_toggle_off')}
          </span>
        </motion.span>
      </button>

      <div className="mt-5 font-waink text-[22px] font-bold uppercase tracking-wide text-white">
        {active ? t('scanner_stop') : t('scanner_start')}
      </div>
      <p className="mt-1 max-w-[250px] text-center text-[13px] leading-snug text-white/45">{t('scanner_hint')}</p>
    </div>
  )
}

function HistoryItem({ vehicle, onOpen, t }: { vehicle: ScannedVehicle; onOpen: () => void; t: T }) {
  return (
    <button
      type="button"
      onClick={onOpen}
      className="flex w-full items-center gap-3 rounded-2xl bg-white/[0.04] p-3 text-left ring-1 ring-white/[0.06] transition-colors hover:bg-white/[0.07]"
    >
      <LockBadge locked={vehicle.locked} />
      <div className="min-w-0 flex-1">
        <div className="flex items-baseline gap-1.5">
          <span className="truncate font-waink text-[18px] font-bold uppercase leading-tight text-white">
            {vehicle.model}
          </span>
          <span className="truncate font-waink text-[14px] font-medium uppercase text-white/40">{vehicle.brand}</span>
        </div>
        <div className="mt-0.5 flex items-center gap-1.5 text-[12.5px] text-white/50">
          <UserRound size={12} />
          <span className={`truncate ${vehicle.owner ? '' : 'text-waink-danger/80'}`}>
            {vehicle.owner ?? t('vehicle_no_owner')}
          </span>
          <span className="text-white/20">•</span>
          <span className="shrink-0">{formatRelativeTime(vehicle.scannedAt, t)}</span>
        </div>
      </div>
      <span className="shrink-0 rounded-md bg-white/90 px-1.5 py-0.5 font-waink text-[13px] font-bold tracking-wider text-[#151826]">
        {vehicle.plate}
      </span>
      <ChevronRight size={16} className="shrink-0 text-white/25" />
    </button>
  )
}

function VehicleDetail({ vehicle, onBack, t }: { vehicle: ScannedVehicle; onBack: () => void; t: T }) {
  const rows: { label: string; value: string; tone?: string }[] = [
    { label: t('widget_owner'), value: vehicle.owner ?? t('vehicle_no_owner'), tone: vehicle.owner ? '' : 'text-waink-danger' },
    {
      label: t('widget_access'),
      value: vehicle.locked ? t('vehicle_locked') : t('vehicle_unlocked'),
      tone: vehicle.locked ? 'text-waink-danger' : 'text-waink-safe',
    },
    { label: t('widget_plate'), value: vehicle.plate },
    { label: t('detail_scanned_at'), value: formatRelativeTime(vehicle.scannedAt, t) },
  ]

  return (
    <motion.div
      className="absolute inset-0 z-10 flex flex-col bg-[#0c0e16] px-5 pt-14"
      initial={{ x: '100%' }}
      animate={{ x: 0 }}
      exit={{ x: '100%' }}
      transition={{ duration: 0.3, ease: [0.22, 1, 0.36, 1] }}
    >
      <button
        type="button"
        onClick={onBack}
        className="-ml-1.5 flex items-center gap-0.5 self-start text-[15px] font-medium text-waink-accent"
      >
        <ChevronLeft size={20} />
        {t('detail_back')}
      </button>

      <div className="mt-4 font-waink text-[13px] font-semibold uppercase tracking-[0.18em] text-white/40">
        {t('detail_title')}
      </div>

      <div className="relative mt-3 overflow-hidden rounded-2xl bg-[#1b1e2e] p-5">
        <WainkLogo className="absolute -right-4 -top-4 h-28 text-white/[0.06]" />
        <div className="relative font-waink text-[17px] font-semibold uppercase text-white/50">{vehicle.brand}</div>
        <div className="relative font-waink text-[32px] font-bold uppercase leading-none text-white">
          {vehicle.model}
        </div>
        <div className="relative mt-4 flex items-center justify-between">
          <span className="rounded-md bg-white px-2 py-1 font-waink text-[18px] font-bold tracking-[0.12em] text-[#151826]">
            {vehicle.plate}
          </span>
          <LockBadge locked={vehicle.locked} size="lg" />
        </div>
      </div>

      <div className="mt-4 rounded-2xl bg-white/[0.04] px-4 ring-1 ring-white/[0.06]">
        {rows.map((row, i) => (
          <div
            key={row.label}
            className={`flex items-center justify-between py-3.5 ${i < rows.length - 1 ? 'border-b border-white/[0.07]' : ''}`}
          >
            <span className="font-waink text-[17px] font-semibold uppercase tracking-wide text-white/55">{row.label}</span>
            <span className={`font-waink text-[17px] font-bold uppercase tracking-wide text-white ${row.tone ?? ''}`}>
              {row.value}
            </span>
          </div>
        ))}
      </div>
    </motion.div>
  )
}

export function PhoneApp() {
  const { t } = useTranslation()
  const [active, setActive] = useState(false)
  const [history, setHistory] = useState<ScannedVehicle[]>([])
  const [selected, setSelected] = useState<ScannedVehicle | null>(null)
  const [historyLimit, setHistoryLimit] = useState(DEFAULT_HISTORY_LIMIT)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    void fetchNui<PhoneInitialState>('getState', {}, { scannerActive: false, history: mockHistory })
      .then((data) => {
        setActive(Boolean(data?.scannerActive))
        setHistory(data?.history ?? [])
        if (data?.historyLimit) setHistoryLimit(data.historyLimit)
        if (data?.locale && data.translations) setGlobalTranslations(data.locale, data.translations)
      })
      .catch(() => {})

    if (import.meta.env.DEV && isEnvBrowser()) {
      const locale = new URLSearchParams(window.location.search).get('lang') ?? 'en'
      void import('virtual:dev-translations').then(({ default: languages }) => {
        debugData([{ action: 'setTranslations', data: { locale, translations: { ...languages.en, ...languages[locale] } } }])
      })
    }
  }, [])

  useNuiEvent<SetPhoneStateData>('setPhoneState', (data) => {
    if (data.scannerActive !== undefined) setActive(data.scannerActive)
    if (data.history) setHistory(data.history)
  })

  useNuiEvent<ScannedVehicle>('addScan', (vehicle) => {
    setHistory((prev) => [{ ...vehicle, scannedAt: vehicle.scannedAt ?? Date.now() }, ...prev].slice(0, historyLimit))
  })

  const toggle = useCallback(() => {
    const next = !active
    setActive(next)
    setError(null)
    void fetchNui<{ active: boolean }>('toggleScanner', { active: next }, { active: next })
      .then((res) => setActive(Boolean(res?.active)))
      .catch((err: unknown) => {
        setActive(!next)
        setError(err instanceof Error && /^[a-z_]+$/.test(err.message) ? `error_${err.message}` : 'error_unknown')
      })
  }, [active])

  useEffect(() => {
    if (!error) return
    const timeout = window.setTimeout(() => setError(null), 4000)
    return () => window.clearTimeout(timeout)
  }, [error])

  const clear = useCallback(() => {
    setHistory([])
    void fetchNui('clearHistory')
  }, [])

  const stats = useMemo(
    () => [
      { label: t('stat_scans'), value: history.length },
      { label: t('stat_locked'), value: history.filter((v) => v.locked).length },
      { label: t('stat_owned'), value: history.filter((v) => v.owner).length },
    ],
    [history, t],
  )

  return (
    <div className="relative flex h-full w-full flex-col overflow-hidden bg-[#0c0e16] text-white">
      <div
        className={`pointer-events-none absolute -top-24 left-1/2 size-[420px] -translate-x-1/2 rounded-full blur-3xl transition-opacity duration-700 ${
          active ? 'opacity-100' : 'opacity-40'
        }`}
        style={{ background: 'radial-gradient(circle, rgba(62,230,255,0.18) 0%, transparent 65%)' }}
      />

      <div className="relative flex min-h-0 flex-1 flex-col overflow-y-auto px-5 pb-8 pt-14">
        <header className="flex items-center justify-between">
          <div className="flex items-center gap-2.5">
            <span className="flex size-10 items-center justify-center rounded-xl bg-[#1b1e2e] ring-1 ring-white/10">
              <WainkLogo className="h-5 text-white" />
            </span>
            <div>
              <div className="font-waink text-[24px] font-bold uppercase leading-none tracking-wide">Waink</div>
              <div className="text-[12px] text-white/45">{t('app_subtitle')}</div>
            </div>
          </div>
          <span
            className={`flex items-center gap-1.5 rounded-full px-2.5 py-1 font-waink text-[13px] font-semibold uppercase tracking-wide ring-1 ${
              active ? 'bg-waink-accent/10 text-waink-accent ring-waink-accent/30' : 'bg-white/5 text-white/45 ring-white/10'
            }`}
          >
            <span className={`size-1.5 rounded-full ${active ? 'animate-pulse bg-waink-accent' : 'bg-white/35'}`} />
            {active ? t('scanner_on') : t('scanner_off')}
          </span>
        </header>

        <div className="mt-10">
          <ScanButton active={active} onToggle={toggle} t={t} />
          <AnimatePresence>
            {error && (
              <motion.p
                key={error}
                className="mx-auto mt-3 max-w-[260px] rounded-xl bg-waink-danger/10 px-3 py-2 text-center text-[13px] leading-snug text-waink-danger ring-1 ring-waink-danger/30"
                initial={{ opacity: 0, y: -4 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0 }}
              >
                {t(error)}
              </motion.p>
            )}
          </AnimatePresence>
        </div>
        <div className="mt-9 grid grid-cols-3 gap-2">
          {stats.map((s) => (
            <div key={s.label} className="rounded-2xl bg-white/[0.04] px-3 py-2.5 ring-1 ring-white/[0.06]">
              <div className="font-waink text-[26px] font-bold leading-none">{s.value}</div>
              <div className="mt-1 font-waink text-[12px] font-semibold uppercase tracking-wider text-white/40">
                {s.label}
              </div>
            </div>
          ))}
        </div>
        <div className="mt-7 flex items-center justify-between">
          <h2 className="font-waink text-[14px] font-semibold uppercase tracking-[0.18em] text-white/45">
            {t('history_title')}
          </h2>
          {history.length > 0 && (
            <button
              type="button"
              onClick={clear}
              className="flex items-center gap-1 text-[13px] text-white/40 transition-colors hover:text-waink-danger"
            >
              <Trash2 size={13} />
              {t('history_clear')}
            </button>
          )}
        </div>

        <div className="mt-3 flex flex-col gap-2">
          <AnimatePresence initial={false}>
            {history.map((v) => (
              <motion.div
                key={`${v.plate}-${v.scannedAt}`}
                layout
                initial={{ opacity: 0, y: -8 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, x: -20 }}
              >
                <HistoryItem vehicle={v} onOpen={() => setSelected(v)} t={t} />
              </motion.div>
            ))}
          </AnimatePresence>
          {history.length === 0 && (
            <div className="rounded-2xl border border-dashed border-white/10 px-4 py-8 text-center text-[13px] text-white/35">
              {t('history_empty')}
            </div>
          )}
        </div>
      </div>

      <AnimatePresence>
        {selected && <VehicleDetail key="detail" vehicle={selected} onBack={() => setSelected(null)} t={t} />}
      </AnimatePresence>
    </div>
  )
}
