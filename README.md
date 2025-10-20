Guide: How to Add Custom Game Support to Powder after discontinuation


This guide provides a step-by-step process for adding new, unsupported games to the discontinued Powder desktop application (v8.0.2 Standalone). Since the app is no longer maintained, this is the only way to enable event detection for newer titles.

The process involves creating configuration files that tell Powder how to identify in-game events and modifying the application's core files to make it recognize your new game.

Disclaimer: This process involves editing application files. While the Powder app is offline and the risk is low, always back up any files before you modify them.

Prerequisites

Before you begin, you will need:

Powder Standalone App: The Powder_v8.0.2_standalone.exe file, installed on your system.

A Code Editor: VS Code is highly recommended as it can search the contents of files within an entire folder. A basic text editor like Notepad will also work.

Node.js: This is required to install the asar tool. Download it from the official Node.js website.

ASAR Tool: A command-line utility for packing and unpacking .asar archives.

Game Assets: You will need three images for your game:

A poster image (e.g., poster.webp)

A banner image (e.g., background.webp)

An icon (e.g., icon-logo.svg or .png)

Gameplay Footage: A video of you playing the game, showing what the on-screen notifications look like for kills, headshots, multi-kills, etc. This is essential for configuring the detection script.

Part 1: Understanding the File Structure

The Powder app's files are primarily located in C:\Users\[YourUsername]\AppData\Local\Programs\powder-desktop\. Inside, you will find a resources folder, which is our main target.

resources/app.asar: This is a compressed archive containing the application's user interface and core logic. We will need to unpack this to add our game to the UI.

resources/app-unpacked/ (You will create this): This will be our temporary workspace for the unpacked application files.

assets/supported-games/: Contains the UI image assets for each game.

ai-configs/visual_cues/: Contains the logic files (.json, .lua) for event detection.

ai-configs/whitelist.json: A simple list of game IDs that the AI engine is allowed to monitor.

Part 2: Creating Your Custom Game Files

We will use "Delta Force" (ID: DF) as our example.

1. Create the Asset Folders and Files

Navigate to the assets/supported-games/ folder and create a new folder with your game's short ID (e.g., DF). Inside that folder, create the following structure and place your images inside:

code
Code
download
content_copy
expand_less
DF/
├── banner/
│   └── background.webp
├── cover/
│   └── poster.webp
└── icon-light-bg-color/
    └── icon-logo.svg  (or .png)
2. Create the Logic Folders and Files

Navigate to the ai-configs/visual_cues/ folder and create another folder with your game's ID (e.g., DF). Inside this folder, you will create two files: events.json and game_postprocess.lua.

A. events.json
This file defines the events Powder should recognize.

Example events.json for Delta Force:

code
JSON
download
content_copy
expand_less
{
  "name": "DeltaForce",
  "events": [
    { "name": "kill", "displayName": "Kill", "icon": "fps-kill", ... },
    { "name": "headshot", "displayName": "Headshot", "icon": "headshot", ... },
    { "name": "doubleKill", "displayName": "Double Kill", "icon": "double-kill", ... },
    { "name": "gadgetDestroyed", "displayName": "Gadget Destroyed", "icon": "gadget-destroyed", ... },
    { "name": "victory", "displayName": "Victory", "icon": "overall-victory", ... },
    { "name": "defeat", "displayName": "Defeat", "icon": "overall-lose", ... }
    // ... add all other events you want to track
  ]
}

B. game_postprocess.lua
This is the most important file. It tells the OCR engine where to look on the screen and what text to match for each event.

Example game_postprocess.lua for Delta Force:

code
Lua
download
content_copy
expand_less
-- Delta Force
local paddle_ocr = require("postprocess.paddle_ocr")

-- Define where on the screen to look for text.
-- These are percentages: {top, right, bottom, left}
local ocrConfig = {
    crops = {
        {
            cropName = "KillMessage",
            debug = false,
            cropCoords = { 0.45, 0.55, 0.55, 0.65 }
        },
        {
            cropName = "StreakMessage",
            debug = false,
            cropCoords = { 0.45, 0.60, 0.55, 0.70 }
        }
    }
}

-- Define the text strings to match for each event.
local setEventsSpecs = function (cues)
    local killDetectors = {
        { event = 'kill',              match = { 'KILL' },               score = 90 },
        { event = 'headshot',          match = { 'HEADSHOT', 'HS' },     score = 80 },
        { event = 'gadgetDestroyed',   match = { 'GADGET DESTROYED' },   score = 70 }
    }
    local streakDetectors = {
        { event = 'doubleKill',        match = { 'DOUBLE KILL' },        score = 80 },
        { event = 'tripleKill',        match = { 'TRIPLE KILL' },        score = 80 }
    }
    -- ... (rest of the detection logic)
end

-- ... (the rest of the boilerplate Lua code)

Critically, you must adjust the cropCoords and match strings based on your own gameplay footage.

Part 3: Modifying the Powder Application

This is where we tell the app that your new game exists.

1. Unpack app.asar

Open PowerShell or Command Prompt as an Administrator.

If you haven't already, install the asar tool by running: npm install -g asar

Navigate to the resources folder: cd "C:\Users\[YourUsername]\AppData\Local\Programs\powder-desktop\resources"

Back up your app.asar file! Copy it and rename the copy to app.asar.bak.

Extract the archive by running: asar extract app.asar app-unpacked

2. Add Your Game to the Master List

Open the app-unpacked folder in VS Code.

Use the search function (Ctrl+Shift+F) to search the entire folder for the name of a known game, like "Among Us".

This will lead you to a file (likely a .js file) containing a large list of all supported games.

Copy an existing game's entry and modify it for your game. Add it to the list, ensuring you place a comma , after the previous entry.

Example Entry to Add:

code
JSON
download
content_copy
expand_less
{
    "name": "Delta Force",
    "steamId": "2507950",
    "powderGameId": "DF",
    "libraries": ["STEAM"],
    "twitchId": "14336",
    "urlSlug": "delta-force",
    "description": "Delta Force marks the return of the classic first-person shooter...",
    "productionDatabasePowderGameId": "",
    "developmentDatabasePowderGameId": "",
    "website": "https://www.playdeltaforce.com",
    "free2play": true
},
3. Add Your Game to the AI Whitelist

Navigate to ai-configs/ and open whitelist.json with a text editor.

Add your game's short ID (e.g., "DF") to the list. Make sure to keep it alphabetical and add a comma after the previous entry.

4. Re-Pack the app.asar Archive

Go back to your PowerShell window (still in the resources directory).

Run the following command to pack your modified files into a new app.asar:

code
Code
download
content_copy
expand_less
asar pack app-unpacked app.asar

This will overwrite the original app.asar file. The app-unpacked folder will not be deleted.

Part 4: Testing and Troubleshooting

Launch the Powder app. Your game should now appear in the "Supported Games" list.

If the game doesn't appear: Your edit to the master list inside app.asar likely has a syntax error (usually a missing comma). Restore your backup (app.asar.bak) and try again.

If the game appears but events aren't detected:

Double-check the text in your .lua file's match fields. It must be an exact match to what appears on screen.

Adjust the cropCoords in the .lua file. This is the most common issue. Your screen resolution may be different, causing the OCR to look in the wrong place. Make small, incremental changes and re-test.

Once everything is working, you can safely delete the app-unpacked folder.
