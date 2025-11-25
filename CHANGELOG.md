## 0.0.5
- Fixed Bugs

## 0.0.4
- Added `RotateOptionConfig` to control visibility of free rotation and fixed-angle rotation buttons.
- Extended `ImageEditorConfig` with a `rotateOptions` field; configure `enableFree` and `enableFixed` to show/hide rotation controls.
- Fixed icon display issue: added `cupertino_icons` dependency to resolve missing `CupertinoIcons.rotate_left` and `CupertinoIcons.rotate_right` icons.
- Improved image scaling calculation to reserve space for top and bottom toolbars, preventing images from covering UI elements.
- Fixed gesture handling: prevented accidental zoom triggers during single-finger panning.

## 0.0.3
- Added `ImageCompressionConfig` to downscale `ui.Image` output when exporting or saving temp files.
- Extended `ImageEditorConfig` with a `compression` field; the example app demonstrates enabling compression.

## 0.0.2
- Add saveImageToTempFile,  For workflows that absolutely need a path

## 0.0.1

### Added
- Initial docs: `README.md` and `README_CN.md` cover overview, features, quick start, and FAQ.
- API reference: `doc/api_reference.md` documents core widgets, configuration objects, controller APIs, and utilities.
- Licensing: distributed under the MIT License.
