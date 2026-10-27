## ChangeLog

### Added
- Added configurable `Rbx*` highlight groups for the Class Browser, Directory Browser, and Property Editor, including links to colorscheme and Netrw highlight groups.
- Added automatic reapplication of configured highlights when the Neovim colorscheme changes.
- Added more informative live property-validation messages, including offending keypoint indices and sequence-wide constraints for `ColorSequence` and `NumberSequence`.

### Changed
- Applied colorscheme-aware highlighting to class names, property names, data types, values, numbers, booleans, directories, file classification suffixes, selections, and validation errors.
- Updated the Property Editor to preserve its displayed contents when focus moves to another window.
- Updated sequence validation to reject keypoint times outside the range `[0, 1]` rather than silently clamping them.

### Fixed
- Fixed default keybinding initialization when `setup()` is called.
- Fixed missing, stale, or misplaced highlights after buffer redraws, property edits, search-mode favorite changes, and keypoint navigation.
- Fixed the `NumberSequence` keypoint-count and endpoint comparisons.
- Fixed font-family alias normalization when generating font asset paths.
- Fixed `.meta.json` destination paths when editing metadata associated with Luau scripts, preventing metadata output from being directed to the script source file.
- Added explicit rejection of unsupported implicit property values during import instead of failing while processing them.
