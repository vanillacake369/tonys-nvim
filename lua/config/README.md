# Config Layer

`lua/config`는 Neovim 자체의 기본 정책을 담는 layer 입니다. 플러그인 구현 세부사항이나 전체 기능 목록을 이 문서에 복제하지 않습니다.

이 문서는 config layer 의 책임과 변경 기준만 설명합니다. 실제 값과 명세는 각 Lua 파일이 source of truth 입니다.

## Files

```text
lua/config/
  keymaps.lua    keymap registry and which-key metadata
  options.lua    editor defaults
  lazy.lua       lazy.nvim bootstrap and plugin import root
  clipboard.lua  clipboard provider
  languages.lua  language tooling registry
```

`init.lua`는 이 layer 를 아래 순서로 로드합니다.

```lua
require("config.keymaps")
require("config.options")
require("config.lazy")
require("config.clipboard")
```

## Responsibilities

`keymaps.lua`

Keymap 을 그룹 단위 registry 로 관리합니다. 플러그인 spec 은 이 registry 에서 필요한 group 또는 일부 key 만 가져갑니다. 키 목록은 README 에 복제하지 않습니다.

`options.lua`

Neovim 기본 편집 동작을 설정합니다. 값의 의미가 자명하지 않거나 UX tradeoff 가 있으면 코드 근처에 comment tag 로 설명합니다.

`lazy.lua`

`lazy.nvim`을 bootstrap 하고 `lua/plugins` tree 를 import 합니다. 플러그인 추가/삭제의 상세는 각 plugin spec 파일과 `lazy-lock.json`이 표현합니다.

`clipboard.lua`

터미널 환경에서 clipboard provider 를 설정합니다. SSH, tmux, zellij, WezTerm 같은 실행 환경 차이가 생기기 쉬운 영역이므로 동작 변경 시 실제 터미널에서 확인합니다.

`languages.lua`

언어별 LSP, Treesitter, formatter, linter 선언을 모읍니다. 일반적인 언어는 이 registry 에 추가하고, 별도 lifecycle 이 필요한 언어만 `lua/plugins/core/lsp-*.lua`로 분리합니다.

## Design Rules

- README 에 option table, keymap table, language matrix 를 두지 않는다.
- 코드와 같은 내용을 문서에 반복하지 않는다.
- 설정 이유가 중요한 경우 Lua 파일 근처에 `NOTE:`, `PERF:`, `TODO:` 주석으로 남긴다.
- 새 keymap 은 `desc`를 갖게 해서 which-key 와 picker 에서 의도가 드러나게 한다.
- plugin lazy-load 와 buffer-local attach 에 필요한 keymap group 은 `keymaps.bind(...)` adapter 를 사용한다.
- language tooling 은 먼저 `languages.lua` registry 에 넣고, plugin-specific attach/lifecycle 이 필요할 때만 별도 module 로 뺀다.

## Change Checklist

작은 변경도 아래 source of truth 를 기준으로 확인합니다.

- Keymap 변경: [keymaps.lua](keymaps.lua)
- Editor option 변경: [options.lua](options.lua)
- Plugin import/bootstrap 변경: [lazy.lua](lazy.lua)
- Clipboard 변경: [clipboard.lua](clipboard.lua)
- Language tooling 변경: [languages.lua](languages.lua)

검증은 변경 범위에 맞게 좁게 시작합니다.

```bash
luac -p lua/config/keymaps.lua
luac -p lua/config/languages.lua
stylua lua/config/keymaps.lua lua/config/languages.lua
```

Neovim runtime 이 필요한 변경은 headless require 또는 `:checkhealth`로 확인합니다.

## Related Layers

- Plugin implementations: [../plugins](../plugins)
- Root architecture overview: [../../README.md](../../README.md)
