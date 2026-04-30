# Agent Skills

該倉庫提供 RIME 輸入法配置的 agent skills。Skill 遵循 [Agent Skills]() 格式。

⚠️ 該倉庫仍在建設中。

## 提供的 Skill

### rime-workflow

Rime 配置的基礎知識。

### rime-gears

說明 Rime 引擎所有內建處理器（processors）、分段器（segmentors）、翻譯器（translators）及過濾器（filters）的功能與配置選項。

### rime-weasel

說明小狼毫（Weasel）Windows 前端的配置，包含 `weasel.yaml` 所有選項、佈局、配色方案、字體語法、按應用/方案覆蓋外觀，以及方案安裝方法。

### rime-spelling-algebra

說明 Rime 拼寫運算的所有操作符（xlit、xform、erase、derive、fuzz、abbrev）及替換字串中的 Boost Regex 特殊序列（`\u`、`\U`、`\L` 等），附帶範例。

### rime-schema

說明如何從零創建 Rime 輸入方案，涵蓋 `schema.yaml` 完整結構、元數據、switches、引擎組件、speller、translator、dict.yaml 格式，以及拼音類和形碼類方案的完整範例。

### rime-lua

說明如何撰寫 Rime Lua 組件（processor、segmentor、translator、filter），涵蓋組件函數規範、生命週期（init/fini/func）、yield 模式、env 物件、notifier 訂閱，以及常見使用範例。附帶 `assets/librime.lua`（lua-language-server 類型標注檔）。


