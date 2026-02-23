// Device registry — loaded from devices.json at the editor root.
// DEVICES_MAP  { [frameName]: { category, model, displayType, outputWidth, outputHeight, screenInsetX, screenInsetY, path } }
// DEVICES_LIST array form for the device dropdown
// DISPLAY_TYPE_SIZES { [displayType]: { width, height } } — canonical App Store slot dimensions

let DEVICES_MAP = {};
let DEVICES_LIST = [];

// Canonical App Store screenshot dimensions per display type slot.
const DISPLAY_TYPE_SIZES = {
  "APP_IPHONE_67":          { width: 1290, height: 2796 },
  "APP_IPHONE_65":          { width: 1242, height: 2688 },
  "APP_IPHONE_61":          { width: 1179, height: 2556 },
  "APP_IPHONE_58":          { width: 1125, height: 2436 },
  "APP_IPHONE_55":          { width: 1242, height: 2208 },
  "APP_IPHONE_47":          { width:  750, height: 1334 },
  "APP_IPHONE_40":          { width:  640, height: 1136 },
  "APP_IPAD_PRO_3GEN_129":  { width: 2048, height: 2732 },
  "APP_IPAD_PRO_3GEN_11":   { width: 1668, height: 2388 },
  "APP_IPAD_PRO_129":       { width: 2048, height: 2732 },
  "APP_IPAD_105":           { width: 1668, height: 2224 },
  "APP_IPAD_97":            { width: 1536, height: 2048 },
  "APP_DESKTOP":            { width: 2880, height: 1800 },
  "APP_WATCH_ULTRA":        { width:  410, height:  502 },
  "APP_WATCH_SERIES_10":    { width:  410, height:  502 },
  "APP_WATCH_SERIES_7":     { width:  396, height:  484 },
  "APP_WATCH_SERIES_4":     { width:  368, height:  448 },
  "IMESSAGE_APP_IPHONE_67": { width: 1290, height: 2796 },
  "IMESSAGE_APP_IPHONE_65": { width: 1242, height: 2688 },
  "IMESSAGE_APP_IPHONE_61": { width: 1179, height: 2556 },
};

async function initDevices() {
  const resp = await fetch('devices.json');
  DEVICES_MAP = await resp.json();
  DEVICES_LIST = Object.entries(DEVICES_MAP).map(([name, d]) => ({ name, ...d }));
}

// Build dropdown grouped by: Category → Model → Variant
function populateDeviceDropdown(selectEl) {
  const categoryOrder = ['iPhone', 'iPad', 'Mac', 'Watch'];

  // Group: category → model → [device]
  const grouped = {};
  for (const d of DEVICES_LIST) {
    const cat = d.category || 'Other';
    const model = d.model || d.name;
    if (!grouped[cat]) grouped[cat] = {};
    if (!grouped[cat][model]) grouped[cat][model] = [];
    grouped[cat][model].push(d);
  }

  // Preserve insertion order for models within each category
  for (const cat of categoryOrder) {
    if (!grouped[cat]) continue;
    const models = Object.keys(grouped[cat]);
    for (const model of models) {
      const devices = grouped[cat][model];
      const group = document.createElement('optgroup');
      group.label = model;
      for (const d of devices) {
        const opt = document.createElement('option');
        opt.value = d.name;
        // Show just the variant part (strip the model prefix from the display name)
        let label = d.name;
        if (label.startsWith(model + ' - ')) label = label.slice(model.length + 3);
        else if (label.startsWith(model + ' ')) label = label.slice(model.length + 1);
        opt.textContent = label || d.name;
        group.appendChild(opt);
      }
      selectEl.appendChild(group);
    }
  }
}
