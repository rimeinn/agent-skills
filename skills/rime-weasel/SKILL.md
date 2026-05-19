---
name: rime-weasel
description: Router and checklist for Windows Weasel (小狼毫) frontend configuration and troubleshooting. Use for user/shared/log directories, weasel.yaml and weasel.custom.yaml, config_version, app_options, style, layout, font_face syntax, color schemes and color formats, per-schema style overrides, tray-based installation, plum integration, and common customization examples. Load references/full-reference.md for option tables.
metadata:
  author: RimeInn
  version: 0.2.0
---

# Rime Weasel

## How To Use This Skill

Use this skill only for the Windows Weasel frontend. Load [full-reference](references/full-reference.md) for complete `style`, `layout`, font, color, install, and example sections.

| User Need | Focus |
|-----------|-------|
| Find config, data, or logs | directories |
| Change candidate window appearance | `style` and `style/layout` |
| Configure per-app behavior | `app_options` |
| Configure fonts | `font_face`, label/comment fonts |
| Configure themes | `preset_color_schemes`, `color_format` |
| Override appearance for one schema | schema-level `style` patch |
| Install schemes on Windows | Weasel scheme installer or plum |

If the task is engine behavior, schema logic, dictionaries, or Lua code, route to the corresponding Rime skill instead.

## Directories

| Directory | Meaning |
|-----------|---------|
| `%APPDATA%\Rime\` | user data directory |
| `%ProgramFiles%\Rime\weasel-*\data\` | shared data directory |
| `%TEMP%\rime.weasel\` | log directory |

Prefer `weasel.custom.yaml` patches over editing shared `weasel.yaml`.

## Patch Pattern

```yaml
patch:
  "style/color_scheme": my_theme
  "style/horizontal": true
  "style/font_face": "Microsoft JhengHei"
  "style/font_point": 15
  "style/layout/+":
    corner_radius: 10
    shadow_radius: 8
```

After changes, redeploy or restart the Weasel service.

## Common Checks

1. `config_version` can affect whether defaults override older user config.
2. App-specific keys use lowercase process names including `.exe`.
3. `color_format` controls how hex colors are interpreted; Weasel defaults to `abgr`.
4. Font names should use family names, not file names.
5. Per-schema style belongs in the schema or `<schema>.custom.yaml`, not only global `weasel.custom.yaml`.
