# Delta Force - Testing & Calibration Guide

## Overview

This guide provides step-by-step instructions for testing and calibrating the Delta Force configuration to ensure accurate event detection. The process involves validating OCR coordinates, testing event detection, and refining parameters.

## Prerequisites

Before starting calibration:
- ✅ Delta Force installed and running at 2560x1440 resolution
- ✅ Powder application installed and configured
- ✅ OCR Debug Overlay Tool (`tools/OverlayOCR.js`) ready
- ✅ Sample gameplay footage (5-10 minutes recommended)

## Step 1: OCR Coordinate Calibration

### Using the OCR Debug Overlay

1. **Launch Delta Force** and start a match
2. **Open Powder** and begin recording
3. **Inject the OCR Overlay Tool**:
   ```javascript
   // Paste this into Powder's DevTools console:
   (function() {
     var script = document.createElement('script');
     script.src = 'file:///path/to/Powder-custom-game-support/tools/OverlayOCR.js';
     document.body.appendChild(script);
   })();
   ```

4. **Verify overlay appears**: You should see colored rectangles showing OCR regions
5. **Toggle layers** (click legend pills) to see different detection areas

### Calibrating Coordinates

#### Kill Message Area
- **Target**: Kill feed notifications ("KILL", "HEADSHOT", etc.)
- **Current coords**: `{ 0.380, 0.650, 0.620, 0.700 }`
- **Calibration process**:
  1. Trigger a kill in-game
  2. Observe where the notification appears
  3. Adjust coordinates to tightly frame the text
  4. Update in `game_postprocess.lua`

#### Streak Message Area
- **Target**: Multi-kill notifications ("DOUBLE KILL", "TRIPLE KILL", etc.)
- **Current coords**: `{ 0.300, 0.100, 0.700, 0.200 }`
- **Calibration process**:
  1. Get a double kill in-game
  2. Note the notification position
  3. Adjust coordinates to capture full notification
  4. Test with different streak types

#### Game Result Area
- **Target**: Victory/Defeat screens
- **Current coords**: `{ 0.350, 0.200, 0.650, 0.400 }`
- **Calibration process**:
  1. Complete a match (win or lose)
  2. Observe result screen position
  3. Adjust to frame the main result text

### Coordinate Format

Coordinates use normalized screen space (0.0 to 1.0):
```lua
cropCoords = { x1, y1, x2, y2 }
-- x1,y1 = top-left corner
-- x2,y2 = bottom-right corner
```

### Calibration Tips

- **Start conservative**: Make regions slightly larger than needed
- **Test multiple events**: Different notifications may appear in slightly different positions
- **Use overlay snapshots**: Press "S" to save PNGs for reference
- **Check all resolutions**: Test at different UI scales if possible

## Step 2: Event Detection Testing

### Running Test Analysis

1. **Capture test footage**:
   - Record 5-10 minutes of gameplay
   - Include all event types (kills, headshots, multi-kills, victory, defeat)
   - Use consistent settings (same resolution, UI scale)

2. **Run Powder analysis**:
   - Load your test footage
   - Use the Delta Force configuration
   - Start automatic analysis

3. **Review results**:
   - Check detected events vs. actual events
   - Note false positives and false negatives
   - Record timing accuracy

### Detection Testing Checklist

| Event Type | Expected Count | Detected Count | Accuracy | Notes |
|------------|-----------------|-----------------|----------|-------|
| Kill | | | | |
| Headshot | | | | |
| Double Kill | | | | |
| Triple Kill | | | | |
| Victory | | | | |
| Defeat | | | | |

## Step 3: Parameter Optimization

### Adjusting Detector Parameters

#### detectorDilateDiameter
- **Purpose**: Expands text pixels to join broken characters
- **Current values**: 4 (KillMessage), 3 (StreakMessage), 5 (GameResult)
- **Adjustment guide**:
  - Increase if text is broken or fragmented
  - Decrease if too much noise is detected
  - Typical range: 3-6

#### detectorMinimumArea
- **Purpose**: Filters out small noise
- **Current values**: 8 (KillMessage), 6 (StreakMessage), 500 (GameResult)
- **Adjustment guide**:
  - Increase to reduce false positives
  - Decrease if legitimate text is being filtered out
  - GameResult needs higher value due to larger text

#### detectorMargin
- **Purpose**: Padding around detected text
- **Current values**: 6 (KillMessage), 5 (StreakMessage), 25 (GameResult)
- **Adjustment guide**:
  - Increase if text is being cut off
  - Decrease for tighter bounding boxes
  - Typical range: 4-30

### Confidence Thresholds

Adjust in `events.json` under each event's `detection.confidenceThreshold`:
- **Current range**: 75-90
- **Adjustment guide**:
  - Start at 80 for most events
  - Increase to 85-90 if too many false positives
  - Decrease to 70-75 if missing legitimate events

## Step 4: Performance Optimization

### FPS Settings

Adjust in `game_postprocess.lua`:
```lua
local get_fps = function()
    return 5  -- Current setting
end
```

**Performance vs. Accuracy Tradeoff**:
- **3 FPS**: Low CPU, may miss fast events
- **5 FPS**: Balanced (recommended)
- **7 FPS**: Better accuracy, higher CPU
- **10 FPS**: Maximum accuracy, high CPU

### Optimization Checklist

1. **Start at 5 FPS** (balanced setting)
2. **Test analysis speed** with your hardware
3. **Monitor CPU/GPU usage** during analysis
4. **Adjust up or down** based on performance
5. **Consider GPU acceleration** if available

## Step 5: Validation & Final Testing

### Comprehensive Test Plan

1. **Create test dataset**:
   - 3 matches of Delta Force gameplay
   - Mix of victory and defeat
   - Various kill types (regular, headshot, melee, etc.)
   - Multiple multi-kill streaks

2. **Run full analysis**:
   - Process all test footage
   - Use optimized parameters
   - Enable detailed logging

3. **Validate results**:
   - Compare detected vs. actual events
   - Check timing accuracy (±0.5s tolerance)
   - Verify no false positives

4. **Document findings**:
   - Record final parameter values
   - Note any remaining issues
   - Document resolution/setting requirements

### Success Criteria

- ✅ **Detection Accuracy**: >95% of events detected correctly
- ✅ **False Positive Rate**: <2% of total detections
- ✅ **Timing Accuracy**: ±0.5s of actual event time
- ✅ **Performance**: Analysis completes in reasonable time
- ✅ **Stability**: No crashes or errors during analysis

## Troubleshooting Common Issues

### No Events Detected

**Symptoms**: Analysis completes but no events are found

**Solutions**:
1. **Verify OCR coordinates** with overlay tool
2. **Check game resolution** matches calibration (2560x1440)
3. **Test with known working footage**
4. **Reduce confidence thresholds** gradually (start with 70)
5. **Enable debug mode** in game_postprocess.lua

### Too Many False Positives

**Symptoms**: Many incorrect event detections

**Solutions**:
1. **Increase confidence thresholds** (try 85-90)
2. **Add more specific match patterns**
3. **Adjust detectorMinimumArea** (increase to filter noise)
4. **Refine crop coordinates** to exclude non-text areas
5. **Add cooldown periods** to event definitions

### Performance Issues

**Symptoms**: Analysis is very slow or crashes

**Solutions**:
1. **Reduce FPS setting** (try 3 instead of 5)
2. **Decrease detectorDilateDiameter** (try 3 instead of 4)
3. **Increase detectorMinimumArea** (filter more noise early)
4. **Enable GPU acceleration** if available
5. **Process shorter segments** (5 min instead of 10 min)

### Specific Events Not Detected

**Symptoms**: Some events work, others don't

**Solutions**:
1. **Check match patterns** for missing events
2. **Test that event type appears in footage**
3. **Adjust confidence threshold** for specific event
4. **Verify crop coordinates** cover the event area
5. **Add alternative match patterns** (e.g., "HS" and "HEADSHOT")

## Advanced Calibration Techniques

### Multi-Resolution Support

To support different resolutions:

1. **Create resolution profiles**:
```lua
local resolutionProfiles = {
    ["2560x1440"] = {
        killMessage = { 0.380, 0.650, 0.620, 0.700 },
        streakMessage = { 0.300, 0.100, 0.700, 0.200 },
        gameResult = { 0.350, 0.200, 0.650, 0.400 }
    },
    ["1920x1080"] = {
        killMessage = { 0.380, 0.650, 0.620, 0.700 }, -- May need adjustment
        -- ... other coordinates
    }
}
```

2. **Add resolution detection**:
```lua
local get_resolution = function()
    -- Implement resolution detection logic
    return "2560x1440" -- or detect dynamically
end

local get_ocr_config = function()
    local resolution = get_resolution()
    local profile = resolutionProfiles[resolution] or resolutionProfiles["2560x1440"]
    
    return {
        crops = {
            { cropName = "KillMessage", cropCoords = profile.killMessage, ... },
            { cropName = "StreakMessage", cropCoords = profile.streakMessage, ... },
            { cropName = "GameResult", cropCoords = profile.gameResult, ... }
        }
    }
end
```

### Dynamic Parameter Adjustment

Adjust parameters based on detection confidence:

```lua
local function detectKill(frameIndex)
    local detectedEvent = nil
    local bestScore = 0
    
    -- First pass with high confidence
    for _, config in ipairs(killDetectors) do
        local score = paddle_ocr.checkFuture(frameIndex, 3, 'KillMessage', config.match, config.score)
        if score and score > 85 then  -- High confidence threshold
            detectedEvent = config.event
            bestScore = score
            break
        end
    end
    
    -- If no high-confidence detection, try lower threshold
    if not detectedEvent then
        for _, config in ipairs(killDetectors) do
            local score = paddle_ocr.checkFuture(frameIndex, 3, 'KillMessage', config.match, 75)  -- Lower threshold
            if score and score > bestScore then
                detectedEvent = config.event
                bestScore = score
            end
        end
    end
    
    return detectedEvent, frameIndex - 2
end
```

## Final Checklist

Before considering calibration complete:

- [ ] OCR coordinates validated with overlay tool
- [ ] All event types tested and detected
- [ ] False positive rate <2%
- [ ] Detection accuracy >95%
- [ ] Performance acceptable for target hardware
- [ ] Documentation updated with final parameters
- [ ] Test footage and results archived
- [ ] Configuration backed up

## Maintenance & Updates

### Version History

```
Version 2.0 (2026-05-30):
- Enhanced event detection logic
- Optimized OCR coordinates
- Added comprehensive calibration guide
- Improved performance settings

Version 1.08 (2025-10-22):
- Initial functional implementation
- Basic OCR configuration
- Event definitions structure
```

### Update Process

1. **Test with new game versions** after updates
2. **Verify UI elements haven't changed** positions
3. **Re-calibrate if necessary** using this guide
4. **Update version number** in configuration files
5. **Document changes** in calibration notes

## Support & Resources

### Getting Help

1. **Check this calibration guide** first
2. **Review troubleshooting section** for common issues
3. **Consult main README.md** for general setup
4. **Use OCR overlay tool** for visual debugging
5. **Contact repository maintainer** for specific issues

### Additional Resources

- **Powder Documentation**: Main application guides
- **Paddle OCR Docs**: OCR engine documentation
- **Lua Reference**: Scripting language guide
- **Delta Force Wiki**: Game-specific information

---

**Last Updated**: 2026-05-30
**Status**: Active Development & Calibration
**Contact**: Repository maintainer for support
