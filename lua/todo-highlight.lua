local M = {}

local defaults = {
  tags = {
    -- FIX
    FIX = "@comment.error",
    BUG = "@comment.error",
    ISSUE = "@comment.error",
    -- HACK
    HACK = "@comment.warning",
    -- WARN
    WARN = "@comment.warning",
    WARNING = "@comment.warning",
    -- TODO
    TODO = "@comment.todo",
    -- NOTE
    NOTE = "@comment.note",
    INFO = "@comment.note",
  },
  enabled = function(ft) return true end,
  ts_query = function(ft) return [[(comment) @comment]] end,
  contextless = function(ft) return false end,
}

local STATE = {
  disabled = true,
  treesitter = true,
  contextless = true,
}

local api = vim.api
local ts = vim.treesitter
local cache_query = {}
local ns = api.nvim_create_namespace("todo-highlight")

local function highlight_plain_tag(bufnr, line, tag, hl, row, col_offset)
  local matcher = "%f[%w]" .. tag .. "%:"

  local s, e = line:find(matcher, 1)

  if s then
    -- highlight tag
    api.nvim_buf_set_extmark(bufnr, ns, row, col_offset + s - 1, {
      end_col = col_offset + e,
      hl_group = hl,
    })

    return true
  end
  return false
end

local function highlight_param_tag(bufnr, line, tag, hl, row, col_offset)
  local matcher = "%f[%w]" .. tag .. "%(([^)]+)%)%:"

  local s, e, param = line:find(matcher, 1)

  if s then
    -- highlight tag
    api.nvim_buf_set_extmark(bufnr, ns, row, col_offset + s - 1, {
      end_col = col_offset + e,
      hl_group = hl,
    })

    -- highlight parameter
    api.nvim_buf_set_extmark(bufnr, ns, row, col_offset + s + #tag, {
      end_col = col_offset + e - 2,
      hl_group = "@parameter",
    })

    return true
  end
  return false
end

local function contextless_highlight(bufnr)
  local winid = api.nvim_get_current_win()

  local first = vim.fn.line("w0", winid) - 1
  local last  = vim.fn.line("w$", winid)

  local lines = api.nvim_buf_get_lines(bufnr, first, last, false)

  -- loop through all lines in visible buffer
  for i, line in ipairs(lines) do
    local row = first + i - 1

    for tag, hl in pairs(M.opts.tags) do
      if highlight_plain_tag(bufnr, line, tag, hl, row, 0) then
        break
      end

      if highlight_param_tag(bufnr, line, tag, hl, row, 0) then
        break
      end
    end
  end
end

local function ts_highlight(bufnr, ft, parser)
  if not cache_query[bufnr] then
    local query_str = M.opts.ts_query(ft)
    if query_str then
      cache_query[bufnr] = ts.query.parse(parser:lang(), query_str)
    else
      cache_query[bufnr] = vim.treesitter.query.get(ft, "highlights")
    end
  end

  local query = cache_query[bufnr]

  local tree = parser:parse()[1]
  local root = tree:root()

  local winid = api.nvim_get_current_win()

  local first = vim.fn.line("w0", winid) - 1
  local last  = vim.fn.line("w$", winid)

  for id, node in query:iter_captures(root, bufnr, first, last) do
    if query.captures[id] == "comment" then
      local text = ts.get_node_text(node, bufnr)

      -- loop through all lines in comment nodes
      for i, line in ipairs(vim.split(text, "\r?\n")) do
        local start_row, start_col = node:start()
        local col_offset = 0

        -- handle same-line comments after code
        if i == 1 then
          col_offset = start_col
        end

        for tag, hl in pairs(M.opts.tags) do
          local row = start_row + i - 1

          if highlight_plain_tag(bufnr, line, tag, hl, row, col_offset) then
            break
          end

          if highlight_param_tag(bufnr, line, tag, hl, row, col_offset) then
            break
          end
        end
      end
    end
  end
end

local function get_current_mode(bufnr, ft, mode)
  if STATE[mode] then
    vim.b[bufnr].todo_highlight = mode
    return mode
  end

  -- mode not recognized, set to default
  -- NOTE: behaviour depended by user command processing
  if not M.opts.enabled(ft) then
    mode = "disabled"
  elseif M.opts.contextless(ft) then
    mode = "contextless"
  else
    mode = "treesitter"
  end
  
  vim.b[bufnr].todo_highlight = mode
  return mode
end

function M.highlight(mode, bufnr)
  -- set default value
  if not bufnr or bufnr == 0 then
    bufnr = api.nvim_get_current_buf()
  end

  -- clear all highlights and reapply
  api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

  local ft = api.nvim_buf_get_option(bufnr, "filetype")
  mode = get_current_mode(bufnr, ft, mode)

  -- do not highlight if disabled for file type
  if mode == "disabled" then
    return
  end

  if mode == "contextless" then
    contextless_highlight(bufnr)
  end

  if mode == "treesitter" then
    -- only highlight if parser exists
    local ok, parser = pcall(ts.get_parser, bufnr)
    if ok then
      ts_highlight(bufnr, ft, parser)
    end
  end
end

function M.setup(opts)
  M.opts = vim.tbl_deep_extend("force", defaults, opts or {})
  M.highlight()

  api.nvim_create_user_command("TodoHighlight", function(buffer_opts)
    if buffer_opts.args == "" or STATE[buffer_opts.args] then
      M.highlight(buffer_opts.args)
    else
      error("Option not recognised!")
    end
  end, {
    nargs = "?",
    complete = function()
      return { "disabled", "treesitter", "contextless" }
    end,
    desc = "Set highlight mode for todo-highlight.nvim"
  })

  api.nvim_create_autocmd(
    { "FileType", "WinScrolled", "TextChanged", "TextChangedI" },
    {
      callback = function(args)
        M.highlight(nil, args.buf)
      end,
    }
  )
end

return M
