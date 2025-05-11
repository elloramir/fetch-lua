-- Copyright 2025 Elloramir.
-- All rights over the MIT license.

local fetch = require("fetch")

fetch("https://example.com", nil, function(res)
    print("Request done with status code:", res.code)
    print("Body Length:", #res.body, "bytes")
    print("Adapter:", res.adapter)

    print("================================")
    for k, v in pairs(res.headers) do
        print(("key %s, value: %s"):format(k, v))
    end

    love.event.quit()
end)

function love.update()
    fetch.update()
end