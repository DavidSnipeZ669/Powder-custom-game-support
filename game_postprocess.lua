local smoothing = require("postprocess.smoothing")
local event = require("postprocess.event")
local utils = require("postprocess.utils")
local paddle_ocr = require("postprocess.paddle_ocr")
local cues_data = require("postprocess.cues_data")

--[[                DF   -- Delta Force Visual and OCR Cues Configuration File
    -----------------------------------------------------------------------------
    22/10/2025 
    Author : DavidGaming669
    Version : 1.00
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

    Ocr events (Paddle) :
        kill
        headshot
        vehicule Destroyed
        double Kill
        triple Kill
        quadra Kill
        reaper Mode
        victory
        defeat
        
    
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
            cropName = "KillMessage",
            debug = true,
            cropCoords = { 0.391, 0.662, 0.605, 0.845 },
            detectorDilateDiameter = 3,
            detectorMinimumArea = 5,
            detectorMargin = 5,
            recogniserStretchVertical = true,
            restrictedCharacters = ""
        },
        {
            cropName = "GameResult",
            debug = true,
            cropCoords = { 0.281, 0.127, 0.705, 0.454 },
            detectorDilateDiameter = 5,
            detectorMinimumArea = 1000,
            detectorMargin = 30,
            recogniserStretchVertical = true,
            restrictedCharacters = ""
        }
    }
}

local setEventsSpecs = function (cues)
    -- Used in events functions ----------

    --------------------------------------

    -- Events functions ------------------
    -- every function in this section have to be in the functionsList
    -- those functions return nil or an event name

    local killDetectors = {
        { event = 'preciseLongShot',   match = { 'Precise Long Shot' }, score = 85 },
        { event = 'longShot',          match = { 'Long Shot' },         score = 85 },
        { event = 'quadraKill',        match = { 'Quadra Kill' },       score = 85 },
        { event = 'tripleKill',        match = { 'Triple Kill' },       score = 85 },
        { event = 'doubleKill',        match = { 'Double Kill' },       score = 85 },
        { event = 'headshot',          match = { 'Headshot' },          score = 85 },
        { event = 'kill',              match = { 'Kill' },              score = 80 }
    }
    local detectKill = function (frameIndex)
        local event = nil

        for _, config in ipairs(killDetectors) do
            if paddle_ocr.checkFuture(frameIndex, 2, 'KillMessage', config.match, config.score) then
                event = config.event
            end
        end

        return event, frameIndex - 2
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

    -- list of the function used to identify events (used in events.computeEvents)
    local functionsList = {
        detectKill, detectEndGame
    }

    -- list of the events specs (used for events merging)
    -- every event has to be listed in events specs
    -- slack : number of consecutive frames that can be ignored when merging events
    local eventsSpecs = {
        kill =                { name = "kill",                slack = 8  },
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

    local cues = {} -- table containing both ocr and visual cues

    -- visual cues if modelOutputs is not empty
    if next(modelOutputs) ~= nil then
        -- get smoothed visual cues
        local visualCues = smoothing.run(visualCuesConfig, modelOutputs, frameTimes)

        -- add visual cues to cues
        for cueName, cueValues in pairs(visualCues) do
            cues[cueName] = cueValues
        end
    else
        -- if model is ocr only we have to add the frametimes table to cues
        -- smoothing.run add it to visual cues
        cues['frameTimes'] = frameTimes
    end

    -- ocr cues if ocrOutput is not empty
    if next(ocrOutput) ~= nil then
        -- add ocr cues to cues
        for cueName, cueValues in pairs(ocrOutput) do
            cues[cueName] = cueValues
        end
    end

    -- ocr cues if paddleOcrOutput is not empty
    if next(paddleOcrOutput) ~= nil then
        -- add ocr cues to cues
        for cueName, cueValues in pairs(paddleOcrOutput) do
            cues[cueName] = cueValues

            -- Adding fake confidence for TCT display
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

    -- get TCT data and add them in the result
    local result = utils.TCTformatCuesData(cues)

    -- get everything needed for events detection
    local eventsSpecs, functionsList = setEventsSpecs(cues)

    cues_data.cues = cues

    -- get detected events
    local eventsTable = event.computeEvents(cues, eventsSpecs, functionsList)

    -- add events to the result
    result.events = eventsTable

    return result
end

return {
    computeEvents = computeEvents,
    get_paddle_ocr_config = get_paddle_ocr_config,
    get_fps = get_fps,
}
