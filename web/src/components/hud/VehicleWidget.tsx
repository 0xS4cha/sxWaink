import { Armchair, CarFront, Fuel, Gauge, KeyRound, LockOpen, UserRound } from 'lucide-react'
import { AnimatePresence, motion } from 'motion/react'
import { useCallback, useEffect, useState, type ReactNode } from 'react'
import { useNuiEvent } from '../../hooks/useNuiEvent'
import { useScramble } from '../../hooks/useScramble'
import { useTranslation } from '../../hooks/useTranslation'
import type { Units } from '../../types/nui'
import type { ScannedVehicle, WidgetPageData } from '../../types/scanner'
import { formatSpeed } from '../../utils/format'
import { isEnvBrowser } from '../../utils/nui'
import { WainkLogo } from '../WainkLogo'

interface VehicleWidgetProps {
  vehicle: ScannedVehicle
  units: Units
  keyHint?: string
}

type Tone = 'danger' | 'safe' | 'neutral'

const ROW_HEIGHT = 46

const toneColor: Record<Tone, string> = {
  danger: 'text-waink-danger',
  safe: 'text-waink-safe',
  neutral: 'text-white',
}

const toneBar: Record<Tone, string> = {
  danger: 'bg-waink-danger',
  safe: 'bg-waink-safe',
  neutral: 'bg-white',
}

const clamp01 = (n: number | undefined) => Math.min(Math.max(n ?? 0, 0), 1)

function RowShell({ index, last, children }: { index: number; last?: boolean; children: ReactNode }) {
  return (
    <motion.div
      className={`flex items-center justify-between gap-4 ${last ? '' : 'border-b border-white/25'}`}
      style={{ height: ROW_HEIGHT }}
      initial={{ opacity: 0, x: 12 }}
      animate={{ opacity: 1, x: 0 }}
      transition={{ delay: 0.06 + index * 0.06, duration: 0.22 }}
    >
      {children}
    </motion.div>
  )
}

function Label({ children }: { children: ReactNode }) {
  return (
    <span className="shrink-0 text-[21px] font-semibold uppercase leading-none tracking-wide text-white">
      {children}
    </span>
  )
}

function IconBadge({ icon, tone = 'neutral' }: { icon: ReactNode; tone?: Tone }) {
  return (
    <span
      className={`flex size-[26px] shrink-0 items-center justify-center rounded-full bg-[#1d2030] ring-1 ring-white/20 ${toneColor[tone]}`}
    >
      {icon}
    </span>
  )
}

interface TextRowProps {
  label: string
  value: string
  icon?: ReactNode
  tone?: Tone
  index: number
  last?: boolean
}

function TextRow({ label, value, icon, tone = 'neutral', index, last }: TextRowProps) {
  const scrambled = useScramble(value.toUpperCase(), 120 + index * 90)

  return (
    <RowShell index={index} last={last}>
      <Label>{label}</Label>
      <span className="flex min-w-0 items-center gap-2">
        <span className="truncate text-[21px] font-semibold uppercase leading-none tracking-wide text-white">
          {scrambled}
        </span>
        {icon && <IconBadge icon={icon} tone={tone} />}
      </span>
    </RowShell>
  )
}

interface BarRowProps {
  label: string
  value: number
  display?: string
  tone?: Tone
  index: number
  last?: boolean
}

const SEGMENTS = 10

function BarRow({ label, value, display, tone = 'neutral', index, last }: BarRowProps) {
  const v = clamp01(value)
  const filled = Math.round(v * SEGMENTS)
  const text = display ?? `${Math.round(v * 100)}%`

  return (
    <RowShell index={index} last={last}>
      <Label>{label}</Label>
      <span className="flex items-center gap-2.5">
        <span className="flex gap-[3px]">
          {Array.from({ length: SEGMENTS }, (_, i) => (
            <motion.span
              key={i}
              className={`h-[12px] w-[7px] -skew-x-12 ${i < filled ? toneBar[tone] : 'bg-white/20'}`}
              initial={{ opacity: 0, scaleY: 0.3 }}
              animate={{ opacity: 1, scaleY: 1 }}
              transition={{ delay: 0.1 + index * 0.06 + i * 0.025, duration: 0.15 }}
            />
          ))}
        </span>
        <span
          className={`w-[78px] whitespace-nowrap text-right text-[19px] font-semibold uppercase leading-none tracking-wide tabular-nums ${toneColor[tone]}`}
        >
          {text}
        </span>
      </span>
    </RowShell>
  )
}

type T = ReturnType<typeof useTranslation>['t']

interface PageDef {
  id: string
  title: string
  rows: number
  render: () => ReactNode
}

function buildPages(vehicle: ScannedVehicle, units: Units, t: T): PageDef[] {
  const perf = vehicle.performance
  const details = vehicle.details

  const levelTone = (pct: number): Tone => (pct <= 20 ? 'danger' : 'neutral')

  return [
    {
      id: 'info',
      title: t('widget_page_info'),
      rows: 3,
      render: () => (
        <>
          <TextRow
            index={0}
            label={t('widget_owner')}
            value={vehicle.owner ?? t('vehicle_no_owner')}
            icon={<UserRound size={15} strokeWidth={2.6} />}
            tone={vehicle.owner ? 'neutral' : 'danger'}
          />
          <TextRow
            index={1}
            label={t('widget_access')}
            value={vehicle.locked ? t('vehicle_locked') : t('vehicle_unlocked')}
            icon={
              vehicle.locked ? <KeyRound size={15} strokeWidth={2.6} /> : <LockOpen size={15} strokeWidth={2.6} />
            }
            tone={vehicle.locked ? 'danger' : 'safe'}
          />
          <TextRow index={2} label={t('widget_plate')} value={vehicle.plate} last />
        </>
      ),
    },
    {
      id: 'perf',
      title: t('widget_page_perf'),
      rows: 4,
      render: () => (
        <>
          <BarRow
            index={0}
            label={t('widget_speed')}
            value={perf?.speed ?? 0}
            display={perf?.maxSpeed ? formatSpeed(perf.maxSpeed, units, t) : undefined}
          />
          <BarRow index={1} label={t('widget_acceleration')} value={perf?.acceleration ?? 0} />
          <BarRow index={2} label={t('widget_braking')} value={perf?.braking ?? 0} />
          <BarRow index={3} label={t('widget_traction')} value={perf?.traction ?? 0} last />
        </>
      ),
    },
    {
      id: 'details',
      title: t('widget_page_details'),
      rows: 4,
      render: () => (
        <>
          <TextRow
            index={0}
            label={t('widget_class')}
            value={details?.class ?? '—'}
            icon={<CarFront size={15} strokeWidth={2.4} />}
          />
          <TextRow
            index={1}
            label={t('widget_seats')}
            value={details ? String(details.seats) : '—'}
            icon={<Armchair size={15} strokeWidth={2.4} />}
          />
          <BarRow
            index={2}
            label={t('widget_fuel')}
            value={(details?.fuel ?? 0) / 100}
            tone={levelTone(details?.fuel ?? 0)}
          />
          <BarRow
            index={3}
            label={t('widget_engine')}
            value={(details?.engine ?? 0) / 100}
            tone={levelTone(details?.engine ?? 0)}
            last
          />
        </>
      ),
    },
  ]
}

const pageIcons: Record<string, ReactNode> = {
  info: <UserRound size={13} strokeWidth={2.6} />,
  perf: <Gauge size={13} strokeWidth={2.6} />,
  details: <Fuel size={13} strokeWidth={2.6} />,
}

export function VehicleWidget({ vehicle, units, keyHint }: VehicleWidgetProps) {
  const { t } = useTranslation()
  const model = useScramble(vehicle.model.toUpperCase(), 60, 360)
  const pages = buildPages(vehicle, units, t)
  const [[page, direction], setPage] = useState<[number, number]>([0, 1])

  const go = useCallback(
    (target: WidgetPageData['page']) => {
      setPage(([current]) => {
        if (target === 'next') return [(current + 1) % pages.length, 1]
        if (target === 'prev') return [(current - 1 + pages.length) % pages.length, -1]
        const idx = Math.min(Math.max(target, 0), pages.length - 1)
        return [idx, idx >= current ? 1 : -1]
      })
    },
    [pages.length],
  )
  useNuiEvent<WidgetPageData>('widgetPage', ({ page: target }) => go(target))
  useEffect(() => {
    if (!isEnvBrowser()) return
    const onKey = (e: KeyboardEvent) => {
      if (e.key.toLowerCase() === 'r') go('next')
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [go])

  const current = pages[page]

  return (
    <motion.div
      className="font-waink pointer-events-none fixed bottom-[6vh] right-[2.5vw] w-[360px] select-none"
      initial={{ opacity: 0, x: 40 }}
      animate={{ opacity: 1, x: 0 }}
      exit={{ opacity: 0, x: 40 }}
      transition={{ duration: 0.3, ease: [0.22, 1, 0.36, 1] }}
    >
      <div className="mb-1.5 flex items-center justify-end gap-2.5 pr-0.5">
        <AnimatePresence mode="wait" initial={false}>
          <motion.span
            key={current.id}
            className="mr-auto flex items-center gap-1.5 pl-0.5 text-[16px] font-semibold uppercase tracking-[0.14em] text-white [text-shadow:0_1px_3px_rgba(0,0,0,0.7)]"
            initial={{ opacity: 0, y: 4 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -4 }}
            transition={{ duration: 0.15 }}
          >
            {pageIcons[current.id]}
            {current.title}
          </motion.span>
        </AnimatePresence>

        <span className="flex items-center gap-1.5">
          {pages.map((p, i) => (
            <motion.span
              key={p.id}
              className="rounded-full bg-white"
              animate={{
                width: i === page ? 9 : 7,
                height: i === page ? 9 : 7,
                opacity: i === page ? 1 : 0.5,
              }}
              transition={{ duration: 0.2 }}
            />
          ))}
        </span>
        {keyHint && (
          <span className="relative flex h-[24px] min-w-[24px] items-center justify-center rounded-[4px] bg-white px-1 text-[17px] font-bold leading-none text-[#151826] shadow-[0_2px_0_rgba(0,0,0,0.35)]">
            {keyHint}
          </span>
        )}
      </div>

      <div className="overflow-hidden shadow-[0_10px_30px_rgba(0,0,0,0.35)]">
        <div className="relative overflow-hidden bg-[#1b1e2e]/92 px-4 pb-2.5 pt-2">
          <WainkLogo className="absolute -right-2 -top-3 h-[88px] text-white/[0.07]" />
          <div className="relative text-[17px] font-semibold uppercase leading-tight tracking-wide text-white/55">
            {vehicle.brand}
          </div>
          <div className="relative truncate text-[22px] font-bold uppercase leading-tight tracking-wide text-white">
            {model || ' '}
          </div>
        </div>
        <motion.div
          className="relative overflow-hidden bg-gradient-to-b from-[#5b5f6c]/55 to-[#3f4250]/60 backdrop-blur-md"
          initial={false}
          animate={{ height: current.rows * ROW_HEIGHT }}
          transition={{ duration: 0.25, ease: [0.22, 1, 0.36, 1] }}
        >
          <AnimatePresence mode="popLayout" initial={false} custom={direction}>
            <motion.div
              key={current.id}
              className="absolute inset-x-0 top-0 px-4"
              custom={direction}
              variants={{
                enter: (d: number) => ({ x: d * 60, opacity: 0 }),
                center: { x: 0, opacity: 1 },
                exit: (d: number) => ({ x: d * -60, opacity: 0 }),
              }}
              initial="enter"
              animate="center"
              exit="exit"
              transition={{ duration: 0.22, ease: [0.22, 1, 0.36, 1] }}
            >
              {current.render()}
            </motion.div>
          </AnimatePresence>
        </motion.div>
      </div>
    </motion.div>
  )
}
