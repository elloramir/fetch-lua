local fetch = require("fetch")

local catImages = {}
local catTimer = 0
local catFetchInterval = 1
local maxImagesPerRow = 5
local imageSize = 200

local function fetchRandomCat()
    fetch("https://api.thecatapi.com/v1/images/search", { method = "GET", headers = {["Accept"] = "application/json"} }, function(res)
        if res.code == 200 then
            local url = res.body:match('"url":"(.-)"')
            if url then
                fetch(url, { method = "GET", headers = {["Accept"] = "image/*"} }, function(imgRes)
                    if imgRes.code == 200 then
                        local status, img = pcall(function()
                            local imgData = love.filesystem.newFileData(imgRes.body, "cat.jpg")
                            return love.graphics.newImage(love.image.newImageData(imgData))
                        end)
                        if status then
                            table.insert(catImages, img)
                            if #catImages > 10 then table.remove(catImages, 1) end
                        end
                    end
                end)
            end
        end
    end)
end

local tests = {
    {name = "GET request to JSON API", func = function(callback)
        fetch("https://api.thecatapi.com/v1/images/search", { method = "GET", headers = {["Accept"] = "application/json"} }, function(res)
            callback(res.code == 200 and res.body:find('"url":"') ~= nil)
        end)
    end},
    {name = "GET request to image", func = function(callback)
        fetch("https://http.cat/200.jpg", { method = "GET", headers = {["Accept"] = "image/*"} }, function(res)
            callback(res.code == 200 and #res.body > 1000)
        end)
    end},
    {name = "404 Not Found test", func = function(callback)
        fetch("https://google.com/alskdjaosida98sd79as87d", { method = "GET" }, function(res)
            callback(res.code == 404)
        end)
    end},
    {name = "HTTPS connection test", func = function(callback)
        fetch("https://www.google.com", { method = "GET" }, function(res)
            callback(res.code ~= nil)
        end)
    end}
}

local currentTest = 1
local testResults = {}
local testing = true
local testStartTime = 0

local function runNextTest()
    if currentTest > #tests then
        testing = false
        return
    end
    testStartTime = love.timer.getTime()
    tests[currentTest].func(function(success)
        testResults[currentTest] = {name = tests[currentTest].name, passed = success, time = love.timer.getTime() - testStartTime}
        currentTest = currentTest + 1
        runNextTest()
    end)
end

function love.load()
    runNextTest()
end

function love.update(dt)
    fetch.update()
    if not testing then
        catTimer = catTimer + dt
        if catTimer >= catFetchInterval then
            catTimer = 0
            fetchRandomCat()
        end
    end
end

function love.draw()
    local xOffset, yOffset = 50, 50
    local rowHeight = 220
    for i, img in ipairs(catImages) do
        local scale = math.min(imageSize / img:getWidth(), imageSize / img:getHeight())
        local row = math.floor((i - 1) / maxImagesPerRow)
        local col = (i - 1) % maxImagesPerRow
        love.graphics.draw(img, xOffset + col * (imageSize + 10), yOffset + row * rowHeight, 0, scale, scale)
    end
    local y = 30
    for _, result in ipairs(testResults) do
        love.graphics.setColor(result.passed and {0, 1, 0} or {1, 0, 0})
        love.graphics.print(string.format("%s: %s (%.2fs)", result.name, result.passed and "PASS" or "FAIL", result.time), 20, y)
        y = y + 25
    end
    if testing then
        love.graphics.setColor(1, 1, 0)
        love.graphics.print("Testing... " .. currentTest .. "/" .. #tests, 20, y)
    else
        love.graphics.setColor(0, 1, 1)
        local passed = 0
        for _, r in ipairs(testResults) do if r.passed then passed = passed + 1 end end
        love.graphics.print(string.format("Tests complete! %d/%d passed", passed, #tests), 20, y)
    end
    love.graphics.setColor(1, 1, 1)
end
