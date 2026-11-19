import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import '../index.css'
import { isEnvBrowser } from '../utils/nui'
import { PhoneApp } from './PhoneApp'

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    {isEnvBrowser() ? (
      <div className="flex h-full w-full items-center justify-center bg-[#2a2d36]">
        <div className="h-[844px] max-h-[96vh] w-[390px] overflow-hidden rounded-[48px] border-[10px] border-black shadow-2xl">
          <PhoneApp />
        </div>
      </div>
    ) : (
      <PhoneApp />
    )}
  </StrictMode>,
)
