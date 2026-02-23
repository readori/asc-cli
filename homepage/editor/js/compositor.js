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

// Composite everything onto a canvas
// screenshot: { sourceImage, device, background, texts }
// canvasEl: <canvas> element
// outSize: { width, height } — App Store output dimensions
// bezelZoom: 0–200 — controls how large the device bezel is within the canvas (default 75)
async function compositeScreenshot(canvasEl, screenshot, outSize, bezelZoom = 75) {
  const { width: cw, height: ch } = outSize;

  // Draw everything on a work canvas first, then copy atomically to avoid flicker
  const work = document.createElement('canvas');
  work.width = cw;
  work.height = ch;
  const ctx = work.getContext('2d');

  // 1. Draw background
  drawBackground(ctx, cw, ch, screenshot.background || { type: 'gradient', colors: ['#1a1a2e', '#0f3460'], angle: 135 });

  // 2. If device frame selected, composite screenshot into bezel
  const deviceName = screenshot.device || null;
  const device = deviceName ? DEVICES_MAP[deviceName] : null;
  const sourceImage = screenshot.sourceImage;
  const offsetX = screenshot.frameOffsetX || 0;
  const offsetY = screenshot.frameOffsetY || 0;

  if (device && sourceImage) {
    let frameImg;
    try {
      frameImg = await getFrameImage(deviceName);
    } catch (e) {
      console.warn('Frame not found:', deviceName, e);
    }

    if (frameImg) {
      // Scale frame to fit output canvas, then apply user drag offset
      const scaleF = Math.min(cw / frameImg.width, ch / frameImg.height) * (bezelZoom / 100);
      const fw = frameImg.width * scaleF;
      const fh = frameImg.height * scaleF;
      const fx = (cw - fw) / 2 + offsetX;
      const fy = (ch - fh) / 2 + offsetY;

      // Screen area inside bezel
      const screenX = fx + device.screenInsetX * scaleF;
      const screenY = fy + device.screenInsetY * scaleF;
      const screenW = fw - device.screenInsetX * 2 * scaleF;
      const screenH = fh - device.screenInsetY * 2 * scaleF;

      const sw = sourceImage.width, sh = sourceImage.height;
      const imgScale = Math.max(screenW / sw, screenH / sh);
      const scaledW = sw * imgScale;
      const scaledH = sh * imgScale;
      const drawX = screenX + (screenW - scaledW) / 2;
      const drawY = screenY + (screenH - scaledH) / 2;

      // Draw screenshot masked to the screen region
      const offscreen = document.createElement('canvas');
      offscreen.width = cw; offscreen.height = ch;
      const offCtx = offscreen.getContext('2d');
      offCtx.drawImage(sourceImage, drawX, drawY, scaledW, scaledH);

      // Use cached mask (flood-fill only runs once per device)
      const mask = getScreenMask(frameImg, deviceName);
      if (mask) {
        const maskScaled = document.createElement('canvas');
        maskScaled.width = cw; maskScaled.height = ch;
        const mCtx = maskScaled.getContext('2d');
        mCtx.drawImage(mask, fx, fy, fw, fh);

        offCtx.globalCompositeOperation = 'destination-in';
        offCtx.drawImage(maskScaled, 0, 0);
        offCtx.globalCompositeOperation = 'source-over';
      }

      ctx.drawImage(offscreen, 0, 0);
      ctx.drawImage(frameImg, fx, fy, fw, fh);
    }
  } else if (sourceImage && !device) {
    // No device frame — just fill canvas with screenshot
    const sw = sourceImage.width, sh = sourceImage.height;
    const scale = Math.max(cw / sw, ch / sh);
    const scaledW = sw * scale;
    const scaledH = sh * scale;
    ctx.drawImage(sourceImage, (cw - scaledW) / 2, (ch - scaledH) / 2, scaledW, scaledH);
  }

  // Atomic copy to visible canvas — no intermediate blank/partial states
  if (canvasEl.width !== cw || canvasEl.height !== ch) {
    canvasEl.width = cw;
    canvasEl.height = ch;
  }
  canvasEl.getContext('2d').drawImage(work, 0, 0);

  // 3. Draw text layers (rendered on the overlay div, not the canvas itself for export)
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
      ctx.textBaseline = 'top';
      const tx = (t.x / 100) * outSize.width;
      const ty = (t.y / 100) * outSize.height;
      ctx.fillText(t.content || '', tx, ty);
    }
  }

  return new Promise(resolve => offCanvas.toBlob(resolve, 'image/png'));
}
