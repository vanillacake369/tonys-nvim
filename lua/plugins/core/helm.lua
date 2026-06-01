-- Helm chart / helmfile / *.gotmpl 의 filetype 을 'helm' 으로 등록
-- nvim 기본에 'helm' filetype 이 없어 languages.lua 의 helm formatter 매핑이
-- 동작하려면 ftdetect 가 선행돼야 함.
-- lazy.nvim 은 ftdetect/ 디렉터리를 lazy 여부와 무관하게 startup 시 source 하므로
-- 별도 lazy=false 지정은 불필요 (기본 lazy=true 로 충분).
return {
    "towolf/vim-helm",
}
