# Editing Plugins Guide

코드 편집 및 조작을 위한 플러그인 상세 가이드입니다.

## 📊 Overview

5개의 편집 도구 플러그인이 설정되어 있습니다:

| Plugin | Purpose | Loading | Keybinding |
|--------|---------|---------|------------|
| [vim-easy-align](#easy-align) | 텍스트 정렬 | VeryLazy | `<leader>a` |
| [nvim-autopairs](#autopairs) | 자동 괄호 | InsertEnter | Auto |
| [Comment.nvim](#comment) | 주석 처리 | Default | `gcc`, `gc` |
| [todo-comments.nvim](#todo-comments) | TODO 하이라이트 | Default | - |
| [vim-visual-multi](#multi-cursor) | 멀티 커서 | Default | `<C-n>` |

---

## Easy Align

### 📦 Plugin Info
- **Repository**: [junegunn/vim-easy-align](https://github.com/junegunn/vim-easy-align)
- **Configuration**: [lua/config/plugins/easy-align.lua](../easy-align.lua)
- **Loading**: `event = "VeryLazy"`

### ✨ Features

구분자를 기준으로 텍스트를 대화형으로 정렬합니다.

### 📋 Keybindings

| Key | Mode | Action |
|-----|------|--------|
| `<leader>a` | Normal | Easy Align (현재 줄부터) |
| `<leader>a` | Visual | Easy Align (선택 영역) |

### 🎯 Usage Examples

#### Example 1: 변수 선언 정렬

**Before**:
```lua
local name = "John"
local age = 30
local city = "Seoul"
local country = "Korea"
```

**After** (`vip<leader>a=`):
```lua
local name    = "John"
local age     = 30
local city    = "Seoul"
local country = "Korea"
```

#### Example 2: JSON/YAML 정렬

**Before**:
```yaml
name: John
age: 30
city: Seoul
occupation: Developer
```

**After** (`vip<leader>a:`):
```yaml
name:       John
age:        30
city:       Seoul
occupation: Developer
```

#### Example 3: Table 정렬

**Before**:
```markdown
| Name | Age | City |
|---|---|---|
| John | 30 | Seoul |
| Jane | 25 | Busan |
```

**After** (`vip<leader>a|`):
```markdown
| Name | Age | City  |
| ---  | --- | ---   |
| John | 30  | Seoul |
| Jane | 25  | Busan |
```

### 📝 Alignment Delimiters

주요 구분자:

| Delimiter | Description | Example |
|-----------|-------------|---------|
| `=` | 등호 | `let x = 1` |
| `:` | 콜론 | `key: value` |
| `,` | 쉼표 | `a, b, c` |
| `|` | 파이프 | Markdown tables |
| `<Space>` | 스페이스 | 단어 정렬 |
| `/` | 정규식 | 커스텀 패턴 |

### 🔧 Interactive Mode

1. 비주얼 모드로 정렬할 텍스트 선택
2. `<leader>a` 입력
3. 구분자 입력 (예: `=`, `:`, `|`)
4. (선택사항) Enter를 눌러 추가 옵션:
   - `l` - 왼쪽 정렬 (Left)
   - `r` - 오른쪽 정렬 (Right)
   - `c` - 가운데 정렬 (Center)

### 💡 Tips

#### Tip 1: 여러 줄 빠르게 정렬

```vim
vip<leader>a=    " 현재 단락(paragraph) 전체를 = 기준으로 정렬
```

#### Tip 2: 특정 줄만 정렬

```vim
V3j<leader>a:    " 현재 줄부터 3줄을 : 기준으로 정렬
```

#### Tip 3: 정규식으로 복잡한 정렬

```vim
vip<leader>a/\s\+/    " 여러 스페이스 기준 정렬
```

---

## Autopairs

### 📦 Plugin Info
- **Repository**: [windwp/nvim-autopairs](https://github.com/windwp/nvim-autopairs)
- **Configuration**: [lua/config/plugins/nvim-autopairs.lua](../nvim-autopairs.lua)
- **Loading**: `event = "InsertEnter"`

### ✨ Features

Insert 모드에서 괄호, 따옴표 등을 자동으로 닫아줍니다.

### 🔧 Auto-completion Pairs

| Input | Result | Cursor Position |
|-------|--------|-----------------|
| `(` | `()` | `(█)` |
| `[` | `[]` | `[█]` |
| `{` | `{}` | `{█}` |
| `"` | `""` | `"█"` |
| `'` | `''` | `'█'` |
| `` ` `` | `` `` ` `` | `` `█` `` |

### 🎯 Smart Behaviors

#### 1. Auto Delete Pair

백스페이스로 여는 괄호 삭제 시 닫는 괄호도 함께 삭제:

```lua
( | )    →  Backspace  →  |
```

#### 2. Skip Closing Character

닫는 괄호 위치에서 같은 문자 입력 시 건너뜀:

```lua
"hello|"   →  type "  →  "hello"|
```

#### 3. Break Line Between Pairs

괄호 사이에서 Enter 입력 시 들여쓰기:

```lua
{|}    →  Enter  →  {
                      |
                    }
```

### 💡 Language-Specific Rules

특정 언어에서의 특수 규칙:

- **Lua**: `then` 이후 `end` 자동 추가
- **Python**: 트리플 큐트 `` ``` `` 자동 완성
- **Markdown**: 코드 블록 자동 완성

### 🔧 Configuration

Default 설정 사용 중. 커스터마이징은 `lua/config/plugins/nvim-autopairs.lua`에서:

```lua
{
  check_ts = true,         -- Treesitter 통합
  ts_config = {
    lua = {'string'},      -- Lua 문자열 내부에서는 비활성화
    javascript = {'template_string'},
  },
  fast_wrap = {},          -- Alt+e로 빠른 감싸기
}
```

---

## Comment

### 📦 Plugin Info
- **Repository**: [numToStr/Comment.nvim](https://github.com/numToStr/Comment.nvim)
- **Configuration**: [lua/config/plugins/comment.lua](../comment.lua)

### ✨ Features

스마트 주석 처리:
- 언어별 주석 스타일 자동 감지
- Treesitter 통합
- 모션 지원
- 비주얼 모드 지원

### 📋 Keybindings

#### Line Comments

| Key | Mode | Action |
|-----|------|--------|
| `gcc` | Normal | 현재 줄 주석 토글 |
| `gc{motion}` | Normal | 모션 범위 주석 토글 |
| `gc` | Visual | 선택 영역 라인 주석 |

#### Block Comments

| Key | Mode | Action |
|-----|------|--------|
| `gbc` | Normal | 현재 줄 블록 주석 토글 |
| `gb{motion}` | Normal | 모션 범위 블록 주석 |
| `gb` | Visual | 선택 영역 블록 주석 |

### 🎯 Usage Examples

#### Example 1: 단일 줄 주석

```lua
local name = "John"    →  gcc  →  -- local name = "John"
```

#### Example 2: 여러 줄 주석

```lua
local function greet()     →  Vjj + gc  →  -- local function greet()
  print("Hello")                              --   print("Hello")
end                                           -- end
```

#### Example 3: 모션과 함께

```lua
gcap    " 현재 단락(paragraph) 주석 토글
gc3j    " 현재 줄부터 3줄 주석 토글
gcG     " 현재 줄부터 파일 끝까지 주석 토글
```

#### Example 4: 블록 주석 (C/C++, CSS 등)

```c
int x = 5;    →  gbc  →  /* int x = 5; */
```

### 🌐 Language Support

자동으로 감지되는 주석 스타일:

| Language | Line Comment | Block Comment |
|----------|--------------|---------------|
| Lua | `--` | `--[[ ]]` |
| Python | `#` | `"""` |
| JavaScript | `//` | `/* */` |
| C/C++ | `//` | `/* */` |
| HTML | - | `<!-- -->` |
| CSS | - | `/* */` |
| Bash | `#` | - |
| Nix | `#` | `/* */` |

### 💡 Tips

#### Tip 1: 블록 전체 주석

```vim
gcap    " 현재 블록(paragraph) 주석 토글
```

#### Tip 2: 함수 전체 주석

```vim
gcaf    " 현재 함수 주석 토글 (Treesitter 필요)
```

#### Tip 3: 주석 해제

이미 주석 처리된 코드에 다시 `gcc` 입력하면 주석 해제

---

## TODO Comments

### 📦 Plugin Info
- **Repository**: [folke/todo-comments.nvim](https://github.com/folke/todo-comments.nvim)
- **Configuration**: [lua/config/plugins/todo-comments.lua](../todo-comments.lua)
- **Dependencies**: `plenary.nvim`

### ✨ Features

특수 주석 키워드를 시각적으로 강조합니다.

### 🎨 Highlighted Keywords

| Keyword | Color | Icon | Usage |
|---------|-------|------|-------|
| `FIX` / `FIXME` | 🔴 Red | ⚠ | 버그 또는 문제 |
| `TODO` | 🔵 Blue | ✓ | 할 일 |
| `HACK` | 🟠 Orange | ⚠ | 임시 해결책 |
| `WARN` / `WARNING` | 🟡 Yellow | ⚠ | 경고 |
| `PERF` / `PERFORMANCE` | 🟣 Purple | ⚡ | 성능 개선 필요 |
| `NOTE` / `INFO` | 🟢 Green | ℹ | 중요 정보 |
| `TEST` / `TESTING` | 🔵 Cyan | ⚗ | 테스트 관련 |

### 🎯 Usage Examples

#### Example 1: TODO

```lua
-- TODO: 사용자 인증 기능 추가
function login(username, password)
  -- implementation
end
```

#### Example 2: FIXME

```python
# FIXME: 이 함수는 빈 리스트에서 에러 발생
def process_items(items):
    return items[0]  # IndexError 가능성
```

#### Example 3: HACK

```javascript
// HACK: 임시 해결책 - 나중에 제대로 구현 필요
setTimeout(() => {
  checkStatus();
}, 5000);
```

#### Example 4: NOTE

```go
// NOTE: 이 함수는 goroutine-safe하지 않음
func updateCounter() {
    counter++
}
```

### 🔍 Search TODO Comments

Telescope나 grep으로 TODO 주석 검색:

```vim
:TodoTelescope    " Telescope로 TODO 목록 보기
:TodoQuickFix     " QuickFix 리스트로 보기
```

### 🔧 Configuration

Default 설정 사용 중. 커스터마이징은 `lua/config/plugins/todo-comments.lua`에서:

```lua
{
  keywords = {
    CUSTOM = { icon = "★", color = "hint" },
  },
  highlight = {
    before = "",        -- 키워드 앞 강조
    keyword = "wide",   -- 키워드 강조
    after = "fg",       -- 키워드 뒤 강조
  }
}
```

### 💡 Tips

#### Tip 1: 프로젝트 전체 TODO 보기

```vim
<leader>fg TODO    " Snacks picker로 TODO 검색
```

#### Tip 2: 우선순위 태그

```lua
-- TODO(high): 긴급 수정 필요
-- TODO(low): 나중에 고려
```

#### Tip 3: 이슈 번호 연결

```python
# FIXME(#123): GitHub 이슈 123번 참조
```

---

## Multi-Cursor

### 📦 Plugin Info
- **Repository**: [mg979/vim-visual-multi](https://github.com/mg979/vim-visual-multi)
- **Configuration**: [lua/config/plugins/vim-visual-multi.lua](../vim-visual-multi.lua)

### ✨ Features

Visual Studio Code와 유사한 멀티 커서 편집:
- 여러 위치 동시 편집
- 패턴 매칭 커서
- 비주얼 선택 확장

### 📋 Keybindings

#### Basic Multi-Cursor

| Key | Mode | Action |
|-----|------|--------|
| `<C-n>` | Normal | 커서 아래 단어 선택 + 다음 찾기 |
| `<C-n>` | Visual | 선택 영역 + 다음 일치 항목 찾기 |
| `<C-Down>` | Normal | 아래에 커서 추가 |
| `<C-Up>` | Normal | 위에 커서 추가 |

#### Advanced Selection

| Key | Action |
|-----|--------|
| `\\A` | 현재 단어의 모든 일치 항목 선택 |
| `\\\/` | 정규식으로 패턴 선택 |
| `\\c` | 케이스 구분 토글 |

#### Multi-Cursor Mode

멀티 커서 모드에 진입하면:

| Key | Action |
|-----|--------|
| `n` | 다음 일치 항목 건너뛰기 |
| `N` | 이전 일치 항목 제거 |
| `q` | 현재 선택 건너뛰기 |
| `Q` | 현재 선택 제거 및 이전으로 |
| `Tab` | 커서 간 전환 |
| `<Esc>` | 멀티 커서 모드 종료 |

### 🎯 Usage Examples

#### Example 1: 변수 이름 일괄 변경

**Before**:
```python
name = "John"
print(name)
log(name)
return name
```

**Steps**:
1. `name` 위에서 `\\A` (모든 일치 항목 선택)
2. `c` (change) 입력
3. 새 이름 입력: `username`
4. `<Esc>`

**After**:
```python
username = "John"
print(username)
log(username)
return username
```

#### Example 2: 여러 줄 동시 편집

**Before**:
```javascript
const user = getUser();
const product = getProduct();
const order = getOrder();
```

**Steps**:
1. 첫 줄에서 `<C-Down>` 두 번 (3개 커서)
2. `A` (줄 끝으로 이동 + Insert)
3. `.then(handleResponse)` 입력
4. `<Esc>`

**After**:
```javascript
const user = getUser().then(handleResponse);
const product = getProduct().then(handleResponse);
const order = getOrder().then(handleResponse);
```

#### Example 3: 패턴 매칭 선택

**Task**: `console.log`를 모두 `logger.info`로 변경

**Steps**:
1. `/console\.log` 검색
2. `\\A` (모든 일치 항목 선택)
3. `c` + `logger.info`
4. `<Esc>`

### 💡 Advanced Features

#### 1. Extend Mode

비주얼 선택을 여러 줄로 확장:

```vim
<C-n>    " 선택 시작
n        " 다음 일치 항목에도 선택 추가
c        " 모든 선택 영역을 동시에 변경
```

#### 2. Column Mode

세로 블록 선택:

```vim
<C-Down>    " 수직 커서
I           " Insert 모드로 블록 편집
```

#### 3. Regex Mode

정규식으로 복잡한 패턴 선택:

```vim
\\\/        " Regex 입력 모드
\d+         " 모든 숫자 선택
c           " 변경
```

### 🔧 Configuration

Default 설정 사용 중. 커스터마이징은 `lua/config/plugins/vim-visual-multi.lua`에서:

```lua
vim.g.VM_maps = {
  ['Find Under'] = '<C-n>',
  ['Find Subword Under'] = '<C-n>',
}
```

### 💡 Tips

#### Tip 1: 특정 일치 항목만 선택

`<C-n>`으로 하나씩 선택하면서 `q`로 건너뛰기

#### Tip 2: 수직 편집

```vim
<C-Down>    " 여러 줄에 커서
I//         " 모든 줄 앞에 // 추가
```

#### Tip 3: 케이스 구분 토글

```vim
<C-n>       " 단어 선택
\\c         " 대소문자 구분 토글
```

---

## 🔗 Editing Workflow Integration

플러그인들을 조합한 효율적인 워크플로우:

### Workflow 1: 코드 정리

```vim
1. vip           " 블록 선택
2. <leader>a=    " 변수 정렬
3. gcc           " 주석 추가
```

### Workflow 2: 리팩토링

```vim
1. <C-n>         " 변수 이름 선택
2. \\A           " 모든 일치 항목
3. c             " 변경
4. new_name      " 새 이름 입력
```

### Workflow 3: TODO 관리

```vim
1. gcc           " 현재 줄 주석
2. A             " 줄 끝으로
3. TODO: task    " TODO 추가
4. <leader>fg TODO   " TODO 검색으로 확인
```

---

## 🔗 Related Documentation

- **[Plugin Catalog](../README.md)** - 전체 플러그인 목록
- **[UI Plugins](../ui/README.md)** - UI 플러그인 가이드
- **[Utility Plugins](../utility/README.md)** - 유틸리티 플러그인
- **[Root README](../../../../README.md)** - 전체 설정 개요

---

**5 Editing Plugins** | **Last Updated: 2026-01-12**
