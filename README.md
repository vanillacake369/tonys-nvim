# Neovim Configuration

간결하고 모듈화된 Neovim 설정입니다.

## 구조

```
~/.config/nvim/
├── init.lua                 # 설정 진입점
├── lazy-lock.json          # 플러그인 버전 잠금 파일
└── lua/
    └── config/
        ├── settings.lua    # Neovim 기본 설정
        ├── keybinds.lua    # 키바인딩
        ├── lazy.lua        # Lazy.nvim 플러그인 매니저
        └── plugins/        # 플러그인 설정
            ├── ayu.lua         # Ayu 테마
            └── treesitter.lua  # Treesitter 구문 분석
```

## 주요 기능

### 기본 설정
- 라인 번호 및 상대 번호 표시
- 2칸 탭 간격
- 줄 바꿈 비활성화
- 증분 검색

### 플러그인
- **lazy.nvim**: 플러그인 매니저
- **ayu**: 컬러 스킴
- **nvim-treesitter**: 향상된 구문 강조 및 코드 분석

## 설치

```bash
# Neovim 설치 (macOS)
brew install neovim

# 이 설정을 복제하거나 심볼릭 링크
git clone <your-repo> ~/.config/nvim

# Neovim 실행 - Lazy.nvim이 자동으로 플러그인 설치
nvim
```

## 플러그인 관리

플러그인은 `lua/config/plugins/` 디렉토리에 개별 파일로 관리됩니다.
새 플러그인을 추가하려면:

1. `lua/config/plugins/` 디렉토리에 새 `.lua` 파일 생성
2. 플러그인 스펙을 반환하는 형식으로 작성
3. Neovim 재시작 - Lazy가 자동으로 인식

## Leader Key

Leader key는 `Space`로 설정되어 있습니다.
