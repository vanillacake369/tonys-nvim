# UI Plugins Guide

UI 및 시각화 관련 플러그인의 상세 가이드입니다.

## 📊 Overview

6개의 UI 플러그인이 설정되어 있으며, 각각 특정한 역할을 담당합니다:

| Plugin | Purpose | Loading | Priority |
|--------|---------|---------|----------|
| [material.nvim](#material-theme) | 컬러 테마 | Immediate | 1000 |
| [lualine.nvim](#lualine) | 상태바 | Default | - |
| [bufferline.nvim](#bufferline) | 버퍼 탭 | VeryLazy | - |
| [snacks.nvim](#snacks) | 다목적 UI (13 모듈) | Immediate | 1000 |
| [nvim-web-devicons](#icons) | 파일 아이콘 | Auto | - |
| [which-key.nvim](#which-key) | 키바인딩 도움말 | VeryLazy | - |

---

## Material Theme

### 📦 Plugin Info
- **Repository**: [marko-cerovac/material.nvim](https://github.com/marko-cerovac/material.nvim)
- **Configuration**: [lua/config/plugins/material.lua](../material.lua)
- **Loading**: `lazy = false`, `priority = 1000`

### ✨ Features

Material Design 기반의 5가지 컬러 스킴을 제공합니다:

| Style | Description |
|-------|-------------|
| `darker` | **현재 사용 중** - 어두운 배경 with high contrast |
| `lighter` | 밝은 배경 |
| `oceanic` | 청록색 기반 다크 테마 |
| `palenight` | 보라색 기반 다크 테마 |
| `deep ocean` | 매우 어두운 청록 테마 |

### ⚙️ Configuration

```lua
style = "darker",
plugins = {
  "telescope",
  "nvim-cmp",
  -- 기타 플러그인 통합
},
lualine_style = "stealth",  -- Lualine 통합
async_loading = true,        -- 빠른 시작
```

### 🎨 Customization

#### 테마 스타일 변경

`lua/config/plugins/material.lua` 파일 수정:

```lua
vim.g.material_style = "oceanic"  -- 다른 스타일로 변경
```

#### Lualine 스타일

| Style | Description |
|-------|-------------|
| `default` | 기본 Material 스타일 |
| `stealth` | **현재 사용** - 미니멀한 스타일 |

### 🔗 Related
- [Lualine](#lualine) - 상태바 테마 통합

---

## Lualine

### 📦 Plugin Info
- **Repository**: [nvim-lualine/lualine.nvim](https://github.com/nvim-lualine/lualine.nvim)
- **Configuration**: [lua/config/plugins/lualine.lua](../lualine.lua)
- **Dependencies**: `nvim-web-devicons`

### ✨ Features

경량화되고 빠른 상태바로 Material 테마와 통합되어 있습니다.

### ⚙️ Current Configuration

```lua
{
  options = {
    theme = 'material',      -- Material 테마 사용
    globalstatus = true,     -- 전역 상태바 (분할 창에서도 하나)
  },
  sections = {
    lualine_a = {'mode'},    -- 모드만 표시 (INSERT, NORMAL 등)
    -- 나머지 섹션은 비활성화 (미니멀 디자인)
  }
}
```

### 🎨 Display

상태바는 현재 **모드만 표시**하는 미니멀한 디자인입니다:

```
 NORMAL
```

```
 INSERT
```

### 🔧 Customization

#### 섹션 추가하기

Git 브랜치, 파일명, 위치 등을 추가하려면:

```lua
sections = {
  lualine_a = {'mode'},
  lualine_b = {'branch'},           -- Git 브랜치
  lualine_c = {'filename'},         -- 파일명
  lualine_x = {'encoding', 'fileformat', 'filetype'},
  lualine_y = {'progress'},         -- 파일 위치 %
  lualine_z = {'location'}          -- 줄:열
}
```

#### 테마 변경

```lua
options = {
  theme = 'auto',        -- 자동 감지
  -- 또는 'gruvbox', 'nord', 'onedark' 등
}
```

### 🔗 Related
- [Material Theme](#material-theme) - 테마 통합

---

## Bufferline

### 📦 Plugin Info
- **Repository**: [akinsho/bufferline.nvim](https://github.com/akinsho/bufferline.nvim)
- **Configuration**: [lua/config/plugins/bufferline.lua](../bufferline.lua)
- **Loading**: `event = "VeryLazy"`

### ✨ Features

- LSP 진단 통합 (에러, 경고 표시)
- 버퍼 핀 기능
- 버퍼 정렬 및 이동
- 조건부 버퍼 삭제

### 📋 Keybindings

#### Buffer Navigation

| Key | Mode | Action |
|-----|------|--------|
| `<S-h>` | Normal | 이전 버퍼로 이동 |
| `<S-l>` | Normal | 다음 버퍼로 이동 |
| `[b` | Normal | 이전 버퍼로 이동 (대체) |
| `]b` | Normal | 다음 버퍼로 이동 (대체) |

#### Buffer Management

| Key | Mode | Action | Description |
|-----|------|--------|-------------|
| `<leader>bdc` | Normal | BufferLineCloseOthers | 현재 버퍼 제외 모두 닫기 |
| `<leader>bda` | Normal | BufferWipeout | 모든 버퍼 닫기 |
| `<leader>bp` | Normal | BufferLineTogglePin | 버퍼 핀 토글 |
| `<leader>bdP` | Normal | BufferLineGroupClose ungrouped | 핀되지 않은 버퍼 닫기 |
| `<leader>bdr` | Normal | BufferLineCloseRight | 오른쪽 버퍼들 닫기 |
| `<leader>bdl` | Normal | BufferLineCloseLeft | 왼쪽 버퍼들 닫기 |

#### Buffer Reordering

| Key | Mode | Action |
|-----|------|--------|
| `[B` | Normal | 버퍼를 왼쪽으로 이동 |
| `]B` | Normal | 버퍼를 오른쪽으로 이동 |

### 🎨 Visual Indicators

- **LSP Diagnostics**: 버퍼 탭에 에러/경고 카운트 표시
- **Modified**: 수정된 버퍼는 `[+]` 표시
- **Pinned**: 핀된 버퍼는 📌 아이콘

### 🔧 Customization

#### LSP 진단 표시 변경

```lua
diagnostics = "nvim_lsp",
diagnostics_indicator = function(count, level)
  local icon = level:match("error") and " " or " "
  return " " .. icon .. count
end
```

### 💡 Tips

- **핀 기능**: 자주 사용하는 버퍼를 핀하면 `<leader>bdP`로 나머지 버퍼만 닫을 수 있음
- **순서 정리**: `[B`, `]B`로 버퍼 순서를 원하는 대로 정리

---

## Snacks

### 📦 Plugin Info
- **Repository**: [folke/snacks.nvim](https://github.com/folke/snacks.nvim)
- **Configuration**: [lua/config/plugins/snacks.lua](../snacks.lua)
- **Loading**: `lazy = false`, `priority = 1000`

### ✨ Overview

13가지 기능을 제공하는 올인원 플러그인입니다. 각 모듈은 독립적으로 활성화/비활성화 가능합니다.

### 📦 Enabled Modules

| Module | Purpose | Keybindings |
|--------|---------|-------------|
| [bigfile](#snacks-bigfile) | 대용량 파일 처리 | - |
| [dashboard](#snacks-dashboard) | 시작 화면 | - |
| [explorer](#snacks-explorer) | 파일 탐색기 | `<leader>e` |
| [indent](#snacks-indent) | 인덴트 가이드 | `<leader>ug` |
| [input](#snacks-input) | 입력 다이얼로그 | - |
| [notifier](#snacks-notifier) | 알림 시스템 | - |
| [terminal](#snacks-terminal) | 통합 터미널 | `<C-_>` |
| [picker](#snacks-picker) | 퍼지 파인더 | `<leader>f*` |
| [quickfile](#snacks-quickfile) | 빠른 파일 열기 | - |
| [scope](#snacks-scope) | 스코프 관리 | - |
| [scroll](#snacks-scroll) | 부드러운 스크롤 | - |
| [statuscolumn](#snacks-statuscolumn) | 상태 컬럼 | - |
| [words](#snacks-words) | 단어 하이라이트 | - |

---

### Snacks: Bigfile

대용량 파일 열 때 자동으로 구문 강조 및 LSP 비활성화하여 성능 확보

**임계값**: 자동 감지

---

### Snacks: Dashboard

Neovim 시작 시 표시되는 대시보드

**Features**:
- 최근 파일 목록
- 프로젝트 목록
- 빠른 액션

---

### Snacks: Explorer

파일 탐색기

#### Keybindings

| Key | Action |
|-----|--------|
| `<leader>e` | 파일 탐색기 토글 |

#### Features
- 파일 트리 뷰
- 파일/디렉토리 생성, 삭제, 이름 변경
- 아이콘 통합

---

### Snacks: Indent

인덴트 가이드 라인 표시

#### Keybindings

| Key | Action |
|-----|--------|
| `<leader>ug` | 인덴트 가이드 토글 |

---

### Snacks: Input

향상된 입력 다이얼로그

**Features**:
- 커스텀 입력 프롬프트
- 자동완성 지원

---

### Snacks: Notifier

알림 시스템

**Configuration**:
- **Timeout**: 3초
- **위치**: 우측 상단
- **스타일**: 모던 알림 박스

---

### Snacks: Terminal

통합 터미널

#### Keybindings

| Key | Mode | Action |
|-----|------|--------|
| `<C-_>` | Normal | 터미널 토글 |
| `<C-_>` | Terminal | 터미널 닫기 |

**Note**: `<C-_>`는 `Ctrl + /`와 동일합니다 (터미널 키 매핑)

#### Features
- 플로팅 터미널
- 여러 터미널 세션 관리
- 터미널 모드 자동 전환

---

### Snacks: Picker

퍼지 파인더 (파일, 텍스트 검색)

#### Keybindings

| Key | Action | Description |
|-----|--------|-------------|
| `<leader><space>` | Smart find files | Git root 기반 스마트 검색 |
| `<leader>:` | Command history | 명령어 히스토리 |
| `<leader>fb` | Find buffers | 열린 버퍼 검색 |
| `<leader>fc` | Find config files | Neovim 설정 파일 검색 |
| `<leader>ff` | Find files | 파일 검색 |
| `<leader>fg` | Grep | 텍스트 검색 (ripgrep) |
| `<leader>fr` | Find recent files | 최근 열었던 파일 |

#### Features
- Hidden 파일 검색 지원
- Ignored 파일 검색 지원 (`show_ignored = true`)
- Git 통합

#### Picker Navigation

파인더 내부에서:
- `<C-n>` / `<Down>` - 다음 항목
- `<C-p>` / `<Up>` - 이전 항목
- `<CR>` - 선택
- `<Esc>` - 닫기

---

### Snacks: Quickfile

파일을 빠르게 여는 최적화

**Features**:
- 버퍼 로딩 최적화
- 자동 성능 개선

---

### Snacks: Scope

스코프 및 컨텍스트 관리

---

### Snacks: Scroll

부드러운 스크롤 애니메이션

**Features**:
- 스크롤 가속
- 애니메이션 효과

---

### Snacks: Statuscolumn

커스텀 상태 컬럼 (라인 번호 영역)

**Features**:
- 라인 번호
- Git 표시
- 진단 표시

---

### Snacks: Words

커서 아래 단어 자동 하이라이트

**Features**:
- 같은 단어 강조
- 자동 언하이라이트

---

### Snacks: Debug Functions

전역 디버그 함수 제공

#### Global Functions

```lua
_G.dd(...)    -- Snacks debug inspect (변수 출력)
_G.bt()       -- Snacks backtrace (스택 트레이스)
```

#### Usage

```lua
-- 변수 내용 확인
dd(vim.api.nvim_get_current_buf())

-- 스택 트레이스
bt()
```

---

### Snacks: UI Toggles

다양한 UI 옵션 토글 키바인딩

| Key | Action |
|-----|--------|
| `<leader>us` | Toggle spelling |
| `<leader>uw` | Toggle wrap |
| `<leader>uL` | Toggle relative line number |
| `<leader>ud` | Toggle diagnostics |
| `<leader>ul` | Toggle line number |
| `<leader>uc` | Toggle conceallevel |
| `<leader>uT` | Toggle treesitter highlight |
| `<leader>ub` | Toggle dark background |
| `<leader>uh` | Toggle inlay hints |
| `<leader>uD` | Toggle dim (inactive window dim) |

---

## Icons

### 📦 Plugin Info
- **Repository**: [nvim-tree/nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons)

### ✨ Features

파일 타입별 아이콘 제공:
- 프로그래밍 언어 아이콘
- 설정 파일 아이콘
- 폴더 아이콘
- Git 관련 아이콘

### 🔧 Used By

- lualine.nvim
- bufferline.nvim
- snacks.nvim (explorer, picker)

### 📋 Supported File Types

- **Languages**: `.py`, `.js`, `.ts`, `.go`, `.rs`, `.lua`, `.java`, `.c`, `.cpp` 등
- **Config**: `.json`, `.yaml`, `.toml`, `.env` 등
- **Web**: `.html`, `.css`, `.scss`, `.vue`, `.jsx`, `.tsx` 등
- **Tools**: `Dockerfile`, `.nix`, `.tf`, `.sh` 등

---

## Which-Key

### 📦 Plugin Info
- **Repository**: [folke/which-key.nvim](https://github.com/folke/which-key.nvim)
- **Configuration**: [lua/config/plugins/which-key.lua](../which-key.lua)
- **Loading**: `event = "VeryLazy"`

### ✨ Features

키바인딩 도움말을 팝업으로 표시합니다.

### 📋 Keybindings

| Key | Action |
|-----|--------|
| `<leader>?` | Show buffer local keymaps |

### 🎨 UI Configuration

```lua
{
  preset = "modern",       -- 모던 프리셋
  win = {
    border = "rounded",    -- 둥근 테두리
    title_pos = "center",  -- 중앙 제목
    padding = { 2, 2 },    -- 2px 패딩
  }
}
```

### 📂 Defined Key Groups

Which-key는 다음 키 그룹을 인식합니다:

| Prefix | Description |
|--------|-------------|
| `<leader>b` | **Buffer** commands |
| `<leader>c` | **Code** commands |
| `<leader>f` | **Find** commands (picker) |
| `<leader>u` | **UI** toggles |
| `<leader>w` | **Window** commands |

### 💡 Usage

1. `<leader>` (Space) 키를 누르면 약 0.5초 후 도움말 팝업 표시
2. 다음 키를 입력하면 해당 그룹의 키바인딩 목록 표시
3. 원하는 액션의 키를 눌러 실행

#### Example

```
<Space>      →  (0.5초 대기)  →  Which-key 팝업
  ↓
  f          →  Find 그룹 키바인딩 표시
  ↓
  f          →  파일 찾기 실행 (Snacks picker)
```

### 🔧 Customization

#### 지연 시간 조정

```lua
{
  delay = 300,  -- 300ms (기본 500ms)
}
```

#### 키 그룹 추가

```lua
vim.keymap.set("n", "<leader>g", "<cmd>Git<cr>", { desc = "Git commands" })
```

Which-key가 자동으로 `<leader>g` 그룹을 인식합니다.

---

## 🎯 UI Plugin Integration Map

플러그인들이 어떻게 함께 작동하는지 보여주는 다이어그램:

```
┌─────────────────────────────────────────────────┐
│         material.nvim (Theme Layer)             │
│  모든 UI 컴포넌트의 색상 및 스타일 제공            │
└─────────────────────────────────────────────────┘
                      │
        ┌─────────────┼─────────────┬─────────────┐
        │             │             │             │
┌───────▼──────┐ ┌────▼────┐ ┌─────▼─────┐ ┌─────▼──────┐
│   lualine    │ │ buffer  │ │  snacks   │ │ which-key  │
│   (상태바)    │ │  line   │ │  (다목적)  │ │ (도움말)    │
└──────────────┘ └─────────┘ └───────────┘ └────────────┘
                      │             │
              ┌───────┴─────────────┴─────────┐
              │    nvim-web-devicons          │
              │    (아이콘 제공)               │
              └───────────────────────────────┘
```

**통합 포인트**:
- **material.nvim** → lualine, snacks에 테마 제공
- **nvim-web-devicons** → lualine, bufferline, snacks에 아이콘 제공
- **which-key** → 모든 키바인딩에 대한 도움말 제공

---

## 🔗 Related Documentation

- **[Plugin Catalog](../README.md)** - 전체 플러그인 목록
- **[Editing Plugins](../editing/README.md)** - 편집 도구 가이드
- **[Utility Plugins](../utility/README.md)** - 유틸리티 플러그인
- **[Root README](../../../../README.md)** - 전체 설정 개요

---

**6 UI Plugins** | **Last Updated: 2026-01-12**
