---
name: rime-plum
description: Describes plum (東風破), the Rime configuration manager. Covers recipe syntax, package installation, conf files, environment variables, recipe.yaml format, and Windows/Linux/macOS usage.
metadata:
  author: RimeInn
  version: 0.1.0
---

# 東風破（plum）配置管理器

plum 是 Rime 的配置管理工具，用於安裝、更新輸入方案及相關數據檔案。

---

## 快速開始

### Linux / macOS（一鍵安裝）

```sh
curl -fsSL https://raw.githubusercontent.com/rime/plum/master/rime-install | bash
```

執行後自動克隆 plum 至當前目錄下的 `plum/` 子目錄，並安裝 `:preset` 預設方案組。

### 使用本地克隆

```sh
git clone --depth 1 https://github.com/rime/plum.git
cd plum
bash rime-install <target...>
```

### Windows

使用小狼毫 0.11+ 的「輸入法設定 → 獲取更多方案」（已內建 plum），或下載 [啓動工具包](https://github.com/rime/plum-windows-bootstrap/archive/master.zip) 後執行 `rime-install-bootstrap.bat`。

---

## Recipe（配方）語法

plum 的核心概念是 **recipe**（配方，符號 ℞）。每個安裝目標稱為一個 recipe，格式為：

```
<user>/<repo>@<branch>:<recipe>:<key>=<value>,...
```

各部分均可省略，解析規則如下：

| 部分 | 說明 | 省略時的行為 |
|------|------|------------|
| `<user>/` | GitHub 用戶名 | 省略時預設為 `rime` |
| `<repo>` | 倉庫名 | 必填（短名如 `luna-pinyin` → 自動展開為 `rime/rime-luna-pinyin`） |
| `@<branch>` | Git 分支名 | 省略時使用倉庫預設分支 |
| `:<recipe>` | 包內具名 recipe（對應 `<recipe>.recipe.yaml`） | 省略時優先使用 `recipe.yaml`，否則安裝所有標準檔案 |
| `:<key>=<value>,...` | 傳遞給 recipe 的選項參數 | 省略時無額外選項 |

### 短名展開規則

- `luna-pinyin` → `rime/rime-luna-pinyin`（自動補 `rime/rime-` 前綴）
- `lotem/rime-zhung` → `lotem/rime-zhung`（已含 `/`，不展開）
- `rime-cangjie` → `rime/rime-cangjie`（已有 `rime-` 前綴，補 `rime/`）

### 範例

```sh
# 安裝官方 luna-pinyin（等同 rime/rime-luna-pinyin，預設分支）
bash rime-install luna-pinyin

# 安裝第三方方案（指定用戶/倉庫）
bash rime-install lotem/rime-zhung

# 指定分支
bash rime-install lotem/rime-zhung@master

# 安裝包內具名 recipe
bash rime-install rimeinn/rime-moran:dist

# 傳遞 recipe 選項（多個用逗號或冒號分隔）
bash rime-install rimeinn/rime-moran:dist:branch_moran=trad

# 同時安裝多個
bash rime-install luna-pinyin cantonese lotem/rime-zhung@master
```

---

## 預置方案組

以冒號開頭的特殊目標，對應 plum 目錄下的 `<name>-packages.conf`：

| 目標 | 說明 | 包含方案 |
|------|------|---------|
| `:preset` | 預設方案（預設行為） | `bopomofo`、`cangjie`、`essay`、`luna-pinyin`、`prelude`、`stroke`、`terra-pinyin` |
| `:extra` | 擴充方案 | `array`、`cantonese`、`combo-pinyin`、`double-pinyin`、`emoji`、`ipa`、`jyutping`、`middle-chinese`、`pinyin-simp`、`quick`、`scj`、`soutzoe`、`stenotype`、`wubi`、`wugniu` |
| `:all` | 上述全部 | `:preset` + `:extra` |

```sh
bash rime-install :preset         # 只安裝預設
bash rime-install :extra          # 只安裝擴充
bash rime-install :all            # 安裝全部
```

---

## 使用 `.conf` 方案清單檔案

`.conf` 檔案是一個 bash 腳本，定義 `package_list` 陣列，可批次安裝多個方案。

### 使用本地 `.conf` 檔案

```sh
bash rime-install /path/to/my-packages.conf
# 或在 plum 目錄下
bash rime-install ./my-packages.conf
```

### 使用遠端 `.conf` 檔案

```sh
# 完整 URL
bash rime-install https://github.com/lotem/rime-forge/raw/master/lotem-packages.conf

# 短形式：<user>/<repo>/<filename>-packages.conf
bash rime-install lotem/rime-forge/lotem-packages.conf

# 指定分支：<user>/<repo>@<branch>/<filename>-packages.conf
bash rime-install lotem/rime-forge@master/lotem-packages.conf
```

### `.conf` 檔案格式

```bash
#!/bin/bash

package_list=(
  "rime/rime-luna-pinyin"
  "rimeinn/rime-moran@${branch_moran:-trad}"   # 支援 shell 變數展開
  "lotem/rime-zhung"
)
```

> 如需在其他用戶的環境中共享，可將 `.conf` 檔案放在 GitHub 倉庫中，通過短形式 URL 引用。

---

## 環境變數

所有變數均可在命令行前綴傳遞，也可在 `rime-install-config.bat`（Windows）中持久設定。

| 變數 | 說明 | 預設值 |
|------|------|--------|
| `rime_dir` | Rime 用戶數據目錄（安裝目標） | 依 `rime_frontend` 自動推斷 |
| `rime_frontend` | 前端名稱，用於推斷 `rime_dir` | 依操作系統推斷 |
| `plum_dir` | plum 自身的目錄 | 腳本所在目錄或 `./plum` |
| `plum_repo` | plum 的 GitHub 倉庫 | `rime/plum` |
| `no_update` | 設為任意非空值時，跳過已下載包的 git pull | 未設定 |

### 各前端對應的 `rime_dir`

| `rime_frontend` | `rime_dir` |
|-----------------|-----------|
| `ibus-rime`（Linux 預設） | `~/.config/ibus/rime` |
| `fcitx-rime` | `~/.config/fcitx/rime` |
| `fcitx5-rime` | `~/.local/share/fcitx5/rime` |
| `squirrel`（macOS 預設） | `~/Library/Rime` |
| `weasel`（Windows 預設） | `%APPDATA%\Rime` |

```sh
# 範例：為 fcitx5-rime 安裝
rime_frontend=fcitx5-rime bash rime-install luna-pinyin

# 或直接指定目錄
rime_dir="$HOME/.local/share/fcitx5/rime" bash rime-install luna-pinyin

# 不更新已存在的包（適合 CI 或離線場景）
no_update=1 bash rime-install :preset
```

---

## 互動選擇模式

使用 `--select` 旗標進入互動式選單，逐一勾選要安裝的方案：

```sh
bash rime-install --select :extra
bash rime-install --select :all lotem/rime-forge/lotem-packages.conf
```

在選單中：
- 輸入編號選取對應方案
- 輸入方案名稱（如 `cantonese`）直接加入
- 輸入 `.`、`end`、`ok`、`0` 確認完成
- 輸入 `reset` 清空已選
- 輸入 `cancel`/`exit`/`quit` 取消

---

## 更新 plum 自身

```sh
bash rime-install plum
```

這會在 plum 目錄內執行 `git pull`。

---

## Windows 特有功能

### `rime-install.bat` 命令行

```batch
rime-install :preset combo-pinyin jyutping wubi
```

### `rime-install-config.bat` 持久設定

在與 `rime-install.bat` 同目錄下建立此檔案，設定持久變數：

```batch
set plum_dir=%APPDATA%\plum
set rime_dir=%APPDATA%\Rime
set use_plum=1
```

### 離線 ZIP 安裝

將從 GitHub 下載的 ZIP 檔案直接拖放到 `rime-install.bat` 捷徑上，即可離線安裝。已下載的 ZIP 快取存於 `%TEMP%` 目錄（可透過 `download_cache_dir` 變數自訂）。

### 安裝 Git（啓用增量更新）

```batch
rime-install git
```

安裝 [Git for Windows](https://gitforwindows.org/) 後，後續安裝改用 git clone/pull 進行增量更新。

---

## `recipe.yaml` 格式

若包的根目錄包含 `recipe.yaml`（或 `<name>.recipe.yaml`），plum 會執行其中定義的安裝步驟，而非預設的「複製所有 yaml/txt/gram 檔案」行為。

```yaml
# encoding: utf-8
---
recipe:
  Rx: <recipe-id>           # recipe 識別碼，必須與檔名一致（具名 recipe 才需要）
  description: >-
    說明文字

# 從包目錄安裝指定檔案（支援 glob 模式）
install_files: >-
  *.schema.yaml
  *.dict.yaml
  lua/*.lua
  opencc/*

# 從外部 URL 下載檔案到包目錄
download_files:
  - https://example.com/data.txt
  - custom_name.txt::https://example.com/remote_name.txt   # 自訂本地名稱

# 向目標目錄中的 yaml 檔案追加 __patch 補丁
patch_files:
  default.yaml:
    schema_list/+:
      - {schema: my_schema}
  my_schema.schema.yaml:
    - other.custom:/patch?
```

### `install_files` 的預設行為（無 `recipe.yaml` 時）

plum 自動複製以下類型的檔案（排除 `*.custom.yaml`、`*.recipe.yaml`、`recipe.yaml`）：

- `*.yaml`（方案與詞典配置）
- `*.txt`（詞庫文本）
- `*.gram`（語言模型）
- `opencc/*.json`、`opencc/*.ocd`、`opencc/*.txt`（OpenCC 字形轉換資源）

### `patch_files` 的行為

`patch_files` 的每個鍵是目標檔案名（相對於 `rime_dir`），值是要追加的 `__patch` 內容。plum 會在目標檔案末尾的 `__patch:` 節點下插入補丁，並以 `# Rx: <recipe>` 標記包圍，以便重複執行時冪等更新（先移除舊補丁再插入新補丁）。

若值為字串列表，則以 YAML `__include` 方式引用外部節點：

```yaml
patch_files:
  my_schema.schema.yaml:
    - other_config:/patch        # 展開為 __include: other_config:/patch
    - another.custom:/patch?     # 展開為 __include: another.custom:/patch?
```

---

## 包緩存目錄結構

plum 將克隆的 git 倉庫儲存於 `<plum_dir>/package/<user>/<package_name>/`，例如：

```
plum/
└── package/
    ├── rime/
    │   ├── luna-pinyin/      # rime/rime-luna-pinyin 的克隆
    │   └── cantonese/        # rime/rime-cantonese 的克隆
    └── rimeinn/
        └── moran/            # rimeinn/rime-moran 的克隆
```

已存在的包目錄在下次執行時會執行 `git fetch && git merge --ff-only`（設定 `no_update=1` 可跳過）。

---

## 系統級安裝（Makefile，Linux 套件打包用）

```sh
# 安裝預設方案到 output/ 目錄
make

# 安裝全部方案
make all

# 安裝並用 rime_deployer 預編譯為二進位
make preset-bin

# 安裝到系統目錄（預設 /usr/share/rime-data）
sudo make install

# 指定前綴
sudo make install PREFIX=/usr/local

# 指定輸出目錄（可直接輸出到 Rime 用戶目錄）
make OUTPUT=~/.config/ibus/rime
```

---

## 完整使用範例

```sh
# 一次安裝多個第三方方案，指定前端
rime_frontend=fcitx5-rime bash rime-install \
  luna-pinyin \
  rimeinn/rime-moran@trad \
  lotem/rime-forge/lotem-packages.conf

# 離線場景：安裝預設方案但不更新已有包
no_update=1 bash rime-install :preset

# 使用互動選單從擴充列表選取
bash rime-install --select :extra

# 更新 plum 後再安裝
bash rime-install plum && bash rime-install :preset
```
