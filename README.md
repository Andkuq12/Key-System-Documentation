# 🔑 Key validation Documentation
[Grandfuscator Key Manager Free](https://www.grandfuscator.my.id/?view=freekeymanager)
> **Grandfuscator**  
> Protect your Lua scripts with a key validation system.

---

## Table of Contents

1. [Overview](#overview)
2. [How It Works](#how-it-works)
3. [Setup Guide](#setup-guide)
4. [Using the Library](#using-the-library)
5. [Manual Integration](#manual-integration)
6. [API Reference](#api-reference)
7. [Key Format](#key-format)
8. [Configuration Options](#configuration-options)
9. [Free Tier Limitations](#free-tier-limitations)
10. [Tier Comparison](#tier-comparison)
11. [FAQ](#faq)

---

## Overview

The Key Page system lets you protect your Lua scripts by requiring users to hold a valid key before your script runs. As a **Free tier** user, you get your own:

- A **public page** where users complete Linkvertise tasks and generate their key
- A **private configuration page** where you manage all settings and keys
- A **REST API endpoint** your script calls to validate a key in real-time
- A **Lua library** (`grandfuscator.lua`) that handles everything in one line

All key data is stored privately — only you can see your own keys.

---

## How It Works

```
User opens your Page
        │
        ▼
User completes N Linkvertise tasks  (N = set by you, 1–20)
        │
        ▼
User clicks "Generate My Key"
        │
        ▼
System creates a GRAND-KEY-XXXXXXXX  (valid for X hours, set by you)
        │
        ▼
User pastes the key into your script
        │
        ▼
Script calls the API → API checks → returns { valid: true/false }
        │
        ▼
Script continues or stops based on the result
```

---

## Setup Guide

### Step 1 — Access Your Key Manager

Log in to the panel, then open the sidebar and click **My Key Manager**.

| URL | Purpose |
|-----|---------|
| `?view=freekeypage&id=<username>` | **Public Page** — share this with your users |
| `?view=freekeymanager` | **Configuration Page** — keep this private |

### Step 2 — Configure Your Page

In the **Configuration** tab, fill in:

**Linkverse ID** *(required)* — Your Linkvertise publisher user ID, found in your Linkvertise dashboard URL.

**Linkvertise Anti-Bypass Token** *(optional but recommended)* — Found in Linkvertise → Settings → Anti Bypassing. Handled server-side; no change needed in your Lua script.

**Tasks Required** — Slider from 1 to 20. How many Linkvertise tasks the user must complete.

**Key Duration** — How long each generated key stays valid (1h, 6h, 12h, 24h, 48h, 72h, or custom).

### Step 3 — Share Your Public Page

Copy your **Public Page URL** and share it with your users. The public page handles everything automatically.

### Step 4 — Add Keys Manually

In the **Keys** tab you can manually add keys for specific users.

| Field | Required | Description |
|-------|----------|-------------|
| Key Value | ✅ | The key string |
| Expiry Date | ✅ | Date the key becomes invalid |
| Note | optional | Internal label |

---

## Using the Library

The **Grandfuscator library** is the easiest way to add key validation.

### Options load library
1. using require
```lua
local grandfuscator = require("grandfuscator_lib")
```
2. using load file
```lua
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

local lib = loadlibrary("grandfuscator_lib")
```
3. using fetch 
```lua
local raw = fetch("https://example.com/grandfuscator_lib.lua")
local lib = load(raw)()
```

### Minimal — One Line Check

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

### Auto-load Saved Key

The library can remember the user's key between sessions automatically:

```lua
local grandfuscator = require("grandfuscator")

grandfuscator.setup("yourusername", {
    recheck  = 600,               -- re-validate every 10 minutes
    onExpire = function(msg)      -- called if key expires mid-session
        stopmyscript()             -- replace with your stop function
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

### Library Functions

| Function | Returns | Description |
|----------|---------|-------------|
| `grandfuscator.setup(username, options?)` | — | Set username before calling anything else |
| `grandfuscator.checkkey(key)` | `ok, message` | Validate a specific key string |
| `grandfuscator.autocheck(options?)` | `ok, message` | Load saved key from device and validate |
| `grandfuscator.savekey(key?)` | `bool` | Save key to device (called automatically on success) |
| `grandfuscator.clearkey()` | — | Delete saved key from device |
| `grandfuscator.Verified()` | `bool` | Returns `true` if key was validated this session |

### `setup()` Options Table

```lua
grandfuscator.setup("yourusername", {
    recheck  = 600,            -- seconds between re-checks (0 = disable, default: 600)
    onExpire = function(msg)   -- function called when key expires mid-session
        stopmyscript()
    end
})
```

---

## Manual Integration

If you prefer to write the key system yourself without using the library:

### Step 1 — Constants

```lua
local KEY_API       = "https://www.grandfuscator.my.id/api/grandfuscator-keyvalidation"
local YOUR_USERNAME = "yourusername"   -- ← CHANGE THIS
local KEY_RECHECK   = 10 * 60
```

### Step 2 — Local Key Storage

```lua
local paths = {
    "/storage/emulated/0/Android/media/launcher.powerkuy.growlauncher/.mykey.lua",
    "/storage/emulated/0/Android/data/launcher.powerkuy.growlauncher/files/.mykey.lua"
}

function loadSavedKey()
    for _, p in ipairs(paths) do
        local f = io.open(p, "r")
        if f then
            local s = f:read("*all"); f:close()
            local k = s:match("key=(.+)")
            if k then return k:match("^%s*(.-)%s*$") end
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
    local raw, err = fetch(url)
    if not raw then return false, "Network error: " .. tostring(err) end
    if raw:find('"valid":true') then return true, "OK" end
    return false, (raw:match('"message":"([^"]+)"') or "Invalid key")
end
```

### Step 4 — Initial Check

```lua
local myKey = loadSavedKey() or ""
local ok, msg = validateKey(myKey)

if not ok then
    LogToConsole("[Script] Key check failed: " .. msg)
    sendDialog({
        title   = "Key Required",
        message = "Your key is invalid or expired:\n" .. msg ..
                  "\n\nGet a key at: grandfuscator.my.id"
    })
    return
end

saveKey(myKey)
LogToConsole("[Script] Key OK! Starting...")
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
                LogToConsole("[Script] Key revoked: " .. vmsg)
                stopmyscript()  -- replace with your stop function
                return
            end
        end
    end
end)
```

---

## API Reference

### Endpoint

```
GET https://www.grandfuscator.my.id/api/grandfuscator-keyvalidation
```

### Query Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `name` | ✅ | Your panel username (case-sensitive) |
| `checkkey` | ✅ | The key to validate |

### Example Request

```
https://www.grandfuscator.my.id/api/grandfuscator-keyvalidation?name=yourusername&checkkey=GRAND-KEY-ABCD1234
```

### Responses

**Valid key:**
```json
{
  "valid": true,
  "message": "Key is valid",
  "expiresAt": 1780000000
}
```

**Invalid / expired:**
```json
{ "valid": false, "message": "Key not found" }
```
```json
{ "valid": false, "message": "Key has expired" }
```
```json
{ "valid": false, "message": "Missing parameter: name" }
```

> `expiresAt` is a Unix timestamp in seconds.

---

## Key Format

```
GRAND-KEY-XXXXXXXX
```

Where `XXXXXXXX` is a random 8-character alphanumeric string (uppercase).

```
GRAND-KEY-A3F9K2PQ
GRAND-KEY-ZX17BCDE
GRAND-KEY-90MNRTYV
```

> The `GRAND-KEY-` prefix is fixed for the Free tier. VVIP tier users can set a custom prefix.

---

## Configuration Options

| Setting | Default | Range | Description |
|---------|---------|-------|-------------|
| Linkverse ID | — | — | Your Linkvertise publisher user ID. Required. |
| Anti-Bypass Token | — | — | From Linkvertise → Settings → Anti Bypassing. Optional. |
| Tasks Required | 3 | 1–20 | How many Linkvertise steps the user must complete. |
| Key Duration | 24h | 1h–∞ | How long each generated key remains valid. |

---

## Free Tier Limitations

| Feature | Free Tier | VVIP Tier |
|---------|-----------|-----------|
| Key validation API | ✅ | ✅ |
| Public key page | ✅ | ✅ |
| Manual key management | ✅ | ✅ |
| Linkvertise task system | ✅ | ✅ |
| Anti-bypass token | ✅ | ✅ |
| Grandfuscator Lua library | ✅ | ✅ |
| Custom key prefix | ❌ Fixed: `GRAND-KEY-` | ✅ Custom prefix |
| Discord ID validation | ❌ Not available | ✅ Available |

---

## Tier Comparison

```
Free Tier                         VVIP Tier
─────────────────────────────     ─────────────────────────────────────
Key prefix: GRAND-KEY-XXXX        Key prefix: YOURCOOLNAME-XXXX (custom)
Discord ID check: NO              Discord ID check: YES (optional)
Public page: YES                  Public page: YES
API validation: YES               API validation: YES
Manual keys: YES                  Manual keys: YES + Discord ID per key
Library (grandfuscator.lua): YES  Library (grandfuscator.lua): YES
```

---

## FAQ

**Q: Which is easier — the library or manual integration?**  
A: The library. `grandfuscator.checkkey("GRAND-KEY-XXXX")` is one line vs ~50 lines manually. Use the library unless you need custom behavior.

**Q: Where do users get their key?**  
A: Share your **Public Page URL** (`?view=freekeypage&id=yourusername`). Users complete Linkvertise tasks and receive their key automatically.

**Q: Do I need to manually create a key for every user?**  
A: No. The public page auto-generates keys. Manual keys are only needed when giving a key to someone without Linkvertise.

**Q: What happens when a key expires?**  
A: The API returns `{ "valid": false, "message": "Key has expired" }`. When using the library with `onExpire`, your stop function is called automatically.

**Q: Can users share their key with others?**  
A: With Free tier, keys are not tied to a device or account. Upgrade to **VVIP** and enable Discord ID validation to prevent sharing.

**Q: Is the key data secure?**  
A: Keys are stored in a private database path. The panel owner can only see the count of your keys, not their actual values.

**Q: Does the anti-bypass token affect my Lua script?**  
A: No. It is only used server-side between the web panel and Linkvertise. Your Lua script only calls `grandfuscator-keyvalidation`.

**Q: What is `autocheck()` for?**  
A: It reads the key saved on the user's device from a previous session, so users only need to paste their key once. The library saves it automatically after the first successful check.

---

*Grandfuscator*  
*For support or questions, visit my [website](https://www.grandfuscator.my.id) or join the [Discord](https://discord.gg/fJSftJ7bbB).*
