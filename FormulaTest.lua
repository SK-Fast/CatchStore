wait(1)
local saveRate = 3

for plrCount = 1,35,1 do

    maxApiCalls = (30 + (10 * plrCount))
    apiCalls = maxApiCalls
    secBeforeReset = 60

    function forumlar()
        return (60/(30 + 10 * plrCount) * plrCount * saveRate)
    end

    for i = 1,120,1 do
        local p = forumlar()
        print("INTERVAL ", p)
        if apiCalls < 0 then
            print("<color=red>Ran out of api calls on: </color>", plrCount)
            break
        end
        apiCalls = apiCalls - plrCount
        secBeforeReset = secBeforeReset - p
        if secBeforeReset <= 0 then
            print("RESET")
            apiCalls = maxApiCalls
            secBeforeReset = 60
        end
        if i >= 120 then
            print("Test successfull for player count:", plrCount)
            break
        end
        print("Save successful!", apiCalls, "/", maxApiCalls, "left")
    end

    wait(0)
end