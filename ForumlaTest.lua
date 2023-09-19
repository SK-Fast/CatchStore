wait(1)
local plrCount = 100
local saveRate = 3
local tries = 200

local maxApiCalls = (30 + (10 * plrCount))
local apiCalls = maxApiCalls
local secBeforeReset = 60

function forumlar()
    return (60/(30 + 10 * plrCount) * plrCount * saveRate)
end

for i = 1,tries,1 do
    local p = forumlar()
    print("INTERVAL ", p)
    wait(0)
    if apiCalls < 0 then
        print("<color=red>Ran out of api calls</color>")
        break
    end
    apiCalls = apiCalls - plrCount
    secBeforeReset = secBeforeReset - p
    if secBeforeReset <= 0 then
        print("RESET")
        apiCalls = maxApiCalls
        secBeforeReset = 60
    end
    if i >= tries then
        print("Test successfull, PASS!!")
        break
    end
    print("Save successful!", apiCalls, "/", maxApiCalls, "left")
end