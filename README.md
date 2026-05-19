# Agent Skills

該倉庫提供 Rime 輸入法配置的 agent skills。Skill 遵循 [Agent Skills](https://agentskills.io/home) 格式。

⚠️ 該倉庫仍在建設中。

## 結構約定

每個 skill 的 `SKILL.md` 是短入口：說明何時使用、先檢查什麼、何時載入更詳細的資料。長篇參考內容放在一層 `references/` 目錄中，並由 `SKILL.md` 明確連結。UI metadata 放在 `agents/openai.yaml`。

驗證格式：

```sh
scripts/validate_skills.rb
```

## 提供的 Skill

### rime-workflow

Rime 配置任務的入口 skill：判斷問題屬於 schema、engine、Lua、plum、Weasel、部署或日誌哪一層。

### rime-gears

Rime engine 組件路由與查表：processors、segmentors、translators、filters、tags、候選 pipeline。

### rime-schema

建立與診斷 Rime schema：`schema.yaml`、`dict.yaml`、translator 選型、engine template、部署檢查。

### rime-spelling-algebra

Rime 拼寫運算：`xlit`、`xform`、`erase`、`derive`、`fuzz`、`abbrev`、Boost.Regex replacement。

### rime-lua

撰寫與除錯 Rime Lua 組件：`lua_processor`、`lua_segmentor`、`lua_translator`、`lua_filter`。附帶 `assets/librime.lua`。

### rime-plum

使用 plum（東風破）安裝、更新、批次部署或打包 Rime 方案。

### rime-weasel

Windows 小狼毫（Weasel）前端配置：`weasel.custom.yaml`、候選窗樣式、字體、配色、app options、方案安裝。
