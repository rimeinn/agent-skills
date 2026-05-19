# Rime Operations Reference

Load this file only when the task needs log locations, troubleshooting commands, or sync setup details.

## Log Locations

| Platform | Frontend | Log Location |
|----------|----------|--------------|
| Windows | Weasel | `%TEMP%\rime.weasel\` |
| macOS | Squirrel | `$TMPDIR/rime.squirrel/` |
| macOS | fcitx5-macos | `/tmp/Fcitx5.log` |
| Linux | iBus Rime / fcitx5-rime | `$XDG_RUNTIME_DIR/rime.*` or `/tmp/rime.*` |

Log files are usually named like `rime.<frontend>.<user>.LOG.{INFO,WARNING,ERROR}.<timestamp>`. Symlinks such as `rime.INFO`, `rime.WARNING`, and `rime.ERROR` often point to the latest logs.

## Useful Searches

```bash
# Errors and warnings
grep -E "^[EW]" /path/to/rime.INFO

# Deployment and build messages
grep "deploy\|build\|load" /path/to/rime.INFO

# One schema or dictionary
grep "luna_pinyin\|schema_id" /path/to/rime.INFO
```

## Common Problems

| Symptom | Check |
|---------|-------|
| Changes have no effect | redeploy, then inspect generated files under `build/` |
| Schema does not appear | `default.yaml` `schema_list` and YAML parse errors |
| Candidates are empty | `translator/dictionary` vs dictionary `name`, deployment output, logs |
| `packs` words cannot be input | each pack is compiled independently and must contain single-character codes |
| Lua code does not run | file location under user data directory and exact YAML reference name |

## Sync Setup

Rime sync is configured in `installation.yaml`.

Recommended steps:

1. Set `installation_id` to a descriptive stable name, such as `windows-weasel` or `macos-squirrel`.
2. Set `sync_dir` to a user-approved shared directory, such as `$DROPBOX/RimeSync`.
3. Consider `backup_config_files: false` to avoid syncing large YAML/dictionary files; confirm this with the user first.

Typical sync directory shape:

```text
RimeSync/
├── installation1/
│   ├── *.yaml
│   └── *.txt
└── installation2/
    ├── *.yaml
    └── *.txt
```
