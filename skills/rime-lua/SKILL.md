---
name: rime-lua
description: Describes how to write Rime Lua components (processor, segmentor, translator, filter). Covers component function signatures, lifecycle (init/fini/func), yield pattern, env object, notifier subscriptions, and common coding patterns. Use this when the user is writing or debugging lua_processor / lua_translator / lua_filter / lua_segmentor, or working with Rime Lua objects.
metadata:
  author: RimeInn
  version: 0.1.0
resources:
  - assets/librime.lua
---

# Rime Lua 組件開發

## 資源：librime.lua

`assets/librime.lua` 是供 [lua-language-server](https://github.com/LuaLS/lua-language-server) 使用的類型標注檔（`---@meta`），包含所有 Rime Lua 物件的類型定義，可提供完整的補全與型別檢查。

**本 skill 不重複 librime.lua 已記錄的類型資訊（屬性名稱、方法簽名等）**，請直接參照 librime.lua 或使用 LSP 查詢。

### 設定 lua-language-server

在專案根目錄的 `.luarc.json` 中加入：

```json
{
  "workspace.library": ["/path/to/skills/rime-lua/assets"]
}
```

或在 Neovim / VSCode 的 lua-language-server 設定中指定 `workspace.library`，指向 `assets/librime.lua` 所在目錄。

---

## 組件在 schema.yaml 中的引用語法

詳見 **rime-gears** skill 的 Lua 組件引用語法總覽，摘要如下：

```yaml
engine:
  processors:
    - lua_processor@func_name          # rime.lua 中的全域函數
    - lua_processor@*module_name       # lua/module_name.lua 模組
    - lua_processor@*module_name@ns    # 指定命名空間（可建立多個實例）
  translators:
    - lua_translator@*date_translator
  filters:
    - lua_filter@*my_filter
  segmentors:
    - lua_segmentor@*my_segmentor
```

---

## 組件函數規範

### 模組結構

模組可回傳**函數**（僅 func）或**帶生命週期的 table**（含 init/fini/func）：

```lua
-- 方式一：直接回傳函數（無初始化需求時）
local function translator(input, segment, env)
  -- ...
end
return translator

-- 方式二：回傳 table（需要 init/fini 或在 env 上儲存狀態）
local M = {}

function M.init(env)
  -- 在 env 上儲存跨呼叫的狀態
  env.config = env.engine.schema.config
  env.my_option = env.config:get_string("my_ns/option") or "default"
end

function M.fini(env)
  -- 清理（斷開 notifier 連線等）
  if env.conn then env.conn:disconnect() end
end

function M.func(...)
  -- 主邏輯
end

return M
```

- `init(env)` 與 `fini(env)` 均可選
- 狀態請儲存於 `env` 上，不要用模組級別的全域變數（多命名空間時各實例共用模組但各有自己的 `env`）
- `env.name_space` 為 yaml 中 `@ns` 指定的命名空間字串

---

### Processor

```lua
-- function(key_event: KeyEvent, env: Env) -> ProcessResult
function M.func(key_event, env)
  if key_event:repr() == "Return" and env.engine.context:is_composing() then
    env.engine.context:commit()
    return 1  -- kAccepted：消費此按鍵
  end
  return 2    -- kNoop：不處理，傳給下一個 processor
  -- return 0 -- kRejected：拒絕，傳回下層程序（OS）
end
```

回傳值語意：

| 值 | 常量 | 說明 |
|----|------|------|
| `0` | `kRejected` | 拒絕此鍵，傳回下層程序 |
| `1` | `kAccepted` | 接受並消費此鍵，後續 processor 不再收到 |
| `2` | `kNoop` | 忽略，傳給下一個 processor |

---

### Translator

```lua
-- function(input: string, segment: Segment, env: Env)
-- 透過 yield() 產生候選，無需回傳值
function M.func(input, segment, env)
  if input ~= "date" then return end

  local date = os.date("%Y-%m-%d")
  yield(Candidate("date", segment.start, segment._end, date, "今日日期"))
end
```

- `yield(cand)` 每次呼叫輸出一個候選，可呼叫多次
- `segment.start` 和 `segment._end` 標示此候選覆蓋的輸入範圍（`_end` 因 `end` 是 Lua 關鍵字而加底線）
- 若不產生任何候選，引擎會詢問下一個翻譯器

---

### Filter

```lua
-- function(input: Translation, env: Env)
-- 或（較新版本）function(input: Translation, cands: table, env: Env)
-- 透過 yield() 輸出處理後的候選
function M.func(input, env)
  for cand in input:iter() do
    if should_keep(cand) then
      -- 可直接傳遞、修改後傳遞，或跳過
      yield(cand)
    end
  end
  -- 也可在迭代完後 yield 額外候選
end
```

- `input:iter()` 回傳惰性迭代器，每次 `next()` 才從上游翻譯器取值
- 不 yield 某個候選即等於過濾掉它
- 可在 yield 前修改 `cand.comment`（直接賦值）
- 若要修改 text 或其他欄位，改用 `ShadowCandidate`

---

### Segmentor

```lua
-- function(segmentation: Segmentation, env: Env) -> boolean
function M.func(segmentation, env)
  -- 若對當前輸入位置不感興趣，回傳 true 繼續；回傳 false 停止分段
  local start = segmentation:get_current_start_position()
  local input = segmentation.input
  local seg_input = input:sub(start + 1)  -- Lua 字串從 1 開始，Rime 位置從 0 開始

  if #seg_input == 0 then return true end

  local seg = Segment(start, start + #seg_input)
  seg.tags:__set("my_tag")               -- 打上自定義 tag
  segmentation:add_segment(seg)
  return false                            -- 分段完成，停止
end
```

---

## env 物件

`env` 在 `init` 時由引擎建立，生命週期與組件實例一致：

| 欄位 | 說明 |
|------|------|
| `env.engine` | `Engine` 物件，可訪問 `schema`、`context` 等 |
| `env.name_space` | 此組件實例的命名空間（yaml 中 `@ns` 部分） |

自訂欄位可直接掛在 `env` 上（如 `env.cache = {}`），各實例互不干擾。

---

## 讀取 Schema 配置

```lua
function M.init(env)
  local config = env.engine.schema.config
  -- 讀取 schema.yaml 中的值
  local page_size = config:get_int("menu/page_size") or 5
  local my_str    = config:get_string("my_translator/option") or ""
  local flag      = config:get_bool("my_translator/enabled")  -- 可能為 nil

  -- 讀取列表
  local rules = config:get_list("speller/algebra")
  if rules then
    local proj = Projection(rules)
    env.proj = proj
  end
end
```

`config` 路徑使用 `/` 分隔，對應 yaml 的層級結構。

---

## Notifier 訂閱

Notifier 用於監聽引擎事件，需在 `fini` 中斷開連線以避免懸空引用。

```lua
function M.init(env)
  local ctx = env.engine.context

  -- 訂閱輸入更新事件
  env.conn = ctx.update_notifier:connect(function(ctx)
    -- ctx.input 已更新
    handle_update(ctx, env)
  end)

  -- 訂閱選項切換事件（option_update_notifier 回呼多一個 name 參數）
  env.opt_conn = ctx.option_update_notifier:connect(function(ctx, name)
    if name == "ascii_mode" then
      env.is_ascii = ctx:get_option("ascii_mode")
    end
  end)
end

function M.fini(env)
  env.conn:disconnect()
  env.opt_conn:disconnect()
end
```

可用的 notifier：

| 屬性 | 觸發時機 | 回呼簽名 |
|------|----------|----------|
| `commit_notifier` | 上屏時 | `fun(ctx)` |
| `select_notifier` | 選擇候選時 | `fun(ctx)` |
| `update_notifier` | 輸入串更新時 | `fun(ctx)` |
| `delete_notifier` | 刪除候選時 | `fun(ctx)` |
| `option_update_notifier` | 開關切換時 | `fun(ctx, name)` |
| `property_update_notifier` | property 變更時 | `fun(ctx, name)` |
| `unhandled_key_notifier` | 未處理按鍵時 | `fun(ctx, key)` |

`connect` 的第二參數 `group`（整數）控制同 group 的連線互相排斥（用於互斥監聽），一般省略。

---

## Candidate 類型選擇

| 類型 | 建構方式 | 適用場景 |
|------|----------|----------|
| `Candidate` | `Candidate(type, start, _end, text, comment)` | 通用簡單候選 |
| `ShadowCandidate` | `ShadowCandidate(cand, type?, text?, comment?, inherit_comment?)` | 基於已有候選衍生，修改部分欄位 |
| `UniquifiedCandidate` | `UniquifiedCandidate(cand, type?, text?, comment?)` | 需去重時使用 |
| `Phrase` | `Phrase(memory, type, start, _end, entry)` | 來自詞庫的候選，含詞頻資訊 |

`cand:get_dynamic_type()` 回傳 `"Sentence"` / `"Phrase"` / `"Simple"` / `"Shadow"` / `"Uniquified"` / `"Other"`，可用來判斷候選來源。

`cand:get_genuine()` 取得 Shadow/Uniquified 候選包裝的原始候選。

---

## Component 動態建立組件

在 Lua 中可動態建立內建 C++ 組件實例：

```lua
function M.init(env)
  -- 在當前引擎下建立一個 script_translator 實例
  env.translator = Component.ScriptTranslator(
    env.engine, env.name_space, "script_translator"
  )
end

function M.func(input, segment, env)
  local translation = env.translator:query(input, segment)
  if not translation then return end
  for cand in translation:iter() do
    yield(cand)
  end
end
```

`Component.Processor` / `Component.Segmentor` / `Component.Translator` / `Component.Filter` 亦可用於包裝任意已註冊的組件類別。

---

## Memory：詞庫查詢與使用者詞庫

```lua
function M.init(env)
  -- 使用當前 schema 的詞庫
  env.mem = Memory(env.engine, env.engine.schema)
  -- 監聽上屏事件，學習用戶輸入
  env.mem:memorize(function(commit_entry)
    for _, entry in ipairs(commit_entry:get()) do
      log.info("committed: " .. entry.text .. " " .. entry.custom_code)
    end
  end)
end

function M.func(input, segment, env)
  -- 查詢詞庫（predictive=false, limit=100）
  if env.mem:dict_lookup(input, false, 100) then
    for entry in env.mem:iter_dict() do
      local cand = Candidate("word", segment.start, segment._end,
                             entry.text, entry.comment)
      cand.quality = entry.weight
      yield(cand)
    end
  end
end

function M.fini(env)
  env.mem:disconnect()
end
```

---

## CommitHistory

`env.engine.context.commit_history` 記錄最近上屏的記錄，最多 **20 條**。

```lua
local history = env.engine.context.commit_history
local last = history:back()          -- CommitRecord | nil
if last then
  log.info(last.text .. " / " .. last.type)
end

-- 遍歷（由新到舊）
for i, record in history:iter() do
  log.info(i .. ": " .. record.text)
end
```

---

## Projection：拼寫運算

```lua
function M.init(env)
  local rules = env.engine.schema.config:get_list("translator/preedit_format")
  env.proj = Projection(rules)   -- 以 ConfigList 初始化
end

function M.func(input, segment, env)
  local display = env.proj:apply(input)  -- 按規則轉換字串
  -- ...
end
```

也可用空建構子再 `load`：
```lua
local proj = Projection()
proj:load(rules)
```

---

## 全局工具

| 物件/函數 | 說明 |
|-----------|------|
| `yield(cand)` | 在 translator/filter 中輸出一個候選 |
| `log.info(msg)` | 寫入 INFO 日誌（可用 `rime.INFO` 查看） |
| `log.warning(msg)` | 寫入 WARNING 日誌 |
| `log.error(msg)` | 寫入 ERROR 日誌 |
| `rime_api` | 取得版本、目錄、regex 工具等（見 librime.lua） |

---

## 常見範例

### 動態日期翻譯器

```lua
local function translator(input, segment, env)
  local map = {
    date = os.date("%Y-%m-%d"),
    time = os.date("%H:%M"),
    week = ({"日","一","二","三","四","五","六"})[tonumber(os.date("%w")) + 1],
  }
  local result = map[input]
  if result then
    yield(Candidate(input, segment.start, segment._end, result, ""))
  end
end

return translator
```

### 修改候選注釋的 Filter

```lua
local function filter(input, env)
  for cand in input:iter() do
    if cand.comment == "" then
      -- 不直接改 cand.comment（Candidate 欄位可能唯讀），用 ShadowCandidate
      yield(ShadowCandidate(cand, cand.type, cand.text, "[" .. cand.preedit .. "]"))
    else
      yield(cand)
    end
  end
end

return filter
```

### 讀取開關狀態的 Processor

```lua
local M = {}

function M.init(env)
  local ctx = env.engine.context
  env.ascii = ctx:get_option("ascii_mode")
  env.conn = ctx.option_update_notifier:connect(function(ctx, name)
    if name == "ascii_mode" then
      env.ascii = ctx:get_option("ascii_mode")
    end
  end)
end

function M.fini(env)
  env.conn:disconnect()
end

function M.func(key_event, env)
  if env.ascii then return 2 end  -- 英文模式下不處理
  -- 其他邏輯...
  return 2
end

return M
```

### 使用 LevelDb 持久化自訂資料

```lua
function M.init(env)
  env.db = LevelDb("my_plugin_data")
  env.db:open()
end

function M.fini(env)
  env.db:close()
end

function M.func(input, segment, env)
  local value = env.db:fetch("key:" .. input)
  if value then
    yield(Candidate("db", segment.start, segment._end, value, ""))
  end
end
```
