# rbx_rojo_obj
A keyboard-first Neovim browser for creating Roblox objects and scripts in Rojo projects, editing supported existing objects, and managing class properties.

## Installation
With lazy.nvim:
```lua
{
    'iWECHAMPIONSi/rbx_rojo_obj.nvim',
    opts = {},
},
```

## Quick Start
1. Open a Rojo project containing `default.project.json` and a source directory (by default, `src/`).
2. Run `:RbxBrowser` to open the Directory Browser. You can supply an optional destination directory (relative to `src/`), or use `:RbxBrowserCwd` to start at the current buffer's location.
3. Navigate to the destination, press `%` (`:NameFile`), and enter a new object name.
4. Search for or select a Roblox class, then optionally edit its properties.
5. In the Class Display, press `<C-e>` (`:ExportClass`) to create the object or script.

To edit an existing supported Rojo object instead, enable file visibility if necessary, select the object in the Directory Browser, and press `E` (`:EditClass`). The editor supports recognized `.model.json`, `.meta.json`, Luau script, and `init.*` directory representations. For editing, property values must use explicit Rojo type wrappers; implicit property values are currently unsupported.

You can also create an object directly with `:RbxCreate <name> <class> [directory]`.

https://github.com/user-attachments/assets/0bf07c23-7b26-44ba-bb66-f2c47d87ae84

## Configuration

The default configuration is this

```lua
require('rbx_rojo_obj').setup({
    custom_keybinds = {
        groups = {},
        actions = {},
    },

    keybinds = {},
    highlights = {
        RbxClass = { default = true, link = "Type" },
        RbxProperty = { default = true, link = "Identifier" },
        RbxValue = { default = true, link = "String" },
        RbxNumber = { default = true, link = "Number" },
        RbxBoolean = { default = true, link = "Boolean" },
        RbxDataType = { default = true, link = "Type" },
        RbxInactive = { default = true, link = "Comment" },
        RbxSelected = { default = true, link = "CursorLine" },
        RbxBrowser = { default = true, link = "Normal" },
        RbxError = { default = true, link = "DiagnosticError" },
        RbxDir = { default = true, link = "netrwDir" },
        RbxPlain = { default = true, link = "netrwPlain" },
        RbxClassify = { default = true, link = "netrwClassify" },
    },
    src_name = "src", -- Source directory name (for example, my_project/src)

    confirm_delete = true, -- Asks if you want to delete something if enabled

    files_visible = true, -- If non-directory files are visible be default in the directory browser if enabled

    return_to_class_disp = true, -- Return to Class Display after saving a property; false keeps the editor active

    allow_overwrite = false, -- If it will allow for you to create a file or directory with the same name as one in the current directory if enabled
    confirm_overwrite = true, -- same as confirm_delete but for overwriting a file if enabled and allow_overwrite is enabled

    enable_default_keybinds = true, -- Any unassigned keybinds will default to predefined keybinds if enabled
})
```

Or if you want to do it in Lazy then use the `opts` field instead.  

### Configuring Keybindings

Keybindings can be assigned through action groups, per-action lists, or direct key maps. For example:

```lua
custom_keybinds = {
    groups = {
        my_group = {
            keybinds = { "<leader>e" },
            actions = { "export_class", "export_property" },
        },
    },
    actions = {
        export_class = { "E" },
    },
},
keybinds = {
    export_class = { ["<C-s>"] = true },
    toggle_favorite_class = {},
},
```

These produce `export_class` bindings for `<leader>e`, `E`, and `<C-s>`, and an `export_property` binding for `<leader>e`. The empty `toggle_favorite_class` table disables its default binding. An action that has been explicitly configured does not receive its default keybindings; other actions receive defaults when `enable_default_keybinds = true`.

Bindings for the same action are cumulative across the configured groups and per-action maps. Avoid binding different actions to the same key in the same buffer; the plugin does not perform conflict checking.

### Highlighting and colorschemes

The browser and Property Editor use configurable `Rbx*` highlight groups. By default they link to your colorscheme's standard groups (and Netrw's directory/classification groups where applicable). You can override an individual group with a link name or a Neovim highlight specification:

```lua
highlights = {
    RbxClass = "Function",
    RbxError = { fg = "#ff6677", bold = true },
    RbxDir = { link = "Directory" },
},
```

Custom highlight definitions replace the corresponding default specification. Colorscheme changes trigger reapplication of the plugin's configured groups. `RbxPlain` and `RbxInactive` are currently defined for customization but are not applied by the browser rendering paths shown in this release.

The command table below identifies the buffer in which each action is available. The primary buffers are the Class List, Class Display, Search Bar, Property Editor, Input prompt, and Directory Browser.

The action keybindings below are in normal mode; the Search Bar and Input prompts also accept text input.

| Action | Buffers | Description | Keybind | Command |
| :----: | :-----: | :---------- | :-----: | :------ |
| `N/A` | `Global` | Opens the Directory Browser (optional path relative to `src/`) | `N/A` | `:RbxBrowser [directory]` |
| `N/A` | `Global` | Opens the Directory Browser from the current buffer location | `N/A` | `:RbxBrowserCwd` |
| `N/A` | `Global` | Creates a Roblox object directly | `N/A` | `:RbxCreate <name> <class> [directory]` |
| select_dir | `Directory Browser` | Enters/selects the highlighted directory | `<CR>` | `:SelectDir` |
| enter_parent_dir | `Directory Browser` | Enters the parent directory | `-` | `:EnterParentDir` |
| create_dir | `Directory Browser` | Creates a new directory inside the current directory | `d` | `:CreateDir` |
| delete_dir | `Directory Browser` | Recursively deletes the highlighted directory | `D` | `:DeleteDir` |
| rename_dir | `Directory Browser` | Renames the highlighted file or directory | `R` | `:RenameDir` |
| name_file | `Directory Browser` | Asks for the name of the file before switching to Class browser | `%` | `:NameFile` |
| edit_class | `Directory Browser` | Opens a window to edit the contents of the highlighted class | `E` | `:EditClass` |
| close_dir_window | `Directory Browser` | Closes the directory browser | `Q` | `:CloseDirWindow` |
| toggle_file_visibility | `Directory Browser` | Toggles the visibility of non-directory files | `H` | `:ToggleFileVisibility` |
| enable_file_visibility | `Directory Browser` | Enables the visibility of non-directory files | `Not Bound` | `:EnableFileVisibility` |
| disable_file_visibility | `Directory Browser` | Disables the visibility of non-directory files | `Not Bound` | `:DisableFileVisibility` |
| close_input | `Input` | Closes the input without saving | `Q` | `:CloseInput` |
| start_search | `Class List` | Enters the Search Bar | `/` | `:StartSearch` |
| close_browser_window | `Class List` `Class Display` `Search Bar` | Closes Class browser | `Q` | `:CloseBrowser` |
| rename_file | `Class List` `Class Display` | Changes the output filename | `R` | `:RenameFile` |
| choose_new_dir | `Class List` `Class Display` | Changes the output directory | `d` | `:SelectDir` |
| select_class | `Class List` | Selects the highlighted class or toggles the highlighted category | `<CR>` | `:SelectClass` |
| toggle_favorite_class | `Class List` | Toggles favoriting/unfavoriting a class | `F` | `:ToggleFavorite` |
| favorite_class | `Class List` | Adds the highlighted class to favorites | `Not Bound` | `:FavoriteClass` |
| unfavorite_class | `Class List` | Removes the highlighted class from favorites | `Not Bound` | `:UnfavoriteClass` |
| select_property | `Class Display` | Selects highlighted property | `<CR>` | `:SelectProperty` |
| export_class | `Class Display` | Exports the current class as a file | `<C-e>` | `:ExportClass` |
| clear_property | `Class Display` | Clears the saved data from the highlighted property | `S` | `:ClearProperty` |
| name_class_config | `Class Display` | Saves/renames the current class config | `C` | `:NameConfig` |
| delete_config | `Class Display` | Deletes current class config | `D` | `:DeleteConfig` |
| prev_config | `Class Display` | Switches to the previous class config | `<` | `:PrevConfig` |
| next_config | `Class Display` | Switches to the next class config | `>` | `:NextConfig` |
| duplicate_config | `Class Display` | Duplicates the current named config | `P` | `:DuplicateConfig` |
| enter_list | `Class Display` | Enters into the Class list | `<Esc>` | `:EnterList` | 
| close_property | `Property Editor` | Exits the property editor without saving | `Q` | `:CloseProperty` |
| export_property | `Property Editor` | Validates and saves the edited property | `<C-e>` | `:ExportProperty` |
| select_property_field | `Property Editor` | Selects the highlighted field | `<CR>` | `:SelectPropertyField` |
| next_keypoint | `Property Editor` | Displays the next keypoint | `>` | `:NextKeypoint` |
| prev_keypoint | `Property Editor` | Displays the previous keypoint | `<` | `:PrevKeypoint` |
| search_enter_list | `Search Bar` | Enters into the Class list | `<CR>` | `:EnterList` |

## Important Behaviors

### Input
Returning nothing (an empty input field) is treated as a no-op.  
#### Special for Class properties  
Returning "nil" will be treated as deleting that value. This was made specifically to allow for deleting of a value from properties/property fields  

### Filenames
When checking for filename conflicts, it checks against `<filename>` and the supported Rojo filetypes that are synced.  
The plugin does not permit names containing spaces or characters rejected by its platform-specific filename checks.  

### Directory Browser
Recognized Roblox objects display their class names beside their filenames or directories. Directory entries are sorted before files, and class-associated entries sort before unrecognized entries of the same kind. The browser supports navigating and renaming files and directories, and opening existing recognized objects for property editing.

So even if `MyScript.client.luau` exists, any attempt create anything with the name `MyScript`, even if it's not a LocalScript, will be flagged as a name conflict.  
You cannot go above the `src` directory (the plugin checks if the parent directory is the root directory, if it is then it no-ops)  
The Directory Browser will attempt to find your `src` directory given the directory Neovim was opened in. There must be a `default.project.json` for the browser to open (so the browser can verify it's in a Roblox project). If it cannot find `src` (or what your `src` directory is named in your config) it will ask you for the name of the `src` directory. This is a temporary value and will not persist between sessions.

### Favoriting a Class
Favorited classes are saved between Neovim sessions.

### Class Configs
A class config is simply a list of property values for a class.  
To save a config for a class, just give it a name. Note that if a config is not named, it's considered temporary and will not persist between neovim sessions.  
Only one temporary (unnamed) config is allowed per class. There is no limit to the number of configs, but to create a new config, all other configs for that class must be named.  
When duplicating a config, that config must be named. Duplicated configs by default are not named. If another unnamed config already exists for that config, you will be asked if you want to replace the current unnamed config.  
When exporting a class, the config does not need to be named.

### Properties
The Property Editor shows `Can Export: true/false`, updated when fields are submitted, with a diagnostic message for supported validation failures. For `ColorSequence` and `NumberSequence`, errors can identify the offending keypoint or a sequence-wide constraint. This is validation feedback before exporting the object, not a promise that every property will be accepted by Roblox Studio.

Saving a verified property adds a `*` beside its name in the Class Display, indicating that the property will be exported with the chosen configuration. Properties without `*` are omitted from export. Invalid values can be retained for later editing if the property has no previously verified export value. If a verified value already exists, an invalid edit does not replace that exported value.

Some datatypes clamp numeric values or supply defaults. `PhysicalProperties` exports `Default` if any field is set to `Default`. See `lua/roblox_insert/roblox_types.lua` and the Roblox/Rojo specifications for datatype-specific requirements.

**Editing existing files:** Imported `Properties`/`properties` entries must use explicit typed representations, such as `{ "Bool": true }`; implicit values (such as a bare `true`) are rejected. Existing-file editing is intended for recognized Roblox objects, not arbitrary JSON or Luau source modification.

### Creating New Configs and Keypoints
When switching between configs and keypoints, when doing either `:NextConfig` or `:NextKeypoint` on the last config/keypoint respectively, will create a new config/keypoint assuming that the previous config/keypoint has at least one filled property/field. And for configs there also must be no other unnamed configs for that class.

## Default Keybinding Definitions
This mirrors the currently defined default keybinding groups and actions:
```lua
local default_keybinds = { 
    groups = {
        export = {
            keybinds = { "<C-e>" },
            actions = {
                "export_class",
                "export_property",
            },
        },

        select = {
            keybinds = { "<CR>" },
            actions = {
                "select_class",
                "select_dir",
                "search_enter_list",
                "select_property",
                "select_property_field",
            },
        },

        close_window = {
            keybinds = { "Q" },
            actions = {
                "close_browser_window",
                "close_dir_window",
                "close_input",
                "close_property",
            },
        },

        delete = {
            keybinds = { "D" },
            actions = {
                "delete_config",
                "delete_dir",
            },
        },

        next = {
            keybinds = { ">" },
            actions = {
                "next_config",
                "next_keypoint",
            },
        },

        prev = {
            keybinds = { "<" },
            actions = {
                "prev_config",
                "prev_keypoint",
            },
        },

        rename = {
            keybinds = { "R" },
            actions = {
                "rename_dir",
                "rename_file",
            },
        },
    },

    actions = {
        choose_new_dir = { "d" },
        class_enter_list = { "<Esc>" },
        create_dir = { "d" },
        duplicate_config = { "P" },
        edit_class = { "E" },
        enter_parent_dir = { "-" },
        name_class_config = { "C" },
        name_file = { "%" },
        start_search = { "/" },
        toggle_file_visibility = { "H" },
        toggle_favorite_class = { "F" },
    },
}
```
