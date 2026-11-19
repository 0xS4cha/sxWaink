interface WainkLogoProps {
  className?: string
}

export function WainkLogo({ className }: WainkLogoProps) {
  return (
    <svg viewBox="0 0 100 80" className={className} fill="currentColor" aria-hidden>
      <path d="M2 4 H24 L38 46 L30 70 Z" />
      <path d="M98 4 H76 L62 46 L70 70 Z" />
      <path d="M33 4 H67 L50 56 Z" fillOpacity={0.55} />
      <path d="M8 76 H92 V80 H8 Z" fillOpacity={0.35} />
    </svg>
  )
}
