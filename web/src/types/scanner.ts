export type ScannerState = 'idle' | 'target' | 'blocked' | 'scanning' | 'locked'

export interface SetScannerData {
  active: boolean
  state?: ScannerState
  progress?: number
}

export interface VibrateData {
  pulses?: number
}
