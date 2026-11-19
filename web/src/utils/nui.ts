export function isEnvBrowser(): boolean {
  const w = window as Window & { invokeNative?: unknown }
  return !w.invokeNative && window.parent === window
}

export function getResourceName(): string {
  if (isEnvBrowser()) {
    return 'sxWaink'
  }

  const injected = (window as Window & { resourceName?: string }).resourceName
  if (injected) {
    return injected
  }

  return (window as Window & { GetParentResourceName?: () => string }).GetParentResourceName?.() ?? 'sxWaink'
}
