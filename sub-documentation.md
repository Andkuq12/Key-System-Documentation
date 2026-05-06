# 🔑 Key Validation Documentation

> Protect your Lua scripts with a key validation.

---
[Full Documentation](https://github.com/Andkuq12/Andkuq12/blob/main/documentation.md)

---

## ⚡ Quick Start — Using the Library (Recommended)

The easiest way to add key validation is with the **Grandfuscator library**.

```lua
local grandfuscator = require("grandfuscator")

grandfuscator.setup("yourusername")

local ok, msg = grandfuscator.checkkey("GRAND-KEY-ABCD1234")
if not ok then
    LogToConsole("Key invalid: " .. msg)
    return
end

-- your script continues here
```

That's it. The library handles saving, loading, and periodic re-checking automatically.

### Library Functions

| Function | Description |
|----------|-------------|
| `grandfuscator.setup(username, options?)` | Set your panel username before calling anything else |
| `grandfuscator.checkkey(key)` | Validate a key. Returns `ok, message` |
| `grandfuscator.autocheck(options?)` | Load saved key from device and validate automatically |
| `grandfuscator.savekey(key?)` | Save key to device (auto-called on success) |
| `grandfuscator.clearkey()` | Delete saved key from device |
| `grandfuscator.Verified()` | Returns `true` if key was validated this session |

### `setup()` Options

```lua
grandfuscator.setup("yourusername", {
    recheck  = 600,            -- re-check interval in seconds (default: 600 = 10 min)
    onExpire = function(msg)   -- called when key expires mid-session
        stopmyscript()          -- replace with your stop function
    end
})
```

### `autocheck()` — Load Saved Key Automatically

If you want the script to remember the user's key between sessions:

```lua
grandfuscator.setup("yourusername", {
    onExpire = function(msg)
        stopmyscript()
    end
})

local ok, msg = grandfuscator.autocheck()
if not ok then
    LogToConsole("Key check failed: " .. msg)
    return
end
-- script continues
```

The library reads the key saved on the device from the previous session. If no key is saved, it returns `false, "Key is empty"`.

### Full Example with Library

```lua
local grandfuscator = require("grandfuscator")

grandfuscator.setup("yourusername", {
    recheck  = 600,
    onExpire = function(msg)
        LogToConsole("[Key] Expired: " .. msg)
        stopmyscript()
    end
})

local ok, msg = grandfuscator.autocheck()
if not ok then
    LogToConsole("[Key] " .. msg)
    sendDialog({
        title   = "Key Required",
        message = "Key is invalid or expired.\n" .. msg ..
                  "\n\nGet a key at: grandfuscator.my.id"
    })
    return
end

LogToConsole("[Key] Valid! Starting script...")
-- your script logic below
```

---

## 📦 Requirements

Your script must run in an environment that provides these functions:

| Function | Purpose |
|----------|---------|
| `fetch(url)` | HTTP GET request, returns string response |
| `Sleep(ms)` | Pause execution in milliseconds |
| `runThread(func)` | Run a function in a separate thread |
| `LogToConsole(msg)` | Print log message to console |
| `sendDialog(tbl)` | Display a dialog to the user |

> These functions are typically available in executors like **GrowLauncher v6/v7**.

---

## 🧱 Manual Integration (Without Library)

If you prefer to write it yourself instead of using the library:

### Step 1 — Define Constants

```lua
local KEY_API       = "https://www.grandfuscator.my.id/api/grandfuscator-keyvalidation"
local YOUR_USERNAME = "yourusername"   -- REPLACE with your panel username
local KEY_RECHECK   = 10 * 60          -- recheck every 10 minutes
```

### Step 2 — Local Key Read/Write

```lua
local paths = {
    "/storage/emulated/0/Android/media/launcher.powerkuy.growlauncher/.mykey.lua",
    "/storage/emulated/0/Android/data/launcher.powerkuy.growlauncher/files/.mykey.lua"
}

function loadSavedKey()
    for _, p in ipairs(paths) do
        local f = io.open(p, "r")
        if f then
            local content = f:read("*all"); f:close()
            local key = content:match("key=(.+)")
            if key then return key:match("^%s*(.-)%s*$") end
        end
    end
    return nil
end

function saveKey(k)
    for _, p in ipairs(paths) do
        local f = io.open(p, "w")
        if f then f:write("key=" .. k); f:close(); return true end
    end
    return false
end
```

### Step 3 — Validation Function

```lua
function validateKey(key)
    if not key or key == "" then return false, "Key is empty" end
    local url = KEY_API .. "?name=" .. YOUR_USERNAME .. "&checkkey=" .. key
    local response, errorMsg = fetch(url)
    if not response then return false, "Connection failed: " .. tostring(errorMsg) end
    if response:find('"valid":true') then return true, "Valid" end
    local message = response:match('"message":"([^"]+)"') or "Invalid key"
    return false, message
end
```

### Step 4 — Initial Check

```lua
local myKey = loadSavedKey() or ""
local ok, msg = validateKey(myKey)

if not ok then
    LogToConsole("[Key] " .. msg)
    sendDialog({
        title   = "Key Required",
        message = "Key is invalid or expired.\nReason: " .. msg ..
                  "\n\nGet a key at:\ngrandfuscator.my.id"
    })
    return
end

saveKey(myKey)
LogToConsole("[Key] Valid! Starting script...")
```

### Step 5 — Periodic Re-check

```lua
local lastCheck = os.time()
runThread(function()
    while true do
        Sleep(60000)
        if os.time() - lastCheck >= KEY_RECHECK then
            lastCheck = os.time()
            local valid, vmsg = validateKey(myKey)
            if not valid then
                LogToConsole("[Key] REVOKED: " .. vmsg)
                stopmyscript()  -- REPLACE with your stop function
                return
            end
        end
    end
end)
```

---

## 📡 API Reference

```
GET https://www.grandfuscator.my.id/api/grandfuscator-keyvalidation
```

| Parameter | Required | Description |
|-----------|----------|-------------|
| `name` | ✅ | Your panel username (case-sensitive) |
| `checkkey` | ✅ | The key to validate |

**Valid response:**
```json
{ "valid": true, "message": "Key is valid", "expiresAt": 1780000000 }
```

**Invalid response:**
```json
{ "valid": false, "message": "Key not found" }
```

---

## 🔑 Key Format

```
GRAND-KEY-XXXXXXXX
```

Examples: `GRAND-KEY-A3F9K2PQ` · `GRAND-KEY-ZX17BCDE`

---

## ❓ FAQ

**Q: Can users run the script without a key?**  
A: No. The script stops at `return` before reaching your main logic.

**Q: Is the key saved automatically?**  
A: Yes — when using the library, the key is saved on success automatically. Manual integration requires calling `saveKey()` yourself.

**Q: How do users get a new key?**  
A: Direct them to your public page URL from the panel → My Key Manager → Public Page.

**Q: What should I replace `stopmyscript()` with?**  
A: Replace it with your actual stop function, e.g. `stopFarming()`. When using the library, pass it as `onExpire` in `setup()`.

---

*Grandfuscator — Lua Key Validation System Documentation*
