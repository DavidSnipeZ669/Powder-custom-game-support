--[[
    Battlefield 6 - Powder Game Support Configuration
    -------------------------------------------------
    Version: 1.0
    Last Updated: 2026-05-30
    Status: Reference Implementation
    
    This configuration provides comprehensive OCR-based event detection
    for Battlefield 6, optimized for 2560x1440 resolution.
    
    Features:
        - Multi-region OCR detection
        - Context-aware event processing
        - Performance-optimized pipeline
        - Comprehensive event coverage
    
    Game Information:
        - Game: Battlefield 6 (2042)
        - Primary Resolution: 2560x1440
        - Secondary Resolution: 1920x1080
        - FPS: 5 (balanced setting)
    
    Detection Regions:
        1. KillFeed - Bottom center (kill notifications)
        2. StreakAlert - Top center (multi-kill alerts)
        3. ObjectiveHUD - Top right (objective updates)
        4. VehicleHUD - Bottom left (vehicle status)
        5. GameResult - Center (victory/defeat screens)
]]--

-- Required modules
local smoothing = require("postprocess.smoothing")
local event = require("postprocess.event")
local utils = require("postprocess.utils")
local paddle_ocr = require("postprocess.paddle_ocr")
local cues_data = require("postprocess.cues_data")

-- Performance Configuration
local get_fps = function()
    return 5  -- Balanced for accuracy and performance
end

-- Visual Cues Configuration (empty - BF6 uses OCR only)
local visualCuesConfig = {}

-- OCR Configuration
-- Optimized for Battlefield 6 UI at 2560x1440
local ocrConfig = {
    crops = {
        -- Kill Feed Area
        -- Targets: KILL, HEADSHOT, VEHICLE DESTROY, etc.
        {
            cropName = "KillFeed",
            debug = false,
            cropCoords = { 0.350, 0.680, 0.650, 0.750 }, -- Bottom-center kill feed
            detectorDilateDiameter = 4,
            detectorMinimumArea = 8,
            detectorMargin = 6,
            recogniserStretchVertical = false,
            restrictedCharacters = ""
        },
        
        -- Streak Alert Area
        -- Targets: DOUBLE KILL, TRIPLE KILL, etc.
        {
            cropName = "StreakAlert",
            debug = false,
            cropCoords = { 0.300, 0.080, 0.700, 0.180 }, -- Top-center multi-kill alerts
            detectorDilateDiameter = 3,
            detectorMinimumArea = 6,
            detectorMargin = 5,
            recogniserStretchVertical = false,
            restrictedCharacters = ""
        },
        
        -- Objective HUD Area
        -- Targets: OBJECTIVE CAPTURED, DEFENDED, etc.
        {
            cropName = "ObjectiveHUD",
            debug = false,
            cropCoords = { 0.700, 0.050, 0.950, 0.200 }, -- Top-right objective updates
            detectorDilateDiameter = 3,
            detectorMinimumArea = 5,
            detectorMargin = 4,
            recogniserStretchVertical = false,
            restrictedCharacters = ""
        },
        
        -- Vehicle HUD Area
        -- Targets: VEHICLE DAMAGE, DESTROYED, etc.
        {
            cropName = "VehicleHUD",
            debug = false,
            cropCoords = { 0.050, 0.650, 0.350, 0.750 }, -- Bottom-left vehicle status
            detectorDilateDiameter = 4,
            detectorMinimumArea = 10,
            detectorMargin = 8,
            recogniserStretchVertical = false,
            restrictedCharacters = ""
        },
        
        -- Game Result Area
        -- Targets: VICTORY, DEFEAT, etc.
        {
            cropName = "GameResult",
            debug = false,
            cropCoords = { 0.300, 0.200, 0.700, 0.400 }, -- Centered result screen
            detectorDilateDiameter = 5,
            detectorMinimumArea = 100,
            detectorMargin = 20,
            recogniserStretchVertical = false,
            restrictedCharacters = ""
        }
    }
}

-- Event Detection Functions
local setEventsSpecs = function (cues)
    -- Event detection configurations with tiered confidence
    
    -- Basic Combat Events
    local combatDetectors = {
        { event = 'kill',              match = { 'KILL', 'ELIMINATED', 'TAKEDOWN' },                     score = 90 },
        { event = 'headshot',          match = { 'HEADSHOT', 'HS', 'HEAD SHOT' },                        score = 88 },
        { event = 'vehicleDestroy',    match = { 'VEHICLE DESTROYED', 'DESTROYED', 'VEHICLE KILL' },      score = 85 },
        { event = 'vehicleDamage',     match = { 'VEHICLE DAMAGE', 'CRITICAL DAMAGE', 'DAMAGED' },        score = 82 },
        { event = 'roadkill',          match = { 'ROADKILL', 'RUN OVER', 'ROAD KILL' },                    score = 85 }
    }
    
    -- Multi-kill Events
    local streakDetectors = {
        { event = 'doubleKill',        match = { 'DOUBLE KILL', 'DOUBLE ELIMINATION' },               score = 88 },
        { event = 'tripleKill',        match = { 'TRIPLE KILL', 'TRIPLE ELIMINATION' },               score = 88 },
        { event = 'quadraKill',        match = { 'QUADRA KILL', 'QUADRUPLE KILL', 'QUAD ELIMINATION' }, score = 88 },
        { event = 'reaperMode',        match = { 'REAPER MODE', 'MULTI KILL', 'KILLING SPREE' },        score = 88 }
    }
    
    -- Objective Events
    local objectiveDetectors = {
        { event = 'objectiveCaptured', match = { 'OBJECTIVE CAPTURED', 'POINT SECURED', 'CAPTURED' }, score = 85 },
        { event = 'objectiveDefended', match = { 'OBJECTIVE DEFENDED', 'DEFENDED', 'DEFENSE SUCCESSFUL' }, score = 85 },
        { event = 'objectiveDestroyed', match = { 'OBJECTIVE DESTROYED', 'DESTROYED', 'TARGET ELIMINATED' }, score = 85 },
        { event = 'flagCaptured',      match = { 'FLAG CAPTURED', 'CAPTURED', 'POINT TAKEN' },           score = 85 }
    }
    
    -- Squad Events
    local squadDetectors = {
        { event = 'squadWipe',  match = { 'SQUAD WIPE', 'ENEMY SQUAD ELIMINATED', 'TEAM WIPE' }, score = 85 },
        { event = 'squadRevive', match = { 'SQUAD REVIVE', 'REVIVED', 'TEAMMATE SAVED' },              score = 85 },
        { event = 'squadHeal',   match = { 'SQUAD HEAL', 'HEALED', 'TEAMMATE HEALTH RESTORED' },    score = 85 }
    }
    
    -- Game Result Events
    local resultDetectors = {
        { event = 'victory', match = { 'VICTORY', 'MATCH WIN', 'ROUND WIN', 'SUCCESS' }, score = 80 },
        { event = 'defeat',  match = { 'DEFEAT', 'MATCH LOSS', 'ROUND LOSS', 'FAILED' },  score = 80 }
    }
    
    -- Enhanced Detection Functions
    local function detectCombat(frameIndex)
        local detectedEvent = nil
        local bestScore = 0
        
        for _, config in ipairs(combatDetectors) do
            local score = paddle_ocr.checkFuture(frameIndex, 3, 'KillFeed', config.match, config.score)
            if score and score > bestScore then
                detectedEvent = config.event
                bestScore = score
            end
        end
        
        -- Special handling for vehicle events
        if not detectedEvent then
            for _, config in ipairs(combatDetectors) do
                if config.event:find('vehicle') or config.event:find('roadkill') then
                    local score = paddle_ocr.checkFuture(frameIndex, 3, 'VehicleHUD', config.match, config.score)
                    if score and score > bestScore then
                        detectedEvent = config.event
                        bestScore = score
                    end
                end
            end
        end
        
        return detectedEvent, frameIndex - 2
    end
    
    local function detectStreak(frameIndex)
        for _, config in ipairs(streakDetectors) do
            local score = paddle_ocr.checkFuture(frameIndex, 3, 'StreakAlert', config.match, config.score)
            if score and score > 80 then
                return config.event, frameIndex
            end
        end
    end
    
    local function detectObjective(frameIndex)
        for _, config in ipairs(objectiveDetectors) do
            local score = paddle_ocr.checkFuture(frameIndex, 3, 'ObjectiveHUD', config.match, config.score)
            if score and score > 75 then
                return config.event, frameIndex
            end
        end
    end
    
    local function detectSquad(frameIndex)
        for _, config in ipairs(squadDetectors) do
            local score = paddle_ocr.checkFuture(frameIndex, 3, 'StreakAlert', config.match, config.score)
            if score and score > 75 then
                return config.event, frameIndex
            end
        end
    end
    
    local function detectResult(frameIndex)
        for _, config in ipairs(resultDetectors) do
            local score = paddle_ocr.checkFuture(frameIndex, 3, 'GameResult', config.match, config.score)
            if score and score > 70 then
                return config.event, frameIndex
            end
        end
    end
    
    -- Event Specifications
    local eventsSpecs = {
        -- Combat events
        kill =              { name = "kill",              slack = 8,  eventScore = 10  },
        headshot =          { name = "headshot",          slack = 8,  eventScore = 15  },
        vehicleDestroy =    { name = "vehicleDestroy",    slack = 10, eventScore = 20  },
        vehicleDamage =     { name = "vehicleDamage",     slack = 8,  eventScore = 8   },
        roadkill =          { name = "roadkill",          slack = 8,  eventScore = 18  },
        
        -- Multi-kill events
        doubleKill =        { name = "doubleKill",        slack = 12, eventScore = 25  },
        tripleKill =        { name = "tripleKill",        slack = 12, eventScore = 40  },
        quadraKill =        { name = "quadraKill",        slack = 15, eventScore = 60  },
        reaperMode =        { name = "reaperMode",        slack = 15, eventScore = 80  },
        
        -- Objective events
        objectiveCaptured = { name = "objectiveCaptured", slack = 10, eventScore = 20  },
        objectiveDefended =  { name = "objectiveDefended",  slack = 10, eventScore = 18  },
        objectiveDestroyed = { name = "objectiveDestroyed", slack = 10, eventScore = 22  },
        flagCaptured =      { name = "flagCaptured",      slack = 8,  eventScore = 15  },
        
        -- Squad events
        squadWipe =         { name = "squadWipe",         slack = 10, eventScore = 25  },
        squadRevive =        { name = "squadRevive",        slack = 8,  eventScore = 12  },
        squadHeal =         { name = "squadHeal",         slack = 8,  eventScore = 10  },
        
        -- Game results
        victory =           { name = "victory",           slack = 30, eventScore = 50  },
        defeat =            { name = "defeat",            slack = 30, eventScore = 10  }
    }
    
    -- Function list for event processing
    local functionsList = {
        detectCombat,
        detectStreak,
        detectObjective,
        detectSquad,
        detectResult
    }
    
    return eventsSpecs, functionsList
end

-- Module Exports
return {
    computeEvents = function(modelOutputs, ocrOutput, frameTimes, paddleOcrOutput)
        local cues = {}
        
        -- Process visual cues (empty for BF6)
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
                -- Add confidence scores
                cueValues.confidences = {}
                for i, value in ipairs(cueValues.results or {}) do
                    if value == nil or value:match("^%s*$") then
                        cueValues.confidences[i] = 0
                    else
                        cueValues.confidences[i] = 0.85  -- Base confidence
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