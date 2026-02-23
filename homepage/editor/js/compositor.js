// Canvas compositor — draws background + bezel + screenshot + text
// Adapts flood-fill masking from bezel-compositor.html

const FRAME_BASE = 'frames/';

// Cache frame images and masks so drag re-composites are fast
const frameImageCache = new Map();
const maskCache = new Map();

function loadImage(src) {
  return new Promise((resolve, reject) => {
    const img = new Image();
    img.onload = () => resolve(img);
    img.onerror = () => reject(new Error('Failed to load: ' + src));
    img.src = src;
  });
}

async function getFrameImage(deviceName) {
  if (frameImageCache.has(deviceName)) return frameImageCache.get(deviceName);
  const device = DEVICES_MAP[deviceName];
  // Use device.path (BezelKit nested path) if available, else fall back to flat filename
  const src = device && device.path
    ? encodeURI(FRAME_BASE + device.path)
    : encodeURIComponent(deviceName) + '.png';
  const img = await loadImage(src);
  frameImageCache.set(deviceName, img);
  return img;
}

function getScreenMask(frameImg, deviceName) {
  if (maskCache.has(deviceName)) return maskCache.get(deviceName);
  const mask = buildScreenMask(frameImg);
  maskCache.set(deviceName, mask);
  return mask;
}

// Flood-fill mask: marks screen area (same algorithm as bezel-compositor.html)
function buildScreenMask(frameImg) {
  const fw = frameImg.width, fh = frameImg.height;
  const off = document.createElement('canvas');
  off.width = fw; off.height = fh;
  const oCtx = off.getContext('2d');
  oCtx.drawImage(frameImg, 0, 0);
  let imgData;
  try { imgData = oCtx.getImageData(0, 0, fw, fh); } catch (e) { return null; }
  const px = imgData.data;
  const total = fw * fh;

  const outer = new Uint8Array(total);
  const queue = new Int32Array(total);
  let head = 0, tail = 0;

  for (let sx = 0; sx < fw; sx++) {
    queue[tail++] = sx;
    queue[tail++] = (fh - 1) * fw + sx;
  }
  for (let sy = 1; sy < fh - 1; sy++) {
    queue[tail++] = sy * fw;
    queue[tail++] = sy * fw + fw - 1;
  }

  while (head < tail) {
    const idx = queue[head++];
    if (outer[idx]) continue;
    const a = px[idx * 4 + 3];
    if (a > 50) continue;
    outer[idx] = 1;
    const ix = idx % fw, iy = (idx - ix) / fw;
    if (ix > 0 && !outer[idx - 1])       queue[tail++] = idx - 1;
    if (ix < fw - 1 && !outer[idx + 1])  queue[tail++] = idx + 1;
    if (iy > 0 && !outer[idx - fw])      queue[tail++] = idx - fw;
    if (iy < fh - 1 && !outer[idx + fw]) queue[tail++] = idx + fw;
  }

  for (let i = 0; i < total; i++) {
    const a = px[i * 4 + 3];
    px[i * 4] = px[i * 4 + 1] = px[i * 4 + 2] = 255;
    if (outer[i]) {
      px[i * 4 + 3] = 0;
    } else if (a > 50) {
      px[i * 4 + 3] = 0;
    } else {
      px[i * 4 + 3] = 255 - a;
    }
  }

  oCtx.putImageData(imgData, 0, 0);
  return off;
}

// Draw gradient background on canvas context
function drawBackground(ctx, w, h, bg) {
  if (bg.type === 'solid') {
    ctx.fillStyle = bg.color || '#1a1a2e';
    ctx.fillRect(0, 0, w, h);
  } else {
    const angleRad = ((bg.angle || 135) * Math.PI) / 180;
    const cx = w / 2, cy = h / 2;
    const len = Math.sqrt(w * w + h * h) / 2;
    const gx1 = cx - Math.cos(angleRad) * len;
    const gy1 = cy - Math.sin(angleRad) * len;
    const gx2 = cx + Math.cos(angleRad) * len;
    const gy2 = cy + Math.sin(angleRad) * len;
    const grad = ctx.createLinearGradient(gx1, gy1, gx2, gy2);
    const colors = bg.colors || ['#1a1a2e', '#0f3460'];
    grad.addColorStop(0, colors[0]);
    grad.addColorStop(1, colors[1]);
    ctx.fillStyle = grad;
    ctx.fillRect(0, 0, w, h);
  }
}

// ─── Two-layer live compositor ────────────────────────────────────────────────
//
// mainCanvas  — background only (never redraws on zoom)
// bezelLayer  — CSS-scaled div containing screenCanvas + frameImg
//               zoom slider only changes CSS transform → GPU, 60 fps, no canvas op
//
// drawBackground(canvas, bg)          — call when bg changes
// updateBezelLayer(layer, ss, zoom)   — call when device/screenshot/zoom changes
// ─────────────────────────────────────────────────────────────────────────────

// Draw background onto a canvas (call when background changes)
function drawBg(canvas, bg) {
  const w = canvas.width, h = canvas.height;
  const ctx = canvas.getContext('2d');
  drawBackground(ctx, w, h, bg || { type: 'gradient', colors: ['#1a1a2e', '#0f3460'], angle: 135 });
}

// Position and show the bezel layer at the right CSS scale.
// Does NOT redraw canvas — call this on zoom slider input.
function applyBezelZoom(bezelLayer, zoom) {
  bezelLayer.style.transform = `scale(${zoom / 100})`;
}

// Update bezel layer content (screenCanvas + frameImg).
// Call when device, screenshot image, or drag offset changes — NOT on zoom.
// outSizeW: full-res canvas width (e.g. 1290) — needed to convert frameOffset
// bezelZoomPct: current zoom slider value (e.g. 75) — needed to invert CSS scale
async function updateBezelLayer(bezelLayer, screenshot, displayW, displayH, outSizeW, bezelZoomPct) {
  const screenCanvas = bezelLayer.querySelector('#screenCanvas');
  const frameImgEl   = bezelLayer.querySelector('#frameImg');
  const deviceName   = screenshot.device || null;
  const device       = deviceName ? DEVICES_MAP[deviceName] : null;
  const sourceImage  = screenshot.sourceImage;

  if (!device || !sourceImage) {
    // No bezel: hide layer, draw screenshot on mainCanvas instead
    bezelLayer.style.display = 'none';
    return;
  }

  bezelLayer.style.display = '';

  let frameImg;
  try {
    frameImg = await getFrameImage(deviceName);
  } catch (e) {
    console.warn('Frame not found:', deviceName, e);
    bezelLayer.style.display = 'none';
    return;
  }

  // Scale frame to fill as much of the display area as possible at zoom=100%
  const scaleF = Math.min(displayW / frameImg.width, displayH / frameImg.height);
  const fw = Math.round(frameImg.width  * scaleF);
  const fh = Math.round(frameImg.height * scaleF);

  // Screen area at this scale
  const screenX = Math.round(device.screenInsetX * scaleF);
  const screenY = Math.round(device.screenInsetY * scaleF);
  const screenW = fw - device.screenInsetX * 2 * scaleF;
  const screenH = fh - device.screenInsetY * 2 * scaleF;

  // Size screenCanvas to the frame dimensions
  screenCanvas.width  = fw;
  screenCanvas.height = fh;
  screenCanvas.style.width  = fw + 'px';
  screenCanvas.style.height = fh + 'px';
  screenCanvas.style.left = '0';
  screenCanvas.style.top  = '0';

  // Draw screenshot clipped to screen rect
  const sCtx = screenCanvas.getContext('2d');
  sCtx.clearRect(0, 0, fw, fh);

  // Apply flood-fill mask for clipping
  const mask = getScreenMask(frameImg, deviceName);
  if (mask) {
    // Draw screenshot into offscreen, apply mask, copy to screenCanvas
    const off = document.createElement('canvas');
    off.width = fw; off.height = fh;
    const oCtx = off.getContext('2d');

    const sw = sourceImage.width, sh = sourceImage.height;
    const imgScale = Math.max(screenW / sw, screenH / sh);
    const scaledW = sw * imgScale, scaledH = sh * imgScale;
    const drawX = screenX + (screenW - scaledW) / 2;
    const drawY = screenY + (screenH - scaledH) / 2;
    oCtx.drawImage(sourceImage, drawX, drawY, scaledW, scaledH);

    // Mask is in frame-native coords; scale it to fw×fh
    const mCanvas = document.createElement('canvas');
    mCanvas.width = fw; mCanvas.height = fh;
    mCanvas.getContext('2d').drawImage(mask, 0, 0, fw, fh);

    oCtx.globalCompositeOperation = 'destination-in';
    oCtx.drawImage(mCanvas, 0, 0);
    sCtx.drawImage(off, 0, 0);
  }

  // Overlay the frame PNG
  frameImgEl.src = frameImg.src;
  frameImgEl.style.width  = fw + 'px';
  frameImgEl.style.height = fh + 'px';
  frameImgEl.style.left = '0';
  frameImgEl.style.top  = '0';

  // Centre the frame group inside the bezel layer (bezelLayer is 100%×100% of
  // canvasWrapper).  frameOffset is stored in full-res output pixels; convert to
  // layer CSS pixels, then invert the CSS zoom so the net screen displacement
  // equals exactly frameOffsetX * displayScale regardless of zoom level.
  const dScale  = displayW / (outSizeW || displayW);  // CSS px per full-res px
  const zScale  = (bezelZoomPct ?? 100) / 100;        // CSS zoom factor
  const offsetX = Math.round((displayW - fw) / 2 + (screenshot.frameOffsetX || 0) * dScale / zScale);
  const offsetY = Math.round((displayH - fh) / 2 + (screenshot.frameOffsetY || 0) * dScale / zScale);
  screenCanvas.style.transform = `translate(${offsetX}px, ${offsetY}px)`;
  frameImgEl.style.transform   = `translate(${offsetX}px, ${offsetY}px)`;
}

// ─── Legacy single-canvas export path ─────────────────────────────────────────
// Used only for ZIP export (full App Store resolution, texts baked in)

async function compositeScreenshot(canvasEl, screenshot, outSize, bezelZoom = 75) {
  const { width: cw, height: ch } = outSize;
  const work = document.createElement('canvas');
  work.width = cw; work.height = ch;
  const ctx = work.getContext('2d');

  drawBackground(ctx, cw, ch, screenshot.background || { type: 'gradient', colors: ['#1a1a2e', '#0f3460'], angle: 135 });

  const deviceName = screenshot.device || null;
  const device = deviceName ? DEVICES_MAP[deviceName] : null;
  const sourceImage = screenshot.sourceImage;

  if (device && sourceImage) {
    let frameImg;
    try { frameImg = await getFrameImage(deviceName); }
    catch (e) { console.warn('Frame not found:', deviceName, e); }

    if (frameImg) {
      const scaleF = Math.min(cw / frameImg.width, ch / frameImg.height) * (bezelZoom / 100);
      const fw = frameImg.width * scaleF, fh = frameImg.height * scaleF;
      const fx = (cw - fw) / 2 + (screenshot.frameOffsetX || 0);
      const fy = (ch - fh) / 2 + (screenshot.frameOffsetY || 0);
      const screenX = fx + device.screenInsetX * scaleF;
      const screenY = fy + device.screenInsetY * scaleF;
      const screenW = fw - device.screenInsetX * 2 * scaleF;
      const screenH = fh - device.screenInsetY * 2 * scaleF;
      const sw = sourceImage.width, sh = sourceImage.height;
      const imgScale = Math.max(screenW / sw, screenH / sh);
      const scaledW = sw * imgScale, scaledH = sh * imgScale;
      const drawX = screenX + (screenW - scaledW) / 2;
      const drawY = screenY + (screenH - scaledH) / 2;
      const off = document.createElement('canvas');
      off.width = cw; off.height = ch;
      const oCtx = off.getContext('2d');
      oCtx.drawImage(sourceImage, drawX, drawY, scaledW, scaledH);
      const mask = getScreenMask(frameImg, deviceName);
      if (mask) {
        const mS = document.createElement('canvas');
        mS.width = cw; mS.height = ch;
        mS.getContext('2d').drawImage(mask, fx, fy, fw, fh);
        oCtx.globalCompositeOperation = 'destination-in';
        oCtx.drawImage(mS, 0, 0);
      }
      ctx.drawImage(off, 0, 0);
      ctx.drawImage(frameImg, fx, fy, fw, fh);
    }
  } else if (sourceImage) {
    const sw = sourceImage.width, sh = sourceImage.height;
    const scale = Math.max(cw / sw, ch / sh);
    ctx.drawImage(sourceImage, (cw - sw * scale) / 2, (ch - sh * scale) / 2, sw * scale, sh * scale);
  }

  if (canvasEl.width !== cw || canvasEl.height !== ch) { canvasEl.width = cw; canvasEl.height = ch; }
  canvasEl.getContext('2d').drawImage(work, 0, 0);
}

// Export screenshot as PNG blob (renders with texts baked in)
async function exportScreenshotToPNG(screenshot, outSize) {
  const offCanvas = document.createElement('canvas');
  await compositeScreenshot(offCanvas, screenshot, outSize);
  const ctx = offCanvas.getContext('2d');

  // Bake text layers into the canvas
  if (screenshot.texts) {
    for (const t of screenshot.texts) {
      const fontStyle = t.fontWeight === 'bold' ? 'bold ' : '';
      ctx.font = `${fontStyle}${t.fontSize || 48}px -apple-system, "SF Pro Display", sans-serif`;
      ctx.fillStyle = t.color || '#ffffff';
      ctx.textAlign = t.align || 'center';
      ctx.textBaseline = 'middle';   // matches CSS translate(-50%,-50%) anchor
      const tx = (t.x / 100) * outSize.width;
      const ty = (t.y / 100) * outSize.height;
      ctx.fillText(t.content || '', tx, ty);
    }
  }

  return new Promise(resolve => offCanvas.toBlob(resolve, 'image/png'));
}
