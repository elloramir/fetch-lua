local fetch = require("fetch")

local images = {}
local timer = 0
local fetchInterval = 1

function love.update(dt)
    timer = timer + dt

    if timer >= fetchInterval then
        timer = timer - fetchInterval

        -- Fetch cat image URL
        fetch("https://api.thecatapi.com/v1/images/search", {
            method = "GET",
            headers = {["Accept"] = "application/json"}
        }, function(response)
            if response.code == 200 then
                local url = response.body:match('"url":"(.-)"')
                if url then
                    -- Fetch image from the URL
                    fetch(url, {
                        method = "GET",
                        headers = {["Accept"] = "image/*"}
                    }, function(imgResponse)
                        if imgResponse.code == 200 then
                            local success, image = pcall(function()
                                local imgData = love.image.newImageData(love.filesystem.newFileData(imgResponse.body, "cat.jpg"))
                                return love.graphics.newImage(imgData)
                            end)
                            if success then
                                table.insert(images, {texture = image, time = love.timer.getTime()})
                            end
                        end
                    end)
                end
            end
        end)
    end

    -- Update pending fetches
    fetch.update()
end

function love.draw()
    local x, y = 10, 10
    local maxWidth, spacing = 200, 10

    for _, img in ipairs(images) do
        if img.texture then
            local scale = maxWidth / img.texture:getWidth()
            love.graphics.draw(img.texture, x, y, 0, scale, scale)

            y = y + img.texture:getHeight() * scale + spacing
            if y > love.graphics.getHeight() - 100 then
                y, x = 10, x + maxWidth + spacing
            end
        end
    end

    love.graphics.print("Images: " .. #images, 10, love.graphics.getHeight() - 30)
end

function love.keypressed(key)
    if key == "space" then
        -- Clear images
        for _, img in ipairs(images) do
            if img.texture then img.texture:release() end
        end
        images = {}
    end
end
