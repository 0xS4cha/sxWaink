import type { Units } from '../types/nui'

type Translate = (key: string, replacements?: Record<string, string | number>) => string

const MS_TO_KMH = 3.6
const MS_TO_MPH = 2.236936

export function formatSpeed(metersPerSecond: number, units: Units, t: Translate): string {
  const value = Math.round(metersPerSecond * (units === 'imperial' ? MS_TO_MPH : MS_TO_KMH))
  return `${value} ${t(units === 'imperial' ? 'unit_speed_imperial' : 'unit_speed_metric')}`
}
