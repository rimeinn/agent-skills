---
name: rime-plum
description: Router and checklist for installing, updating, packaging, or troubleshooting Rime schemas with plum (東風破). Use for rime-install usage, recipe target syntax, preset package groups, packages.conf files, environment variables, frontend data directories, interactive selection, recipe.yaml install/download/patch behavior, package cache layout, Windows bootstrap, and Makefile/system installs. Load references/full-reference.md for syntax tables and examples.
metadata:
  author: RimeInn
  version: 0.2.0
---

# Rime Plum

## How To Use This Skill

Use this skill when the task is about plum installation, update, packaging, or recipe behavior. Load [full-reference](references/full-reference.md) only for exact recipe syntax, package-list examples, environment variable tables, or `recipe.yaml` details.

| User Need | Focus |
|-----------|-------|
| Install a schema package | target syntax and `rime_dir` |
| Install many packages | `.conf` package list |
| Package a schema for reuse | `recipe.yaml`, `install_files`, `patch_files` |
| Windows setup | Weasel bootstrap, Git for Windows, `rime-install.bat` |
| Offline/CI/system install | `no_update`, ZIP cache, Makefile |

If the user wants to edit the schema itself, use `rime-schema`. If the user wants Weasel UI configuration, use `rime-weasel`.

## First Checks

Before giving commands, identify:

1. OS and frontend: Weasel, Squirrel, iBus Rime, fcitx, or fcitx5.
2. Target user data directory (`rime_dir`).
3. Whether Git and network access are available.
4. Whether the target is a package, `:preset` group, `.conf` file, or local recipe.
5. Whether repeated installs should skip updates with `no_update=1`.

## Common Commands

```sh
# install official preset group
bash rime-install :preset

# install one package
bash rime-install luna-pinyin

# install a third-party package
bash rime-install lotem/rime-zhung

# install with explicit frontend
rime_frontend=fcitx5-rime bash rime-install luna-pinyin

# skip updating existing package clones
no_update=1 bash rime-install :preset
```

## Target Syntax

Recipe target shape:

```text
<user>/<repo>@<branch>:<recipe>:<key>=<value>,...
```

Parts may be omitted. Official short names such as `luna-pinyin` expand to `rime/rime-luna-pinyin`.

## Packaging Checklist

For a reusable plum package:

1. Include schema, dictionary, Lua, OpenCC, and other required files.
2. Use `install_files` when the default copy rules are insufficient.
3. Use `download_files` only for generated or external data that should be fetched at install time.
4. Use `patch_files` to add schemas to `default.yaml` or patch installed files idempotently.
5. Test from a clean `rime_dir`, then redeploy Rime.
