local cwd = ...
local sys = require("love.system")
local adapter = { ["Windows"] = "winnet", ["Linux"] = "curl", } 
local httpsRequest = require(cwd .. adapter [ sys.getOS() ])

local requestChannel = love.thread.getChannel("fetch_request")
local responseChannel = love.thread.getChannel("fetch_response")

local function hostFromURL(url)
    local host = url:match("^https?://([^/]+)") or url:match("^[^/]+")
    return host
end

local function pathFromURL(url)
    local path = url:match("^https?://[^/]+(/.*)$") or "/"
    return path
end

local function encodeHeader(headers)
    headers = headers or {}
    local headerStr = ""
    for key, value in pairs(headers) do
        headerStr = headerStr .. key .. ": " .. value .. "\r\n"
    end
    return headerStr
end

while true do
    local message = requestChannel:demand()
    local url = message.address
    local options = message.options or {}
    
    -- Extract host and path from the URL
    local host = hostFromURL(url)
    local path = pathFromURL(url)
    
    local method = (options.method or "GET"):upper()
    local headers = encodeHeader(options.headers)
    local data = options.data or ""
    
    -- Perform the request
    local status, body, responseHeaders = httpsRequest(host, path, method, headers, data)
    
    -- Once done, send the response back to the channel
    responseChannel:push({
        id = message.id,
        code = status,
        body = body,
        headers = responseHeaders
    })
end
