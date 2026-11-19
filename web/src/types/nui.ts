export interface NuiMessage<T = unknown> {
  action: string
  data: T
}

export interface NuiCallbackResponse<T = unknown> {
  ok: boolean
  data?: T
  error?: string
}
