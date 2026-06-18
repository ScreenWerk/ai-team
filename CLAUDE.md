# CLAUDE.md — screenwerk-dev

## On startup

1. Read `.claude/teams/screenwerk-dev/prompts/lumiere.md` (your prompt — you are Lumiere, the team lead)
2. Read `.claude/teams/screenwerk-dev/common-prompt.md` (mission, standards, communication rules)
3. Read `.claude/teams/screenwerk-dev/design-spec.md` (full team design, architecture, workflow)
4. Ask the user which agents to spawn. (The team is always-on — its name is the session id. There is nothing to create.)
5. Spawn each requested agent natively with the `Agent` tool — one call per member, run in the background, named after its roster entry. You do **not** need to read a member's full prompt to spawn it: `roster.json` gives name/model/color/agentType, and the agent reads its own prompt on startup. Pass only a short bootstrap instruction pointing the agent at its own files:

```
Agent(
  name: "<agent>",                 # e.g. talbot
  subagent_type: "general-purpose",
  run_in_background: true,
  prompt: "You are <Agent> on screenwerk-dev. Bootstrap: read prompts/<agent>.md (your identity), common-prompt.md (team standards), and your scratchpad memory/<agent>.md if it exists; send team-lead a timestamped intro via SendMessage; then stand by for tasking."
)
```

Continue or redirect a running member via `SendMessage({to: "<agent>"})`.

Agents: plateau, daguerre, niepce, melies, reynaud, talbot

Do NOT auto-spawn all agents. Ask the user first.

> **Retired (do not use):** `TeamCreate`/`TeamDelete` (team is now always-on, session-id named) and the tmux-based `spawn_member.sh` / `apply-layout.sh` scripts. Spawn members with the native `Agent` tool instead.
