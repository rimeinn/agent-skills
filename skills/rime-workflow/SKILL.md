---
name: rime-workflow
description: This workflow describes the basic knowledge of rime. Always read this if the user is asking about Rime.
metadata:
  author: RimeInn
  version: 0.1.0
---

# Rime 工作流程

## 輸入邏輯

用戶按下鍵時，KeyEvent 將被依次發送給每個 processor（按鍵處理器）。
- 每個 processor 獨立判斷，是否接受（accept）/拒絕（reject）/什麼都不做並傳遞事件給下一個處理器（noop）。
- 若事件被接受或拒絕，該按鍵事件將不會傳回下層程序。
- 若所有 processor 都對事件返回 noop，則 Rime 整體不處理該事件，事件傳回下層程序。
- 某些 processor 將事件添加到 context.input 中。

若 context.input 發生變化，則觸發重新翻譯流程。

輸入首先發送給 segmentor，將輸入切分爲若干個 segment，每個 segment 可以攜帶 tags。

每個 segment，除非已經選字過，否則將發送至每個 translator（翻譯器），每個翻譯器會產生一個翻譯（translation）。每個 translation 是一個惰性的列表，只在前端請求時才產生相應候選。translation 中的元素是 Candidate（候選項）。候選項具有 quality，引擎最終將所有 translation 按 quality 大小合併爲一個 translation。

translation 最後會經過所有 filters（濾鏡）。每個濾鏡都是 Translation 到 Translation 的函數，可以獨立判斷是否保留、變換、添加、刪除候選項。

## 構建邏輯

每個 Rime 安裝有共享數據目錄和用戶配置目錄，通常共享數據目錄是只讀的，提供：
- 朙月拼音 `luna_pinyin.schema.yaml`（基於八股文詞庫，提供字音和一些詞的讀音）
- 倉頡 `cangjie5.schema.yaml`
- 五筆劃 `stroke.schema.yaml`
- 地球拼音 `terra_pinyin.schema.yaml`
- 八股文詞庫 `essay.txt` （含有詞語和詞頻）

用戶目錄中，提供：
- default.yaml 個人配置起點，其中 `schema_list` 定義了當前配置啓用的方案列表，並且提供一些共享的默認選項，供其他方案導入。
  格式爲：
  ```
  schema_list:
    - {schema: <方案名1>}
    - {schema: <方案名2>}
  ```
- 各方案的 schema.yaml
- 用戶補充的 dict.yaml
- .txt 可能是詞庫（vocabulary）或 stabledb（純文本的用戶詞庫，無法同步）

## 用戶補丁

rime yaml parser 支持特定的 directive 以修改當前讀入的 yaml 文檔。只在解析到此處時，才會展開，只一次（不支持不動點計算）。
```
foo:
  bar: key
  __include: cfg:/?    # 將整個 cfg.yaml 讀入到此處， ? 表示讀入失敗也不報錯

__include: cfg:/foo    # cfg.yaml /foo 節點讀入到此處

__patch:
  key1/key2: value          # 覆寫當前文檔的 key1/key2 爲 value，需注意類型必須吻合（list 仍是 list，map 仍是 map，scalar 仍是 scalar）
  key3/key4/+: [1,2,3]      # 向 key3/key4 下的列表追加元素
  key5/+:                   # 將這裏的 map 與 key5 的 map 合併（a b c 之外的其他 key 值不變）
    a: avalue               # key5/a 被覆寫
    b/+: [bvalue]           # key5/b 增加 bvalue
    c/+:
      d: dvalue             # key5/c/d 被覆寫，但 key5/c 下的其他 key 值不變
```

每個 foo.schema.yaml 在文件中 *不存在顯式 __patch 時* 會隱含地增加

```
__patch:
  __include: foo.custom:/patch?
```

因此一般對方案進行 patch 時不直接修改 foo.schema.yaml，而是寫 foo.custom.yaml :

```
patch:
  translator/enable_user_dict: false  # 關閉用戶詞庫
```

## dict.yaml 格式

```yaml
---
name: "字符串（詞庫名）"              # 必需
version: "字符串（版本號）"           # 必需
use_preset_vocabulary: true | false   # 導入八股文詞庫（essay.txt），默認爲繁體詞庫，可選，默認爲 true
...

字	zi	1000
詞語	ci yu	100
瓩	qian wa
# 註釋
# nocomment
#	hashtag
```

詞語和編碼之間以 tab 隔開。對拼音類方案，多音節詞的音節之間用空格隔開。形碼類方案一般將編碼視作單音節，故不用空格。
在出現單獨的 `# nocomment` 之後，`#` 不再視作註釋。

條目格式可以在 frontmatter 中用 columns 自定義。默認爲：
```
columns:
  - text    # 詞條內容
  - code    # 詞條編碼
  - weight  # 詞條權重
  - stem    # 構詞碼（一般只對形碼方案有意義）
```
調整該順序，則詞庫也需要與之對應。

## 除錯方法

### 查看日誌

Rime 的運行日誌是排查配置問題的主要手段。日誌分三個級別：`INFO`（`rime.INFO`）、`WARNING`（`rime.WARNING`）、`ERROR`（`rime.ERROR`）。

各平臺日誌目錄：

| 平臺 | 前端 | 日誌目錄 |
|------|------|----------|
| Windows | 小狼毫（Weasel） | `%TEMP%\rime.weasel\` |
| macOS | 鼠鬚管（Squirrel） | `$TMPDIR/rime.squirrel/`（通常為 `/var/folders/.../T/rime.squirrel/`） |
| macOS | fcitx5-macos（f5m） | `/tmp/Fcitx5.log`（單一日誌檔） |
| Linux | iBus Rime / fcitx5-rime | `$XDG_RUNTIME_DIR/rime.*` 或 `/tmp/rime.*`（依前端而異） |

日誌檔名格式通常為 `rime.前端名.用戶名.LOG.INFO.時間戳`，可只看 `rime.INFO` 符號連結（指向最新日誌）。

常用搜索模式：

```bash
# 查看 ERROR 與 WARNING
grep -E "^[EW]" /path/to/rime.INFO

# 查看部署（編譯）過程
grep "deploy\|build\|load" /path/to/rime.INFO

# 查看特定方案的錯誤
grep "luna_pinyin\|schema_id" /path/to/rime.INFO
```

### 常見問題排查

- **部署後無效**：查看日誌中是否有 `ERROR` 或 `failed`，常見原因為 YAML 格式錯誤（縮進、冒號後空格）。
- **候選為空**：確認 `translator/dictionary` 名稱與 `.dict.yaml` 的 `name` 欄位一致，且詞庫已部署（有對應 `.table.bin`）。
- **packs 中詞語無法輸入**：各 pack 獨立編譯，必須在 pack 詞庫中包含單字的編碼，否則整句拼不出音節。
- **自訂 lua 不生效**：確認 `rime.lua` 或 `lua/` 目錄下的檔案存在於用戶資料目錄，且函數名稱與 yaml 中引用的名稱完全一致。

## Rime 同步

修改 installation.yaml：
- 除非用戶反對，否則將 `installation_id` 修改爲更有描述性的名字（默認爲 UUID），如 `windows7-weasel` 或 `macos-squirrel` ，前者是操作系統名，後者是 Rime 發行版名。如果操作系統名有衝突，可以使用設備名。
- 將 `sync_dir` 指向一個共享目錄，例如 `$DROPBOX/RimeSync`，需要詢問用戶具體目錄位置，若不存在，確認是否創建。若用戶提供了目錄，請首先確認這個位置是合理的（見下），否則再次要求確認。
- 將 `backup_config_files` 改爲 false（默認爲 true）以阻止同步所有 yaml 文件（防止同步大 dict），需向用戶確認。

Rime 同步目錄結構：
```
RimeSync/
- installation1/
  + *.yaml
  + *.txt
- installation2/
  + *.yaml
  + *.txt
- ...
```

