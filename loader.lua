warn("[HellShade] Checking executor")

local BlacklistedExecutors = {
    "xeno",
    "solara",
    "velocity",
}

local function isBlacklistedExecutor()
    if typeof(identifyexecutor) ~= "function" then
        return false, "Unknown"
    end
    local exec = string.lower(tostring(identifyexecutor()))
    for _, name in ipairs(BlacklistedExecutors) do
        if exec:find(name, 1, true) then
            return true, exec
        end
    end
    return false, exec
end

local blacklisted, executorName = isBlacklistedExecutor()
if blacklisted then
    warn("[HellShade] Blacklisted executor detected: " .. tostring(executorName))
    game:GetService("Players").LocalPlayer:Kick(
        "[HellShade Loader]\nYour executor (" .. tostring(executorName) .. ") is blacklisted."
    )
    return
end

warn(("[HellShade] Detected executor: %s"):format(executorName))

local Games = {
    CB = {
        Name = "Counter Blox",
        Ids = { "301549746" },
        SourceUrl = "",
        UseActor = false,
    },
    TS = {
        Name = "Trident Survival",
        Ids = { "13253735473" },
        SourceUrl = "https://raw.githubusercontent.com/denplanewalker/loader/refs/heads/main/TS.lua",
        UseActor = true,
    },
    DL = {
        Name = "Defusal",
        Ids = { "79393329652220" },
        SourceUrl = "https://raw.githubusercontent.com/denplanewalker/loader/refs/heads/main/DL.lua",
        UseActor = false,
    },
}

local function locateGame(placeId)
    local id = tostring(placeId)
    for code, data in pairs(Games) do
        if table.find(data.Ids, id) then
            return code, data
        end
    end
    return nil, nil
end

local function loadOnActor(sourceUrl)
    local actor
    if typeof(getactors) == "function" then
        local actors = getactors()
        if actors then
            actor = actors[1]
        end
    end
    if not actor then
        actor = game:GetService("Players").LocalPlayer.PlayerScripts:FindFirstChild("Client")
    end
    if not actor then
        warn("[HellShade] Failed to get actor")
        return false
    end

    run_on_actor(actor, [==[
        loadstring(game:HttpGet("]==] .. sourceUrl .. [==["))()
    ]==])
    return true
end

local placeId = tostring(game.PlaceId)
local gameCode, gameData = locateGame(placeId)

if not gameCode or not gameData then
    warn("[HellShade] Game is unsupported!")
    return
end

if not gameData.SourceUrl or gameData.SourceUrl:find("PLACEHOLDER", 1, true) then
    warn(("[HellShade] %s (%s) is not configured yet (missing loader URL)."):format(gameData.Name, gameCode))
    return
end

warn(("[HellShade] Detected game: %s (%s). Loading script..."):format(gameData.Name, gameCode))

if gameData.UseActor then
    if not loadOnActor(gameData.SourceUrl) then
        loadstring(game:HttpGet(gameData.SourceUrl))()
    end
else
    loadstring(game:HttpGet(gameData.SourceUrl))()
end
