# rbx_rojo_obj
This plugin is designed to make creating new objects and scripts as easy as possible

## How to Install
for Lazy just do
```lua
{
    'iWECHAMPIONSi/rbx_rojo_obj.nvim',
    opts = {},
},
```

## Quick Start
* Open a Rojo project containing a `default.project.json` and a `src` directory inside
* Run `:RbxBrowser`
* Navigate to the desired destination Directory
* Press `%` (Or run `:NameFile`) and provide a filename
* Search or select a Roblox Class or Roblox Script
* Optionally edit its properties
* Press `<C-e>` (Or run `:ExportClass`) while in the Class Display to export the file
* Profit?

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
    src_name = "src", -- the default name for your project's source directory (my_project/src)

    confirm_delete = true, -- Asks if you want to delete something if enabled

    files_visible = true, -- If non-directory files are visible be default in the directory browser if enabled

    return_to_class_disp = true, -- Switches cursor to Class Display when saving a property

    allow_overwrite = false, -- If it will allow for you to create a file or directory with the same name as one in the current directory if enabled
    confirm_overwrite = true, -- same as confirm_delete but for overwriting a file if enabled and allow_overwrite is enabled

    enable_default_keybinds = true, -- Any unassigned keybinds will default to predefined keybinds if enabled
})
```

Or if you want to do it in Lazy then use the `opts` field instead.  

### Configuring Keybindings

There are 2 methods:
```lua

custom_keybinds = {
    groups = {
        my_group = {
            keybinds = { "<C-e>", "<leader>e" },
            actions = {
                "export_class",
                "save_property",
            },
        },
    },
    actions = {
        export_class = { "E" },
    },
}

keybinds = {
    export_class = {
        ["<C-s>"] = true,
    },
    toggle_favorite_class = {},
}
```

```lua
-- Resulting keybinds, unmetioned keybinds will receive their defaults assuming the configuration is enabled
export_class = { "<leader>e", "<C-s>", "<C-e>", "E" }
toggle_favorite_class = {}
save_property = { "<C-e>" }

```

All custom keybinds are cumulative, so if an action is listed in `actions`, `my_group`, and `keybinds`, it will receive all of those keybinds.

If you choose to list an action, regardless of assigning a keybinding to it or not, the default keybindings will not be assigned to that action. It's recommended to check and make sure that you aren't assigning keybinds that conflict within the same buffer.

I didn't implement keybind conflict checking, there's a table that shows each action and its associated buffer(s).

Buffers:
There are buffers to be aware of when using commands and keybindings.  
`Class List`  
`Class Display`  
`Search Bar`  
`Property Editor`  
`Input`  
`Directory Browser`  

all actions/commands are in `normal` mode

| Action | Buffers | Description | Keybind | Command |
| :----: | :-----: | :---------- | :-----: | :------ |
| `N/A` | `Global` | Opens the browser |`N/A`| `:RbxBrowser` |
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
| choose_new_dir | `Class List` `Class Display` | Changes the output directory | `d` | `:ChooseNewDir` |
| select_class | `Class List` | Selects the highlighted class or toggles the highlighted category | `<CR>` | `:SelectClass` |
| toggle_favorite_class | `Class List` | Toggles favoriting/unfavoriting a class | `F` | `:ToggleFavorite` |
| favorite_class | `Class List` | Adds the highlighted class to favorites | `Not Bound` | `:FavoriteClass` |
| unfavorite_class | `Class List` | Removes the highlighted class from favorites | `Not Bound` | `:UnfavoriteClass` |
| select_property | `Class Display` | Selects highlighted property | `<CR>` | `:SelectProperty` |
| export_class | `Class Display` | Exports the current class as a file | `<C-e>` | `:ExportClass` |
| clear_property | `Class Display` | Clears the saved data from the highlighted property | `S` | `:ClearProperty` |
| name_class_config | `Class Display` | Saves/renames the current class config | `C` | `:SaveConfig` |
| delete_config | `Class Display` | Deletes current class config | `D` | `:DeleteConfig` |
| prev_config | `Class Display` | Switches to the previous class config | `<` | `:PrevConfig` |
| next_config | `Class Display` | Switches to the next class config | `>` | `:NextConfig` |
| duplicate_config | `Class Display` | Duplicates the current named config | `P` | `:DuplicateConfig` |
| enter_list | `Class Display` | Enters into the Class list | `<Esc>` | `:EnterList` | 
| close_property | `Property Editor` | Exits the property editor without saving | `Q` | `:CloseProperty` |
| save_property | `Property Editor` | Validates and saves the edited property | `<C-e>` | `:SaveProperty` |
| select_field | `Property Editor` | Selects the highlighted field | `<CR>` | `:SelectField` |
| next_keypoint | `Property Editor` | Displays the next keypoint | `>` | `:NextKeypoint` |
| prev_keypoint | `Property Editor` | Displays the previous keypoint | `<` | `:PrevKeypoint` |
| search_enter_list | `Search Bar` | Enters into the Class list | `<CR>` | `:EnterList` |

## Important Behaviors

### Input
Returning nothing (an empty input field) is treated as a no-op.  
#### Special for Class properties  
Returning "nil" will be treated as deleting that value. This was made specifically to allow for deleting of a value from properties/property fields  

### Filenames
When Checking for filename conflicts, it checks against `<filename>` and the supported Rojo filetypes that are synced.  
As of right now the plugin does not allow to create filenames with spaces or illegal characters for the detected OS.  

### Directory Browser
So even if `MyScript.client.luau` exists, any attempt create anything with the name `MyScript`, even if it's not a LocalScript, will be flagged as a name conflict.  
You cannot go above the `src` directory (the plugin checks if the parent directory is the root directory, if it is then it no-ops)  
The Directory Browser will attempt to find your `src` directory given the directory Neovim was opened in. There must be a `default.project.json` for the browser to open (so the browser can verify it's in a Roblox project). If it cannot find `src` (or what your `src` directory is named in your config) it will ask you for the name of the `src` directory. This is a temporary value and will not persist between sessions.

### Favoriting a Class
Every time you favroite a class, your saved classes are saved between Neovim sessions.

### Class Configs
A class config is simply a list of property values for a class.  
To save a config for a class, just give it a name. Note that if a config is not named, it's considered temporary and will not persist between neovim sessions.  
Only one temporary (unnamed) config is allowed per class. There is no limit to the number of configs, but to create a new config, all other configs for that class must be named.  
When duplicating a config, that config must be named. Duplicated configs by default are not named. If another unnamed config already exists for that config, you will be asked if you want to replace the current unnamed config.  
When exporting a class, the config does not need to be named.

### Properties   
Properties go through a verification when you save a property. If that verification passes, you will see a `*` next to that property name, indicating that it will be exported with the class if exporting that class with the configuration. Properties that do not have a `*` will not be exported with the rest of the config.  
If the verification fails and the property does not have a `*` next to it, the values will still save for later editing. If the property does have a `*` next to it, the values will revert back to their previously verified values. This is to prevent stale property values. Valid properties are properties whos data match the Roblox API's specifications. For more specifics the source file is `roblox_types.lua`.  
Some properties have default values or clamped values that will automatically be applied if no value is given or that value is outside of the clamped range. Make sure to look at the Roblox API for information regarding clamped values. **Default values may be removed in the future, which will require every value to be explicitly defined.**

### Creating New Configs and Keypoints
When switching between configs and keypoints, when doing either `:NextConfig` or `:NextKeypoint` on the last config/keypoint respectively, will create a new config/keypoint assuming that the previous config/keypoint has at least one filled property/field. And for configs there also must be no other unnamed configs for that class.


## Default Keybinds list
### This can also be used as a reference for how to make keybinds
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
