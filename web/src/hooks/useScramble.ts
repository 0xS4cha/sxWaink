import { useEffect, useState } from 'react'

const GLYPHS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789#$%&@'

export function useScramble(text: string, delay = 0, duration = 420): string {
  const [output, setOutput] = useState('')

  useEffect(() => {
    let frame = 0
    let start: number | null = null

    const tick = (now: number) => {
      if (start === null) start = now
      const elapsed = now - start - delay

      if (elapsed < 0) {
        setOutput('')
        frame = requestAnimationFrame(tick)
        return
      }

      const revealed = Math.floor((Math.min(elapsed / duration, 1)) * text.length)
      let next = text.slice(0, revealed)

      for (let i = revealed; i < text.length; i++) {
        next += text[i] === ' ' ? ' ' : GLYPHS[Math.floor(Math.random() * GLYPHS.length)]
      }

      setOutput(next)

      if (revealed < text.length) {
        frame = requestAnimationFrame(tick)
      }
    }

    frame = requestAnimationFrame(tick)
    return () => cancelAnimationFrame(frame)
  }, [text, delay, duration])

  return output
}
