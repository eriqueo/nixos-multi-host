

## Phase 0 — Snapshot & Safety (Day 1)
- Create branch: `git checkout -b nix-dir-refactor`
- Snapshot imports/options:
  - `rg -n 'imports\s*=\s*\[' -S hosts modules`
  - `rg -n '^\s*options\.' -S hosts modules`
  - `rg -n '/etc/nixos|/mnt/|/var/' -S hosts/server/modules modules`
- Dry build both hosts:
  - `sudo nixos-rebuild build --flake .#hwc-server`
  - `sudo nixos-rebuild build --flake .#hwc-laptop`

## Phase 1 — Batch-0 Mechanical Reorg (No Behavior Change)
- Create layout:
  - `modules/services`, `modules/storage`, `modules/gpu`, `modules/networking`, `modules/users`, `modules/_shims`, `profiles`, `lib/_shims`
- Add shim helper `modules/_shims/deprecate.nix`:
  `{ lib, newPath }: { lib.warn "Module moved to ${newPath}"; imports = [ newPath ]; }`
- Move **selected** shared bits (leave shims at old paths):
  - e.g. `shared/networking.nix  → modules/networking/main.nix`
  - e.g. `lib/scripts.nix       → lib/core-scripts.nix`
  - write a shim file at each old path that imports the new path via `_shims/deprecate.nix`
- Format/lint:
  - `nix run nixpkgs#alejandra -- -q .`
  - `nix run nixpkgs#statix -- check`
  - `nix run nixpkgs#deadnix -- .`
- Dry build both hosts again (no switch).

## Phase 2 — Paths Normalization (Dynamic Paths)
- Introduce/confirm central paths module `modules/core/paths.nix`:
  - `options.hwc.paths.{root,hot,media,state,cache,logs}`
- Replace hard-coded paths in **one low-risk module** (e.g., Transcript API) to consume `config.hwc.paths`.
- Adopt systemd `StateDirectory/CacheDirectory/LogsDirectory` in custom services.
- Validate with `build/test`.

## Phase 3 — Profiles & Host Slimming
- Create profiles:
  - `profiles/base.nix`, `profiles/server.nix`, `profiles/media-stack.nix`, `profiles/surveillance-stack.nix`, `profiles/ai-bible-stack.nix`
- Update `hosts/*/config.nix` to import profiles and remove duplicate settings.
- Dry build, then `test` on one host, then the other.

## Phase 4 — Targeted Merges (One at a Time)
- Example: `jellyfin-gpu.nix` → fold into `modules/services/jellyfin.nix` with `enableGpuTranscoding`.
- Example: monitoring split (`monitoring.nix` + `grafana-dashboards.nix`) → single `monitoring.nix` if options are compatible.
- Keep old file paths as shims for 7 days, then prune.

## Phase 5 — Documentation & Consistency
- Update doc headers with new canonical paths.
- Run your consistency validator scripts (cross-refs, broken links).
- Remove shims after quiet period.

## Conventions (enforced)
- **One module per service**; options at top, config after.
- **Kebab-case filenames**; clear scopes (e.g., `vpn-gluetun.nix`).
- **Namespace**: `hwc.*` everywhere for custom options.
- No `.backup`/`.disabled` files—use toggles instead.

## Assistant/Agent Preamble (paste into any new chat)
- NixOS is **declarative**; don’t manage services imperatively. Use `nixos-rebuild build/test/switch`.
- Keep behavior unchanged unless `hwc.*` toggles are set in host/profile.
- When moving files, **leave a shim** at the old path for at least 7 days.
- Don’t rename options. If necessary, add an alias with a warning and migration note.
- Don’t touch SOPS secrets; only adjust references.
- If in doubt, dry build and stop.

## Commands Cheat-Sheet
- Dry build: `sudo nixos-rebuild build --flake .#<host>`
- Staged: `sudo nixos-rebuild test --flake .#<host>`
- Persist: `grebuild "refactor: batch-0 moves with shims"`
- Format: `nix run nixpkgs#alejandra -- -q .`
- Lint: `nix run nixpkgs#statix -- check`
- Dead code: `nix run nixpkgs#deadnix -- .`
- Quick logs: `journalctl -p 4 -b | rg -i hwc|warn|error`