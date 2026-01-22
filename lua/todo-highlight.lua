
local M = {}

local defaults = {
    tags = {
        TODO = "@comment.todo",
        NOTE = "@comment.warning",
    }
}

local api = vim.api
local ns = api.nvim_create_namespace("todo-highlight")

function M.say_hello()
    print("hello from neovim")
end

local function highlight_visible_todos(bufnr, winid)
  -- Clear only our decorations
  api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

  -- Visible window range (1-based)
  local first = vim.fn.line("w0", winid) - 1
  local last  = vim.fn.line("w$", winid)

  local lines = api.nvim_buf_get_lines(bufnr, first, last, false)

  for i, line in ipairs(lines) do
    local lnum = first + i - 1

    for tag, hl in pairs(M.opts.tags) do

      local matcher = tag .. "%:"


      local s, e = string.find(line, matcher, 1)

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
