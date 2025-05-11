local socket = require("socket")

local function parseStatusCode(statusLine)
    return tonumber(statusLine:match("HTTP/%d+%.%d+%s(%d%d%d)"))
end

local function httpRequest(host, path, port, method, rawHeaders, data)
    method = method or "GET"
    data = data or ""
    rawHeaders = rawHeaders or ""

    -- Open TCP and connect
    local tcp = assert(socket.tcp())
    tcp:settimeout(5)
    local ok, err = tcp:connect(host, port)
    if not ok then
        return nil, "Connection failed: " .. err
    end

    -- Build request
    local req = method .. " " .. path .. " HTTP/1.1\r\n"
              .. "Host: " .. host .. "\r\n"
              .. rawHeaders
              .. "Connection: close\r\n"  -- Closes the connection after the response
              .. "Content-Length: " .. #data .. "\r\n"
              .. "\r\n" .. data
    tcp:send(req)

    -- Read status line
    local statusLine = assert(tcp:receive("*l"))

    -- Read headers
    local responseHeaders = {}
    while true do
        local line = tcp:receive("*l")
        if not line or line == "" then break end
        local k, v = line:match("^([^:]+):%s*(.+)$")
        if k and v then responseHeaders[k] = v end
    end

    -- Read body based on Content-Length
    local len = tonumber(responseHeaders["Content-Length"]) or 0
    local body = ""
    if len > 0 then
        body = assert(tcp:receive(len))
    end
    tcp:close()

    return statusLine, body, responseHeaders
end

return httpRequest
