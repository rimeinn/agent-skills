---
name: rime-gears
description: Reference router for Rime engine components. Use when configuring or debugging processors, segmentors, translators, filters, formatters, menu options, Lua component references, tags, recognizer/matcher behavior, translator options, simplifier, reverse lookup filters, or candidate pipeline ordering. Load references/full-reference.md only when exact component options or examples are needed.
metadata:
  author: RimeInn
  version: 0.3.0
---

# Rime Gears

## How To Use This Skill

Use this skill to decide which Rime engine component is responsible for a behavior. Keep the main answer focused on the pipeline and load [full-reference](references/full-reference.md) only when the task needs exact option names, YAML examples, or component-specific edge cases.

| User Need | Component Area |
|-----------|----------------|
| Key is ignored, consumed, remapped, or commits unexpectedly | `processors` |
| Input text is not split or tagged as expected | `segmentors` |
| Candidates are empty, incomplete, duplicated, or ordered badly | `translators` and `filters` |
| Reverse lookup prefix or URL/symbol mode fails | `recognizer`, `matcher`, `affix_segmentor`, related translators/filters |
| Lua component reference syntax is unclear | Lua component syntax here, implementation in `rime-lua` |

## Engine Pipeline

Rime engine components are configured in `schema.yaml`:

```yaml
engine:
  processors:
    - ascii_composer
    - recognizer
    - key_binder
    - speller
    - punctuator
    - selector
    - navigator
    - express_editor
  segmentors:
    - ascii_segmentor
    - matcher
    - abc_segmentor
    - punct_segmentor
    - fallback_segmentor
  translators:
    - punct_translator
    - script_translator
  filters:
    - simplifier
    - uniquifier
```

Pipeline summary:

1. `processors` receive each key event in order and return accepted, rejected, or noop.
2. When `context.input` changes, `segmentors` split the input into tagged segments.
3. `translators` respond to matching tags and lazily produce candidates.
4. `filters` transform, drop, annotate, reorder, or deduplicate candidates.

## Debug Checklist

Check these before proposing a config change:

1. Is the component in the correct `engine` list and in a sensible order?
2. If using `component@class`, does the config live under the matching `class:` node?
3. If using `component@namespace`, does the config live under that namespace node?
4. Does the segmentor produce the tag that the translator or filter expects?
5. Is the issue actually spelling algebra? If yes, use `rime-spelling-algebra`.
6. Is the issue Lua implementation rather than component wiring? If yes, use `rime-lua`.

## Important Edge Case

`recognizer` is a processor, so it sees keys before the editor. Over-broad recognizer patterns can consume editing keys and prevent the editor from marking selected segments correctly. For auxiliary tags such as emoji or English hints, prefer a separate `matcher@namespace` in the segmentor phase instead of putting the pattern in the main recognizer.

## Lua Component Syntax

All Lua component classes support the same reference forms:

| Syntax | Meaning |
|--------|---------|
| `lua_xxx@func_name` | Call global `func_name` from `rime.lua` |
| `lua_xxx@*module_name` | Load `lua/module_name.lua` and use the returned component |
| `lua_xxx@*module_name@ns` | Same module with namespace `ns` |
| `lua_xxx@*dir/module` | Load `lua/dir/module.lua` |
| `lua_xxx@*mod*table*func@ns` | Use a nested field from a module-returned table |

For function signatures, lifecycle, `yield`, candidates, and Rime Lua objects, load `rime-lua`.

## Full Reference

Load [full-reference](references/full-reference.md) when you need:

- option tables for built-in processors, segmentors, translators, filters, or formatters;
- concrete YAML examples for a component;
- navigation bindings/default inheritance, ASCII switch keys, dictionary exclusions, or segmented learning;
- OpenCC/simplifier options;
- translator option details such as `dictionary`, `prism`, `packs`, `spelling_hints`, or `initial_quality`;
- complete notes on `matcher`, `recognizer`, `reverse_lookup_filter`, or Lua component variants.
