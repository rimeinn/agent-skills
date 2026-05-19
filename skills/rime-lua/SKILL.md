---
name: rime-lua
description: Router and checklist for writing or debugging Rime Lua components. Use for lua_processor, lua_segmentor, lua_translator, lua_filter, module return shapes, init/fini/func lifecycle, env state, yield semantics, notifier cleanup, Candidate/ShadowCandidate, Component wrappers, Memory, CommitHistory, Projection, LevelDb, and the bundled librime.lua type stub. Load references/full-reference.md for signatures and examples.
metadata:
  author: RimeInn
  version: 0.2.0
resources:
  - assets/librime.lua
---

# Rime Lua

## How To Use This Skill

Use this skill for Rime Lua implementation and debugging. Keep this file as the decision checklist; load [full-reference](references/full-reference.md) for function signatures, detailed examples, and object usage. Load [librime.lua](assets/librime.lua) only when exact API members or type details are needed.

| User Need | Component |
|-----------|-----------|
| Intercept, consume, or rewrite key events | `lua_processor` |
| Add tags or custom segmentation | `lua_segmentor` |
| Generate candidates from input | `lua_translator` |
| Modify, reorder, annotate, or remove existing candidates | `lua_filter` |

## Component Shape

Lua modules can return either a function or a lifecycle table:

```lua
local M = {}

function M.init(env)
  env.config = env.engine.schema.config
end

function M.func(...)
  -- component logic
end

function M.fini(env)
  if env.conn then env.conn:disconnect() end
end

return M
```

Rules:

1. Put instance state on `env`, not in module globals.
2. Use `env.name_space` for per-instance YAML namespaces.
3. Disconnect notifiers, databases, and memories in `fini`.
4. Translator and filter components output with `yield(cand)`, not return values.

## Return Values And Output

| Component | Main Function | Output |
|-----------|---------------|--------|
| `processor` | `func(key_event, env)` | `0` rejected, `1` accepted, `2` noop |
| `segmentor` | `func(segmentation, env)` | boolean continue/stop |
| `translator` | `func(input, segment, env)` | one or more `yield(Candidate(...))` |
| `filter` | `func(input, env)` | iterate upstream and `yield` kept/changed candidates |

For exact signatures and examples, load [full-reference](references/full-reference.md).

## Schema Reference Forms

Lua component references are configured in `schema.yaml`:

```yaml
engine:
  translators:
    - lua_translator@func_name
    - lua_translator@*module_name
    - lua_translator@*module_name@namespace
```

If the issue is component wiring rather than Lua code, use `rime-gears`.

## Debug Checklist

Before changing code, check:

1. The Lua file is under the Rime user data directory: `rime.lua` or `lua/<module>.lua`.
2. The YAML reference exactly matches the global function or module path.
3. The module returns the expected function/table.
4. Candidate start/end positions use `segment.start` and `segment._end`.
5. Filters use `ShadowCandidate` when changing text/comment on wrapped or read-only candidates.
6. Logs show whether the Lua file loaded or raised an error.
