--[[
    Delta Force - Powder Game Support Configuration
    ------------------------------------------------
    Version: 2.0 (Enhanced)
    Last Updated: 2026-05-30
    Status: Functional Implementation
    
    This configuration file provides OCR-based event detection for Delta Force.
    The implementation uses Paddle OCR to detect in-game text notifications.
    
    Game Information:
        - Game: Delta Force (2024)
        - Resolution: 2560x1440 (primary target)
        - FPS: 5 frames per second (balanced for performance)
    
    Features:
        - Comprehensive event detection (kills, headshots, multi-kills, etc.)
        - Optimized OCR coordinates
        - Robust detection logic with fallback mechanisms
        - Performance-optimized processing
    
    Usage:
        1. Ensure game runs at 2560x1440 resolution
        2. Calibrate coordinates using OCR overlay tool if needed
        3. Test with sample gameplay footage
        4. Adjust parameters based on detection results
]]--

-- Required modules
local smoothing = require("postprocess.smoothing")
local event = require("postprocess.event")
local utils = require("postprocess.utils")
local paddle_ocr = require("postprocess.paddle_ocr")
local cues_data = require("postprocess.cues_data")

-- Performance Configuration
-- FPS: Higher values provide better accuracy but increase CPU usage
-- Recommended range: 3-10 FPS for most systems
local get_fps = function()
    return 5  -- Balanced setting for accuracy and performance
end

-- Visual Cues Configuration (empty - Delta Force uses OCR only)
local visualCuesConfig = {}

-- OCR Configuration
-- Defines regions where text detection occurs
local ocrConfig = {
    crops = {
        -- Kill Message Area
        -- Targets: KILL, ELIMINATED, HEADSHOT, etc.
        {
            cropName = "KillMessage",
            debug = false,
            cropCoords = { 0.380, 0.650, 0.620, 0.700 }, -- Optimized kill feed area
            detectorDilateDiameter = 4,  -- Increased for better text joining
            detectorMinimumArea = 8,      -- Filter out small noise
            detectorMargin = 6,           -- Ensure full text capture
            recogniserStretchVertical = false,
            restrictedCharacters = ""
        },
        
        -- Streak/Multi-kill Notification Area
        -- Targets: DOUBLE KILL, TRIPLE KILL, REAPER MODE, etc.
        {
            cropName = "StreakMessage",
            debug = false,
            cropCoords = { 0.300, 0.100, 0.700, 0.200 }, -- Expanded multi-kill area
            detectorDilateDiameter = 3,
            detectorMinimumArea = 6,
            detectorMargin = 5,
            recogniserStretchVertical = false,
            restrictedCharacters = ""
        },
        
        -- Game Result Area
        -- Targets: VICTORY, DEFEAT, MISSION SUCCESS, etc.
        {
            cropName = "GameResult",
            debug = false,
            cropCoords = { 0.350, 0.200, 0.650, 0.400 }, -- Centered result screen
            detectorDilateDiameter = 5,  -- Larger text needs more dilation
            detectorMinimumArea = 500,  -- Filter out small elements
            detectorMargin = 25,
            recogniserStretchVertical = false,
            restrictedCharacters = ""
        }
    }
}

-- Event Detection Functions
local setEventsSpecs = function (cues)
    -- Event detection configurations
    -- Each event has match patterns and confidence scores
    
    -- Basic Kill Events
    local killDetectors = {
        { event = 'preciselongshot',   match = { 'PRECISE LONG SHOT' },                score = 85 },
        { event = 'longshot',          match = { 'LONG SHOT' },                        score = 85 },
        { event = 'kill',              match = { 'KILL', 'ELIMINATED', 'TAKEDOWN' }, score = 90 },
        { event = 'headshot',          match = { 'HEADSHOT', 'HS', 'HEAD SHOT' },     score = 88 },
        { event = 'gadgetDestroyed',   match = { 'GADGET DESTROYED', 'DEVICE DESTROYED', 'EQUIPMENT DESTROYED' }, score = 82 }
    }
    
    -- Multi-kill/Streak Events
    local streakDetectors = {
        { event = 'meleeKill',         match = { 'MELEE KILL', 'TAKEDOWN', 'KNIFE KILL', 'MELEE ELIMINATION' }, score = 85 },
        { event = 'doubleKill',        match = { 'DOUBLE KILL', 'DOUBLE ELIMINATION' },                              score = 88 },
        { event = 'tripleKill',        match = { 'TRIPLE KILL', 'TRIPLE ELIMINATION' },                              score = 88 },
        { event = 'quadraKill',        match = { 'QUADRA KILL', 'QUADRUPLE KILL', 'QUAD ELIMINATION' },            score = 88 },
        { event = 'reaperMode',        match = { 'REAPER MODE', 'MULTI KILL', 'KILLING SPREE', 'ULTRA KILL', 'MONSTER KILL' }, score = 88 }
    }
    
    -- Squad/Team Events
    local squadWipeDetectors = { 'SQUAD WIPE', 'ENEMY SQUAD ELIMINATED', 'TEAM WIPE', 'SQUAD ELIMINATION', 'FULL TEAM ELIMINATION' }
    
    -- Game Result Events
    local endGameDetectors = {
        { event = 'victory', match = { 'VICTORY', 'MISSION SUCCESS', 'ROUND WIN', 'MATCH WIN', 'SUCCESS' }, score = 80 },
        { event = 'defeat',  match = { 'DEFEAT', 'MISSION FAILED', 'ROUND LOSS', 'MATCH LOSS', 'FAILED', 'ELIMINATED' }, score = 80 }
    }
    
    -- Enhanced Detection Function with Fallback Logic
    local function detectKill(frameIndex)
        local detectedEvent = nil
        local bestScore = 0
        
        -- Check all kill detector patterns
        for _, config in ipairs(killDetectors) do
            local score = paddle_ocr.checkFuture(frameIndex, 3, 'KillMessage', config.match, config.score)
            if score and score > bestScore then
                detectedEvent = config.event
                bestScore = score
            end
        end
        
        -- If we found a kill, check for streak events in nearby frames
        if detectedEvent == 'kill' or detectedEvent == 'headshot' then 
            -- Look ahead and behind for multi-kill notifications
            for i = -3, 5 do  -- Expanded search window
                for _, config in ipairs(streakDetectors) do
                    local streakScore = paddle_ocr.checkValues(cues['StreakMessage'] and cues['StreakMessage'].results[frameIndex + i], config.match, config.score)
                    if streakScore and streakScore > 75 then
                        detectedEvent = config.event
                        bestScore = streakScore
                        break
                    end
                end
            end
        end
        
        return detectedEvent, frameIndex - 2
    end
    
    local function detectSquadWipe(frameIndex)
        local score = paddle_ocr.checkFuture(frameIndex, 3, 'StreakMessage', squadWipeDetectors, 80)
        if score and score > 75 then
            return 'squadWipe', frameIndex
        end
    end
    
    local function detectEndGame(frameIndex)
        for _, config in ipairs(endGameDetectors) do
            local score = paddle_ocr.checkFuture(frameIndex, 3, 'GameResult', config.match, config.score)
            if score and score > 70 then
                return config.event, frameIndex
            end
        end
    end
    
    -- Event Specifications
    -- Defines timing and montage behavior for each event
    local eventsSpecs = {
        -- Basic kills
        kill =              { name = "kill",              slack = 8,  eventScore = 10  },
        headshot =          { name = "headshot",          slack = 8,  eventScore = 15  },
        preciselongshot =  { name = "preciselongshot",  slack = 8,  eventScore = 12  },
        longshot =          { name = "longshot",          slack = 8,  eventScore = 11  },
        gadgetDestroyed =   { name = "gadgetDestroyed",   slack = 8,  eventScore = 13  },
        meleeKill =         { name = "meleeKill",         slack = 8,  eventScore = 18  },
        
        -- Multi-kills (longer slack for animation)
        doubleKill =        { name = "doubleKill",        slack = 12, eventScore = 25  },
        tripleKill =        { name = "tripleKill",        slack = 12, eventScore = 40  },
        quadraKill =        { name = "quadraKill",        slack = 12, eventScore = 60  },
        reaperMode =        { name = "reaperMode",        slack = 15, eventScore = 80  },
        squadWipe =         { name = "squadWipe",         slack = 10, eventScore = 30  },
        
        -- Game results (longest slack)
        victory =           { name = "victory",           slack = 30, eventScore = 50  },
        defeat =            { name = "defeat",            slack = 30, eventScore = 10  }
    }
    
    -- Function list for event processing
    local functionsList = {
        detectKill,
        detectSquadWipe,
        detectEndGame
    }
    
    return eventsSpecs, functionsList
end

-- Module Exports
return {
    computeEvents = function(modelOutputs, ocrOutput, frameTimes, paddleOcrOutput)
        local cues = {}
        
        -- Process visual cues (empty for Delta Force)
        if next(modelOutputs) ~= nil then
            local visualCues = smoothing.run(visualCuesConfig, modelOutputs, frameTimes)
            for cueName, cueValues in pairs(visualCues) do
                cues[cueName] = cueValues
            end
        else
            cues['frameTimes'] = frameTimes
        end
        
        -- Process OCR output
        if next(ocrOutput) ~= nil then
            for cueName, cueValues in pairs(ocrOutput) do
                cues[cueName] = cueValues
            end
        end
        
        -- Process Paddle OCR output
        if next(paddleOcrOutput) ~= nil then
            for cueName, cueValues in pairs(paddleOcrOutput) do
                cues[cueName] = cueValues
                -- Add confidence scores for better filtering
                cueValues.confidences = {}
                for i, value in ipairs(cueValues.results or {}) do
                    if value == nil or value:match("^%s*$") then
                        cueValues.confidences[i] = 0
                    else
                        cueValues.confidences[i] = 0.8  -- Increased base confidence
                    end
                end
            end
        end
        
        -- Format cues and compute events
        local result = utils.TCTformatCuesData(cues)
        local eventsSpecs, functionsList = setEventsSpecs(cues)
        cues_data.cues = cues
        local eventsTable = event.computeEvents(cues, eventsSpecs, functionsList)
        result.events = eventsTable
        
        return result
    end,
    
    get_paddle_ocr_config = function()
        return ocrConfig
    end,
    
    get_fps = get_fps
}