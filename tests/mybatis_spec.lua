local H = require("tests.helpers")
local adapter = require("utils.mybatis_fs")
local lsp = require("plugins.core.lsp")

local root = H.temp_root()
local xml = H.write(root .. "/src/main/resources/static/mybatis/livemarket/livemarketDao.xml", {
    '<mapper namespace="io.vpplab.client.domain.livemarket.LiveMarketDao">',
    '  <select id="getParticipatePortfolios">SELECT 1</select>',
    "</mapper>",
})
H.write(root .. "/build/main/static/mybatis/livemarket/livemarketDao.xml", { "generated copy" })
H.write(root .. "/.git/objects/static/mybatis/livemarket/livemarketDao.xml", { "git copy" })

local matches = adapter.find_case_insensitive(root, "LiveMarketDao.xml", {
    exclude_dirnames = { ".git", "build" },
})

H.assert_eq(matches, { xml }, "MyBatis XML lookup should tolerate repository filename casing")

local signature =
    "    List<LiveMarketDto.PortfolioInfoResponse> getParticipatePortfolios(LiveMarketDto.PortfolioInfoRequest dto);"
H.assert_eq(
    lsp.is_java_mapper_method_name(signature, signature:find("LiveMarketDto", 1, true) - 1),
    false,
    "DTO type should use the Java LSP definition"
)
H.assert_eq(
    lsp.is_java_mapper_method_name(signature, signature:find("PortfolioInfoResponse", 1, true) - 1),
    false,
    "nested response type should use the Java LSP definition"
)
H.assert_eq(
    lsp.is_java_mapper_method_name(signature, signature:find("getParticipatePortfolios", 1, true) - 1),
    true,
    "mapper method name should use the MyBatis XML jump"
)
