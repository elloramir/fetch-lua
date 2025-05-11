### Fetch Lua

DLL free, multi-platform HTTP client for LÖVE games

Perform HTTPS requests directly from your game without external code (other than Lua).  
Works on Windows (via WinINet) and Linux (via cURL). Includes a fallback to LuaSocket for HTTP requests if not on Windows or Linux.

**Key Features:**
- Cross-platform support for Windows (via WinINet) and Linux (via cURL).
- Fallback to LuaSocket for HTTP requests on other platforms (e.g., macOS).
- Easy integration with LÖVE games without the need for additional dependencies.
- Non-blocking HTTP requests to avoid blocking the game loop.
- Handles image fetching and display, with retries on error.

### Example
```lua
local fetch = require("fetch")

fetch("https://google.com", nil, function(res)
    print(res.status)
end)

function love.update()
    fetch.update()
end
```