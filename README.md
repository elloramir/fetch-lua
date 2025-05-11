### Fetch Lua

DLL free, multi-platform HTTP client for LÖVE games

Perform https requests directly from your game without external code (other than lua). 
Works on Windows (via WinINet) and Linux (via cURL).

### Example
```lua
local fetch = require("fetch")

fetch("https://google.com", nil, function(res)
	print(res.status)
end)

if code == 202 then
	print("Body len: ", #body)
end

function love.update()
	fetch.update()
end
```
