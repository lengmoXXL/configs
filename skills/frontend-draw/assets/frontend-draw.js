(function (global) {
  "use strict";

  const version = "0.2.0";
  const markerPath = "M1.5,1.5 L8.5,5 L1.5,8.5 Z";
  const fontClasses = ["font-clean", "font-tech", "font-editorial", "font-compact"];
  const controllers = new Set();

  const numberData = (el, key) => Number(el.dataset[key] || 0);

  const svgEl = (name, attrs = {}) => {
    const el = document.createElementNS("http://www.w3.org/2000/svg", name);
    Object.entries(attrs).forEach(([key, value]) => el.setAttribute(key, value));
    return el;
  };

  const center = (box) => ({
    x: box.left + box.width / 2,
    y: box.top + box.height / 2,
  });

  const autoSide = (fromBox, toBox) => {
    const fromCenter = center(fromBox);
    const toCenter = center(toBox);
    const dx = toCenter.x - fromCenter.x;
    const dy = toCenter.y - fromCenter.y;
    if (Math.abs(dx) > Math.abs(dy)) return dx >= 0 ? "right" : "left";
    return dy >= 0 ? "bottom" : "top";
  };

  const anchor = (box, side, offset = 0) => {
    const midX = box.left + box.width / 2;
    const midY = box.top + box.height / 2;
    if (side === "left") return { x: box.left, y: midY + offset };
    if (side === "right") return { x: box.left + box.width, y: midY + offset };
    if (side === "top") return { x: midX + offset, y: box.top };
    return { x: midX + offset, y: box.top + box.height };
  };

  const arcPath = (start, end, bend = 120) => {
    const dx = end.x - start.x;
    const dy = end.y - start.y;
    const length = Math.hypot(dx, dy) || 1;
    const control = {
      x: (start.x + end.x) / 2 - (dy / length) * bend,
      y: (start.y + end.y) / 2 + (dx / length) * bend,
    };
    return {
      d: `M${start.x} ${start.y} Q${control.x} ${control.y} ${end.x} ${end.y}`,
      label: {
        x: 0.25 * start.x + 0.5 * control.x + 0.25 * end.x,
        y: 0.25 * start.y + 0.5 * control.y + 0.25 * end.y,
      },
    };
  };

  const parsePoints = (value) => {
    return String(value || "")
      .split(/[;|]/)
      .map((chunk) => chunk.trim())
      .filter(Boolean)
      .map((chunk) => {
        const [x, y] = chunk.split(/[,\s]+/).map(Number);
        return Number.isFinite(x) && Number.isFinite(y) ? { x, y } : null;
      })
      .filter(Boolean);
  };

  const pointAtHalfLength = (points) => {
    if (points.length === 0) return { x: 0, y: 0 };
    if (points.length === 1) return points[0];

    const lengths = [];
    let total = 0;
    for (let i = 1; i < points.length; i += 1) {
      const length = Math.hypot(points[i].x - points[i - 1].x, points[i].y - points[i - 1].y);
      lengths.push(length);
      total += length;
    }

    let remaining = total / 2;
    for (let i = 0; i < lengths.length; i += 1) {
      if (remaining <= lengths[i]) {
        const ratio = lengths[i] === 0 ? 0 : remaining / lengths[i];
        return {
          x: points[i].x + (points[i + 1].x - points[i].x) * ratio,
          y: points[i].y + (points[i + 1].y - points[i].y) * ratio,
        };
      }
      remaining -= lengths[i];
    }

    return points[points.length - 1];
  };

  const polylinePath = (points) => ({
    d: points.map((point, index) => `${index === 0 ? "M" : "L"}${point.x} ${point.y}`).join(" "),
    label: pointAtHalfLength(points),
  });

  const smoothPath = (points, tension = 1) => {
    if (points.length <= 2) return polylinePath(points);

    const factor = Number.isFinite(tension) ? tension / 6 : 1 / 6;
    const commands = [`M${points[0].x} ${points[0].y}`];
    for (let i = 0; i < points.length - 1; i += 1) {
      const p0 = points[i - 1] || points[i];
      const p1 = points[i];
      const p2 = points[i + 1];
      const p3 = points[i + 2] || p2;
      const cp1 = {
        x: p1.x + (p2.x - p0.x) * factor,
        y: p1.y + (p2.y - p0.y) * factor,
      };
      const cp2 = {
        x: p2.x - (p3.x - p1.x) * factor,
        y: p2.y - (p3.y - p1.y) * factor,
      };
      commands.push(`C${cp1.x} ${cp1.y} ${cp2.x} ${cp2.y} ${p2.x} ${p2.y}`);
    }

    return {
      d: commands.join(" "),
      label: pointAtHalfLength(points),
    };
  };

  const boxFor = (slide, id) => {
    const el = Array.from(slide.querySelectorAll("[data-box]")).find((item) => item.id === id);
    if (!el) return null;
    return {
      left: numberData(el, "x"),
      top: numberData(el, "y"),
      width: numberData(el, "w"),
      height: numberData(el, "h"),
    };
  };

  const stageSize = (stage) => {
    const styles = getComputedStyle(stage);
    return {
      width: parseFloat(styles.getPropertyValue("--stage-width")) || 1920,
      height: parseFloat(styles.getPropertyValue("--stage-height")) || 1080,
    };
  };

  const arrowStylesFor = (slide) => {
    const styles = new Map();
    slide.querySelectorAll(".arrow-style").forEach((style) => {
      styles.set(style.dataset.name || "default", {
        stroke: style.dataset.stroke || "",
        width: style.dataset.width || "",
        dash: style.dataset.dash || "",
        opacity: style.dataset.opacity || "",
        marker: style.dataset.marker || "arrow",
        labelFill: style.dataset.labelFill || "",
        labelOutline: style.dataset.labelOutline || "",
        labelOutlineWidth: style.dataset.labelOutlineWidth || "",
      });
    });
    return styles;
  };

  const applyArrowStyle = (el, style) => {
    if (style.stroke) el.style.setProperty("--arrow-stroke", style.stroke);
    if (style.width) el.style.setProperty("--arrow-width", style.width);
    if (style.dash) el.style.setProperty("--arrow-dash", style.dash);
    if (style.opacity) el.style.setProperty("--arrow-opacity", style.opacity);
    if (style.labelFill) el.style.setProperty("--label-fill", style.labelFill);
    if (style.labelOutline) el.style.setProperty("--label-outline", style.labelOutline);
    if (style.labelOutlineWidth) el.style.setProperty("--label-outline-width", style.labelOutlineWidth);
  };

  const ensureLayer = (slide) => {
    let layer = slide.querySelector(".arrow-layer");
    if (!layer) {
      layer = svgEl("svg", { class: "arrow-layer", "aria-hidden": "true" });
      slide.insertBefore(layer, slide.firstChild);
    }
    let defs = layer.querySelector("defs");
    if (!defs) {
      defs = svgEl("defs");
      layer.insertBefore(defs, layer.firstChild);
    }
    return layer;
  };

  const ensureBaseMarker = (layer, id) => {
    let marker = layer.querySelector(`#${id}`);
    if (!marker) {
      marker = svgEl("marker", {
        id,
        markerWidth: "10",
        markerHeight: "10",
        refX: "8",
        refY: "5",
        orient: "auto-start-reverse",
      });
      marker.appendChild(svgEl("path", { d: markerPath, fill: "var(--line)" }));
      layer.querySelector("defs").appendChild(marker);
    }
    return id;
  };

  const markerFor = (layer, baseMarkerId, styleName, style) => {
    const safeName = String(styleName || "default").replace(/[^a-z0-9_-]/gi, "-");
    const id = `${baseMarkerId}-${safeName}`;
    let marker = layer.querySelector(`#${id}`);
    if (!marker) {
      marker = svgEl("marker", {
        id,
        markerWidth: "10",
        markerHeight: "10",
        refX: "8",
        refY: "5",
        orient: "auto-start-reverse",
      });
      marker.appendChild(svgEl("path", { d: markerPath }));
      layer.querySelector("defs").appendChild(marker);
    }
    marker.querySelector("path").setAttribute("fill", style.stroke || "var(--line)");
    return id;
  };

  const applyLayout = (stage) => {
    stage.querySelectorAll("[data-box]").forEach((el) => {
      ["x", "y", "w", "h"].forEach((key) => {
        el.style.setProperty(`--${key}`, `${numberData(el, key)}px`);
      });
    });
  };

  const renderArrows = (stage, slide, slideIndex) => {
    const layer = ensureLayer(slide);
    const { width, height } = stageSize(stage);
    layer.setAttribute("viewBox", `0 0 ${width} ${height}`);
    layer.querySelectorAll(".generated-arrow").forEach((el) => el.remove());

    const baseMarkerId = ensureBaseMarker(layer, `arrowhead-${slideIndex + 1}`);
    const opposite = { left: "right", right: "left", top: "bottom", bottom: "top" };
    const arrowStyles = arrowStylesFor(slide);

    slide.querySelectorAll(".arrow-spec").forEach((spec) => {
      const fromBox = boxFor(slide, spec.dataset.from);
      const toBox = boxFor(slide, spec.dataset.to);
      if (!fromBox || !toBox) return;

      const fromSide = spec.dataset.fromSide || autoSide(fromBox, toBox);
      const toSide = spec.dataset.toSide || opposite[autoSide(fromBox, toBox)];
      const start = anchor(fromBox, fromSide, Number(spec.dataset.fromOffset || 0));
      const end = anchor(toBox, toSide, Number(spec.dataset.toOffset || 0));
      const points = [start, ...parsePoints(spec.dataset.points), end];
      const route = spec.dataset.route || (points.length > 2 ? "polyline" : "straight");
      const pathData = (() => {
        if (route === "arc") return arcPath(start, end, Number(spec.dataset.bend || 120));
        if (route === "polyline") return polylinePath(points);
        if (route === "smooth" || route === "curve") return smoothPath(points, Number(spec.dataset.tension || 1));
        return {
          d: `M${start.x} ${start.y} L${end.x} ${end.y}`,
          label: { x: (start.x + end.x) / 2, y: (start.y + end.y) / 2 },
        };
      })();
      const styleName = spec.dataset.style || "default";
      const visualStyle = arrowStyles.get(styleName) || arrowStyles.get("default") || {};

      const path = svgEl("path", {
        class: "arrow generated-arrow",
        d: pathData.d,
      });
      applyArrowStyle(path, visualStyle);
      if (visualStyle.marker !== "none") {
        path.setAttribute("marker-end", `url(#${markerFor(layer, baseMarkerId, styleName, visualStyle)})`);
      }
      layer.appendChild(path);

      if (spec.dataset.label) {
        const label = svgEl("text", {
          class: "arrow-label generated-arrow",
          x: pathData.label.x + Number(spec.dataset.labelDx || 0),
          y: pathData.label.y + Number(spec.dataset.labelDy || -18),
          "text-anchor": "middle",
        });
        applyArrowStyle(label, visualStyle);
        label.textContent = spec.dataset.label;
        layer.appendChild(label);
      }
    });
  };

  const init = (stage = document.getElementById("drawStage"), options = {}) => {
    if (!stage) return null;
    if (stage.frontendDraw) stage.frontendDraw.destroy();

    const slides = Array.from(stage.querySelectorAll(".draw-slide"));
    const slideList = slides.length ? slides : [stage];
    const controls = document.querySelector(options.controls || ".draw-controls");
    const count = controls ? controls.querySelector("[data-count]") : document.querySelector("[data-count]");
    const fontSelect = document.querySelector(options.fontSelect || "[data-font]");
    const prevButton = controls ? controls.querySelector("[data-prev]") : document.querySelector("[data-prev]");
    const nextButton = controls ? controls.querySelector("[data-next]") : document.querySelector("[data-next]");
    let current = Math.max(0, slideList.findIndex((slide) => slide.classList.contains("active")));
    if (current === -1) current = 0;

    const render = () => {
      applyLayout(stage);
      renderArrows(stage, slideList[current], current);
    };

    const scale = () => {
      const { width, height } = stageSize(stage);
      const scaleValue = Math.min(window.innerWidth / width, window.innerHeight / height);
      const x = (window.innerWidth - width * scaleValue) / 2;
      const y = (window.innerHeight - height * scaleValue) / 2;
      stage.style.transform = `translate(${x}px, ${y}px) scale(${scaleValue})`;
      render();
    };

    const showSlide = (index) => {
      current = Math.max(0, Math.min(index, slideList.length - 1));
      slideList.forEach((slide, i) => {
        const active = i === current;
        slide.classList.toggle("active", active);
        slide.classList.toggle("visible", active);
      });
      if (count) count.textContent = `${current + 1} / ${slideList.length}`;
      render();
    };

    const applyFont = () => {
      if (!fontSelect) return;
      document.body.classList.remove(...fontClasses);
      document.body.classList.add(fontSelect.value);
    };

    const syncFontSelect = () => {
      if (!fontSelect) return;
      fontSelect.value = fontClasses.find((className) => document.body.classList.contains(className)) || "font-clean";
    };

    const onResize = () => scale();
    const onKeydown = (event) => {
      if (event.key === "ArrowRight" || event.key === " " || event.key === "PageDown") showSlide(current + 1);
      if (event.key === "ArrowLeft" || event.key === "PageUp") showSlide(current - 1);
    };
    const onFontChange = () => applyFont();
    const onPrev = () => showSlide(current - 1);
    const onNext = () => showSlide(current + 1);

    if (fontSelect) fontSelect.addEventListener("change", onFontChange);
    if (prevButton) prevButton.addEventListener("click", onPrev);
    if (nextButton) nextButton.addEventListener("click", onNext);
    window.addEventListener("resize", onResize);
    window.addEventListener("keydown", onKeydown);

    const controller = {
      render,
      scale,
      showSlide,
      destroy() {
        if (fontSelect) fontSelect.removeEventListener("change", onFontChange);
        if (prevButton) prevButton.removeEventListener("click", onPrev);
        if (nextButton) nextButton.removeEventListener("click", onNext);
        window.removeEventListener("resize", onResize);
        window.removeEventListener("keydown", onKeydown);
        controllers.delete(controller);
        delete stage.frontendDraw;
      },
    };

    stage.frontendDraw = controller;
    controllers.add(controller);
    syncFontSelect();
    if (controls && slideList.length <= 1) controls.hidden = true;
    scale();
    showSlide(current);
    return controller;
  };

  const initAll = (selector = ".draw-stage", options = {}) => {
    return Array.from(document.querySelectorAll(selector))
      .map((stage) => init(stage, options))
      .filter(Boolean);
  };

  const renderAll = () => controllers.forEach((controller) => controller.render());

  const boot = () => initAll();
  if (typeof document !== "undefined") {
    if (document.readyState === "loading") {
      document.addEventListener("DOMContentLoaded", boot, { once: true });
    } else {
      boot();
    }
  }

  global.FrontendDraw = { version, init, initAll, renderAll };
})(typeof window !== "undefined" ? window : globalThis);
