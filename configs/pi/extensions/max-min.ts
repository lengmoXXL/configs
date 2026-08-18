// Automatic MAX/MIN coding loop. `mode` (undefined = off) is the phase that is running, queued, or paused. Each
// completed phase queues the next one with the opposite mode; an aborted phase keeps mode and round and resumes; the
// loop stops after consecutive no-change phases.

import { createHash } from "node:crypto";
import { spawnSync } from "node:child_process";
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
- Every function, branch, option, comment, and abstraction must earn its place; remove what exists only out of caution or habit, and accept a small amount of duplication over a meaningless abstraction.
- Keep required behaviour, public APIs, error handling, and tests intact; do not broaden scope or touch unrelated pre-existing changes.
- Prefer doing this review through an available skill when one fits the task.

In both modes, inspect the current code and existing project instructions, make only meaningful edits, run proportionate checks,
and report honestly when the phase has no useful change to make. The loop stops automatically after ${NO_CHANGE_PHASES_TO_STOP}
consecutive phases with no file changes. If the user interrupts a phase, the loop keeps its state and resumes the same phase
on the next message.`;

// before_agent_start only fires for real user prompts; automated phases receive the rules via the control message.
const LOOP_PROMPT = `## Automatic MAX/MIN loop

The latest <max_min_control> message is authoritative for the current phase.

${LOOP_RULES}`;

function getWorkspaceSignature(cwd: string): string | undefined {
	const status = spawnSync("git", ["status", "--porcelain=v1", "--untracked-files=all"], { cwd, timeout: 5_000 });
	const diff = spawnSync("git", ["diff", "HEAD", "--no-ext-diff", "--binary", "--"], { cwd, timeout: 5_000 });
	if (status.status !== 0 || diff.status !== 0) return undefined;
	return createHash("sha256").update(status.stdout).update(diff.stdout).digest("hex");
}

export default function (pi: ExtensionAPI) {
	let mode: Mode | undefined; // undefined = loop off
	let round = 0;
	let noChangeStreak = 0;
	let phaseStopReason: string | undefined;
	let phaseChangedByTool = false;
	let phaseStartSignature: string | undefined;

	const reset = (ctx: ExtensionContext) => {
		mode = undefined;
		round = 0;
		noChangeStreak = 0;
		phaseStopReason = undefined;
		phaseChangedByTool = false;
		phaseStartSignature = undefined;
		ctx.ui.setStatus(STATUS_KEY, undefined);
	};

	const setStatus = (ctx: ExtensionContext, letter: Mode) => {
		ctx.ui.setStatus(STATUS_KEY, ctx.ui.theme.fg(letter === "max" ? "accent" : "muted", `${letter.toUpperCase()} ${round}`));
	};

	const sendControl = (letter: Mode, streakNote = "") => {
		pi.sendMessage(
			{
				customType: "max-min-control",
				content: `<max_min_control mode="${letter}" round="${round}">\nEnter ${letter.toUpperCase()} mode now. Re-evaluate the original user goal using the current workspace and prior phase results.${streakNote}\n\n${LOOP_RULES}\n</max_min_control>`,
				display: false,
			},
			{ triggerTurn: true, deliverAs: "followUp" },
		);
	};

	const registerLoopCommand = (name: string, first: Mode) => {
		pi.registerCommand(name, {
			description: `Start or switch the MAX/MIN loop to ${first.toUpperCase()} mode; run again to disable`,
			handler: async (_args, ctx) => {
				if (mode === first) {
					reset(ctx);
					ctx.ui.notify("MAX/MIN loop disabled", "info");
					return;
				}
				const switched = mode !== undefined;
				const interrupted = !ctx.isIdle();
				reset(ctx);
				mode = first;
				round = 1;
				setStatus(ctx, first);
				if (interrupted) {
					ctx.abort();
					sendControl(first);
				}
				const startNote = interrupted
					? "the running turn was interrupted and round 1 starts when it ends"
					: "round 1 begins on your next message";
				ctx.ui.notify(
					switched
						? `MAX/MIN loop switched to ${first.toUpperCase()}; ${startNote}`
						: `MAX/MIN loop enabled (starts with ${first.toUpperCase()}); ${startNote}`,
					"info",
				);
			},
		});
	};
	registerLoopCommand("max-loop", "max");
	registerLoopCommand("min-loop", "min");

	pi.on("session_start", (_event, ctx) => {
		reset(ctx);
	});

	pi.on("before_agent_start", (event, ctx) => {
		if (mode === undefined) return undefined;
		phaseStopReason = undefined;
		phaseChangedByTool = false;
		phaseStartSignature = getWorkspaceSignature(ctx.cwd);
		setStatus(ctx, mode);
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

	pi.on("agent_end", (event, ctx) => {
		if (!mode) return;
		const assistant = event.messages.findLast((message) => message.role === "assistant");
		if (!assistant) return;
		phaseStopReason = assistant.stopReason;
		if (phaseStopReason === "aborted") {
			// Reset the change baseline for the resume.
			phaseChangedByTool = false;
			phaseStartSignature = getWorkspaceSignature(ctx.cwd);
		}
	});

	pi.on("agent_settled", (_event, ctx) => {
		if (mode === undefined) return;

		// An aborted phase pauses: the queued control or the next prompt resumes it.
		if (phaseStopReason === "aborted") {
			setStatus(ctx, mode);
			return;
		}

		// A phase completed: settle it and queue the next one.
		const endSignature = getWorkspaceSignature(ctx.cwd);
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

		mode = mode === "max" ? "min" : "max";
		round += 1;
		phaseStopReason = undefined;
		phaseChangedByTool = false;
		phaseStartSignature = endSignature;
		setStatus(ctx, mode);
		const streakNote =
			noChangeStreak > 0
				? `\nThe previous phase made no file changes (${noChangeStreak} consecutive; the loop stops at ${NO_CHANGE_PHASES_TO_STOP}).`
				: "";
		sendControl(mode, streakNote);
	});
}
