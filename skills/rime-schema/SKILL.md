---
name: rime-schema
description: Describes how to create a Rime input method schema from scratch. Covers schema.yaml structure, metadata, switches, engine configuration, speller, translator, dict.yaml format, and complete examples for both phonetic and table-based schemas.
metadata:
  author: RimeInn
  version: 0.1.0
---

# 創建 Rime 輸入方案

## 文件命名與位置

一個方案由兩類文件組成，均放在**用戶配置目錄**：

| 文件 | 命名規則 | 說明 |
|------|----------|------|
| `<schema_id>.schema.yaml` | 方案 ID + `.schema.yaml` | 方案定義文件（必需） |
| `<dict_name>.dict.yaml` | 詞庫名 + `.dict.yaml` | 詞庫文件（有翻譯器時必需） |

- 方案 ID（`schema_id`）只能包含小寫字母、數字、下劃線
- 啟用方案需在 `default.yaml` 的 `schema_list` 中添加 `{schema: <schema_id>}`
- 修改後需**重新部署**（Re-deploy）才能生效

---

## schema.yaml 頂層結構

```yaml
schema:          # 方案元數據
  schema_id: ...
  name: ...
  ...

switches:        # 可切換選項列表
  - ...

engine:          # 引擎組件配置
  processors:
    - ...
  segmentors:
    - ...
  translators:
    - ...
  filters:
    - ...

speller:         # 拼寫器設定（拼音/注音類方案）
  ...

translator:      # 翻譯器設定
  ...

punctuator:      # 標點符號映射
  ...

key_binder:      # 按鍵重綁定
  ...

recognizer:      # 輸入模式識別（URL、反查等）
  ...

menu:            # 候選選單設定
  ...
```

---

## schema 元數據

```yaml
schema:
  schema_id: my_schema          # 唯一標識，只允許小寫字母、數字、下劃線
  name: 我的方案                 # 顯示名稱（方案選單中顯示）
  version: "0.1"                # 版本號（字串）
  author:
    - 作者名 <email@example.com>
  description: |
    方案說明文字。
  dependencies:                 # 可選，依賴的其他方案（用於反查等）
    - luna_pinyin
```

---

## switches 開關

`switches` 定義可切換的狀態選項。每個開關在 context 中對應一個 option name。

```yaml
switches:
  - name: ascii_mode            # 中英文切換，0=中文，1=英文
    reset: 0                    # reset: 指定部署後的初始狀態（不填則記憶上次狀態）
    states: [中文, 西文]

  - name: full_shape            # 全形/半形，0=半形，1=全形
    states: [半形, 全形]

  - name: simplification        # 繁簡轉換，配合 simplifier 使用
    states: [漢字, 汉字]

  - name: extended_charset      # 字符集過濾，0=僅基本區，1=含擴展區
    states: [通用, 增廣]

  - name: ascii_punct           # 標點符號，0=中文標點，1=西文標點
    states: [。，, ．，]
```

### Radio 開關（多選一）

```yaml
switches:
  - options: [simplification, trad_tw, trad_hk]
    states: [通用繁體, 臺灣正體, 香港繁體]
    reset: 0
```

---

## engine 引擎組件

引擎由四類組件構成，詳細說明見 **rime-gears** skill。

### 拼音類方案（script_translator）典型配置

```yaml
engine:
  processors:
    - ascii_composer     # 中英切換（Caps/Shift）
    - recognizer         # 識別特殊輸入模式（URL、反查）
    - key_binder         # 按鍵重綁定
    - speller            # 接受字母加入輸入串
    - punctuator         # 標點符號
    - selector           # 候選選擇、翻頁
    - navigator          # 光標移動
    - express_editor     # 空白上屏、Enter 提交原碼
  segmentors:
    - ascii_segmentor    # 西文模式直接提交
    - matcher            # 配合 recognizer 的模式分段
    - abc_segmentor      # 標準輸入段（打上 abc tag）
    - punct_segmentor    # 標點分段
    - fallback_segmentor # 兜底（打上 raw tag）
  translators:
    - punct_translator   # 標點翻譯
    - script_translator  # 拼音翻譯（音節拆分 + 整句）
  filters:
    - simplifier         # 繁簡轉換（需有 simplification 開關）
    - uniquifier         # 去重
```

### 形碼類方案（table_translator）典型配置

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
    - table_translator   # 碼表翻譯（查表式）
  filters:
    - simplifier
    - uniquifier
```

---

## speller 拼寫器

用於拼音、注音等音節式方案。形碼方案也需配置 `alphabet` 和 `max_code_length`。

```yaml
speller:
  alphabet: zyxwvutsrqponmlkjihgfedcba   # 參與拼寫的字元集
  delimiter: " '"                         # 音節分隔符（空格或撇號）
  algebra:                                # 拼寫運算規則（見 rime-spelling-algebra）
    - erase/^xx$/
    - abbrev/^([a-z]).+$/$1/
    - derive/^([nl])ve$/$1ue/
  # 形碼常用選項：
  # max_code_length: 4                   # 達到最大碼長自動上屏
  # auto_select: true                    # 唯一候選自動上屏
  # auto_select_pattern: ^[a-z]{4}$      # 匹配此模式時自動上屏
```

---

## translator 翻譯器

### script_translator（拼音類）

```yaml
translator:
  dictionary: my_dict           # 對應 my_dict.dict.yaml 的 name 欄位
  prism: my_schema              # 棱鏡名，默認與 dictionary 相同；多方案共用詞庫時設為 schema_id
  enable_sentence: true         # 啟用整句輸入
  enable_user_dict: true        # 啟用用戶詞庫（記錄上屏習慣）
  spelling_hints: 5             # 候選注釋中顯示拼音提示的最大字數（0=不顯示）
  preedit_format:               # 輸入框顯示格式
    - xform/([nl])v/$1ü/
  comment_format:               # 候選注釋格式
    - xform/([nl])v/$1ü/
  initial_quality: 1            # 候選優先級偏移
```

### table_translator（形碼類）

```yaml
translator:
  dictionary: my_dict
  enable_sentence: false        # 形碼通常不需整句
  enable_encoder: true          # 自動造詞
  encode_commit_history: true   # 根據上屏歷史造詞
  max_phrase_length: 4
  max_code_length: 4            # 最大碼長
  auto_select: true             # 唯一候選自動上屏
  enable_charset_filter: true   # 過濾生僻字
```

### 多翻譯器（命名空間）

當方案中有多個翻譯器時，非默認翻譯器使用自定義命名空間：

```yaml
engine:
  translators:
    - script_translator          # 使用 translator: 節點
    - script_translator@luna     # 使用 luna: 節點（副翻譯器）

luna:
  tag: luna                      # 響應 luna tag 的輸入段
  dictionary: luna_pinyin
  enable_sentence: false
```

---

## punctuator 標點符號

```yaml
punctuator:
  import_preset: default        # 導入預設標點（default.yaml 中定義）
  half_shape:                   # 覆蓋或補充半形標點
    ",": "，"
    ".": "。"
    "?": "？"
    "!": "！"
    "'": {pair: ["'", "'"]}
    '"': {pair: [""", """]}
    "/": ["／", "÷"]            # 列表：循環切換
```

---

## key_binder 按鍵綁定

```yaml
key_binder:
  import_preset: default        # 導入預設綁定
  bindings:
    - {when: has_menu, accept: minus, send: Page_Up}    # - 翻上頁
    - {when: has_menu, accept: equal, send: Page_Down}  # = 翻下頁
    - {when: always, accept: "Control+period", toggle: ascii_punct}
    - {when: always, accept: "Control+Shift+4", toggle: simplification}
```

`when` 條件：`always`、`composing`（有輸入串）、`has_menu`（有候選）、`paging`（已翻頁）

---

## recognizer 識別器

與 `matcher` 分段器配合，識別特殊輸入模式：

```yaml
recognizer:
  import_preset: default
  patterns:
    reverse_lookup: "^`[a-z]*'?$"    # 反查模式：以 ` 開頭
    punct: "^/([0-9]0?|[A-Za-z]+)$"  # 符號模式
```

---

## 反查（Reverse Lookup）配置

反查允許以另一套方案（如拼音）查詢當前方案的編碼。需要以下組件配合：

```yaml
# 1. 在 schema/dependencies 中聲明依賴
schema:
  dependencies:
    - luna_pinyin

# 2. recognizer 中定義觸發模式
recognizer:
  patterns:
    reverse_lookup: "^`[a-z]*'?$"

# 3. 添加 affix_segmentor（分段器）
engine:
  segmentors:
    - affix_segmentor@reverse_lookup   # 使用 reverse_lookup: 節點

# 4. 添加翻譯器和過濾器
  translators:
    - reverse_lookup_translator
  filters:
    - reverse_lookup_filter@reverse_lookup

# 5. 配置節點
reverse_lookup:
  tag: reverse_lookup
  prefix: "`"
  suffix: "'"
  tips: 〔反查〕
  dictionary: luna_pinyin
  comment_format:
    - xform/([nl])v/$1ü/
```

---

## menu 選單

```yaml
menu:
  page_size: 5                         # 每頁候選數（默認 5，最小 1）
  alternative_select_keys: asdfghjkl   # 自定義選字鍵（長度需與 page_size 一致）
```

---

## dict.yaml 格式

### 元數據

```yaml
---
name: my_dict                          # 詞庫名稱，與 translator/dictionary 一致
version: "2024.01.01"
sort: by_weight                        # 排序：original（保持原序）或 by_weight（按權重）
use_preset_vocabulary: true            # 導入八股文詞頻（繁體），默認 true
# columns:                            # 自定義列順序，默認如下：
#   - text                            #   詞條文字
#   - code                            #   編碼
#   - weight                          #   權重
#   - stem                            #   構詞碼（形碼用）
# import_tables:                      # 導入其他詞庫
#   - other_dict
...
```

### 詞條格式

詞條以 **Tab 分隔**（注意不是空格）：

```
字	zi	1000
詞語	ci yu	100
瓩	qian wa
# 這是注釋
```

- 拼音類：多音節詞各音節間用**空格**分隔（`ci yu`）
- 形碼類：編碼視作整體，不用空格
- 權重可省略
- `# nocomment` 出現後，`#` 不再視為注釋

### 形碼詞庫的 encoder

```yaml
encoder:
  exclude_patterns:
    - ^x.*$                   # 含 x 的編碼不參與自動造詞
  rules:
    - length_equal: 2         # 二字詞：取每字前兩碼
      formula: "AaAaBbBb"
    - length_equal: 3         # 三字詞：取前兩字首碼 + 末字前兩碼
      formula: "AaBbCcCc"
    - length_in_range: [4, 10] # 四字及以上：取前三字首碼 + 末字首碼
      formula: "AaBbCcDa"
```

`formula` 中：大寫字母（A/B/C/D...）表示詞中第幾個字，小寫字母（a/b/c...）表示該字編碼的第幾個碼位。

---

## 完整範例

### 最簡方案（echo 翻譯器）

驗證引擎基本流程，輸入什麼就輸出什麼：

```yaml
schema:
  schema_id: minimal
  name: 最簡方案
  version: "0.1"

engine:
  processors:
    - speller
    - selector
    - express_editor
  segmentors:
    - fallback_segmentor
  translators:
    - echo_translator
```

### 拼音方案（script_translator）

```yaml
schema:
  schema_id: my_pinyin
  name: 我的拼音
  version: "0.1"
  author:
    - 作者名

switches:
  - name: ascii_mode
    reset: 0
    states: [中文, 西文]
  - name: full_shape
    states: [半形, 全形]
  - name: simplification
    states: [漢字, 汉字]

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

speller:
  alphabet: zyxwvutsrqponmlkjihgfedcba
  delimiter: " '"
  algebra:
    - erase/^xx$/
    - abbrev/^([a-z]).+$/$1/
    - abbrev/^([zcs]h).+$/$1/
    - derive/^([nl])ve$/$1ue/
    - derive/ui$/uei/
    - derive/iu$/iou/

translator:
  dictionary: my_pinyin
  enable_sentence: true
  enable_user_dict: true
  preedit_format:
    - xform/([nl])v/$1ü/
    - xform/([jqxy])v/$1u/

simplifier:
  option_name: simplification

punctuator:
  import_preset: default

key_binder:
  import_preset: default

recognizer:
  import_preset: default

menu:
  page_size: 5
```

對應詞庫 `my_pinyin.dict.yaml`：

```yaml
---
name: my_pinyin
version: "2024.01.01"
use_preset_vocabulary: true
...
你	ni
我	wo
他	ta
中文	zhong wen
```

### 形碼方案（table_translator）

```yaml
schema:
  schema_id: my_table
  name: 我的形碼
  version: "0.1"

switches:
  - name: ascii_mode
    reset: 0
    states: [中文, 西文]
  - name: full_shape
    states: [半形, 全形]

engine:
  processors:
    - ascii_composer
    - key_binder
    - speller
    - punctuator
    - selector
    - navigator
    - express_editor
  segmentors:
    - ascii_segmentor
    - abc_segmentor
    - punct_segmentor
    - fallback_segmentor
  translators:
    - punct_translator
    - table_translator
  filters:
    - uniquifier

speller:
  alphabet: zyxwvutsrqponmlkjihgfedcba
  max_code_length: 4
  auto_select: true

translator:
  dictionary: my_table
  enable_sentence: false
  enable_encoder: true
  encode_commit_history: true
  max_phrase_length: 4

punctuator:
  import_preset: default

key_binder:
  import_preset: default

menu:
  page_size: 5
```

---

## 常見錯誤

| 現象 | 原因 |
|------|------|
| 部署後方案不在列表中 | `default.yaml` 的 `schema_list` 未添加 |
| 候選為空 | `translator/dictionary` 名稱與 `dict.yaml` 的 `name` 不一致 |
| 詞庫未編譯（無 `.table.bin`） | 部署失敗，查看日誌 |
| YAML 解析錯誤 | 縮進使用了 Tab、冒號後缺少空格、字串未加引號 |
| 自定義 lua 不生效 | 函數名與 yaml 引用不一致，或文件不在用戶目錄 |
| packs 中詞語無法輸入 | pack 詞庫中缺少單字編碼（每個 pack 獨立編譯） |
