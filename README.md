# todo-highlight.nvim

Highlights TODO comments for easy lookup.

> [!Note]
> This plugin is beta.
> Configuration and behaviour may change significantly without warning.

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

## Buffer Local Option

To temporarily switch modes for the current buffer:

- `:TodoHighlight` switch to default mode based on configuration
- `:TodoHighlight disabled` disable tag highlighting
- `:TodoHighlight contextless` use contextless highlighting
- `:TodoHighlight treesitter` use Tree-sitter context and highlight only comments

## Default Configuration

```lua
{
    tags = {

        -- TAG_NAME = "highlight group",

        -- run `:highlight` to browse available highlight groups
        -- or `:Telescope highlight` if you have telescope available

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

    -- Return true to allow highlighting for selected file type
    enabled = function(ft) return true end,

    -- Return the Tree-sitter query for the selected file type
    ts_query = function(ft) return [[(comment) @comment]] end,

    -- Return true to highlight without context awareness (no Tree-sitter)
    contextless = function(ft) return false end,
}
```

## Fallback behaviour

There is no fallback behaviour.
By default, all files are highlighted with Tree-sitter context.
If no corresponding Tree-sitter parser is found,
then no highlighting is performed.

## Highlighting with Custom Context

To highlight any text content as well as comments,
configure the `ts_query` for that language.
Recommended for file types containing pure text content and no code structure.

```lua
ts_query = function(ft)
    if ft == "typst" then
        return [[
            ((comment) @comment)
            ((text) @text)
        ]]
    end
    return [[(comment) @comment]]
end
```

## Highlighting without Context

To highlight any text that looks like the tag,
regardless of if it is a comment or not,
set contextless to true for that file type.

Recommended for file types containing pure text content and no code structure.

```lua
contextless = function(ft)
    return ft == "markdown"
end
```

## Changing the highlighting

You should change switch highlight group of tags in the configuration,
or change the highlight group for Tree-sitter.

This plugin uses the following highlight groups for tags by default:

- `@comment.error`
- `@comment.warning`
- `@comment.todo`
- `@comment.note`

## TODO Features

- custom scope highlighting
- tree-sitter update hook

## Inspiration

- [folke/todo-commits.nvim](https://github.com/folke/todo-comments.nvim)

## License

MIT License


