local ffi = require("ffi")
local curl = ffi.load("libcurl")

ffi.cdef[[
typedef void* CURL;
typedef void* CURLcode;

CURL curl_easy_init();
CURLcode curl_easy_setopt(CURL handle, int option, ...);
CURLcode curl_easy_perform(CURL handle);
CURLcode curl_easy_cleanup(CURL handle);
]]
