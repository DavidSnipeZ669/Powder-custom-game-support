# Delta Force - Powder Game Support

## Status: Under Development ⚠️

This directory contains the configuration files for Delta Force support in Powder. The implementation is currently being refined to ensure accurate event detection.

## Files Included

### Configuration Files
- `ai-configs/visual_cues/DF/events.json` - Event definitions and scoring
- `ai-configs/visual_cues/DF/game_postprocess.lua` - OCR and detection logic
- `ai-configs/whitelist.json` - AI engine whitelist

### Game Entry Codes
- `Event Whitelist Code (main.js)` - Event definitions for main.js
- `Game Entry Code (main.js)` - Game metadata for main.js

### Assets
- `assets/supported-games/banner/bg-main.webp` - Game banner
- `assets/supported-games/cover/poster.webp` - Game cover art
- `assets/supported-games/icon-light-bg-color/96x96x1.svg` - Game icon

## Current Implementation Status

### Working Features
- ✅ Event definitions structure
- ✅ Basic OCR configuration
- ✅ Game asset files

### Features Under Development
- ⚠️ OCR coordinate calibration (needs validation)
- ⚠️ Event detection accuracy (being refined)
- ⚠️ Performance optimization (FPS settings)

### Known Issues
- OCR crop coordinates may not match actual UI positions
- Event detection may have false positives/negatives
- Timing offsets may need adjustment

## Usage Instructions

1. **Installation**: Follow the main README.md guide to add these files to Powder
2. **Calibration**: Use the OCR overlay tool to validate coordinates
3. **Testing**: Analyze gameplay footage to verify event detection
4. **Refinement**: Adjust coordinates and parameters as needed

## Troubleshooting

If events are not detected correctly:
1. Check OCR coordinates with the overlay tool
2. Verify match strings against actual game text
3. Adjust detector parameters (dilateDiameter, minimumArea)
4. Test with different FPS settings

## Contributing

To help improve this implementation:
1. Provide gameplay footage for analysis
2. Report detected vs. actual event timing
3. Suggest coordinate adjustments
4. Test with different resolutions

## Roadmap

- [ ] Validate OCR coordinates with actual gameplay
- [ ] Refine event detection logic
- [ ] Optimize performance settings
- [ ] Add comprehensive testing results
- [ ] Document calibration process

**Last Updated**: 2026-05-30
**Status**: Active Development
