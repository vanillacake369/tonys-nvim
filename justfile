set shell := ["zsh", "-cu"]

default:
    @just --list

# Lua spec 전체를 headless Neovim 으로 실행한다.
test:
    nvim --headless -u NONE -c 'set rtp^=.' -c 'luafile tests/run.lua' -c 'qa'

# Lua/TOML/YAML/JSON 형식, lint, headless spec 을 한 번에 확인한다.
check:
    stylua --check lua tests
    selene --quiet --allow-warnings lua tests
    jq empty snippets/*.json
    just test

# Selene warning 까지 전부 자세히 보고 싶을 때 사용한다.
lint:
    selene lua tests

# Lua source 와 spec 을 repository formatting 규칙에 맞춘다.
format:
    stylua lua tests
