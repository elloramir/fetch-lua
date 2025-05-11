### Fetch Lua

 Lua only, multi-platform HTTP/HTTPS client for LÖVE games

**Key Features:**
- Cross-platform support for Windows (via WinINet) and Linux (via cURL).
- Fallback to LuaSocket for HTTP requests on other platforms (e.g., macOS).
- Easy integration with LÖVE games without the need for additional dependencies.
- Non-blocking HTTP requests to avoid blocking the game loop.

### Example
```lua
local fetch = require("fetch")
local opts = { }

-- default options values:
-- opts.headers = {}
-- opts.method = "GET"
-- opts.data = nil

fetch("https://google.com", opts, function(res)
    print(res.code) -- status number
    print(res.headers) -- table key/value
    print(res.body) -- raw string with the respose
    print(res.adapter) -- how the request was made
end)

function love.update()
    fetch.update()
end
```