import Domain
import Foundation

/// Pure renderer: (CompositionPlan, RenderAssets) → HTML String.
/// No file I/O, no CLI parsing — just data in, HTML out.
enum CompositionHTMLRenderer {

    static func render(plan: CompositionPlan, assets: RenderAssets) -> String {
        let W = plan.canvas.width
        let H = plan.canvas.height
        let d = plan.defaults

        let cards = plan.screens.enumerated().map { (i, screen) in
            let heading = screen.texts.first?.content ?? "Screen \(i)"
            return """
            <div class="card">
                <div class="preview-wrap" onclick="exportSingle(\(i))">
                    \(renderSlide(screen: screen, index: i, plan: plan, assets: assets))
                </div>
                <div class="card-footer">
                    <span class="card-label">\(escapeHTML(heading))</span>
                    <span class="card-index">#\(i)</span>
                </div>
            </div>
            """
        }.joined(separator: "\n")

        let exportSlides = plan.screens.enumerated().map { (i, screen) in
            renderSlide(screen: screen, index: i, plan: plan, assets: assets, exportId: "export-slide-\(i)")
        }.joined(separator: "\n")

        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>\(escapeHTML(plan.appName)) — App Store Screenshots</title>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/html-to-image/1.11.11/html-to-image.min.js"></script>
        <link href="https://fonts.googleapis.com/css2?family=\(d.font.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? d.font):wght@400;500;600;700;800;900&display=swap" rel="stylesheet">
        <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: '\(d.font)', -apple-system, sans-serif;
            background: #111;
            color: #e0e0e0;
        }
        .header {
            display: flex; align-items: center; justify-content: space-between;
            padding: 20px 40px;
            border-bottom: 1px solid rgba(255,255,255,0.06);
        }
        .header-left h1 { font-size: 18px; font-weight: 700; color: #fff; }
        .header-left .meta { font-size: 13px; color: #666; margin-top: 2px; }
        .header-right { display: flex; align-items: center; gap: 6px; }
        .export-all-btn {
            background: \(d.accentColor); color: #fff; border: none;
            padding: 8px 24px; border-radius: 8px; font-size: 14px;
            font-weight: 600; cursor: pointer; transition: opacity 0.15s;
        }
        .export-all-btn:hover { opacity: 0.85; }
        .export-all-btn:disabled { opacity: 0.4; cursor: not-allowed; }
        .grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
            gap: 20px; padding: 32px 40px;
            max-width: 1600px; margin: 0 auto;
        }
        .card { display: flex; flex-direction: column; }
        .preview-wrap {
            width: 100%; aspect-ratio: \(W) / \(H);
            overflow: hidden; border-radius: \(Int(Double(W) * 0.04))px;
            position: relative; cursor: pointer;
            transition: transform 0.2s, box-shadow 0.2s;
        }
        .preview-wrap:hover { transform: translateY(-4px); box-shadow: 0 12px 40px rgba(0,0,0,0.5); }
        .preview-wrap .slide { transform-origin: top left; }
        .card-footer { display: flex; align-items: center; justify-content: space-between; padding: 10px 4px 0; }
        .card-footer .card-label { font-size: 13px; color: #666; font-weight: 500; }
        .card-footer .card-index { font-size: 13px; color: #444; font-weight: 600; }
        .slide {
            width: \(W)px; height: \(H)px;
            position: relative; overflow: hidden;
            border-radius: \(Int(Double(W) * 0.04))px;
        }
        .export-container { position: absolute; left: -99999px; top: 0; }
        .status-bar {
            position: fixed; bottom: 0; left: 0; right: 0;
            background: rgba(17,17,17,0.95); backdrop-filter: blur(10px);
            border-top: 1px solid rgba(255,255,255,0.06);
            padding: 12px 40px; text-align: center; font-size: 13px; color: #888;
            transform: translateY(100%); transition: transform 0.3s; z-index: 100;
        }
        .status-bar.visible { transform: translateY(0); }
        </style>
        </head>
        <body>
        <div class="header">
            <div class="header-left">
                <h1>\(escapeHTML(plan.appName))</h1>
                <div class="meta">\(plan.screens.count) screenshots &middot; \(W)&times;\(H)</div>
            </div>
            <div class="header-right">
                <button class="export-all-btn" onclick="exportAll()">Export All</button>
            </div>
        </div>
        <div class="grid">
        \(cards)
        </div>
        <div class="status-bar" id="statusBar"></div>
        <div class="export-container" id="exportContainer">
        \(exportSlides)
        </div>
        <script>
        const W = \(W), H = \(H);
        function scaleAll() {
            document.querySelectorAll('.preview-wrap').forEach(w => {
                const s = w.querySelector('.slide');
                if (s) s.style.transform = 'scale(' + (w.offsetWidth / W) + ')';
            });
        }
        scaleAll(); window.addEventListener('resize', scaleAll);
        function showStatus(m) { const b=document.getElementById('statusBar'); b.textContent=m; b.classList.add('visible'); }
        function hideStatus() { document.getElementById('statusBar').classList.remove('visible'); }
        async function exportSingle(i) {
            const el=document.getElementById('export-slide-'+i); if(!el) return;
            const c=document.getElementById('exportContainer');
            c.style.left='0px'; c.style.opacity='0'; c.style.zIndex='-1';
            await htmlToImage.toPng(el,{width:W,height:H,pixelRatio:1,cacheBust:true});
            const d=await htmlToImage.toPng(el,{width:W,height:H,pixelRatio:1,cacheBust:true});
            c.style.left='-99999px';
            const a=document.createElement('a'); a.download='screen-'+i+'-'+W+'x'+H+'.png'; a.href=d; a.click();
        }
        async function exportAll() {
            const btn=document.querySelector('.export-all-btn'); btn.disabled=true;
            for(let i=0;i<\(plan.screens.count);i++){
                showStatus('Exporting '+(i+1)+' of \(plan.screens.count)...');
                await exportSingle(i); await new Promise(r=>setTimeout(r,300));
            }
            showStatus('All \(plan.screens.count) exported!'); btn.disabled=false;
            setTimeout(hideStatus,3000);
        }
        </script>
        </body>
        </html>
        """
    }

    // MARK: - Slide rendering (shared between preview cards and export)

    private static func renderSlide(
        screen: SlideComposition,
        index: Int,
        plan: CompositionPlan,
        assets: RenderAssets,
        exportId: String? = nil
    ) -> String {
        let W = plan.canvas.width
        let H = plan.canvas.height
        let d = plan.defaults
        let slideBg = screen.background ?? d.background

        let texts = screen.texts.map { t in
            let font = t.font ?? d.font
            let px = Int(t.fontSize * Double(W))
            let left = Int(t.x * Double(W))
            let top = Int(t.y * Double(H))
            let alignCSS: String
            switch t.textAlign {
            case .center:
                alignCSS = "text-align:center;transform:translateX(-50%);"
            case .right:
                alignCSS = "text-align:right;transform:translateX(-100%);"
            case .left:
                alignCSS = ""
            }
            return "<div style=\"position:absolute;left:\(left)px;top:\(top)px;font-family:'\(escapeHTML(font))',sans-serif;font-size:\(px)px;font-weight:\(t.fontWeight);color:\(t.color);line-height:1.1;letter-spacing:-0.02em;white-space:pre-line;z-index:3;\(alignCSS)\">\(escapeHTML(t.content))</div>"
        }.joined(separator: "\n")

        let devices = screen.devices.map { slot in
            renderDevice(slot: slot, canvasWidth: W, canvasHeight: H, assets: assets)
        }.joined(separator: "\n")

        let idAttr = exportId.map { " id=\"\($0)\"" } ?? ""

        return """
        <div\(idAttr) class="slide" style="\(bgCSS(slideBg))">
        \(texts)
        \(devices)
        </div>
        """
    }

    private static func renderDevice(
        slot: DeviceSlot,
        canvasWidth W: Int,
        canvasHeight H: Int,
        assets: RenderAssets
    ) -> String {
        let screenshotURI = assets.screenshotDataURIs[slot.screenshotFile]
        let mockup = assets.mockups[slot.mockup]
        let deviceW = Int(slot.scale * Double(W))
        let centerX = Int(slot.x * Double(W))
        let centerY = Int(slot.y * Double(H))
        let transform = slot.rotation != 0
            ? "transform:translate(-50%,-50%) rotate(\(String(format: "%.1f", slot.rotation))deg);"
            : "transform:translate(-50%,-50%);"

        let inner: String
        if let m = mockup {
            let screenW = m.frameWidth - 2 * m.insetX
            let screenH = m.frameHeight - 2 * m.insetY
            let ixPct = String(format: "%.2f", Double(m.insetX) / Double(m.frameWidth) * 100)
            let iyPct = String(format: "%.2f", Double(m.insetY) / Double(m.frameHeight) * 100)
            let swPct = String(format: "%.2f", Double(screenW) / Double(m.frameWidth) * 100)
            let shPct = String(format: "%.2f", Double(screenH) / Double(m.frameHeight) * 100)
            let objFit = slot.contentMode == .fill ? "cover" : "contain"
            let screenshotTag = screenshotURI.map { "<img src=\"\($0)\" style=\"width:100%;height:100%;object-fit:\(objFit);display:block;\">" } ?? ""
            inner = """
            <div style="position:relative;width:100%;">
                <div style="position:absolute;left:\(ixPct)%;top:\(iyPct)%;width:\(swPct)%;height:\(shPct)%;overflow:hidden;border-radius:13.8% / 6.8%;z-index:1;">\(screenshotTag)</div>
                <img src="\(m.dataURI)" style="width:100%;display:block;position:relative;z-index:2;pointer-events:none;">
            </div>
            """
        } else {
            let screenshotTag = screenshotURI.map { "<img src=\"\($0)\" style=\"width:100%;display:block;border-radius:\(Int(Double(W) * 0.04))px;\">" } ?? ""
            inner = screenshotTag
        }

        return "<div style=\"position:absolute;left:\(centerX)px;top:\(centerY)px;width:\(deviceW)px;\(transform)z-index:2;\">\(inner)</div>"
    }

    // MARK: - Helpers

    private static func bgCSS(_ bg: SlideBackground) -> String {
        switch bg {
        case .solid(let c): return "background:\(c);"
        case .gradient(let from, let to, let angle): return "background:linear-gradient(\(angle)deg,\(from),\(to));"
        }
    }

    private static func escapeHTML(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
