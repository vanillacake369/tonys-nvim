# Plugin Catalog

Neovim 설정에 사용된 모든 플러그인의 상세 카탈로그입니다.

## 📊 Overview

| 카테고리 | 플러그인 수 | 설명 |
|---------|-----------|------|
| **[UI & Visualization](#ui--visualization)** | 6개 | 테마, 상태바, 버퍼라인, 다목적 UI |
| **[Editing Tools](#editing-tools)** | 5개 | 텍스트 정렬, 자동 괄호, 주석, 멀티 커서 |
| **[Language Support](#language-support)** | 4개 | LSP, Treesitter, 린터, AI 완성 |
| **[Utilities](#utilities)** | 2개 | 지원 라이브러리 |
| **Total** | **18개** | 플러그인 관리자 포함 |

## 🔧 Plugin Loading Strategy

이 설정은 **lazy.nvim**을 사용하여 플러그인을 효율적으로 로드합니다:

### Lazy Loading 전략

| 로딩 방식 | 사용 사례 | 예시 |
|----------|----------|------|
| `lazy = false` | 즉시 로드 필요 | material.nvim (테마), snacks.nvim |
| `event = "VeryLazy"` | Neovim 시작 후 지연 로드 | bufferline, which-key, vim-easy-align |
| `event = "InsertEnter"` | Insert 모드 진입 시 | nvim-autopairs |
| `event = "BufReadPost"` | 파일 읽기 후 | nvim-lint |
| `keys = {...}` | 키바인딩 사용 시 | - |
| `dependencies` | 다른 플러그인 의존성 | lualine → nvim-web-devicons |

### Priority 설정

| Priority | 플러그인 | 이유 |
|----------|---------|------|
| `1000` | material.nvim, snacks.nvim | UI 테마는 가장 먼저 로드되어야 함 |
| Default | 나머지 플러그인 | 일반 우선순위 |

## 📦 Complete Plugin List

### Plugin Manager

#### lazy.nvim
- **Repository**: [folke/lazy.nvim](https://github.com/folke/lazy.nvim)
- **Purpose**: 현대적이고 빠른 플러그인 매니저
- **Features**:
  - 자동 lazy loading
  - 플러그인 변경 감지
  - 버전 잠금 (lazy-lock.json)
  - 빌트인 UI (:Lazy 명령)
- **Configuration**: [lua/config/lazy.lua](../lazy.lua)

---

## UI & Visualization

### 1. material.nvim
- **Repository**: [marko-cerovac/material.nvim](https://github.com/marko-cerovac/material.nvim)
- **Category**: Theme
- **Loading**: `lazy = false`, `priority = 1000`
- **Purpose**: Material Design 컬러 스킴
- **Features**:
  - 5가지 스타일 (darker, lighter, oceanic, palenight, deep ocean)
  - Lualine 통합
  - 비동기 로딩
- **Current Style**: `darker`
- **Documentation**: [UI Plugins Guide](ui/README.md#material-theme)

### 2. lualine.nvim
- **Repository**: [nvim-lualine/lualine.nvim](https://github.com/nvim-lualine/lualine.nvim)
- **Category**: Status Line
- **Dependencies**: `nvim-web-devicons`
- **Purpose**: 빠르고 커스터마이징 가능한 상태바
- **Features**:
  - Material 테마 적용
  - 모드 표시 (INSERT, NORMAL 등)
  - 전역 상태바
- **Configuration**: 미니멀 디자인 (모드만 표시)
- **Documentation**: [UI Plugins Guide](ui/README.md#lualine)

### 3. bufferline.nvim
- **Repository**: [akinsho/bufferline.nvim](https://github.com/akinsho/bufferline.nvim)
- **Category**: Buffer Management
- **Loading**: `event = "VeryLazy"`
- **Purpose**: LSP 진단이 포함된 버퍼 탭 라인
- **Features**:
  - 버퍼 탭 시각화
  - LSP 진단 표시
  - 버퍼 핀 기능
  - 버퍼 정렬 및 이동
- **Keybindings**:
  - `<leader>bd*` - 버퍼 삭제 관련
  - `<S-h>`, `<S-l>` - 버퍼 이동
  - `[B]`, `]B` - 버퍼 순서 변경
- **Documentation**: [UI Plugins Guide](ui/README.md#bufferline)

### 4. snacks.nvim
- **Repository**: [folke/snacks.nvim](https://github.com/folke/snacks.nvim)
- **Category**: Multi-purpose UI
- **Loading**: `lazy = false`, `priority = 1000`
- **Purpose**: 13가지 기능을 제공하는 올인원 플러그인
- **Enabled Modules**:
  - `bigfile` - 대용량 파일 처리
  - `dashboard` - 시작 화면
  - `explorer` - 파일 탐색기
  - `indent` - 인덴트 가이드
  - `input` - 입력 다이얼로그
  - `notifier` - 알림 시스템 (3초 타임아웃)
  - `terminal` - 통합 터미널
  - `picker` - 퍼지 파인더
  - `quickfile` - 빠른 파일 열기
  - `scope` - 스코프 관리
  - `scroll` - 부드러운 스크롤
  - `statuscolumn` - 커스텀 상태 컬럼
  - `words` - 단어 하이라이트
- **Keybindings**:
  - `<leader>ff`, `<leader>fg`, `<leader>fb` - Picker
  - `<leader>e` - Explorer
  - `<C-_>` - Terminal
  - `<leader>u*` - UI 토글 (spelling, wrap, diagnostics 등)
- **Global Functions**:
  - `_G.dd()` - 디버그 inspect
  - `_G.bt()` - Backtrace
- **Documentation**: [UI Plugins Guide](ui/README.md#snacks)

### 5. nvim-web-devicons
- **Repository**: [nvim-tree/nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons)
- **Category**: Icons
- **Purpose**: 파일 타입 및 프로젝트 아이콘
- **Features**:
  - 파일 확장자별 아이콘
  - 폴더 아이콘
  - 테마 통합
- **Used by**: lualine.nvim, bufferline.nvim, snacks.nvim
- **Documentation**: [UI Plugins Guide](ui/README.md#icons)

### 6. which-key.nvim
- **Repository**: [folke/which-key.nvim](https://github.com/folke/which-key.nvim)
- **Category**: Help & Documentation
- **Loading**: `event = "VeryLazy"`
- **Purpose**: 키바인딩 도움말 팝업
- **Features**:
  - 모던 프리셋
  - 둥근 테두리
  - 중앙 정렬 제목
  - 2px 패딩
- **Defined Groups**:
  - `<leader>b` - Buffer commands
  - `<leader>c` - Code commands
  - `<leader>f` - Find commands
  - `<leader>u` - UI toggles
  - `<leader>w` - Window commands
- **Keybinding**: `<leader>?` - 로컬 키맵 표시
- **Documentation**: [UI Plugins Guide](ui/README.md#which-key)

---

## Editing Tools

### 1. vim-easy-align
- **Repository**: [junegunn/vim-easy-align](https://github.com/junegunn/vim-easy-align)
- **Category**: Text Alignment
- **Loading**: `event = "VeryLazy"`
- **Purpose**: 대화형 텍스트 정렬
- **Features**:
  - 구분자 기준 정렬 (=, :, , 등)
  - 비주얼 모드 지원
  - 정규식 구분자
- **Keybinding**: `<leader>a` (Normal & Visual)
- **Documentation**: [Editing Plugins Guide](editing/README.md#easy-align)

### 2. nvim-autopairs
- **Repository**: [windwp/nvim-autopairs](https://github.com/windwp/nvim-autopairs)
- **Category**: Auto-completion
- **Loading**: `event = "InsertEnter"`
- **Purpose**: 자동 괄호/따옴표 쌍 완성
- **Features**:
  - 자동 괄호 닫기 (), [], {}
  - 자동 따옴표 닫기 '', "", ``
  - 스마트 삭제
- **Configuration**: Default
- **Documentation**: [Editing Plugins Guide](editing/README.md#autopairs)

### 3. Comment.nvim
- **Repository**: [numToStr/Comment.nvim](https://github.com/numToStr/Comment.nvim)
- **Category**: Commenting
- **Purpose**: 스마트 코드 주석 처리
- **Features**:
  - 라인 주석 토글 (gcc)
  - 블록 주석 토글 (gbc)
  - 비주얼 모드 주석 (gc)
  - Treesitter 통합
- **Default Keybindings**:
  - `gcc` - 현재 줄 주석 토글
  - `gc` (Visual) - 선택 영역 주석
  - `gbc` - 블록 주석 토글
- **Documentation**: [Editing Plugins Guide](editing/README.md#comment)

### 4. todo-comments.nvim
- **Repository**: [folke/todo-comments.nvim](https://github.com/folke/todo-comments.nvim)
- **Category**: Syntax Highlighting
- **Dependencies**: `plenary.nvim`
- **Purpose**: TODO, FIXME, HACK 등 주석 하이라이트
- **Features**:
  - 키워드별 색상 구분
  - 검색 통합
  - 퀵픽스 리스트
- **Highlighted Keywords**:
  - TODO, HACK, WARN, PERF, NOTE, TEST, FIX
- **Configuration**: Default
- **Documentation**: [Editing Plugins Guide](editing/README.md#todo-comments)

### 5. vim-visual-multi
- **Repository**: [mg979/vim-visual-multi](https://github.com/mg979/vim-visual-multi)
- **Category**: Multi-cursor
- **Purpose**: 멀티 커서 편집
- **Features**:
  - 여러 커서 동시 편집
  - 비주얼 선택 확장
  - 패턴 매칭 커서
- **Default Keybindings**:
  - `<C-n>` - 단어 선택 및 다음 찾기
  - `<C-Down>`, `<C-Up>` - 수직 커서 추가
  - `\\A` - 모든 일치 항목 선택
- **Documentation**: [Editing Plugins Guide](editing/README.md#multi-cursor)

---

## Language Support

### 1. nvim-treesitter
- **Repository**: [nvim-treesitter/nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)
- **Category**: Syntax Parser
- **Loading**: `lazy = false`
- **Build**: `:TSUpdate`
- **Purpose**: 구문 분석 및 강조
- **Features**:
  - 향상된 구문 강조
  - 스마트 인덴트
  - 자동 태그 닫기
- **Installed Parsers** (30+):
  - **Languages**: python, java, c, cpp, go, javascript, typescript, tsx, nix, lua, terraform, bash
  - **Web**: html, css, json, json5, yaml
  - **Config**: dockerfile, helm, hcl
  - **Docs**: markdown, markdown_inline, rst
  - **Tools**: gomod, gowork, gosum, ninja, query, regex, vim
- **Enabled Features**:
  - `highlight` - 구문 강조
  - `indent` - 자동 인덴트
  - `autotag` - HTML/XML 태그 자동 닫기
- **Configuration**: [lua/config/plugins/treesitter.lua](treesitter.lua)

### 2. nvim-lspconfig
- **Repository**: [neovim/nvim-lspconfig](https://github.com/neovim/nvim-lspconfig)
- **Category**: Language Server Protocol
- **Purpose**: LSP 서버 통합 설정
- **Features**:
  - 14개 LSP 서버 지원
  - 자동 서버 설정
  - 진단 설정
- **Configured Servers**:
  - Python (pylsp), Java (jdtls), C/C++ (clangd), Go (gopls)
  - JavaScript/TypeScript (ts_ls), Nix (nil_ls), Lua (lua_ls)
  - Terraform (terraformls), Bash (bashls)
  - HTML (html), CSS (cssls), JSON (jsonls), YAML (yamlls)
  - Docker (docker_compose_language_service)
- **Core Keybindings**:
  - `gd` - Go to definition
  - `K` - Hover documentation
  - `gr` - Find references
- **Diagnostic Configuration**:
  - Virtual text with "●" prefix
  - Underline enabled
  - Signs in gutter
  - Auto popup on cursor hold
- **Configuration**: [lua/config/plugins/lspconfig.lua](lspconfig.lua)

### 3. nvim-lint
- **Repository**: [mfussenegger/nvim-lint](https://github.com/mfussenegger/nvim-lint)
- **Category**: Linting
- **Loading**: `event = "BufReadPost", "BufNewFile"`
- **Purpose**: 비동기 린팅 프레임워크
- **Features**:
  - 파일 읽기/쓰기 시 자동 린팅
  - Insert 모드 종료 시 린팅
- **Configured Linters**:
  - Bash: `shellcheck`
  - Go: `golangcilint`
  - Python: `ruff`
  - Nix: `statix`, `deadnix`
  - Lua: `selene`
  - Terraform: `tflint`
  - Dockerfile: `hadolint`
  - JavaScript/TypeScript: `biomejs`
  - YAML: `yamllint`
- **Auto-trigger Events**:
  - BufReadPost (파일 읽기 후)
  - BufWritePost (파일 저장 후)
  - InsertLeave (Insert 모드 종료)
- **Configuration**: [lua/config/plugins/lint.lua](lint.lua)

### 4. copilot.lua
- **Repository**: [zbirenbaum/copilot.lua](https://github.com/zbirenbaum/copilot.lua)
- **Category**: AI Completion
- **Purpose**: GitHub Copilot 통합
- **Features**:
  - AI 기반 코드 완성
  - 제안 패널
  - 자동 트리거
- **Keybindings**:
  - `<M-l>` - Accept suggestion
  - `<M-]>` - Next suggestion
  - `<M-[>` - Previous suggestion
  - `<C-]>` - Dismiss suggestion
- **Panel Features**:
  - 수동 새로고침
  - 제안 목록 보기
- **Configuration**: [lua/config/plugins/copilot.lua](copilot.lua)

---

## Utilities

### 1. plenary.nvim
- **Repository**: [nvim-lua/plenary.nvim](https://github.com/nvim-lua/plenary.nvim)
- **Category**: Library
- **Purpose**: 공통 Lua 유틸리티 라이브러리
- **Features**:
  - 비동기 작업
  - 파일 I/O
  - 경로 유틸리티
  - 테스트 프레임워크
- **Used by**: todo-comments.nvim, 기타 여러 플러그인
- **Documentation**: [Utility Plugins Guide](utility/README.md#plenary)

### 2. SchemaStore.nvim
- **Repository**: [b0o/SchemaStore.nvim](https://github.com/b0o/SchemaStore.nvim)
- **Category**: Schema Support
- **Purpose**: JSON/YAML 스키마 저장소
- **Features**:
  - JSON 스키마 자동 완성
  - YAML 스키마 지원
  - LSP 통합
- **Schemas Included**:
  - package.json, tsconfig.json
  - GitHub Workflows, Actions
  - Docker Compose
  - Kubernetes, Helm
  - Ansible, Terraform
  - 기타 100개 이상의 스키마
- **Used by**: jsonls, yamlls LSP servers
- **Documentation**: [Utility Plugins Guide](utility/README.md#schemastore)

---

## 📋 Plugin Quick Reference Table

| Plugin | Category | Lazy Load | Priority | Keybindings | Dependencies |
|--------|----------|-----------|----------|-------------|--------------|
| **lazy.nvim** | Manager | - | - | `:Lazy` | - |
| **material.nvim** | Theme | ❌ No | 1000 | - | - |
| **lualine.nvim** | UI | Default | - | - | nvim-web-devicons |
| **bufferline.nvim** | UI | VeryLazy | - | `<leader>bd*`, `<S-h/l>` | - |
| **snacks.nvim** | UI | ❌ No | 1000 | `<leader>f*`, `<leader>e`, `<C-_>` | - |
| **nvim-web-devicons** | UI | - | - | - | - |
| **which-key.nvim** | UI | VeryLazy | - | `<leader>?` | - |
| **vim-easy-align** | Editing | VeryLazy | - | `<leader>a` | - |
| **nvim-autopairs** | Editing | InsertEnter | - | Auto | - |
| **Comment.nvim** | Editing | Default | - | `gcc`, `gc` | - |
| **todo-comments.nvim** | Editing | Default | - | - | plenary.nvim |
| **vim-visual-multi** | Editing | Default | - | `<C-n>` | - |
| **nvim-treesitter** | Language | ❌ No | - | - | - |
| **nvim-lspconfig** | Language | Default | - | `gd`, `K`, `gr` | - |
| **nvim-lint** | Language | BufRead | - | Auto | - |
| **copilot.lua** | Language | Default | - | `<M-l>`, `<M-]>` | - |
| **plenary.nvim** | Utility | - | - | - | - |
| **SchemaStore.nvim** | Utility | - | - | - | - |

---

## 🔗 Related Documentation

- **[Root README](../../../README.md)** - 전체 설정 개요
- **[Core Configuration](../README.md)** - 기본 설정 파일
- **[UI Plugins](ui/README.md)** - UI 플러그인 상세 가이드
- **[Editing Plugins](editing/README.md)** - 편집 도구 상세 가이드
- **[Utility Plugins](utility/README.md)** - 유틸리티 플러그인 가이드

---

**Total Plugins: 18** | **Last Updated: 2026-01-12**
