---
name: rime-gears
description: Describes all built-in processors, segmentors, translators, and filters in Rime. Use this when configuring or debugging Rime engine components.
metadata:
  author: RimeInn
  version: 0.1.0
---

# Rime 內建組件（Gears）說明

Rime 引擎的各類組件在 `schema.yaml` 中以列表方式配置：

```yaml
engine:
  processors:
    - ascii_composer
    - speller
    ...
  segmentors:
    - ascii_segmentor
    - abc_segmentor
    ...
  translators:
    - table_translator
    ...
  filters:
    - simplifier
    ...
```

---

## 處理器（Processors）

處理器依序接收鍵盤事件（KeyEvent），每個處理器回傳 `kAccepted`、`kRejected` 或 `kNoop`。

### `ascii_composer`

管理 ASCII 模式（西文模式）的切換。

**配置節點：** `ascii_composer`

| 選項 | 說明 |
|------|------|
| `good_old_caps_lock` | `true` 時 CapsLock 保持傳統大寫鎖定行為（不切換輸入法模式） |
| `switch_key` | 切換鍵與切換行為的對應表，可用鍵名為 `Caps_Lock`、`Shift_L`、`Shift_R` 等 |

`switch_key` 的值（切換行為）：

| 值 | 說明 |
|----|------|
| `inline_ascii` | 暫時切換為西文模式，上屏後恢復 |
| `commit_text` | 提交當前已選候選後切換 |
| `commit_code` | 提交原始輸入碼後切換 |
| `clear` | 清空輸入串後切換 |
| `set_ascii_mode` | 強制切換到西文模式（不切換回） |
| `unset_ascii_mode` | 強制切換到中文模式（不切換回） |

**範例：**
```yaml
ascii_composer:
  good_old_caps_lock: true
  switch_key:
    Caps_Lock: clear
    Shift_L: inline_ascii
    Shift_R: commit_text
```

---

### `chord_composer`

和絃輸入處理器，支援多鍵同時按下後作為一組輸入（如注音鍵盤）。

**配置節點：** `chord_composer`

| 選項 | 說明 |
|------|------|
| `alphabet` | 參與和絃的按鍵集合（字串） |
| `algebra` | 拼寫運算規則，將和絃按鍵組合轉換為輸入串 |
| `output_format` | 輸出格式運算規則 |
| `prompt_format` | 輸入提示格式運算規則 |
| `use_control` | 是否允許 Ctrl 參與和絃，預設 `false` |
| `use_alt` | 是否允許 Alt 參與和絃，預設 `false` |
| `use_shift` | 是否允許 Shift 參與和絃，預設 `false` |
| `use_super` | 是否允許 Super 參與和絃，預設 `false` |
| `use_caps` | 是否允許 CapsLock 參與和絃，預設 `false` |
| `finish_chord_on_first_key_release` | 第一個鍵釋放時即完成和絃，預設 `false` |
| `bindings` | 快捷鍵綁定（可綁定 `commit_raw_input` 等動作） |

---

### `express_editor`

簡易編輯器。空白鍵上屏選中候選，Enter 鍵提交原始輸入碼，Backspace 刪除一個字元。不支援自動上屏（`_auto_commit = false`）。通常用於形碼等需要手動確認的方案。

支援以下動作（可透過 `express_editor/bindings` 自訂按鍵綁定）：

- `confirm`：上屏選中候選
- `toggle_selection`：切換候選選中狀態
- `commit_comment`：提交候選的注釋
- `commit_raw_input`：提交原始輸入碼
- `commit_script_text`：提交拼音文字
- `commit_composition`：提交整個組合
- `revert`：撤回上一次編輯
- `back`：退回到前一個輸入
- `back_syllable`：退回到前一個音節
- `delete_candidate`：刪除選中候選（從用戶詞庫中刪除）
- `delete`：刪除一個字元
- `cancel`：取消當前輸入

---

### `fluid_editor`（別名：`fluency_editor`）

流式編輯器。空白鍵作為分隔符加入輸入串（不立即上屏），Enter 鍵才提交整個組合。適用於連續輸入再統一上屏的方案（如整句輸入）。啓用 `_auto_commit = true`。

支援的動作與 `express_editor` 相同，可透過 `editor/bindings` 自訂。

---

### `key_binder`

按鍵重綁定處理器。可在特定條件下，將某個按鍵重新映射為另一個按鍵或動作。

**配置節點：** `key_binder`

| 選項 | 說明 |
|------|------|
| `import_preset` | 導入預設按鍵配置（如 `default`），再在 `bindings` 中覆蓋或補充 |
| `bindings` | 綁定規則列表 |

每條綁定規則：
```yaml
- { when: <條件>, accept: <輸入鍵>, send: <目標鍵> }
# 或發送按鍵序列：
- { when: <條件>, accept: <輸入鍵>, send_sequence: "<序列>" }
# 或切換開關（toggle true/false）：
- { when: <條件>, accept: <輸入鍵>, toggle: <選項名> }
# 或強制設為 true：
- { when: <條件>, accept: <輸入鍵>, set_option: <選項名> }
# 或強制設為 false：
- { when: <條件>, accept: <輸入鍵>, unset_option: <選項名> }
# 或選擇某個 radio 選項：
- { when: <條件>, accept: <輸入鍵>, select: <選項名> }
```

`when` 條件：

| 值 | 說明 |
|----|------|
| `always` | 始終生效 |
| `composing` | 有輸入串時 |
| `has_menu` | 有候選時 |
| `paging` | 已翻頁時 |
| `predicting` | 預測候選時 |

---

### `navigator`

光標移動處理器，處理在輸入串中移動光標的按鍵（方向鍵、Home、End 等）。

無額外配置選項。

---

### `punctuator`

標點符號處理器，將單個按鍵映射到標點符號或文字。

**配置節點：** `punctuator`

| 選項 | 說明 |
|------|------|
| `import_preset` | 導入預設標點配置（如 `default`），再在本節點覆蓋 |
| `half_shape` | 半形標點映射表（map） |
| `full_shape` | 全形標點映射表（map） |
| `symbols` | 額外符號映射表（map），在兩種形狀均查詢 |
| `use_space` | 空白鍵是否參與標點映射，預設 `false` |
| `digit_separators` | 數字分隔符字元集（如 `.,`），在數字後輸入這些字元時直接提交 |
| `digit_separator_action` | `commit` 表示直接提交數字分隔符 |

映射值可以是：
- 字串：直接輸出
- 列表：循環切換（每次輸入同一鍵輸出不同值）
- `{pair: [開, 閉]}`：交替輸出開/閉括號

**範例：**
```yaml
punctuator:
  half_shape:
    ",": "，"
    ".": "。"
    "?": "？"
    "!": "！"
    "'": {pair: ["'", "'"]}
    '"': {pair: [""", """]}
```

---

### `recognizer`

識別器，根據正則表達式模式識別輸入串是否符合特定模式（如 URL、反查前綴），並設置對應 tag 供後續分段器使用。

**配置節點：** `recognizer`

| 選項 | 說明 |
|------|------|
| `import_preset` | 導入預設模式（如 `default`），再在本節點補充或覆蓋 |
| `patterns` | 模式名稱到正則表達式的映射，模式名稱即 tag 名稱 |
| `use_space` | 是否允許空白鍵參與識別，預設 `false` |

**範例：**
```yaml
recognizer:
  patterns:
    email: "^[a-z][-_.0-9a-z]*@.*$"
    url: "^(www[.]|https?:|ftp[.:|]|mailto:|file:).*$"
    reverse_lookup: "`[a-z]*'?$"
```

---

### `selector`

候選選擇器，處理數字選擇鍵和候選翻頁按鍵。

**配置節點：** `selector`（可透過 `bindings` 自訂按鍵）

支援的動作：
- `previous_candidate`：選擇上一個候選
- `next_candidate`：選擇下一個候選
- `previous_page`：向前翻頁
- `next_page`：向後翻頁
- `home`：跳至第一頁
- `end`：跳至最後一頁

---

### `speller`

拼寫處理器，接受字母按鍵並加入輸入串，支援自動上屏、自動清空等功能。

**配置節點：** `speller`

| 選項 | 說明 |
|------|------|
| `alphabet` | 參與拼寫的字元集，預設為 `zyxwvutsrqponmlkjihgfedcba` |
| `initials` | 可作為音節首字的字元集，預設與 `alphabet` 相同 |
| `finals` | 韻母字元集，用於判斷是否期待聲母 |
| `delimiter` | 音節分隔符，如 `" '"` |
| `max_code_length` | 最大輸入碼長度，到達此長度後自動上屏（形碼用） |
| `auto_select` | 候選唯一時是否自動上屏，預設 `false` |
| `auto_select_pattern` | 自動上屏的輸入碼正則模式（優先於 `max_code_length`） |
| `use_space` | 空白鍵是否加入輸入串，預設 `false` |
| `auto_clear` | 無候選時的自動清空行為：`auto`（自動清空）、`manual`（僅在下一個按鍵為聲母時清空）、`max_length`（達到最大碼長後清空） |

---

### `shape_processor`

字形處理器，處理全形/半形切換相關的按鍵事件。通常與 `shape_formatter` 搭配使用。無額外配置選項。

---

### `lua_processor`

Lua 自訂處理器，由 librime-lua 插件提供。在 `engine/processors` 中以 `lua_processor@` 語法引用 Lua 函數或模組。

```yaml
engine:
  processors:
    - lua_processor@my_processor          # 引用 rime.lua 中的 my_processor 函數
    - lua_processor@*my_processor         # 引用 lua/my_processor.lua 模組
    - lua_processor@*my_processor@ns      # 同上，並指定命名空間為 ns
```

---

## 分段器（Segmentors）

分段器將輸入串劃分為若干 segment，並為每個 segment 打上 tag，供翻譯器識別。

### `abc_segmentor`

標準分段器，將輸入串中尚未分段的部分打上 `abc` tag。

**配置節點：** `abc_segmentor`

| 選項 | 說明 |
|------|------|
| `extra_tags` | 在 `abc` tag 之外額外附加的 tag 列表 |

---

### `affix_segmentor`

前後綴分段器，識別帶有特定前綴（和可選後綴）的輸入段，並打上自定義 tag。適用於反查、副翻譯等場景。

**配置節點：** 使用者自訂（通常與對應翻譯器同名，如 `reverse_lookup`）

| 選項 | 說明 |
|------|------|
| `tag` | 要打上的 tag 名稱（預設 `abc`） |
| `prefix` | 前綴字串（如 `` ` ``） |
| `suffix` | 後綴字串（如 `'`），可選 |
| `tips` | 輸入提示文字（顯示於前綴段） |
| `closing_tips` | 後綴段的提示文字，預設與 `tips` 相同 |
| `extra_tags` | 額外附加的 tag 列表 |

**範例：**
```yaml
reverse_lookup:
  tag: reverse_lookup
  prefix: "`"
  suffix: "'"
  tips: 〔反查〕
  closing_tips: 〔反查完畢〕
  extra_tags: [abc]
```

---

### `ascii_segmentor`

西文分段器，在 ASCII 模式下將整個輸入串打上 `raw` tag，直接提交。

無額外配置選項。

---

### `matcher`

模式匹配分段器，與 `recognizer` 配合，將符合正則模式的輸入段打上對應的 tag。

無額外配置選項（模式在 `recognizer` 中配置）。

---

### `punct_segmentor`

標點分段器，將被 `punctuator` 識別為標點的輸入打上 `punct` tag。

無額外配置選項。

---

### `fallback_segmentor`

後備分段器，將所有尚未分段的輸入打上 `raw` tag，通常放在分段器列表的最後。

無額外配置選項。

---

### `lua_segmentor`

Lua 自訂分段器，由 librime-lua 插件提供。

```yaml
engine:
  segmentors:
    - lua_segmentor@my_segmentor          # 引用 rime.lua 中的 my_segmentor 函數
    - lua_segmentor@*my_segmentor         # 引用 lua/my_segmentor.lua 模組
    - lua_segmentor@*my_segmentor@ns      # 同上，並指定命名空間為 ns
```

---

## 翻譯器（Translators）

翻譯器接收帶 tag 的輸入段，回傳候選列表（Translation）。

### `echo_translator`

回聲翻譯器，當其他翻譯器無法產生候選時，將輸入碼本身作為唯一候選輸出。

**配置節點：** `translator`（或自訂命名空間）

| 選項 | 說明 |
|------|------|
| `tag` | 響應的 tag，預設 `raw` |

---

### `punct_translator`

標點翻譯器，將 `punct` tag 的輸入段翻譯為標點符號候選。標點映射在 `punctuator` 節點配置。

無額外配置選項。

---

### `table_translator`

碼表翻譯器，用於形碼（倉頡、五筆等）等查表式輸入法。讀取預編譯詞典（`.table.bin`）和用戶詞典。

**配置節點：** `translator`（或自訂命名空間）

**通用翻譯器選項（`TranslatorOptions`）：**

| 選項 | 說明 |
|------|------|
| `tag` | 響應的 tag（預設 `abc`），支援列表 `tags` |
| `dictionary` | 詞典名稱（對應 `dict.yaml` 的 `name`） |
| `prism` | 棱鏡（拼寫索引）名稱，預設與 `dictionary` 相同。多個方案共用同一詞庫但有各自拼寫規則時，可指定不同的 prism |
| `user_dict` | 用戶詞典名稱，預設與 `dictionary` 相同；設為 `false` 停用 |
| `db_class` | 用戶詞典的數據庫類型（`stabledb` 或 `userdb`） |
| `enable_completion` | 啓用補全候選，預設 `true` |
| `strict_spelling` | 嚴格拼寫（不允許補全），預設 `false` |
| `contextual_suggestions` | 啓用上下文感知候選排序，預設 `false` |
| `initial_quality` | 候選的初始質量分偏移，預設 `0`。調高可使此翻譯器的候選排在其他翻譯器之前 |
| `max_sentences` | 最大整句候選數，預設 `1`。設為大於 `1` 時，建議同時將 `script_translator` 的 `max_homophones` 調大（如 `8`），效果更佳 |
| `delimiter` | 音節分隔符，預設從 `speller/delimiter` 讀取 |
| `preedit_format` | 輸入框中顯示的文字格式（拼寫運算列表） |
| `comment_format` | 候選注釋的格式（拼寫運算列表） |
| `disable_user_dict_for_patterns` | 符合這些正則的輸入碼不使用用戶詞典 |
| `packs` | 附加詞庫包名稱列表（字串列表），在主詞典之外額外載入對應的 `.table.bin`，可選，缺失時靜默忽略 |

> **`packs` 注意事項：** 每個 pack 的 `.table.bin` 是獨立編譯的，編譯時不依賴主詞典。因此每個 pack 的詞庫中**必須包含單字的編碼**，否則整句模式無法為 pack 中的詞語拼出正確的音節切分，導致詞語無法被輸入。

**`table_translator` 特有選項：**

| 選項 | 說明 |
|------|------|
| `enable_charset_filter` | 啓用字集過濾，預設 `false` |
| `enable_sentence` | 啓用整句模式，預設 `true` |
| `sentence_over_completion` | 整句候選優先於補全，預設 `false` |
| `enable_encoder` | 啓用自動造詞編碼，預設 `false` |
| `encode_commit_history` | 根據上屏歷史自動造詞，預設 `true`（需 `enable_encoder`） |
| `max_phrase_length` | 自動造詞的最大詞語長度，預設 `5` |
| `max_homographs` | 最大同碼異字數，預設 `1` |

---

### `script_translator`（別名：`r10n_translator`）

音節翻譯器，用於拼音、粵拼等拼讀式輸入法。支援音節拆分、整句翻譯。

**配置節點：** `translator`（或自訂命名空間）

繼承所有 `TranslatorOptions` 選項，並額外支援：

| 選項 | 說明 |
|------|------|
| `spelling_hints` | 在候選注釋中顯示拼音提示的最大字數，預設 `0`（不顯示） |
| `always_show_comments` | 即使只有一個候選也顯示注釋，預設 `false` |
| `max_homophones` | 每個音節保留的最大同音字數，預設 `1`。整句模式下建議調大（如 `8`） |
| `enable_correction` | 啓用輸入糾錯（容錯拼寫），預設 `false`。啓用後部署時會額外編譯 corrector 資料 |
| `enable_word_completion` | 啓用詞語補全（輸入不完整時補全詞語），預設同 `enable_completion` |

---

### `history_translator`

歷史翻譯器，將最近上屏的詞語作為候選輸出（重複上一次輸入）。

**配置節點：** `history`（或自訂命名空間）

| 選項 | 說明 |
|------|------|
| `tag` | 響應的 tag，預設 `abc` |
| `input` | 觸發歷史候選的特定輸入串（如 `z`），必須設定，否則不輸出候選 |
| `size` | 最多輸出的歷史候選數，預設 `1` |
| `initial_quality` | 候選的初始質量分，預設 `1000` |

**範例：**
```yaml
history:
  input: z
  size: 3
  initial_quality: 1000
```

---

### `reverse_lookup_translator`

反查翻譯器，將帶有反查 tag 的輸入段，以另一個方案的字音來查詢漢字。

**配置節點：** 通常自訂（如 `reverse_lookup`），也可從 `translator` 讀取

| 選項 | 說明 |
|------|------|
| `tag` | 響應的 tag，如 `reverse_lookup` |
| `dictionary` | 用於反查的詞典名稱 |
| `overwrite_comment` | 覆寫候選的注釋，預設 `false` |
| `comment_format` | 注釋格式的拼寫運算列表 |
| `preedit_format` | 輸入框顯示格式 |

---

### `schema_list_translator`

方案列表翻譯器，在方案切換介面中輸出可切換的方案候選。通常在 switcher 中使用。

無需用戶配置。

---

### `switch_translator`

開關翻譯器，輸出當前可切換的選項（如繁/簡、全形/半形等）作為候選，允許用戶透過選擇候選來切換選項。通常與 switcher 搭配使用。

無需用戶配置。

---

### `lua_translator`

Lua 自訂翻譯器，由 librime-lua 插件提供。常用於輸出動態內容（日期、時間、計算結果等）。

```yaml
engine:
  translators:
    - lua_translator@my_translator        # 引用 rime.lua 中的 my_translator 函數
    - lua_translator@*date_translator     # 引用 lua/date_translator.lua 模組
    - lua_translator@*date_translator@dt  # 同上，並指定命名空間為 dt
    - lua_translator@*date/translator     # 引用 lua/date/translator.lua（子目錄）
    - lua_translator@*mod*subtable@ns     # 引用模組內 Lua table 中的子元素
```

---

## 過濾器（Filters）

過濾器接收翻譯器的輸出（Translation），對候選進行篩選、重排或加工。

### `simplifier`

字形轉換過濾器，使用 OpenCC 將候選文字轉換字形（如繁→簡、簡→繁、臺灣用字等）。

**配置節點：** `simplifier`（或自訂命名空間）

| 選項 | 說明 |
|------|------|
| `opencc_config` | OpenCC 配置文件名（如 `t2s.json`、`s2t.json`、`t2tw.json`） |
| `option_name` | 控制此過濾器開關的選項名稱，預設 `simplification` |
| `tips` | 在注釋中顯示原字的程度：`none`（不顯示）、`char`（僅單字）、`all`（全部） |
| `show_in_comment` | 轉換結果放在注釋而非主文字，預設 `false` |
| `inherit_comment` | 繼承原候選的注釋，預設 `true` |
| `comment_format` | 注釋格式的拼寫運算列表 |
| `excluded_types` | 不進行轉換的候選類型列表（如 `["punct"]`） |
| `random` | 從多個轉換結果中隨機選擇，預設 `false` |
| `tags` | 只對這些 tag 的候選進行轉換 |

常用的 OpenCC 配置文件：

| 文件 | 轉換方向 |
|------|------|
| `t2s.json` | 繁體→簡體 |
| `s2t.json` | 簡體→繁體 |
| `t2tw.json` | 繁體→臺灣正體 |
| `t2hk.json` | 繁體→香港繁體 |
| `s2tw.json` | 簡體→臺灣正體 |
| `s2hk.json` | 簡體→香港繁體 |

**範例：**
```yaml
simplifier:
  opencc_config: t2s.json
  option_name: simplification
  tips: char
```

---

### `uniquifier`

去重過濾器，移除候選列表中文字相同的重複候選（保留第一個出現的）。通常放在過濾器列表的最後。

無配置選項。

---

### `charset_filter`（別名：`cjk_minifier`）

字集過濾器，過濾掉包含 CJK 擴展區（Extension A/B/C/D/E/F/G/H/I/J 及相容漢字區）字符的候選。用於限制輸出為基本 CJK 字符範圍（U+4E00–U+9FFF）。

無配置選項。

> 注意：`cjk_minifier` 為 `charset_filter` 的別名，功能相同。

---

### `reverse_lookup_filter`

反查注釋過濾器，為候選附加另一個字音方案的讀音作為注釋。比 `reverse_lookup_translator` 更靈活，可附加到任意 tag 的候選上。

**配置節點：** `reverse_lookup`（或自訂命名空間）

| 選項 | 說明 |
|------|------|
| `dictionary` | 用於反查的詞典名稱 |
| `overwrite_comment` | 以反查結果覆寫原注釋，預設 `false` |
| `append_comment` | 在原注釋後附加反查結果，預設 `false`（預設是前置） |
| `comment_format` | 注釋格式的拼寫運算列表 |
| `tags` | 只對這些 tag 的候選進行反查 |

---

### `single_char_filter`

單字優先過濾器，將 `table` 和 `user_table` 類型候選中的單字排在詞語之前。

無配置選項。

---

### `lua_filter`

Lua 自訂過濾器，由 librime-lua 插件提供。

```yaml
engine:
  filters:
    - lua_filter@my_filter                # 引用 rime.lua 中的 my_filter 函數
    - lua_filter@*my_filter               # 引用 lua/my_filter.lua 模組
    - lua_filter@*my_filter@ns            # 同上，並指定命名空間為 ns
```

---

## 選單（Menu）

選單選項配置於方案頂層的 `menu` 節點，影響候選頁面的行為。

| 選項 | 說明 |
|------|------|
| `page_size` | 每頁候選數，預設 `5`，最小值 `1` |
| `alternative_select_keys` | 自訂選字鍵，長度須與 `page_size` 一致（如 `asdfghjkl`） |
| `page_down_cycle` | 翻到最後一頁後再按翻頁是否循環回第一頁，預設 `false` |

---

## 格式化器（Formatters）

### `shape_formatter`

字形格式化器，根據 `full_shape` 選項將輸出文字轉換為全形或半形。通常與 `shape_processor` 搭配使用。

無需用戶配置。

---

## Lua 組件引用語法總覽

由 librime-lua 插件提供，適用於所有四類 Lua 組件（`lua_processor`、`lua_segmentor`、`lua_translator`、`lua_filter`）。

### 引用方式

| 語法 | 說明 |
|------|------|
| `lua_xxx@func_name` | 引用 `rime.lua` 中定義的全域函數 `func_name` |
| `lua_xxx@*module_name` | 引用 `lua/module_name.lua`，模組須 `return` 組件函數 |
| `lua_xxx@*module_name@ns` | 同上，並以 `ns` 作為命名空間（可建立多個實例） |
| `lua_xxx@*dir/module` | 引用子目錄下的模組 `lua/dir/module.lua` |
| `lua_xxx@*mod*table*func@ns` | 引用模組回傳的 Lua table 中的子元素 `table.func` |

### 模組檔案結構

```
用戶資料目錄/
├── rime.lua            # 全域函數定義（舊式寫法）
└── lua/
    ├── date_translator.lua   # 模組寫法，須 return 組件
    └── mylib/
        └── helper.lua
```

模組寫法範例（`lua/date_translator.lua`）：

```lua
local function translator(input, seg)
  -- 實作內容
end
return translator
```

若模組匯出多個組件，可回傳 table：

```lua
return { translator = ..., filter = ... }
```

在 yaml 中以 `*module*translator` 引用 table 中的 `translator` 欄位。
