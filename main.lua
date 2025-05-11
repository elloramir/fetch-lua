local fetch = require("fetch")

fetch("https://google.com", nil, function(res)
    print(res.code)
end)

function love.update()
    fetch.update()
end