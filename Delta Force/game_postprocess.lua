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
