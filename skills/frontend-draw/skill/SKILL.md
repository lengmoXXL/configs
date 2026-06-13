---
name: frontend-draw
description: Create simple self-contained HTML diagrams with cards/components, arrows, timelines, and optional multi-slide walkthroughs. Use for component maps, flows, dependency sketches, call chains, and timeline explanations that should open directly in a browser.
---

# Frontend Draw

Generate browser-native HTML diagrams. Keep v1 simple: cards plus arrows, with multiple slides only when the explanation needs sequencing or a timeline.

## Rules

- Start from `template.html`; copy it to the requested output file and replace the sample cards, arrows, labels, and slides.
- Use the published assets directly: `<link rel="stylesheet" href="https://lengmo-asserts.oss-cn-beijing.aliyuncs.com/css/frontend-draw.css?v=0.1.0">` and `<script src="https://lengmo-asserts.oss-cn-beijing.aliyuncs.com/js/frontend-draw.js?v=0.1.0" defer></script>`. Generated diagrams should reference the OSS URLs unless the user asks for an offline file.
- Pick a background by setting the body class: `theme-paper`, `theme-white`, `theme-blueprint`, or `theme-mint`.
- Keep the `<font-picker>` component unless the user asks for a locked diagram. It lets users set the global font preset: `font-clean`, `font-tech`, `font-editorial`, or `font-compact`.
- Output one browser-openable HTML file that references the shared OSS CSS and JS. If the user explicitly asks for a locked/offline single file, fetch the referenced CSS and JS, then inline them.
- Keep the body declarative and easy to edit: put structure first, reference shared CSS/JS from the head, and avoid inline CSS in body markup.
- Use the template layout contract: each diagram node must have `data-box`, an `id`, class `box`, and `data-x`, `data-y`, `data-w`, `data-h` pixel values.
- Add arrows with `.arrow-spec` elements instead of hand-written SVG paths. Treat each `.arrow-spec` as connection geometry: `data-from` and `data-to` must reference `data-box` ids; with only those fields, the template uses the default straight route with automatic opposite sides. Use `data-from-side`, `data-to-side`, offsets, `data-route="arc"`, and `data-bend` only when the default route is unclear.
- Describe reusable visual line styles with `.arrow-style` elements. Give each style `data-name` plus optional `data-stroke`, `data-width`, `data-dash`, `data-opacity`, `data-label-fill`, `data-label-outline`, or `data-marker="none"`; reference it from an arrow with `data-style`. Keep visual style details out of the connection geometry.
- Keep the SVG arrow layer above cards and panels so arrowheads are not hidden by content.
- Use a fixed stage scaled to the viewport. Default to `1920x1080`; do not reflow the diagram per device.
- Use cards for components, steps, services, states, or concepts. Keep card text short.
- Use straight arrows for simple relationships and arc arrows when a return path, timeline jump, or crossing would be clearer.
- Use a timeline as `data-box` phase cards connected by arrows.
- Use multiple slides for overview/detail, staged explanation, before/after, or timeline progression.
- For slide switching, use `.active` / `.visible` with `visibility`, `opacity`, and `pointer-events`; do not switch slides with `display: none`.
- Include keyboard navigation for multi-slide output.
- Include `prefers-reduced-motion` if using animation.
- Do not use Mermaid or another diagram DSL unless the user explicitly asks for it.

## Quality Bar

- First screen shows the diagram itself, not a landing page.
- Remove unused sample cards, arrows, slides, and placeholder text from the template.
- Cards and labels must not overflow.
- Arrows must connect clearly and not cover important text.
- If a slide becomes crowded, split it instead of shrinking text.

## Verification

- After generating or editing a diagram, open the HTML in a browser or use Playwright screenshots at desktop and phone viewports.
- Check every slide: navigation works, cards do not overlap, labels fit, arrows and arrowheads are visible, and arc arrows do not cover important text.
- Fix the HTML if screenshots show hidden controls, text overflow, missing arrows, or unclear arrow routes.
