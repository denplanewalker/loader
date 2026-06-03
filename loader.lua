warn("[HellShade] Checking executor")

-- Resolve key from environment (getgenv, shared, _G, or caller environment)
local function getScriptKey()
    -- Check globals/genv
    local genv = (typeof(getgenv) == "function" and getgenv()) or {}
    local key = genv.script_key or genv.SCRIPT_KEY or shared.script_key or shared.SCRIPT_KEY or _G.script_key or _G.SCRIPT_KEY
    if key and key ~= "" then
        return key
    end

    -- Check calling environment levels
    for level = 1, 6 do
        local success, env = pcall(getfenv, level)
        if success and env then
            local k = env.script_key or env.SCRIPT_KEY
            if k and k ~= "" then
                return k
            end
        end
    end
    return nil
end

local script_key = getScriptKey()

if not script_key or script_key == "" then
    warn("[HellShade Loader] Error: No key found! Please define SCRIPT_KEY before running this script.")
    game:GetService("Players").LocalPlayer:Kick(
        "[HellShade Loader]\nKey not found!\n\nPlease make sure to define the key like this:\nSCRIPT_KEY = \"YOUR_KEY_HERE\"\nloadstring(game:HttpGet(...))()"
    )
    return
end

-- Propagate key to globals and environments for the loaded script
local genv = (typeof(getgenv) == "function" and getgenv())
if genv then
    genv.SCRIPT_KEY = script_key
    genv.script_key = script_key
end
_G.SCRIPT_KEY = script_key
_G.script_key = script_key
pcall(function()
    getfenv(1).SCRIPT_KEY = script_key
    getfenv(1).script_key = script_key
end)

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
    warn("[HellShade] Blacklisted executor detected: " .. tostring(executorName) .. ". Join: https://discord.gg/VBtwWkdR9s")
    game:GetService("Players").LocalPlayer:Kick(
        "[HellShade Loader]\nYour executor (" .. tostring(executorName) .. ") is blacklisted.\n\nJoin: https://discord.gg/VBtwWkdR9s"
    )
    setclipboard("https://discord.gg/VBtwWkdR9s")
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
        SourceUrl = "https://api.jnkie.com/api/v1/luascripts/public/235613f95887df459787629e576370797c867e7d35e05971f146377337868c5e/download",
        UseActor = true,
    },
    DL = {
        Name = "Defusal",
        Ids = { "79393329652220" },
        SourceUrl = "",
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
        script_key="]==] .. tostring(script_key) .. [==[";
        SCRIPT_KEY="]==] .. tostring(script_key) .. [==[";
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
