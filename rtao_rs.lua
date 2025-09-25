local Players = game:GetService("Players")
local player = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local GRACE_SECONDS = 0.5


local KEYS_RAW_URL      = "https://raw.githubusercontent.com/RTaOexe1/Whitelist/main/Key.json" -- ลิงก์ raw สำหรับเช็ค key
local REMOTE_SCRIPT_URL = "https://raw.githubusercontent.com/rtaodev/Loader/main/Script.lua" -- สคริปต์หลักที่จะโหลด

local function getKey()
    if getgenv and type(getgenv().Key_Script) == "string" and getgenv().Key_Script ~= "" then
        return tostring(getgenv().Key_Script)
    end
    return ""
end

local function validateKey(key)
    if key == "" then return false end
    local ok, res = pcall(function()
        return game:HttpGet(KEYS_RAW_URL, true)
    end)
    if not ok or type(res) ~= "string" then
        warn("[KeyCheck] Failed to fetch keys:", res)
        return false
    end

    local ok2, parsed = pcall(function()
        return HttpService:JSONDecode(res)
    end)
    if not ok2 or type(parsed) ~= "table" or type(parsed.keys) ~= "table" then
        warn("[KeyCheck] Invalid JSON format")
        return false
    end

    for _, entry in ipairs(parsed.keys) do
        if type(entry) == "table" and tostring(entry.key) == key then
            local expiry = entry.expires
            if expiry then
                local y,m,d = expiry:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)$")
                if y and m and d then
                    local ts = os.time({year=tonumber(y), month=tonumber(m), day=tonumber(d), hour=0, min=0, sec=0})
                    if os.time() > ts then
                        return false
                    end
                end
            end
            return true
        end
    end
    return false
end

local function runRemoteScript(url)
    local ok,res = pcall(function() return game:HttpGet(url, true) end)
    if not ok or type(res) ~= "string" then
        warn("[RemoteLoad] HttpGet failed:", res)
        return
    end
    local fn, err
    if loadstring then fn,err = loadstring(res) else fn,err = load(res) end
    if not fn then
        warn("[RemoteLoad] Load error:", err)
        return
    end
    local ok2, runErr = pcall(fn)
    if not ok2 then
        warn("[RemoteLoad] Runtime error:", runErr)
        return
    end
    print("[RemoteLoad] Script loaded successfully")
end
task.spawn(function()
    wait(GRACE_SECONDS)
    local key = getKey()
    if not validateKey(key) then
        player:Kick("Key invalid or expired (client-side).")
        return
    end

    runRemoteScript(REMOTE_SCRIPT_URL)
end)
