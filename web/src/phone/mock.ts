import type { ScannedVehicle } from '../types/scanner'

const now = Date.now()

export const mockHistory: ScannedVehicle[] = [
  { brand: 'Imponte', model: "'77 Phoenix", plate: '46EEK572', owner: 'Lucas Martin', locked: true, scannedAt: now - 40_000 },
  { brand: 'Pegassi', model: 'Zentorno', plate: '82LSP019', owner: null, locked: false, scannedAt: now - 6 * 60_000 },
  { brand: 'Vapid', model: 'Dominator', plate: '13VNW884', owner: 'Inès Dubois', locked: false, scannedAt: now - 22 * 60_000 },
  { brand: 'Bravado', model: 'Buffalo STX', plate: '07BRV331', owner: 'Hugo Leroy', locked: true, scannedAt: now - 2 * 3600_000 },
]
