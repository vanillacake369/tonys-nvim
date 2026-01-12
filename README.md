# Neovim Configuration

현대적이고 기능이 풍부한 Neovim 개발 환경 설정입니다.

## ✨ 주요 특징

- 🎨 **세련된 UI**: Material Design 테마와 커스텀 상태바
- 🚀 **빠른 성능**: Lazy 플러그인 로딩과 Treesitter 구문 분석
- 🔧 **14개 언어 지원**: LSP, 린터, 자동완성이 포함된 완전한 개발 환경
- 🤖 **AI 코드 완성**: GitHub Copilot 통합
- 📝 **강력한 편집**: 멀티 커서, 정렬, 자동 괄호, 스마트 주석
- 🔍 **효율적인 탐색**: 퍼지 파인더, 파일 탐색기, 버퍼 관리

## 📚 문서 구조

이 설정은 계층적 문서 구조로 구성되어 있습니다:

- **[Core Configuration](lua/config/README.md)** - 기본 설정 파일 설명
- **플러그인 설정** - 카테고리별로 정리된 플러그인 설정
  - **[UI Plugins](lua/plugins/ui/)** - 테마, 상태바, 버퍼라인 등
  - **[Editing Plugins](lua/plugins/editing/)** - 편집 도구 및 유틸리티
  - **[Navigation](lua/plugins/navigation/)** - 파일 탐색기, 검색, 대시보드
  - **[Core Development](lua/plugins/core/)** - LSP 서버, 린터, Treesitter

## 🚀 빠른 시작

### 설치

```bash
# Neovim 설치 (macOS)
brew install neovim

# 이 설정을 복제
git clone <your-repo> ~/.config/nvim

# Neovim 실행 - Lazy.nvim이 자동으로 플러그인 설치
nvim
```

### 첫 실행

1. Neovim을 시작하면 **lazy.nvim**이 자동으로 모든 플러그인을 설치합니다
2. 설치가 완료되면 `:checkhealth`로 설정을 검증합니다
3. 각 LSP 서버는 별도로 설치해야 합니다 (아래 언어 지원 참조)

### 필수 키바인딩

**Leader 키는 `Space`입니다**

| 키바인딩 | 모드 | 기능 |
|---------|------|------|
| `<leader>ff` | Normal | 파일 찾기 (퍼지 파인더) |
| `<leader>fg` | Normal | 텍스트 검색 (Grep) |
| `<leader>fb` | Normal | 버퍼 목록 |
| `<leader>e` | Normal | 파일 탐색기 토글 |
| `<C-_>` | Normal/Insert | 터미널 토글 |
| `gd` | Normal | 정의로 이동 (LSP) |
| `K` | Normal | 호버 문서 (LSP) |
| `gr` | Normal | 참조 찾기 (LSP) |
| `gcc` | Normal | 줄 주석 토글 |
| `<leader>a` | Normal/Visual | 텍스트 정렬 |
| `<M-l>` | Insert | Copilot 제안 수락 |
| `<leader>?` | Normal | 키바인딩 도움말 |

## 🎨 기능별 플러그인

### Theme & UI/UX

| 기능 | 플러그인 | 상태 |
|-----|---------|-----|
| 컬러 테마 | [material.nvim](lua/plugins/ui/theme.lua) | ✅ |
| 상태바 | [lualine.nvim](lua/plugins/ui/theme.lua) | ✅ |
| 버퍼 탭 | [bufferline.nvim](lua/plugins/ui/buffer.lua) | ✅ |
| 다목적 UI | [snacks.nvim](lua/plugins/navigation/snacks.lua) | ✅ |
| 파일 아이콘 | nvim-web-devicons | ✅ |
| 키바인딩 도움말 | [which-key.nvim](lua/plugins/navigation/which-key.lua) | ✅ |

### 코드 편집

| 기능 | 플러그인 | 상태 |
|-----|---------|-----|
| 텍스트 정렬 | [vim-easy-align](lua/plugins/editing/easy-align.lua) | ✅ |
| 자동 괄호 | [nvim-autopairs](lua/plugins/editing/autopairs.lua) | ✅ |
| 스마트 주석 | [Comment.nvim](lua/plugins/editing/comment.lua) | ✅ |
| TODO 하이라이트 | [todo-comments.nvim](lua/plugins/editing/comment.lua) | ✅ |
| 멀티 커서 | [vim-visual-multi](lua/plugins/editing/vim-multiple-cursors.lua) | ✅ |

### 파일 탐색 & 네비게이션

| 기능 | 구현 | 상태 |
|-----|------|-----|
| 퍼지 파인더 | [snacks.nvim picker](lua/plugins/navigation/snacks.lua) | ✅ |
| 파일 탐색기 | [snacks.nvim explorer](lua/plugins/navigation/snacks.lua) | ✅ |
| 버퍼 관리 | [bufferline.nvim](lua/plugins/ui/buffer.lua) | ✅ |
| 빠른 파일 열기 | [snacks.nvim quickfile](lua/plugins/navigation/snacks.lua) | ✅ |

### 개발 핵심 기능

| 기능 | 구현 | 상태 |
|-----|------|-----|
| LSP 통합 | [nvim-lspconfig](lua/plugins/core/lsp.lua) | ✅ 14개 서버 |
| 구문 강조 | [nvim-treesitter](lua/plugins/core/treesitter.lua) | ✅ 30+ 언어 |
| AI 완성 | [copilot.lua](lua/plugins/core/copilot.lua) | ✅ |
| 린팅 | [nvim-lint](lua/plugins/core/lint.lua) | ✅ 9개 린터 |

### 디버깅 & 테스팅

| 기능 | 구현 | 상태 |
|-----|------|-----|
| 디버그 도구 | [snacks.nvim debug](lua/plugins/navigation/snacks.lua) | ✅ |
| 테스트 프레임워크 | - | ⬜ 예정 |

### Git 통합

| 기능 | 구현 | 상태 |
|-----|------|-----|
| Git 도구 | - | ⬜ 예정 |

### 터미널 & 유틸리티

| 기능 | 구현 | 상태 |
|-----|------|-----|
| 통합 터미널 | [snacks.nvim terminal](lua/plugins/navigation/snacks.lua) | ✅ |
| 알림 시스템 | [snacks.nvim notifier](lua/plugins/navigation/snacks.lua) | ✅ |
| 대시보드 | [snacks.nvim dashboard](lua/plugins/navigation/snacks.lua) | ✅ |

## 🌐 언어 지원

14개 프로그래밍 언어를 완벽하게 지원합니다:

| 언어 | LSP 서버 | 린터 | Treesitter |
|-----|---------|------|-----------|
| **Python** | pylsp | ruff | ✅ python, ninja, rst |
| **Java** | jdtls | - | ✅ java |
| **C/C++** | clangd | - | ✅ c, cpp |
| **Go** | gopls | golangcilint | ✅ go, gomod, gowork, gosum |
| **JavaScript** | ts_ls | biomejs | ✅ javascript |
| **TypeScript** | ts_ls | biomejs | ✅ typescript, tsx |
| **Nix** | nil_ls | statix, deadnix | ✅ nix |
| **Lua** | lua_ls | selene | ✅ lua |
| **Terraform** | terraformls | tflint | ✅ terraform, hcl |
| **Bash** | bashls | shellcheck | ✅ bash |
| **HTML** | html | - | ✅ html |
| **CSS** | cssls | - | ✅ css |
| **JSON** | jsonls | - | ✅ json, json5 |
| **YAML** | yamlls | yamllint | ✅ yaml |
| **Docker** | docker_compose_ls | hadolint | ✅ dockerfile |

> 각 언어 서버의 상세 설정 및 설치 방법은 [LSP Configuration](lua/config/plugins/lsp/README.md)을 참조하세요.

## 📦 전체 플러그인 목록 (18개)

### 플러그인 관리
- **[lazy.nvim](https://github.com/folke/lazy.nvim)** - 현대적인 플러그인 매니저

### UI & 시각화 (6개)
- **[material.nvim](https://github.com/marko-cerovac/material.nvim)** - Material Design 컬러 스킴
- **[lualine.nvim](https://github.com/nvim-lualine/lualine.nvim)** - 빠르고 설정 가능한 상태바
- **[bufferline.nvim](https://github.com/akinsho/bufferline.nvim)** - LSP 진단이 포함된 버퍼라인
- **[snacks.nvim](https://github.com/folke/snacks.nvim)** - 13가지 기능의 다목적 플러그인
- **[nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons)** - 파일 타입 아이콘
- **[which-key.nvim](https://github.com/folke/which-key.nvim)** - 키바인딩 도움말 팝업

### 편집 도구 (5개)
- **[vim-easy-align](https://github.com/junegunn/vim-easy-align)** - 대화형 텍스트 정렬
- **[nvim-autopairs](https://github.com/windwp/nvim-autopairs)** - 자동 괄호 쌍
- **[Comment.nvim](https://github.com/numToStr/Comment.nvim)** - 스마트 주석 처리
- **[todo-comments.nvim](https://github.com/folke/todo-comments.nvim)** - TODO/FIXME 하이라이트
- **[vim-visual-multi](https://github.com/mg979/vim-visual-multi)** - 멀티 커서 편집

### 언어 지원 (4개)
- **[nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)** - 구문 분석 및 강조
- **[nvim-lspconfig](https://github.com/neovim/nvim-lspconfig)** - LSP 설정 모음
- **[nvim-lint](https://github.com/mfussenegger/nvim-lint)** - 비동기 린팅 프레임워크
- **[copilot.lua](https://github.com/zbirenbaum/copilot.lua)** - GitHub Copilot 통합

### 유틸리티 (2개)
- **[plenary.nvim](https://github.com/nvim-lua/plenary.nvim)** - 공통 Lua 유틸리티
- **[SchemaStore.nvim](https://github.com/b0o/SchemaStore.nvim)** - JSON/YAML 스키마 저장소

## 📁 프로젝트 구조

```
~/.config/nvim/
├── init.lua                       # 설정 진입점 (core 모듈 로드)
├── lazy-lock.json                 # 플러그인 버전 잠금 파일
│
├── lua/
│   ├── config/
│   │   ├── clipboard.lua          # OSC 52 클립보드 통합
│   │   ├── keybinds.lua           # 전역 키바인딩
│   │   ├── lazy.lua               # Lazy.nvim 플러그인 매니저 설정
│   │   ├── options.lua            # Neovim 편집기 옵션
│   │   │
│   │   └── languages.lua          # LSP 서버 설정 (14개)
│   │
│   └── plugins/                   # 플러그인 설정 (18개)
│       ├── ui/                    # 🎨 테마 & UI (2개)
│       │   ├── theme.lua          # material.nvim + lualine.nvim
│       │   └── buffer.lua         # bufferline.nvim
│       │
│       ├── editing/               # 📝 코드 편집 (4개)
│       │   ├── easy-align.lua     # vim-easy-align
│       │   ├── autopairs.lua      # nvim-autopairs
│       │   ├── comment.lua        # Comment.nvim + todo-comments.nvim
│       │   └── vim-multiple-cursors.lua # vim-visual-multi
│       │
│       ├── navigation/            # 🔍 파일 탐색 (2개)
│       │   ├── snacks.lua         # snacks.nvim (picker, explorer, dashboard)
│       │   └── which-key.lua      # which-key.nvim
│       │
│       └── core/                  # 🔧 개발 핵심 기능 (5개)
│           ├── lsp.lua            # nvim-lspconfig
│           ├── treesitter.lua     # nvim-treesitter
│           ├── lint.lua           # nvim-lint
│           ├── copilot.lua        # copilot.lua
│           └── trouble.lua        # trouble.nvim + SchemaStore.nvim
│
└── README.md                      # 이 파일
```

### 핵심 파일 설명

- **[init.lua](init.lua)** - 전체 설정의 진입점, core 모듈을 순차적으로 로드
- **[lua/config/options.lua](lua/config/README.md#options)** - 라인 번호, 탭 간격, 검색 등 편집기 설정
- **[lua/config/keybinds.lua](lua/config/README.md#keybinds)** - 전역 키바인딩 (윈도우 분할, 기본 편집)
- **[lua/config/clipboard.lua](lua/config/README.md#clipboard)** - OSC 52 프로토콜 클립보드 지원
- **[lua/config/lazy.lua](lua/config/README.md#lazy)** - Lazy.nvim 플러그인 매니저 부트스트랩

> 상세 설명은 [Core Configuration](lua/config/README.md)을 참조하세요.

## ⚙️ 설정 관리

### 새 플러그인 추가하기

1. 적절한 카테고리 디렉토리에 새 `.lua` 파일 생성:
   - Theme/UI: `lua/plugins/ui/`
   - Editing: `lua/plugins/editing/`
   - Navigation: `lua/plugins/navigation/`
   - Core Development: `lua/plugins/core/`

2. 플러그인 스펙을 반환하는 형식으로 작성:

```lua
return {
  "author/plugin-name",
  event = "VeryLazy",  -- 선택사항: lazy loading
  opts = {
    -- 플러그인 옵션
  },
  keys = {
    { "<leader>x", "<cmd>PluginCommand<cr>", desc = "Plugin action" }
  }
}
```

3. Neovim 재시작 - Lazy가 자동으로 인식하고 설치

### 플러그인 관리 명령어

Neovim에서 `:Lazy`를 입력하여 플러그인 매니저 UI를 엽니다:

- `I` - 플러그인 설치
- `U` - 업데이트
- `X` - 제거
- `S` - 동기화 (설치 + 업데이트 + 정리)
- `C` - 변경 사항 확인
- `L` - 로그 보기

### LSP 서버 추가하기

1. `lua/config/lsp/` 디렉토리에 새 `<server>.lua` 파일 생성
2. 서버 설정 반환:

```lua
return {
  name = "server_name",
  cmd = { "language-server-command" },
  filetypes = { "filetype1", "filetype2" },
  settings = {
    -- 서버별 설정
  }
}
```

3. `lua/config/plugins/lspconfig.lua`에서 자동으로 로드됨

> LSP 설정 가이드는 [LSP Configuration](lua/config/plugins/lsp/README.md)을 참조하세요.

## 🔧 커스터마이징

### 테마 변경

`lua/config/plugins/material.lua` 파일에서 스타일 변경:

```lua
style = "darker",  -- lighter, darker, oceanic, palenight, deep ocean
```

### 키바인딩 수정

- 전역 키바인딩: `lua/config/keybinds.lua`
- 플러그인별 키바인딩: 각 플러그인 파일의 `keys` 섹션

### 편집기 옵션 조정

`lua/config/options.lua`에서 설정 변경:

```lua
vim.opt.tabstop = 4        -- 탭 간격
vim.opt.number = true      -- 라인 번호 표시
vim.opt.wrap = false       -- 줄 바꿈 비활성화
```

## 🐛 문제 해결

### LSP가 작동하지 않을 때

1. 언어 서버가 설치되었는지 확인:
```bash
which <server-command>  # 예: which pylsp
```

2. LSP 로그 확인:
```vim
:LspLog
```

3. 건강 체크 실행:
```vim
:checkhealth lsp
```

### 플러그인 로딩 문제

```vim
:Lazy health  # 플러그인 상태 확인
:Lazy sync    # 플러그인 동기화
```

### Treesitter 파서 문제

```vim
:TSInstallInfo           # 설치된 파서 확인
:TSUpdate                # 파서 업데이트
:TSInstall <language>    # 특정 파서 설치
```

## 📊 통계

- **총 플러그인 수**: 18개
- **LSP 서버**: 14개
- **린터**: 9개
- **Treesitter 파서**: 30개 이상
- **커스텀 키바인딩**: 50개 이상
- **지원 언어**: 14개

## 🤝 기여

이슈와 개선 제안은 언제든 환영합니다!

## 📄 라이선스

이 설정은 개인 사용을 위한 것입니다. 자유롭게 사용하고 수정하세요.

---

**Made with ❤️ using Neovim**
