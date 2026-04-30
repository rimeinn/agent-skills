---
name: rime-weasel
description: Describes Weasel (小狼毫), the Rime frontend for Windows. Covers weasel.yaml configuration, style options, layout, color schemes, font syntax, app-specific options, per-schema style overrides, and schema installation.
metadata:
  author: RimeInn
  version: 0.1.0
---

# 小狼毫（Weasel）Windows 前端說明

小狼毫是 Rime 在 Windows 上的前端實現。用戶可透過 `weasel.yaml` 控制外觀與行為，並透過 `weasel.custom.yaml` 覆蓋設定。

## 目錄結構

| 目錄 | 說明 |
|------|------|
| `%APPDATA%\Rime\` | 用戶配置目錄（方案、自訂 yaml、用戶詞典） |
| `%ProgramFiles%\Rime\weasel-*\data\` | 共享數據目錄（預設方案、weasel.yaml 預設值） |
| `%TEMP%\rime.weasel\` | 日誌目錄（`rime.INFO`、`rime.WARNING`、`rime.ERROR`） |

修改 `weasel.yaml` 後需在系統托盤右鍵選擇「重新部署」（或「重啓服務」）才能生效。

---

## `weasel.yaml` 頂層結構

```yaml
config_version: "0.25"   # 配置版本，低於預設版本時預設值覆蓋用戶設定
app_options:             # 按應用程式設定選項
  <進程名.exe>:
    ascii_mode: true
    ...
style:                   # 全域外觀設定
  ...
preset_color_schemes:    # 預設配色方案
  <方案代號>:
    ...
```

> `config_version` 的作用：預設 `weasel.yaml` 中若版本號較新，會以預設值覆蓋用戶的舊設定。升級後如發現設定被重置，需確認版本號。

---

## `app_options`

針對特定應用程式設定行為，鍵為**進程名（含 `.exe`，小寫）**。

```yaml
app_options:
  cmd.exe:
    ascii_mode: true        # 啓動時預設 ASCII 模式
  nvim-qt.exe:
    ascii_mode: true
    vim_mode: true          # Vim 模式：Normal/Visual 模式下自動切 ASCII
  firefox.exe:
    inline_preedit: true    # 覆蓋全域 inline_preedit 設定
```

可用選項：

| 選項 | 說明 |
|------|------|
| `ascii_mode` | 該應用程式啓動時預設進入 ASCII 模式 |
| `vim_mode` | 啓用 Vim 模式感知（Normal/Visual 時自動 ASCII） |
| `inline_preedit` | 覆蓋全域 inline_preedit 設定 |

---

## `style` 全域外觀

### 基本選項

| 選項 | 預設值 | 說明 |
|------|--------|------|
| `color_scheme` | `aqua` | 使用的配色方案代號 |
| `color_scheme_dark` | — | 系統深色模式時使用的配色方案代號 |
| `inline_preedit` | `false` | 是否將輸入串顯示在應用程式文字框內（而非候選窗） |
| `preedit_type` | `composition` | 輸入串顯示內容：`composition`（待選串）或 `preview`（預覽上屏文字） |
| `horizontal` | `false` | 候選列表水平排列（`true`）或垂直排列（`false`） |
| `vertical_text` | `false` | 垂直文字模式（配合豎排文字輸入） |
| `vertical_text_left_to_right` | `false` | 垂直文字由左至右排列 |
| `vertical_text_with_wrap` | `false` | 垂直文字自動換行 |
| `vertical_auto_reverse` | `false` | 垂直候選列表在游標靠近螢幕底部時自動反向 |
| `fullscreen` | `false` | 全螢幕候選視窗 |
| `display_tray_icon` | `false` | 顯示系統托盤圖示（部分版本已移除） |
| `antialias_mode` | `default` | 字體反鋸齒模式：`default`、`cleartype`、`grayscale`、`aliased` |
| `ascii_tip_follow_cursor` | `false` | ASCII 模式切換提示跟隨游標位置 |

### 字體選項

| 選項 | 預設值 | 說明 |
|------|--------|------|
| `font_face` | `Microsoft YaHei` | 主字體，見下方字體語法 |
| `font_point` | `14` | 主字體大小（pt） |
| `label_font_face` | `Microsoft YaHei` | 候選序號字體 |
| `label_font_point` | `14` | 候選序號字體大小 |
| `comment_font_face` | `Microsoft YaHei` | 注釋字體 |
| `comment_font_point` | `14` | 注釋字體大小 |

### 候選顯示選項

| 選項 | 預設值 | 說明 |
|------|--------|------|
| `label_format` | `"%s."` | 候選序號格式，`%s` 為序號本身 |
| `mark_text` | `""` | 選中候選的標記文字（顯示於候選左側） |
| `candidate_abbreviate_length` | `0` | 候選文字截斷長度，`0` 表示不截斷 |
| `hover_type` | `none` | 滑鼠懸停效果：`none`、`hilite`（整行高亮）、`semi_hilite`（部分高亮） |
| `paging_on_scroll` | `false` | 滑鼠滾輪是否翻頁 |
| `click_to_capture` | `false` | 點擊候選視窗是否截取（某些場景下防止視窗消失） |
| `global_ascii` | `false` | ASCII 模式是否影響所有視窗（而非僅當前視窗） |
| `show_notifications` | `true` | 是否顯示狀態切換通知（如「中文」「西文」） |
| `show_notifications_time` | `1200` | 通知顯示時長（毫秒） |

### `layout` 佈局子節點

所有間距單位為像素。

| 選項 | 預設值 | 說明 |
|------|--------|------|
| `min_width` | `160` | 候選視窗最小寬度 |
| `max_width` | `0` | 候選視窗最大寬度（`0` 不限） |
| `min_height` | `0` | 候選視窗最小高度 |
| `max_height` | `0` | 候選視窗最大高度（`0` 不限） |
| `border_width` | `3` | 視窗邊框寬度（也可用 `border` 作為別名） |
| `margin_x` | `12` | 水平內邊距 |
| `margin_y` | `12` | 垂直內邊距 |
| `spacing` | `10` | 輸入串與候選列表之間的間距 |
| `candidate_spacing` | `5` | 候選項之間的間距 |
| `hilite_spacing` | `4` | 序號與候選文字之間的間距 |
| `hilite_padding` | `2` | 高亮區域的內邊距（同時設定 x/y） |
| `hilite_padding_x` | — | 高亮區域水平內邊距（覆蓋 `hilite_padding`） |
| `hilite_padding_y` | — | 高亮區域垂直內邊距（覆蓋 `hilite_padding`） |
| `round_corner` | `4` | 高亮區域的圓角半徑 |
| `corner_radius` | `4` | 視窗整體的圓角半徑 |
| `shadow_radius` | `0` | 視窗陰影半徑（`0` 無陰影） |
| `shadow_offset_x` | `4` | 陰影水平偏移 |
| `shadow_offset_y` | `4` | 陰影垂直偏移 |
| `linespacing` | `0` | 額外行距（垂直候選模式） |
| `baseline` | `0` | 基線偏移（調整文字垂直對齊） |
| `align_type` | `center` | 序號與文字的垂直對齊方式：`top`、`center`、`bottom` |

---

## 字體語法

`font_face`（以及 `label_font_face`、`comment_font_face`）支援複合字體語法，以逗號分隔多個字體群組，依序作為後備。

```
字體名 [: 起始碼位] [: 結束碼位] [: 字重] [: 字形], 字體名2 ...
```

- **碼位**：十六進位 Unicode 碼位（如 `0x4E00`），指定此字體生效的字元範圍
- **字重**（僅第一組）：`thin`、`extra_light`、`light`、`semi_light`、`medium`、`semi_bold`、`bold`、`extra_bold`、`black` 等
- **字形**（僅第一組）：`italic`、`oblique`、`normal`

```yaml
# 範例：中文用微軟正黑、Emoji 用 Segoe UI Emoji、其餘用 Consolas
font_face: "Microsoft JhengHei : 0x4E00 : 0x9FFF, Segoe UI Emoji : 0x1F000 : 0x1FFFF, Consolas"

# 範例：加粗半黑體，後備微軟雅黑
font_face: "Source Han Sans SC : bold, Microsoft YaHei"
```

> 需使用字體的**字族名（Family Name）**，可從 Word 等軟體的字體選擇框取得。部分製作粗糙的字體即使設定正確也可能無法正常顯示。

---

## 配色方案

### 定義位置

在 `weasel.yaml`（或 `weasel.custom.yaml`）的 `preset_color_schemes` 下新增：

```yaml
preset_color_schemes:
  my_theme:
    name: "我的主題／My Theme"
    author: "作者名"
    color_format: abgr          # 可選：abgr（預設）、argb、rgba
    # 各色彩鍵見下表
```

### 顏色格式

| 格式 | 排列 | 範例 |
|------|------|------|
| `abgr`（預設） | `0xAABBGGRR` | `0xFFfa3a0a` |
| `argb` | `0xAARRGGBB` | `0xFF0a3afa` |
| `rgba` | `0xRRGGBBAA` | `0x0a3afaFF` |

Alpha `0x00` = 完全透明，`0xFF` = 完全不透明。未指定 `color_format` 時預設 `abgr`。

### 色彩鍵

以下前綴區域可與基礎色彩鍵組合：

| 區域前綴 | 說明 |
|----------|------|
| （無前綴） | 整個候選視窗的預設值 |
| `candidate_` | 未選中候選項 |
| `hilited_` | 高亮的輸入串（preedit） |
| `hilited_candidate_` | 當前選中的候選項 |

基礎色彩鍵：

| 色彩鍵 | 說明 |
|--------|------|
| `text_color` | 主文字顏色 |
| `back_color` | 背景色 |
| `shadow_color` | 陰影色（含 alpha 通道控制透明度） |
| `border_color` | 邊框色 |
| `label_color` | 序號文字色 |
| `comment_text_color` | 注釋文字色 |

組合範例（完整鍵名）：

```
text_color                    # 視窗整體文字色
candidate_text_color          # 未選中候選文字色
hilited_text_color            # 高亮輸入串文字色
hilited_candidate_text_color  # 選中候選文字色
hilited_candidate_back_color  # 選中候選背景色
hilited_label_color           # 選中候選序號色
hilited_comment_text_color    # 選中候選注釋色
hilited_mark_color            # 選中標記（mark_text）顏色
candidate_back_color          # 未選中候選背景色
```

其他特殊鍵：

| 色彩鍵 | 說明 |
|--------|------|
| `prevpage_color` | 上一頁箭頭色 |
| `nextpage_color` | 下一頁箭頭色 |

### 完整範例

```yaml
preset_color_schemes:
  my_dark:
    name: "深色主題／Dark"
    author: "作者"
    color_format: argb
    text_color: 0xFFe8e8e8
    back_color: 0xFF1e1e1e
    border_color: 0xFF444444
    shadow_color: 0x40000000
    label_color: 0xFF888888
    candidate_text_color: 0xFFd4d4d4
    hilited_candidate_text_color: 0xFFffffff
    hilited_candidate_back_color: 0xFF0078d4
    hilited_label_color: 0xFFffffff
    comment_text_color: 0xFF888888
    hilited_comment_text_color: 0xFFcccccc
```

---

## 按方案覆蓋外觀

在特定方案的 `schema.yaml` 或 `<方案>.custom.yaml` 中，可覆蓋全域 `style` 的任意選項：

```yaml
# luna_pinyin.custom.yaml
patch:
  "style/color_scheme": my_dark
  "style/horizontal": true
  "style/layout/candidate_spacing": 12
```

或在 `schema.yaml` 中直接加：

```yaml
style:
  color_scheme: my_dark
  horizontal: true
```

切換到此方案時，Weasel 會自動套用這些覆蓋值；切換到其他方案時，恢復全域設定。

---

## 安裝與更新方案

### 方法一：托盤圖示（簡易）

右鍵系統托盤的小狼毫圖示 → **輸入法設定** → **獲取更多方案**，在對話框中輸入 `<用戶名>/<倉庫名>`。

限制：只下載倉庫根目錄的 yaml 文件，**不會自動複製 Lua 腳本等其他文件**，需手動複製到用戶目錄。

### 方法二：plum（完整工具）

1. 安裝 [Git for Windows](https://git-scm.com/)，確認 `git.exe` 已加入 PATH
2. 在方案對話框輸入 `git`，確認安裝成功
3. 輸入 `plum`，自動克隆 plum 到用戶目錄

plum 安裝後成為預設方案下載器，支援 recipe 語法（如 `rime-cantonese:schema`），並能完整複製所有相關文件。

---

## 常用自訂範例

### weasel.custom.yaml 結構

```yaml
customization:
  distribution_code_name: Weasel
  distribution_version: "0.0.0.0"
  generator: "Weasel::UIStyleSettings"
  modified_time: "..."

patch:
  "style/color_scheme": my_theme
  "style/horizontal": true
  "style/font_face": "Microsoft JhengHei"
  "style/font_point": 15
  "style/layout/+":
    corner_radius: 10
    shadow_radius: 8
```

### 深淺色自動切換

```yaml
patch:
  "style/color_scheme": my_light
  "style/color_scheme_dark": my_dark
```

系統切換深/淺色模式時，Weasel 自動切換對應配色。

### 橫排佈局（Windows 11 風格）

```yaml
patch:
  style/+:
    horizontal: true
    inline_preedit: true
    label_format: "%s"
    font_point: 15
    layout:
      margin_x: 16
      margin_y: 8
      candidate_spacing: 22
      hilite_padding_x: 8
      corner_radius: 10
      shadow_radius: 8
```
