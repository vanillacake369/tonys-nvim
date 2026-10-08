# Host Convention Routing Spec

## Goal

기본 formatter/linter 는 `tonys-nix`와 `tonys-nvim`의 tracked 설정을 따른다.
단, 특정 workspace path 에서는 회사/프로젝트 컨벤션 pack 을 적용한다.

첫 대상은 `~/dev/vpp-*` 아래 Java 파일이다. 이 경로 또는 명시 marker 로 VPP
workspace 임이 확인되면 VPP Lab Java 컨벤션을 적용하고, 그 밖의 경로에서는
기존 `tonys-nvim` 기본 설정을 사용한다.

VPP Lab Java 컨벤션:
https://vpplab.atlassian.net/wiki/spaces/VPP/pages/267681797/DEV-B-002-01+BE+Convention+Java

## Requirements

- 기본 formatter/linter 동작은 tracked `tonys-nvim` 설정을 따른다.
- Java 기본 formatter 는 non-VPP workspace 에서도 `clang-format-java`를 사용한다.
- VPP Lab workspace 에서는 Java formatter/linter 를 VPP Lab convention pack 으로
  교체한다.
- VPP Lab convention pack 은 이 Mac local-only 로 유지한다.
- VPP Lab workspace 판별은 local rule 에서 선언한 `roots` 또는 `markers`로
  수행한다.
- marker 는 `.gitignore` 같은 표식 파일/디렉토리다. 임의의 상위 디렉토리에
  marker 가 있으면 그 하위 buffer 는 해당 convention rule 을 따른다.
- convention 선택은 plugin load 시점이 아니라 buffer formatter/linter 실행
  시점에 결정한다.
- resolver 실패, local module 누락, convention pack setup 실패는 저장을 막지
  않고 warning 후 fallback 을 사용한다.
- local-only 파일은 Git에 올라가지 않아야 한다.

## Acceptance Criteria

- `~/dev/vpp-*` 아래 Java buffer 는 `vpplab-java-format`을 formatter 로 선택한다.
- `.vpplab-convention` marker 아래 Java buffer 는 path 이름과 무관하게
  `vpplab-java-format`을 formatter 로 선택한다.
- VPP Lab rule 이 매칭된 Java buffer 는 `vpplab-java-convention` linter 를
  실행한다.
- VPP Lab rule 이 매칭되지 않은 Java buffer 는 `clang-format-java` formatter 를
  선택한다.
- VPP Lab rule 이 매칭되지 않은 Java buffer 는 VPP Lab linter 를 실행하지 않는다.
- 기존 Lua/Python/Go 등 tracked formatter/linter mapping 은 유지된다.
- `git status --short`에는 tracked 구현 변경만 보이고 local convention pack 과
  local rules 는 ignored 상태여야 한다.
- headless Neovim 검증으로 VPP path, marker path, non-VPP path 를 각각 확인한다.

## Non-Goals

- lazy.nvim plugin spec 을 workspace 마다 load/unload 하지 않는다.
- tracked `lua/plugins/lang/java.lua`에 회사별 정책을 직접 넣지 않는다.
- 모든 컨벤션을 formatter 로 자동 수정하려 하지 않는다.
- 정적 분석 도구 설치를 이 repo 안에서 강제하지 않는다.
- 회사/프로젝트 판별을 코드에 하드코딩하지 않는다. path 와 marker 는 local
  rule 에서 선언한다.

## Design

컨벤션 선택은 plugin load 시점이 아니라 buffer 실행 시점에 결정한다.

```text
buffer path + ancestor markers
  -> convention resolver
  -> matched convention pack
  -> formatter/linter names for filetype
  -> conform.nvim / nvim-lint execution
```

tracked 코드가 제공하는 것은 resolver contract 와 기본 fallback 이다.
호스트/회사별 규칙은 ignored local Lua 파일에 둔다.

## Files

Tracked:

- `lua/config/conventions.lua`
  - path pattern matching
  - convention pack loading
  - formatter/linter resolution
  - default fallback
- `lua/plugins/core/format.lua`
  - `formatters_by_ft.<filetype>`가 resolver 를 호출할 수 있게 연결
- `lua/plugins/core/lint.lua`
  - lint 실행 시 resolver 가 선택한 linter list 를 사용하게 연결
- `README.md`
  - host-local convention adapter 운영 원칙

Ignored local:

- `lua/config/conventions_local.lua`
  - 이 호스트의 path pattern, marker, convention pack 매핑
- `lua/plugins/conventions/vpplab_local.lua`
  - VPP Lab convention pack manifest
- `lua/plugins/conventions/vpplab_java_formatter_local.lua`
  - VPP Lab Java formatter definition
- `lua/plugins/conventions/vpplab_java_linter_local.lua`
  - VPP Lab Java linter definition

`lua/plugins/conventions/*_local.lua`도 local-only pack 으로 허용한다.

## Resolver Contract

`lua/config/conventions.lua`는 다음 API를 제공한다.

```lua
local M = {}

function M.match(bufnr) end
function M.formatters(bufnr, filetype, fallback) end
function M.linters(bufnr, filetype, fallback) end

return M
```

### `match(bufnr)`

현재 buffer path 를 기준으로 가장 먼저 매칭되는 convention rule 을 반환한다.
매칭되는 rule 이 없으면 `nil`을 반환한다.

Rule shape:

```lua
{
    name = "vpplab",
    roots = { "~/dev/vpp-*" },
    markers = {
        ".vpplab-convention",
    },
    module = "plugins.conventions.vpplab_local",
}
```

`roots`와 `markers`는 OR 조건이다. 둘 중 하나만 매칭되어도 rule 이 선택된다.
둘 다 생략한 rule 은 무시한다.

### `roots`

glob-like path pattern 목록이다. buffer path 가 하나라도 매칭되면 rule 이
선택된다.

### `markers`

buffer path 에서 상위 디렉토리로 올라가며 찾을 marker 파일/디렉토리 이름
목록이다. 하나라도 발견되면 rule 이 선택된다. marker 는 magic value 를 코드에
숨기지 않기 위한 local 선언이다.

### `formatters(bufnr, filetype, fallback)`

반환값은 conform formatter name list 다.

우선순위:

1. 매칭된 convention pack 의 `formatters_by_ft[filetype]`
2. `fallback`

### `linters(bufnr, filetype, fallback)`

반환값은 nvim-lint linter name list 다.

우선순위:

1. 매칭된 convention pack 의 `linters_by_ft[filetype]`
2. `fallback`

## Convention Pack Contract

Convention pack 은 formatter/linter 이름과 필요한 tool definition 을 제공한다.
SRP 를 지키기 위해 manifest 는 formatter/linter module 을 조합하고, 실제
formatter 정의와 linter 진단 규칙은 별도 module 이 소유한다.

```lua
local formatter = require("plugins.conventions.vpplab_java_formatter_local")
local linter = require("plugins.conventions.vpplab_java_linter_local")

return {
    name = "vpplab",
    formatters_by_ft = {
        java = { formatter.name },
    },
    linters_by_ft = {
        java = { linter.name },
    },
    setup = function()
        formatter.setup()
        linter.setup()
    end,
}
```

`setup()`은 idempotent 해야 한다. 같은 buffer 에서 여러 번 호출되어도 formatter
와 linter definition 을 중복 생성하거나 상태를 누적하지 않는다.

## Local Rules Example

`lua/config/conventions_local.lua`:

```lua
return {
    {
        name = "vpplab",
        roots = { "~/dev/vpp-*" },
        markers = {
            ".vpplab-convention",
        },
        module = "plugins.conventions.vpplab_local",
    },
}
```

`~`는 `vim.fn.expand()`로 확장한다. pattern 은 Lua pattern 이 아니라 glob-like
path pattern 으로 해석한다. 구현은 `vim.fn.glob()` 또는 `vim.fs` 기반으로
정규화하되, 스펙의 사용자 표면은 glob 을 유지한다.

marker 는 repo root 또는 submodule root 에 둘 수 있다. VPP repo 에 marker 를
추가할 수 없는 경우에도 `roots = { "~/dev/vpp-*" }`로 동작한다. path pattern 은
fallback 이고, marker 가 있으면 더 명시적인 판별 근거로 쓴다.

## Formatter Integration

conform.nvim 은 `formatters_by_ft.<filetype>`에 function 을 둘 수 있다.
따라서 Java는 다음처럼 연결한다.

```lua
opts.formatters_by_ft.java = function(bufnr)
    return require("config.conventions").formatters(bufnr, "java", nil)
end
```

기본 Java formatter 를 tracked 설정으로 켤 경우 fallback 을 둔다.

```lua
opts.formatters_by_ft.java = function(bufnr)
    return require("config.conventions").formatters(bufnr, "java", { "clang-format-java" })
end
```

VPP Lab 경로에서는 `vpplab-java-format`이 선택되고, 그 외 경로에서는
`clang-format-java`가 선택된다.

이번 구현에서는 non-VPP Java 기본 formatter 를 켠다.

```lua
fallback = { "clang-format-java" }
```

## Linter Integration

nvim-lint 의 `linters_by_ft`는 정적 list 중심이다. 따라서 두 가지 중 하나로
구현한다.

Preferred:

- core lint autocmd 에서 `try_lint(names)`를 직접 호출한다.
- `names`는 resolver 가 반환한 list 다.

```lua
local names = require("config.conventions").linters(0, vim.bo.filetype, opts.linters_by_ft[vim.bo.filetype])
require("lint").try_lint(names)
```

Fallback:

- filetype별 wrapper linter 를 하나 두고 wrapper parser/command 가 convention
  pack 으로 위임한다.

Preferred 방식이 더 단순하고, `:lua require("lint").try_lint()` 기본 동작만
고집하지 않아도 되므로 우선한다.

## Default Behavior

매칭되는 convention rule 이 없으면 기존 tracked 설정이 그대로 동작한다.

- Lua는 `stylua`와 `selene`
- Python은 `ruff`
- Java는 tracked 설정에서 명시한 fallback 이 있으면 그 formatter/linter
- Java formatter fallback 은 `{ "clang-format-java" }`
- Java linter fallback 은 없음

즉 local convention pack 은 opt-in overlay 이며 기본 설정을 오염시키지 않는다.

## Ordering

`conventions_local.lua`에 적힌 순서가 우선순위다. 먼저 매칭된 rule 이 이긴다.

```lua
return {
    {
        name = "vpplab-api",
        roots = { "~/dev/vpp-api-*" },
        markers = { ".vpplab-api-convention" },
        module = "...",
    },
    {
        name = "vpplab",
        roots = { "~/dev/vpp-*" },
        markers = { ".vpplab-convention" },
        module = "...",
    },
}
```

구체적인 rule 을 위에 둔다.

## Failure Policy

- local rule module 이 없으면 warning 을 한 번 띄우고 fallback 을 쓴다.
- convention pack `setup()`이 실패하면 warning 을 한 번 띄우고 fallback 을 쓴다.
- formatter/linter 실행 실패는 기존 conform/nvim-lint error policy 를 따른다.
- resolver 는 저장 동작을 막지 않는다.

## Implementation Steps

1. `lua/config/conventions.lua`를 추가한다.
2. `.gitignore`에 `lua/config/conventions_local.lua`와
   `lua/plugins/conventions/*_local.lua`를 추가한다.
3. 기존 VPP local formatter/linter 를 `lua/plugins/conventions/vpplab_local.lua`
   pack 형태로 옮긴다.
4. `lua/plugins/core/format.lua`에서 Java formatter mapping 을 resolver 함수로
   연결한다. non-VPP fallback 은 `{ "clang-format-java" }`로 둔다.
5. `lua/plugins/core/lint.lua` autocmd 에서 resolver 가 반환한 linter list 로
   `try_lint(names)`를 호출한다.
6. `~/dev/vpp-*` root rule 과 VPP marker 후보를 `conventions_local.lua`에 둔다.
7. headless Neovim 으로 VPP 경로와 non-VPP 경로를 각각 검증한다.

## Implementation TODO

- Add tracked resolver module:
  - Create `lua/config/conventions.lua`.
  - Implement `match(bufnr)`, `formatters(bufnr, filetype, fallback)`,
    `linters(bufnr, filetype, fallback)`.
  - Support `roots` glob matching.
  - Support ancestor `markers`.
  - Cache loaded convention packs by module name.
  - Make pack `setup()` idempotent from the resolver side.
  - Emit warning once per failed local module/setup.

- Add ignored local surfaces:
  - Add `lua/config/conventions_local.lua` to `.gitignore`.
  - Add `lua/plugins/conventions/*_local.lua` to `.gitignore`.
  - Keep existing `lua/plugins/lang/*_local.lua` ignored for backward
    compatibility during migration.

- Migrate current VPP local Java config:
  - Move formatter definition from `lua/plugins/lang/java_formatter_local.lua`
    into `lua/plugins/conventions/vpplab_java_formatter_local.lua`.
  - Move linter definition from `lua/plugins/lang/java_linter_local.lua` into
    `lua/plugins/conventions/vpplab_java_linter_local.lua`.
  - Keep `lua/plugins/conventions/vpplab_local.lua` as a thin manifest.
  - Keep Confluence URL and clause comments in formatter/linter modules.
  - Remove or neutralize the old `java_*_local.lua` files after migration to
    avoid double registration.

- Add this Mac local rules:
  - Create ignored `lua/config/conventions_local.lua`.
  - Add VPP rule with `roots = { "~/dev/vpp-*" }`.
  - Add `markers = { ".vpplab-convention" }`.
  - Point module to `plugins.conventions.vpplab_local`.

- Wire formatter routing:
  - In `lua/plugins/core/format.lua`, set Java formatter mapping to a function.
  - Use `require("config.conventions").formatters(bufnr, "java",
    { "clang-format-java" })`.
  - Preserve existing `clang-format-java` formatter definition.

- Wire linter routing:
  - In `lua/plugins/core/lint.lua`, compute linter names through
    `config.conventions`.
  - Fallback to existing `opts.linters_by_ft[vim.bo.filetype]`.
  - Do not run lint when the resolved list is empty.

- Verify:
  - `luac -p` for changed Lua files.
  - `stylua` for changed Lua files.
  - Headless check: non-VPP Java resolves `clang-format-java`.
  - Headless check: `~/dev/vpp-*` Java resolves `vpplab-java-format` and
    `vpplab-java-convention`.
  - Headless check: marker-only workspace resolves VPP pack.
  - `git status --short --ignored` confirms local pack/rules are ignored.

## Decisions

- non-VPP Java formatter 는 기본으로 `{ "clang-format-java" }`를 켠다.
- VPP convention pack 은 이 Mac local-only 로 유지한다.
- VPP workspace 판별은 `roots`와 `markers`를 모두 지원한다. 현재는
  `~/dev/vpp-*` root pattern 을 기본으로 두고, marker 이름은 local rule 에서
  교체 가능하게 한다.

## Approval Checklist

- `~/dev/vpp-*` path fallback 을 유지해도 되는가?
- marker 이름을 `.vpplab-convention`으로 시작해도 되는가?
- non-VPP Java 저장 시 `clang-format-java`가 자동 실행되어도 되는가?
