--[[
    Test Game Video - AI-Generated Powder Game Support Configuration
    -------------------------------------------------
    Version: 1.0
    Last Updated: 2026-05-30
    Status: AI-Optimized Configuration
    
    This configuration was automatically generated using AI-based event pattern detection.
    
    Detected Events: 6 types
    Analysis Date: 2026-05-30 17:23:51
    Game Type: fps
    
    Features:
        - AI-optimized OCR detection regions
        - Automatically detected event patterns
        - Smart confidence thresholds
        - Performance-optimized pipeline
    
    Game Information:
        - Game: Test Game Video
        - Primary Resolution: 2560x1440
        - Secondary Resolution: 1920x1080
        - FPS: 5 (balanced setting)
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

-- Visual Cues Configuration (empty - uses OCR only)
local visualCuesConfig = {}

-- AI-Optimized OCR Configuration for TEST_GAME_
local ocrConfig = {
    crops = {
        -- KillFeed - Bottom-center kill notifications
        {
            cropName = "KillFeed",
            debug = false,
            cropCoords = { 0.3, 0.65, 0.7, 0.75 },
            detectorDilateDiameter = 4,
            detectorMinimumArea = 8,
            detectorMargin = 6,
            recogniserStretchVertical = false,
            restrictedCharacters = ""
        },

        -- StreakAlert - Top-center multi-kill alerts
        {
            cropName = "StreakAlert",
            debug = false,
            cropCoords = { 0.3, 0.05, 0.7, 0.15 },
            detectorDilateDiameter = 4,
            detectorMinimumArea = 8,
            detectorMargin = 6,
            recogniserStretchVertical = false,
            restrictedCharacters = ""
        },

        -- ObjectiveHUD - Top-right objective updates
        {
            cropName = "ObjectiveHUD",
            debug = false,
            cropCoords = { 0.7, 0.05, 0.95, 0.2 },
            detectorDilateDiameter = 4,
            detectorMinimumArea = 8,
            detectorMargin = 6,
            recogniserStretchVertical = false,
            restrictedCharacters = ""
        },

        -- GameResult - Centered victory/defeat screens
        {
            cropName = "GameResult",
            debug = false,
            cropCoords = { 0.3, 0.2, 0.7, 0.4 },
            detectorDilateDiameter = 4,
            detectorMinimumArea = 8,
            detectorMargin = 6,
            recogniserStretchVertical = false,
            restrictedCharacters = ""
        },

    }
}

-- AI-Generated Event Detection Functions
local setEventsSpecs = function (cues)
    local killDetectors = {
        { event = 'kill', match = { 'TAKEDOWN' }, score = 85 },
        { event = 'kill', match = { 'DOWN' }, score = 85 },
        { event = 'kill', match = { 'KILL' }, score = 85 },
        { event = 'kill', match = { 'ELIMINATED' }, score = 85 },
    }

    local headshotDetectors = {
        { event = 'headshot', match = { 'HEAD SHOT' }, score = 85 },
        { event = 'headshot', match = { 'HEADSHOT' }, score = 85 },
        { event = 'headshot', match = { 'HS' }, score = 85 },
    }

    local double_killDetectors = {
        { event = 'double_kill', match = { 'DOUBLE KILL' }, score = 85 },
        { event = 'double_kill', match = { 'DOUBLE ELIMINATION' }, score = 85 },
    }

    local triple_killDetectors = {
        { event = 'triple_kill', match = { 'TRIPLE KILL' }, score = 85 },
        { event = 'triple_kill', match = { 'TRIPLE ELIMINATION' }, score = 85 },
    }

    local victoryDetectors = {
        { event = 'victory', match = { 'WIN' }, score = 85 },
        { event = 'victory', match = { 'VICTORY' }, score = 85 },
        { event = 'victory', match = { 'MATCH WIN' }, score = 85 },
    }

    local defeatDetectors = {
        { event = 'defeat', match = { 'MATCH LOSS' }, score = 85 },
        { event = 'defeat', match = { 'LOSS' }, score = 85 },
        { event = 'defeat', match = { 'DEFEAT' }, score = 85 },
    }

    local function detectKill(frameIndex)
        for _, config in ipairs(killDetectors) do
            local score = paddle_ocr.checkFuture(frameIndex, 3, 'KillFeed', config.match, config.score)
            if score and score > 75 then
                return config.event, frameIndex
            end
        end
    end

    local function detectHeadshot(frameIndex)
        for _, config in ipairs(headshotDetectors) do
            local score = paddle_ocr.checkFuture(frameIndex, 3, 'KillFeed', config.match, config.score)
            if score and score > 80 then
                return config.event, frameIndex
            end
        end
    end

    local function detectDouble_kill(frameIndex)
        for _, config in ipairs(double_killDetectors) do
            local score = paddle_ocr.checkFuture(frameIndex, 3, 'StreakAlert', config.match, config.score)
            if score and score > 80 then
                return config.event, frameIndex
            end
        end
    end

    local function detectTriple_kill(frameIndex)
        for _, config in ipairs(triple_killDetectors) do
            local score = paddle_ocr.checkFuture(frameIndex, 3, 'StreakAlert', config.match, config.score)
            if score and score > 80 then
                return config.event, frameIndex
            end
        end
    end

    local function detectVictory(frameIndex)
        for _, config in ipairs(victoryDetectors) do
            local score = paddle_ocr.checkFuture(frameIndex, 3, 'GameResult', config.match, config.score)
            if score and score > 80 then
                return config.event, frameIndex
            end
        end
    end

    local function detectDefeat(frameIndex)
        for _, config in ipairs(defeatDetectors) do
            local score = paddle_ocr.checkFuture(frameIndex, 3, 'GameResult', config.match, config.score)
            if score and score > 80 then
                return config.event, frameIndex
            end
        end
    end

    local eventsSpecs = {
        kill = { name = "kill", slack = 8, eventScore = 10 },
        headshot = { name = "headshot", slack = 8, eventScore = 10 },
        double_kill = { name = "double_kill", slack = 8, eventScore = 10 },
        triple_kill = { name = "triple_kill", slack = 8, eventScore = 10 },
        victory = { name = "victory", slack = 8, eventScore = 10 },
        defeat = { name = "defeat", slack = 8, eventScore = 10 },
    }

    local functionsList = {
        detectKill,
        detectHeadshot,
        detectDouble_kill,
        detectTriple_kill,
        detectVictory,
        detectDefeat,
    }

    return eventsSpecs, functionsList
end

return {
    computeEvents = function(modelOutputs, ocrOutput, frameTimes, paddleOcrOutput)
        -- Standard processing (same as base template)
        -- ... (standard processing code would go here) ...
    end,

    get_paddle_ocr_config = function()
        return ocrConfig
    end,

    get_fps = get_fps
}
