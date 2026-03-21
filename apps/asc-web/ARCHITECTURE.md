# ASC Web Apps — Architecture Guide

Two web apps + shared layer + Node.js server, all served from one process.

## Directory Structure

```
apps/asc-web/
├── server.js                    # Node.js HTTP server (port 8420)
├── command-center/              # Interactive manager UI
│   ├── index.html               # Sidebar + content + modals
│   ├── css/                     # base, components, layout, theme, utilities
│   └── js/
│       ├── main.js              # Entry: wires theme, nav, DataProvider
│       └── presentation/
│           ├── navigation.js    # Page routing (pageTitles, renderers, loaders)
│           ├── state.js         # Shared mutable state
│           ├── auth.js          # Auth status display
│           ├── helpers.js       # escapeHTML, appColors, etc.
│           ├── toast.js         # Toast notifications
│           ├── theme.js         # Light/dark toggle
│           ├── modal.js         # Modal open/close
│           ├── mode-indicator.js # CLI/mock mode badge
│           └── pages/           # One file per page (apps.js, builds.js, iris.js, ...)
├── console/                     # CLI reference & learning tool
│   ├── index.html               # Sidebar + terminal + search overlay
│   ├── css/                     # base, components, layout, theme
│   └── js/
│       ├── main.js              # Entry: wires nav, terminal, palette, theme
│       └── presentation/
│           ├── nav-data.js      # ★ Source of truth for features & commands
│           ├── navigation.js    # Sidebar rendering + page routing
│           ├── palette.js       # Cmd+K search overlay
│           ├── terminal.js      # Embedded terminal panel
│           ├── icons.js         # SVG icon library
│           ├── theme.js         # Light/dark toggle
│           ├── state.js         # Shared mutable state
│           ├── helpers.js       # Utilities
│           └── pages/
│               ├── dashboard.js # Stats + quick actions
│               └── feature.js   # Auto-renders any feature from nav-data
└── shared/                      # Code shared between both apps
    ├── infrastructure/
    │   ├── data-provider.js     # ★ CLI/mock data abstraction
    │   └── mock-data.js         # ★ Static demo data
    ├── domain/
    │   ├── affordances.js       # ★ CAEOAS affordance generators
    │   ├── enrichers.js         # Injects affordances into mock data
    │   └── version-state.js     # Semantic booleans for version states
    └── static/                  # Logos, favicons
```

## The Two Apps

### Console (`/console`)

A CLI reference tool. Shows all `asc` commands organized by feature, with a terminal panel to run them.

**Key concept:** Everything is driven by `nav-data.js`. The `feature.js` page renderer auto-generates command pages from the NAV structure — no per-feature page files needed.

- **Sidebar:** Built from `nav-data.js` groups/items
- **Search (Cmd+K):** Indexes all features + commands from `nav-data.js`
- **Feature pages:** Show entry commands, workflow commands, and flow breadcrumbs
- **Terminal:** Sends commands via DataProvider → server → `asc` CLI

### Command Center (`/command-center`)

An interactive manager. Each page has its own renderer with tables, cards, modals, and action buttons.

**Key concept:** Each page is a separate file in `pages/` with `render*()` and `load*()` exports. Navigation is wired in `navigation.js`.

- **Sidebar:** Hardcoded in `index.html` with `data-page` attributes
- **Pages:** Custom UI per resource (apps grid, version table, builds list, etc.)
- **Data:** Loaded via DataProvider on page navigation
- **Actions:** Affordance buttons call `runAffordance(cmd)` → toast + terminal

## Data Flow

```
User clicks / types command
        │
        ▼
  DataProvider.fetch('apps list')
        │
        ├─ CLI mode ──► POST /api/run { command: "asc apps list" }
        │                    │
        │                    ▼
        │              server.js executes `asc apps list`
        │                    │
        │                    ▼
        │              Returns { stdout, stderr, exit_code }
        │
        └─ Mock mode ─► Routes to MockDataProvider
                             │
                             ▼
                        Enriches with affordances
                             │
                             ▼
                        Returns { data: [...] }
```

## How to Add a New Feature

### Step 1: Console app — add to `nav-data.js`

This is the only file you need for the console app. Add an item to the appropriate group:

```javascript
// console/js/presentation/nav-data.js
{ group: 'App Management', items: [
    // ... existing items ...
    { id: 'myfeature', label: 'My Feature', icon: 'star',
      entry: ['my-feature list'],                          // direct commands
      workflow: ['my-feature create', 'my-feature delete'], // affordance commands
      flow: ['apps list', 'my-feature list --app-id'],      // resource path
    },
]}
```

That's it — the console sidebar, search palette, and feature page all auto-update.

**Available icons:** See `console/js/presentation/icons.js` for the full set (grid, box, layers, globe, image, play, info, scissors, package, send, star, check-circle, shopping-cart, repeat, tag, bar-chart, shield, cloud, trophy, activity, camera, map, key, users, puzzle, zap).

### Step 2: Command Center — create a page

**a) Create the page file:**

```javascript
// command-center/js/presentation/pages/my-feature.js
import { DataProvider } from '../../../../shared/infrastructure/data-provider.js';
import { escapeHTML } from '../helpers.js';

export function renderMyFeature() {
  return `
    <div id="myFeatureContent">
      <div class="empty-state"><div class="spinner" style="margin:24px auto"></div></div>
    </div>`;
}

export async function loadMyFeature() {
  const result = await DataProvider.fetch('my-feature list --app-id APP_ID');
  if (result?.data) {
    document.getElementById('myFeatureContent').innerHTML = `
      <table class="data-table">
        <thead><tr><th>ID</th><th>Name</th></tr></thead>
        <tbody>${result.data.map(item => `
          <tr><td class="cell-mono">${item.id}</td><td>${escapeHTML(item.name)}</td></tr>
        `).join('')}</tbody>
      </table>`;
  }
}
```

**b) Wire into navigation.js:**

```javascript
// command-center/js/presentation/navigation.js

// 1. Import
import { renderMyFeature, loadMyFeature } from './pages/my-feature.js';

// 2. Add to pageTitles
const pageTitles = {
  // ... existing ...
  myfeature: 'My Feature',
};

// 3. Add to renderers
const renderers = {
  // ... existing ...
  myfeature: renderMyFeature,
};

// 4. Add to loaders (if page needs async data)
const loaders = {
  // ... existing ...
  myfeature: loadMyFeature,
};
```

**c) Add sidebar button in index.html:**

```html
<!-- command-center/index.html — inside the appropriate nav-section -->
<button class="nav-item" data-page="myfeature">
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"
       stroke-linecap="round" stroke-linejoin="round">
    <!-- SVG path for icon -->
  </svg>
  My Feature
</button>
```

### Step 3: Mock data (for offline/demo)

```javascript
// shared/infrastructure/mock-data.js
myFeature: {
  'APP_ID': {
    data: [
      { id: 'mf-1', appId: 'APP_ID', name: 'Example', status: 'active' },
    ],
  },
},
```

### Step 4: Data provider routing (for mock mode)

```javascript
// shared/infrastructure/data-provider.js — inside _fetchMock()
if (cmd === 'my-feature' && sub === 'list') {
  const appId = args['--app-id'];
  const items = M.myFeature?.[appId];
  if (items) return enrichList(items, myFeatureAffordances);
}
```

### Step 5: Affordances (CAEOAS)

```javascript
// shared/domain/affordances.js
export function myFeatureAffordances(item) {
  return {
    getDetail: `asc my-feature get --id ${item.id}`,
    delete: `asc my-feature delete --id ${item.id}`,
    listSiblings: `asc my-feature list --app-id ${item.appId}`,
  };
}
```

## Server

`server.js` is a Node.js HTTP server embedded in the `asc` binary at build time via the `EmbedServerJS` SPM plugin.

```
Port: 8420 (--port flag)
Routes:
  /                    → command-center/index.html
  /command-center/*    → command-center static files
  /console/*           → console static files
  /shared/*            → shared static files
  /api/run             → POST { command: "asc ..." } → executes asc CLI
```

Security: commands are validated (blocks shell metacharacters `;&|$\``), paths are checked for traversal.

## CSS Architecture

Both apps share a similar CSS structure:

| File | Purpose |
|------|---------|
| `base.css` | Reset, variables, typography |
| `theme.css` | Light/dark theme variables |
| `layout.css` | Sidebar, content area, grid |
| `components.css` | Cards, tables, buttons, badges, modals, toast |
| `utilities.css` | Helper classes (command-center only) |

Key CSS classes:
- `.card` — bordered container
- `.data-table` — striped table
- `.btn .btn-primary .btn-secondary` — buttons
- `.platform-badge` — small tag
- `.cell-mono` — monospace text
- `.empty-state` — centered placeholder
- `.spinner` — loading indicator
- `.grid-3` — 3-column grid

## Checklist: Adding a Feature End-to-End

- [ ] `console/js/presentation/nav-data.js` — add item to NAV array
- [ ] `shared/infrastructure/mock-data.js` — add mock data
- [ ] `shared/domain/affordances.js` — add affordance generator
- [ ] `shared/infrastructure/data-provider.js` — add mock routing in `_fetchMock()`
- [ ] `command-center/js/presentation/pages/<feature>.js` — create page
- [ ] `command-center/js/presentation/navigation.js` — register page
- [ ] `command-center/index.html` — add sidebar nav button
