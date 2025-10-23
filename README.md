**Guide: How to Add Custom Game Support to Powder after discontinuation**




This guide provides a step-by-step process for adding new, unsupported games to the discontinued Powder desktop application (v8.0.2 Standalone). Since the app is no longer maintained, this is the only way to enable event detection for newer titles.

The process involves creating configuration files that tell Powder how to identify in-game events and modifying the application's core files to make it recognize your new game.

Disclaimer: This process involves editing application files. While the Powder app is offline and the risk is low, always back up any files before you modify them.

Prerequisites

Before you begin, you will need:

Powder Standalone App: The Powder_v8.0.2_standalone.exe file, installed on your system. (found at either https://wheybags.com/assets/Powder_v8.0_final.exe or releases)

A Code Editor: VS Code is highly recommended as it can search the contents of files within an entire folder. A basic text editor like Notepad will also work.

Node.js: This is required to install the asar tool. Download it from the official Node.js website.

ASAR Tool: A command-line utility for packing and unpacking .asar archives.

Game Assets: You will need three images for your game:

A poster image (e.g., poster.webp)

A banner image (e.g., background.webp)

An icon (e.g., icon-logo.svg or .png)

Gameplay Footage: A video of you playing the game, showing what the on-screen notifications look like for kills, headshots, multi-kills, etc. This is essential for configuring the detection script.



**Part 1: Understanding the File Structure**



The Powder app's files are primarily located in C:\Users\[YourUsername]\AppData\Local\Programs\powder-desktop\. Inside, you will find a resources folder, which is our main target.

powder-desktop\resources\app.asar: This is a compressed archive containing the application's user interface and core logic. We will need to unpack this to add our game to the UI.

powder-desktop\resources\app-unpacked\ (You will create this): This will be our temporary workspace for the unpacked application files.

powder-desktop\assets\supported-games\: Contains the UI image assets for each game.

powder-desktop\ai-configs\visual_cues\: Contains the logic files (.json, .lua) for event detection.

powder-desktop\ai-configs\whitelist.json: A simple list of game IDs that the AI engine is allowed to monitor.



**Part 2: Creating Your Custom Game Files**

We will use "Delta Force" (ID: DF) as our example.

1. Create the Asset Folders and Files

Navigate to the assets/supported-games/ folder and create a new folder with your game's short ID (e.g., DF). Inside that folder, create the following structure and place your images inside:

DF\
├── banner\
│   └── background.webp
├── cover\
│   └── poster.webp
└── icon-light-bg-color\
    └── icon-logo.svg  (or .png)
    
2. Create the Logic Folders and Files

Navigate to the ai-configs\visual_cues\ folder and create another folder with your game's ID (e.g., DF). Inside this folder, you will create two files: events.json and game_postprocess.lua.

A. events.json
This file defines the events Powder should recognize.

Example events.json for Delta Force (currently doesn't work):
```
{
  "name": "DF",
  "events": [
    {
      "name": "victory",
      "displayName": "Victory",
      "icon": "overall-victory",
      "default": true,
      "tooltip": "When you win a game.",
      "eventScore": 30,
      "automontage" : {
        "primary": false,
        "secondary": true,
        "offsetBefore": 3,
        "offsetAfter": 3,
        "effectTypes": []
      }
    },
    {
      "name": "defeat",
      "displayName": "Defeat",
      "icon": "overall-lose",
      "default": false,
      "tooltip": "When you lose a game.",
      "eventScore": 5,
      "automontage" : {
        "primary": false,
        "secondary": false,
        "offsetBefore": 0,
        "offsetAfter": 0,
        "effectTypes": []
      }
    },
    {
      "name": "doubleKill",
      "displayName": "Double Kill",
      "icon": "double-kill",
      "default": true,
      "tooltip": "When you kill 2 enemies within a short time of one another.",
      "eventScore": 25,
      "automontage" : {
        "primary": true,
        "secondary": false,
        "offsetBefore": 2,
        "offsetAfter": 2,
        "effectTypes": ["greyDistortionArrow", "veryFastThenSlow", "fastThenSlow", "flashScope", "slowFastSlow", "lensShake", "backToColor"]
      }
    },
    {
      "name": "tripleKill",
      "displayName": "Triple Kill",
      "icon": "triple-kill",
      "default": true,
      "tooltip": "When you kill 3 enemies within a short time of one another.",
      "eventScore": 40,
      "automontage" : {
        "primary": true,
        "secondary": false,
        "offsetBefore": 2,
        "offsetAfter": 2,
        "effectTypes": ["greyDistortionArrow", "veryFastThenSlow", "fastThenSlow", "flashScope", "slowFastSlow", "lensShake", "backToColor"]
      }
    },
    {
      "name": "quadraKill",
      "displayName": "Quadra Kill",
      "icon": "quadra-kill",
      "default": true,
      "tooltip": "When you kill 4 enemies within a short time of one another.",
      "eventScore": 60,
      "automontage" : {
        "primary": true,
        "secondary": false,
        "offsetBefore": 2,
        "offsetAfter": 2,
        "effectTypes": ["greyDistortionArrow", "veryFastThenSlow", "fastThenSlow", "flashScope", "slowFastSlow", "lensShake", "backToColor"]
      }
    },
    {
      "name": "longShot",
      "displayName": "Long Shot",
      "icon": "long-range-kill",
      "default": true,
      "tooltip": "When you kill an enemy from a long distance.",
      "eventScore": 30,
      "automontage" : {
        "primary": true,
        "secondary": false,
        "offsetBefore": 3,
        "offsetAfter": 2,
        "effectTypes": ["greyDistortionArrow", "veryFastThenSlow", "fastThenSlow", "flashScope", "slowFastSlow", "lensShake", "backToColor"]
      }
    },
    {
      "name": "headshot",
      "displayName": "Headshot",
      "icon": "headshot",
      "default": true,
      "tooltip": "When you headshot an opponent.",
      "eventScore": 15,
      "automontage" : {
        "primary": true,
        "secondary": false,
        "offsetBefore": 2,
        "offsetAfter": 2,
        "effectTypes": ["greyDistortionArrow", "veryFastThenSlow", "fastThenSlow", "flashScope", "slowFastSlow", "lensShake", "backToColor"]
      }
    },
    {
      "name": "preciseLongShot",
      "displayName": "Precise Long Shot",
      "icon": "sniper-kill",
      "default": true,
      "tooltip": "When you kill an enemy with a precise shot from a very long distance.",
      "eventScore": 50,
      "automontage" : {
        "primary": true,
        "secondary": false,
        "offsetBefore": 3,
        "offsetAfter": 2,
        "effectTypes": ["greyDistortionArrow", "veryFastThenSlow", "fastThenSlow", "flashScope", "slowFastSlow", "lensShake", "backToColor"]
      }
    }
  ]
}
```
B. game_postprocess.lua
This is the most important file. It tells the OCR engine where to look on the screen and what text to match for each event.

Example game_postprocess.lua for Delta Force (currently doesn't work):
```
local smoothing = require("postprocess.smoothing")
local event = require("postprocess.event")
local utils = require("postprocess.utils")
local paddle_ocr = require("postprocess.paddle_ocr")
local cues_data = require("postprocess.cues_data")

--[[                DF - Delta Force 
    Visual events :
        no visual model

    Ocr events (Paddle) :
        doubleKill, tripleKill, quadraKill, longShot, preciseLongShot,
        headshot, victory, defeat

]]--

-- fps config
local get_fps = function()
    return 4
end

-- visual cues
local visualCuesConfig = {}

-- ocr cues
local ocrConfig = {
    crops = {
        {
            -- Catches all in-game accolades at the bottom-center of the screen
            cropName = "ScoreMessage",
            debug = false,
            -- Coordinates confirmed for 2560x1440.
            cropCoords = { 0.420, 0.730, 0.580, 0.820 }, 
            detectorDilateDiameter = 3,
            detectorMinimumArea = 10,
            detectorMargin = 5,
            recogniserStretchVertical = false,
            restrictedCharacters = ""
        },
        {
            -- Catches the final 'DEFEAT' or 'VICTORY' message
            cropName = "GameResult",
            debug = false,
            -- Coordinates confirmed for 2560x1440.
            cropCoords = { 0.250, 0.450, 0.750, 0.550 },
            detectorDilateDiameter = 5,
            detectorMinimumArea = 1000,
            detectorMargin = 30,
            recogniserStretchVertical = false,
            restrictedCharacters = ""
        }
    }
}

local setEventsSpecs = function (cues)
    -- Events functions ------------------
    local accoladeEvents = {
        { event = 'preciseLongShot',   match = { 'Precise Long Shot' }, score = 85 },
        { event = 'longShot',          match = { 'Long Shot' },         score = 85 },
        { event = 'quadraKill',        match = { 'QUADRA KILL' },       score = 85 },
        { event = 'tripleKill',        match = { 'TRIPLE KILL' },       score = 85 },
        { event = 'doubleKill',        match = { 'DOUBLE KILL' },       score = 85 },
        { event = 'headshot',          match = { 'Headshot' },          score = 85 }
    }
    local function detectAccoladeEvents(frameIndex)
        for _, config in ipairs(accoladeEvents) do
            if paddle_ocr.checkFuture(frameIndex, 2, 'ScoreMessage', config.match, config.score) then
                return config.event, frameIndex - 2
            end
        end
    end

    local endGameDetectors = {
        { event = 'victory', match = { 'VICTORY' }, score = 70 },
        { event = 'defeat',  match = { 'DEFEAT' },  score = 70 }
    }
    local function detectEndGame (frameIndex)
        for _, config in ipairs(endGameDetectors) do
            if paddle_ocr.checkFuture(frameIndex, 2, 'GameResult', config.match, config.score) then
                return config.event
            end
        end
    end
  
    --------------------------------------

    local functionsList = {
        detectAccoladeEvents, detectEndGame
    }

    local eventsSpecs = {
        doubleKill =          { name = "doubleKill",          slack = 16 },
        tripleKill =          { name = "tripleKill",          slack = 16 },
        quadraKill =          { name = "quadraKill",          slack = 16 },
        longShot =            { name = "longShot",            slack = 12 },
        preciseLongShot =     { name = "preciseLongShot",     slack = 12 },
        headshot =            { name = "headshot",            slack = 12 },
        victory =             { name = "victory",             slack = 30 },
        defeat =              { name = "defeat",              slack = 30 }
    }

    return eventsSpecs, functionsList
end

-- DO NOT EDIT BELOW THIS LINE -----------------------------------------------------------
local get_paddle_ocr_config = function()
    return ocrConfig
end

-- compute events for both ocr and visual
local computeEvents = function(modelOutputs, ocrOutput, frameTimes, paddleOcrOutput)
    local cues = {}

    if next(modelOutputs) ~= nil then
        local visualCues = smoothing.run(visualCuesConfig, modelOutputs, frameTimes)
        for cueName, cueValues in pairs(visualCues) do
            cues[cueName] = cueValues
        end
    else
        cues['frameTimes'] = frameTimes
    end

    if next(ocrOutput) ~= nil then
        for cueName, cueValues in pairs(ocrOutput) do
            cues[cueName] = cueValues
        end
    end

    if next(paddleOcrOutput) ~= nil then
        for cueName, cueValues in pairs(paddleOcrOutput) do
            cues[cueName] = cueValues
            cueValues.confidences = {}
            for i, value in ipairs(cueValues.results) do
                if value == nil or value:match("^%s*$") then
                    cueValues.confidences[i] = 0
                else
                    cueValues.confidences[i] = 0.5
                end
            end
        end
    end

    local result = utils.TCTformatCuesData(cues)
    local eventsSpecs, functionsList = setEventsSpecs(cues)
    cues_data.cues = cues
    local eventsTable = event.computeEvents(cues, eventsSpecs, functionsList)
    result.events = eventsTable

    return result
end

return {
    computeEvents = computeEvents,
    get_paddle_ocr_config = get_paddle_ocr_config,
    get_fps = get_fps,
}



```

Critically, you must adjust the cropCoords and match strings based on your own gameplay footage.


**Part 3: Modifying the Powder Application**

This is where we tell the app that your new game exists.

1. Unpack app.asar

Open PowerShell or Command Prompt as an Administrator.

If you haven't already, install the asar tool by running: npm install -g asar

Navigate to the resources folder: cd "C:\Users\[YourUsername]\AppData\Local\Programs\powder-desktop\resources"

Back up your app.asar file! Copy it and rename the copy to app.asar.bak.

Extract the archive by running:``` asar extract app.asar app-unpacked```

2. Add Your Game to the Master List

Open the app-unpacked folder in VS Code.

Use the search function (Ctrl+Shift+F) to search the entire folder for the name of a known game, like "Among Us".

This will lead you to a file (resources\app-unpacked\dist\main\main.js) containing a large list of all supported games.

Copy an existing game's entry and modify it for your game. Add it to the list, ensuring you place a comma , after the previous entry.

Example Entry to Add:

```{"name":"Delta Force","steamId":"2507950","powderGameId":"DF","libraries":["STEAM"],"twitchId":"14336","urlSlug":"delta-force","description":"Delta Force marks the return of the classic first-person shooter, offering large-scale multiplayer combat across land, sea, and air. Engage in tactical, objective-based warfare with realistic weaponry and operator skills in a modern military setting.","productionDatabasePowderGameId":"","developmentDatabasePowderGameId":"","website": "https://www.playdeltaforce.com","free2play": true},```



3. Add Your Game to the AI Whitelist

Navigate to ai-configs/ and open whitelist.json with a text editor.

Add your game's short ID (e.g., "DF") to the list. Make sure to keep it alphabetical and add a comma after the previous entry.


4. Re-Pack the app.asar Archive

Go back to your PowerShell window (still in the resources directory).

Run the following command to pack your modified files into a new app.asar:

```asar pack app-unpacked app.asar```

This will overwrite the original app.asar file. The app-unpacked folder will not be deleted.


**Part 4: Testing and Troubleshooting**

Launch the Powder app. Your game should now appear in the "Supported Games" list.

If the game doesn't appear: Your edit to the master list inside app.asar likely has a syntax error (usually a missing comma). Restore your backup (app.asar.bak) and try again.

If the game appears but events aren't detected:

Double-check the text in your .lua file's match fields. It must be an exact match to what appears on screen.

Adjust the cropCoords in the .lua file. This is the most common issue. Your screen resolution may be different, causing the OCR to look in the wrong place. Make small, incremental changes and re-test.


**Part 5: Accessing the Developer Console**

reopen app.asar files, head to "powder-desktop\resources\app-unpacked\dist\main\main.js", open it in VS Code once again. 
Search (Ctrl+F) "Browser"
You should find a line that looks like ```n=new o.BrowserWindow({width:1280,height:720,minWidth:1100,minHeight:600,show:!1,frame:!1,titleBarStyle:g?"customButtonsOnHover":"hidden",roundedCorners:!1,backgroundColor:"#1d1d1d",webPreferences:{preload:E,webviewTag:!0,devTools:b}})```
You'll modify this to ```n=new o.BrowserWindow({width:1280,height:720,minWidth:1100,minHeight:600,show:!1,frame:!1,titleBarStyle:g?"customButtonsOnHover":"hidden",roundedCorners:!1,backgroundColor:"#1d1d1d",webPreferences:{preload:E,webviewTag:!0,devTools:true}}), n.webContents.openDevTools()```
Double check you have an app.asar.bak file (backup app.asar)
Now you know you have this bak file, safe main.js and rerun ```asar pack app-unpacked app.asar```
Now launch Powder and you'll be in the Developer Console, to deactivate, just click the cross at the top right of the console.

Once everything is working, you can safely delete the app-unpacked folder.
