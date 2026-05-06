takeWorld = "world|id"
saveWorld = "world|id"
dropX, dropY = 9, 52
itemID = 8641

takingMode = false
droppingMode = false






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

local grandfuscator = loadGrandfuscatorLib()
if not grandfuscator then
    LogToConsole("Cannot continue without key library")
    return
end

local USERNAME = "Grandkuq"
grandfuscator.setup(USERNAME, { recheck = 600 })

local ok, msg = grandfuscator.autocheck()
if not ok then
    local keyInput = ""
    local dialog = [[
add_label_with_icon|big|`wKey Required|left|242|
add_spacer|small|
add_textbox|`9Enter your Grandfuscator key:|left|
add_text_input|gf_key|||32|left|
add_spacer|small|
end_dialog|key_dialog|Cancel|Verify|
]]
    SendVariant({ v1 = "OnDialogRequest", v2 = dialog })
    
    local waiting = true
    function onKeyDialog(var)
        if var.v1 == "OnDialogRequest" and var.v2:find("key_dialog") then
            if var.v2:find("Verify") then
                local key = var.v2:match("gf_key|([^|\n]*)")
                if key and key ~= "" then
                    local valid, errMsg = grandfuscator.checkkey(key)
                    if valid then
                        waiting = false
                        LogToConsole("Key accepted.")
                    else
                        LogToConsole("Invalid key: " .. errMsg)
                        sendDialog({ title = "Invalid Key", message = "Key is wrong or expired. Script stopped." })
                        waiting = false
                    end
                end
            elseif var.v2:find("Cancel") then
                waiting = false
                LogToConsole("Key entry cancelled.")
            end
            return true
        end
        return false
    end
    addHook(onKeyDialog, "onVariant")
    
    while waiting do
        Sleep(500)
    end
    
    if not grandfuscator.Verified() then
        LogToConsole("Script stopped: no valid key.")
        return
    end
end

hasAccess = grandfuscator.Verified()
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

if hasAccess == true then
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
else
  LogToConsole("Not registered")
end
