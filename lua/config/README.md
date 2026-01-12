# Core Configuration Guide

Neovim의 핵심 설정 파일 및 옵션 가이드입니다.

## 📊 Overview

5개의 핵심 설정 파일로 구성되어 있습니다:

| File | Purpose | Load Order |
|------|---------|------------|
| [init.lua](#initlua) | 설정 진입점 | 1 |
| [keybinds.lua](#keybindslua) | 전역 키바인딩 | 2 |
| [options.lua](#optionslua) | 편집기 옵션 | 3 |
| [lazy.lua](#lazylua) | 플러그인 매니저 | 4 |
| [clipboard.lua](#clipboardlua) | 클립보드 설정 | 5 |

---

## init.lua

### 📍 Location
`~/.config/nvim/init.lua`

### 📝 Description

Neovim 설정의 **진입점**입니다. 모든 core 모듈을 순차적으로 로드합니다.

### 📄 Full Content

```lua
require("config.keybinds")
require("config.options")
require("config.lazy")
require("config.clipboard")
```

### 🔄 Load Sequence

1. **keybinds.lua** - Leader 키 및 전역 키바인딩 설정
2. **options.lua** - 편집기 기본 옵션 설정
3. **lazy.lua** - 플러그인 매니저 부트스트랩 및 플러그인 로드
4. **clipboard.lua** - 클립보드 통합 설정

### ⚙️ Why This Order?

- **keybinds first**: Leader 키는 플러그인 전에 설정되어야 함
- **options early**: 기본 편집기 동작은 플러그인 전에 확립
- **lazy before clipboard**: 일부 클립보드 기능이 플러그인을 사용할 수 있음
- **clipboard last**: 다른 설정에 의존적이지 않음

---

## keybinds.lua

### 📍 Location
`~/. config/nvim/lua/config/keybinds.lua`

### 📝 Description

전역 키바인딩 설정입니다. Leader 키와 윈도우 관리 키바인딩을 정의합니다.

### 📄 Full Content

```lua
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Window splits
vim.keymap.set("n", "<leader>w-", "<C-w>s", { desc = "[Window] Split Below" })
vim.keymap.set("n", "<leader>w|", "<C-w>v", { desc = "[Window] Split Right" })
```

### ⌨️ Keybindings

#### Leader Keys

| Variable | Key | Description |
|----------|-----|-------------|
| `mapleader` | `Space` | 전역 Leader 키 |
| `maplocalleader` | `Space` | 로컬 Leader 키 (파일 타입별) |

#### Window Management

| Key | Action | Description |
|-----|--------|-------------|
| `<leader>w-` | `<C-w>s` | 아래로 창 분할 (horizontal) |
| `<leader>w|` | `<C-w>v` | 오른쪽으로 창 분할 (vertical) |

### 💡 Leader Key Concept

**Leader 키**는 Vim/Neovim에서 커스텀 키바인딩의 시작점입니다:

- `Space`를 누르면 which-key 팝업이 표시됨
- 이후 명령어 키를 입력하여 액션 실행
- 예: `Space` + `w` + `-` = 창 분할

### 🔧 Customization

#### 새 윈도우 키바인딩 추가

```lua
-- Window close
vim.keymap.set("n", "<leader>wq", "<C-w>q", { desc = "[Window] Close" })

-- Window navigation
vim.keymap.set("n", "<leader>wh", "<C-w>h", { desc = "[Window] Go Left" })
vim.keymap.set("n", "<leader>wl", "<C-w>l", { desc = "[Window] Go Right" })
```

#### Leader 키 변경

```lua
vim.g.mapleader = ","        -- Comma를 Leader로
vim.g.maplocalleader = "\\"  -- Backslash를 Local Leader로
```

### 🔗 Related

- **[Which-Key Plugin](plugins/ui/README.md#which-key)** - 키바인딩 도움말
- **Plugin Keybindings** - 각 플러그인별 추가 키바인딩

---

## options.lua

### 📍 Location
`~/.config/nvim/lua/config/options.lua`

### 📝 Description

Neovim 편집기의 기본 옵션을 설정합니다.

### 📄 Full Content

```lua
-- Line numbers
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.showmode = false

-- Tabs and indentation
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.autoindent = true

-- Wrap
vim.opt.wrap = false

-- Incremental Search
vim.opt.incsearch = true

-- 비주얼 모드에서 들여쓰기 후 선택 영역 유지
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")
```

### ⚙️ Option Breakdown

#### Line Numbers

| Option | Value | Description |
|--------|-------|-------------|
| `number` | `true` | 절대 라인 번호 표시 |
| `relativenumber` | `true` | 상대 라인 번호 표시 |
| `showmode` | `false` | 모드 표시 숨김 (lualine이 대신 표시) |

**Display Example**:
```
  3  │  -- 현재 줄에서 3줄 위
  2  │  local name = "John"
  1  │  local age = 30
  0  │  local city = "Seoul"    ← 현재 줄 (0)
  1  │  print(city)
  2  │  -- 현재 줄에서 2줄 아래
```

**Benefits**:
- 상대 번호로 빠른 점프 (`3k`, `2j`)
- 절대 번호로 정확한 위치 파악

#### Tabs and Indentation

| Option | Value | Description |
|--------|-------|-------------|
| `tabstop` | `4` | 탭 문자의 시각적 너비 |
| `shiftwidth` | `4` | 자동 들여쓰기 너비 |
| `expandtab` | `true` | 탭을 스페이스로 변환 |
| `autoindent` | `true` | 자동 들여쓰기 활성화 |

**Example**:
```lua
function example()
····local x = 1    -- 4 spaces (not tab character)
····if x > 0 then
········print(x)   -- 8 spaces (4 * 2 levels)
····end
end
```

#### Line Wrapping

| Option | Value | Description |
|--------|-------|-------------|
| `wrap` | `false` | 긴 줄을 다음 줄로 넘기지 않음 |

**With wrap = false** (현재 설정):
```
This is a very long line that extends beyond the screen width →
```

**With wrap = true**:
```
This is a very long line that extends
beyond the screen width
```

#### Search

| Option | Value | Description |
|--------|-------|-------------|
| `incsearch` | `true` | 타이핑하는 동안 실시간 검색 |

**Behavior**:
- `/search` 입력 시 입력하는 즉시 일치 항목으로 이동
- 검색어 수정 시 실시간으로 결과 업데이트

#### Visual Mode Indentation

| Key | Mode | Action |
|-----|------|--------|
| `<` | Visual | 왼쪽 들여쓰기 후 선택 유지 |
| `>` | Visual | 오른쪽 들여쓰기 후 선택 유지 |

**Without `gv`** (기본 Vim):
```
1. Select lines (V)
2. Press >
3. Selection is lost ✗
```

**With `gv`** (현재 설정):
```
1. Select lines (V)
2. Press >
3. Selection maintained ✓
4. Can press > again for more indentation
```

### 🔧 Customization

#### 2칸 탭으로 변경 (JavaScript/TypeScript 스타일)

```lua
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
```

#### 줄 바꿈 활성화

```lua
vim.opt.wrap = true
vim.opt.linebreak = true  -- 단어 중간이 아닌 단어 경계에서 줄 바꿈
```

#### 절대 라인 번호만 사용

```lua
vim.opt.number = true
vim.opt.relativenumber = false
```

#### 검색 하이라이트 추가

```lua
vim.opt.hlsearch = true    -- 검색 결과 하이라이트
vim.opt.ignorecase = true  -- 대소문자 무시
vim.opt.smartcase = true   -- 대문자 포함 시 대소문자 구분
```

### 💡 Tips

#### Tip 1: 파일 타입별 설정

특정 파일 타입만 2칸 들여쓰기:

```lua
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "javascript", "typescript", "json" },
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
  end,
})
```

#### Tip 2: 상대 번호 토글

이미 `<leader>uL` 키바인딩으로 토글 가능 (snacks.nvim)

---

## lazy.lua

### 📍 Location
`~/.config/nvim/lua/config/lazy.lua`

### 📝 Description

**lazy.nvim** 플러그인 매니저를 부트스트랩하고 설정합니다.

### 📄 Full Content

```lua
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    { import = "plugins" },
  },
  checker = { enabled = true, notify = false },
  change_detection = {
    notify = false
  },
})
```

### 🔧 Configuration Breakdown

#### 1. Bootstrap (자동 설치)

```lua
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  -- Git clone lazy.nvim
end
vim.opt.rtp:prepend(lazypath)
```

**What it does**:
- lazy.nvim이 없으면 GitHub에서 자동으로 클론
- 설치 위치: `~/.local/share/nvim/lazy/lazy.nvim`
- stable 브랜치 사용

#### 2. Setup Configuration

| Option | Value | Description |
|--------|-------|-------------|
| `spec` | `{ import = "plugins" }` | `lua/config/plugins/` 디렉토리의 모든 플러그인 자동 로드 |
| `checker.enabled` | `true` | 플러그인 업데이트 자동 확인 |
| `checker.notify` | `false` | 업데이트 알림 비활성화 |
| `change_detection.notify` | `false` | 플러그인 파일 변경 알림 비활성화 |

### 📂 Plugin Import Structure

```
lua/config/plugins/
├── material.lua       ─┐
├── lualine.lua         │
├── bufferline.lua      │
├── snacks.lua          ├─→  자동으로 lazy.nvim에 import
├── ...                 │
└── which-key.lua      ─┘

각 파일은 플러그인 스펙을 반환:
return {
  "author/plugin-name",
  opts = {},
  keys = {},
}
```

### ⚙️ Lazy.nvim Features

#### Auto-Update Checker

- **Frequency**: 매일 자동으로 확인
- **Notification**: 비활성화 (조용히 확인)
- **Manual Check**: `:Lazy check`

#### Change Detection

- **Watch**: `lua/config/plugins/` 디렉토리 변경 감지
- **Auto-reload**: 플러그인 파일 수정 시 자동 재로드
- **Notification**: 비활성화

### 📋 Lazy Commands

Neovim에서 사용 가능한 명령어:

| Command | Action |
|---------|--------|
| `:Lazy` | Lazy UI 열기 |
| `:Lazy install` | 새 플러그인 설치 |
| `:Lazy update` | 모든 플러그인 업데이트 |
| `:Lazy sync` | Install + Update + Clean |
| `:Lazy clean` | 사용하지 않는 플러그인 제거 |
| `:Lazy check` | 업데이트 확인 |
| `:Lazy log` | 플러그인 커밋 로그 |
| `:Lazy profile` | 플러그인 로딩 시간 프로파일 |

### 🔧 Customization

#### 업데이트 알림 활성화

```lua
checker = {
  enabled = true,
  notify = true,  -- 업데이트 가능 시 알림
}
```

#### 플러그인 변경 알림 활성화

```lua
change_detection = {
  notify = true,  -- 파일 변경 시 알림
}
```

#### 특정 브랜치/태그 고정

```lua
-- lazy.lua는 변경하지 않고, 각 플러그인 파일에서:
return {
  "author/plugin",
  branch = "main",     -- 특정 브랜치
  -- or
  tag = "v1.0.0",      -- 특정 태그
  -- or
  commit = "abc123",   -- 특정 커밋
}
```

### 💡 Tips

#### Tip 1: 플러그인 로딩 시간 확인

```vim
:Lazy profile
```

느린 플러그인을 찾아 lazy loading 최적화

#### Tip 2: Lock 파일 사용

`lazy-lock.json` 파일은 플러그인 버전을 고정합니다:
- 버전 충돌 방지
- 팀 환경에서 일관성 유지
- Git에 커밋하여 공유

#### Tip 3: 플러그인 추가 워크플로우

1. `lua/config/plugins/new-plugin.lua` 파일 생성
2. 플러그인 스펙 작성
3. `:Lazy` 열기 → 자동으로 인식됨
4. `I` 키로 설치

---

## clipboard.lua

### 📍 Location
`~/.config/nvim/lua/config/clipboard.lua`

### 📝 Description

**OSC 52 프로토콜**을 사용한 클립보드 통합 설정입니다. SSH, tmux, 터미널 환경에서도 시스템 클립보드와 연동됩니다.

### 📄 Full Content

```lua
vim.opt.clipboard = "unnamedplus"

local clipboard_cache = { "", "" }

vim.g.clipboard = {
    name = "OSC 52",
    copy = {
        ["+"] = function(lines, regtype)
            clipboard_cache = { lines, regtype }
            require("vim.ui.clipboard.osc52").copy("+")(lines, regtype)
        end,
        ["*"] = function(lines, regtype)
            clipboard_cache = { lines, regtype }
            require("vim.ui.clipboard.osc52").copy("*")(lines, regtype)
        end,
    },
    paste = {
        ["+"] = function() return clipboard_cache end,
        ["*"] = function() return clipboard_cache end,
    },
}
```

### 🔧 Configuration Breakdown

#### 1. Clipboard Option

```lua
vim.opt.clipboard = "unnamedplus"
```

- `+` 레지스터 (시스템 클립보드)를 기본 사용
- `yank` 시 자동으로 시스템 클립보드에 복사
- `paste` 시 시스템 클립보드에서 붙여넣기

#### 2. OSC 52 Provider

| Register | Purpose | Description |
|----------|---------|-------------|
| `+` | System clipboard | Ctrl+C / Ctrl+V 클립보드 |
| `*` | Selection clipboard | X11 선택 클립보드 (Linux) |

#### 3. Clipboard Cache

```lua
local clipboard_cache = { "", "" }
```

- 복사한 내용을 로컬 캐시에 저장
- 붙여넣기 시 캐시에서 복원
- OSC 52는 복사만 지원하므로 paste 처리를 위한 캐시

### 🌐 What is OSC 52?

**OSC 52** (Operating System Command 52)는 터미널 이스케이프 시퀀스입니다:

- SSH 연결에서도 시스템 클립보드 사용 가능
- tmux/screen 내부에서도 작동
- 로컬과 원격 환경 모두에서 클립보드 공유

### 🎯 Use Cases

#### Case 1: 로컬 Neovim

```vim
yy     " 줄 복사 → 시스템 클립보드로
```

다른 앱에서 `Ctrl+V`로 붙여넣기 가능

#### Case 2: SSH 연결

```bash
ssh remote-server
nvim file.txt
```

```vim
yy     " 복사 → 로컬 시스템 클립보드로 전송
```

로컬 머신의 다른 앱에서 `Ctrl+V`로 사용 가능

#### Case 3: tmux 내부

```bash
tmux
nvim file.txt
```

```vim
yy     " 복사 → tmux를 거쳐 시스템 클립보드로
```

### 📋 Clipboard Commands

| Command | Action |
|---------|--------|
| `yy` | 현재 줄 복사 (클립보드로) |
| `"+y` | 명시적으로 + 레지스터에 복사 |
| `p` | 클립보드에서 붙여넣기 |
| `"+p` | 명시적으로 + 레지스터에서 붙여넣기 |

### 🔧 Customization

#### OSC 52 비활성화 (로컬 전용)

```lua
vim.opt.clipboard = "unnamedplus"
-- OSC 52 설정 제거
```

시스템 기본 클립보드 provider 사용

#### 캐시 크기 제한

```lua
copy = {
    ["+"] = function(lines, regtype)
        if #lines <= 1000 then  -- 1000줄 이하만 캐시
            clipboard_cache = { lines, regtype }
        end
        require("vim.ui.clipboard.osc52").copy("+")(lines, regtype)
    end,
}
```

### 💡 Tips

#### Tip 1: 터미널 지원 확인

OSC 52를 지원하는 터미널:
- ✅ iTerm2 (macOS)
- ✅ WezTerm
- ✅ Alacritty (최신 버전)
- ✅ Kitty
- ✅ Windows Terminal
- ❌ Terminal.app (macOS 기본)

#### Tip 2: tmux 설정

`~/.tmux.conf`에 추가:

```bash
set -g set-clipboard on
```

#### Tip 3: SSH 클립보드 테스트

```vim
:echo "test" | call system('echo', @+)
```

정상 작동 시 "test"가 시스템 클립보드에 복사됨

---

## 🔗 Configuration Flow Diagram

```
Neovim 시작
    │
    ├─→ init.lua (Entry Point)
    │
    ├─→ 1. keybinds.lua
    │      ├─ Leader = Space
    │      └─ Window splits
    │
    ├─→ 2. options.lua
    │      ├─ Line numbers
    │      ├─ Tabs (4 spaces)
    │      ├─ No wrap
    │      └─ Incremental search
    │
    ├─→ 3. lazy.lua
    │      ├─ Bootstrap lazy.nvim
    │      ├─ Import plugins/ dir
    │      └─ Load all plugins
    │
    └─→ 4. clipboard.lua
           ├─ OSC 52 setup
           └─ Clipboard cache
```

---

## 🔗 Related Documentation

- **[Plugin Catalog](plugins/README.md)** - 전체 플러그인 목록
- **[UI Plugins](plugins/ui/README.md)** - UI 플러그인 가이드
- **[Editing Plugins](plugins/editing/README.md)** - 편집 도구 가이드
- **[Utility Plugins](plugins/utility/README.md)** - 유틸리티 플러그인
- **[Root README](../../README.md)** - 전체 설정 개요

---

**5 Core Files** | **Last Updated: 2026-01-12**
