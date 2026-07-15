local counts = {
    small = { lines = 500, images = 5 },
    medium = { lines = 5000, images = 100 },
    large = { lines = 20000, images = 500 },
}

local function ms(start)
    return (vim.uv.hrtime() - start) / 1000000
end

local function make_fixture(spec)
    local lines = {}
    local interval = math.max(1, math.floor(spec.lines / spec.images))
    for index = 1, spec.lines do
        if index % interval == 0 then
            lines[#lines + 1] = string.format("![image %d](./assets/bench/image-%03d.png)", index, index)
        else
            lines[#lines + 1] = string.format("line %d", index)
        end
    end
    return lines
end

local function find_visible(bufnr, from, to)
    local done = false
    local count = 0
    local start = vim.uv.hrtime()
    Snacks.image.doc.find(bufnr, function(images)
        count = #images
        done = true
    end, { from = from, to = to })
    vim.wait(2000, function()
        return done
    end, 10)
    return ms(start), count
end

local results = {}

for name, spec in pairs(counts) do
    local bufnr = vim.api.nvim_create_buf(true, true)
    vim.bo[bufnr].filetype = "markdown"
    vim.api.nvim_buf_set_name(bufnr, vim.fn.tempname() .. ".md")

    local initial_start = vim.uv.hrtime()
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, make_fixture(spec))
    local initial_ms = ms(initial_start)

    local cold_visible_ms, cold_visible_count = find_visible(bufnr, 1, 120)
    local warm_visible_ms, warm_visible_count = find_visible(bufnr, 1, 120)

    local edit_start = vim.uv.hrtime()
    vim.api.nvim_buf_set_lines(bufnr, 10, 11, false, { "single edit" })
    local edit_ms = ms(edit_start)

    results[#results + 1] = string.format(
        "%s lines=%d images=%d initial_set_lines_ms=%.3f cold_visible_query_ms=%.3f cold_visible_images=%d warm_visible_query_ms=%.3f warm_visible_images=%d single_edit_ms=%.3f",
        name,
        spec.lines,
        spec.images,
        initial_ms,
        cold_visible_ms,
        cold_visible_count,
        warm_visible_ms,
        warm_visible_count,
        edit_ms
    )

    vim.api.nvim_buf_delete(bufnr, { force = true })
end

print(table.concat(results, "\n"))
