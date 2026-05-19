---
name: rime-spelling-algebra
description: Router and checklist for Rime spelling algebra and formatting rules. Use for xlit, xform, erase, derive, fuzz, abbrev, derive fourth-argument variants, Boost.Regex replacement syntax, speller/algebra, translator/preedit_format, translator/comment_format, and chord_composer algebra/output/prompt formats. Load references/full-reference.md for operator details and examples.
metadata:
  author: RimeInn
  version: 0.2.0
---

# Rime Spelling Algebra

## How To Use This Skill

Use this skill when a Rime task involves spelling transformations or display formatting. Load [full-reference](references/full-reference.md) for exact operator semantics, Boost.Regex replacement sequences, and examples.

First decide whether the rule changes input behavior or display only:

| Config Node | Effect |
|-------------|--------|
| `speller/algebra` | changes accepted spellings and compiled prism behavior |
| `translator/preedit_format` | changes composition display only |
| `translator/comment_format` | changes candidate comments only |
| `chord_composer/algebra` | maps chord keys to spellings |
| `chord_composer/output_format` | formats chord output |
| `chord_composer/prompt_format` | formats chord prompt text |

## Operator Choice

| Need | Operator |
|------|----------|
| character-by-character transliteration | `xlit` |
| regex rewrite and discard original spelling | `xform` |
| remove matching spellings | `erase` |
| add aliases while keeping originals | `derive` |
| add fuzzy spellings for multi-syllable contexts | `fuzz` |
| add abbreviation spellings | `abbrev` |

Rules run in order. In `speller/algebra`, changes require redeployment.

## Syntax Reminder

The first non-letter after the operator is the separator and must be used consistently in that rule:

```yaml
- xform/^([nl])ue$/$1ve/
- xform|^([nl])ue$|$1ve|
- "xform ^([nl])ue$ $1ve "
```

Replacement strings use Boost.Regex syntax, including `$1`, `$2`, `\u`, `\l`, `\U`, `\L`, and `\E`. Load [full-reference](references/full-reference.md) before relying on less common replacement behavior.

## Debug Checklist

1. Confirm whether the rule belongs in `speller/algebra`, `preedit_format`, or `comment_format`.
2. Check rule order; earlier rewrites affect later rules.
3. Use `derive` when both old and new spellings should work.
4. Use `xform` when the old spelling must stop working.
5. Prefer `fuzz` over broad `derive` when a fuzzy spelling should not make standalone single-character input too noisy.
