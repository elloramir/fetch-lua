local ffi = require("ffi")
local wininet = ffi.load("wininet")

ffi.cdef[[
typedef void* HINTERNET;
typedef unsigned long DWORD;
typedef DWORD DWORD_PTR;
typedef const char* LPCSTR;
typedef char* LPSTR;
typedef void* LPVOID;
typedef int BOOL;

HINTERNET InternetOpenA(
  LPCSTR lpszAgent,
  DWORD dwAccessType,
  LPCSTR lpszProxy,
  LPCSTR lpszProxyBypass,
  DWORD dwFlags
);

HINTERNET InternetConnectA(
  HINTERNET hInternet,
  LPCSTR lpszServerName,
  DWORD nServerPort,
  LPCSTR lpszUsername,
  LPCSTR lpszPassword,
  DWORD dwService,
  DWORD dwFlags,
  DWORD_PTR dwContext
);

HINTERNET HttpOpenRequestA(
  HINTERNET hConnect,
  LPCSTR lpszVerb,
  LPCSTR lpszObjectName,
  LPCSTR lpszVersion,
  LPCSTR lpszReferer,
  LPCSTR* lplpszAcceptTypes,
  DWORD dwFlags,
  DWORD_PTR dwContext
);

BOOL HttpSendRequestA(
  HINTERNET hRequest,
  LPCSTR lpszHeaders,
  DWORD dwHeadersLength,
  LPVOID lpOptional,
  DWORD dwOptionalLength
);

BOOL InternetReadFile(
  HINTERNET hFile,
  LPVOID lpBuffer,
  DWORD dwNumberOfBytesToRead,
  DWORD* lpdwNumberOfBytesRead
);

BOOL InternetCloseHandle(
  HINTERNET hInternet
);

BOOL HttpQueryInfoA(
  HINTERNET hRequest,
  DWORD dwInfoLevel,
  LPVOID lpBuffer,
  DWORD* lpdwBufferLength,
  DWORD* lpdwIndex
);

DWORD GetLastError();
]]

local INTERNET_OPEN_TYPE_DIRECT = 1
local INTERNET_SERVICE_HTTP = 3
local INTERNET_FLAG_SECURE = 0x00800000  -- HTTPS
local INTERNET_DEFAULT_HTTPS_PORT = 443
local HTTP_QUERY_STATUS_CODE = 19
local HTTP_QUERY_RAW_HEADERS_CRLF = 22

-- Function to perform an HTTPS request
local function httpsRequest(host, path, method, headers, data)
    method = method or "GET"
    headers = headers or ""
    
    -- Initialize internet session
    local hInternet = wininet.InternetOpenA(
        "LuaJIT/WinINet Client",
        INTERNET_OPEN_TYPE_DIRECT,
        nil,
        nil,
        0
    )
    
    if hInternet == nil then
        return nil, "Failed to initialize WinINet", nil
    end
    
    -- Connect to the server
    local hConnect = wininet.InternetConnectA(
        hInternet,
        host,
        INTERNET_DEFAULT_HTTPS_PORT,
        nil,
        nil,
        INTERNET_SERVICE_HTTP,
        0,
        0
    )
    
    if hConnect == nil then
        wininet.InternetCloseHandle(hInternet)
        return nil, "Failed to connect to server", nil
    end
    
    -- Open the request
    local hRequest = wininet.HttpOpenRequestA(
        hConnect,
        method,
        path,
        nil,
        nil,
        nil,
        INTERNET_FLAG_SECURE,
        0
    )
    
    if hRequest == nil then
        wininet.InternetCloseHandle(hConnect)
        wininet.InternetCloseHandle(hInternet)
        return nil, "Failed to create HTTP request", nil
    end
    
    -- Prepare request body data, if any
    local dataPtr = nil
    local dataLen = 0
    if data and #data > 0 then
        dataLen = #data
        dataPtr = ffi.new("char[?]", dataLen + 1)
        ffi.copy(dataPtr, data, dataLen)
    end
    
    -- Send the request
    local success = wininet.HttpSendRequestA(
        hRequest,
        headers,
        #headers,
        dataPtr,
        dataLen
    )
    
    if success == 0 then
        local errCode = ffi.C.GetLastError()
        wininet.InternetCloseHandle(hRequest)
        wininet.InternetCloseHandle(hConnect)
        wininet.InternetCloseHandle(hInternet)
        return nil, "Failed to send request (Error: " .. errCode .. ")", nil
    end
    
    -- Get status code
    local statusStr = ffi.new("char[16]") -- Buffer for status string
    local statusLen = ffi.new("DWORD[1]", 16)
    local statusIndex = ffi.new("DWORD[1]", 0)
    success = wininet.HttpQueryInfoA(
        hRequest,
        HTTP_QUERY_STATUS_CODE,
        statusStr,
        statusLen,
        statusIndex
    )
    
    local status = 0
    if success == 0 then
        local errCode = ffi.C.GetLastError()
        wininet.InternetCloseHandle(hRequest)
        wininet.InternetCloseHandle(hConnect)
        wininet.InternetCloseHandle(hInternet)
        return nil, "Failed to retrieve status code (Error: " .. errCode .. ")", nil
    else
        status = tonumber(ffi.string(statusStr, statusLen[0])) or 0
    end
    
    -- Validate status code
    if status < 100 or status > 599 then
        wininet.InternetCloseHandle(hRequest)
        wininet.InternetCloseHandle(hConnect)
        wininet.InternetCloseHandle(hInternet)
        return nil, "Invalid status code: " .. status, nil
    end
    
    -- Get response headers
    local headersBuffer = ffi.new("char[8192]")
    local headersLen = ffi.new("DWORD[1]", 8192)
    success = wininet.HttpQueryInfoA(
        hRequest,
        HTTP_QUERY_RAW_HEADERS_CRLF,
        headersBuffer,
        headersLen,
        nil
    )
    
    local responseHeaders = {}
    if success ~= 0 then
        local headersStr = ffi.string(headersBuffer, headersLen[0])
        for line in headersStr:gmatch("[^\r\n]+") do
            local key, value = line:match("^([^:]+):%s*(.+)$")
            if key and value then
                responseHeaders[key] = value
            end
        end
    end
    
    -- Read response body
    local body = ""
    local buffer = ffi.new("char[4096]")
    local bytesRead = ffi.new("DWORD[1]")
    
    while true do
        success = wininet.InternetReadFile(
            hRequest,
            buffer,
            4096,
            bytesRead
        )
        
        if success == 0 or bytesRead[0] == 0 then
            break
        end
        
        body = body .. ffi.string(buffer, bytesRead[0])
    end
    
    -- Free resources
    wininet.InternetCloseHandle(hRequest)
    wininet.InternetCloseHandle(hConnect)
    wininet.InternetCloseHandle(hInternet)
    
    return status, body, responseHeaders
end

return httpsRequest
