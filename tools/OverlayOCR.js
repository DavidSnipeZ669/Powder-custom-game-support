/*
============================================================================================================================
 Powder OCR Debug Overlay (v1.2)
--------------------------------------------------------------
 - Displays OCR crop regions and parameter overlays in Powder
 - Click legend keys (bottom-right) to toggle each layer
 - Hover keys for explanations (top-left)
 - Press "B" to toggle overlay visibility
 - Press "S" to export a PNG of the current frame + overlay
============================================================================================================================

Example update command (paste into DevTools Console):
----------------------------------------------------------------------------------------------------------------------------
window.__setOcrCrops([
  {
    cropName: 'KillMessage',
    cropCoords: [0.130, 0.690, 0.395, 0.750],
    detectorDilateDiameter: 4,
    detectorMinimumArea: 8,
    detectorMargin: 6
  },
  {
    cropName: 'StreakMessage',
    cropCoords: [0.210, 0.590, 0.395, 0.650],
    detectorDilateDiameter: 3,
    detectorMinimumArea: 5,
    detectorMargin: 5
  },
  {
    cropName: 'GameResult',
    cropCoords: [0.380, 0.415, 0.620, 0.530],
    detectorDilateDiameter: 5,
    detectorMinimumArea: 1000,
    detectorMargin: 30
  }
]);
----------------------------------------------------------------------------------------------------------------------------
This will update the live overlay with your own crop definitions for real-time coordinate debugging.
============================================================================================================================
*/
(() => {
  const video = document.querySelector('video.shared-graphics-organisms-VideoPlayer2-style-module__video--qcKYb') || document.querySelector('video');
  if (!video) { console.warn('[OCR Overlay] video not found'); return; }

  // overlay canvas
  let canvas = document.getElementById('ocr-debug-overlay');
  if (!canvas) {
    canvas = document.createElement('canvas');
    canvas.id = 'ocr-debug-overlay';
    Object.assign(canvas.style, {
      position: 'absolute',
      inset: '0',
      pointerEvents: 'auto',          // <-- enable interaction
      zIndex: 2147483647
    });
    const wrap = document.createElement('div');
    Object.assign(wrap.style, { position: 'relative', display: 'inline-block' });
    video.parentNode.insertBefore(wrap, video);
    wrap.appendChild(video);
    wrap.appendChild(canvas);
  }
  const ctx = canvas.getContext('2d');

  // styles
  const COLORS = {
    cropStroke: 'white',
    marginFill: 'rgba(255,255,0,0.18)',
    marginStroke:'rgba(255,255,0,0.9)',
    dilateStroke:'rgba(0,220,255,1)',
    minAFill:   'rgba(255,0,200,0.22)',
    minAStroke: 'rgba(255,0,200,0.9)',
    text:'white',
    key: {
      Dilate:{ bg:'rgba(0,220,255,0.85)', fg:'#111' },
      MinA:  { bg:'rgba(255,0,200,0.85)', fg:'white' },
      Margin:{ bg:'rgba(255,255,0,0.85)', fg:'#111' }
    }
  };

  // ----- layer toggles (legend controls these) -----
  const visible = { Dilate: true, MinA: true, Margin: true };

  // OCR data (for game_postprocess.lua)
  let crops = [
    { cropName:'KillMessage',  cropCoords:[0.259,0.630,0.422,0.659], detectorDilateDiameter:3, detectorMinimumArea:5,    detectorMargin:5  },
    { cropName:'StreakMessage',cropCoords:[0.235,0.550,0.422,0.590], detectorDilateDiameter:3, detectorMinimumArea:5,    detectorMargin:5  },
    { cropName:'GameResult',   cropCoords:[0.420,0.428,0.580,0.508], detectorDilateDiameter:5, detectorMinimumArea:1000, detectorMargin:30 }
  ];

  // helpers
  function rect(x,y,w,h,{fill,stroke,lineWidth=2,dash=null}={}) {
    if (fill) { ctx.fillStyle = fill; ctx.fillRect(x,y,w,h); }
    if (stroke) { ctx.save(); if (dash) ctx.setLineDash(dash); ctx.lineWidth=lineWidth; ctx.strokeStyle=stroke; ctx.strokeRect(x,y,w,h); ctx.restore(); }
  }
  function labelPill(text,x,y,bg,fg){
    const padX=6, r=4, h=18; ctx.font='11px monospace';
    const w = Math.ceil(ctx.measureText(text).width) + padX*2;
    ctx.beginPath();
    ctx.moveTo(x+r,y); ctx.lineTo(x+w-r,y); ctx.quadraticCurveTo(x+w,y,x+w,y+r);
    ctx.lineTo(x+w,y+h-r); ctx.quadraticCurveTo(x+w,y+h,x+w-r,y+h);
    ctx.lineTo(x+r,y+h); ctx.quadraticCurveTo(x,y+h,x,y+h-r);
    ctx.lineTo(x,y+r); ctx.quadraticCurveTo(x,y,x+r,y);
    ctx.closePath(); ctx.fillStyle=bg; ctx.fill();
    ctx.fillStyle=fg; ctx.fillText(text, x+padX, y+(h-11)/2-1);
    return {width:w, height:h};
  }

  // legend state
  let legendRects = [];      // [{key:'Dilate'|'MinA'|'Margin', x,y,w,h}]
  let hoverKey = null;       // which key we're hovering
  let overlayVisible = true;

  // tooltips
  const EXPLAIN = {
    Dilate: 'detectorDilateDiameter: morphological kernel (px) used to expand bright pixels and join nearby strokes before blob analysis.',
    MinA:   'detectorMinimumArea: minimum pixel area (after dilation) for a connected component to be considered text.',
    Margin: 'detectorMargin: padding (px) added around detected regions before recognition to avoid clipping.'
  };

  function drawControlsKey() {
    const lines = ['Controls','B — Toggle overlay','S — Save PNG','Click legend keys to hide/show','Hover keys for help'];
    ctx.font = '11px monospace';
    const padX=10, padY=8, lineH=16;
    const width = Math.max(...lines.map(t => Math.ceil(ctx.measureText(t).width))) + padX*2;
    const height = lines.length*lineH + padY*2;
    const x = 10, y = canvas.height/(window.devicePixelRatio||1) - height - 10;
    // panel
    ctx.save();
    const r=6;
    ctx.beginPath();
    ctx.moveTo(x+r,y); ctx.lineTo(x+width-r,y); ctx.quadraticCurveTo(x+width,y,x+width,y+r);
    ctx.lineTo(x+width,y+height-r); ctx.quadraticCurveTo(x+width,y+height,x+width-r,y+height);
    ctx.lineTo(x+r,y+height); ctx.quadraticCurveTo(x,y+height,x,y+height-r);
    ctx.lineTo(x,y+r); ctx.quadraticCurveTo(x,y,x+r,y);
    ctx.closePath();
    ctx.fillStyle='rgba(20,20,25,0.75)'; ctx.fill();
    ctx.strokeStyle='rgba(255,255,255,0.35)'; ctx.lineWidth=1; ctx.stroke();
    // text
    let ty=y+padY;
    lines.forEach((t,i)=>{
      ctx.fillStyle = i===0 ? 'white' : 'rgba(255,255,255,0.9)';
      ctx.font = i===0 ? 'bold 12px monospace' : '11px monospace';
      ctx.fillText(t, x+padX, ty); ty+=lineH;
    });
    ctx.restore();
  }

  function drawTooltipTopLeft(key) {
    if (!key) return;
    const text = EXPLAIN[key];
    if (!text) return;
    ctx.save();
    ctx.font = '11px monospace';
    const padX=10, padY=8, lineH=16;
    const lines = text.split(/\n/g);
    const width = Math.max(...lines.map(t => Math.ceil(ctx.measureText(t).width))) + padX*2;
    const height = lines.length*lineH + padY*2;
    const x = 10, y = 10;
    // panel
    const r=6;
    ctx.beginPath();
    ctx.moveTo(x+r,y); ctx.lineTo(x+width-r,y); ctx.quadraticCurveTo(x+width,y,x+width,y+r);
    ctx.lineTo(x+width,y+height-r); ctx.quadraticCurveTo(x+width,y+height,x+width-r,y+height);
    ctx.lineTo(x+r,y+height); ctx.quadraticCurveTo(x,y+height,x,y+height-r);
    ctx.lineTo(x,y+r); ctx.quadraticCurveTo(x,y,x+r,y);
    ctx.closePath();
    ctx.fillStyle='rgba(20,20,25,0.8)'; ctx.fill();
    ctx.strokeStyle='rgba(255,255,255,0.35)'; ctx.lineWidth=1; ctx.stroke();
    // text
    let ty = y + padY;
    ctx.fillStyle='white';
    lines.forEach(t => { ctx.fillText(t, x+padX, ty); ty += lineH; });
    ctx.restore();
  }

  // draw
  function draw(){
    const r = video.getBoundingClientRect();
    const dpr = Math.max(1, window.devicePixelRatio || 1);
    const wCSS = Math.floor(r.width), hCSS = Math.floor(r.height);

    if (wCSS <= 0 || hCSS <= 0) {
      canvas.width = canvas.height = 1;
      requestAnimationFrame(draw);
      return;
    }
    canvas.style.width = wCSS + 'px';
    canvas.style.height = hCSS + 'px';
    canvas.width = Math.floor(wCSS * dpr);
    canvas.height = Math.floor(hCSS * dpr);
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    ctx.clearRect(0,0,wCSS,hCSS);

    if (overlayVisible) {
      // regions
      crops.forEach(({cropName,cropCoords,detectorDilateDiameter,detectorMinimumArea,detectorMargin})=>{
        const [x1,y1,x2,y2]=cropCoords;
        const rx=x1*wCSS, ry=y1*hCSS, rw=(x2-x1)*wCSS, rh=(y2-y1)*hCSS;

        // margin
        if (visible.Margin) {
          const mx=rx-detectorMargin, my=ry-detectorMargin, mw=rw+2*detectorMargin, mh=rh+2*detectorMargin;
          rect(mx,my,mw,mh,{fill:COLORS.marginFill, stroke:COLORS.marginStroke, lineWidth:1.5, dash:[6,4]});
        }

        // crop
        rect(rx,ry,rw,rh,{stroke:COLORS.cropStroke, lineWidth:2});

        // dilate stroke
        if (visible.Dilate) rect(rx,ry,rw,rh,{stroke:COLORS.dilateStroke, lineWidth:Math.max(1,detectorDilateDiameter)});

        // min area square
        if (visible.MinA) {
          const side=Math.max(6,Math.min(Math.sqrt(detectorMinimumArea),Math.min(rw,rh)*0.6,80));
          rect(rx+6, ry + (rh - side)/2, side, side, { fill: COLORS.minAFill, stroke: COLORS.minAStroke, lineWidth: 1 });
        }

        // centered title
        const titleSize=Math.max(12,Math.min(24,rh*0.12));
        ctx.font=`${titleSize}px monospace`; ctx.fillStyle=COLORS.text; ctx.textBaseline='top';
        const tW=ctx.measureText(cropName).width;
        ctx.fillText(cropName, rx+(rw-tW)/2, ry+4);

        // small white text labels
        const mx=rx-detectorMargin, my=ry-detectorMargin, mw=rw+2*detectorMargin, mh=rh+2*detectorMargin;
        ctx.font='11px monospace'; ctx.fillStyle=COLORS.text;
        const labels=[`Dilate:${detectorDilateDiameter}`,`MinA:${detectorMinimumArea}`,`Margin:${detectorMargin}`];
        const spacing=10, widths=labels.map(s=>Math.ceil(ctx.measureText(s).width));
        const totalW=widths.reduce((a,b)=>a+b,0)+spacing*(labels.length-1);
        let startX=mx+mw-totalW, baseY=my+mh+3;
        labels.forEach((s,i)=>{ ctx.fillText(s,startX,baseY); startX+=widths[i]+spacing; });
      });

      // legend
      legendRects = [];
      (function legend(){
        const pad=10, gap=6;
        ctx.font='11px monospace';
        const items=[{k:'Dilate'},{k:'MinA'},{k:'Margin'}];
        const maxW=Math.max(...items.map(it=>Math.ceil(ctx.measureText(it.k).width)+12));
        let x=wCSS-pad-maxW, y=hCSS-pad-(items.length*18+(items.length-1)*gap);
        items.forEach((it,idx)=>{
          const {bg,fg}=COLORS.key[it.k];
          // dim if hidden
          const bgEff = visible[it.k] ? bg : bg.replace(/, *0\.\d+\)/, ', 0.35)');
          const pill = labelPill(it.k, x, y+idx*(18+gap), bgEff, fg);
          legendRects.push({ key: it.k, x, y: y+idx*(18+gap), w: pill.width, h: pill.height });
        });
      })();

      // controls
      drawControlsKey();

      // tooltip for legend
      drawTooltipTopLeft(hoverKey);
    }

    requestAnimationFrame(draw);
  }
  draw();

  // API
  window.__setOcrCrops = (arr)=>{
    const map=new Map(crops.map(c=>[c.cropName,{...c}]));
    for(const n of arr){ const prev=map.get(n.cropName)||{}; map.set(n.cropName,{...prev,...n}); }
    crops=Array.from(map.values());
    console.log('[OCR Overlay] updated crops',crops);
  };
  window.__saveOverlayFrame = ()=>{
    const r = video.getBoundingClientRect();
    const w = Math.floor(r.width), h = Math.floor(r.height);
    if (!w || !h) { console.warn('[OCR Overlay] video not visible'); return; }
    const out = document.createElement('canvas'); out.width=w; out.height=h;
    const octx = out.getContext('2d');
    try { octx.drawImage(video,0,0,w,h); } catch(e) {}
    octx.drawImage(canvas,0,0,w,h,0,0,w,h);
    const a=document.createElement('a'); a.href=out.toDataURL('image/png'); a.download=`powder_overlay_${Date.now()}.png`;
    document.body.appendChild(a); a.click(); a.remove();
  };

  // interaction
  function cssToCanvasXY(evt){
    const rect = canvas.getBoundingClientRect();
    return { x: evt.clientX - rect.left, y: evt.clientY - rect.top };
  }
  canvas.addEventListener('mousemove', (e)=>{
    const {x,y} = cssToCanvasXY(e);
    hoverKey = null;
    for (const r of legendRects) {
      if (x >= r.x && x <= r.x+r.w && y >= r.y && y <= r.y+r.h) { hoverKey = r.key; break; }
    }
    canvas.style.cursor = hoverKey ? 'pointer' : 'default';
  });
  canvas.addEventListener('mouseleave', ()=>{ hoverKey = null; canvas.style.cursor='default'; });
  canvas.addEventListener('click', (e)=>{
    if (!hoverKey) return;
    visible[hoverKey] = !visible[hoverKey];
    console.log(`[OCR Overlay] ${hoverKey} ${visible[hoverKey]?'shown':'hidden'}`);
  });

  window.addEventListener('keydown', (e)=>{
    const k=e.key.toLowerCase();
    if (k==='s' && !e.ctrlKey && !e.metaKey && !e.altKey) { window.__saveOverlayFrame(); }
    if (k==='b' && !e.ctrlKey && !e.metaKey && !e.altKey) {
      overlayVisible = !overlayVisible;
      canvas.style.display = overlayVisible ? 'block' : 'none';
      console.log('[OCR Overlay] overlay', overlayVisible?'ON':'OFF');
    }
  });

  console.log('[OCR Overlay] ready. Click legend pills (bottom-right) to toggle layers. Hover pills for help. Keys: B toggle overlay, S save PNG.');
})();
