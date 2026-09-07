local H = {}

function H.assert_eq(actual, expected, message)
    if vim.deep_equal(actual, expected) then
        return
    end
    error(string.format("%s\nexpected: %s\nactual: %s", message, vim.inspect(expected), vim.inspect(actual)))
end

function H.temp_root()
    local root = vim.fs.normalize(vim.fn.tempname())
    vim.fn.mkdir(root, "p")
    return root
end

function H.write(path, lines)
    vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
    vim.fn.writefile(lines, path)
    return path
end

function H.gradlew(root)
    vim.fn.writefile({}, root .. "/gradlew")
    vim.fn.setfperm(root .. "/gradlew", "rwxr-xr-x")
end

function H.gradle_runner()
    require("plugins.core.test")
    return assert(_G.__test_alternate._test.gradle, "missing JVM Gradle runner test surface")
end

return H
