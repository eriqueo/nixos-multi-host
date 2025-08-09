

**Owner**: Eric  
**Scope**: /etc/nixos (all hosts), related scripts, systemd unit files, and docs  
**Goal**: Reduce complexity, remove drift, standardize layout, and make future changes safe and boring.

## Summary
We’re consolidating the NixOS tree into a sane structure with shims, profiles, and a single paths namespace. Changes are incremental and reversible. No behavior changes occur until explicitly toggled per host.

## Objectives
- Mechanical reorg with **no behavior change** (use deprecation shims).
- Consolidate into layers: **lib → modules → profiles → hosts**.
- Replace hard-coded paths with **config.hwc.paths.***.
- Convert split service files into single modules with **toggles** (e.g., `enableGpuTranscoding`).
- Enforce readability: one service per module, options first, then config, formatted by `alejandra`.

## Non-Goals (for this project)
- Swapping Podman↔Docker, changing service semantics, or new features.
- Secret handling rework beyond path normalization.

## Guardrails (for any assistant/agent)
- **NixOS is declarative**. Don’t “fix” by ad-hoc `systemctl stop/disable` or editing files outside Nix. Use `nixos-rebuild build/test/switch`.
- Prefer `build`/`test` first; only `switch` when validated.
- No file deletions without an **equivalent shim** left in place for at least a week.
- No option renames. If unavoidable, keep old option as alias with a warning and a migration note.
- Do not touch SOPS secrets, keys, or credentials. If a path changes, update only the reference.
- Any “merge” of split modules must preserve current defaults and behavior.

## Operating Model
- **Profiles** bundle modules (e.g., `profiles/media-stack.nix`).
- **Hosts** import profiles + local overrides.
- **Modules** expose `options.hwc.*` and apply config under `mkIf cfg.enable`.
- Paths come from `config.hwc.paths` (root, hot, media, state, cache, logs).
- Long-lived data should prefer systemd’s `StateDirectory/CacheDirectory/LogsDirectory`.

## Build/Test Workflow
- Dry build: `sudo nixos-rebuild build --flake .#<host>`
- Staged apply: `sudo nixos-rebuild test --flake .#<host>`
- Persist: `grebuild "<msg>"` (git + switch)
- Validation: `journalctl -p 4 -b | rg -i hwc|error|warn`

## Success Criteria
- Host configs short, readable.
- No duplicate service definitions.
- Zero hard-coded `/etc/nixos`, `/mnt/hot`, `/mnt/media` in service modules.
- `statix`, `deadnix`, `alejandra` clean run.
- Build/test without regressions for both hosts.

## Risks
- Hidden relative-path assumptions. Mitigation: leave shims + `environment.etc` provisioning.
- Option collisions during merges. Mitigation: `mkDefault`/`mkForce` sparingly; keep one source of truth.

## Definitions (short)
- **Shim**: tiny module that imports the new path and logs a warning.
- **mkEnableOption**: creates a boolean toggle (`enable`).
- **mkOption**: declares a configurable value (path/str/int/etc.).
- **mkIf**: applies config only when a condition is true.
- **mkDefault/mkForce**: precedence controls for conflicting values.