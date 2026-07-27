// Flat Codex-like input editor for pi.
// Always padded with one empty row above and below,
// "› " prompt on the first content row, gray background block.

import { CustomEditor, type ExtensionAPI, type KeybindingsManager } from "@earendil-works/pi-coding-agent";
import { visibleWidth, type EditorTheme, type TUI } from "@earendil-works/pi-tui";

const PROMPT = "› ";
const BG = "\x1b[48;2;51;51;51m"; // #333333
const BG_RESET = "\x1b[49m";
const SGR_RESET = "\x1b[0m";

export default function (pi: ExtensionAPI) {
	pi.on("session_start", (_event, ctx) => {
		class FlatEditor extends CustomEditor {
			constructor(tui: TUI, theme: EditorTheme, keybindings: KeybindingsManager) {
				super(tui, theme, keybindings, { paddingX: 0 });
			}

			render(width: number): string[] {
				const promptWidth = 2; // "› "
				const textWidth = Math.max(1, width - promptWidth);
				const raw = super.render(textWidth);
				// Default editor emits [top border, ...content, bottom border, ...autocomplete rows];
				// borders sit at fixed positions: first line, and right before the autocomplete rows
				const { autocompleteState, autocompleteList } = this as unknown as {
					autocompleteState?: unknown;
					autocompleteList?: { render(width: number): string[] };
				};
				const autocompleteRows =
					autocompleteState && autocompleteList ? autocompleteList.render(textWidth).length : 0;
				const bottomBorder = raw.length - autocompleteRows - 1;
				let content = [...raw.slice(1, bottomBorder), ...raw.slice(bottomBorder + 1)];

				// Always keep one empty row above and below so the block breathes;
				// padding wraps the whole block, so the autocomplete menu stays attached to the text
				content = ["", ...content, ""];

				// Prompt fixed on the first text row (row 0 is padding)
				const promptRow = 1;

				return content.map((line, i) => {
					const prompt = i === promptRow ? PROMPT : "  ";
					// Inner SGR resets would clear our background; re-apply it after each one
					const restored = line.replaceAll(SGR_RESET, SGR_RESET + BG);
					const pad = " ".repeat(Math.max(0, textWidth - visibleWidth(line)));
					return BG + prompt + restored + BG + pad + BG_RESET;
				});
			}
		}

		ctx.ui.setEditorComponent((tui, theme, keybindings) => new FlatEditor(tui, theme, keybindings));
	});
}
