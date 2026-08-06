# Neovim Config

개인 개발 환경을 위한 Neovim 설정입니다. 이 문서는 기능 목록을 exhaustive 하게 유지하지 않습니다. 실제 동작의 source of truth 는 Lua 설정 파일입니다.

README 는 이 repo 의 방향, 구조, 운영 원칙만 설명합니다. 플러그인, 키맵, 언어 서버, formatter, linter 의 상세 목록은 코드에서 확인합니다.

## Philosophy

- 설정은 작고 명확한 Lua module 로 나눈다.
- 공통 정책은 `lua/config`에 두고, 플러그인별 구현은 `lua/plugins` 아래에 둔다.
- keymap, language tooling, plugin spec 은 문서에 복제하지 않는다. 코드가 유일한 명세다.
- terminal image preview 처럼 터미널/멀티플렉서 제약을 타는 기능은 기본값을 보수적으로 둔다.
- Markdown preview 는 Neovim inline 기능보다 browser preview 를 우선한다. zellij/wezterm 환경에서 image protocol 의 불안정성을 줄이기 위함이다.
- Java, Rust 처럼 일반 LSP 흐름과 다른 lifecycle 이 필요한 언어는 별도 plugin module 로 분리한다.

## Architecture

```text
init.lua
  -> lua/config/keymaps.lua
  -> lua/config/options.lua
  -> lua/config/lazy.lua
  -> lua/config/clipboard.lua

lua/config/
  keymaps.lua    keymap registry
  languages.lua  language tooling registry
  options.lua    editor defaults
  lazy.lua       lazy.nvim bootstrap
  clipboard.lua  clipboard provider

lua/plugins/
  core/          editing, LSP, format, lint, test, runner, language-specific logic
  navigation/    picker, explorer, window/session/navigation workflow
  ui/            theme, bufferline, Markdown/browser preview
```

## Source Of Truth

- Keymaps: [lua/config/keymaps.lua](lua/config/keymaps.lua)
- Language tooling registry: [lua/config/languages.lua](lua/config/languages.lua)
- LSP attach/save policy: [lua/plugins/core/lsp.lua](lua/plugins/core/lsp.lua)
- Java lifecycle: [lua/plugins/core/lsp-java.lua](lua/plugins/core/lsp-java.lua)
- Rust lifecycle: [lua/plugins/core/lsp-rust.lua](lua/plugins/core/lsp-rust.lua)
- Formatter policy: [lua/plugins/core/format.lua](lua/plugins/core/format.lua)
- Linter policy: [lua/plugins/core/lint.lua](lua/plugins/core/lint.lua)
- Markdown asset workflow: [lua/plugins/core/paste-img.lua](lua/plugins/core/paste-img.lua)
- Markdown inline/image preview: [lua/plugins/ui/preview.lua](lua/plugins/ui/preview.lua)
- Browser preview: [lua/plugins/ui/browser-preview.lua](lua/plugins/ui/browser-preview.lua)

## Extension Rules

새 기능을 추가할 때는 먼저 어느 정책에 속하는지 결정합니다.

- editor 기본값이면 `lua/config/options.lua`
- keymap 이면 `lua/config/keymaps.lua`
- 언어별 LSP/formatter/linter registry 항목이면 `lua/config/languages.lua`
- 일반 plugin spec 이면 `lua/plugins/core`, `lua/plugins/navigation`, `lua/plugins/ui` 중 가장 가까운 곳
- 일반 LSP 흐름과 충돌하는 언어 lifecycle 이면 `lua/plugins/core/lsp-*.lua`

문서에는 새 기능 목록을 추가하지 않습니다. 복잡한 의도나 제약은 해당 Lua 파일 근처에 `NOTE:`, `PERF:`, `TODO:` 같은 comment tag 로 남깁니다.

## Runtime Notes

- Neovim 0.11+ 를 기준으로 한다.
- `lazy-lock.json`은 plugin pin 의 현재 상태를 나타낸다.
- Nix 환경에서는 `init.lua`가 `nix-providers.lua`를 감지해 provider path 를 로드한다. non-Nix clone 은 PATH 기반 provider detection 으로 동작한다.
- Java Lombok 은 `$LOMBOK_JAR`를 우선하고, 없으면 PATH 의 `lombok` wrapper 에서 jar 를 추출한다.

## Verification

변경 후에는 범위에 맞게 작은 검증부터 실행합니다.

```bash
luac -p lua/path/to/file.lua
stylua lua/path/to/file.lua
nvim --headless -c 'checkhealth' -c qa
```

Plugin 설치/동기화 문제는 Neovim 안에서 `:Lazy`, `:Lazy health`, `:Lazy sync`로 확인합니다.

## Documentation Policy

README 는 inventory 가 아니라 index 와 decision record 입니다.

상세 표를 README 에 복제하지 않는 이유:

- keymap 과 plugin spec 은 자주 바뀐다.
- 언어 서버와 formatter mapping 은 환경에 따라 조정된다.
- 중복 문서는 코드보다 빨리 stale 해진다.

필요한 상세는 링크된 Lua 파일을 읽습니다.
