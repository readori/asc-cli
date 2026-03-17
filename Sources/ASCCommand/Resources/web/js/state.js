// Global app state + routing

export const state = {
  page: 'releases',
  appId: null,
  appName: '',
  bundleId: '',
  platform: 'IOS',
  apps: [],
};

const listeners = new Set();

export function onNavigate(fn) { listeners.add(fn); }

export function navigate(page) {
  state.page = page;
  listeners.forEach(fn => fn(page));
}

export function selectApp(app) {
  state.appId = app.id;
  state.appName = app.name || app.appName || 'App';
  state.bundleId = app.bundleId || '';
  listeners.forEach(fn => fn(state.page));
}
