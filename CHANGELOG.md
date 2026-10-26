## ChangeLog

### Added
- Added support for editing existing Roblox objects directly from the Directory Browser.
- Added detection and loading of Rojo model files, metadata files, and associated Luau scripts.
- Added bidirectional conversion between Rojo JSON property values and editable property representations.
- Added a persistent Property Editor with live previews when navigating through class properties.
- Added `:RbxBrowserCwd` to open the Directory Browser at the current buffer's location.
- Added optional directory arguments and path completion to `:RbxBrowser`.
- Added `return_to_class_disp` configuration option.
- Added `EditClass` (`E`) binding

### Changed
- Updated the Property Editor to reuse an existing window and clear its contents when closed.
- Updated primitive and Enum property displays to support previews without opening input prompts.
- Updated the Directory Browser to display recognized Roblox class names and sort class-associated entries.
- Updated Directory Browser layout dimensions for consistency with the Class Browser.
- Updated the Class Browser to distinguish existing-file editing from creating new Roblox objects.
- Updated property validation and normalization for several Roblox ValueTypes.
- Updated serialization of `init.meta.json` for script and non-script classes.
- Updated class configuration handling to isolate existing-file editing from saved presets.
- Updated PhysicalProperties serialization to export `Default` when any field is set to `Default`

### Fixed
- Corrected the output path for non-script `init.meta.json` creation.
- Corrected the distinction between model and init-metadata serialization.
- Corrected UDim display when exporting property
- Removed development debugging output from object creation.
- Fixed `ClearProperty` (`S`) binding not being binded

### Updated Roblox API Data Dump

- Added the `AudioContent` property to `AudioPlayer` and `Sound`.
- Added the `Editor` property to `InputAction`, `InputBinding`, and `InputContext`.
- Added the `AudioSortType` enum with six values.
- Added `Bezier` and `Spring` to `EasingStyle`.
- Added `NoReason` to `FriendsCallingEndReason`.

No existing classes, properties, or enum values were removed.
