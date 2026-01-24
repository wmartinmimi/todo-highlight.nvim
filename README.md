# todo-highlight.nvim

Highlights TODO comments for easy lookup.

NOTE: This plugin is beta.
Configuration and behaviour may change significantly without warning.

## Features

- Configurable tag highlighting
- Comment only highlighting via Tree-sitter
- Optional everywhere highlight based on file type

## Installation

```lua
-- lazy.nvim
{
    "wmartinmimi/todo-highlight.nvim",
    opts = {},
}
```

## Default Configuration

```lua
{
    tags = {

        --[[
        TAG_NAME = "highlight group",
        ]]

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
        NOTE = "@comment.hint",
        INFO = "@comment.hint",
    },

    -- Return true to allow highlighting for selected file type
    enabled = function(ft) return true end,

    -- Return true to enable Tree-sitter support
    treesitter = function(ft) return true end,
}
```

## Highlighting on Text Content

To enable highlighting any text content,
disable Tree-sitter for that file type.

```lua
treesitter = function(ft)
    return ft ~= "typst" and ft ~= "markdown"
end
```

## Changing the highlighting

You should change switch highlight group of tags in the configuration,
or change the highlight group for Tree-sitter.

This plugin uses the following highlight groups for tags by default:

- `@comment.error`
- `@comment.warning`
- `@comment.todo`
- `@comment.hint`

## License

MIT License


