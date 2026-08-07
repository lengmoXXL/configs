// Automatic MAX/MIN coding loop: stops after consecutive no-change phases; an aborted phase keeps loop state and
// resumes on the next prompt.

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

The current user request starts an automatic alternating implementation loop. The start command picks the first mode, and the
latest <max_min_control> message is authoritative for the current phase.

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
	let enabled = false;
	let startMode: Mode = "max";
	let mode: Mode | undefined;
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
		if (enabled) {
			ctx.ui.setStatus(STATUS_KEY, ctx.ui.theme.fg("muted", startMode.toUpperCase()));
		} else {
			ctx.ui.setStatus(STATUS_KEY, undefined);
		}
	};

	const registerLoopCommand = (name: string, first: Mode) => {
		pi.registerCommand(name, {
			description: `Toggle the automatic MAX/MIN coding loop starting with ${first.toUpperCase()}`,
			handler: async (_args, ctx) => {
				enabled = !enabled;
				if (enabled) startMode = first;
				reset(ctx);
				ctx.ui.notify(
					enabled ? `MAX/MIN loop enabled (starts with ${first.toUpperCase()})` : "MAX/MIN loop disabled",
					"info",
				);
			},
		});
	};
	registerLoopCommand("max-loop", "max");
	registerLoopCommand("min-loop", "min");

	pi.on("session_start", (_event, ctx) => {
		enabled = false;
		reset(ctx);
	});

	pi.on("before_agent_start", async (event, ctx) => {
		if (!enabled) return undefined;
		if (mode === undefined) {
			mode = startMode;
			round = 1;
		}
		phaseStopReason = undefined;
		phaseChangedByTool = false;
		phaseStartSignature = await getWorkspaceSignature(pi, ctx.cwd);
		const label = `${mode.toUpperCase()} ${round}`;
		ctx.ui.setStatus(STATUS_KEY, ctx.ui.theme.fg(mode === "max" ? "accent" : "muted", label));
		return { systemPrompt: `${event.systemPrompt}\n\n${LOOP_PROMPT}` };
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
		const assistant = [...event.messages].reverse().find((message) => message.role === "assistant");
		if (!assistant) return;
		phaseStopReason = assistant.stopReason;
	});

	pi.on("agent_settled", async (_event, ctx) => {
		if (!mode) return;

		if (phaseStopReason === "aborted") {
			ctx.ui.setStatus(STATUS_KEY, ctx.ui.theme.fg("muted", `${mode.toUpperCase()} ${round}`));
			return;
		}

		// The session is idle while this handler awaits, so a user prompt can interleave and reset
		// phase state via before_agent_start; snapshot everything needed before the first await.
		const settledMode = mode;
		const settledRound = round;
		const settledStopReason = phaseStopReason;
		const settledChangedByTool = phaseChangedByTool;
		const settledStartSignature = phaseStartSignature;
		const endSignature = await getWorkspaceSignature(pi, ctx.cwd);
		const changed =
			settledChangedByTool ||
			(settledStartSignature !== undefined && endSignature !== undefined && settledStartSignature !== endSignature);
		noChangeStreak = changed ? 0 : noChangeStreak + 1;

		if (settledStopReason !== "stop") {
			enabled = false;
			reset(ctx);
			ctx.ui.notify(
				`MAX/MIN stopped after round ${settledRound}: phase ended with ${settledStopReason ?? "no assistant result"}`,
				"warning",
			);
			return;
		}

		if (noChangeStreak >= NO_CHANGE_PHASES_TO_STOP) {
			enabled = false;
			reset(ctx);
			ctx.ui.notify(
				`MAX/MIN stopped after round ${settledRound}: ${NO_CHANGE_PHASES_TO_STOP} consecutive phases made no changes`,
				"info",
			);
			return;
		}

		mode = settledMode === "max" ? "min" : "max";
		round = settledRound + 1;
		phaseStopReason = undefined;
		phaseChangedByTool = false;
		phaseStartSignature = endSignature;
		const label = `${mode.toUpperCase()} ${round}`;
		ctx.ui.setStatus(STATUS_KEY, ctx.ui.theme.fg(mode === "max" ? "accent" : "muted", label));
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
