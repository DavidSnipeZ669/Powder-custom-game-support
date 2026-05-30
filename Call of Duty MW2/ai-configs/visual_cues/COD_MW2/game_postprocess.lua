--[[
    Call of Duty: Modern Warfare 2 (2022) - Powder Game Support Configuration
    --------------------------------------------------------------------------
    Version: 1.0
    Last Updated: 2026-05-30
    Status: Reference Implementation
    
    This configuration provides OCR-based event detection for Call of Duty: MW2 (2022).
    
    Features:
        - Multi-region OCR detection
        - Context-aware event processing
        - Performance-optimized pipeline
        - Comprehensive event coverage
    
    Game Information:
        - Game: Call of Duty: Modern Warfare II (2022)
        - Primary Resolution: 2560x1440
        - Secondary Resolution: 1920x1080
        - FPS: 5 (balanced setting)
    
    Detection Regions:
        1. KillFeed - Bottom center (kill notifications)
        2. StreakAlert - Top center (killstreak alerts)
        3. ObjectiveHUD - Top right (objective updates)
        4. GameResult - Center (victory/defeat screens)
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

-- Visual Cues Configuration (empty - MW2 uses OCR only)
local visualCuesConfig = {}

-- OCR Configuration for COD MW2
local ocrConfig = {
    crops = {
        -- Kill Feed Area
        {
            cropName = "KillFeed",
            debug = false,
            cropCoords = { 0.300, 0.650, 0.700, 0.750 },
            detectorDilateDiameter = 4,
            detectorMinimumArea = 8,
            detectorMargin = 6,
            recogniserStretchVertical = false,
            restrictedCharacters = ""
        },
        
        -- Streak Alert Area
        {
            cropName = "StreakAlert",
            debug = false,
            cropCoords = { 0.300, 0.050, 0.700, 0.150 },
            detectorDilateDiameter = 3,
            detectorMinimumArea = 6,
            detectorMargin = 5,
            recogniserStretchVertical = false,
            restrictedCharacters = ""
        },
        
        -- Objective HUD Area
        {
            cropName = "ObjectiveHUD",
            debug = false,
            cropCoords = { 0.700, 0.050, 0.950, 0.200 },
            detectorDilateDiameter = 3,
            detectorMinimumArea = 5,
            detectorMargin = 4,
            recogniserStretchVertical = false,
            restrictedCharacters = ""
        },
        
        -- Game Result Area
        {
            cropName = "GameResult",
            debug = false,
            cropCoords = { 0.300, 0.200, 0.700, 0.400 },
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
    -- Event detection configurations
    
    local combatDetectors = {
        { event = 'kill',      match = { 'KILL', 'ELIMINATED', 'TAKEDOWN' },               score = 90 },
        { event = 'headshot',  match = { 'HEADSHOT', 'HS', 'HEAD SHOT' },                  score = 88 },
        { event = 'meleeKill', match = { 'MELEE', 'KNIFE', 'MELEE KILL', 'KNIFE KILL' },       score = 85 },
        { event = 'execution', match = { 'EXECUTION', 'FINISHING MOVE', 'FINISHER' },         score = 85 },
        { event = 'pointBlank', match = { 'POINT BLANK', 'CLOSE QUARTERS', 'CQC' },           score = 85 }
    }
    
    local streakDetectors = {
        { event = 'doubleKill', match = { 'DOUBLE KILL', 'DOUBLE ELIMINATION' },            score = 88 },
        { event = 'tripleKill', match = { 'TRIPLE KILL', 'TRIPLE ELIMINATION' },            score = 88 },
        { event = 'quadraKill', match = { 'QUADRA KILL', 'QUADRUPLE KILL', 'QUAD ELIMINATION' }, score = 88 },
        { event = 'killChain',  match = { 'KILL CHAIN', 'KILLSTREAK', 'MULTI KILL' },      score = 88 }
    }
    
    local killstreakDetectors = {
        { event = 'uav',          match = { 'UAV', 'RECON DRONE', 'UAV ACTIVE' },           score = 85 },
        { event = 'cruiseMissile', match = { 'CRUISE MISSILE', 'MISSILE STRIKE' },          score = 85 },
        { event = 'gunship',      match = { 'GUNSHIP', 'AC130', 'HELICOPTER SUPPORT' },    score = 85 },
        { event = 'nuke',         match = { 'NUKE', 'TACTICAL NUKE', 'NUKE INCOMING' },      score = 85 }
    }
    
    local objectiveDetectors = {
        { event = 'flagCaptured', match = { 'FLAG CAPTURED', 'CAPTURED', 'POINT TAKEN' },      score = 85 },
        { event = 'bombPlanted',  match = { 'BOMB PLANTED', 'PLANTED', 'BOMB SET' },         score = 85 },
        { event = 'bombDefused',  match = { 'BOMB DEFUSED', 'DEFUSED', 'BOMB DISARMED' },    score = 85 }
    }
    
    local resultDetectors = {
        { event = 'victory', match = { 'VICTORY', 'MATCH WIN', 'ROUND WIN', 'SUCCESS' }, score = 80 },
        { event = 'defeat',  match = { 'DEFEAT', 'MATCH LOSS', 'ROUND LOSS', 'FAILED' },  score = 80 }
    }
    
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
        
        return detectedEvent, frameIndex - 2
    end
    
    local function detectStreak(frameIndex)
        for _, config in ipairs(streakDetectors) do
            local score = paddle_ocr.checkFuture(frameIndex, 3, 'KillFeed', config.match, config.score)
            if score and score > 80 then
                return config.event, frameIndex
            end
        end
    end
    
    local function detectKillstreak(frameIndex)
        for _, config in ipairs(killstreakDetectors) do
            local score = paddle_ocr.checkFuture(frameIndex, 3, 'StreakAlert', config.match, config.score)
            if score and score > 75 then
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
    
    local function detectResult(frameIndex)
        for _, config in ipairs(resultDetectors) do
            local score = paddle_ocr.checkFuture(frameIndex, 3, 'GameResult', config.match, config.score)
            if score and score > 70 then
                return config.event, frameIndex
            end
        end
    end
    
    local eventsSpecs = {
        -- Combat events
        kill =        { name = "kill",        slack = 8,  eventScore = 10  },
        headshot =    { name = "headshot",    slack = 8,  eventScore = 15  },
        meleeKill =   { name = "meleeKill",   slack = 8,  eventScore = 12  },
        execution =   { name = "execution",   slack = 8,  eventScore = 13  },
        pointBlank =  { name = "pointBlank",  slack = 8,  eventScore = 11  },
        
        -- Multi-kill events
        doubleKill =  { name = "doubleKill",  slack = 12, eventScore = 25  },
        tripleKill =  { name = "tripleKill",  slack = 12, eventScore = 40  },
        quadraKill =  { name = "quadraKill",  slack = 15, eventScore = 60  },
        killChain =   { name = "killChain",   slack = 15, eventScore = 80  },
        
        -- Killstreak events
        uav =          { name = "uav",          slack = 10, eventScore = 20  },
        cruiseMissile = { name = "cruiseMissile", slack = 10, eventScore = 25  },
        gunship =      { name = "gunship",      slack = 15, eventScore = 30  },
        nuke =         { name = "nuke",         slack = 20, eventScore = 100 },
        
        -- Objective events
        flagCaptured = { name = "flagCaptured", slack = 8,  eventScore = 15  },
        bombPlanted =  { name = "bombPlanted",  slack = 8,  eventScore = 18  },
        bombDefused =  { name = "bombDefused",  slack = 8,  eventScore = 18  },
        
        -- Game results
        victory =      { name = "victory",      slack = 30, eventScore = 50  },
        defeat =       { name = "defeat",       slack = 30, eventScore = 10  }
    }
    
    local functionsList = {
        detectCombat,
        detectStreak,
        detectKillstreak,
        detectObjective,
        detectResult
    }
    
    return eventsSpecs, functionsList
end

return {
    computeEvents = function(modelOutputs, ocrOutput, frameTimes, paddleOcrOutput)
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
                for i, value in ipairs(cueValues.results or {}) do
                    if value == nil or value:match("^%s*$") then
                        cueValues.confidences[i] = 0
                    else
                        cueValues.confidences[i] = 0.85
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
    end,
    
    get_paddle_ocr_config = function()
        return ocrConfig
    end,
    
    get_fps = get_fps
}