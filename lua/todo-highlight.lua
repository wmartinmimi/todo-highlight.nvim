
local M = {}

local defaults = {
    tags = {
        TODO = "@comment.todo",
        NOTE = "@comment.warning",
    }
}

local api = vim.api
local ts = vim.treesitter
local ns = api.nvim_create_namespace("todo-highlight")

function M.say_hello()
    print("hello from neovim")
end

local function raw_buffer_highlight(bufnr, winid)
  local first = vim.fn.line("w0", winid) - 1
  local last  = vim.fn.line("w$", winid)

  local lines = api.nvim_buf_get_lines(bufnr, first, last, false)

  for i, line in ipairs(lines) do
    local lnum = first + i - 1

    for tag, hl in pairs(M.opts.tags) do

      local matcher = tag .. "%:"

      local s, e = line:find(matcher, 1)

      if s then
          -- highlight todo
        api.nvim_buf_set_extmark(bufnr, ns, lnum, s - 1, {
          end_col = e,
          hl_group = hl,
        })
      end
    end
  end
end

local function ts_highlight(bufnr, winid, lang)

  local ok, parser = pcall(ts.get_parser, bufnr, lang)
  if not ok then
    return
  end

  local tree = parser:parse()[1]
  local root = tree:root()

  local query = ts.query.parse(lang, "(comment) @comment")

  for _, node in query:iter_captures(root, bufnr, 0, -1) do
    
    local text = ts.get_node_text(node, bufnr)

    for i, line in ipairs(vim.split(text, "\r?\n")) do
      
      local start_row, start_col = node:start()
      local col_offset = 0

      if i == 1 then
        col_offset = start_col
      end

      for tag, hl in pairs(M.opts.tags) do

        local matcher = tag .. "%:"

        local s, e = line:find(matcher, 1)

        if s then
          print(start_row + i - 1)
          -- highlight todo
          api.nvim_buf_set_extmark(bufnr, ns, start_row + i - 1, col_offset + s - 1, {
            end_col = col_offset + e,
            hl_group = hl,
          })
        end
      end
    end
  end
end

local function highlight_visible_todos(bufnr, winid)
  -- Clear only our decorations
  api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

  local lang = ts.language.get_lang(
    api.nvim_buf_get_option(bufnr, "filetype")
  )

  if lang then
    ts_highlight(bufnr, winid, lang)
  else
    raw_buffer_highlight(bufnr, winid)
  end
end

function M.setup(opts)
    M.opts = vim.tbl_deep_extend("force", defaults, opts or {})

    api.nvim_create_autocmd(
      { "BufEnter", "WinScrolled", "TextChanged", "TextChangedI" },
      {
        callback = function(args)
          local winid = api.nvim_get_current_win()
          highlight_visible_todos(args.buf, winid)
        end,
      }
    )
end

return M
