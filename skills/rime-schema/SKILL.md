---
name: rime-schema
description: Router and checklist for creating, editing, or diagnosing a Rime input method schema. Covers schema.yaml/dict.yaml relationships, schema metadata, switches, engine component selection, speller/translator choices, reverse lookup, menu, and validation steps. Load references/full-reference.md for detailed YAML examples, option tables, and complete phonetic/table schemas.
metadata:
  author: RimeInn
  version: 0.2.0
---

# Rime Schema

## How To Use This Skill

Use this skill when the user is building or changing a Rime input method. Keep `SKILL.md` as the schema planning checklist; load [full-reference](references/full-reference.md) only when exact YAML examples or option details are needed.

| Schema Type | Main Translator | Dictionary Code Shape |
|-------------|-----------------|-----------------------|
| Pinyin, Jyutping, Bopomofo, other syllabic schemes | `script_translator` | syllables separated by spaces, such as `zhong wen` |
| Cangjie, Wubi, stroke, other table schemes | `table_translator` | code treated as one unit, usually no spaces |
| Minimal smoke test or echo scheme | `echo_translator` | no dictionary required |

## Required Files

Place schema files in the Rime user data directory:

| File | Purpose |
|------|---------|
| `<schema_id>.schema.yaml` | schema definition, engine, speller, translators, filters |
| `<dict_name>.dict.yaml` | dictionary used by `translator/dictionary` |

Naming invariants:

1. `schema/schema_id` must match `<schema_id>.schema.yaml`.
2. `translator/dictionary` must match the `name` in `<dict_name>.dict.yaml`.
3. Add the schema to `default.yaml` under `schema_list`.
4. Redeploy after changes.

## Schema Build Order

1. Choose `schema_id`, display name, version, and dependencies.
2. Choose switches such as `ascii_mode`, `full_shape`, `simplification`, and `ascii_punct`.
3. Choose an engine template:
   - syllabic: `script_translator` plus `speller/algebra`;
   - table: `table_translator` plus `max_code_length` and optional `encoder`;
   - test: `echo_translator`.
4. Configure `speller`.
5. Configure translator namespace and dictionary.
6. Add `punctuator`, `key_binder`, `recognizer`, `menu`, and filters.
7. Validate with deployment logs and generated files under `build/`.

## Typical Engine Templates

Syllabic schemes usually start with:

```yaml
engine:
  processors: [ascii_composer, recognizer, key_binder, speller, punctuator, selector, navigator, express_editor]
  segmentors: [ascii_segmentor, matcher, abc_segmentor, punct_segmentor, fallback_segmentor]
  translators: [punct_translator, script_translator]
  filters: [simplifier, uniquifier]
```

Table schemes usually start with:

```yaml
engine:
  processors: [ascii_composer, key_binder, speller, punctuator, selector, navigator, express_editor]
  segmentors: [ascii_segmentor, abc_segmentor, punct_segmentor, fallback_segmentor]
  translators: [punct_translator, table_translator]
  filters: [uniquifier]
```

For exact multi-line examples, load [full-reference](references/full-reference.md).

## Cross-Skill Routing

| Need | Use |
|------|-----|
| Exact component behavior or options | `rime-gears` |
| `speller/algebra`, `preedit_format`, `comment_format` rules | `rime-spelling-algebra` |
| Lua processors, segmentors, translators, or filters | `rime-lua` |
| Installing a schema package | `rime-plum` |
| Windows Weasel appearance or app behavior | `rime-weasel` |

## Validation Checklist

Before considering a schema fix complete, check:

1. YAML indentation uses spaces, not tabs.
2. `schema_id`, file names, dictionary name, and translator dictionary agree.
3. Engine components are in the expected order.
4. Tags produced by segmentors match translator/filter `tag` or `tags`.
5. `default.yaml` includes the schema in `schema_list`.
6. Rime has been redeployed and logs do not show relevant `ERROR` or `WARNING` lines.

## Full Reference

Load [full-reference](references/full-reference.md) when you need:

- complete top-level `schema.yaml` structure;
- full metadata, switches, speller, translator, punctuator, key binder, recognizer, reverse lookup, or menu examples;
- `dict.yaml` frontmatter, columns, entry format, import tables, or encoder rules;
- complete phonetic and table schema examples;
- the common error table.
