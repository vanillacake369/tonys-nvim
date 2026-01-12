# Utility Plugins Guide

다른 플러그인들을 지원하는 유틸리티 라이브러리 가이드입니다.

## 📊 Overview

2개의 유틸리티 플러그인이 설정되어 있습니다:

| Plugin | Purpose | Used By |
|--------|---------|---------|
| [plenary.nvim](#plenaryнvim) | Lua 유틸리티 라이브러리 | todo-comments, 기타 플러그인들 |
| [SchemaStore.nvim](#schemastorenvim) | JSON/YAML 스키마 저장소 | jsonls, yamlls LSP |

---

## plenary.nvim

### 📦 Plugin Info
- **Repository**: [nvim-lua/plenary.nvim](https://github.com/nvim-lua/plenary.nvim)
- **Type**: Library (의존성)
- **Purpose**: 공통 Lua 유틸리티 및 헬퍼 함수

### ✨ Features

Neovim 플러그인 개발에 필수적인 Lua 라이브러리입니다:

#### 1. Async Operations
- 비동기 작업 처리
- Promise 스타일 API
- 콜백 관리

#### 2. File I/O
- 파일 읽기/쓰기
- 경로 조작
- 디렉토리 탐색

#### 3. Functional Programming
- Map, filter, reduce 등
- 함수형 유틸리티
- 테이블 조작

#### 4. Testing Framework
- 플러그인 테스트 작성
- Assertion 함수
- 테스트 러너

### 🔧 Core Modules

| Module | Purpose | Example Usage |
|--------|---------|---------------|
| `plenary.async` | 비동기 작업 | 파일 비동기 읽기 |
| `plenary.path` | 경로 조작 | 경로 결합, 정규화 |
| `plenary.scandir` | 디렉토리 스캔 | 파일 목록 가져오기 |
| `plenary.job` | 외부 프로세스 실행 | Git 명령어 실행 |
| `plenary.curl` | HTTP 요청 | API 호출 |
| `plenary.filetype` | 파일 타입 감지 | MIME 타입 확인 |
| `plenary.test_harness` | 테스트 프레임워크 | 플러그인 테스트 |

### 📋 Used By

이 설정에서 plenary.nvim을 사용하는 플러그인:

| Plugin | Usage |
|--------|-------|
| **todo-comments.nvim** | 파일 스캔, 비동기 작업 |
| **nvim-lint** (간접적) | Job 실행 |
| **기타 플러그인** | 다양한 유틸리티 함수 |

### 💡 Why Plenary?

Neovim Lua API는 기본적이므로, 복잡한 작업을 위해 추가 유틸리티가 필요합니다:

- **Without Plenary**:
  ```lua
  -- 비동기 파일 읽기가 복잡함
  local uv = vim.loop
  local fd = uv.fs_open(path, "r", 438)
  local stat = uv.fs_fstat(fd)
  local data = uv.fs_read(fd, stat.size, 0)
  uv.fs_close(fd)
  ```

- **With Plenary**:
  ```lua
  local Path = require('plenary.path')
  local content = Path:new(path):read()
  ```

### 🎯 Common Use Cases

#### Example 1: 파일 읽기

```lua
local Path = require('plenary.path')

local config_path = Path:new(vim.fn.stdpath('config'), 'init.lua')
if config_path:exists() then
  local content = config_path:read()
  print(content)
end
```

#### Example 2: 디렉토리 스캔

```lua
local scan = require('plenary.scandir')

scan.scan_dir(vim.fn.stdpath('config'), {
  hidden = false,
  add_dirs = false,
  on_insert = function(entry)
    print(entry)
  end,
})
```

#### Example 3: 비동기 작업

```lua
local async = require('plenary.async')

async.run(function()
  local result = async.util.block_on(some_async_function())
  print(result)
end)
```

#### Example 4: 외부 명령 실행

```lua
local Job = require('plenary.job')

Job:new({
  command = 'git',
  args = { 'status' },
  on_exit = function(j, return_val)
    print(table.concat(j:result(), "\n"))
  end,
}):start()
```

### 🔧 Advanced Features

#### 1. Async/Await Style

```lua
local async = require('plenary.async')
local tx, rx = async.control.channel.oneshot()

async.run(function()
  tx.send("Hello from async")
end)

print(rx.recv())  -- "Hello from async"
```

#### 2. Path Utilities

```lua
local Path = require('plenary.path')

local p = Path:new("~/.config/nvim")
print(p:expand())      -- /Users/username/.config/nvim
print(p:is_dir())      -- true
print(p:absolute())    -- Full path
```

#### 3. Functional Helpers

```lua
local func = require('plenary.functional')

local numbers = {1, 2, 3, 4, 5}
local doubled = func.map(numbers, function(n) return n * 2 end)
-- doubled = {2, 4, 6, 8, 10}
```

### 📚 Documentation

Plenary는 직접 사용하기보다는 다른 플러그인의 의존성으로 설치됩니다.

**Official Docs**: `:help plenary` (플러그인 설치 후)

---

## SchemaStore.nvim

### 📦 Plugin Info
- **Repository**: [b0o/SchemaStore.nvim](https://github.com/b0o/SchemaStore.nvim)
- **Type**: LSP Enhancement
- **Purpose**: JSON 및 YAML 파일의 스키마 자동 완성

### ✨ Features

100개 이상의 JSON/YAML 스키마를 제공하여 설정 파일 작성 시 자동완성과 검증을 지원합니다.

### 🗂️ Supported Schemas

#### Development Configurations

| File | Schema | Auto-completion |
|------|--------|-----------------|
| `package.json` | npm package | ✅ dependencies, scripts, etc. |
| `tsconfig.json` | TypeScript config | ✅ compilerOptions, include, etc. |
| `jsconfig.json` | JavaScript config | ✅ Similar to tsconfig |
| `pyproject.toml` | Python project | ✅ Poetry, setuptools |
| `Cargo.toml` | Rust package | ✅ dependencies, package |
| `go.mod` | Go modules | ✅ module, require |

#### CI/CD & DevOps

| File | Schema | Auto-completion |
|------|--------|-----------------|
| `.github/workflows/*.yml` | GitHub Actions | ✅ jobs, steps, on |
| `.gitlab-ci.yml` | GitLab CI | ✅ stages, jobs, scripts |
| `azure-pipelines.yml` | Azure Pipelines | ✅ pool, steps, stages |
| `Jenkinsfile.json` | Jenkins | ✅ pipeline, agent |
| `cloudbuild.yaml` | Google Cloud Build | ✅ steps, images |

#### Containerization

| File | Schema | Auto-completion |
|------|--------|-----------------|
| `docker-compose.yml` | Docker Compose | ✅ services, volumes, networks |
| `.dockerignore` | Docker ignore | ✅ patterns |

#### Cloud & Infrastructure

| File | Schema | Auto-completion |
|------|--------|-----------------|
| `*.tf.json` | Terraform | ✅ resource, provider |
| `ansible.yml` | Ansible | ✅ tasks, plays |
| `k8s/*.yaml` | Kubernetes | ✅ pods, deployments, services |
| `helm/values.yaml` | Helm | ✅ chart values |

#### Configuration Files

| File | Schema | Auto-completion |
|------|--------|-----------------|
| `.prettierrc` | Prettier | ✅ printWidth, tabWidth |
| `.eslintrc.json` | ESLint | ✅ rules, extends |
| `.babelrc` | Babel | ✅ presets, plugins |
| `renovate.json` | Renovate | ✅ packageRules, extends |
| `dependabot.yml` | Dependabot | ✅ version, updates |

### 🔗 LSP Integration

SchemaStore는 다음 LSP 서버와 통합됩니다:

#### 1. jsonls (JSON Language Server)

**Configuration** (in `lua/config/plugins/lspconfig.lua`):
```lua
local schemastore = require('schemastore')

require('lspconfig').jsonls.setup({
  settings = {
    json = {
      schemas = schemastore.json.schemas(),
      validate = { enable = true },
    }
  }
})
```

#### 2. yamlls (YAML Language Server)

**Configuration**:
```lua
require('lspconfig').yamlls.setup({
  settings = {
    yaml = {
      schemas = schemastore.yaml.schemas(),
      validate = true,
    }
  }
})
```

### 🎯 Usage Examples

#### Example 1: package.json

**File**: `package.json`

타이핑하면 자동으로 필드 제안:

```json
{
  "name": "my-project",
  "ver|"    ← 입력 시 "version" 자동 완성
}
```

완성 후:
```json
{
  "name": "my-project",
  "version": "1.0.0",
  "scripts": {
    "te|"    ← "test", "build" 등 제안
  }
}
```

#### Example 2: GitHub Workflow

**File**: `.github/workflows/ci.yml`

```yaml
name: CI
on:
  |    ← "push", "pull_request", "workflow_dispatch" 등 제안
```

완성 후:
```yaml
name: CI
on:
  push:
    branches:
      - |    ← "main", "master", "develop" 등 제안
jobs:
  test:
    runs-on: |    ← "ubuntu-latest", "windows-latest" 등 제안
```

#### Example 3: Docker Compose

**File**: `docker-compose.yml`

```yaml
version: "3.8"
services:
  web:
    |    ← "image", "build", "ports", "volumes" 등 제안
```

완성 후:
```yaml
version: "3.8"
services:
  web:
    image: nginx
    ports:
      - "|"    ← "8080:80" 형식 제안
```

#### Example 4: tsconfig.json

**File**: `tsconfig.json`

```json
{
  "compilerOptions": {
    "target": "|"    ← "ES2015", "ES2020", "ESNext" 등 제안
  }
}
```

### 🔍 Schema Detection

SchemaStore는 파일명과 경로를 기반으로 자동으로 스키마를 감지합니다:

| File Pattern | Detected Schema |
|-------------|-----------------|
| `package.json` | npm package |
| `tsconfig*.json` | TypeScript config |
| `.github/workflows/*.yml` | GitHub Actions |
| `docker-compose*.yml` | Docker Compose |
| `**/k8s/**/*.yaml` | Kubernetes |

### 💡 Benefits

#### 1. Auto-completion

타이핑 시 유효한 필드만 제안:
```json
{
  "scripts": {
    "|"    ← 유효한 script 이름만 제안
  }
}
```

#### 2. Validation

잘못된 값 입력 시 경고:
```json
{
  "version": 123    ← ⚠ Warning: should be string
}
```

#### 3. Documentation

호버 시 필드 설명 표시:
```json
{
  "dependencies": {}    ← Hover: "Package dependencies"
}
```

### 🔧 Customization

#### Custom Schema 추가

```lua
local schemastore = require('schemastore')

require('lspconfig').jsonls.setup({
  settings = {
    json = {
      schemas = vim.list_extend(
        schemastore.json.schemas(),
        {
          {
            fileMatch = { "my-config.json" },
            url = "https://example.com/schema.json"
          }
        }
      )
    }
  }
})
```

#### 특정 Schema만 사용

```lua
local schemastore = require('schemastore')

require('lspconfig').jsonls.setup({
  settings = {
    json = {
      schemas = schemastore.json.schemas({
        select = {
          'package.json',
          'tsconfig.json',
          '.eslintrc',
        }
      })
    }
  }
})
```

#### Schema 제외

```lua
schemas = schemastore.json.schemas({
  ignore = {
    'jsconfig.json',  -- 이 스키마는 사용하지 않음
  }
})
```

### 📊 Available Schemas

전체 스키마 목록:

```vim
:lua print(vim.inspect(require('schemastore').json.schemas()))
```

100개 이상의 스키마가 나열됩니다.

### 💡 Tips

#### Tip 1: 스키마 확인

파일이 어떤 스키마를 사용하는지 확인:

```vim
:LspInfo
```

"jsonls" 또는 "yamlls" 섹션에서 active schemas 확인

#### Tip 2: 수동으로 스키마 지정

파일 상단에 주석으로 스키마 지정:

**JSON**:
```json
{
  "$schema": "https://json.schemastore.org/package.json"
}
```

**YAML**:
```yaml
# yaml-language-server: $schema=https://json.schemastore.org/github-workflow.json
```

#### Tip 3: Schema 업데이트

SchemaStore.nvim 업데이트 시 최신 스키마 반영:

```vim
:Lazy update SchemaStore.nvim
```

---

## 🔗 Utility Integration Map

두 유틸리티 플러그인이 어떻게 시스템에 통합되는지:

```
┌─────────────────────────────────────────────────┐
│                 Your Plugins                    │
├─────────────────────────────────────────────────┤
│                                                 │
│  ┌──────────────┐         ┌──────────────┐    │
│  │ todo-        │         │  jsonls LSP  │    │
│  │ comments.nvim│         │  yamlls LSP  │    │
│  └──────┬───────┘         └──────┬───────┘    │
│         │                        │             │
│         │ uses                   │ uses        │
│         ▼                        ▼             │
│  ┌──────────────┐         ┌──────────────┐    │
│  │ plenary.nvim │         │ SchemaStore  │    │
│  │ (async, I/O) │         │ (schemas)    │    │
│  └──────────────┘         └──────────────┘    │
│                                                 │
└─────────────────────────────────────────────────┘
```

**Integration Points**:
- **plenary.nvim**: 파일 I/O, 비동기 작업, 경로 조작 등 범용 유틸리티
- **SchemaStore.nvim**: LSP와 통합되어 JSON/YAML 자동완성 및 검증

---

## 🔗 Related Documentation

- **[Plugin Catalog](../README.md)** - 전체 플러그인 목록
- **[UI Plugins](../ui/README.md)** - UI 플러그인 가이드
- **[Editing Plugins](../editing/README.md)** - 편집 도구 가이드
- **[Core Configuration](../../README.md)** - 핵심 설정 파일
- **[Root README](../../../../README.md)** - 전체 설정 개요

---

**2 Utility Plugins** | **Last Updated: 2026-01-12**
