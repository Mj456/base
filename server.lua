

RegisterServerEvent("dev")
AddEventHandler("dev", function(pass, dev)
	if pass == "dev69" then
		if dev == true then
			TriggerClientEvent("chatMessage", -1, "^7[^1DEV^7]", {0,0,0}, "Dev mode enabled!")
		else
			TriggerClientEvent("chatMessage", -1, "^7[^1DEV^7]", {0,0,0}, "Dev mode disabled")
		end
	else
		TriggerClientEvent("chatMessage", source, "^7[^1DEV^7]", {0,0,0}, "Wrong password!")
	end
end)


--Tire Slash--

RegisterServerEvent("SlashTires:TargetClient")
AddEventHandler("SlashTires:TargetClient", function(client, tireIndex)
	TriggerClientEvent("SlashTires:SlashClientTire", client, tireIndex)
end)

RegisterServerEvent("911")
AddEventHandler("911", function(mess)
  TriggerClientEvent("chatMessage", -1, "^7[^4911^7]", {0,0,0,0}, mess)
end)



RegisterServerEvent("rcd")
AddEventHandler("rcd", function(mess)
  TriggerClientEvent("chatMessage", -1, "^7[^1ROBBERY COOLDOWN^7]", {0,0,0,0}, mess)
end)

RegisterServerEvent("advert")
AddEventHandler("advert", function(mess, name)
  TriggerClientEvent("chatMessage", -1, "^7[^9Advert^7] ^7|^3 "..name.." ", {0,0,0,0}, mess)
end)

RegisterServerEvent("discord")
AddEventHandler("discord", function()
  TriggerClientEvent("chatMessage", source, "^6[^8Discord^6]: ^5Join the Discord! ^7| ^2discord.gg/UvAdjRD", {0,0,0,0})
end)



RegisterServerEvent("id")
AddEventHandler("id", function(mess, name)
  TriggerClientEvent("chatMessage", -1, "^7[^1ID ^7] |^7 "..name..": ", {0,0,0,0}, mess)
end)

RegisterServerEvent('3dme:shareDisplay')
AddEventHandler('3dme:shareDisplay', function(text)
	TriggerClientEvent('3dme:triggerDisplay', -1, text, source)
end)

--Tackle--
RegisterServerEvent('Tackle:Server:TacklePlayer')
AddEventHandler('Tackle:Server:TacklePlayer', function(Tackled, ForwardVectorX, ForwardVectorY, ForwardVectorZ, Tackler)
	TriggerClientEvent("Tackle:Client:TacklePlayer", Tackled, ForwardVectorX, ForwardVectorY, ForwardVectorZ, Tackler)
end)


--Tow--
AddEventHandler( 'chatMessage', function( s, n, msg )  
    msg = string.lower(msg)
    if (msg == "/tow") then 
        CancelEvent() 
        TriggerClientEvent('wk:spawnTow', s)
	elseif (msg == "/canceltow") then 
        CancelEvent() 
        TriggerClientEvent('wk:cancelTow', s)
	end
end)


--Jail--




--dv--

AddEventHandler( 'chatMessage', function( source, n, msg )  

    msg = string.lower( msg )
    
    -- Check to see if a client typed in /dv
    if ( msg == "/dv" or msg == "/delveh" ) then 
    
        -- Cancel the chat message event (stop the server from posting the message)
        CancelEvent() 

        -- Trigger the client event 
        TriggerClientEvent( 'wk:deleteVehicle', source )
    end
end )


--News Camera--

RegisterCommand("cam", function(source, args, raw)
    local src = source
    TriggerClientEvent("Cam:ToggleCam", src)
end)

RegisterCommand("bmic", function(source, args, raw)
    local src = source
    TriggerClientEvent("Mic:ToggleBMic", src)
end)

RegisterCommand("mic", function(source, args, raw)
    local src = source
    TriggerClientEvent("Mic:ToggleMic", src)
end)

--Player Tow--

RegisterCommand('ptow', function(source, args)
	TriggerClientEvent("asser:tow", source)
end, false)

-- Train --


PlayerCount = 0
list = {}


RegisterServerEvent("hardcap:playerActivated")
RegisterServerEvent("playerDropped")

function ActivateTrain ()
	if (PlayerCount) == 1 then
		TriggerClientEvent('StartTrain', GetHostId())
	else
		SetTimeout(15000,ActivateTrain)
	end
end

--snippet from hardcap to make PlayerCount work
-- yes i know i'm lazy
AddEventHandler('hardcap:playerActivated', function()
  if not list[source] then
    PlayerCount = PlayerCount + 1
    list[source] = true
		if (PlayerCount) == 1 then -- new session?
			SetTimeout(15000,ActivateTrain)
		end
  end
end)

AddEventHandler('playerDropped', function()
  if list[source] then
    PlayerCount = PlayerCount - 1
    list[source] = nil
  end
end)

-- Helicopter --

RegisterServerEvent('heli:spotlight')
AddEventHandler('heli:spotlight', function(state)
	local serverID = source
	TriggerClientEvent('heli:spotlight', -1, serverID, state)
end)


-- Hide Incorrect Commamnds --


AddEventHandler('chatMessage', function(Source, Name, Msg)
    args = stringsplit(Msg, " ")
    CancelEvent()
    if string.find(args[1], "/") then
        local cmd = args[1]
        table.remove(args, 1)
	else
		TriggerClientEvent('chatMessage', -1, Name, { 255, 255, 255 }, Msg)
	end
end)

function stringsplit(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t={} ; i=1
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        t[i] = str
        i = i + 1
    end
    return t
end

RegisterCommand('tweet', function(source, args, rawCommand)
    local playerName = GetPlayerName(source)
    -- local msg = rawCommand:sub(6)
    local msg = table.concat(args, " ")
    local name = GetPlayerName(source)
    fal = name
    TriggerClientEvent('chat:addMessage', -1, {
        template = '<div style="padding: 0.5vw; margin-right: auto; background-color: rgba(28, 160, 242, 0.7); border-radius: 5px; text-overflow: wrap; word-wrap: break-word; margin-right: 10px; margin-bottom: 10px; display: inline-block;"><i class="twitter"></i> @{0}: {1}</div>',
        args = { fal, msg }
    })
end)

RegisterCommand('ooc', function(source, args, rawCommand)
    local playerName = GetPlayerName(source)
    -- local msg = rawCommand:sub(6)
    local msg = table.concat(args, " ")
    local name = GetPlayerName(source)
    fal = name
    TriggerClientEvent('chat:addMessage', -1, {
        template = '<div style="padding: 0.5vw; margin-right: auto; background-color: rgba(255, 128, 0, 0.7); border-radius: 5px; text-overflow: wrap; word-wrap: break-word; margin-right: 10px; margin-bottom: 10px; display: inline-block;"><i class="ooc"></i>OOC Chat | {0}: {1}</div>',
        args = { fal, msg }
    })
end, false)

RegisterCommand('tow', function(source, args, rawCommand)
    local playerName = GetPlayerName(source)
    -- local msg = rawCommand:sub(6)
    local msg = table.concat(args, " ")
    local name = GetPlayerName(source)
    fal = name
    TriggerClientEvent('chat:addMessage', -1, {
        template = '<div style="padding: 0.5vw; margin-right: auto; background-color: rgba(157, 76, 255, 0.7); border-radius: 5px; text-overflow: wrap; word-wrap: break-word; margin-right: 10px; margin-bottom: 10px; display: inline-block;"><i class="tow"></i>Tow | {0}: {1}</div>',
        args = { fal, msg }
    })
end, false)

RegisterCommand('towr', function(source, args, rawCommand)
    local playerName = GetPlayerName(source)
    -- local msg = rawCommand:sub(6)
    local msg = table.concat(args, " ")
    local name = GetPlayerName(source)
    fal = name
    TriggerClientEvent('chat:addMessage', -1, {
        template = '<div style="padding: 0.5vw; margin-right: auto; background-color: rgba(157, 76, 255, 0.7); border-radius: 5px; text-overflow: wrap; word-wrap: break-word; margin-right: 10px; margin-bottom: 10px; display: inline-block;"><i class="towr"></i>Tow Response | {0}: {1}</div>',
        args = { fal, msg }
    })
end, false)



-- Revive 
AddEventHandler('chatMessage', function(from,name,message)
    if(message:sub(1,1) == "/") then

        local args = stringsplit(message, " ")
        local cmd = args[1]


        if (cmd == "/respawn") then
            CancelEvent()
            TriggerClientEvent('RPD:allowRespawn', from)
        end

        if (cmd == "/toggleDeath") then
            CancelEvent()
            TriggerClientEvent('RPD:toggleDeath', from)
        end

        if (cmd == "/revive") then
            CancelEvent()

            if (args[2] ~= nil) then
                local playerID = tonumber(args[2])

                if(playerID == nil or playerID == 0 or GetPlayerName(playerID) == nil) then
                    TriggerClientEvent('chatMessage', from, "RPDeath", {200,0,0} , "Invalid PlayerID")
                    return
                end

                TriggerClientEvent('RPD:allowRevive', playerID, from)

                TriggerClientEvent('chatMessage', from, "RPDeath", {200,0,0} , "Player revived")
            else
                TriggerClientEvent('RPD:allowRevive', from, from)
            end
        end
    end
end)


-- String splits by the separator.
function stringsplit(inputstr, sep)
    if sep == nil then
            sep = "%s"
    end
    local t={} ; i=1
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
            t[i] = str
            i = i + 1
    end
    return t
end
