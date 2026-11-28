-------------------------------------------------------------------------------
-- Test user/lspconfig.lua configuration
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local M = {}
local join = vim.fs.joinpath
local workspaces = { "MODULE.bazel", "WORKSPACE.bazel", "WORKSPACE" }
local packages = { "BUILD.bazel", "BUILD" }
local projects = { ".venv", "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", "Pipfile", ".git" }

local function nearest(dir, markers, stop)
    while dir do
        for _, marker in ipairs(markers) do
            if vim.uv.fs_stat(join(dir, marker)) then return dir end
        end
        if dir == stop or vim.uv.fs_stat(join(dir, ".git")) then break end
        local parent = vim.fs.dirname(dir)
        if parent == dir then break end
        dir = parent
    end
end

function M.root_dir(bufnr, on_dir)
    local dir = vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr))
    local workspace = nearest(dir, workspaces)
    local markers = workspace and vim.list_extend(vim.list_slice(projects), packages) or projects
    on_dir(nearest(dir, markers, workspace) or workspace or dir)
end

local function directories()
    local paths, seen = {}, {}
    local function add(path)
        if vim.fn.isdirectory(path) == 0 then return end
        local real = vim.uv.fs_realpath(path)
        if real and not seen[real] then
            seen[real] = true
            paths[#paths + 1] = path
        end
    end
    return paths, add
end

local function matches(dir, pattern)
    return vim.fn.globpath(vim.fn.escape(dir, ",*?[]{}"), pattern, true, true)
end

local function sites(env, add)
    for _, site in ipairs(matches(env, "lib/python*/site-packages")) do add(site) end
end

function M.resolve(root, shared)
    local workspace = nearest(root, workspaces)
    local local_root = nearest(root, { ".venv/bin/python" }, workspace)
    local python
    local fallbacks, add = directories()
    local sources, add_source = directories()
    local function environment(env)
        local executable = join(env, "bin/python")
        if not python and vim.fn.executable(executable) == 1 then
            python = executable
        else
            sites(env, add)
        end
    end
    if local_root then environment(join(local_root, ".venv")) end
    environment(shared)
    if workspace then
        add_source(workspace)
        local package = nearest(root, packages, workspace) or workspace
        local relative = vim.fs.relpath(workspace, package) or ""
        local bin = join(workspace, "bazel-bin")
        local outputs = vim.fn.isdirectory(bin) == 1 and { bin } or matches(join(workspace, "bazel-out"), "*/bin")
        for _, output in ipairs(outputs) do
            add_source(output)
            local built = join(output, relative)
            for _, env in ipairs(matches(built, "*.venv")) do environment(env) end
            local runfiles = matches(built, "*.runfiles")
            for _, tree in ipairs(runfiles) do
                add_source(tree)
                for _, repo in ipairs(matches(tree, "*")) do
                    if vim.fn.isdirectory(repo) == 1 then
                        add(join(repo, "site-packages"))
                        sites(repo, add)
                        for _, lib in ipairs(matches(repo, "3rdparty/bazel/pip/*/lib")) do add(lib) end
                        for _, env in ipairs(matches(join(repo, relative), "*.venv")) do environment(env) end
                        add(repo)
                    end
                end
            end
            if #runfiles == 0 then
                for _, lib in ipairs(matches(output, "3rdparty/bazel/pip/*/lib")) do add(lib) end
            end
        end
    end
    return { python = python, fallbacks = fallbacks, sources = sources }
end

function M.start(dispatchers, config)
    local shared = join(vim.fn.expand("~"), ".local/share/venv")
    local resolved = M.resolve(config.root_dir, shared)
    local plugins = config.settings.pylsp.plugins
    local env = vim.tbl_extend("force", {}, config.cmd_env or {})
    plugins.jedi = vim.tbl_extend("force", plugins.jedi or {}, {
        environment = resolved.python,
        extra_paths = vim.list_extend(vim.list_slice(resolved.fallbacks), resolved.sources),
    })
    local python = resolved.python or vim.fn.exepath("python3")
    if python ~= "" then
        local probe = python
        if #resolved.fallbacks > 0 then
            probe = join(vim.fn.stdpath("config"), "bin/mypy-python")
            env.NVIM_PYLSP_PYTHON = python
            env.NVIM_PYLSP_FALLBACKS = table.concat(resolved.fallbacks, ":")
        end
        plugins.pylsp_mypy.overrides = { true, "--python-executable", probe }
    end
    if #resolved.sources > 0 then
        local paths = vim.list_slice(resolved.sources)
        if vim.env.MYPYPATH and vim.env.MYPYPATH ~= "" then paths[#paths + 1] = vim.env.MYPYPATH end
        env.MYPYPATH = table.concat(paths, ":")
    end
    local server = join(shared, "bin/pylsp")
    if vim.fn.executable(server) == 0 then server = "pylsp" end
    return vim.lsp.rpc.start({ server }, dispatchers, { cwd = config.root_dir, env = env })
end

return M
