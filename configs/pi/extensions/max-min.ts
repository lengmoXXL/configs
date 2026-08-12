// Automatic MAX/MIN coding loop: the start command arms its mode (switches when the other mode is active, disables when
// its own mode is active); round 1 begins on the user's next prompt; phases then alternate automatically and round
// increments on every switch; stops after consecutive no-change phases; enabling or switching mid-run leaves the
// in-flight turn untouched (it is not a loop phase and its settle is ignored); an aborted phase keeps loop state.

import { createHash } from "node:crypto";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

type Mode = "max" | "min";

const STATUS_KEY = "minmax-loop";
const NO_CHANGE_PHASES_TO_STOP = 3;
const FILE_EDIT_TOOLS = new Set(["edit", "write", "replace", "undo_last_replace"]);

const LOOP_RULES = `MAX mode:
- Fulfil the original user request completely and correctly. MAX means maximum functional completeness, not maximum code.
- Re-check the implementation after the preceding MIN phase, restore any required behaviour it removed, and close concrete gaps.
- Do not add unrelated features or manufacture work merely to keep the loop running.

MIN mode:
- Preserve the behaviour required by the original request while deleting code that is unnecessary, redundant, duplicated, dead, or needlessly abstract.
- Prefer a smaller and clearer implementation only when behaviour, public APIs, compatibility, error handling, and tests remain intact.
- Do not broaden scope, rewrite code for taste alone, or modify unrelated and pre-existing user changes.

In both modes, inspect the current code and existing project instructions, make only meaningful edits, run proportionate checks,
and report honestly when the phase has no useful change to make. The loop stops automatically after ${NO_CHANGE_PHASES_TO_STOP}
consecutive phases with no file changes. If the user interrupts a phase, the loop keeps its state and resumes the same phase
on the next message.`;

// before_agent_start only fires for real user prompts; automated phases receive the rules via the control message.
const LOOP_PROMPT = `## Automatic MAX/MIN loop

The latest <max_min_control> message is authoritative for the current phase.

${LOOP_RULES}`;

async function getWorkspaceSignature(pi: ExtensionAPI, cwd: string): Promise<string | undefined> {
	const [status, unstaged, staged] = await Promise.all([
		pi.exec("git", ["status", "--porcelain=v1", "--untracked-files=all"], { cwd, timeout: 5_000 }),
		pi.exec("git", ["diff", "--no-ext-diff", "--binary", "--"], { cwd, timeout: 5_000 }),
		pi.exec("git", ["diff", "--cached", "--no-ext-diff", "--binary", "--"], { cwd, timeout: 5_000 }),
	]);
	if (status.code !== 0 || unstaged.code !== 0 || staged.code !== 0) return undefined;
	return createHash("sha256").update(status.stdout).update(unstaged.stdout).update(staged.stdout).digest("hex");
}

export default function (pi: ExtensionAPI) {
	let mode: Mode | undefined; // undefined = loop off, which also implies phaseInFlight === false
	let round = 0;
	let noChangeStreak = 0;
	let phaseStopReason: string | undefined;
	let phaseChangedByTool = false;
	let phaseStartSignature: string | undefined;
	let phaseInFlight = false;
	const reset = (ctx: ExtensionContext) => {
		mode = undefined;
		round = 0;
		noChangeStreak = 0;
		phaseStopReason = undefined;
		phaseChangedByTool = false;
		phaseStartSignature = undefined;
		phaseInFlight = false;
		ctx.ui.setStatus(STATUS_KEY, undefined);
	};

	const registerLoopCommand = (name: string, first: Mode) => {
		pi.registerCommand(name, {
			description: `Start or switch the MAX/MIN loop to ${first.toUpperCase()} mode; run again to disable`,
			handler: async (_args, ctx) => {
				if (mode === first) {
					reset(ctx);
					ctx.ui.notify("MAX/MIN loop disabled", "info");
				} else {
					const switched = mode !== undefined;
					reset(ctx);
					mode = first;
					round = 1;
					ctx.ui.setStatus(STATUS_KEY, ctx.ui.theme.fg(mode === "max" ? "accent" : "muted", `${mode.toUpperCase()} ${round}`));
					ctx.ui.notify(
						switched
							? `MAX/MIN loop switched to ${first.toUpperCase()}; round 1 begins on your next message`
							: `MAX/MIN loop enabled (starts with ${first.toUpperCase()}); round 1 begins on your next message`,
						"info",
					);
				}
			},
		});
	};
	registerLoopCommand("max-loop", "max");
	registerLoopCommand("min-loop", "min");

	pi.on("session_start", (_event, ctx) => {
		reset(ctx);
	});

	pi.on("before_agent_start", async (event, ctx) => {
		if (mode === undefined) return undefined;
		phaseInFlight = true;
		phaseStopReason = undefined;
		phaseChangedByTool = false;
		phaseStartSignature = await getWorkspaceSignature(pi, ctx.cwd);
		ctx.ui.setStatus(STATUS_KEY, ctx.ui.theme.fg(mode === "max" ? "accent" : "muted", `${mode.toUpperCase()} ${round}`));
		return {
			systemPrompt: `${event.systemPrompt}

${LOOP_PROMPT}

Current phase: ${mode.toUpperCase()} mode, round ${round}.`,
		};
	});

	pi.on("tool_result", (event) => {
		if (!mode || event.isError || !FILE_EDIT_TOOLS.has(event.toolName)) return;
		if (
			event.toolName === "replace" &&
			(event.details as { metrics?: { classification?: string } } | undefined)?.metrics?.classification === "noop"
		) {
			return;
		}
		phaseChangedByTool = true;
	});

	pi.on("agent_end", (event) => {
		if (!mode) return;
		const assistant = event.messages.findLast((message) => message.role === "assistant");
		if (!assistant) return;
		phaseStopReason = assistant.stopReason;
	});

	pi.on("agent_settled", async (_event, ctx) => {
		if (!mode || !phaseInFlight) return;
		phaseInFlight = false;

		if (phaseStopReason === "aborted") {
			ctx.ui.setStatus(STATUS_KEY, ctx.ui.theme.fg("muted", `${mode.toUpperCase()} ${round}`));
			return;
		}

		// The session is idle while this handler awaits, so a user prompt or loop command can interleave
		// and re-arm state; bail out if that happened. There are no awaits below, so state stays stable.
		const settledMode = mode;
		const endSignature = await getWorkspaceSignature(pi, ctx.cwd);
		if (phaseInFlight || mode !== settledMode) return;
		const changed =
			phaseChangedByTool ||
			(phaseStartSignature !== undefined && endSignature !== undefined && phaseStartSignature !== endSignature);
		noChangeStreak = changed ? 0 : noChangeStreak + 1;

		if (phaseStopReason !== "stop") {
			ctx.ui.notify(
				`MAX/MIN stopped after round ${round}: phase ended with ${phaseStopReason ?? "no assistant result"}`,
				"warning",
			);
			reset(ctx);
			return;
		}

		if (noChangeStreak >= NO_CHANGE_PHASES_TO_STOP) {
			ctx.ui.notify(
				`MAX/MIN stopped after round ${round}: ${NO_CHANGE_PHASES_TO_STOP} consecutive phases made no changes`,
				"info",
			);
			reset(ctx);
			return;
		}

		mode = settledMode === "max" ? "min" : "max";
		round += 1;
		phaseStopReason = undefined;
		phaseChangedByTool = false;
		phaseStartSignature = endSignature;
		phaseInFlight = true;
		ctx.ui.setStatus(STATUS_KEY, ctx.ui.theme.fg(mode === "max" ? "accent" : "muted", `${mode.toUpperCase()} ${round}`));
		const streakNote =
			noChangeStreak > 0
				? `\nThe previous phase made no file changes (${noChangeStreak} consecutive; the loop stops at ${NO_CHANGE_PHASES_TO_STOP}).`
				: "";
		pi.sendMessage(
			{
				customType: "max-min-control",
				content: `<max_min_control mode="${mode}" round="${round}">\nEnter ${mode.toUpperCase()} mode now. Re-evaluate the original user goal using the current workspace and prior phase results.${streakNote}\n\n${LOOP_RULES}\n</max_min_control>`,
				display: false,
			},
			{ triggerTurn: true, deliverAs: "followUp" },
		);
	});
}
