export interface SetLocaleData {
  locale: string
}

export type PhraseDictionary = Record<string, string>

export interface SetTranslationsData {
  locale: string
  translations: PhraseDictionary
}

export type Units = 'metric' | 'imperial'

export interface SetSettingsData {
  units: Units
}

export interface NuiMessage<T = unknown> {
  action: string
  data: T
}

export interface NuiCallbackResponse<T = unknown> {
  ok: boolean
  data?: T
  error?: string
}
