takeWorld = "world|id"
saveWorld = "world|id"
dropX, dropY = 9, 52
itemID = 8641

takingMode = false
droppingMode = false
-- fetch("https://backup-grandfuscator.vercel.app/raw/Grandfuscator_lib.lua")
-- fetch("https://raw.githubusercontent.com/Andkuq12/Key-System-Documentation/refs/heads/main/grandfuscator_lib.lua")
function loadGrandfuscatorLib()
    local raw, err = fetch("https://raw.githubusercontent.com/Andkuq12/Key-System-Documentation/refs/heads/main/grandfuscator_lib.lua")
    if not raw then
        LogToConsole("Failed to fetch key library: " .. tostring(err))
        return nil
    end
    local fn, loadErr = load(raw)
    if not fn then
        LogToConsole("Failed to load key library: " .. tostring(loadErr))
        return nil
    end
    return fn()
end

function loadlibrary(filename)
    local paths = {
        "/storage/emulated/0/Android/media/launcher.powerkuy.growlauncher/" .. filename .. ".lua",
        "/storage/emulated/0/Android/data/launcher.powerkuy.growlauncher/files/" .. filename .. ".lua"
    }
    for _, p in ipairs(paths) do
        local f = io.open(p, "r")
        if f then
            local s = f:read("*a")
            f:close()
            local fn, err = load(s)
            if fn then
                return fn()
            else
                return nil, err
            end
        end
    end
    return nil, "File not found"
end

local grandfuscator = loadGrandfuscatorLib()
if not grandfuscator then
    LogToConsole("Cannot continue without key library")
    return
end

local USERNAME = "Grandkuq"
grandfuscator.setup(USERNAME, { recheck = 600 })

local keyVerified = false
local showKeyWindow = true
local inputKey = ""
local verifyStatus = "Enter your key"

function drawKeyWindow()
    if not showKeyWindow then return end
    ImGui.Begin("Key Required", true)
    ImGui.Text("Get your key at: grandfuscator.my.id")
    ImGui.Spacing()
    local ch, newKey = ImGui.InputText("##key", inputKey, 64)
    if ch then inputKey = newKey end
    ImGui.Spacing()
    if ImGui.Button("Verify") then
        runThread(function()
            local ok, msg = grandfuscator.checkkey(inputKey)
            if ok then
                keyVerified = true
                verifyStatus = "Key OK"
                showKeyWindow = false
                startMainScript()
            else
                verifyStatus = "Invalid: " .. msg
            end
        end)
    end
    ImGui.Text("Status: " .. verifyStatus)
    ImGui.End()
end

addHook(drawKeyWindow, "onDrawImGui")

local ok, msg = grandfuscator.autocheck()
if ok then
    keyVerified = true
    startMainScript()
else
    verifyStatus = "Auto-check failed. Enter key."
    showKeyWindow = true
end

function startMainScript()
    takeee = true
    savee = false
    AddHook(function(event)
        if event.v1 == "OnConsoleMessage" and event.v2:find("entered.") then
            if takeee == true then
                takeee = false
                takingMode = true
            elseif savee == true then
                savee = false
                droppingMode = true
            end
        end
    end, "OnVariant")

    function takeItem()
        for _, obj in pairs(GetObjectList()) do
            local dx = math.abs(GetLocal().posX - obj.posX)
            local dy = math.abs(GetLocal().posY - obj.posY)
            if dx < 40 and dy < 40 and getItemCount(obj.itemid) < 200 then
                SendPacketRaw(false, {
                    type = 11,
                    value = obj.id,
                    x = obj.posX,
                    y = obj.posY,
                })
            end
        end
    end

    function getItemCount(itemId)
        for _, item in pairs(GetInventory()) do
            if item.id == itemId then
                return item.amount
            end
        end
        return 0
    end

    function dropAll()
        SendPacket(2, "action|drop\n|itemID|" .. itemID)
        SendPacket(2, "action|dialog_return\ndialog_name|drop_item\nitemID|" .. itemID .. "|\ncount|" .. getItemCount(itemID))
    end

    function doTake()
        for _, obj in pairs(GetObjectList()) do
            if obj.itemid == itemID and getItemCount(itemID) ~= 200 then
                local targetY = obj.posY // 32
                local targetX = obj.posX // 32
                repeat
                    if GetLocal().posX // 32 == targetX then
                        if GetLocal().posY // 32 ~= targetY then
                            FindPath(targetX, targetY)
                            Sleep(1000)
                        end
                    else
                        FindPath(targetX, targetY)
                        Sleep(1000)
                    end
                until GetLocal().posX // 32 == targetX and GetLocal().posY // 32 == targetY
                takeItem()
                Sleep(1000)
            end
        end
        if getItemCount(itemID) == 200 then
            savee = true
            SendPacket(3, "action|join_request\nname|" .. saveWorld .. "\ninvitedWorld|0")
        end
    end

    function doDrop()
        Sleep(3000)
        repeat
            if GetLocal().posX // 32 == dropX then
                if GetLocal().posY // 32 ~= dropY then
                    FindPath(dropX, dropY)
                    Sleep(800)
                end
            else
                FindPath(dropX, dropY)
                Sleep(800)
            end
        until GetLocal().posX // 32 == dropX and GetLocal().posY // 32 == dropY
        dropAll()
        Sleep(3000)
        while getItemCount(itemID) > 0 do
            FindPath(dropX - 1, dropY)
            Sleep(800)
            dropY = GetLocal().posY // 32
            dropX = GetLocal().posX // 32
            dropAll()
            Sleep(3000)
        end
        SendPacket(3, "action|join_request\nname|" .. takeWorld .. "\ninvitedWorld|0")
        takeee = true
    end

        Sleep(2000)
        SendPacket(3, "action|join_request\nname|" .. takeWorld .. "\ninvitedWorld|0")
        while true do
            Sleep(2000)
            if droppingMode == true then
                Sleep(2500)
                doDrop()
                droppingMode = false
            else
                if takingMode == true then
                    Sleep(2500)
                    doTake()
                    takingMode = false
                end
            end
        end
end
