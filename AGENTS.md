# Repository Guidelines for Future Development

This repository is maintained using GitOps tooling (FluxCD) and relies heavily on YAML manifests.

## Coding Style

- **YAML indentation:** 2 spaces. Keep `---` at the top of each file and include the appropriate `yaml-language-server` schema comment where applicable.
- **Markdown indentation:** 4 spaces. Trailing whitespace is allowed in Markdown to enable line breaks.
- **Shell scripts:** Use 4 space indentation.

## Commit Messages

Use the conventional commit format:

```
<type>(<scope>): <summary>
```

Example: `feat(database): add cloudnative-pg operator`

## Verification

After committing changes, run `git log -1 --stat` to show the latest commit and the files affected.

## Pull Requests

Summaries should briefly list major changes. Include a Testing section describing any commands run. If commands cannot run due to environment limits, mention the limitation.


