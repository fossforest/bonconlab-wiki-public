# BonConLab Wiki — Claude Instructions

## Session Start Checklist

Before making any changes, always run the following to ensure the worktree is based on the latest main (edits are sometimes made directly in VSCode outside of Claude):

```bash
git -C /Users/anon/bonconlab-wiki pull origin main
```

Then verify the current worktree branch is up to date with main before proceeding.

## Workflow

1. Pull latest main (see above)
2. Make all edits in the worktree branch
3. Commit changes with a descriptive message
4. Merge into main and push:
   ```bash
   git -C /Users/anon/bonconlab-wiki checkout main
   git -C /Users/anon/bonconlab-wiki merge <worktree-branch> --ff-only
   git -C /Users/anon/bonconlab-wiki push origin main
   ```

No pull request required — this is a solo repository.

## Wiki Structure

| File | Purpose |
|------|---------|
| `changelog.md` | Running log of all changes, newest-first within each month |
| `network.md` | IP assignments and network topology |
| `services/_services-index.md` | Master index of all services (Active Services table + Services by Node) |
| `services/<name>.md` | Per-service documentation |

## Conventions

- **Changelog**: Reverse chronological order (newest entry first within each month section). New months go above older months.
- **Services index**: Active Services table rows are grouped by node (Datto → SB → TMG → Pi). Services by Node section mirrors this.
- **Network IP table**: Rows are in ascending IP order.
- **Commit messages**: Plain English summary of what changed and why.
