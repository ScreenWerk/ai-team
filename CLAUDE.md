# CLAUDE.md — screenwerk-dev

## On startup

1. Read `.claude/teams/screenwerk-dev/prompts/lumiere.md` (your prompt — you are Lumiere, the team lead)
2. Read `.claude/teams/screenwerk-dev/common-prompt.md` (mission, standards, communication rules)
3. Read `.claude/teams/screenwerk-dev/design-spec.md` (full team design, architecture, workflow)
4. Run `TeamCreate(team_name="screenwerk-dev")`
5. Ask the user which agents to spawn, then use `spawn_member.sh` for each:

```bash
bash ~/workspace/.claude/teams/screenwerk-dev/spawn_member.sh --target-pane %N <agent-name>
```

Agents: plateau, daguerre, niepce, melies, reynaud, talbot

Do NOT auto-spawn all agents. Ask the user first.
