# Installation

The skill is a self-contained folder: `visual-implementation/`. Installing means copying that folder into your agent runtime's skills directory, then starting a fresh session so it is discovered.

## Get the files

```bash
git clone https://github.com/Feelynx/visual-implementation-skill.git
cd visual-implementation-skill
```

## Claude Code

Skills live in `~/.claude/skills/`.

```bash
cp -R visual-implementation ~/.claude/skills/visual-implementation
```

Start a new session — skills are discovered at session start.

## Codex

Skills live in `~/.codex/skills/`.

```bash
cp -R visual-implementation ~/.codex/skills/visual-implementation
```

The folder ships an `agents/openai.yaml` manifest (display name and default prompt) that the runtime reads.

## Other skill-aware runtimes

Any runtime that loads folder-based skills can use it: copy `visual-implementation/` into that runtime's skills directory. The contract lives in `SKILL.md`; the `references/*.md` files are loaded on demand.

## Updating

Pull the latest and re-copy:

```bash
git pull
cp -R visual-implementation ~/.claude/skills/visual-implementation     # and/or ~/.codex/skills/...
```

Re-copying overwrites the installed `SKILL.md` and `references/`. If your runtime keeps an install manifest beside the skill (for example a plugin descriptor), it is preserved as long as you copy *into* the existing folder rather than replacing it wholesale.

## Verifying the install

```bash
ls ~/.claude/skills/visual-implementation        # SKILL.md, references/, agents/
diff -r visual-implementation ~/.claude/skills/visual-implementation
```

A clean `diff` (ignoring any runtime-added manifest) means the installed copy matches the source.

## Uninstalling

```bash
rm -rf ~/.claude/skills/visual-implementation
rm -rf ~/.codex/skills/visual-implementation
```

## Notes

- Installs are **copies**, independent of this git checkout — moving or deleting the clone does not affect an installed skill.
- Keep the directory name `visual-implementation`; the skill name in `SKILL.md` frontmatter matches it.
