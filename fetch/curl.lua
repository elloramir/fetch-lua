local ffi = require("ffi")
local curl = ffi.load("libcurl")

ffi.cdef[[
typedef void* CURL;
typedef void* CURLcode;

CURL curl_easy_init();
CURLcode curl_easy_setopt(CURL handle, int option, ...);
CURLcode curl_easy_perform(CURL handle);
CURLcode curl_easy_cleanup(CURL handle);

#define CURLOPT_URL 10002
#define CURLOPT_HTTPHEADER 10023
#define CURLOPT_POSTFIELDS 10015
#define CURLOPT_SSL_VERIFYPEER 64
#define CURLOPT_FOLLOWLOCATION 52
#define CURLOPT_WRITEFUNCTION 20011
#define CURLOPT_WRITEDATA 10001
]]

-- Function to perform an HTTPS request using libcurl
local function httpsRequest(host, path, method, headers, data)
    method = method or "GET"
    headers = headers or ""
    
    -- Initialize curl
    local curlHandle = curl.curl_easy_init()
    if curlHandle == nil then
        return nil, "Failed to initialize libcurl", nil
    end
    
    -- Set URL
    local url = host .. path
    local res = curl.curl_easy_setopt(curlHandle,  CURLOPT_URL, url)
    if res ~= 0 then
        curl.curl_easy_cleanup(curlHandle)
        return nil, "Failed to set URL", nil
    end
    
    -- Set SSL verification (disabling for simplicity)
    res = curl.curl_easy_setopt(curlHandle, CURLOPT_SSL_VERIFYPEER, 0)
    if res ~= 0 then
        curl.curl_easy_cleanup(curlHandle)
        return nil, "Failed to set SSL verification", nil
    end
    
    -- Set method (POST or GET)
    if method == "POST" then
        res = curl.curl_easy_setopt(curlHandle, CURLOPT_POSTFIELDS, data)
        if res ~= 0 then
            curl.curl_easy_cleanup(curlHandle)
            return nil, "Failed to set POST data", nil
        end
    end
    
    -- Set headers
    if headers and #headers > 0 then
        local headerList = curl.curl_slist_append(nil, headers)
        res = curl.curl_easy_setopt(curlHandle, CURLOPT_HTTPHEADER, headerList)
        if res ~= 0 then
            curl.curl_easy_cleanup(curlHandle)
            return nil, "Failed to set headers", nil
        end
    end
    
    -- Perform the request
    res = curl.curl_easy_perform(curlHandle)
    if res ~= 0 then
        curl.curl_easy_cleanup(curlHandle)
        return nil, "Failed to perform request", nil
    end
    
    -- Read the response body
    local body = ""
    local function writeCallback(ptr, size, nmemb, userdata)
        local data = ffi.string(ptr, size * nmemb)
        userdata = userdata .. data
        return size * nmemb
    end
    
    res = curl.curl_easy_setopt(curlHandle, CURLOPT_WRITEFUNCTION, writeCallback)
    res = curl.curl_easy_setopt(curlHandle, CURLOPT_WRITEDATA, body)
    if res ~= 0 then
        curl.curl_easy_cleanup(curlHandle)
        return nil, "Failed to set write callback", nil
    end

    -- Cleanup
    curl.curl_easy_cleanup(curlHandle)

    return 200, body, {}  -- Assuming status 200 for simplicity
end

return httpsRequest
