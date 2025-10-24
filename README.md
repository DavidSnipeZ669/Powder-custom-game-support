**Guide: How to Add Custom Game Support to Powder after discontinuation**




This guide provides a step-by-step process for adding new, unsupported games to the discontinued Powder desktop application (v8.0.2 Standalone). Since the app is no longer maintained, this is the only way to enable event detection for newer titles.

The process involves creating configuration files that tell Powder how to identify in-game events and modifying the application's core files to make it recognize your new game.

Disclaimer: This process involves editing application files. While the Powder app is offline and the risk is low, always back up any files before you modify them.

Prerequisites

Before you begin, you will need:

Powder Standalone App: The Powder_v8.0.2_standalone.exe file, installed on your system. (found at either ```https://docs.google.com/document/d/1p8TjN7bCRdOnhrD5DjG02pmoGi4ylsGKmdCS-YV4jrg/edit?tab=t.0```, ```https://wheybags.com/assets/Powder_v8.0_final.exe``` or releases)

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
      "automontage": {
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
      "automontage": {
        "primary": false,
        "secondary": false,
        "offsetBefore": 0,
        "offsetAfter": 0,
        "effectTypes": []
      }
    },
    {
      "name": "kill",
      "displayName": "Kill",
      "icon": "fps-kill",
      "default": true,
      "tooltip": "When you kill an opponent.",
      "eventScore": 10,
      "automontage": {
        "primary": true,
        "secondary": false,
        "offsetBefore": 2,
        "offsetAfter": 2,
        "effectTypes": [
          "greyDistortionArrow",
          "veryFastThenSlow",
          "fastThenSlow",
          "flashScope",
          "slowFastSlow",
          "lensShake",
          "backToColor"
        ]
      }
    },
    {
      "name": "headshot",
      "displayName": "Headshot",
      "icon": "headshot",
      "default": true,
      "tooltip": "When you headshot an opponent.",
      "eventScore": 15,
      "automontage": {
        "primary": true,
        "secondary": false,
        "offsetBefore": 2,
        "offsetAfter": 2,
        "effectTypes": [
          "greyDistortionArrow",
          "veryFastThenSlow",
          "fastThenSlow",
          "flashScope",
          "slowFastSlow",
          "lensShake",
          "backToColor"
        ]
      }
    },
    {
      "name": "doubleKill",
      "displayName": "Double Kill",
      "icon": "double-kill",
      "default": true,
      "tooltip": "When you kill 2 enemies within a short time of one another.",
      "eventScore": 25,
      "automontage": {
        "primary": true,
        "secondary": false,
        "offsetBefore": 2,
        "offsetAfter": 2,
        "effectTypes": [
          "greyDistortionArrow",
          "veryFastThenSlow",
          "fastThenSlow",
          "flashScope",
          "slowFastSlow",
          "lensShake",
          "backToColor"
        ]
      }
    },
    {
      "name": "tripleKill",
      "displayName": "Triple Kill",
      "icon": "triple-kill",
      "default": true,
      "tooltip": "When you kill 3 enemies within a short time of one another.",
      "eventScore": 40,
      "automontage": {
        "primary": true,
        "secondary": false,
        "offsetBefore": 2,
        "offsetAfter": 2,
        "effectTypes": [
          "greyDistortionArrow",
          "veryFastThenSlow",
          "fastThenSlow",
          "flashScope",
          "slowFastSlow",
          "lensShake",
          "backToColor"
        ]
      }
    },
    {
      "name": "quadraKill",
      "displayName": "Quadra Kill",
      "icon": "quadra-kill",
      "default": true,
      "tooltip": "When you kill 4 enemies within a short time of one another.",
      "eventScore": 60,
      "automontage": {
        "primary": true,
        "secondary": false,
        "offsetBefore": 2,
        "offsetAfter": 2,
        "effectTypes": [
          "greyDistortionArrow",
          "veryFastThenSlow",
          "fastThenSlow",
          "flashScope",
          "slowFastSlow",
          "lensShake",
          "backToColor"
        ]
      }
    },
    {
      "name": "reaperMode",
      "displayName": "Reaper Mode",
      "icon": "streak",
      "default": true,
      "tooltip": "When you kill 5 enemies or more within a short time of one another.",
      "eventScore": 80,
      "automontage": {
        "primary": true,
        "secondary": false,
        "offsetBefore": 2,
        "offsetAfter": 2,
        "effectTypes": [
          "greyDistortionArrow",
          "veryFastThenSlow",
          "fastThenSlow",
          "flashScope",
          "slowFastSlow",
          "lensShake",
          "backToColor"
        ]
      }
    },
    {
      "name": "vehiculeDestroyed",
      "displayName": "Vehicule Destroyed",
      "icon": "vehicule-destroyed",
      "default": true,
      "tooltip": "When you destroyed an enemy vehicule.",
      "eventScore": 15,
      "automontage": {
        "primary": true,
        "secondary": false,
        "offsetBefore": 2,
        "offsetAfter": 2,
        "effectTypes": [
          "greyDistortionArrow",
          "veryFastThenSlow",
          "fastThenSlow",
          "flashScope",
          "slowFastSlow",
          "lensShake",
          "backToColor"
        ]
      }
    },
    {
      "name": "squadWipe",
      "displayName": "Squad Wipe",
      "icon": "kingslayer",
      "default": true,
      "tooltip": "When you kill an entire enemy squad.",
      "eventScore": 25,
      "automontage": {
        "primary": true,
        "secondary": false,
        "offsetBefore": 2,
        "offsetAfter": 2,
        "effectTypes": [
          "greyDistortionArrow",
          "veryFastThenSlow",
          "fastThenSlow",
          "flashScope",
          "slowFastSlow",
          "lensShake",
          "backToColor"
        ]
      }
    },
    {
      "name": "knifeKill",
      "displayName": "Knife Kill",
      "icon": "revenge-kill",
      "default": true,
      "tooltip": "When you kill an enemy hand to hand.",
      "eventScore": 50,
      "automontage": {
        "primary": true,
        "secondary": false,
        "offsetBefore": 2,
        "offsetAfter": 2,
        "effectTypes": [
          "greyDistortionArrow",
          "veryFastThenSlow",
          "fastThenSlow",
          "flashScope",
          "slowFastSlow",
          "lensShake",
          "backToColor"
        ]
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

--[[                DF   -- Delta Force Visual and OCR Cues Configuration File
    -----------------------------------------------------------------------------
    22/10/2025 
    Author : DavidGaming669 
    Version : 1.08
    -----------------------------------------------------------------------------
    Visual events :
        no visual model
    -----------------------------------------------------------------------------
    OCR events :
        Paddle OCR is used to detect in-game text events.
    -----------------------------------------------------------------------------
    Game Information :
        Game : Delta Force (2024)
    
    Monitor Size : 2560x1440
    Game Resolution : 2560x1440

    Template game_postprocess.lua modified for DF from BF6 version.
    
]]-- FPS Configuration 
local get_fps = function()
    return 5  -- Changed to more standard FPS
end

-- visual cues
local visualCuesConfig = {}

-- ocr cues
local ocrConfig = {
    crops = {
        {
            cropName = "KillMessage",
            debug = false,
            cropCoords = { 0.400, 0.660, 0.600, 0.825 }, -- Centered kill feed area
            detectorDilateDiameter = 3,
            detectorMinimumArea = 5,
            detectorMargin = 5,
            recogniserStretchVertical = false,
            restrictedCharacters = ""
        },
        {
            cropName = "StreakMessage",
            debug = false,
            cropCoords = { 0.325, 0.125, 0.675, 0.225 }, -- Multi-kill/streek notification area
            detectorDilateDiameter = 3,
            detectorMinimumArea = 5,
            detectorMargin = 5,
            recogniserStretchVertical = false,
            restrictedCharacters = ""
        },
        {
            cropName = "GameResult",
            debug = false,
            cropCoords = { 0.400, 0.225, 0.600, 0.375 }, -- Victory/Defeat screen
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
    local killDetectors = {
        { event = 'kill',              match = { 'KILL', 'ELIMINATED' },                       score = 85 },
        { event = 'headshot',          match = { 'HEADSHOT', 'HS' },                           score = 80 },
        { event = 'gadgetDestroyed',   match = { 'GADGET DESTROYED', 'DEVICE DESTROYED' },     score = 75 }
    }
    
    local streakDetectors = {
        { event = 'meleeKill',         match = { 'MELEE KILL', 'TAKEDOWN', 'KNIFE KILL' },     score = 80 },
        { event = 'doubleKill',        match = { 'DOUBLE KILL' },                              score = 80 },
        { event = 'tripleKill',        match = { 'TRIPLE KILL' },                              score = 80 },
        { event = 'quadraKill',        match = { 'QUADRA KILL', 'QUADRUPLE KILL' },            score = 80 },
        { event = 'reaperMode',        match = { 'REAPER MODE', 'MULTI KILL', 'KILLING SPREE', 'ULTRA KILL' }, score = 80 } 
    }
    
    local function detectKill(frameIndex)
        local detectedEvent = nil

        -- First check for basic kill events
        for _, config in ipairs(killDetectors) do
            if paddle_ocr.checkFuture(frameIndex, 2, 'KillMessage', config.match, config.score) then
                detectedEvent = config.event
                break
            end
        end

        -- If we found a kill, check for streak events in nearby frames
        if detectedEvent ~= nil then 
            for i = -2, 6 do  -- Check frames before and after
                for _, config in ipairs(streakDetectors) do
                    if paddle_ocr.checkValues(cues_data.cues['StreakMessage'].results[frameIndex + i], config.match, config.score) then
                        detectedEvent = config.event
                        break
                    end
                end
            end
        end

        return detectedEvent, frameIndex - 2
    end

    local squadWipeDetectors = { 'SQUAD WIPE', 'ENEMY SQUAD ELIMINATED', 'TEAM WIPE', 'SQUAD ELIMINATED' }
    local function detectSquadWipe(frameIndex)
        if paddle_ocr.checkFuture(frameIndex, 2, 'StreakMessage', squadWipeDetectors, 80) then
            return 'squadWipe', frameIndex
        end
    end

    local endGameDetectors = {
        { event = 'victory', match = { 'VICTORY', 'MISSION SUCCESS', 'SUCCESS' }, score = 75 },
        { event = 'defeat',  match = { 'DEFEAT', 'MISSION FAILED', 'FAILED' },    score = 75 }
    }
    local function detectEndGame(frameIndex)
        for _, config in ipairs(endGameDetectors) do
            if paddle_ocr.checkFuture(frameIndex, 2, 'GameResult', config.match, config.score) then
                return config.event, frameIndex
            end
        end
    end
  
    --------------------------------------

    local functionsList = {
        detectKill, 
        detectSquadWipe,
        detectEndGame
    }

    local eventsSpecs = {
        kill =              { name = "kill",              slack = 8  },
        headshot =          { name = "headshot",          slack = 8  },
        doubleKill =        { name = "doubleKill",        slack = 12 },
        tripleKill =        { name = "tripleKill",        slack = 12 },
        quadraKill =        { name = "quadraKill",        slack = 12 },
        reaperMode =        { name = "reaperMode",        slack = 12 },
        victory =           { name = "victory",           slack = 30 },
        defeat =            { name = "defeat",            slack = 30 },
        gadgetDestroyed =   { name = "gadgetDestroyed",   slack = 8  },
        squadWipe =         { name = "squadWipe",         slack = 10 },
        meleeKill =         { name = "meleeKill",         slack = 8  }
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
                    cueValues.confidences[i] = 0.7  -- Increased confidence for better detection
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
Now you know you have this bak file, save main.js and rerun ```asar pack app-unpacked app.asar```
Now launch Powder and you'll be in the Developer Console, to close it for just that session, just click the cross at the top right of the console, to deactivate permanently, rename the current app.asar to something else (or delete it) and rename the backup app.asar.bak to app.asar.

Once everything is working, you can safely delete the app-unpacked folder.


**Part 6: Accessing the Backend (Main Process) Console for Advanced Debugging**

The standard developer console (from Part 5) is great for UI issues. However, the actual video analysis and Lua script execution happens in a hidden background process (the "Main Process"). To see the real errors when your event detection fails, you need to connect to this backend console.

Create a Backend Debug Shortcut:

Right click on your desktop or in a folder, go down to "new" -> Shortcut and paste the following

```C:\Users\[YourUsername]\AppData\Local\Programs\powder-desktop\Powder.exe --inspect-brk=5858```

You can name this shortcut anything you want that will allow you to remember what it does, I recommend "Powder (Backend Debug)".

*Connect the DevTools*

The order of these steps is important.

First, make sure Powder is completely closed. (Open task manager and end process)

Open your Chromium-based browser (Chrome, Opera GX, Edge, firefox, etc) and navigate to chrome://inspect.

You should now be on a page with a URL that looks like "opera://inspect/#devices"

Now click the "Open dedicated DevTools for Node" link which will open a DevTools window.

Click the "Connection" tab and add the address "localhost:5858"

Open your Backend Debug shortcut and move over to the DevTools window, you should be moved to Sources where you will see the main.js file has opened.

The Powder Backend will be paused on the first line of code, indicated by a "Debugger paused" banner.

Click the Resume script execution button (a blue "play" icon ►) in the top-right of the DevTools panel to allow the app to finish loading.

The main Powder application window will now launch. The DevTools window you opened is now connected to the backend.

Move to the Console tab and switch to Powder.

Do what you did to get the error, and you will see the detailed error messages from your Lua/JSON files (assuming it's game support that is failing) in the DevTools window.

**Part 7: Adding event whitelists**

Sometimes games don't work on their own since their events aren't whitelisted, such as Delta Force.

My current workaround for this is to add the actual events to a whitelist and assuming your script works, analysis should give you events and clip them (they will be available in auto montage too).

To do this, you want to reopen main.js (make a backup and place it somewhere memorable), make sure you have added the game as guided in **part 3**.

Go to line 578 or search (Ctrl+F) "AMNGU" and go to the final one, in that line, you want to add your event code in the following format before another games eventlist (I added Delta Force after AMNGU and before APXL):

```"DF":{"name":"DF","events":[{"name":"victory","displayName":"Victory","icon":"overall-victory","default":true,"tooltip":"When you win a game.","eventScore":30,"automontage":{"primary":false,"secondary":true,"offsetBefore":3,"offsetAfter":3,"effectTypes":[]}},{"name":"defeat","displayName":"Defeat","icon":"overall-lose","default":false,"tooltip":"When you lose a game.","eventScore":5,"automontage":{"primary":false,"secondary":false,"offsetBefore":0,"offsetAfter":0,"effectTypes":[]}},{"name":"kill","displayName":"Kill","icon":"fps-kill","default":true,"tooltip":"When you kill an opponent.","eventScore":10,"automontage":{"primary":true,"secondary":false,"offsetBefore":1,"offsetAfter":2,"effectTypes":["greyDistortionArrow","veryFastThenSlow","fastThenSlow","flashScope","slowFastSlow","lensShake","backToColor"]}},{"name":"headshot","displayName":"Headshot","icon":"headshot","default":true,"tooltip":"When you headshot an opponent.","eventScore":15,"automontage":{"primary":true,"secondary":false,"offsetBefore":1,"offsetAfter":2,"effectTypes":["greyDistortionArrow","veryFastThenSlow","fastThenSlow","flashScope","slowFastSlow","lensShake","backToColor"]}},{"name":"doubleKill","displayName":"Double Kill","icon":"double-kill","default":true,"tooltip":"When you kill 2 enemies within a short time of one another.","eventScore":25,"automontage":{"primary":true,"secondary":false,"offsetBefore":2,"offsetAfter":2,"effectTypes":["greyDistortionArrow","veryFastThenSlow","fastThenSlow","flashScope","slowFastSlow","lensShake","backToColor"]}},{"name":"tripleKill","displayName":"Triple Kill","icon":"triple-kill","default":true,"tooltip":"When you kill 3 enemies within a short time of one another.","eventScore":40,"automontage":{"primary":true,"secondary":false,"offsetBefore":2,"offsetAfter":2,"effectTypes":["greyDistortionArrow","veryFastThenSlow","fastThenSlow","flashScope","slowFastSlow","lensShake","backToColor"]}},{"name":"quadraKill","displayName":"Quadra Kill","icon":"quadra-kill","default":true,"tooltip":"When you kill 4 enemies within a short time of one another.","eventScore":60,"automontage":{"primary":true,"secondary":false,"offsetBefore":2,"offsetAfter":2,"effectTypes":["greyDistortionArrow","veryFastThenSlow","fastThenSlow","flashScope","slowFastSlow","lensShake","backToColor"]}},{"name":"reaperMode","displayName":"Multi Kill","icon":"streak","default":true,"tooltip":"When you kill 5 enemies or more within a short time of one another.","eventScore":80,"automontage":{"primary":true,"secondary":false,"offsetBefore":2,"offsetAfter":2,"effectTypes":["greyDistortionArrow","veryFastThenSlow","fastThenSlow","flashScope","slowFastSlow","lensShake","backToColor"]}},{"name":"gadgetDestroyed","displayName":"Gadget Destroyed","icon":"gadget-destroyed","default":true,"tooltip":"When you destroy an enemy gadget.","eventScore":15,"automontage":{"primary":true,"secondary":false,"offsetBefore":2,"offsetAfter":2,"effectTypes":["greyDistortionArrow","veryFastThenSlow","fastThenSlow","flashScope","slowFastSlow","lensShake","backToColor"]}},{"name":"squadWipe","displayName":"Squad Wipe","icon":"kingslayer","default":true,"tooltip":"When you kill an entire enemy squad.","eventScore":25,"automontage":{"primary":true,"secondary":false,"offsetBefore":2,"offsetAfter":2,"effectTypes":["greyDistortionArrow","veryFastThenSlow","fastThenSlow","flashScope","slowFastSlow","lensShake","backToColor"]}},{"name":"meleeKill","displayName":"Melee Kill","icon":"revenge-kill","default":true,"tooltip":"When you kill an enemy with a melee weapon.","eventScore":50,"automontage":{"primary":true,"secondary":false,"offsetBefore":1,"offsetAfter":2,"effectTypes":["greyDistortionArrow","veryFastThenSlow","fastThenSlow","flashScope","slowFastSlow","lensShake","backToColor"]}}],"powderGameId":"DF","isEventsConfigurationSupported":true},```


This is the code I used for Delta Force, however, it can me modified and customised to your liking. The following is the blank version with no event scores, game names, events, icons or display names.:


```"GAME_NAME":{"name":"GAME_NAME","events":[{"name":"EVENT_NAME_1","displayName":"Display Name 1","icon":"icon-name-1","default":true,"tooltip":"Tooltip description for the event.","eventScore":0,"automontage":{"primary":false,"secondary":true,"offsetBefore":3,"offsetAfter":3,"effectTypes":[]}},{"name":"EVENT_NAME_2","displayName":"Display Name 2","icon":"icon-name-2","default":false,"tooltip":"Tooltip description for the event.","eventScore":0,"automontage":{"primary":false,"secondary":false,"offsetBefore":0,"offsetAfter":0,"effectTypes":[]}},{"name":"EVENT_NAME_3","displayName":"Display Name 3","icon":"icon-name-3","default":true,"tooltip":"Tooltip description for the event.","eventScore":0,"automontage":{"primary":true,"secondary":false,"offsetBefore":1,"offsetAfter":2,"effectTypes":["effectName1","effectName2","effectName3","effectName4","effectName5","effectName6","effectName7"]}},{"name":"EVENT_NAME_4","displayName":"Display Name 4","icon":"icon-name-4","default":true,"tooltip":"Tooltip description for the event.","eventScore":0,"automontage":{"primary":true,"secondary":false,"offsetBefore":1,"offsetAfter":2,"effectTypes":["effectName1","effectName2","effectName3","effectName4","effectName5","effectName6","effectName7"]}},{"name":"EVENT_NAME_5","displayName":"Display Name 5","icon":"icon-name-5","default":true,"tooltip":"Tooltip description for the event.","eventScore":0,"automontage":{"primary":true,"secondary":false,"offsetBefore":2,"offsetAfter":2,"effectTypes":["effectName1","effectName2","effectName3","effectName4","effectName5","effectName6","effectName7"]}},{"name":"EVENT_NAME_6","displayName":"Display Name 6","icon":"icon-name-6","default":true,"tooltip":"Tooltip description for the event.","eventScore":0,"automontage":{"primary":true,"secondary":false,"offsetBefore":2,"offsetAfter":2,"effectTypes":["effectName1","effectName2","effectName3","effectName4","effectName5","effectName6","effectName7"]}},{"name":"EVENT_NAME_7","displayName":"Display Name 7","icon":"icon-name-7","default":true,"tooltip":"Tooltip description for the event.","eventScore":0,"automontage":{"primary":true,"secondary":false,"offsetBefore":2,"offsetAfter":2,"effectTypes":["effectName1","effectName2","effectName3","effectName4","effectName5","effectName6","effectName7"]}},{"name":"EVENT_NAME_8","displayName":"Display Name 8","icon":"icon-name-8","default":true,"tooltip":"Tooltip description for the event.","eventScore":0,"automontage":{"primary":true,"secondary":false,"offsetBefore":2,"offsetAfter":2,"effectTypes":["effectName1","effectName2","effectName3","effectName4","effectName5","effectName6","effectName7"]}},{"name":"EVENT_NAME_9","displayName":"Display Name 9","icon":"icon-name-9","default":true,"tooltip":"Tooltip description for the event.","eventScore":0,"automontage":{"primary":true,"secondary":false,"offsetBefore":2,"offsetAfter":2,"effectTypes":["effectName1","effectName2","effectName3","effectName4","effectName5","effectName6","effectName7"]}},{"name":"EVENT_NAME_10","displayName":"Display Name 10","icon":"icon-name-10","default":true,"tooltip":"Tooltip description for the event.","eventScore":0,"automontage":{"primary":true,"secondary":false,"offsetBefore":2,"offsetAfter":2,"effectTypes":["effectName1","effectName2","effectName3","effectName4","effectName5","effectName6","effectName7"]}},{"name":"EVENT_NAME_11","displayName":"Display Name 11","icon":"icon-name-11","default":true,"tooltip":"Tooltip description for the event.","eventScore":0,"automontage":{"primary":true,"secondary":false,"offsetBefore":1,"offsetAfter":2,"effectTypes":["effectName1","effectName2","effectName3","effectName4","effectName5","effectName6","effectName7"]}}],"powderGameId":"GAME_ID","isEventsConfigurationSupported":true}```

For clarity, this event list is the same as your event file in your visual_cues folder for your specific game you wish to add support for.

I will assume you have reached this github via the Powder discord and if you have successfully added support for games currently unsupported, ping me in the discord @absolutegamer2337 and send me the name of the game the support is for, event whitelist code (if needed), the events.json, game_postprocessing.lua and the image files from supported games and I will add them to a folder with the game name to this repository.
