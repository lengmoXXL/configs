---
name: frontend-draw
description: Create simple browser-openable HTML diagrams with cards/components, arrows, timelines, and optional multi-slide walkthroughs. Use for component maps, flows, dependency sketches, call chains, and timeline explanations that should open directly in a browser.
---

# Frontend Draw

Generate browser-native HTML diagrams. Keep v1 simple: cards plus arrows, with multiple slides only when the explanation needs sequencing or a timeline.

## Rules

- Start from `template.html`; copy it to the requested output file and replace the sample cards, arrows, labels, and slides.
- Use these runtime URLs in the page head: `<link rel="stylesheet" href="https://lengmo-asserts.oss-cn-beijing.aliyuncs.com/css/frontend-draw.css?v=0.2.3">` and `<script src="https://lengmo-asserts.oss-cn-beijing.aliyuncs.com/js/frontend-draw.js?v=0.2.3" defer></script>`. Generated diagrams should reference the URLs unless the user asks for an offline file.
- Use the runtime's default theme and font. Do not add theme classes, font classes, or font picker controls.
- Output one browser-openable HTML file that references the runtime CSS and JS URLs. If the user explicitly asks for a locked/offline single file, fetch those URLs, then inline them.
- Keep the body declarative and easy to edit: put structure first, reference shared CSS/JS from the head, and avoid inline CSS in body markup.
- Use the template layout contract: each diagram node must have `data-box`, an `id`, class `box`, and `data-x`, `data-y`, `data-w`, `data-h` pixel values.
- Use groups for parent regions, layers, subsystems, or ownership boundaries. Add a group as `<div id="..." class="group" data-group data-members="card-a card-b">...</div>` before its member cards; `data-members` lists card ids and auto-sizes the group around those cards. Use `data-padding` to adjust the auto bounds.
- Add group text with nested `.group-label` elements. Position each label with `data-x` and `data-y` in group-local stage pixels. Place labels in empty space inside the group so cards do not cover the label text and labels do not cover card text.
- Add arrows with `.arrow-spec` elements instead of hand-written SVG paths. Treat each `.arrow-spec` as connection geometry: `data-from` and `data-to` must reference `data-box` ids; with only those fields, the template uses the default straight route with automatic opposite sides. Use `data-from-side`, `data-to-side`, and offsets when the default anchors are unclear.
- Use `data-points="x,y; x,y"` for intermediate route points in stage coordinates. Use `data-route="polyline"` for hard bends, `data-route="smooth"` for a smooth curve through the points, or omit `data-route` to default to `polyline` when points are present. Use `data-tension` on smooth routes when the curve needs tighter or looser handles.
- Use `data-route="arc"` and `data-bend` for a simple single-bend return path when explicit intermediate points are not needed.
- Describe reusable visual line styles with `.arrow-style` elements. Give each style `data-name` plus optional `data-stroke`, `data-width`, `data-dash`, `data-opacity`, `data-label-fill`, `data-label-outline`, or `data-marker="none"`; reference it from an arrow with `data-style`. Keep visual style details out of the connection geometry.
- Keep the SVG arrow layer above cards and panels so arrowheads are not hidden by content.
- Use a fixed stage scaled to the viewport. Default to `1920x1080`; do not reflow the diagram per device.
- Use cards for components, steps, services, states, or concepts. Keep card text short.
- Use straight arrows for simple relationships; use `polyline`, `smooth`, or `arc` routes when a return path, timeline jump, or crossing would be clearer.
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
- Cards may overlap group frames when the group/member relationship is clear; unrelated cards should not overlap, and no card or group label should hide text.
- Arrows must connect clearly and not cover important text.
- If a slide becomes crowded, split it instead of shrinking text.

## Verification

- After generating or editing a diagram, create a fixed desktop screenshot with Playwright at `1920x1080`. Write screenshots under `/tmp/frontend-draw`, not the current project directory:

```bash
mkdir -p /tmp/frontend-draw
playwright screenshot --viewport-size=1920,1080 "file://$(realpath path/to/diagram.html)" "/tmp/frontend-draw/diagram.png"
```

- For multi-slide diagrams, capture each slide at the same `1920x1080` viewport by advancing with `[data-next]` or `ArrowRight` in Playwright and saving `/tmp/frontend-draw/diagram-slide1.png`, `/tmp/frontend-draw/diagram-slide2.png`, etc.
- Inspect the PNGs before finishing: unrelated cards must not overlap, group/member overlaps must leave all text readable, group labels must not be covered by cards, labels must fit, arrows and arrowheads must be visible, and `arc`/`polyline`/`smooth` routes must not cover important card text.
- Fix the HTML and repeat the `1920x1080` screenshot check if arrows, arrowheads, cards, labels, or controls are misplaced.
