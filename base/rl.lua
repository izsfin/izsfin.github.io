-- [[ base/rl ]]
return function(sUA)
    local req = request or syn.request or http_request
    local sl = function(url)
        return req({
            Url = url,
            Method = "GET",
            Headers = { ["User-Agent"] = sUA }
        }).Body
    end
    return sl, request, syn.request, http_request
end