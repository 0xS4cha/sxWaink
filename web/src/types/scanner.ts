export type ScannerState = 'idle' | 'target' | 'blocked' | 'scanning' | 'locked'

export interface VehiclePerformance {
  speed: number
  acceleration: number
  braking: number
  traction: number
  maxSpeed?: number
}

export interface VehicleDetails {
  class: string
  seats: number
  fuel: number
  engine: number
}

export interface ScannedVehicle {
  brand: string
  model: string
  plate: string
  owner: string | null
  locked: boolean
  performance?: VehiclePerformance
  details?: VehicleDetails
}

export interface SetScannerData {
  active: boolean
  state?: ScannerState
  progress?: number
}

export interface SetWidgetData {
  visible: boolean
  vehicle?: ScannedVehicle | null
  key?: string
}

export interface WidgetPageData {
  page: 'next' | 'prev' | number
}
