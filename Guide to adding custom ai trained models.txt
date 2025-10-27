# Powder Model (.pwdmdl) Format Guide

## Overview
`.pwdmdl` files are Powder's custom model format used for AI-based game event detection. These models are loaded by the native Powder application and used alongside the Lua-based event detection scripts.

## What is .pwdmdl?

Based on analysis of the Powder application:
- `.pwdmdl` files are **ONNX models** with a custom Powder wrapper/header
- The application uses **ONNX Runtime** for model inference (`onnxruntime.dll`)
- Models are optimized and may include hardware-specific acceleration (VitisAI on AMD, etc.)

## File Structure

### Header Format
```
Bytes 0-5: "OXsK32" - Magic identifier/signature
Bytes 6+:  Binary model data (likely ONNX format)
```

## Creating .pwdmdl Models

### Prerequisites
1. **ONNX Runtime** installed
2. **Python** with TensorFlow/Keras or PyTorch
3. Model training environment

### Step 1: Train Your Model

Your model should:
- Accept game video frames as input (typical: 224x224 or 320x320 RGB)
- Output probabilities for different game events/states
- Be optimized for real-time inference (lightweight architecture)

Example output classes for a FPS game:
```python
classes = [
    'in_game',
    'kill_message',
    'death_message',
    'victory_screen',
    'defeat_screen',
    # ... etc
]
```

### Step 2: Convert to ONNX

#### From Keras (.h5 or .keras):
```python
import tf2onnx
import tensorflow as tf

# Load your Keras model
model = tf.keras.models.load_model('your_model.keras')

# Convert to ONNX
spec = (tf.TensorSpec((None, 224, 224, 3), tf.float32, name="input"),)
output_path = "model.onnx"

model_proto, _ = tf2onnx.convert.from_keras(
    model,
    input_signature=spec,
    opset=13,
    output_path=output_path
)
```

#### From PyTorch:
```python
import torch
import torch.onnx

model = YourModel()
model.load_state_dict(torch.load('model.pth'))
model.eval()

dummy_input = torch.randn(1, 3, 224, 224)
torch.onnx.export(
    model,
    dummy_input,
    "model.onnx",
    export_params=True,
    opset_version=13,
    input_names=['input'],
    output_names=['output']
)
```

### Step 3: Create .pwdmdl File

**Method 1: Direct Wrapper (Recommended)**
```python
import struct

def create_pwdmdl(onnx_path, output_path):
    # Read ONNX model
    with open(onnx_path, 'rb') as f:
        onnx_data = f.read()
    
    # Create .pwdmdl with header
    header = b'OXsK32'
    
    with open(output_path, 'wb') as f:
        f.write(header)
        f.write(onnx_data)
    
    print(f"Created {output_path}")

# Usage
create_pwdmdl('model.onnx', 'model.pwdmdl')
```

**Method 2: Copy Existing Structure**
```bash
# Copy an existing .pwdmdl from a similar game
cp ai-configs/visual_cues/FRTN/model.pwdmdl ai-configs/visual_cues/MYGAME/model.pwdmdl
# Then replace with your trained model
```

### Step 4: Optimize for Hardware (Optional)

For AMD GPUs with VitisAI support:
```python
# The app automatically creates optimized xmodel files in cache
# Structure: visual_cues/GAME/model_vitis_cache_strix/cache/
# This happens automatically on first load
```

## Using .pwdmdl Files

### 1. Place Model in Game Folder
```
ai-configs/
└── visual_cues/
    └── YOURGAME/
        ├── model.pwdmdl          # Your trained model
        ├── events.json            # Event definitions
        └── game_postprocess.lua   # Processing logic
```

### 2. Configure game_postprocess.lua

The Lua script receives model outputs and processes them:

```lua
local visualCuesConfig = {
    -- Map model output classes to cues
    ['in_out::in_game'] = { halfWindowSmoothing = 5, smoothingPower = 0 },
    ['visual_cues::kill_message'] = { halfWindowSmoothing = 3 },
    ['visual_cues::death_banner'] = { halfWindowSmoothing = 3 },
    -- Add your model's output classes here
}

local computeEvents = function(modelOutputs, ocrOutput, frameTimes)
    -- modelOutputs contains the predictions from your .pwdmdl model
    local cues = {}
    
    if next(modelOutputs) ~= nil then
        local visualCues = smoothing.run(visualCuesConfig, modelOutputs, frameTimes)
        for cueName, cueValues in pairs(visualCues) do
            cues[cueName] = cueValues
        end
    end
    
    -- Process cues into events
    -- ...
end
```

### 3. Model Output Format

Your model should output a dictionary/map of class probabilities:
```
{
    "in_out::in_game": 0.95,
    "visual_cues::kill_message": 0.12,
    "visual_cues::death_banner": 0.03,
    ...
}
```

## Model Requirements

### Input Specifications
- **Format**: RGB images
- **Typical sizes**: 224x224, 320x320, 640x640
- **Normalization**: Usually [0, 1] or [-1, 1]
- **Batch size**: Support dynamic batch size (None, H, W, C)

### Output Specifications
- **Format**: Probability scores (0-1) for each class
- **Classes**: Named using Powder's convention:
  - `in_out::*` - Game state detection (in_game, out_of_game)
  - `visual_cues::*` - Event detection (kill_message, victory, etc.)

### Performance
- **Inference time**: < 50ms per frame (preferably < 20ms)
- **Model size**: < 50MB (preferably < 20MB)
- **FPS setting**: Configure in `game_postprocess.lua`:
  ```lua
  local get_fps = function()
      return 4  -- Process 4 frames per second
  end
  ```

## Example: Complete Workflow

```python
# 1. Train your model (using Keras)
import tensorflow as tf

model = tf.keras.Sequential([
    tf.keras.layers.Conv2D(32, 3, activation='relu', input_shape=(224, 224, 3)),
    tf.keras.layers.MaxPooling2D(),
    # ... more layers
    tf.keras.layers.Dense(num_classes, activation='softmax')
])

model.compile(optimizer='adam', loss='categorical_crossentropy')
model.fit(train_data, train_labels, epochs=10)
model.save('game_detector.keras')

# 2. Convert to ONNX
import tf2onnx

spec = (tf.TensorSpec((None, 224, 224, 3), tf.float32, name="input"),)
tf2onnx.convert.from_keras(model, input_signature=spec, 
                           output_path="model.onnx", opset=13)

# 3. Create .pwdmdl
def create_pwdmdl(onnx_path, output_path):
    with open(onnx_path, 'rb') as f:
        onnx_data = f.read()
    with open(output_path, 'wb') as f:
        f.write(b'OXsK32')
        f.write(onnx_data)

create_pwdmdl('model.onnx', 'model.pwdmdl')

# 4. Copy to game folder
# cp model.pwdmdl ai-configs/visual_cues/YOURGAME/
```

## Troubleshooting

### Model Not Loading
- Verify the header is correct: `OXsK32` (6 bytes)
- Ensure ONNX model is valid (test with onnxruntime separately)
- Check model input/output shapes match expectations

### Poor Detection Performance
- Increase FPS in `get_fps()` for more frequent sampling
- Adjust smoothing parameters in `visualCuesConfig`
- Retrain model with more diverse data
- Check event detection thresholds in Lua functions

### High CPU/GPU Usage
- Reduce FPS setting
- Use smaller model architecture
- Enable hardware acceleration (VitisAI for AMD)
- Quantize model weights

## Additional Resources

### Existing Model Analysis
Study existing models for reference:
```bash
# Compare model sizes
ls -lh ai-configs/visual_cues/*/model.pwdmdl

# Check which games have models
find ai-configs/visual_cues -name "model.pwdmdl"
```

### Model Classes
Look at `game_postprocess.lua` files to see what classes other games detect:
- `ai-configs/visual_cues/FRTN/game_postprocess.lua` (Fortnite)
- `ai-configs/visual_cues/CS2/game_postprocess.lua` (Counter-Strike 2)
- `ai-configs/visual_cues/CODMW3/game_postprocess.lua` (Call of Duty)

## Notes

- `.pwdmdl` is a Powder-specific format wrapping ONNX models
- The application loads these models using ONNX Runtime
- Hardware acceleration is automatic when available
- Models work in conjunction with Lua scripts for event detection
- OCR detection (Paddle OCR) is separate and doesn't require custom models

---

**Version**: 8.0.3 (Modified)
**Last Updated**: October 27, 2025
