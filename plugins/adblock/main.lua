local ipPattern = "(%d+)%.(%d+)%.(%d+)%.(%d+)"
local nonAsciiPattern = "[^\x00-\x7F]+"

AddEventHandler("OnPluginStart", function (_)
    config:Create("adblock", {
        immune_flags = "a",
        block_non_ascii = true,
        block_ips = true,
        block_words = true,
        words = {
            "usp","elitegamers", "llg", "1tap", "ndr-pc", "fireon", "arenax", "csro", "fairside", "alphacs",
            "ggez", "epic-gamers", "og-stars", "skz", "jucausii", "toplay", "csgoromania", "nevermore",
            "lunario", "gomania", "leaguecs", "connect", "http", "www"
        },
        allowed_ips = {
            "5.83.147.54"
        }
    })
end)

AddEventHandler("OnRoundStart", function(event) 
    for i = 0, playermanager:GetPlayerCap() - 1 do
        local player = GetPlayer(i)
        if player ~= nil and player:IsValid() and player:CBasePlayerController().Connected == PlayerConnectedState.PlayerConnected then
            HandleBlockedName(player, player:CBasePlayerController().PlayerName)
        end
    end
end)

AddEventHandler("OnPlayerConnectFull", function(event)
    local playerid = event:GetInt("userid")
	local player = GetPlayer(playerid)
	if not player or player:IsFakeClient()  then return end

    HandleBlockedName(player, player:CBasePlayerController().PlayerName)
end)

AddEventHandler("OnClientChat", function(event, playerid, text, teamonly)
    local player = GetPlayer(playerid)
	if not player or config:Fetch("adblock.immune_flags") ~= "" and exports["admins"]:HasFlags(playerid, config:Fetch("adblock.immune_flags")) then return end

    if config:Fetch("adblock.block_non_ascii") == true and text:match(nonAsciiPattern) then
        PrintToAdmins("adblock.non-ascii", "", player:CBasePlayerController().PlayerName, "")

        event:SetReturn(false)
        return EventResult.Stop
    end

    if config:Fetch("adblock.block_ips") == true and text:match(ipPattern) then
        local ips = config:Fetch("adblock.allowed_ips") or {}
        if type(ips) ~= "table" then return end
        
        for _, ip in ipairs(ips) do
            if text:find(ip) then
                return
            end
        end
        PrintToAdmins("adblock.ip", text, player:CBasePlayerController().PlayerName, "")

        event:SetReturn(false)
        return EventResult.Stop
    end

    if config:Fetch("adblock.block_words") == true then
        local words = config:Fetch("adblock.words") or {}
        if type(words) ~= "table" then return end

        for _, word in ipairs(words) do
            if text:lower():find(word) then
                PrintToAdmins("adblock.word", text, player:CBasePlayerController().PlayerName, "")

                event:SetReturn(false)
                return EventResult.Stop
            end
        end
    end

    event:SetReturn(true)
	return EventResult.Continue
end)

function PrintToAdmins(text, msg, name, newName)
    for i = 0, playermanager:GetPlayerCap() - 1 do
        local player = GetPlayer(i)
        if player ~= nil and player:IsValid() and player:CBasePlayerController().Connected == PlayerConnectedState.PlayerConnected and exports["admins"]:HasFlags(i, "a") then
            ReplyToCommand(i, FetchTranslation("adblock.prefix", i), FetchTranslation(text, i):gsub("{text}", msg):gsub("{name}", name):gsub("{newname}", newName))
        end
    end
end

function HandleBlockedName(player, name)
    if config:Fetch("adblock.block_words") == true then
        local words = config:Fetch("adblock.words") or {}
        if type(words) == "table" then
            local filteredName = name
            
            for _, word in ipairs(words) do
                local pattern = ""
                for i = 1, #word do
                    local c = word:sub(i, i)
                    pattern = pattern .. string.format("[%s%s]", c:lower(), c:upper())
                end
                
                filteredName = filteredName:gsub(pattern, "")
            end
            
            if name ~= filteredName then
                player:CBasePlayerController().PlayerName = filteredName
                PrintToAdmins("adblock.renaming", "", name, player:CBasePlayerController().PlayerName)
            end
        end
    end
end


