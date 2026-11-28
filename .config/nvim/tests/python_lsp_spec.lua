-------------------------------------------------------------------------------
-- Test user/lspconfig.lua configuration
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local python = require("user.python-lsp")
local join = vim.fs.joinpath

describe("Python analysis paths", function()
    local tmp, project, shared

    local function dir(path)
        vim.fn.mkdir(path, "p")
        return path
    end

    local function interpreter(env)
        dir(join(env, "bin"))
        assert(vim.uv.fs_symlink(vim.v.progpath, join(env, "bin/python")))
        return dir(join(env, "lib/python3.12/site-packages"))
    end

    before_each(function()
        tmp = vim.fn.tempname()
        project = dir(join(tmp, "project"))
        shared = join(tmp, "shared")
        dir(join(project, ".git"))
    end)

    after_each(function()
        vim.fn.delete(tmp, "rf")
    end)

    it("prefers the project venv and keeps the shared packages as a fallback", function()
        local shared_site = interpreter(shared)
        local env = join(project, ".venv")
        interpreter(env)
        local paths = python.resolve(dir(join(project, "src")), shared)
        assert.equals(join(env, "bin/python"), paths.python)
        assert.same({ shared_site }, paths.fallbacks)
        assert.same({}, paths.sources)
    end)

    it("falls back without crossing repo boundaries or following broken executables", function()
        interpreter(join(tmp, ".venv"))
        dir(join(project, ".venv/bin"))
        assert(vim.uv.fs_symlink(join(tmp, "gone"), join(project, ".venv/bin/python")))
        assert.is_nil(python.resolve(project, shared).python)
        interpreter(shared)
        assert.equals(join(shared, "bin/python"), python.resolve(project, shared).python)
    end)

    it("uses the buffer's Bazel package, not the editor cwd or a sibling target", function()
        vim.fn.writefile({}, join(project, "MODULE.bazel"))
        local package = dir(join(project, "apps/demo"))
        vim.fn.writefile({}, join(package, "BUILD.bazel"))
        local src = dir(join(package, "src"))
        local bufnr = vim.fn.bufadd(join(src, "main.py"))
        local root
        python.root_dir(bufnr, function(path) root = path end)
        assert.equals(package, root)
        local output = dir(join(project, "bazel-out/fastbuild/bin"))
        assert(vim.uv.fs_symlink(output, join(project, "bazel-bin")))
        local bin = join(project, "bazel-bin")
        local target = join(bin, "apps/demo/tool.runfiles")
        local wheel = dir(join(target, "_main/3rdparty/bazel/pip/sample/lib"))
        local site = dir(join(target, "pip+numpy/site-packages"))
        local other = dir(join(bin, "apps/other/test.runfiles/pip+other/site-packages"))
        dir(join(project, "bazel-out/stale/bin"))
        local shared_site = interpreter(shared)
        interpreter(join(project, ".venv"))
        local paths = python.resolve(root, shared)
        assert.equals(shared_site, paths.fallbacks[1])
        assert.is_true(vim.tbl_contains(paths.fallbacks, site))
        assert.is_true(vim.tbl_contains(paths.fallbacks, wheel))
        assert.is_false(vim.tbl_contains(paths.fallbacks, other))
        assert.same({ project, bin, target }, paths.sources)
    end)

    it("uses a built environment when neither regular venv is available", function()
        vim.fn.writefile({}, join(project, "WORKSPACE"))
        local bin = dir(join(project, "bazel-out/debug/bin"))
        local env = join(bin, "tool.venv")
        interpreter(env)
        local wheel = dir(join(bin, "3rdparty/bazel/pip/sample/lib"))
        local paths = python.resolve(project, shared)
        assert.equals(join(env, "bin/python"), vim.fs.normalize(paths.python))
        assert.same({ wheel }, paths.fallbacks)
    end)
end)
