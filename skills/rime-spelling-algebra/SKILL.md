---
name: rime-spelling-algebra
description: Describes Rime spelling algebra operations (xlit, xform, erase, derive, fuzz, abbrev) with examples, and boost regex replacement sequences. Use this when configuring speller/algebra, preedit_format, comment_format, or chord_composer/algebra.
metadata:
  author: RimeInn
  version: 0.1.0
---

# Rime 拼寫運算（Spelling Algebra）

拼寫運算是 Rime 的字符串變換系統，以規則列表依序對拼寫串進行處理。常用於：

| 配置節點 | 用途 |
|----------|------|
| `speller/algebra` | 定義輸入法接受的拼寫集合（從音節表推導） |
| `translator/preedit_format` | 輸入框中顯示的文字格式 |
| `translator/comment_format` | 候選注釋的格式 |
| `chord_composer/algebra` | 和絃輸入的按鍵到拼寫的轉換 |
| `chord_composer/output_format` | 和絃輸入的輸出格式 |
| `chord_composer/prompt_format` | 和絃輸入的提示格式 |

---

## 分隔符

每條規則的格式為 `操作符<sep>參數1<sep>參數2<sep>`，其中分隔符 `<sep>` 是**緊接在操作符名稱之後第一個非字母字元**，且貫穿整條規則。因此下列寫法等價：

```yaml
- xform/^([nl])ue$/$1ve/
- xform|^([nl])ue$|$1ve|
- "xform ^([nl])ue$ $1ve "
```

---

## 運算符

### `xlit`　逐字替換

將左側字元集中的每個字元，按位置對應替換為右側字元集中的字元。左右字元集長度必須相等，支援 UTF-8 字元（含漢字）。

```
xlit/<左側字元集>/<右側字元集>/
```

**範例：**

```yaml
# 倉頡：將字母替換為對應倉頡字根名稱
- xlit|abcdefghijklmnopqrstuvwxyz|日月金木水火土竹戈十大中一弓人心手口尸廿山女田難卜符|

# 注音：將按鍵映射為注音符號
- xlit|1qaz2wsxedcrfv5tgbyhnujm8ik,9ol.0p;/- 6347|ㄅㄆㄇㄈㄉㄊㄋㄌㄍㄎㄏㄐㄑㄒㄓㄔㄕㄖㄗㄘㄙㄧㄨㄩㄚㄛㄜㄝㄞㄟㄠㄡㄢㄣㄤㄥㄦˊˇˋ˙ |
```

---

### `xform`　正則取代（不保留原拼寫）

以正則表達式匹配並替換，若發生替換則**移除原拼寫**，只保留替換結果。用於強制改寫拼寫。

```
xform/<正則模式>/<替換字串>/
```

**範例：**

```yaml
# 將 nue/lue 統一為 nve/lve（改寫，不保留 nue）
- xform/^([nl])ue$/$1ve/

# preedit_format：還原顯示，把 v 改回 ü
- xform/([nl])v/$1ü/

# 去除聲調數字（1–5），只保留音節本體
- xform/[12345]$//

# 大寫首字母（搭配 \u，見下文）
- xform/^([a-z])(.*)$/\u$1$2/
```

---

### `erase`　刪除

刪除完整匹配指定模式的拼寫，使其從有效拼寫集合中消失。

```
erase/<正則模式>/
```

**範例：**

```yaml
# 刪除所有帶聲調數字的拼寫（保留無調版本）
- erase/^.*\d$/

# 刪除以 v 結尾的拼寫（不需要此別名時）
- erase/^.*v$/

# 刪除空字串（防止空拼寫殘留）
- erase/^$/
```

---

### `derive`　派生（保留原拼寫）

以正則表達式產生**額外**的替代拼寫，原拼寫同時保留。用於容錯、異體輸入等。

```
derive/<正則模式>/<替換字串>/
```

**範例：**

```yaml
# 允許 nue 與 nve 互通（兩者皆可輸入）
- derive/^([nl])ve$/$1ue/

# 允許 gui 與 guei 互通
- derive/ui$/uei/

# 允許省略 zh/ch/sh 的 h（模糊音容錯）
- derive/^zh/z/
- derive/^ch/c/
- derive/^sh/s/

# 允許 ing 與 in 混淆
- derive/ing$/in/
```

#### 第四參數

`derive` 支援可選的第四參數，指定後等同於對應的運算符，但寫法不同：

```yaml
- derive/^([a-z]).+$/$1/correction   # 等同 abbrev，但懲罰更大（見下文）
- derive/^([a-z]).+$/$1/abbrev       # 等同 abbrev/
- derive/^([nl])ve$/$1ue/fuzz        # 等同 fuzz/
```

---

### `fuzz`　模糊派生

與 `derive` 相同（保留原拼寫），但產生的派生拼寫被標記為「模糊拼寫」，**只能用於多音節詞的中間音節**，不能單獨作為獨字的輸入碼。同時附加 `log(0.5) ≈ -0.693` 的可信度懲罰。

```
fuzz/<正則模式>/<替換字串>/
```

**範例：**

```yaml
# 模糊音：z/zh 不分，但避免單獨輸入 z 時誤出 zh 的字
- fuzz/^zh/z/
- fuzz/^ch/c/
- fuzz/^sh/s/

# n/l 不分（模糊）
- fuzz/^n/l/
- fuzz/^l/n/
```

---

### `abbrev`　縮寫派生

與 `derive` 相同（保留原拼寫），但產生的派生拼寫被標記為「縮寫」，在音節切分時有特殊處理（允許以縮寫為分界），同時附加 `log(0.5) ≈ -0.693` 的可信度懲罰。適合聲母簡拼。

```
abbrev/<正則模式>/<替換字串>/
```

**範例：**

```yaml
# 聲母簡拼：只保留首字母
- abbrev/^([a-z]).+$/$1/

# zh/ch/sh 雙字母簡拼
- abbrev/^([zcs]h).+$/$1/

# 零聲母的整音節縮寫
- abbrev/^([aeiouv]).+$/$1/
```

---

## 各運算符行為對照

| 運算符 | 保留原拼寫 | 新增派生 | 拼寫類型標記 | 可信度懲罰 |
|--------|-----------|---------|------------|-----------|
| `xlit` | 否（改寫） | 是 | 正常 | 無 |
| `xform` | 否（改寫） | 是 | 正常 | 無 |
| `erase` | 否（刪除） | 否 | — | — |
| `derive` | 是 | 是 | 正常 | 無 |
| `fuzz` | 是 | 是 | `kFuzzySpelling` | `log(0.5)` |
| `abbrev` | 是 | 是 | `kAbbreviation` | `log(0.5)` |
| `derive/.../correction` | 是 | 是 | `is_correction` | `log(0.01)` |

---

## 替換字串中的 Boost Regex 特殊序列

`xform`、`derive`、`fuzz`、`abbrev` 的替換字串使用 Boost.Regex Perl 格式，支援以下特殊序列：

### 反向引用

| 序列 | 說明 |
|------|------|
| `$1`、`$2`…（或 `\1`、`\2`…） | 第 n 個捕獲組的匹配內容 |
| `$&` | 整個匹配的字串 |
| `$`` ` | 匹配之前的字串（前綴） |
| `$'` | 匹配之後的字串（後綴） |

### 大小寫轉換（`\u`、`\l`、`\U`、`\L`、`\E`）

| 序列 | 說明 |
|------|------|
| `\u` | 將**緊接其後的一個字元**轉為大寫 |
| `\l` | 將**緊接其後的一個字元**轉為小寫 |
| `\U` | 將其後所有字元轉為大寫，直到遇到 `\E` 或字串結尾 |
| `\L` | 將其後所有字元轉為小寫，直到遇到 `\E` 或字串結尾 |
| `\E` | 結束 `\U` 或 `\L` 的大小寫轉換範圍 |

**範例：**

```yaml
# \u：首字母大寫（用於 preedit_format 顯示）
- xform/^([a-z])(.*)$/\u$1$2/
# "pinyin" → "Pinyin"

# \U：全部大寫
- xform/^(.*)$/\U$1/
# "abc" → "ABC"

# \L：全部小寫
- xform/^(.*)$/\L$1/
# "ABC" → "abc"

# \U...\E：只大寫部分字串
- xform/^([a-z]+)(_[a-z]+)$/\U$1\E$2/
# "foo_bar" → "FOO_bar"

# \u 結合捕獲組：聲母大寫、韻母保持
- xform/^([a-z])([a-z]*)$/\u$1$2/
# "zhong" → "Zhong"
```

---

## 完整範例

### 朙月拼音（luna_pinyin）典型配置

```yaml
speller:
  algebra:
    - erase/^xx$/                     # 刪除無效音節
    - abbrev/^([a-z]).+$/$1/          # 聲母簡拼
    - abbrev/^([zcs]h).+$/$1/         # zh/ch/sh 雙字母簡拼
    - derive/^([nl])ve$/$1ue/         # nve ↔ nue
    - derive/^([nl])ue$/$1ve/
    - derive/ui$/uei/                 # gui ↔ guei
    - derive/iu$/iou/                 # liu ↔ liou
    - derive/([aeiou])ng$/$1gn/       # 韻尾容錯
    - derive/^(.)uai$/$1uia/          # 韻母調換容錯
    - derive/^zh/j/                   # zh ↔ j 容錯（非標準）

translator:
  preedit_format:
    - xform/([nl])v/$1ü/              # v → ü 顯示
    - xform/([nl])ue/$1üe/
    - xform/([jqxy])v/$1u/
```

### 注音符號 preedit_format

```yaml
preedit_format:
  - xlit|abcdefghijklmnopqrstuvwxyz|日月金木水火土竹戈十大中一弓人心手口尸廿山女田難卜符|
```
