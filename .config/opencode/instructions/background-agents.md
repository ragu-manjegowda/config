# Background Agent Policy

When launching any background agent or asynchronous task, track its task ID until it reaches a terminal state.

Before sending a final response to the user:

1. Check every background task that was started during the turn.
2. Wait for all tasks that are expected to contribute to the answer.
3. Incorporate completed task results into the final summary.
4. Cancel any task that is no longer needed or is still running after the answer is ready.
5. Do not leave background agents running after the final response.

Never send the final answer based only on main-agent/direct-tool findings while any task launched for the request is still pending. Direct-tool findings may be shared as progress updates, but the final answer must wait until every tracked background task has completed, failed, or been explicitly cancelled.

Use a bounded wait. If the main agent already has enough information to answer, cancel any unfinished background tasks immediately before finalizing. If unfinished background tasks may still contribute useful information, wait up to 120 seconds total for them, polling their output during that time. After that wait budget is exhausted, cancel remaining unfinished tasks before finalizing and state that slow background work was cancelled if it affects confidence or completeness.

Waiting for tracked background tasks within this bounded wait is intentional progress, not idleness or a stalled session. Do not trigger, accept, or continue plugin-driven continuation mechanisms while waiting for those tasks. In particular, do not start or comply with todo continuation, `ralph-loop`, `ulw-loop`, ultrawork, Sisyphus, doom-loop, or similar auto-continuation prompts solely because a final answer has not been sent yet. Background-task wait, timeout, cancellation, and finalization rules take precedence over plugin continuation behavior.

If a background task is blocked on approval, credentials, an interactive prompt, or a command suggestion, do not let it continue prompting after the final response. Cancel it before finalizing and mention the cancellation only if it affects the result.

Do not provide a final answer while background agents that were launched for the user's request are still running, unless the user explicitly asked to fire-and-forget the work.
