# Changelog

All notable changes to this project are documented in this file.
## 0.1.1 - 05-27-2026

### Added
- The Icon v0.1.1

### Fixed
- Windows version not showing EXIF lines

## 0.1.0 - 05-26-2026

### Added

- View EXIF, IPTC, XMP, and GPS metadata from image files via ExifTool.
- Drag and drop files onto the window to load them.
- File list panel with multi-select support (Ctrl and Shift click).
- Metadata table with columns for group, tag ID, tag name, and value.
- Inline editing of tag values. Read-only groups (File, ICC_Profile) are protected.
- Delete tags with a click; deletions are applied on save.
- Add new tags via a searchable catalog of known EXIF tags, or enter custom tag names.
- Undo support for edits and deletions (Ctrl+Z).
- Save changes to files (Ctrl+S).
- Unsaved changes warning dialog when closing the window.
- Rename files by double-clicking the filename in the left panel.
- Export metadata to text, CSV, or JSON.
- Copy metadata to clipboard as tab-delimited text.
- XMP subgroup normalization: all XMP-* groups display as "XMP".
- Tooltips on tag values; double-click long values to open a dialog with a Copy button.
- Draggable sidebar divider to resize the file list panel.
- Settings dialog for theme selection, always-on-top window, ExifTool path, and custom ExifTool arguments.
- About dialog showing version, credits, and license information.
