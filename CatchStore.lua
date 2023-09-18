-- CatchStore
-- by devpixels (devynawy)

function CatchStoreLib()
    local playercs = {}
    local csroot = {
        version = "1",
        OnAutosaved = {},
        AutosaveRate = 3,
    }

    print("CatchStore v"..csroot.version)
    print("By devynawy")

    local function stringStarts(str,sta)
        return string.sub(str,1,string.len(sta))==sta
    end

    local function isJson(str)
        local status = pcall(function () json.parse(str) end)
        return status
    end

    function csroot:CreateDS(player, prefix)
        local csModule = {
            cached = {},
            changes = {},
            updatedKeys = {},
            backupCount = 0,
            usingBackup = false
        }
    
        local ds = Datastore:GetDatastore(prefix..player.UserID)
        while ds.Loading do
            wait()
        end

        playercs[player.UserID] = {
            ds = ds,
            csModule = csModule
        }
    
        function csModule:Get(key, defaultValue)
            if csModule.cached[key] then
                return csModule.cached[key]
            else
                local requesting = true
                local resSuccess = nil
                local resValue = nil
                local resErr = nil
                local fetchedFromWeb = true
                local curBackup = csModule.backupCount
                
                while true do
                    requesting = true
                    resSuccess = nil
                    resValue = nil
                    resErr = nil
    
                    ds:Get(key, function(value, success, err)
                        resSuccess = success
                        resErr = err
                        resValue = value
                        requesting = false
                    end)
    
                    while true do
                        if not requesting then
                            break
                        end
                        wait(0)
                    end
    
                    -- Check error codes
                    if resSuccess == false then
                        if stringStarts(resErr, "No value for key") then
                            resValue = defaultValue
                            fetchedFromWeb = false
                            resSuccess = true
                        end
    
                        if stringStarts(resErr, "Too many read requests") then
                            wait(2)
                        end
                    end

                    if csModule.backupCount ~= 0 then
                        if curBackup <= 0 then
                            resValue = defaultValue
                            fetchedFromWeb = false
                            resSuccess = true
                            break
                        end
                    end
                    
                    if resSuccess then
                        csModule.usingBackup = false
                        break
                    else
                        if csModule.backupCount ~= 0 then
                            curBackup = curBackup - 1
                            csModule.usingBackup = true
                        end
                    end
                end

                if type(resValue) == "string" and game.GameID ~= 0 and fetchedFromWeb then
                    if stringStarts(resValue, '"') then
                        -- Remove faulty symbols
                        resValue = string.gsub(resValue, "\\", "")
                        resValue = string.sub(resValue, 2)
                        resValue = string.sub(resValue, 1, -2)
                    end
                end

                if isJson(resValue) then
                    resValue = json.parse(resValue)
                end
    
                csModule.cached[key] = resValue
                return resValue
            end
        end
    
        function csModule:Set(key, value)
            local resValue = value

            if isJson(resValue) then
                resValue = json.parse(resValue)
            end

            if csModule.cached[key] and csModule.cached[key] ~= resValue then
                table.insert(csModule.updatedKeys, key)
            end
            csModule.cached[key] = resValue
        end

        function csModule:SetBackup(count)
            csModule.backupCount = count
        end

        function csModule:ClearBackup()
            csModule.backupCount = 0
            csModule.usingBackup = false
        end

        function csModule:Update(key, value)
            if type(value) ~= "table" then
                print("[CatchStore WARN] csModule:update : Cannot update because the value type is not a table")
                return
            end

            if type(csModule.cached[key]) ~= "table" then
                print("[CatchStore WARN] csModule:update : Cannot update because the ORIGIN value type is not a table")
                return
            end

            for k,v in pairs(value) do
                csModule.cached[key][k] = v
            end

            table.insert(csModule.updatedKeys, key)
        end
    
        function csModule:Increase(key, value)
            if tonumber(csModule.cached[key]) ~= nil then
                csModule.cached[key] = csModule.cached[key] + value

                table.insert(csModule.updatedKeys, key)
            else
                print("[CatchStore WARN] csModule:increase : Cannot Increase because the value type is not a number")
            end
        end

        function csModule:Save()
            csroot:ForceSave(player)
        end
    
        return csModule
    end

    game["Players"].PlayerRemoved:Connect(function (player)
        csroot:ForceSave(player)
        playercs[player.UserID] = nil
    end)

    local autosaveCallbacks = {}

    -- Autosave
    spawn(function()
        while true do
            local plrcount = #game["Players"]:GetPlayers()
            local waitSec = ((60 / (30 + (10 * plrcount))) * plrcount) * csroot.AutosaveRate
            wait(waitSec)

            for i, p in pairs(game["Players"]:GetPlayers()) do
                csroot:ForceSave(p)
            end

            for k,v in pairs(autosaveCallbacks) do
                if v then
                    k()
                end
            end
        end
    end)

    function csroot.OnAutosaved:Connect(callback)
        autosaveCallbacks[callback] = true
    end

    function csroot.OnAutosaved:Disconnect(callback)
        autosaveCallbacks[callback] = false
    end

    function csroot:ForceSave(player)
        if playercs[player.UserID] then
            for kz,key in pairs(playercs[player.UserID].csModule.updatedKeys) do
                local ds = playercs[player.UserID].ds

                while true do
                    local requesting = true
                    local resSuccess = nil
                    local resErr = nil
                    local valueTarget = playercs[player.UserID].csModule.cached[key]

                    if type(valueTarget) == "table" then
                        valueTarget = json.serialize(valueTarget)
                    end

                    ds:Set(key, valueTarget, function(success, err)
                        resSuccess = success
                        resErr = err
                        requesting = false
                    end)
                
                    while true do
                        if not requesting then
                            break
                        end
                        wait(0)
                    end
    
                    -- Check error codes
                    if resSuccess == false then
                        if stringStarts(resErr, "Invalid value type") then
                            break
                        end
    
                        if stringStarts(resErr, "Too many write requests") then
                            wait(2)
                        end
                    end
                    
                    if resSuccess then
                        break
                    end
                end

                playercs[player.UserID].csModule.updatedKeys[kz] = nil
            end
        end
    end

    return csroot
end