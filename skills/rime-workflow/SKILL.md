---
name: rime-workflow
description: Start here for Rime configuration, schema, dictionary, deployment, debugging, or sync tasks. Provides the core engine flow, directory model, patching rules, redeploy checklist, and routing to specialized Rime skills. Load references/operations.md only for log locations, troubleshooting commands, or sync setup details.
metadata:
  author: RimeInn
  version: 0.3.0
---

# Rime Workflow

## How To Use This Skill

Use this as the first Rime skill. It should answer “where in Rime does this problem live?” and then route to a narrower skill.

| Task | Next Skill |
|------|------------|
| Create or restructure an input schema | `rime-schema` |
| Inspect processors, segmentors, translators, filters, tags, or component order | `rime-gears` |
| Edit `speller/algebra`, `preedit_format`, or `comment_format` | `rime-spelling-algebra` |
| Write or debug `lua_processor`, `lua_segmentor`, `lua_translator`, or `lua_filter` | `rime-lua` |
| Install, update, or package schemes with plum | `rime-plum` |
| Configure Windows Weasel UI, app options, fonts, or colors | `rime-weasel` |

For logs, platform paths, common troubleshooting checks, or sync setup, load [operations](references/operations.md).

## First Checks

Before proposing a fix, identify:

1. the OS and Rime frontend, such as Weasel, Squirrel, iBus Rime, fcitx5-rime, other unofficial frontends;
2. whether the relevant file is in the user data directory, shared data directory, or deployed `build/` output;
3. whether the change belongs in `<name>.custom.yaml` instead of an upstream/default file;
4. whether the user redeployed after changing YAML, dictionaries, Lua files, or OpenCC data;
5. whether logs contain relevant `ERROR` or `WARNING` lines.

## Engine Flow

Rime handles input in this order:

1. `processors` receive each key event in order and return accepted, rejected, or noop.
2. If a processor changes `context.input`, Rime rebuilds the composition.
3. `segmentors` split `context.input` into segments and attach tags.
4. `translators` query tagged segments and lazily produce candidates.
5. Candidates from translations are merged by quality.
6. `filters` transform, annotate, remove, reorder, or deduplicate candidates.

If the problem is at a specific component, route to `rime-gears`.

## Data Directories

Every Rime installation has:

| Directory | Role |
|-----------|------|
| Shared data directory | read-only defaults: bundled schemas, dictionaries, OpenCC data, frontend defaults |
| User data directory | user schemas, `default.yaml`, `*.custom.yaml`, dictionaries, Lua scripts, user data |
| User `build/` directory | deployed output after `__patch` / `__include` expansion and dictionary compilation |

Debug deployed behavior against files under `build/`, not only source YAML.

## Schema Basics

A custom schema normally needs:

1. `<schema_id>.schema.yaml`
2. `<dict_name>.dict.yaml`, unless it uses only `echo_translator` or other non-dictionary translators
3. an entry in `default.yaml`:

```yaml
schema_list:
  - {schema: luna_pinyin}
  - {schema: my_schema}
```

For schema structure, translator choices, dictionary format, and complete examples, use `rime-schema`.

## Patching Rules

Prefer user patches over editing shared/default files directly.

Rime YAML supports `__include` and `__patch`. A schema without an explicit `__patch` implicitly includes:

```yaml
__patch:
  __include: <schema_id>.custom:/patch?
```

So user overrides usually go in `<schema_id>.custom.yaml`:

```yaml
patch:
  translator/enable_user_dict: false
  menu/page_size: 9
```

Patch path reminders:

- `key/path: value` overwrites a node.
- `key/path/+: value` appends to a list or merges into a map.
- Source and target types must match: list with list, map with map, scalar with scalar.

## Redeploy Checklist

After changes, redeploy and check:

1. YAML parses without indentation or quoting errors.
2. schema appears in the enabled scheme list.
3. `translator/dictionary` matches the dictionary `name`.
4. dictionary compilation produced expected `*.table.bin` / `*.prism.bin`.
5. custom patches appear in `build/<schema_id>.schema.yaml`.
6. relevant logs contain no new `ERROR` or `WARNING` lines.
