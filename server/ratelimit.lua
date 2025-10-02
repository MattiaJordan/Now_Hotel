-- server/ratelimit.lua
local EVENT_LIMITS = {}

local function rateLimit(eventName)
    local limits = EVENT_LIMITS[eventName] or { limit = 5, lastCalled = {} }
    return function(playerId)
        local currentTime = os.time()
        local lastCalledTime = limits.lastCalled[playerId] or 0
        if currentTime - lastCalledTime < limits.limit then
            return false -- Rate limit exceeded
        end
        limits.lastCalled[playerId] = currentTime
        return true
    end
end

-- Wrap RegisterNetEvent to apply rate limits
local function RegisterLimitedNetEvent(eventName)
    local limitedFunction = rateLimit(eventName)
    RegisterNetEvent(eventName, function(...) 
        local playerId = source
        if limitedFunction(playerId) then
            -- Execute original event
            TriggerEvent(eventName, ...)
        else
            print("Rate limit exceeded for event: " .. eventName)
        end
    end)
end

-- Clean up on player drop
AddEventHandler('playerDropped', function() 
    for eventName, _ in pairs(EVENT_LIMITS) do
        EVENT_LIMITS[eventName].lastCalled[source] = nil
    end
end