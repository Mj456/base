--Chat Commands--

-- [ME] -- 

local color = {r = 255, g = 255, b = 255, alpha = 255} -- Color of the text 
local font = 0 -- Font of the text
local time = 6500 -- Duration of the display of the text : 1000ms = 1sec
local Displaying2 = 1

RegisterCommand('me', function(source, args)
    local text = '' -- edit here if you want to change the language : EN: the person / FR: la personne
    for i = 1,#args do
        text = text .. ' ' .. args[i]
    end
    text = text .. ''
    TriggerServerEvent('3dme:shareDisplay', text)
end)

RegisterNetEvent('3dme:triggerDisplay')
AddEventHandler('3dme:triggerDisplay', function(text, source)
    local offset = Displaying2*0.14
    Display(GetPlayerFromServerId(source), text, offset)
end)

function Display(mePlayer, text, offset)
    local displaying = true
    Citizen.CreateThread(function()
        Wait(time)
        displaying = false
    end)
    Citizen.CreateThread(function()
        Displaying2 = Displaying2 + 1
        print(nbrDisplaying)
        while displaying do
            Wait(0)
            local coordsMe = GetEntityCoords(GetPlayerPed(mePlayer), false)
            local coords = GetEntityCoords(PlayerPedId(), false)
            local dist = GetDistanceBetweenCoords(coordsMe['x'], coordsMe['y'], coordsMe['z'], coords['x'], coords['y'], coords['z'], true)
            if dist < 50 then
                DrawText3D(coordsMe['x'], coordsMe['y'], coordsMe['z']+offset, text)
            end
        end
        Displaying2 = Displaying2 - 1
    end)
end

function DrawText3D(x,y,z, text)
	local onScreen,_x,_y=World3dToScreen2d(x,y,z)
	local px,py,pz=table.unpack(GetGameplayCamCoords())
	SetTextScale(0.35, 0.35)
	SetTextFont(4)
	SetTextProportional(1)
	SetTextColour(255, 255, 255, 215)
	SetTextEntry("STRING")
	SetTextCentre(1)
	AddTextComponentString(text)
	DrawText(_x,_y)
	local factor = (string.len(text)) / 370
	DrawRect(_x,_y+0.0125, 0.035+ factor, 0.03, 0, 0, 0, 150)
end

-- [END] --


-- Unlimited Stamina

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		ResetPlayerStamina(PlayerId(-1))
	end
end)

-- END --

-- FALL OVER / SPAM JUMP --

local ragdollChance = 0.03

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		local ped = GetPlayerPed(-1)
		if IsPedRunning(ped) and not IsPedSwimming(ped) and (IsPedRunning(ped) or IsPedSprinting(ped)) and not IsPedClimbing(ped) and not IsPedRagdoll(ped) then
			if not IsPedStill(ped) and not IsPedGettingUp(ped) and not IsPedGettingIntoAVehicle(ped) and not IsPedInCover(ped, 0) and not IsPedStopped(ped) and not IsPedCuffed(ped) then
				local chance = math.random()
				if chance < ragdollChance then
					Citizen.Wait(500)
					ShakeGameplayCam("JOLT_SHAKE", 0.3)
					ShakeGameplayCam("SMALL_EXPLOSION_SHAKE", 0.09)
					SetPedToRagdoll(ped, 5000, 1, 2)
				else
					Citizen.Wait(2000)
				end
			end
		end
	end
end)

-- END --


local mp_pointing = false
local keyPressed = false

local function startPointing()
    local ped = GetPlayerPed(-1)
    RequestAnimDict("anim@mp_point")
    while not HasAnimDictLoaded("anim@mp_point") do
        Wait(0)
    end
    SetPedCurrentWeaponVisible(ped, 0, 1, 1, 1)
    SetPedConfigFlag(ped, 36, 1)
    Citizen.InvokeNative(0x2D537BA194896636, ped, "task_mp_pointing", 0.5, 0, "anim@mp_point", 24)
    RemoveAnimDict("anim@mp_point")
end

local function stopPointing()
    local ped = GetPlayerPed(-1)
    Citizen.InvokeNative(0xD01015C7316AE176, ped, "Stop")
    if not IsPedInjured(ped) then
        ClearPedSecondaryTask(ped)
    end
    if not IsPedInAnyVehicle(ped, 1) then
        SetPedCurrentWeaponVisible(ped, 1, 1, 1, 1)
    end
    SetPedConfigFlag(ped, 36, 0)
    ClearPedSecondaryTask(PlayerPedId())
end

local once = true
local oldval = false
local oldvalped = false

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        if once then
            once = false
        end

        if not keyPressed then
            if IsControlPressed(0, 29) and not mp_pointing and IsPedOnFoot(PlayerPedId()) then
                Wait(200)
                if not IsControlPressed(0, 29) then
                    keyPressed = true
                    startPointing()
                    mp_pointing = true
                else
                    keyPressed = true
                    while IsControlPressed(0, 29) do
                        Wait(50)
                    end
                end
            elseif (IsControlPressed(0, 29) and mp_pointing) or (not IsPedOnFoot(PlayerPedId()) and mp_pointing) then
                keyPressed = true
                mp_pointing = false
                stopPointing()
            end
        end

        if keyPressed then
            if not IsControlPressed(0, 29) then
                keyPressed = false
            end
        end
        if Citizen.InvokeNative(0x921CE12C489C4C41, PlayerPedId()) and not mp_pointing then
            stopPointing()
        end
        if Citizen.InvokeNative(0x921CE12C489C4C41, PlayerPedId()) then
            if not IsPedOnFoot(PlayerPedId()) then
                stopPointing()
            else
                local ped = GetPlayerPed(-1)
                local camPitch = GetGameplayCamRelativePitch()
                if camPitch < -70.0 then
                    camPitch = -70.0
                elseif camPitch > 42.0 then
                    camPitch = 42.0
                end
                camPitch = (camPitch + 70.0) / 112.0

                local camHeading = GetGameplayCamRelativeHeading()
                local cosCamHeading = Cos(camHeading)
                local sinCamHeading = Sin(camHeading)
                if camHeading < -180.0 then
                    camHeading = -180.0
                elseif camHeading > 180.0 then
                    camHeading = 180.0
                end
                camHeading = (camHeading + 180.0) / 360.0

                local blocked = 0
                local nn = 0

                local coords = GetOffsetFromEntityInWorldCoords(ped, (cosCamHeading * -0.2) - (sinCamHeading * (0.4 * camHeading + 0.3)), (sinCamHeading * -0.2) + (cosCamHeading * (0.4 * camHeading + 0.3)), 0.6)
                local ray = Cast_3dRayPointToPoint(coords.x, coords.y, coords.z - 0.2, coords.x, coords.y, coords.z + 0.2, 0.4, 95, ped, 7);
                nn,blocked,coords,coords = GetRaycastResult(ray)

                Citizen.InvokeNative(0xD5BB4025AE449A4E, ped, "Pitch", camPitch)
                Citizen.InvokeNative(0xD5BB4025AE449A4E, ped, "Heading", camHeading * -1.0 + 1.0)
                Citizen.InvokeNative(0xB0A6CFD2C69C1088, ped, "isBlocked", blocked)
                Citizen.InvokeNative(0xB0A6CFD2C69C1088, ped, "isFirstPerson", Citizen.InvokeNative(0xEE778F8C7E1142E2, Citizen.InvokeNative(0x19CAFA3C87F7C2FF)) == 4)

            end
        end
    end
end)






-- Tire Slash Script--


Citizen.CreateThread(function()
    while true do
        local allowedWeapons = {"WEAPON_KNIFE", "WEAPON_BOTTLE", "WEAPON_DAGGER", "WEAPON_HATCHET", "WEAPON_MACHETE", "WEAPON_SWITCHBLADE"}
        local player = PlayerId()
        local plyPed = GetPlayerPed(player)
        local vehicle = GetClosestVehicleToPlayer()
        local animDict = "melee@knife@streamed_core_fps"
        local animName = "ground_attack_on_spot"
        if vehicle ~= 0 then
            if CanUseWeapon(allowedWeapons) then
                local closestTire = GetClosestVehicleTire(vehicle)
                if closestTire ~= nil then
                    
                    if IsVehicleTyreBurst(vehicle, closestTire.tireIndex, 0) == false then
                        Draw3DText(closestTire.bonePos.x, closestTire.bonePos.y, closestTire.bonePos.z, tostring("~r~[E] SLASH TIRE"))
                        if IsControlJustPressed(1, 38) then

                            RequestAnimDict(animDict)
                            while not HasAnimDictLoaded(animDict) do
                                Citizen.Wait(100)
                            end

                            local animDuration = GetAnimDuration(animDict, animName)
                            TaskPlayAnim(plyPed, animDict, animName, 8.0, -8.0, animDuration, 15, 1.0, 0, 0, 0)
                            Citizen.Wait((animDuration / 2) * 1000)

                            local driverOfVehicle = GetDriverOfVehicle(vehicle)
                            local driverServer = GetPlayerServerId(driverOfVehicle)

                            if driverServer == 0 then
                                SetVehicleTyreBurst(vehicle, closestTire.tireIndex, 0, 100.0)
                            else
                                TriggerServerEvent("SlashTires:TargetClient", driverServer, closestTire.tireIndex)
                            end
                            Citizen.Wait((animDuration / 2) * 1000)
                            ClearPedTasksImmediately(plyPed)
                        end
                    end
                end
            end
        end
        Citizen.Wait(0)
    end
end)

RegisterNetEvent("SlashTires:SlashClientTire")
AddEventHandler("SlashTires:SlashClientTire", function(tireIndex)
    TriggerEvent("chatMessage", "^1A player is trying to slash your tire")
    local player = PlayerId()
    local plyPed = GetPlayerPed(player)
    local vehicle = GetVehiclePedIsIn(plyPed, false)
    SetVehicleTyreBurst(vehicle, tireIndex, 0, 100.0)
end)

function GetDriverOfVehicle(vehicle)
    local dPed = GetPedInVehicleSeat(vehicle, -1)
    for a = 0, 32 do
        if dPed == GetPlayerPed(a) then
            return a
        end
    end
    return -1
end

function CanUseWeapon(allowedWeapons)
    local player = PlayerId()
    local plyPed = GetPlayerPed(player)
    local plyCurrentWeapon = GetSelectedPedWeapon(plyPed)
    for a = 1, #allowedWeapons do
        if GetHashKey(allowedWeapons[a]) == plyCurrentWeapon then
            return true
        end
    end
    return false
end

function GetClosestVehicleToPlayer()
    local player = PlayerId()
    local plyPed = GetPlayerPed(player)
    local plyPos = GetEntityCoords(plyPed, false)
    local plyOffset = GetOffsetFromEntityInWorldCoords(plyPed, 0.0, 1.0, 0.0)
    local radius = 3.0
    local rayHandle = StartShapeTestCapsule(plyPos.x, plyPos.y, plyPos.z, plyOffset.x, plyOffset.y, plyOffset.z, radius, 10, plyPed, 7)
    local _, _, _, _, vehicle = GetShapeTestResult(rayHandle)
    return vehicle
end

function GetClosestVehicleTire(vehicle)
    local tireBones = {"wheel_lf", "wheel_rf", "wheel_lm1", "wheel_rm1", "wheel_lm2", "wheel_rm2", "wheel_lm3", "wheel_rm3", "wheel_lr", "wheel_rr"}
    local tireIndex = {
        ["wheel_lf"] = 0,
        ["wheel_rf"] = 1,
        ["wheel_lm1"] = 2,
        ["wheel_rm1"] = 3,
        ["wheel_lm2"] = 45,
        ["wheel_rm2"] = 47,
        ["wheel_lm3"] = 46,
        ["wheel_rm3"] = 48,
        ["wheel_lr"] = 4,
        ["wheel_rr"] = 5,
    }
    local player = PlayerId()
    local plyPed = GetPlayerPed(player)
    local plyPos = GetEntityCoords(plyPed, false)
    local minDistance = 1.0
    local closestTire = nil
    
    for a = 1, #tireBones do
        local bonePos = GetWorldPositionOfEntityBone(vehicle, GetEntityBoneIndexByName(vehicle, tireBones[a]))
        local distance = Vdist(plyPos.x, plyPos.y, plyPos.z, bonePos.x, bonePos.y, bonePos.z)

        if closestTire == nil then
            if distance <= minDistance then
                closestTire = {bone = tireBones[a], boneDist = distance, bonePos = bonePos, tireIndex = tireIndex[tireBones[a]]}
            end
        else
            if distance < closestTire.boneDist then
                closestTire = {bone = tireBones[a], boneDist = distance, bonePos = bonePos, tireIndex = tireIndex[tireBones[a]]}
            end
        end
    end

    return closestTire
end

function Draw3DText(x, y, z, text)
    local onScreen,_x,_y=World3dToScreen2d(x,y,z)
    local px,py,pz=table.unpack(GetGameplayCamCoords())
    local dist = GetDistanceBetweenCoords(px,py,pz, x,y,z, 1)
 
    local scale = (1/dist)*2
    local fov = (1/GetGameplayCamFov())*100
    local scale = scale*fov
   
    if onScreen then
        SetTextScale(0.0*scale, 0.55*scale)
        SetTextFont(0)
        SetTextProportional(1)
        -- SetTextScale(0.0, 0.55)
        SetTextColour(255, 255, 255, 255)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x,_y)
    end
end

--Tackle--

local TackleKey = 205 -- Change to a number which can be found here: https://wiki.fivem.net/wiki/Controls
local TackleTime = 3500 -- In milliseconds

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if IsPedJumping(PlayerPedId()) and IsControlJustReleased(0, TackleKey) then
            if IsPedInAnyVehicle(PlayerPedId()) then
                 TriggerEvent('chatMessage', 'Tackle', {255, 255, 255}, 'You cannot tackle someone in a vehicle')
             else
                local ForwardVector = GetEntityForwardVector(PlayerPedId())
                local Tackled = {}

                SetPedToRagdollWithFall(PlayerPedId(), 1500, 2000, 0, ForwardVector, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)

                while IsPedRagdoll(PlayerPedId()) do
                    Citizen.Wait(0)
                    for Key, Value in ipairs(GetTouchedPlayers()) do
                        if not Tackled[Value] then
                            Tackled[Value] = true
                             TriggerServerEvent('Tackle:Server:TacklePlayer', GetPlayerServerId(Value), ForwardVector.x, ForwardVector.y, ForwardVector.z, GetPlayerName(PlayerId()))
                        end
                    end
                end
            end
        end
    end
end)

 RegisterNetEvent('Tackle:Client:TacklePlayer')
 AddEventHandler('Tackle:Client:TacklePlayer', function(ForwardVectorX, ForwardVectorY, ForwardVectorZ, Tackler)
     SetPedToRagdollWithFall(PlayerPedId(), TackleTime, TackleTime, 0, ForwardVectorX, ForwardVectorY, ForwardVectorZ, 10.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
 end)

function GetPlayers()
    local Players = {}

    for i = 0, 31 do
        if NetworkIsPlayerActive(i) then
            table.insert(Players, i)
        end
    end

    return Players
end

function GetTouchedPlayers()
    local TouchedPlayer = {}
    for Key, Value in ipairs(GetPlayers()) do
        if IsEntityTouchingEntity(PlayerPedId(), GetPlayerPed(Value)) then
            table.insert(TouchedPlayer, Value)
        end
    end
    return TouchedPlayer
end




--Recoil--

-- Script by Lyrad for LEFR

local scopedWeapons = 
{
    100416529,  -- WEAPON_SNIPERRIFLE
    205991906,  -- WEAPON_HEAVYSNIPER
    3342088282, -- WEAPON_MARKSMANRIFLE
	177293209,   -- WEAPON_HEAVYSNIPER MKII
	1785463520  -- WEAPON_MARKSMANRIFLE_MK2
}

function HashInTable( hash )
    for k, v in pairs( scopedWeapons ) do 
        if ( hash == v ) then 
            return true 
        end 
    end 

    return false 
end 

function ManageReticle()
    local ped = GetPlayerPed( -1 )
    local _, hash = GetCurrentPedWeapon( ped, true )
        if not HashInTable( hash ) then 
            HideHudComponentThisFrame( 14 )
		end 
end 


Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		local ped = GetPlayerPed( -1 )
		local weapon = GetSelectedPedWeapon(ped)
		--print(weapon) -- To get the weapon hash by pressing F8 in game
		
		-- Disable reticle
		
		ManageReticle()
		
		-- Disable melee while aiming (may be not working)
		
		if IsPedArmed(ped, 6) then
        	DisableControlAction(1, 140, true)
            DisableControlAction(1, 141, true)
            DisableControlAction(1, 142, true)
        end
		
		-- Disable ammo HUD
		
		DisplayAmmoThisFrame(false)
		
		-- Shakycam
		
		-- Pistol
		if weapon == GetHashKey("WEAPON_STUNGUN") then
			if IsPedShooting(ped) then
				ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.01)
			end
		end
		
		if weapon == GetHashKey("WEAPON_FLAREGUN") then	
			if IsPedShooting(ped) then
				ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.01)
			end
		end
		
		if weapon == GetHashKey("WEAPON_SNSPISTOL") then		
			if IsPedShooting(ped) then
				ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.02)
			end
		end
		
		if weapon == GetHashKey("WEAPON_SNSPISTOL_MK2") then		
			if IsPedShooting(ped) then
				ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.025)
			end
		end
		
		if weapon == GetHashKey("WEAPON_PISTOL") then		
			if IsPedShooting(ped) then
				ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.08)
			end
		end
		
		if weapon == GetHashKey("WEAPON_PISTOL_MK2") then
			if IsPedShooting(ped) then
				ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.03)
			end
		end
		
		if weapon == GetHashKey("WEAPON_APPISTOL") then
			if IsPedShooting(ped) then
				ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.05)
			end
		end
		
		if weapon == GetHashKey("WEAPON_COMBATPISTOL") then		
			if IsPedShooting(ped) then
				ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.005)
			end
		end
		
		if weapon == GetHashKey("WEAPON_PISTOL50") then
			if IsPedShooting(ped) then
				ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.05)
			end
		end
		
		if weapon == GetHashKey("WEAPON_HEAVYPISTOL") then		
			if IsPedShooting(ped) then
				ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.03)
			end
		end
		
		if weapon == GetHashKey("WEAPON_VINTAGEPISTOL") then		
			if IsPedShooting(ped) then
				ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.025)
			end
		end
		
		if weapon == GetHashKey("WEAPON_MARKSMANPISTOL") then		
			if IsPedShooting(ped) then
				ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.03)
			end
		end
		
		if weapon == GetHashKey("WEAPON_REVOLVER") then	
			if IsPedShooting(ped) then
				ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.045)
			end
		end
		
		if weapon == GetHashKey("WEAPON_REVOLVER_MK2") then	
			if IsPedShooting(ped) then
				ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.055)
			end
		end
		
		if weapon == GetHashKey("WEAPON_DOUBLEACTION") then	
			if IsPedShooting(ped) then
				ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.025)
			end
		end
		-- SMG
		
		if weapon == GetHashKey("WEAPON_MICROSMG") then	
			if IsPedShooting(ped) then
				ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.035)
			end
		end
		
		if weapon == GetHashKey("WEAPON_COMBATPDW") then			
			if IsPedShooting(ped) then
				ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.045)
			end
		end
		
		if weapon == GetHashKey("WEAPON_SMG") then
			if IsPedShooting(ped) then
				ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.045)
			end
		end
		
		if weapon == GetHashKey("WEAPON_SMG_MK2") then	
			if IsPedShooting(ped) then
				ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.055)
			end
		end
		
		if weapon == GetHashKey("WEAPON_ASSAULTSMG") then	
			if IsPedShooting(ped) then
				ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.050)
			end
		end
		
		if weapon == GetHashKey("WEAPON_MACHINEPISTOL") then		
			if IsPedShooting(ped) then
				ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.035)
			end
		end
		
		if weapon == GetHashKey("WEAPON_MINISMG") then
			if IsPedShooting(ped) then
				ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.035)
			end
		end
		
		if weapon == GetHashKey("WEAPON_MG") then
			if IsPedShooting(ped) then
				ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.07)
			end
		end
		
		if weapon == GetHashKey("WEAPON_COMBATMG") then		
			if IsPedShooting(ped) then
				ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.08)
			end
		end
		
		if weapon == GetHashKey("WEAPON_COMBATMG_MK2") then			
			if IsPedShooting(ped) then
				ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.085)
			end
		end
		
		-- Rifles
		
		if weapon == GetHashKey("WEAPON_ASSAULTRIFLE") then			
			if IsPedShooting(ped) then
				ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.07)
			end
		end
		
		if weapon == GetHashKey("WEAPON_ASSAULTRIFLE_MK2") then			
			if IsPedShooting(ped) then
				ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.075)
			end
		end
		
		if weapon == GetHashKey("WEAPON_CARBINERIFLE") then	
			if IsPedShooting(ped) then
				ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.06)
			end
		end
		
		if weapon == GetHashKey("WEAPON_CARBINERIFLE_MK2") then			
			if IsPedShooting(ped) then
				ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.065)
			end
		end
		
		if weapon == GetHashKey("WEAPON_ADVANCEDRIFLE") then		
			if IsPedShooting(ped) then
				ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.06)
			end
		end
		
		if weapon == GetHashKey("WEAPON_GUSENBERG") then		
			if IsPedShooting(ped) then
				ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.05)
			end
		end
		
		if weapon == GetHashKey("WEAPON_SPECIALCARBINE") then		
			if IsPedShooting(ped) then
				ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.06)
			end
		end
		
		if weapon == GetHashKey("WEAPON_SPECIALCARBINE_MK2") then		
			if IsPedShooting(ped) then
				ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.075)
			end
		end
		
		if weapon == GetHashKey("WEAPON_BULLPUPRIFLE") then			
			if IsPedShooting(ped) then
				ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.05)
			end
		end
		
		if weapon == GetHashKey("WEAPON_BULLPUPRIFLE_MK2") then			
			if IsPedShooting(ped) then
				ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.065)
			end
		end
		
		if weapon == GetHashKey("WEAPON_COMPACTRIFLE") then		
			if IsPedShooting(ped) then
				ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.05)
			end
		end
		
		-- Shotgun
		
		if weapon == GetHashKey("WEAPON_PUMPSHOTGUN") then
			if IsPedShooting(ped) then
				ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.07)
			end
		end
		
		if weapon == GetHashKey("WEAPON_PUMPSHOTGUN_MK2") then
			if IsPedShooting(ped) then
				ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.085)
			end
		end
		
		if weapon == GetHashKey("WEAPON_SAWNOFFSHOTGUN") then
			if IsPedShooting(ped) then
				ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.06)
			end
		end
		
		if weapon == GetHashKey("WEAPON_ASSAULTSHOTGUN") then	
			if IsPedShooting(ped) then
				ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.12)
			end
		end
		
		if weapon == GetHashKey("WEAPON_BULLPUPSHOTGUN") then		
			if IsPedShooting(ped) then
				ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.08)
			end
		end
		
		if weapon == GetHashKey("WEAPON_DBSHOTGUN") then	
			if IsPedShooting(ped) then
				ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.05)
			end
		end
		
		if weapon == GetHashKey("WEAPON_AUTOSHOTGUN") then	
			if IsPedShooting(ped) then
				ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.08)
			end
		end
		
		if weapon == GetHashKey("WEAPON_MUSKET") then
			if IsPedShooting(ped) then
				ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.04)
			end
		end
		
		if weapon == GetHashKey("WEAPON_HEAVYSHOTGUN") then	
			if IsPedShooting(ped) then
				ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.13)
			end
		end
		
		-- Sniper
		
		if weapon == GetHashKey("WEAPON_SNIPERRIFLE") then
			if IsPedShooting(ped) then
				ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.2)
			end
		end
		
		if weapon == GetHashKey("WEAPON_HEAVYSNIPER") then	
			if IsPedShooting(ped) then
				ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.3)
			end
		end
		
		if weapon == GetHashKey("WEAPON_HEAVYSNIPER_MK2") then
			if IsPedShooting(ped) then
				ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.35)
			end
		end
		
		if weapon == GetHashKey("WEAPON_MARKSMANRIFLE") then			
			if IsPedShooting(ped) then
				ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.1)
			end
		end
		
		if weapon == GetHashKey("WEAPON_MARKSMANRIFLE_MK2") then			
			if IsPedShooting(ped) then
				ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.1)
			end
		end
		
		-- Launcher
		
		if weapon == GetHashKey("WEAPON_GRENADELAUNCHER") then		
			if IsPedShooting(ped) then
				ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.08)
			end
		end
		
		if weapon == GetHashKey("WEAPON_RPG") then
			if IsPedShooting(ped) then
				ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.9)
			end
		end
		
		if weapon == GetHashKey("WEAPON_HOMINGLAUNCHER") then		
			if IsPedShooting(ped) then
				ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.9)
			end
		end
		
		if weapon == GetHashKey("WEAPON_MINIGUN") then	
			if IsPedShooting(ped) then
				ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.20)
			end
		end
		
		if weapon == GetHashKey("WEAPON_RAILGUN") then	
			if IsPedShooting(ped) then
				ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 1.0)
				
			end
		end
		
		if weapon == GetHashKey("WEAPON_COMPACTLAUNCHER") then		
			if IsPedShooting(ped) then
				ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.08)
			end
		end
		
		if weapon == GetHashKey("WEAPON_FIREWORK") then	
			if IsPedShooting(ped) then
				ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.5)
			end
		end
		
		-- Infinite FireExtinguisher
		
		if weapon == GetHashKey("WEAPON_FIREEXTINGUISHER") then		
			if IsPedShooting(ped) then
				SetPedInfiniteAmmo(ped, true, GetHashKey("WEAPON_FIREEXTINGUISHER"))
			end
		end
	end
end)

-- recoil script by bluethefurry / Blumlaut https://forum.fivem.net/t/betterrecoil-better-3rd-person-recoil-for-fivem/82894
-- I just added some missing weapons because of the doomsday update adding some MK2.
-- I can't manage to make negative hashes works, if someone make it works, please let me know =)

local recoils = {
	[453432689] = 0.3, -- PISTOL
	[3219281620] = 0.3, -- PISTOL MK2
	[1593441988] = 0.2, -- COMBAT PISTOL
	[584646201] = 0.1, -- AP PISTOL
	[2578377531] = 0.6, -- PISTOL .50
	[324215364] = 0.2, -- MICRO SMG
	[736523883] = 0.1, -- SMG
	[2024373456] = 0.1, -- SMG MK2
	[4024951519] = 0.1, -- ASSAULT SMG
	[3220176749] = 0.2, -- ASSAULT RIFLE
	[961495388] = 0.2, -- ASSAULT RIFLE MK2
	[2210333304] = 0.1, -- CARBINE RIFLE
	[4208062921] = 0.1, -- CARBINE RIFLE MK2
	[2937143193] = 0.1, -- ADVANCED RIFLE
	[2634544996] = 0.1, -- MG
	[2144741730] = 0.1, -- COMBAT MG
	[3686625920] = 0.1, -- COMBAT MG MK2
	[487013001] = 0.4, -- PUMP SHOTGUN
	[1432025498] = 0.4, -- PUMP SHOTGUN MK2
	[2017895192] = 0.7, -- SAWNOFF SHOTGUN
	[3800352039] = 0.4, -- ASSAULT SHOTGUN
	[2640438543] = 0.2, -- BULLPUP SHOTGUN
	[911657153] = 0.1, -- STUN GUN
	[100416529] = 0.5, -- SNIPER RIFLE
	[205991906] = 0.7, -- HEAVY SNIPER
	[177293209] = 0.7, -- HEAVY SNIPER MK2
	[856002082] = 1.2, -- REMOTE SNIPER
	[2726580491] = 1.0, -- GRENADE LAUNCHER
	[1305664598] = 1.0, -- GRENADE LAUNCHER SMOKE
	[2982836145] = 0.0, -- RPG
	[1752584910] = 0.0, -- STINGER
	[1119849093] = 0.01, -- MINIGUN
	[3218215474] = 0.2, -- SNS PISTOL
	[2009644972] = 0.25, -- SNS PISTOL MK2
	[1627465347] = 0.1, -- GUSENBERG
	[3231910285] = 0.2, -- SPECIAL CARBINE
	[-1768145561] = 0.25, -- SPECIAL CARBINE MK2
	[3523564046] = 0.5, -- HEAVY PISTOL
	[2132975508] = 0.2, -- BULLPUP RIFLE
	[-2066285827] = 0.25, -- BULLPUP RIFLE MK2
	[137902532] = 0.4, -- VINTAGE PISTOL
	[-1746263880] = 0.4, -- DOUBLE ACTION REVOLVER
	[2828843422] = 0.7, -- MUSKET
	[984333226] = 0.2, -- HEAVY SHOTGUN
	[3342088282] = 0.3, -- MARKSMAN RIFLE
	[1785463520] = 0.35, -- MARKSMAN RIFLE MK2
	[1672152130] = 0, -- HOMING LAUNCHER
	[1198879012] = 0.9, -- FLARE GUN
	[171789620] = 0.2, -- COMBAT PDW
	[3696079510] = 0.9, -- MARKSMAN PISTOL
  	[1834241177] = 2.4, -- RAILGUN
	[3675956304] = 0.3, -- MACHINE PISTOL
	[3249783761] = 0.6, -- REVOLVER
	[-879347409] = 0.65, -- REVOLVER MK2
	[4019527611] = 0.7, -- DOUBLE BARREL SHOTGUN
	[1649403952] = 0.3, -- COMPACT RIFLE
	[317205821] = 0.2, -- AUTO SHOTGUN
	[125959754] = 0.5, -- COMPACT LAUNCHER
	[3173288789] = 0.1, -- MINI SMG		
}



Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		if IsPedShooting(PlayerPedId()) and not IsPedDoingDriveby(PlayerPedId()) then
			local _,wep = GetCurrentPedWeapon(PlayerPedId())
			_,cAmmo = GetAmmoInClip(PlayerPedId(), wep)
			if recoils[wep] and recoils[wep] ~= 0 then
				tv = 0
				repeat 
					Wait(0)
					p = GetGameplayCamRelativePitch()
					if GetFollowPedCamViewMode() ~= 4 then
						SetGameplayCamRelativePitch(p+0.1, 0.2)
					end
					tv = tv+0.1
				until tv >= recoils[wep]
			end
			
		end
	end
end)

--Tow--

-- C O N F I G --
local companyName = "DVTowing"

local towOffset = -5.0

local deleteLastTruck = true --Deletes the last spawned truck.
local spawnDistance = 500 	--	Default 500
							---								---
local drivingStyle = 786603  	--	**786603  - "Normal" - Default**
								--	**1074528293 - "Rushed"**
								--	**2883621 - "Ignore Lights"**
								--	**5 - "Sometimes Overtake Traffic"**
								--	**Customize Driving Style: https://vespura.com/drivingstyle/

local towDriverQuoteOfTheDay = {"Howdy partner! I'll get it towed.","Do you even lift bro? Because i do.","You called the right guy, because i got puns from head to tow.","Tow'nt worry about it, i'll get it towed!","I wont charge you a arm and a leg! I only want your tows.","You want too hook up some time?","I hate my job.","Sorry i took so long!","We have some of the best hookers in town!","Sorry i took so long.","There ya go!","Take care.","That will look good in the impound!","Fuck you.", "I got it!", ("Thanks for using " .. companyName .. "!"), "It will be at the compound."}
	
								
-- Register a network event 
RegisterNetEvent('wk:spawnTow')
RegisterNetEvent('wk:cancelTow')

-- Gets a vehicle in a certain direction
-- Credit to Konijima
function GetVehicleInDirection( coordFrom, coordTo )
    local rayHandle = CastRayPointToPoint( coordFrom.x, coordFrom.y, coordFrom.z, coordTo.x, coordTo.y, coordTo.z, 10, GetPlayerPed( -1 ), 0 )
    local _, _, _, _, vehicle = GetRaycastResult( rayHandle )
    return vehicle
end

-- The distance to check in front of the player for a vehicle
-- Distance is in GTA units, which are quite big  
local distanceToCheck = 5.0

enroute = false
onscene = false
cleartask = false
AddEventHandler( 'wk:spawnTow', function()
	local spawnDistance = math.random(spawnDistance * -1, spawnDistance)
	local player = GetPlayerPed(-1)
	local playerPos = GetEntityCoords(player)
	local pmodels = {"mp_m_waremech_01"}
	local vehicles = {"flatbed"}
	local driver = GetHashKey(pmodels[math.random(#pmodels)])
	local vehiclehash = GetHashKey(vehicles[math.random(#vehicles)])
    local inFrontOfPlayer = GetOffsetFromEntityInWorldCoords(player, 0.0, distanceToCheck, 0.0)
	RequestModel(vehiclehash)
	RequestModel(driver)
	
	while not HasModelLoaded(vehiclehash) and RequestModel(driver) do
		RequestModel(vehiclehash)
		RequestModel(driver)
		Citizen.Wait(0)
	end
	
	if IsPedSittingInAnyVehicle(player) then 
        targetVeh = GetVehiclePedIsIn(player, false)
	else
		targetVeh = GetVehicleInDirection(playerPos, inFrontOfPlayer)
	end
	
	if DoesEntityExist(vehicle) and deleteLastTruck == true then
		SetEntityAsMissionEntity(driver)
		SetEntityAsMissionEntity(vehicle)
		SetEntityAsMissionEntity(towedVeh)
		
		DeleteEntity(driver)
		DeleteEntity(vehicle)
		DeleteEntity(towedVeh)
		
		while DoesEntityExist(driver) do
			Wait(0)
			DeleteEntity(driver)
		end
	end
	
	if DoesEntityExist(targetVeh) then
	TriggerEvent('radio')
	
		Wait(math.random(2000, 6000))
		
		local x, y, z = table.unpack(GetEntityCoords(GetPlayerPed(-1), false))
		local heading, vector = GetNthClosestVehicleNode(x, y, z, spawnDistance, 0, 0, 0)
		local sX, sY, sZ = table.unpack(vector)	
		vehicle = CreateVehicle(vehiclehash, sX, sY, sZ, heading, true, true)
		
		local vehiclehash = GetHashKey(vehicle)
		
		driver = CreatePedInsideVehicle(vehicle, 26, driver, -1, true, false)
		local vehpos = GetEntityCoords(targetVeh)
		TaskVehicleDriveToCoord(driver, vehicle, vehpos.x, vehpos.y, vehpos.z, 17.0, 0, vehiclehash, drivingStyle, 1.0, true)
		SetVehicleFixed(vehicle)
		SetVehicleOnGroundProperly(vehicle)
		if DoesEntityExist(driver) and DoesEntityExist(vehicle) then
		SetEntityAsMissionEntity(driver, true, true)
		towblip = AddBlipForEntity(vehicle)
		SetBlipColour(towblip, 29)
		SetBlipFlashes(towblip, true)
		
		local distanceToTow = GetDistanceBetweenCoords(GetEntityCoords(vehicle), GetEntityCoords(targetVeh))
		
		if distanceToTow < 100 then
			eta = '~g~1 Mike'
		elseif distanceToTow < 300 then
			eta = '~g~2 Mikes'
		elseif distanceToTow < 500 then
			eta = '~o~3 Mikes'
		elseif distanceToTow > 500 then
			eta = '~r~5 Mikes'
		end
		
		ShowNotification("A tow truck has been dispatched to your location. Thanks for using ~y~" .. companyName .. "~w~\nETA: " .. eta)
		enroute = true
		while (enroute) do
			Citizen.Wait(300)
			local distanceToVeh = GetDistanceBetweenCoords(GetEntityCoords(vehicle), GetEntityCoords(targetVeh), 1)
			SetEntityInvincible(vehicle, true)
			SetEntityInvincible(driver, true)
				if distanceToVeh <= 15 then
					SetVehicleIndicatorLights(vehicle, 1, true)
					SetVehicleIndicatorLights(vehicle, 2, true)
					TaskVehicleTempAction(driver, vehicle, 27, 5000)
					Wait(5000)
					AttachEntityToEntity(targetVeh, vehicle, 20, -0.5, towOffset, 1.0, 0.0, 0.0, 0.0, false, false, false, false, 20, true)
					targetVeh = towedVeh
					SetDriveTaskDrivingStyle(vehicle, 786603)
					TaskVehicleDriveWander(driver, vehicle, 17.0, drivingStyle)
					SetVehicleSiren(vehicle, true)
					ShowNotification("~o~Tow Driver:~w~ " .. towDriverQuoteOfTheDay[math.random(#towDriverQuoteOfTheDay)])
					SetEntityAsNoLongerNeeded(vehicle)
					enroute = false
					towblip = RemoveBlip(towblip)
					SetVehicleIndicatorLights(vehicle, 1, false)
					SetVehicleIndicatorLights(vehicle, 2, false)
					SetEntityInvincible(vehicle, false)
					SetEntityInvincible(driver, false)
					SetEntityAsNoLongerNeeded(vehicle)
					SetEntityAsNoLongerNeeded(driver)
					SetEntityAsNoLongerNeeded(targetVeh)
				end
			end
		end
	else
	ShowNotification("No vehicle found!")
	end
end)

AddEventHandler( 'wk:cancelTow', function()
	if enroute == true then
		ShowNotification("Tow Truck request has been canceled. Thank you for using ~y~" .. companyName)
		
		SetEntityAsMissionEntity(vehicle)
		SetEntityAsMissionEntity(driver)
		
		DeleteEntity(vehicle)
		DeleteEntity(driver)
		enroute = false
	end
end)

RegisterNetEvent('radio')
AddEventHandler('radio', function()
    Citizen.CreateThread(function()
        TaskPlayAnim(player, "random@arrests", "generic_radio_enter", 1.5, 2.0, -1, 50, 2.0, 0, 0, 0 )
		Citizen.Wait(6000)
		ClearPedTasks(player)
    end)
end)

function loadAnimDict( dict )
	while ( not HasAnimDictLoaded( dict ) ) do
		RequestAnimDict( dict )
		Citizen.Wait( 0 )
	end
end

-- Shows a notification on the player's screen 
function ShowNotification( text )
    SetNotificationTextEntry( "STRING" )
    AddTextComponentString( text )
    DrawNotification( false, false )
end


--Location Display--

-- CONFIG --
local showCompass = true
local displayTime = true
local useMilitaryTime = true

-- en for english translate
-- ru for russian translate
local lang = 'en' 

local timeAndDateString = nil
local hour
local minute

-- CODE --
function drawTxt2(x,y ,width,height,scale, text, r,g,b,a)
        SetTextFont(6)
        SetTextProportional(1)
        SetTextScale(0.0, 0.48)
        SetTextColour(255, 255, 255, 255)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(1, 0, 0, 0, 255)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        AddTextComponentString(text)
        DrawText(x, y)
end

local lastStreet = nil
local zones_ru = { ['AIRP'] = "ÐœÐÐ›Ð¡", ['ALAMO'] = "ÐÐ»Ð°Ð¼Ð¾-Ð¡Ð¸", ['ALTA'] = "ÐÐ»ÑŒÑ‚Ð°", ['ARMYB'] = "Ð¤Ð¾Ñ€Ñ‚ Ð—Ð°Ð½ÐºÑƒÐ´Ð¾", ['BANHAMC'] = "Ð‘ÑÐ½Ñ…ÑÐ¼ Ð”Ñ€Ð°Ð¹Ð²", ['BANNING'] = "Ð‘ÑÐ½Ð½Ð¸Ð½Ð³", ['BEACH'] = "Ð’ÐµÑÐ¿ÑƒÑ‡Ñ‡Ð¸-Ð‘Ð¸Ñ‡", ['BHAMCA'] = "ÐšÐ°Ð½ÑŒÐ¾Ð½ Ð‘ÑÐ½Ñ…ÑÐ¼", ['BRADP'] = "ÐŸÐµÑ€ÐµÐ²Ð°Ð» Ð‘Ñ€ÑÐ´Ð´Ð¾ÐºÐ°", ['BRADT'] = "Ð¢Ð¾Ð½Ð½ÐµÐ»ÑŒ Ð‘Ñ€ÑÐ´Ð´Ð¾ÐºÐ°", ['BURTON'] = "Ð‘ÐµÑ€Ñ‚Ð¾Ð½", ['CALAFB'] = "ÐšÐ°Ð»Ð°Ñ„Ð¸Ð°-Ð‘Ñ€Ð¸Ð´Ð¶", ['CANNY'] = "ÐšÐ°Ð½ÑŒÐ¾Ð½ Ð Ð°Ñ‚Ð¾Ð½", ['CCREAK'] = "ÐšÑÑÑÐ¸Ð´Ð¸-ÐšÑ€Ð¸Ðº", ['CHAMH'] = "Ð§ÐµÐ¼Ð±ÐµÑ€Ð»ÐµÐ½-Ð¥Ð¸Ð»Ð»Ð·", ['CHIL'] = "Ð’Ð°Ð¹Ð½Ð²ÑƒÐ´-Ð¥Ð¸Ð»Ð»Ð·", ['CHU'] = "Ð§ÑƒÐ¼Ð°Ñˆ", ['CMSW'] = "Ð—Ð°Ð¿Ð¾Ð²ÐµÐ´Ð½Ð¸Ðº Ð“Ð¾Ñ€Ñ‹ Ð§Ð¸Ð»Ð¸Ð°Ð´", ['CYPRE'] = "Ð¡Ð°Ð¹Ð¿Ñ€ÐµÑÑ-Ð¤Ð»ÑÑ‚Ñ", ['DAVIS'] = "Ð”ÑÐ²Ð¸Ñ", ['DELBE'] = "Ð”ÐµÐ»ÑŒ-ÐŸÐµÑ€Ñ€Ð¾-Ð‘Ð¸Ñ‡", ['DELPE'] = "Ð”ÐµÐ»ÑŒ-ÐŸÐµÑ€Ñ€Ð¾", ['DELSOL'] = "Ð›Ð°-ÐŸÑƒÑÑ€Ñ‚Ð°", ['DESRT'] = "ÐŸÑƒÑÑ‚Ñ‹Ð½Ñ Ð“Ñ€Ð°Ð½Ð´-Ð¡ÐµÐ½Ð¾Ñ€Ð°", ['DOWNT'] = "Ð¦ÐµÐ½Ñ‚Ñ€", ['DTVINE'] = "Ð¦ÐµÐ½Ñ‚Ñ€ Ð’Ð°Ð¹Ð½Ð²ÑƒÐ´", ['EAST_V'] = "Ð—Ð°Ð¿Ð°Ð´Ð½Ñ‹Ð¹ Ð’Ð°Ð¹Ð½Ð²ÑƒÐ´", ['EBURO'] = "Ð­Ð»ÑŒ-Ð‘ÑƒÑ€Ñ€Ð¾-Ð¥Ð°Ð¹Ñ‚Ñ", ['ELGORL'] = "ÐœÐ°ÑÐº Ð­Ð»ÑŒ-Ð“Ð¾Ñ€Ð´Ð¾", ['ELYSIAN'] = "Ð­Ð»Ð¸Ð·Ð¸Ð°Ð½-ÐÐ¹Ð»ÐµÐ½Ð´", ['GALFISH'] = "Ð“Ð°Ð»Ð¸Ð»ÐµÐ¾", ['GOLF'] = "Ð“Ð¾Ð»ÑŒÑ„-ÐšÐ»ÑƒÐ±", ['GRAPES'] = "Ð“Ñ€ÐµÐ¹Ð¿ÑÐ¸Ð´", ['GREATC'] = "Ð“Ñ€ÐµÐ¹Ñ‚-Ð§Ð°Ð¿Ð°Ñ€Ñ€Ð°Ð»", ['HARMO'] = "Ð¥Ð°Ñ€Ð¼Ð¾Ð½Ð¸", ['HAWICK'] = "Ð¥Ð°Ð²Ð¸Ðº", ['HORS'] = "Ð“Ð¾Ð½Ð¾Ñ‡Ð½Ð°Ñ Ñ‚Ñ€Ð°ÑÑÐ° Ð’Ð°Ð¹Ð½Ð²ÑƒÐ´Ð°", ['HUMLAB'] = "Ð›Ð°Ð±Ð¾Ñ€Ð°Ñ‚Ð¾Ñ€Ð¸Ñ Humane Labs and Research", ['JAIL'] = "Ð¢ÑŽÑ€ÑŒÐ¼Ð° Ð‘Ð¾Ð»Ð¸Ð½Ð³Ð±Ñ€Ð¾ÑƒÐº", ['KOREAT'] = "ÐœÐ°Ð»ÐµÐ½ÑŒÐºÐ¸Ð¹ Ð¡ÐµÑƒÐ»", ['LACT'] = "Ð›ÑÐ½Ð´-Ð­ÐºÑ‚-Ð ÐµÐ·ÐµÑ€Ð²ÑƒÐ°Ñ€", ['LAGO'] = "Ð›Ð°Ð³Ð¾-Ð—Ð°Ð½ÐºÑƒÐ´Ð¾", ['LDAM'] = "Ð›ÑÐ½Ð´-Ð­ÐºÑ‚-Ð”ÑÐ¼", ['LEGSQU'] = "ÐŸÐ»Ð¾Ñ‰Ð°Ð´ÑŒ Ð›ÐµÐ³Ð¸Ð¾Ð½Ð°", ['LMESA'] = "Ð›Ð°-ÐœÐµÑÐ°", ['LOSPUER'] = "Ð›Ð°-ÐŸÑƒÑÑ€Ñ‚Ð°", ['MIRR'] = "ÐœÐ¸Ñ€Ñ€Ð¾Ñ€-ÐŸÐ°Ñ€Ðº", ['MORN'] = "ÐœÐ¾Ñ€Ð½Ð¸Ð½Ð³Ð²ÑƒÐ´", ['MOVIE'] = "ÐšÐ¸Ð½Ð¾ÑÑ‚ÑƒÐ´Ð¸Ñ Richards Majestic", ['MTCHIL'] = "Ð“Ð¾Ñ€Ð° Ð§Ð¸Ð»Ð¸Ð°Ð´", ['MTGORDO'] = "Ð“Ð¾Ñ€Ð° Ð“Ð¾Ñ€Ð´Ð¾", ['MTJOSE'] = "Ð“Ð¾Ñ€Ð° Ð”Ð¶Ð¾ÑÐ°Ð¹Ñ", ['MURRI'] = "ÐœÑƒÑ€ÑŒÐµÑ‚Ð°-Ð¥Ð°Ð¹Ñ‚Ñ", ['NCHU'] = "Ð¡ÐµÐ²ÐµÑ€Ð½Ñ‹Ð¹ Ð§ÑƒÐ¼Ð°Ñˆ", ['NOOSE'] = "Ð¦ÐµÐ½Ñ‚Ñ€ Ð.Ð£.ÐŸ.", ['OCEANA'] = "Ð¢Ð¸Ñ…Ð¸Ð¹ ÐžÐºÐµÐ°Ð½", ['PALCOV'] = "Ð‘ÑƒÑ…Ñ‚Ð° ÐŸÐ°Ð»ÐµÑ‚Ð¾", ['PALETO'] = "ÐŸÐ°Ð»ÐµÑ‚Ð¾-Ð‘ÑÐ¹", ['PALFOR'] = "Ð›ÐµÑ ÐŸÐ°Ð»ÐµÑ‚Ð¾", ['PALHIGH'] = "ÐÐ°Ð³Ð¾Ñ€ÑŒÑ ÐŸÐ°Ð»Ð°Ð¼Ð¸Ð½Ð¾", ['PALMPOW'] = "Ð­Ð»ÐµÐºÑ‚Ñ€Ð¾ÑÑ‚Ð°Ð½Ñ†Ð¸Ñ ÐŸÐ°Ð»Ð¼ÐµÑ€-Ð¢ÑÐ¹Ð»Ð¾Ñ€", ['PBLUFF'] = "ÐŸÐ°ÑÐ¸Ñ„Ð¸Ðº-Ð‘Ð»Ð°Ñ„Ñ„Ñ", ['PBOX'] = "ÐŸÐ¸Ð»Ð»Ð±Ð¾ÐºÑ-Ð¥Ð¸Ð»Ð»", ['PROCOB'] = "ÐŸÑ€Ð¾ÐºÐ¾Ð¿Ð¸Ð¾-Ð‘Ð¸Ñ‡", ['RANCHO'] = "Ð Ð°Ð½Ñ‡Ð¾", ['RGLEN'] = "Ð Ð¸Ñ‡Ð¼Ð°Ð½-Ð“Ð»ÐµÐ½", ['RICHM'] = "Ð Ð¸Ñ‡Ð¼Ð°Ð½", ['ROCKF'] = "Ð Ð¾ÐºÑ„Ð¾Ñ€Ð´-Ð¥Ð¸Ð»Ð»Ð·", ['RTRAK'] = "Ð¢Ñ€Ð°ÑÑÐ° Redwood Lights", ['SANAND'] = "Ð¡Ð°Ð½-ÐÐ½Ð´Ñ€ÐµÐ°Ñ", ['SANCHIA'] = "Ð¡Ð°Ð½-Ð¨Ð°Ð½ÑŒÑÐºÐ¸Ð¹ Ð“Ð¾Ñ€Ð½Ñ‹Ð¹ Ð¥Ñ€ÐµÐ±ÐµÑ‚", ['SANDY'] = "Ð¡ÑÐ½Ð´Ð¸-Ð¨Ð¾Ñ€Ñ", ['SKID'] = "ÐœÐ¸ÑˆÐ½-Ð Ð¾Ñƒ", ['SLAB'] = "Ð¡Ñ‚ÑÐ±-Ð¡Ð¸Ñ‚Ð¸", ['STAD'] = "ÐÑ€ÐµÐ½Ð° Maze Bank", ['STRAW'] = "Ð¡Ñ‚Ñ€Ð¾Ð±ÐµÑ€Ñ€Ð¸", ['TATAMO'] = "Ð¢Ð°Ñ‚Ð°Ð²Ð¸Ð°Ð¼ÑÐºÐ¸Ðµ Ð³Ð¾Ñ€Ñ‹", ['TERMINA'] = "Ð¢ÐµÑ€Ð¼Ð¸Ð½Ð°Ð»", ['TEXTI'] = "Ð¢ÐµÐºÑÑ‚Ð°Ð¹Ð»-Ð¡Ð¸Ñ‚Ð¸", ['TONGVAH'] = "Ð¢Ð¾Ð½Ð³Ð²Ð°-Ð¥Ð¸Ð»Ð»Ð·", ['TONGVAV'] = "Ð”Ð¾Ð»Ð¸Ð½Ð° Ð¢Ð¾Ð½Ð³Ð²Ð°", ['VCANA'] = "ÐšÐ°Ð½Ð°Ð»Ñ‹ Ð’ÐµÑÐ¿ÑƒÑ‡Ñ‡Ð¸", ['VESP'] = "Ð’ÐµÑÐ¿ÑƒÑ‡Ñ‡Ð¸", ['VINE'] = "Ð’Ð°Ð¹Ð½Ð²ÑƒÐ´", ['WINDF'] = "Ð’ÐµÑ‚Ñ€ÑÐ½Ð°Ñ Ð¤ÐµÑ€Ð¼Ð° Ron Alternates", ['WVINE'] = "Ð’Ð¾ÑÑ‚Ð¾Ñ‡Ð½Ñ‹Ð¹ Ð’Ð°Ð¹Ð½Ð²ÑƒÐ´", ['ZANCUDO'] = "Ð ÐµÐºÐ° Ð—Ð°Ð½ÐºÑƒÐ´Ð¾", ['ZP_ORT'] = "ÐŸÐ¾Ñ€Ñ‚ Ð®Ð¶Ð½Ð¾Ð³Ð¾ Ð›Ð¾Ñ-Ð¡Ð°Ð½Ñ‚Ð¾ÑÐ°", ['ZQ_UAR'] = "Ð”ÑÐ²Ð¸Ñ-ÐšÐ²Ð°Ñ€Ñ†" }

local zones_en = { ['AIRP'] = "LSIA", ['ALAMO'] = "Alamo Sea", ['ALTA'] = "Alta", ['ARMYB'] = "Fort Zancudo", ['BANHAMC'] = "Banham Canyon Dr", ['BANNING'] = "Banning", ['BEACH'] = "Vespucci Beach", ['BHAMCA'] = "Banham Canyon", ['BRADP'] = "Braddock Pass", ['BRADT'] = "Braddock Tunnel", ['BURTON'] = "Burton", ['CALAFB'] = "Calafia Bridge", ['CANNY'] = "Raton Canyon", ['CCREAK'] = "Cassidy Creek", ['CHAMH'] = "Chamberlain Hills", ['CHIL'] = "Vinewood Hills", ['CHU'] = "Chumash", ['CMSW'] = "Chiliad Mountain State Wilderness", ['CYPRE'] = "Cypress Flats", ['DAVIS'] = "Davis", ['DELBE'] = "Del Perro Beach", ['DELPE'] = "Del Perro", ['DELSOL'] = "La Puerta", ['DESRT'] = "Grand Senora Desert", ['DOWNT'] = "Downtown", ['DTVINE'] = "Downtown Vinewood", ['EAST_V'] = "East Vinewood", ['EBURO'] = "El Burro Heights", ['ELGORL'] = "El Gordo Lighthouse", ['ELYSIAN'] = "Elysian Island", ['GALFISH'] = "Galilee", ['GOLF'] = "GWC and Golfing Society", ['GRAPES'] = "Grapeseed", ['GREATC'] = "Great Chaparral", ['HARMO'] = "Harmony", ['HAWICK'] = "Hawick", ['HORS'] = "Vinewood Racetrack", ['HUMLAB'] = "Humane Labs and Research", ['JAIL'] = "Bolingbroke Penitentiary", ['KOREAT'] = "Little Seoul", ['LACT'] = "Land Act Reservoir", ['LAGO'] = "Lago Zancudo", ['LDAM'] = "Land Act Dam", ['LEGSQU'] = "Legion Square", ['LMESA'] = "La Mesa", ['LOSPUER'] = "La Puerta", ['MIRR'] = "Mirror Park", ['MORN'] = "Morningwood", ['MOVIE'] = "Richards Majestic", ['MTCHIL'] = "Mount Chiliad", ['MTGORDO'] = "Mount Gordo", ['MTJOSE'] = "Mount Josiah", ['MURRI'] = "Murrieta Heights", ['NCHU'] = "North Chumash", ['NOOSE'] = "N.O.O.S.E", ['OCEANA'] = "Pacific Ocean", ['PALCOV'] = "Paleto Cove", ['PALETO'] = "Paleto Bay", ['PALFOR'] = "Paleto Forest", ['PALHIGH'] = "Palomino Highlands", ['PALMPOW'] = "Palmer-Taylor Power Station", ['PBLUFF'] = "Pacific Bluffs", ['PBOX'] = "Pillbox Hill", ['PROCOB'] = "Procopio Beach", ['RANCHO'] = "Rancho", ['RGLEN'] = "Richman Glen", ['RICHM'] = "Richman", ['ROCKF'] = "Rockford Hills", ['RTRAK'] = "Redwood Lights Track", ['SANAND'] = "San Andreas", ['SANCHIA'] = "San Chianski Mountain Range", ['SANDY'] = "Sandy Shores", ['SKID'] = "Mission Row", ['SLAB'] = "Stab City", ['STAD'] = "Maze Bank Arena", ['STRAW'] = "Strawberry", ['TATAMO'] = "Tataviam Mountains", ['TERMINA'] = "Terminal", ['TEXTI'] = "Textile City", ['TONGVAH'] = "Tongva Hills", ['TONGVAV'] = "Tongva Valley", ['VCANA'] = "Vespucci Canals", ['VESP'] = "Vespucci", ['VINE'] = "Vinewood", ['WINDF'] = "Ron Alternates Wind Farm", ['WVINE'] = "West Vinewood", ['ZANCUDO'] = "Zancudo River", ['ZP_ORT'] = "Port of South Los Santos", ['ZQ_UAR'] = "Davis Quartz" }

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(1)
		local pos = GetEntityCoords(GetPlayerPed(-1))

        if(GetStreetNameFromHashKey(var1) and GetNameOfZone(pos.x, pos.y, pos.z))then
        	x, y, z = table.unpack(GetEntityCoords(GetPlayerPed(-1), true))
            lastStreet = GetStreetNameAtCoord(x, y, z)
            lastStreetName = GetStreetNameFromHashKey(lastStreet)
            compass = getCardinalDirectionFromHeading(GetEntityHeading(GetPlayerPed(-1)))
            timeAndDateString = ""
            CalculateTimeToDisplay()
            timeAndDateString = timeAndDateString .. hour .. ":" .. minute

            if lang == 'en' then
                if(zones_en[GetNameOfZone(pos.x, pos.y, pos.z)] and tostring(GetStreetNameFromHashKey(var1)))then
                    drawTxt2(0.165, 0.955, 1.0,1.0,0.4,compass.." ~r~|~w~ "..lastStreetName.." ~r~|~w~ "..zones_en[GetNameOfZone(pos.x, pos.y, pos.z)].." ~r~|~w~ "..timeAndDateString, 255, 255, 255, 255)
                end
            end
		end
	end
end)

-- Citizen.CreateThread(function()
--     while true do
--         Citizen.Wait(1)
        
--         x, y, z = table.unpack(GetEntityCoords(GetPlayerPed(-1), true))
--         lastStreet = GetStreetNameAtCoord(x, y, z)
--         lastStreetName = GetStreetNameFromHashKey(lastStreet)


--         SetTextFont(6)
--         SetTextProportional(1)
--         SetTextScale(0.0, 0.48)
--         SetTextColour(255, 255, 255, 255)
--         SetTextDropshadow(0, 0, 0, 0, 255)
--         SetTextEdge(1, 0, 0, 0, 255)
--         SetTextDropShadow()
--         SetTextOutline()
--         SetTextEntry("STRING")

--         if showCompass then
--         	compass = getCardinalDirectionFromHeading(GetEntityHeading(GetPlayerPed(-1)))
--         	lastStreetName = compass .. " | " .. lastStreetName  -- Example: N | Spanish Ave.
--         end

--         AddTextComponentString(lastStreetName)
--         DrawText(0.165, 0.930)
--     end
-- end)

-- Citizen.CreateThread(function()
-- 	while true do
-- 		Wait(1)
-- 		timeAndDateString = ""
		
-- 		if displayTime == true then
-- 			CalculateTimeToDisplay()
-- 			timeAndDateString = timeAndDateString .. "Time: " .. hour .. ":" .. minute  -- Example: Time: 00:00
-- 		end
		
--         SetTextFont(6)
--         SetTextProportional(1)
--         SetTextScale(0.0, 0.48)
--         SetTextColour(255, 255, 255, 255)
--         SetTextDropshadow(0, 0, 0, 0, 255)
--         SetTextEdge(1, 0, 0, 0, 255)
--         SetTextDropShadow()
--         SetTextOutline()
--         SetTextEntry("STRING")
		
-- 		AddTextComponentString(timeAndDateString)
-- 		DrawText(0.165, 0.890)
-- 	end
-- end)


-- Thanks @marxy
function getCardinalDirectionFromHeading(heading)
    if ((heading >= 0 and heading < 45) or (heading >= 315 and heading < 360)) then
        if lang == 'en' then
            return "N" -- North
        elseif lang == 'ru' then
            return "Ð¡" -- North
        else
            return "~r~Err"
        end
    elseif (heading >= 45 and heading < 135) then
        if lang == 'en' then
            return "E" -- East
        elseif lang == 'ru' then
            return "Ð’" -- East
        else
            return "~r~Err"
        end
    elseif (heading >=135 and heading < 225) then
        if lang == 'en' then
            return "S" -- South
        elseif lang == 'ru' then
            return "Ð®" -- South
        else
            return "~r~Err"
        end
    elseif (heading >= 225 and heading < 315) then
        if lang == 'en' then
            return "W" -- West
        elseif lang == 'ru' then
            return "Ð—" -- West
        else
            return "~r~Err"
        end
    end
end

function CalculateTimeToDisplay()
	hour = GetClockHours()
	minute = GetClockMinutes()

	if useMilitaryTime == false then
		if hour == 0 or hour == 24 then
			hour = 12
		elseif hour >= 13 then
			hour = hour - 12
		end
	end

	if hour <= 9 then
		hour = "0" .. hour
	end
	if minute <= 9 then
		minute = "0" .. minute
	end
end

-- Damage 

local UseBaseevents = false

-- Vehicles Classes :
-- 0: Compacts  
-- 1: Sedans  
-- 2: SUVs  
-- 3: Coupes  
-- 4: Muscle  
-- 5: Sports Classics  
-- 6: Sports  
-- 7: Super  
-- 8: Motorcycles  
-- 9: Off-road  
-- 10: Industrial  
-- 11: Utility  
-- 12: Vans  
-- 13: Cycles  
-- 14: Boats  
-- 15: Helicopters  
-- 16: Planes  
-- 17: Service  
-- 18: Emergency  
-- 19: Military  
-- 20: Commercial  
-- 21: Trains
local VehiclesClassDamagesModifiers = {
    [0]  = {engine = 3.0, collision = 3.0, weapons = 3.0}, -- 0: Compacts  
    [1]  = {engine = 3.0, collision = 3.0, weapons = 3.0},-- 1: Sedans  
    [2]  = {engine = 3.0, collision = 3.0, weapons = 3.0},-- 2: SUVs  
    [3]  = {engine = 3.0, collision = 3.0, weapons = 3.0},-- 3: Coupes  
    [4]  = {engine = 3.0, collision = 3.0, weapons = 3.0},-- 4: Muscle  
    [5]  = {engine = 3.0, collision = 3.0, weapons = 3.0},-- 5: Sports Classic
    [6]  = {engine = 3.0, collision = 3.0, weapons = 3.0},-- 6: Sports  
    [7]  = {engine = 3.0, collision = 3.0, weapons = 3.0},-- 7: Super  
    [8]  = {engine = 3.0, collision = 3.0, weapons = 3.0},-- 8: Motorcycles  
    [9]  = {engine = 3.0, collision = 3.0, weapons = 3.0},-- 9: Off-road  
    [10] = {engine = 3.0, collision = 3.0, weapons = 3.0},-- 10: Industrial  
    [11] = {engine = 3.0, collision = 3.0, weapons = 3.0},-- 11: Utility  
    [12] = {engine = 3.0, collision = 3.0, weapons = 3.0},-- 12: Vans  
    [13] = {engine = 3.0, collision = 3.0, weapons = 3.0},-- 13: Cycles  
    [14] = {engine = 3.0, collision = 3.0, weapons = 3.0},-- 14: Boats  
    [15] = {engine = 3.0, collision = 3.0, weapons = 3.0},-- 15: Helicopters  
    [16] = {engine = 3.0, collision = 3.0, weapons = 3.0},-- 16: Planes  
    [17] = {engine = 3.0, collision = 3.0, weapons = 3.0},-- 17: Service  
    [18] = {engine = 3.0, collision = 3.0, weapons = 3.0},-- 18: Emergency  
    [19] = {engine = 3.0, collision = 3.0, weapons = 3.0},-- 19: Military  
    [20] = {engine = 3.0, collision = 3.0, weapons = 3.0},-- 20: Commercial  
    [21] = {engine = 3.0, collision = 3.0, weapons = 3.0},-- 21: Trains
}

local VehicleNameDamagesModifiers = {
    [GetHashKey("blista")] = {engine = 2.5, collision = 2.5, weapons = 2.5},
    [GetHashKey("brioso")] = {engine = 2.0, collision = 2.0, weapons = 2.0},
}


DecorRegister("_Custom_Damages", 2)

if not UseBaseevents then
    local isInVehicle = false
    local isEnteringVehicle = false
    local currentVehicle = 0
    local currentSeat = 0

    Citizen.CreateThread(function()
        while true do
            local ped = PlayerPedId()

            if not isInVehicle and not IsPlayerDead(PlayerId()) then
                if IsPedInAnyVehicle(ped, false) then
                    isEnteringVehicle = false
                    isInVehicle = true
                    currentVehicle = GetVehiclePedIsUsing(ped)
                    local model = GetEntityModel(currentVehicle)
                    StartVehiclesDamages(currentVehicle)
                end
            elseif isInVehicle then
                if not IsPedInAnyVehicle(ped, false) or IsPlayerDead(PlayerId()) then
                    isInVehicle = false
                    currentVehicle = 0
                end
            end
            Citizen.Wait(50)
        end
    end)
else
    AddEventHandler('baseevents:enteredVehicle', function(vehicle)
        StartVehiclesDamages(vehicle)
    end)
end

function StartVehiclesDamages(vehicle)
    if not DecorExistOn(vehicle, "_Custom_Damages") or DecorGetBool(vehicle, "_Custom_Damages") == false then
        local values = nil
        local vehModel = GetEntityModel(vehicle)
        if VehicleNameDamagesModifiers[vehModel] ~= nil then
            values = VehicleNameDamagesModifiers[vehModel]
        else
            local vehicleClass = GetVehicleClass(vehicle)
            if VehiclesClassDamagesModifiers[vehicleClass] ~= nil then
                values = VehiclesClassDamagesModifiers[vehicleClass]
            end
        end
        if values ~= nil then
            SetVehicleHandlingFloat(vehicle, "CHandlingData", "fEngineDamageMult", values.engine)
            SetVehicleHandlingFloat(vehicle, "CHandlingData", "fCollisionDamageMult", values.collision)
            SetVehicleHandlingFloat(vehicle, "CHandlingData", "fWeaponDamageMult", values.weapons)
        end
        DecorSetBool(vehicle, "_Custom_Damages", true)
    end
end


-- revive

RegisterNetEvent('RPD:allowRespawn')
RegisterNetEvent('RPD:allowRevive') 
RegisterNetEvent('RPD:toggleDeath')

local reviveWaitPeriod = 1 -- How many seconds to wait before allowing player to revive themselves
local RPDeathEnabled = true  -- Is RPDeath enabled by default? (/toggleDeath changes this value.)



-- Turn off automatic respawn here instead of updating FiveM file.
AddEventHandler('onClientMapStart', function()
    Citizen.Trace("RPDeath: Disabling autospawn...")
    exports.spawnmanager:spawnPlayer() -- Ensure player spawns into server.
    Citizen.Wait(2500)
    exports.spawnmanager:setAutoSpawn(false)
    Citizen.Trace("RPDeath: Autospawn disabled!")
end)


local allowRespawn = false
local allowRevive = false
local diedTime = nil


AddEventHandler('RPD:allowRespawn', function(from)
    TriggerEvent('chatMessage', "RPDeath", {200,0,0}, "Respawned")
    allowRespawn = true
end)


AddEventHandler('RPD:allowRevive', function(from)
    if(not IsEntityDead(GetPlayerPed(-1)))then
        -- You are alive, do nothing.
        return
    end

    -- Trying to revive themselves?
    if(GetPlayerServerId(PlayerId()) == from and diedTime ~= nil)then
        local waitPeriod = diedTime + (reviveWaitPeriod * 1000)
        if(GetGameTimer() < waitPeriod)then
            local seconds = math.ceil((waitPeriod - GetGameTimer()) / 1000)
            local message = ""
            if(seconds > 60)then
                local minutes = math.floor((seconds / 60))
                seconds = math.ceil(seconds-(minutes*60))
                message = minutes.." minutes "
            end
            message = message..seconds.." seconds"
            TriggerEvent('chatMessage', "RPDeath", {200,0,0}, "You must wait before reviving yourself, you have ^5"..message.."^0 remaining.")
            return      
        end
    end

    -- Revive the player.
    TriggerEvent('chatMessage', "RPDeath", {200,0,0}, "Revived")
    allowRevive = true
end)

AddEventHandler('RPD:toggleDeath', function(from)
    RPDeathEnabled = not RPDeathEnabled
    if (RPDeathEnabled) then
        TriggerEvent('chatMessage', "RPDeath", {200,0,0}, "RPDeath enabled.")
    else
        TriggerEvent('chatMessage', "RPDeath", {200,0,0}, "RPDeath disabled.")
    end
end)



function revivePed(ped)
    local playerPos = GetEntityCoords(ped, true)

    NetworkResurrectLocalPlayer(playerPos, true, true, false)
    SetPlayerInvincible(ped, false)
    ClearPedBloodDamage(ped)
end


function respawnPed(ped,coords)
    SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, false, false, false, true)
    NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, coords.heading, true, false) 

    SetPlayerInvincible(ped, false) 

    TriggerEvent('playerSpawned', coords.x, coords.y, coords.z, coords.heading)
    ClearPedBloodDamage(ped)
end


Citizen.CreateThread(function()
    local respawnCount = 0
    local spawnPoints = {}
    local playerIndex = NetworkGetPlayerIndex(-1) or 0


    math.randomseed(playerIndex)

    function createSpawnPoint(x1,x2,y1,y2,z,heading)
        local xValue = math.random(x1,x2) + 0.0001
        local yValue = math.random(y1,y2) + 0.0001

        local newObject = {
            x = xValue,
            y = yValue,
            z = z + 0.0001,
            heading = heading + 0.0001
        }
        table.insert(spawnPoints,newObject)
    end

     createSpawnPoint(372, 375, -596, -594, 30.0, 0)   -- Pillbox Hill
 

    while true do
        Wait(0)
        local ped = GetPlayerPed(-1)
        
        if (RPDeathEnabled) then

            if (IsEntityDead(ped)) then
                if(diedTime == nil)then
                    diedTime = GetGameTimer()
                end


                SetPlayerInvincible(ped, true)
                SetEntityHealth(ped, 1)
                
                if (allowRespawn) then 
                    local coords = spawnPoints[math.random(1,#spawnPoints)]

                    respawnPed(ped, coords)

                    allowRespawn = false
                    diedTime = nil
                    respawnCount = respawnCount + 1
                    math.randomseed( playerIndex * respawnCount )

                elseif (allowRevive) then
                    revivePed(ped)

                    allowRevive = false 
                    diedTime = nil
                    Wait(0)
                else
                    Wait(0)
                end
            else
                allowRespawn = false
                allowRevive = false 
                diedTime = nil      
                Wait(0)
            end


        else 
            if IsEntityDead(ped) then
                Wait(3000) 

                local coords = spawnPoints[math.random(1,#spawnPoints)]

                respawnPed(ped,coords)

                respawnCount = respawnCount + 1
                math.randomseed( playerIndex * respawnCount )
                
            end
        end

    end
end)

--Dv-

-- Register a network event 
RegisterNetEvent( 'wk:deleteVehicle' )

-- The distance to check in front of the player for a vehicle
-- Distance is in GTA units, which are quite big  
local distanceToCheck = 5.0

-- Add an event handler for the deleteVehicle event. 
-- Gets called when a user types in /dv in chat (see server.lua)
AddEventHandler( 'wk:deleteVehicle', function()
    local ped = GetPlayerPed( -1 )

    if ( DoesEntityExist( ped ) and not IsEntityDead( ped ) ) then 
        local pos = GetEntityCoords( ped )

        if ( IsPedSittingInAnyVehicle( ped ) ) then 
            local vehicle = GetVehiclePedIsIn( ped, false )

            if ( GetPedInVehicleSeat( vehicle, -1 ) == ped ) then 
                SetEntityAsMissionEntity( vehicle, true, true )
                deleteCar( vehicle )

                if ( DoesEntityExist( vehicle ) ) then 
                	ShowNotification( "~r~Unable to delete vehicle, try again." )
                else 
                	ShowNotification( "Vehicle deleted." )
                end 
            else 
                ShowNotification( "You must be in the driver's seat!" )
            end 
        else
            local playerPos = GetEntityCoords( ped, 1 )
            local inFrontOfPlayer = GetOffsetFromEntityInWorldCoords( ped, 0.0, distanceToCheck, 0.0 )
            local vehicle = GetVehicleInDirection( playerPos, inFrontOfPlayer )

            if ( DoesEntityExist( vehicle ) ) then 
                SetEntityAsMissionEntity( vehicle, true, true )
                deleteCar( vehicle )

                if ( DoesEntityExist( vehicle ) ) then 
                	ShowNotification( "~r~Unable to delete vehicle, try again." )
                else 
                	ShowNotification( "Vehicle deleted." )
                end 
            else 
                ShowNotification( "You must be in or near a vehicle to delete it." )
            end 
        end 
    end 
end )

-- Delete car function borrowed frtom Mr.Scammer's model blacklist, thanks to him!
function deleteCar( entity )
    Citizen.InvokeNative( 0xEA386986E786A54F, Citizen.PointerValueIntInitialized( entity ) )
end

-- Gets a vehicle in a certain direction
-- Credit to Konijima
function GetVehicleInDirection( coordFrom, coordTo )
    local rayHandle = CastRayPointToPoint( coordFrom.x, coordFrom.y, coordFrom.z, coordTo.x, coordTo.y, coordTo.z, 10, GetPlayerPed( -1 ), 0 )
    local _, _, _, _, vehicle = GetRaycastResult( rayHandle )
    return vehicle
end

-- Shows a notification on the player's screen 
function ShowNotification( text )
    SetNotificationTextEntry( "STRING" )
    AddTextComponentString( text )
    DrawNotification( false, false )
end

-- hands up 
Citizen.CreateThread(function()
    local dict = "missminuteman_1ig_2"
    
	RequestAnimDict(dict)
	while not HasAnimDictLoaded(dict) do
		Citizen.Wait(100)
	end
    local handsup = false
	while true do
		Citizen.Wait(0)
		if IsControlJustReleased(1, 323) then --Start holding X
            if not handsup then
                TaskPlayAnim(GetPlayerPed(-1), dict, "handsup_enter", 8.0, 8.0, -1, 50, 0, false, false, false)
                handsup = true
            else
                handsup = false
                ClearPedTasks(GetPlayerPed(-1))
            end
        end
    end
end)
	


--News Camera--

local holdingCam = false
local usingCam = false
local holdingMic = false
local usingMic = false
local holdingBmic = false
local usingBmic = false
local camModel = "prop_v_cam_01"
local camanimDict = "missfinale_c2mcs_1"
local camanimName = "fin_c2_mcs_1_camman"
local micModel = "p_ing_microphonel_01"
local micanimDict = "missheistdocksprep1hold_cellphone"
local micanimName = "hold_cellphone"
local bmicModel = "prop_v_bmike_01"
local bmicanimDict = "missfra1"
local bmicanimName = "mcs2_crew_idle_m_boom"
local bmic_net = nil
local mic_net = nil
local cam_net = nil
local UI = { 
	x =  0.000 ,
	y = -0.001 ,
}

---------------------------------------------------------------------------
-- Toggling Cam --
---------------------------------------------------------------------------
RegisterNetEvent("Cam:ToggleCam")
AddEventHandler("Cam:ToggleCam", function()
    if not holdingCam then
        RequestModel(GetHashKey(camModel))
        while not HasModelLoaded(GetHashKey(camModel)) do
            Citizen.Wait(100)
        end
		
        local plyCoords = GetOffsetFromEntityInWorldCoords(GetPlayerPed(PlayerId()), 0.0, 0.0, -5.0)
        local camspawned = CreateObject(GetHashKey(camModel), plyCoords.x, plyCoords.y, plyCoords.z, 1, 1, 1)
        Citizen.Wait(1000)
        local netid = ObjToNet(camspawned)
        SetNetworkIdExistsOnAllMachines(netid, true)
        NetworkSetNetworkIdDynamic(netid, true)
        SetNetworkIdCanMigrate(netid, false)
        AttachEntityToEntity(camspawned, GetPlayerPed(PlayerId()), GetPedBoneIndex(GetPlayerPed(PlayerId()), 28422), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1, 1, 0, 1, 0, 1)
        TaskPlayAnim(GetPlayerPed(PlayerId()), 1.0, -1, -1, 50, 0, 0, 0, 0) -- 50 = 32 + 16 + 2
        TaskPlayAnim(GetPlayerPed(PlayerId()), camanimDict, camanimName, 1.0, -1, -1, 50, 0, 0, 0, 0)
        cam_net = netid
        holdingCam = true
		DisplayNotification("To enter News cam press ~INPUT_PICKUP~ \nTo Enter Movie Cam press ~INPUT_INTERACTION_MENU~")
    else
        ClearPedSecondaryTask(GetPlayerPed(PlayerId()))
        DetachEntity(NetToObj(cam_net), 1, 1)
        DeleteEntity(NetToObj(cam_net))
        cam_net = nil
        holdingCam = false
        usingCam = false
    end
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		if holdingCam then
			while not HasAnimDictLoaded(camanimDict) do
				RequestAnimDict(camanimDict)
				Citizen.Wait(100)
			end

			if not IsEntityPlayingAnim(PlayerPedId(), camanimDict, camanimName, 3) then
				TaskPlayAnim(GetPlayerPed(PlayerId()), 1.0, -1, -1, 50, 0, 0, 0, 0) -- 50 = 32 + 16 + 2
				TaskPlayAnim(GetPlayerPed(PlayerId()), camanimDict, camanimName, 1.0, -1, -1, 50, 0, 0, 0, 0)
			end
				
			DisablePlayerFiring(PlayerId(), true)
			DisableControlAction(0,25,true) -- disable aim
			DisableControlAction(0, 44,  true) -- INPUT_COVER
			DisableControlAction(0,37,true) -- INPUT_SELECT_WEAPON
			SetCurrentPedWeapon(GetPlayerPed(-1), GetHashKey("WEAPON_UNARMED"), true)
		end
	end
end)

---------------------------------------------------------------------------
-- Cam Functions --
---------------------------------------------------------------------------

local fov_max = 70.0
local fov_min = 5.0
local zoomspeed = 10.0
local speed_lr = 8.0
local speed_ud = 8.0

local camera = false
local fov = (fov_max+fov_min)*0.5

---------------------------------------------------------------------------
-- Movie Cam --
---------------------------------------------------------------------------

Citizen.CreateThread(function()
	while true do

		Citizen.Wait(10)

		local lPed = GetPlayerPed(-1)
		local vehicle = GetVehiclePedIsIn(lPed)

		if holdingCam and IsControlJustReleased(1, 244) then
			movcamera = true

			SetTimecycleModifier("default")

			SetTimecycleModifierStrength(0.3)
			
			local scaleform = RequestScaleformMovie("security_camera")

			while not HasScaleformMovieLoaded(scaleform) do
				Citizen.Wait(10)
			end


			local lPed = GetPlayerPed(-1)
			local vehicle = GetVehiclePedIsIn(lPed)
			local cam1 = CreateCam("DEFAULT_SCRIPTED_FLY_CAMERA", true)

			AttachCamToEntity(cam1, lPed, 0.0,0.0,1.0, true)
			SetCamRot(cam1, 2.0,1.0,GetEntityHeading(lPed))
			SetCamFov(cam1, fov)
			RenderScriptCams(true, false, 0, 1, 0)
			PushScaleformMovieFunction(scaleform, "security_camera")
			PopScaleformMovieFunctionVoid()

			while movcamera and not IsEntityDead(lPed) and (GetVehiclePedIsIn(lPed) == vehicle) and true do
				if IsControlJustPressed(0, 177) then
					PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
					movcamera = false
				end
				
				SetEntityRotation(lPed, 0, 0, new_z,2, true)

				local zoomvalue = (1.0/(fov_max-fov_min))*(fov-fov_min)
				CheckInputRotation(cam1, zoomvalue)

				HandleZoom(cam1)
				HideHUDThisFrame()

				drawRct(UI.x + 0.0, 	UI.y + 0.0, 1.0,0.15,0,0,0,255) -- Top Bar
				DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255)
				drawRct(UI.x + 0.0, 	UI.y + 0.85, 1.0,0.16,0,0,0,255) -- Bottom Bar
				
				local camHeading = GetGameplayCamRelativeHeading()
				local camPitch = GetGameplayCamRelativePitch()
				if camPitch < -70.0 then
					camPitch = -70.0
				elseif camPitch > 42.0 then
					camPitch = 42.0
				end
				camPitch = (camPitch + 70.0) / 112.0
				
				if camHeading < -180.0 then
					camHeading = -180.0
				elseif camHeading > 180.0 then
					camHeading = 180.0
				end
				camHeading = (camHeading + 180.0) / 360.0
				
				Citizen.InvokeNative(0xD5BB4025AE449A4E, GetPlayerPed(-1), "Pitch", camPitch)
				Citizen.InvokeNative(0xD5BB4025AE449A4E, GetPlayerPed(-1), "Heading", camHeading * -1.0 + 1.0)
				
				Citizen.Wait(10)
			end

			movcamera = false
			ClearTimecycleModifier()
			fov = (fov_max+fov_min)*0.5
			RenderScriptCams(false, false, 0, 1, 0)
			SetScaleformMovieAsNoLongerNeeded(scaleform)
			DestroyCam(cam1, false)
			SetNightvision(false)
			SetSeethrough(false)
		end
	end
end)

---------------------------------------------------------------------------
-- News Cam --
---------------------------------------------------------------------------

Citizen.CreateThread(function()
	while true do

		Citizen.Wait(10)

		local lPed = GetPlayerPed(-1)
		local vehicle = GetVehiclePedIsIn(lPed)

		if holdingCam and IsControlJustReleased(1, 38) then
			newscamera = true

			SetTimecycleModifier("default")

			SetTimecycleModifierStrength(0.3)
			
			local scaleform = RequestScaleformMovie("security_camera")
			local scaleform2 = RequestScaleformMovie("breaking_news")


			while not HasScaleformMovieLoaded(scaleform) do
				Citizen.Wait(10)
			end
			while not HasScaleformMovieLoaded(scaleform2) do
				Citizen.Wait(10)
			end


			local lPed = GetPlayerPed(-1)
			local vehicle = GetVehiclePedIsIn(lPed)
			local cam2 = CreateCam("DEFAULT_SCRIPTED_FLY_CAMERA", true)

			AttachCamToEntity(cam2, lPed, 0.0,0.0,1.0, true)
			SetCamRot(cam2, 2.0,1.0,GetEntityHeading(lPed))
			SetCamFov(cam2, fov)
			RenderScriptCams(true, false, 0, 1, 0)
			PushScaleformMovieFunction(scaleform, "SET_CAM_LOGO")
			PushScaleformMovieFunction(scaleform2, "breaking_news")
			PopScaleformMovieFunctionVoid()

			while newscamera and not IsEntityDead(lPed) and (GetVehiclePedIsIn(lPed) == vehicle) and true do
				if IsControlJustPressed(1, 177) then
					PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
					newscamera = false
				end

				SetEntityRotation(lPed, 0, 0, new_z,2, true)
					
				local zoomvalue = (1.0/(fov_max-fov_min))*(fov-fov_min)
				CheckInputRotation(cam2, zoomvalue)

				HandleZoom(cam2)
				HideHUDThisFrame()

				DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255)
				DrawScaleformMovie(scaleform2, 0.5, 0.63, 1.0, 1.0, 255, 255, 255, 255)
				Breaking("BREAKING NEWS")
				
				local camHeading = GetGameplayCamRelativeHeading()
				local camPitch = GetGameplayCamRelativePitch()
				if camPitch < -70.0 then
					camPitch = -70.0
				elseif camPitch > 42.0 then
					camPitch = 42.0
				end
				camPitch = (camPitch + 70.0) / 112.0
				
				if camHeading < -180.0 then
					camHeading = -180.0
				elseif camHeading > 180.0 then
					camHeading = 180.0
				end
				camHeading = (camHeading + 180.0) / 360.0
				
				Citizen.InvokeNative(0xD5BB4025AE449A4E, GetPlayerPed(-1), "Pitch", camPitch)
				Citizen.InvokeNative(0xD5BB4025AE449A4E, GetPlayerPed(-1), "Heading", camHeading * -1.0 + 1.0)
				
				Citizen.Wait(10)
			end

			newscamera = false
			ClearTimecycleModifier()
			fov = (fov_max+fov_min)*0.5
			RenderScriptCams(false, false, 0, 1, 0)
			SetScaleformMovieAsNoLongerNeeded(scaleform)
			DestroyCam(cam2, false)
			SetNightvision(false)
			SetSeethrough(false)
		end
	end
end)

---------------------------------------------------------------------------
-- Events --
---------------------------------------------------------------------------

-- Activate camera
RegisterNetEvent('camera:Activate')
AddEventHandler('camera:Activate', function()
	camera = not camera
end)

--FUNCTIONS--
function HideHUDThisFrame()
	HideHelpTextThisFrame()
	HideHudAndRadarThisFrame()
	HideHudComponentThisFrame(1)
	HideHudComponentThisFrame(2)
	HideHudComponentThisFrame(3)
	HideHudComponentThisFrame(4)
	HideHudComponentThisFrame(6)
	HideHudComponentThisFrame(7)
	HideHudComponentThisFrame(8)
	HideHudComponentThisFrame(9)
	HideHudComponentThisFrame(13)
	HideHudComponentThisFrame(11)
	HideHudComponentThisFrame(12)
	HideHudComponentThisFrame(15)
	HideHudComponentThisFrame(18)
	HideHudComponentThisFrame(19)
end

function CheckInputRotation(cam, zoomvalue)
	local rightAxisX = GetDisabledControlNormal(0, 220)
	local rightAxisY = GetDisabledControlNormal(0, 221)
	local rotation = GetCamRot(cam, 2)
	if rightAxisX ~= 0.0 or rightAxisY ~= 0.0 then
		new_z = rotation.z + rightAxisX*-1.0*(speed_ud)*(zoomvalue+0.1)
		new_x = math.max(math.min(20.0, rotation.x + rightAxisY*-1.0*(speed_lr)*(zoomvalue+0.1)), -89.5)
		SetCamRot(cam, new_x, 0.0, new_z, 2)
	end
end

function HandleZoom(cam)
	local lPed = GetPlayerPed(-1)
	if not ( IsPedSittingInAnyVehicle( lPed ) ) then

		if IsControlJustPressed(0,241) then
			fov = math.max(fov - zoomspeed, fov_min)
		end
		if IsControlJustPressed(0,242) then
			fov = math.min(fov + zoomspeed, fov_max)
		end
		local current_fov = GetCamFov(cam)
		if math.abs(fov-current_fov) < 0.1 then
			fov = current_fov
		end
		SetCamFov(cam, current_fov + (fov - current_fov)*0.05)
	else
		if IsControlJustPressed(0,17) then
			fov = math.max(fov - zoomspeed, fov_min)
		end
		if IsControlJustPressed(0,16) then
			fov = math.min(fov + zoomspeed, fov_max)
		end
		local current_fov = GetCamFov(cam)
		if math.abs(fov-current_fov) < 0.1 then
			fov = current_fov
		end
		SetCamFov(cam, current_fov + (fov - current_fov)*0.05)
	end
end


---------------------------------------------------------------------------
-- Toggling Mic --
---------------------------------------------------------------------------
RegisterNetEvent("Mic:ToggleMic")
AddEventHandler("Mic:ToggleMic", function()
    if not holdingMic then
        RequestModel(GetHashKey(micModel))
        while not HasModelLoaded(GetHashKey(micModel)) do
            Citizen.Wait(100)
        end
		
		while not HasAnimDictLoaded(micanimDict) do
			RequestAnimDict(micanimDict)
			Citizen.Wait(100)
		end

        local plyCoords = GetOffsetFromEntityInWorldCoords(GetPlayerPed(PlayerId()), 0.0, 0.0, -5.0)
        local micspawned = CreateObject(GetHashKey(micModel), plyCoords.x, plyCoords.y, plyCoords.z, 1, 1, 1)
        Citizen.Wait(1000)
        local netid = ObjToNet(micspawned)
        SetNetworkIdExistsOnAllMachines(netid, true)
        NetworkSetNetworkIdDynamic(netid, true)
        SetNetworkIdCanMigrate(netid, false)
        AttachEntityToEntity(micspawned, GetPlayerPed(PlayerId()), GetPedBoneIndex(GetPlayerPed(PlayerId()), 60309), 0.055, 0.05, 0.0, 240.0, 0.0, 0.0, 1, 1, 0, 1, 0, 1)
        TaskPlayAnim(GetPlayerPed(PlayerId()), 1.0, -1, -1, 50, 0, 0, 0, 0) -- 50 = 32 + 16 + 2
        TaskPlayAnim(GetPlayerPed(PlayerId()), micanimDict, micanimName, 1.0, -1, -1, 50, 0, 0, 0, 0)
        mic_net = netid
        holdingMic = true
    else
        ClearPedSecondaryTask(GetPlayerPed(PlayerId()))
        DetachEntity(NetToObj(mic_net), 1, 1)
        DeleteEntity(NetToObj(mic_net))
        mic_net = nil
        holdingMic = false
        usingMic = false
    end
end)

---------------------------------------------------------------------------
-- Toggling Boom Mic --
---------------------------------------------------------------------------
RegisterNetEvent("Mic:ToggleBMic")
AddEventHandler("Mic:ToggleBMic", function()
    if not holdingBmic then
        RequestModel(GetHashKey(bmicModel))
        while not HasModelLoaded(GetHashKey(bmicModel)) do
            Citizen.Wait(100)
        end
		
        local plyCoords = GetOffsetFromEntityInWorldCoords(GetPlayerPed(PlayerId()), 0.0, 0.0, -5.0)
        local bmicspawned = CreateObject(GetHashKey(bmicModel), plyCoords.x, plyCoords.y, plyCoords.z, true, true, false)
        Citizen.Wait(1000)
        local netid = ObjToNet(bmicspawned)
        SetNetworkIdExistsOnAllMachines(netid, true)
        NetworkSetNetworkIdDynamic(netid, true)
        SetNetworkIdCanMigrate(netid, false)
        AttachEntityToEntity(bmicspawned, GetPlayerPed(PlayerId()), GetPedBoneIndex(GetPlayerPed(PlayerId()), 28422), -0.08, 0.0, 0.0, 0.0, 0.0, 0.0, 1, 1, 0, 1, 0, 1)
        TaskPlayAnim(GetPlayerPed(PlayerId()), 1.0, -1, -1, 50, 0, 0, 0, 0) -- 50 = 32 + 16 + 2
        TaskPlayAnim(GetPlayerPed(PlayerId()), bmicanimDict, bmicanimName, 1.0, -1, -1, 50, 0, 0, 0, 0)
        bmic_net = netid
        holdingBmic = true
    else
        ClearPedSecondaryTask(GetPlayerPed(PlayerId()))
        DetachEntity(NetToObj(bmic_net), 1, 1)
        DeleteEntity(NetToObj(bmic_net))
        bmic_net = nil
        holdingBmic = false
        usingBmic = false
    end
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		if holdingBmic then
			while not HasAnimDictLoaded(bmicanimDict) do
				RequestAnimDict(bmicanimDict)
				Citizen.Wait(100)
			end

			if not IsEntityPlayingAnim(PlayerPedId(), bmicanimDict, bmicanimName, 3) then
				TaskPlayAnim(GetPlayerPed(PlayerId()), 1.0, -1, -1, 50, 0, 0, 0, 0) -- 50 = 32 + 16 + 2
				TaskPlayAnim(GetPlayerPed(PlayerId()), bmicanimDict, bmicanimName, 1.0, -1, -1, 50, 0, 0, 0, 0)
			end
			
			DisablePlayerFiring(PlayerId(), true)
			DisableControlAction(0,25,true) -- disable aim
			DisableControlAction(0, 44,  true) -- INPUT_COVER
			DisableControlAction(0,37,true) -- INPUT_SELECT_WEAPON
			SetCurrentPedWeapon(GetPlayerPed(-1), GetHashKey("WEAPON_UNARMED"), true)
			
			if (IsPedInAnyVehicle(GetPlayerPed(-1), -1) and GetPedVehicleSeat(GetPlayerPed(-1)) == -1) or IsPedCuffed(GetPlayerPed(-1)) or holdingMic then
				ClearPedSecondaryTask(GetPlayerPed(-1))
				DetachEntity(NetToObj(bmic_net), 1, 1)
				DeleteEntity(NetToObj(bmic_net))
				bmic_net = nil
				holdingBmic = false
				usingBmic = false
			end
		end
	end
end)

---------------------------------------------------------------------------------------
-- misc functions --
---------------------------------------------------------------------------------------

function drawRct(x,y,width,height,r,g,b,a)
	DrawRect(x + width/2, y + height/2, width, height, r, g, b, a)
end

function Breaking(text)
		SetTextColour(255, 255, 255, 255)
		SetTextFont(8)
		SetTextScale(1.2, 1.2)
		SetTextWrap(0.0, 1.0)
		SetTextCentre(false)
		SetTextDropshadow(0, 0, 0, 0, 255)
		SetTextEdge(1, 0, 0, 0, 205)
		SetTextEntry("STRING")
		AddTextComponentString(text)
		DrawText(0.2, 0.85)
end

function Notification(message)
	SetNotificationTextEntry("STRING")
	AddTextComponentString(message)
	DrawNotification(0, 1)
end

function DisplayNotification(string)
	SetTextComponentFormat("STRING")
	AddTextComponentString(string)
    DisplayHelpTextFromStringLabel(0, 0, 1, -1)
end


--Anti Seat Shuffle--

local disableShuffle = true
function disableSeatShuffle(flag)
	disableShuffle = flag
end

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		if IsPedInAnyVehicle(GetPlayerPed(-1), false) and disableShuffle then
			if GetPedInVehicleSeat(GetVehiclePedIsIn(GetPlayerPed(-1), false), 0) == GetPlayerPed(-1) then
				if GetIsTaskActive(GetPlayerPed(-1), 165) then
					SetPedIntoVehicle(GetPlayerPed(-1), GetVehiclePedIsIn(GetPlayerPed(-1), false), 0)
				end
			end
		end
	end
end)

RegisterNetEvent("SeatShuffle")
AddEventHandler("SeatShuffle", function()
	if IsPedInAnyVehicle(GetPlayerPed(-1), false) then
		disableSeatShuffle(false)
		Citizen.Wait(5000)
		disableSeatShuffle(true)
	else
		CancelEvent()
	end
end)

RegisterCommand("s", function(source, args, raw) --change command here
    TriggerEvent("SeatShuffle")
end, false) --False, allow everyone to run it

--disable Ai--

Citizen.CreateThread(function()
	while true do
		Wait(0)
		for i = 1, 12 do
			EnableDispatchService(i, false)
		end
		SetPlayerWantedLevel(PlayerId(), 0, false)
		SetPlayerWantedLevelNow(PlayerId(), false)
		SetPlayerWantedLevelNoDrop(PlayerId(), 0, false)
	end
end)

--Handscrossed--

Citizen.CreateThread(function()
    local dict = "amb@world_human_hang_out_street@female_arms_crossed@base"
    
	RequestAnimDict(dict)
	while not HasAnimDictLoaded(dict) do
		Citizen.Wait(100)
	end
    local handsup = false
	while true do
		Citizen.Wait(0)
		if IsControlJustPressed(1, 289) then --Start holding g
            if not handsup then
                TaskPlayAnim(GetPlayerPed(-1), dict, "base", 8.0, 8.0, -1, 50, 0, false, false, false)
                handsup = true
            else
                handsup = false
                ClearPedTasks(GetPlayerPed(-1))
            end
        end
    end
end)

-- No Bullet proof tyres --

showMessage = false -- Show the message? https://faxes.zone/imagebanks/45ik2.png
restrictMessage = "~r~This mod is restricted." -- Message displayed if one is found with bullet proof tires

--- Code ---

function ShowNotification(text)
    SetNotificationTextEntry("STRING")
	AddTextComponentString(text)
	DrawNotification(false, false)
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(500)
        local ped = GetPlayerPed(-1)
        local veh = GetVehiclePedIsUsing(ped)
        
        if IsPedInAnyVehicle(ped, false) then
            if not GetVehicleTyresCanBurst(veh) then
                SetVehicleTyresCanBurst(veh, true)
                if showMessage then
                    ShowNotification(restrictMessage)
                end
            end
        end
	end
end)


--Player Tow--

local currentlyTowedVehicle = nil

RegisterNetEvent('asser:tow')
AddEventHandler('asser:tow', function()
	
	local playerped = GetPlayerPed(-1)
	local vehicle = GetVehiclePedIsIn(playerped, true)
	
	local towmodel = GetHashKey('mule6')
	local isVehicleTow = IsVehicleModel(vehicle, towmodel)
			
	if isVehicleTow then
	
		local coordA = GetEntityCoords(playerped, 1)
		local coordB = GetOffsetFromEntityInWorldCoords(playerped, 0.0, 5.0, 0.0)
		local targetVehicle = getVehicleInDirection(coordA, coordB)
		
		if currentlyTowedVehicle == nil then
			if targetVehicle ~= 0 then
				if not IsPedInAnyVehicle(playerped, true) then
					if vehicle ~= targetVehicle then
						AttachEntityToEntity(targetVehicle, vehicle, 30, -0.3, -5.0, 0.7, 0.0, 0.0, 0.0, false, false, false, false, 20, true)
						currentlyTowedVehicle = targetVehicle
						TriggerEvent("chatMessage", "[TOW]", {255, 255, 0}, "Vehicle successfully attached to towtruck!")
					else
						TriggerEvent("chatMessage", "[TOW]", {255, 255, 0}, "Are you retarded? You cant tow your own towtruck with your own towtruck?")
					end
				end
			else
				TriggerEvent("chatMessage", "[TOW]", {255, 255, 0}, "Theres no vehicle to tow?")
			end
		else
			AttachEntityToEntity(currentlyTowedVehicle, vehicle, 20, -0.5, -12.0, 1.0, 0.0, 0.0, 0.0, false, false, false, false, 20, true)
			DetachEntity(currentlyTowedVehicle, true, true)
			currentlyTowedVehicle = nil
			TriggerEvent("chatMessage", "[TOW]", {255, 255, 0}, "The vehicle has been successfully detached!")
		end
	end
end)

function getVehicleInDirection(coordFrom, coordTo)
	local rayHandle = CastRayPointToPoint(coordFrom.x, coordFrom.y, coordFrom.z, coordTo.x, coordTo.y, coordTo.z, 10, GetPlayerPed(-1), 0)
	local a, b, c, d, vehicle = GetRaycastResult(rayHandle)
	return vehicle
end

-- Rich Presence --

local appid = "532712129195802634" -- Make an application @ https://discordapp.com/developers/applications/ ID can be found there.
local asset = "logo" -- Go to https://discordapp.com/developers/applications/APPID/rich-presence/assets

function SetRP()
    local name = GetPlayerName(PlayerId())
    local id = GetPlayerServerId(PlayerId())

    SetRichPresence(name .. ' is playing on Vanity')
    SetDiscordAppId(appid)
    SetDiscordRichPresenceAsset(asset)
end

Citizen.CreateThread(function()
    
    SetRP()
    
    while true do
        Citizen.Wait(2500)
        SetRP()
    end

end)



-- Train --


PayWithBank 			= 0		-- Change this to 1 if you want users to pay with bank card (NOTE: Do implement your OWN banking system here please!)
UserBankIDi 			= 3		-- 1 = Maze, 2 = Bank Of Liberty, 3 = Fleeca  (This will show the corresponding message when the player doesn't have enoug money)
AllowEnterTrainWanted		= 0		-- Change to 1 if you want to allow players to ENTER the train when they have a wanted level
TicketPrice			= 25		-- Change to any value YOU think is suitable for a Metro Ticket in your (RP) Server
StationsExitScanRadius		= 15.0		-- I would RECOMMEND to leave it at 15 for best detection in trains, this variable sets the 'scan radius size' per station marker.
						-- NOTE: The StationsExitScanRadius HAS TO BE A FLOAT! (15.0 for example (which is the default!))

UseTwoMetros			= 1		-- KEEP IN MIND: When using two Metro's, players on one of the trams CAN be 'thrown out' when the trams pass eachother
						-- since the Metro's will PASS THROUGH EACH OTHER at some point! (this is inevitable! since the Metro track is just ONE TRACK!)
						-- it looks like they are two tracks in the game, but at both ends it will make a large 'u turn'!
						-- so if you do NOT want your players to be thrown out (and POSSIBLY killed) by a Metro, then set this value to 0!
						-- When set to 0, the script will only spawn ONE Metro Train instead of two (each in opposite direction)

ReportTerroristOnMetro	= false			-- When set to true the player will get an INSTANT wanted level of 4 when shooting on the Metro,
						-- this to 'contribute' to 'terroristic behavior' realism on (Real-Life) RP servers (where it's not normal either to
						-- just (randomly) shoot while on/in public transportation!) if you want to ENABLE shooting from the Metro (as passenger)
						-- then change this value to false
--===================================================
-- Variables used BY the script, do NOT modify them
-- unless you know what you are doing!
-- Modifying these might/will result in undesired
-- behaviour and/or script breaking!
--===================================================
IsPlayerNearMetro = false
IsPlayerInMetro = false
PlayerHasMetroTicket = false
IsPlayerUsingTicketMachine = false
ShowingExitMetroMessage = false

-- These are the locations of which 'the host' (well his/her script) will
-- pick a random location to spawn a new (Freight) train
TrainLocations = {
	{2533.0,2833.0,38.0},
	{2606.0,2927.0,40.0},
	{2463.0,3872.0,38.8},
	{1164.0,6433.0,32.0},
	{537.0,-1324.1,29.1},
	{219.1,-2487.7,6.0}
}

--===================================================
-- These are radius locations (multiple per station)
-- to detect if the player can exit the Metro
--===================================================
local XNLMetroScanPoints = {
	{XNLStationid=0, x=230.82389831543, y=-1204.0643310547, z=38.902523040771},
	{XNLStationid=0, x=249.59216308594, y=-1204.7095947266, z=38.92488861084},
	{XNLStationid=0, x=270.33166503906, y=-1204.5366210938, z=38.902912139893},
	{XNLStationid=0, x=285.96697998047, y=-1204.2261962891, z=38.929733276367},
	{XNLStationid=0, x=304.13528442383, y=-1204.3720703125, z=38.892612457275},
	{XNLStationid=1, x=-294.53421020508, y=-353.38571166992, z=10.063089370728},
	{XNLStationid=1, x=-294.96997070313, y=-335.69766235352, z=10.06309223175},
	{XNLStationid=1, x=-294.66772460938, y=-318.29565429688, z=10.063152313232},
	{XNLStationid=1, x=-294.73403930664, y=-303.77200317383, z=10.063160896301},
	{XNLStationid=1, x=-294.84133911133, y=-296.04568481445, z=10.063159942627},
	{XNLStationid=2, x=-795.28063964844, y=-126.3436050415, z=19.950298309326},
	{XNLStationid=2, x=-811.87170410156, y=-136.16409301758, z=19.950319290161},
	{XNLStationid=2, x=-819.25689697266, y=-140.25764465332, z=19.95037651062},
	{XNLStationid=2, x=-826.06652832031, y=-143.90898132324, z=19.95037651062},
	{XNLStationid=2, x=-839.2587890625, y=-151.32421875, z=19.950378417969},
	{XNLStationid=2, x=-844.77874755859, y=-154.31440734863, z=19.950380325317},
	{XNLStationid=3, x=-1366.642578125, y=-440.04803466797, z=15.045327186584},
	{XNLStationid=3, x=-1361.4998779297, y=-446.50497436523, z=15.045324325562},
	{XNLStationid=3, x=-1357.4061279297, y=-453.40963745117, z=15.045320510864},
	{XNLStationid=3, x=-1353.4593505859, y=-461.88238525391, z=15.045323371887},
	{XNLStationid=3, x=-1346.1264648438, y=-474.15142822266, z=15.045383453369},
	{XNLStationid=3, x=-1338.1717529297, y=-488.97756958008, z=15.045383453369},
	{XNLStationid=3, x=-1335.0261230469, y=-493.50796508789, z=15.045380592346},
	{XNLStationid=4, x=-530.67529296875, y=-673.33935546875, z=11.808959960938},
	{XNLStationid=4, x=-517.35559082031, y=-672.76635742188, z=11.808965682983},
	{XNLStationid=4, x=-499.44836425781, y=-673.37664794922, z=11.808973312378},
	{XNLStationid=4, x=-483.1321105957, y=-672.68438720703, z=11.809024810791},
	{XNLStationid=4, x=-468.05545043945, y=-672.74371337891, z=11.80902671814},
	{XNLStationid=5, x=-206.90379333496, y=-1014.9454345703, z=30.138082504272},
	{XNLStationid=5, x=-212.65534973145, y=-1031.6101074219, z=30.208702087402},
	{XNLStationid=5, x=-212.65534973145, y=-1031.6101074219, z=30.208702087402},
	{XNLStationid=5, x=-217.0216217041, y=-1042.4768066406, z=30.573789596558},
	{XNLStationid=5, x=-221.29409790039, y=-1054.5914306641, z=30.13950920105},
	{XNLStationid=6, x=101.89681243896, y=-1714.7589111328, z=30.112174987793},
	{XNLStationid=6, x=113.05246734619, y=-1724.7247314453, z=30.111650466919},
	{XNLStationid=6, x=122.72943878174, y=-1731.7276611328, z=30.54141998291},
	{XNLStationid=6, x=132.55198669434, y=-1739.7276611328, z=30.109527587891},
	{XNLStationid=7, x=-532.24133300781, y=-1263.6896972656, z=26.901586532593},
	{XNLStationid=7, x=-539.62115478516, y=-1280.5207519531, z=26.908163070679},
	{XNLStationid=7, x=-545.18548583984, y=-1290.9525146484, z=26.901586532593},
	{XNLStationid=7, x=-549.92230224609, y=-1302.8682861328, z=26.901605606079},
	{XNLStationid=8, x=-872.75714111328, y=-2289.3198242188, z=-11.732793807983},
	{XNLStationid=8, x=-875.53247070313, y=-2297.67578125, z=-11.732793807983},
	{XNLStationid=8, x=-880.05035400391, y=-2309.1235351563, z=-11.732788085938},
	{XNLStationid=8, x=-883.25482177734, y=-2321.3303222656, z=-11.732738494873},
	{XNLStationid=8, x=-890.087890625, y=-2336.2553710938, z=-11.732738494873},
	{XNLStationid=8, x=-894.92395019531, y=-2350.4128417969, z=-11.732727050781},
	{XNLStationid=9, x=-1062.7882080078, y=-2690.7492675781, z=-7.4116077423096},
	{XNLStationid=9, x=-1071.6839599609, y=-2701.8503417969, z=-7.410071849823},
	{XNLStationid=9, x=-1079.0869140625, y=-2710.7033691406, z=-7.4100732803345},
	{XNLStationid=9, x=-1086.8758544922, y=-2720.0673828125, z=-7.4101362228394},
	{XNLStationid=9, x=-1095.3796386719, y=-2729.8442382813, z=-7.4101347923279},
	{XNLStationid=9, x=-1103.7401123047, y=-2740.369140625, z=-7.4101300239563}
}

-- These are the 'exit points' to where the player is teleported with the short fade-out / fade-in
-- NOTE: XNLStationid is NOT used in this table, it's just here for user refrence!
 local XNLMetroEXITPoints = {
	{XNLStationid=0, x=294.46011352539, y=-1203.5991210938, z=38.902496337891, h=90.168075561523},
	{XNLStationid=1, x=-294.76913452148, y=-303.44619750977, z=10.063159942627, h=185.19216918945},
	{XNLStationid=2, x=-839.20843505859, y=-151.43312072754, z=19.950380325317, h=298.70877075195},
	{XNLStationid=3, x=-1337.9787597656, y=-488.36145019531, z=15.045375823975, h=28.487064361572},
	{XNLStationid=4, x=-474.07037353516, y=-673.10729980469, z=11.809032440186, h=81.799621582031},
	{XNLStationid=5, x=-222.13038635254, y=-1054.5043945313, z=30.139930725098, h=155.81954956055},
	{XNLStationid=6, x=133.13328552246, y=-1739.5617675781, z=30.109495162964, h=231.40335083008},
	{XNLStationid=7, x=-550.79998779297, y=-1302.4467773438, z=26.901605606079, h=155.53070068359},
	{XNLStationid=8, x=-891.87664794922, y=-2342.6486816406, z=-11.732737541199, h=353.59387207031},
	{XNLStationid=9, x=-1099.6376953125, y=-2734.8957519531, z=-7.410129070282, h=314.91424560547}
}


local TicketMachines = {'prop_train_ticket_02', 'v_serv_tu_statio3_'}
local anim = "mini@atmenter"

Citizen.CreateThread(function()
	function LoadTrainModels() -- f*ck your rails, too!

		tempmodel = GetHashKey("freight")
		RequestModel(tempmodel)
		while not HasModelLoaded(tempmodel) do
			--RequestModel(tempmodel)
			Citizen.Wait(0)
		end
		
		tempmodel = GetHashKey("freightcar")
		RequestModel(tempmodel)
		while not HasModelLoaded(tempmodel) do
			--RequestModel(tempmodel)
			Citizen.Wait(0)
		end
		
		tempmodel = GetHashKey("freightgrain")
		RequestModel(tempmodel)
		while not HasModelLoaded(tempmodel) do
			--RequestModel(tempmodel)
			Citizen.Wait(0)
		end
		
		tempmodel = GetHashKey("freightcont1")
		RequestModel(tempmodel)
		while not HasModelLoaded(tempmodel) do
			--RequestModel(tempmodel)
			Citizen.Wait(0)
		end
		
		tempmodel = GetHashKey("freightcont2")
		RequestModel(tempmodel)
		while not HasModelLoaded(tempmodel) do
			--RequestModel(tempmodel)
			Citizen.Wait(0)
		end
		
		tempmodel = GetHashKey("freighttrailer")
		RequestModel(tempmodel)
		while not HasModelLoaded(tempmodel) do
			--RequestModel(tempmodel)
			Citizen.Wait(0)
		end

		tempmodel = GetHashKey("tankercar")
		RequestModel(tempmodel)
		while not HasModelLoaded(tempmodel) do
			--RequestModel(tempmodel)
			Citizen.Wait(0)
		end
		
		tempmodel = GetHashKey("metrotrain")
		RequestModel(tempmodel)
		while not HasModelLoaded(tempmodel) do
			--RequestModel(tempmodel)
			Citizen.Wait(0)
		end
		
		tempmodel = GetHashKey("s_m_m_lsmetro_01")
		RequestModel(tempmodel)
		while not HasModelLoaded(tempmodel) do
			--RequestModel(tempmodel)
			Citizen.Wait(0)
		end
		print("XNL Log: Train Models Loaded" )
	end

	LoadTrainModels()

	RegisterNetEvent("StartTrain")
	function StartTrain()
		--Citizen.Trace("a train has arrived") -- whee i must be host, lucky me
		randomSpawn = math.random(#TrainLocations)
		x,y,z = TrainLocations[randomSpawn][1], TrainLocations[randomSpawn][2], TrainLocations[randomSpawn][3] -- get some random locations for our spawn
	
	
		-- For those whom are interested: The yesorno variable determines the direction of the train ;)
		yesorno = math.random(0,100)
		if yesorno >= 50 then -- untested, but seems to work /shrug
			yesorno = true
		elseif yesorno < 50 then
			yesorno = false
		end
		
		DeleteAllTrains()
		Wait(100)
		Train = CreateMissionTrain(math.random(0,22), x,y,z,yesorno)
		print("XNL Log: Train 1 created (Freight)." )

		MetroTrain = CreateMissionTrain(24,40.2,-1201.3,31.0,true) -- these ones have pre-defined spawns since they are a pain to set up
		print("XNL Log: Train 2 created (Metro)." )
		if UseTwoMetros == 1 then
			MetroTrain2 = CreateMissionTrain(24,-618.0,-1476.8,16.2,true)
			print("XNL Log: Train 3 created (Metro #2)." )
		end
		
		TrainDriverHash = GetHashKey("s_m_m_lsmetro_01")

		-- By making a refrence to the drivers we can call them further on to make them invincible for example.
		Driver1 = CreatePedInsideVehicle(Train, 26, TrainDriverHash, -1, 1, true)
		Driver2 = CreatePedInsideVehicle(MetroTrain, 26, TrainDriverHash, -1, 1, true)

		if UseTwoMetros == 1 then
			Driver3 = CreatePedInsideVehicle(MetroTrain2, 26, TrainDriverHash, -1, 1, true) -- create peds for the trains
		end
		
		--=========================================================
		-- XNL 'Addition': This SHOULD prevent the train driver(s)
		-- from getting shot or fleeing out of the train/tram when
		-- being targeted by the player.
		-- We have had several instances where the tram driver just
		-- teleported out of the tram to attack the player when it
		-- it was targeted (even without holding a weapon).
		-- I suspect that this behaviour is default in the game
		-- unless you override it.
		--=========================================================
		SetBlockingOfNonTemporaryEvents(driver1, true)
		SetPedFleeAttributes(driver1, 0, 0)
		SetEntityInvincible(driver1, true)
		SetEntityAsMissionEntity(Driver1, true)


		SetBlockingOfNonTemporaryEvents(Driver3, true)
		SetPedFleeAttributes(Driver3, 0, 0)
		SetEntityInvincible(Driver3, true)
		SetEntityAsMissionEntity(Driver3, true)
	
		SetEntityAsMissionEntity(Train,true,true) -- dunno if this does anything, just throwing it in for good measure
		SetEntityAsMissionEntity(MetroTrain,true,true)

		SetEntityInvincible(Train, true)
		SetEntityInvincible(MetroTrain, true)

		if UseTwoMetros == 1 then
			SetBlockingOfNonTemporaryEvents(Driver2, true)
			SetPedFleeAttributes(Driver2, 0, 0)
			SetEntityInvincible(Driver2, true)
			SetEntityAsMissionEntity(Driver2, true)
			SetEntityAsMissionEntity(MetroTrain2,true,true)
			SetEntityInvincible(MetroTrain2, true)
		end
		
		-- Cleanup from memory
		SetModelAsNoLongerNeeded(TrainDriverHash)

		print("XNL Log: Train System Started, you are currently 'host' for the trains." )
	end

	AddEventHandler("StartTrain", StartTrain)
end)

--=============================================================
-- Forces to call the Start Train funciton and thus making you
-- the host and instantly spawning NEW trains.
-- WARNING: This function is ONLY meant for testing purposes
-- when making extra script modifications for example.
-- It will NOT clean up exisiting trains and thus resulting in
-- a lot of 'cr*p' on your server. When you have used this
-- function manually and want to resume a 'normal run' of the
-- server you should close all clients to make sure that the
-- trains will dissapear.
--=============================================================
--RegisterCommand("XNLforcetrains",function(source, args)
--	StartTrain()
--end)


Citizen.CreateThread(function()
	ShowedBuyTicketHelper = false
	ShowedLeaveMetroHelper = false
	while true do
		Wait(10)
		
		if IsPlayerNearTicketMachine then
			if not IsPlayerUsingTicketMachine  then
				if not ShowedBuyTicketHelper then
					DisplayHelpText("Press ~INPUT_CONTEXT~ to to buy a metro ticket ($" .. TicketPrice .. ")")
					ShowedBuyTicketHelper = true
				end
			else
				ClearAllHelpMessages()				
				DisableControlAction(0, 201, true)
				DisableControlAction(1, 201, true)				
			end

			if IsControlJustPressed(0, 51) and PlayerHasMetroTicket then	
				SMS_Message("CHAR_LS_TOURIST_BOARD", "Los Santos Transit", "Tourist Information", "You already have a valid Metro Ticket, please go to one of the stations and board the Metro", true)
				Wait(3500) -- To avoid people 'spamming themselves' with the message popup (3500ms is 'just enough' to take the fun out of it :P)
			end
			
			if IsControlJustPressed(0, 51) and not PlayerHasMetroTicket then	
				IsPlayerUsingTicketMachine = true
				RequestAnimDict("mini@atmbase")		
				RequestAnimDict(anim)
				while not HasAnimDictLoaded(anim) do
					Wait(1)
				end

				SetCurrentPedWeapon(playerPed, GetHashKey("weapon_unarmed"), true)
				TaskLookAtEntity(playerPed, currentTicketMachine, 2000, 2048, 2)
				Wait(500)
				TaskGoStraightToCoord(playerPed, TicketMX, TicketMY, TicketMZ, 0.1, 4000, GetEntityHeading(currentTicketMachine), 0.5)				
				Wait(2000)
				TaskPlayAnim(playerPed, anim, "enter", 8.0, 1.0, -1, 0, 0.0, 0, 0, 0)
				RemoveAnimDict(animDict)
				Wait(4000)
				TaskPlayAnim(playerPed, "mini@atmbase", "base", 8.0, 1.0, -1, 0, 0.0, 0, 0, 0)
				RemoveAnimDict("mini@atmbase")				
				Wait(500)
				PlaySoundFrontend(-1, "ATM_WINDOW", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
				
				RequestAnimDict("mini@atmexit")
				while not HasAnimDictLoaded("mini@atmexit") do
					Wait(1)
				end
				TaskPlayAnim(playerPed, "mini@atmexit", "exit", 8.0, 1.0, -1, 0, 0.0, 0, 0, 0)
				RemoveAnimDict("mini@atmexit")
				Wait(500)
				
				--=====================================================================================
				-- Put here the actual 'reader'/function that your server uses
				-- to calculate/get the players bank account saldo and cash money!
				-- Now they are just set 'hardcoded' to an high amount to make the
				-- script work for people whom don't read a single line of code
				-- and then instantly post "Hey, i can't even buy a ticket, the script is broken" :P
				-- 
				-- Nope it's NOT broken, it just needs a BIT of adapting to your server and it's
				-- money handling. Since we use a custom banking system we have much different calls 
				-- than others might have so i've decided to put it in here like this so that it
				-- functions for everyone when they want to test/try the script :)
				--=====================================================================================
				BankAmount = 10000    --StatGetInt("BANK_BALANCE",-1)
				PlayerCashAm = 10000  --StatGetInt("MP0_WALLET_BALANCE",-1)
				
				if PayWithBank == 1 then
					XNLUserMoney = BankAmount
				else
					XNLUserMoney = PlayerCashAm
				end

				--===================================================================
				-- Please note, that despite if you make your players pay with
				-- cash or by bank, it will always show the selected bank popup
				-- if the player doesn't have enough cash (this is NOT a bug!)
				-- if you want/need it differently you can adapt the code bellow ;)
				--==================================================================
				if XNLUserMoney < TicketPrice then
					if UserBankIDi == 1 then		  		-- Maze Bank
						BankIcon = "CHAR_BANK_MAZE"		
						BankName = "Maze Bank"
					end
					if UserBankIDi == 2 then				-- Bank Of Liberty
						BankIcon = "CHAR_BANK_BOL"
						BankName = "Bank Of Liberty"
					end
					
					if UserBankIDi == 3 then		  		-- Fleeca (Default Fallback to!)
						BankIcon = "CHAR_BANK_FLEECA"
						BankName = "Fleeca Bank"
					end
					SMS_Message(BankIcon, BankName, "Account Information", "Transaction failed, you do not have sufficient funds.", true)
				else
					if PayWithBank == 1 then
						-- Put YOUR code to deduct the amount from the players BANK account here
						-- 'Basic Example':  PlayerBankMoney = PlayerBankMoney - TicketPrice
					else
						-- Put YOUR code to deduct the amount from the players CASH money account here
						-- 'Basic Example':  PlayerCash = PlayerCash - TicketPrice
					end
				
					SMS_Message("CHAR_LS_TOURIST_BOARD", "Los Santos Transit", "Tourist Information", "Thank you for your purchase, your ticket will be valid for the current session.", true)
					PlayerHasMetroTicket = true
				end
				
				IsPlayerUsingTicketMachine = false
			end
		else
			ShowedBuyTicketHelper = false
		end
		


		-- E/Action key (There will only be checked for trains when the player presses the action key)
		-- This Section is used to ENTER the Metro
		if IsControlJustPressed(0, 51) then	
			playerPed = PlayerPedId()
			x,y,z = table.unpack(GetEntityCoords(playerPed, true))
			IsPlayerInVehicle = IsPedInAnyVehicle(playerPed, true)
			SkipReEnterCheck = false
			
			if IsPlayerInMetro then
				if XNLCanPlayerExitTrain() then
					if not XNLTeleportPlayerToNearestMetroExit() then
						SMS_Message("CHAR_LS_TOURIST_BOARD", "Los Santos Transit", "Tourist Information", "Sorry, it seems that you pressed a little bit to late, you'll have to wait for the next station.", true)
					end
					SkipReEnterCheck = true -- This variable is used to prevent the character from directly trying to re-enter the Metro after leaving it.
				else
					XNLGenMess = "Sir"
					if XNLIsPedFemale(playerPed) then
						XNLGenMess = "Miss"
					end
					SMS_Message("CHAR_LS_TOURIST_BOARD", "Los Santos Transit", "Tourist Information", "Sorry " .. XNLGenMess .. ", but it's not allowed to randomly exit the Metro. Please wait for the next station!", true)
				end
			end
			
			--===============================================
			-- Make sure the player is NOT in a vehicle and 
			-- NOT already on the Metro
			--===============================================
			if not IsPlayerNearMetro and not IsPlayerInMetro and not SkipReEnterCheck then
				if not IsPlayerInVehicle then
					local coordA = GetEntityCoords(GetPlayerPed(-1), 1)
					local coordB = GetOffsetFromEntityInWorldCoords(GetPlayerPed(-1), 0.0, 3.0, 0.0)
					local Metro = getVehicleInDirection(coordA, coordB)
					if DoesEntityExist(Metro) then
						if GetEntityModel(Metro) == GetHashKey("metrotrain") then
							if not PlayerHasMetroTicket	then
									--==========================================================================
									-- Notify the player he/she needs to buy a ticket before entering the metro
									--==========================================================================
									SMS_Message("CHAR_LS_TOURIST_BOARD", "Los Santos Transit", "Tourist Information", "Sorry, You will need to buy a LST Metro Ticket first.", true)
							else
								if IsPlayerWantedLevelGreater(PlayerId(), 0) and AllowEnterTrainWanted == 0 then
									--==========================================================================
									-- If the player's wanted level is greater than 0, he/she will be
									-- denied to ENTER the Metro.
									-- If he/she GETS WHILE wanted on the train, we will handle that furher on
									--==========================================================================
									SMS_Message("CHAR_LS_TOURIST_BOARD", "Los Santos Transit", "Tourist Information", "Sorry we do not allow futugives in our Metro's. All passengers should be able to travel safely!", true)
								else
									CurrentMetro = Metro
									MetroX, MetroY, MetroZ = table.unpack(GetOffsetFromEntityInWorldCoords(CurrentMetro, 0.0, 0.0, 0.0))
									IsPlayerNearMetro = true
									
									-- Extra Info: Use the commentented line bellow to put passengers on 
									-- a seat in the train. DO NOTE! that you will need to make a (simple)
									-- check to detect if the seat is not taken by a ped or another player!
									-- for the function bellow you can use inded 1 or 2 (the last parm)
									--SetPedIntoVehicle(GetPlayerPed(-1), Metro, 1) 
									SetEntityCoordsNoOffset(PlayerPedId(), MetroX, MetroY, MetroZ + 2.0)
									IsPlayerInMetro = true
									PlayerHasMetroTicket = false
									SMS_Message("CHAR_LS_TOURIST_BOARD", "Los Santos Transit", "Tourist Information", "You've entered the Metro, your ticket has been invalidated.", true)
								end
							end
						else
							IsPlayerNearMetro = false
						end
					else
						IsPlayerNearMetro = false
					end
				else
					if not DoesEntityExist(CurrentMetro) then
						IsPlayerNearMetro = false
					else
						if GetDistanceBetweenCoords(x,y,z, MetroX, MetroY, MetroZ, true) > 3.5 then
							IsPlayerNearMetro = false
						end
					end
				end
			end
		end


		--=============================================================
		-- Check if the player is in the Metro AND pressed the [E] key
		--=============================================================
		if IsPlayerInMetro then
			if ReportTerroristOnMetro == true then
				if GetPlayerWantedLevel(PlayerId()) < 4 then
					if IsPedShooting(GetPlayerPed(-1)) then
						SetPlayerWantedLevel(PlayerId(), 4, 0)
						SetPlayerWantedLevelNow(PlayerId(), 0)
						SMS_Message("CHAR_LS_TOURIST_BOARD", "Los Santos Transit", "Tourist Information", "We will NOT tolerate terrorist behaviour on our public transport vehicles!", true)
					end
				end
			end
			
			if not DoesEntityExist(CurrentMetro) then
				-- Not ANY clue on when this might happen haha, but it's a funny message and error handler in one :Phone_SoundSet_Default
				-- we have seen it happen once or so in MANY test rounds of the metro system that the metro just vanished, so this is to
				-- 'encounter' that POSSIBLE issue (which I presume has to do with de-syncing or so)
				IsPlayerNearMetro = false
				IsPlayerInMetro = false
				PlayerHasMetroTicket = true
				SMS_Message("CHAR_LS_TOURIST_BOARD", "Los Santos Transit", "Tourist Information", "Our Appologies, something has gone terribly wrong, you have received a free ticket!", true)
			else
				if IsPlayerInMetro then
					-- This will ensure that it will only show the 'how to leave metro' text while near/at a station
					if ShowingExitMetroMessage == true and not ShowedLeaveMetroHelper then
						DisplayHelpText("Press ~INPUT_CONTEXT~ to leave the metro")
						ShowedLeaveMetroHelper = true
					end
					
					-- This part detects if the player is further away than 15.0 units from the Metro he/she used
					MetroX, MetroY, MetroZ = table.unpack(GetOffsetFromEntityInWorldCoords(CurrentMetro, 0.0, 0.0, 0.0))
					x,y,z = table.unpack(GetEntityCoords(playerPed, true))
					if GetDistanceBetweenCoords(x,y,z, MetroX, MetroY, MetroZ, true) > 15.0 then
						IsPlayerNearMetro = false
						IsPlayerInMetro = false
						SMS_Message("CHAR_LS_TOURIST_BOARD", "Los Santos Transit", "Tourist Information", "Thank you for traveling with Los Santos Transit.", true)
					end
					
				end
			end
		end
		
	end
end)

Citizen.CreateThread(function()
	--=======================================================================================
	-- Note only do this 'check' every 550ms to prevent
	-- to much load in the game (taking in account many other scripts also running of course)
	--=======================================================================================
	ShowedEToEnterMetro = false
	while true do
		Wait(550)
		if IsPlayerInMetro then
			if XNLCanPlayerExitTrain() then
				ShowingExitMetroMessage = true
			else
				ShowingExitMetroMessage = false
				ShowedLeaveMetroHelper = false
			end
			ShowedEToEnterMetro = false
		end
		
		-- We only have to check this part if the player is NOT on the metro.
		if not IsPlayerInMetro then
			playerPed = PlayerPedId()
			IsPlayerInVehicle = IsPedInAnyVehicle(playerPed, true)
	
			-- And then ONLY check it if the player isn't in a vehicle either 
			-- Note: The way i'm using the metro, the game doesn't recognize it as being
			-- on/in a vehicle.
			if not IsPlayerInVehicle then
				
				-- Yes, yes I know, the function is called 'XNLCanPlayerEXITTrain', but it
				-- is also used to detect if the player is at one of the stations on foot :)
				if PlayerHasMetroTicket and XNLCanPlayerExitTrain() then
					if not ShowedEToEnterMetro then
						DisplayHelpText("Press ~INPUT_CONTEXT~ while facing (and near) the Metro to enter it.")
						ShowedEToEnterMetro = true
					end
				else
					ShowedEToEnterMetro = false
				end
			
				-- Only show the "Press [E] to buy...." message near the ticket machine if the player does NOT own a ticket already
				-- Do note that it IS possible to 'activate' the ticket machine again though (but will give a different message ;) )
				x,y,z = table.unpack(GetEntityCoords(playerPed, true))
				-- And then only need to keep checking (scanning cords) if the player is not near the Ticket Machine (anymore)
				if not IsPlayerNearTicketMachine then
					for k,v in pairs(TicketMachines) do
						TicketMachine = GetClosestObjectOfType(x, y, z, 0.75, GetHashKey(v), false)
						if DoesEntityExist(TicketMachine) then
							currentTicketMachine = TicketMachine
							TicketMX, TicketMY, TicketMZ = table.unpack(GetOffsetFromEntityInWorldCoords(TicketMachine, 0.0, -.85, 0.0))
							IsPlayerNearTicketMachine = true
						end
					end
				else
					if not DoesEntityExist(currentTicketMachine) then
						IsPlayerNearTicketMachine = false -- If for some (weird) reasons the ticked machine (suddenly)
					else								  --doesn't exist anymore, tell the script that the player isn't near one anymore
						if GetDistanceBetweenCoords(x,y,z, TicketMX, TicketMY, TicketMZ, true) > 2.0 then
							IsPlayerNearTicketMachine = false -- And do the same if the player is more than a radius of 2.0 away from the ticket machine
						end
					end
				end
			end
		end
	end
end)

-- This is the function which is used to display 'SMS Style messages'
-- If you need more/other icons to display, then make sure to check out:
-- https://wiki.gtanet.work/index.php?title=Notification_Pictures
-- YES YES, I KNOW! it's 'a competitor' :P but it's definitly a good
-- resource for fellow modders :)
function SMS_Message(NotiPic, SenderName, Subject, MessageText, PlaySound)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(MessageText)
    SetNotificationBackgroundColor(140)
    SetNotificationMessage(NotiPic, NotiPic, true, 4, SenderName, Subject, MessageText)
    DrawNotification(false, true)
	if PlaySound then
		PlaySoundFrontend(GetSoundId(), "Text_Arrive_Tone", "Phone_SoundSet_Default", true)
	end
end

-- This is the text 'helper' which is used at the top left for messages like 'Press [E] to buy ticket ($25)'
function DisplayHelpText(str)
	SetTextComponentFormat("STRING")
	AddTextComponentString(str)
	DisplayHelpTextFromStringLabel(0, 0, 1, -1)
	EndTextCommandDisplayHelp(0, 0, true, 2000)
end

-- Using a RayCast to detect if the player is trying to get into the train
-- This is needed since it's not possible (yet) to detect the train model with
-- the normal native calls
function getVehicleInDirection(coordFrom, coordTo)
	local rayHandle = CastRayPointToPoint(coordFrom.x, coordFrom.y, coordFrom.z, coordTo.x, coordTo.y, coordTo.z, 10, GetPlayerPed(-1), 0)
	local a, b, c, d, vehicle = GetRaycastResult(rayHandle)
	return vehicle
end


--==============================================
-- Simple yet effective function to check if
-- player is female or male (sine we only use
-- mp_f_freemode_01 and mp_m_freemode_01 on our
-- server) We need(ed) this function because for
-- some weird reason IsPedMale had some issues
-- with some scripts.
--==============================================
function XNLIsPedFemale(ped)
	if IsPedModel(ped, 'mp_f_freemode_01') then
		return true
	else
		return false
	end
end

function XNLCanPlayerExitTrain()
	playerPed = PlayerPedId()
	for _, item in pairs(XNLMetroScanPoints) do
		Px,Py,Pz = table.unpack(GetEntityCoords(playerPed, true))
		if GetDistanceBetweenCoords(Px,Py,Pz, item.x, item.y, item.z, true) < StationsExitScanRadius then
			return true -- The function DID detected the player within one of the radius markers at the stations
		end
	end
	return false -- The function did NOT detected the player within one of the radius markers at the stations
end

function XNLTeleportPlayerToNearestMetroExit()
	playerPed = PlayerPedId()
	for _, item in pairs(XNLMetroScanPoints) do
		Px,Py,Pz = table.unpack(GetEntityCoords(playerPed, true))
		if GetDistanceBetweenCoords(Px,Py,Pz, item.x, item.y, item.z, true) < StationsExitScanRadius then
			for _, item2 in pairs(XNLMetroEXITPoints) do
				if item.XNLStationid == item2.XNLStationid  then
					DoScreenFadeOut(800)
					while not IsScreenFadedOut() do
						Wait(10)
					end
					XNLNewX = item2.x -- The 'new' Player X position
					XNLNewY = item2.y -- The 'new' Player Y position
					XNLNewZ = item2.z -- The 'new' Player Z position
					XNLNewH = item2.h -- The 'new' Player Heading Direction
		
					SetEntityCoordsNoOffset(PlayerPedId(), XNLNewX, XNLNewY, XNLNewZ)
					SetEntityHeading(PlayerPedId(), XNLNewH)
		
					DoScreenFadeIn(800)
					while not IsScreenFadedIn() do
						Wait(10)
					end
					return true 
				end
			end
		end
	end
	return false -- The function did NOT detected the player within one of the radius markers at the stations
end

-- Helicopter --



-- config
local fov_max = 80.0
local fov_min = 10.0 -- max zoom level (smaller fov is more zoom)
local zoomspeed = 2.0 -- camera zoom speed
local speed_lr = 3.0 -- speed by which the camera pans left-right 
local speed_ud = 3.0 -- speed by which the camera pans up-down
local toggle_helicam = 51 -- control id of the button by which to toggle the helicam mode. Default: INPUT_CONTEXT (E)
local toggle_vision = 25 -- control id to toggle vision mode. Default: INPUT_AIM (Right mouse btn)
local toggle_rappel = 154 -- control id to rappel out of the heli. Default: INPUT_DUCK (X)
local toggle_spotlight = 183 -- control id to toggle the front spotlight Default: INPUT_PhoneCameraGrid (G)
local toggle_lock_on = 22 -- control id to lock onto a vehicle with the camera. Default is INPUT_SPRINT (spacebar)

-- Script starts here
local helicam = false
local polmav_hash = GetHashKey("polmav")
local fov = (fov_max+fov_min)*0.5
local vision_state = 0 -- 0 is normal, 1 is nightmode, 2 is thermal vision
Citizen.CreateThread(function()
	while true do
        Citizen.Wait(0)
		if IsPlayerInPolmav() then
			local lPed = GetPlayerPed(-1)
			local heli = GetVehiclePedIsIn(lPed)
			
			if IsHeliHighEnough(heli) then
				if IsControlJustPressed(0, toggle_helicam) then -- Toggle Helicam
					PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
					helicam = true
				end
				
				if IsControlJustPressed(0, toggle_rappel) then -- Initiate rappel
					Citizen.Trace("try to rappel")
					if GetPedInVehicleSeat(heli, 1) == lPed or GetPedInVehicleSeat(heli, 2) == lPed then
						PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
						TaskRappelFromHeli(GetPlayerPed(-1), 1)
					else
						SetNotificationTextEntry( "STRING" )
						AddTextComponentString("~r~Can't rappel from this seat")
						DrawNotification(false, false )
						PlaySoundFrontend(-1, "5_Second_Timer", "DLC_HEISTS_GENERAL_FRONTEND_SOUNDS", false) 
					end
				end
			end
			
			if IsControlJustPressed(0, toggle_spotlight)  and GetPedInVehicleSeat(heli, -1) == lPed then
				spotlight_state = not spotlight_state
				TriggerServerEvent("heli:spotlight", spotlight_state)
				PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
			end
			
		end
		
		if helicam then
			SetTimecycleModifier("heliGunCam")
			SetTimecycleModifierStrength(0.3)
			local scaleform = RequestScaleformMovie("HELI_CAM")
			while not HasScaleformMovieLoaded(scaleform) do
				Citizen.Wait(0)
			end
			local lPed = GetPlayerPed(-1)
			local heli = GetVehiclePedIsIn(lPed)
			local cam = CreateCam("DEFAULT_SCRIPTED_FLY_CAMERA", true)
			AttachCamToEntity(cam, heli, 0.0,0.0,-1.5, true)
			SetCamRot(cam, 0.0,0.0,GetEntityHeading(heli))
			SetCamFov(cam, fov)
			RenderScriptCams(true, false, 0, 1, 0)
			PushScaleformMovieFunction(scaleform, "SET_CAM_LOGO")
			PushScaleformMovieFunctionParameterInt(1) -- 0 for nothing, 1 for LSPD logo
			PopScaleformMovieFunctionVoid()
			local locked_on_vehicle = nil
			while helicam and not IsEntityDead(lPed) and (GetVehiclePedIsIn(lPed) == heli) and IsHeliHighEnough(heli) do
				if IsControlJustPressed(0, toggle_helicam) then -- Toggle Helicam
					PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
					helicam = false
				end
				if IsControlJustPressed(0, toggle_vision) then
					PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
					ChangeVision()
				end

				if locked_on_vehicle then
					if DoesEntityExist(locked_on_vehicle) then
						PointCamAtEntity(cam, locked_on_vehicle, 0.0, 0.0, 0.0, true)
						RenderVehicleInfo(locked_on_vehicle)
						if IsControlJustPressed(0, toggle_lock_on) then
							PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
							locked_on_vehicle = nil
							local rot = GetCamRot(cam, 2) -- All this because I can't seem to get the camera unlocked from the entity
							local fov = GetCamFov(cam)
							local old cam = cam
							DestroyCam(old_cam, false)
							cam = CreateCam("DEFAULT_SCRIPTED_FLY_CAMERA", true)
							AttachCamToEntity(cam, heli, 0.0,0.0,-1.5, true)
							SetCamRot(cam, rot, 2)
							SetCamFov(cam, fov)
							RenderScriptCams(true, false, 0, 1, 0)
						end
					else
						locked_on_vehicle = nil -- Cam will auto unlock when entity doesn't exist anyway
					end
				else
					local zoomvalue = (1.0/(fov_max-fov_min))*(fov-fov_min)
					CheckInputRotation(cam, zoomvalue)
					local vehicle_detected = GetVehicleInView(cam)
					if DoesEntityExist(vehicle_detected) then
						RenderVehicleInfo(vehicle_detected)
						if IsControlJustPressed(0, toggle_lock_on) then
							PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
							locked_on_vehicle = vehicle_detected
						end
					end
				end
				HandleZoom(cam)
				HideHUDThisFrame()
				PushScaleformMovieFunction(scaleform, "SET_ALT_FOV_HEADING")
				PushScaleformMovieFunctionParameterFloat(GetEntityCoords(heli).z)
				PushScaleformMovieFunctionParameterFloat(zoomvalue)
				PushScaleformMovieFunctionParameterFloat(GetCamRot(cam, 2).z)
				PopScaleformMovieFunctionVoid()
				DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255)
				Citizen.Wait(0)
			end
			helicam = false
			ClearTimecycleModifier()
			fov = (fov_max+fov_min)*0.5 -- reset to starting zoom level
			RenderScriptCams(false, false, 0, 1, 0) -- Return to gameplay camera
			SetScaleformMovieAsNoLongerNeeded(scaleform) -- Cleanly release the scaleform
			DestroyCam(cam, false)
			SetNightvision(false)
			SetSeethrough(false)
		end
	end
end)

RegisterNetEvent('heli:spotlight')
AddEventHandler('heli:spotlight', function(serverID, state)
	local heli = GetVehiclePedIsIn(GetPlayerPed(GetPlayerFromServerId(serverID)), false)
	SetVehicleSearchlight(heli, state, false)
	Citizen.Trace("Set heli light state to "..tostring(state).." for serverID: "..serverID)
end)

function IsPlayerInPolmav()
	local lPed = GetPlayerPed(-1)
	local vehicle = GetVehiclePedIsIn(lPed)
	return IsVehicleModel(vehicle, polmav_hash)
end

function IsHeliHighEnough(heli)
	return GetEntityHeightAboveGround(heli) > 1.5
end

function ChangeVision()
	if vision_state == 0 then
		SetNightvision(true)
		vision_state = 1
	elseif vision_state == 1 then
		SetNightvision(false)
		SetSeethrough(true)
		vision_state = 2
	else
		SetSeethrough(false)
		vision_state = 0
	end
end

function HideHUDThisFrame()
	HideHelpTextThisFrame()
	HideHudAndRadarThisFrame()
	HideHudComponentThisFrame(19) -- weapon wheel
	HideHudComponentThisFrame(1) -- Wanted Stars
	HideHudComponentThisFrame(2) -- Weapon icon
	HideHudComponentThisFrame(3) -- Cash
	HideHudComponentThisFrame(4) -- MP CASH
	HideHudComponentThisFrame(13) -- Cash Change
	HideHudComponentThisFrame(11) -- Floating Help Text
	HideHudComponentThisFrame(12) -- more floating help text
	HideHudComponentThisFrame(15) -- Subtitle Text
	HideHudComponentThisFrame(18) -- Game Stream
end

function CheckInputRotation(cam, zoomvalue)
	local rightAxisX = GetDisabledControlNormal(0, 220)
	local rightAxisY = GetDisabledControlNormal(0, 221)
	local rotation = GetCamRot(cam, 2)
	if rightAxisX ~= 0.0 or rightAxisY ~= 0.0 then
		new_z = rotation.z + rightAxisX*-1.0*(speed_ud)*(zoomvalue+0.1)
		new_x = math.max(math.min(20.0, rotation.x + rightAxisY*-1.0*(speed_lr)*(zoomvalue+0.1)), -89.5) -- Clamping at top (cant see top of heli) and at bottom (doesn't glitch out in -90deg)
		SetCamRot(cam, new_x, 0.0, new_z, 2)
	end
end

function HandleZoom(cam)
	if IsControlJustPressed(0,241) then -- Scrollup
		fov = math.max(fov - zoomspeed, fov_min)
	end
	if IsControlJustPressed(0,242) then
		fov = math.min(fov + zoomspeed, fov_max) -- ScrollDown		
	end
	local current_fov = GetCamFov(cam)
	if math.abs(fov-current_fov) < 0.1 then -- the difference is too small, just set the value directly to avoid unneeded updates to FOV of order 10^-5
		fov = current_fov
	end
	SetCamFov(cam, current_fov + (fov - current_fov)*0.05) -- Smoothing of camera zoom
end

function GetVehicleInView(cam)
	local coords = GetCamCoord(cam)
	local forward_vector = RotAnglesToVec(GetCamRot(cam, 2))
	--DrawLine(coords, coords+(forward_vector*100.0), 255,0,0,255) -- debug line to show LOS of cam
	local rayhandle = CastRayPointToPoint(coords, coords+(forward_vector*200.0), 10, GetVehiclePedIsIn(GetPlayerPed(-1)), 0)
	local _, _, _, _, entityHit = GetRaycastResult(rayhandle)
	if entityHit>0 and IsEntityAVehicle(entityHit) then
		return entityHit
	else
		return nil
	end
end

function RenderVehicleInfo(vehicle)
	local model = GetEntityModel(vehicle)
	local vehname = GetLabelText(GetDisplayNameFromVehicleModel(model))
	local licenseplate = GetVehicleNumberPlateText(vehicle)
	SetTextFont(0)
	SetTextProportional(1)
	SetTextScale(0.0, 0.55)
	SetTextColour(255, 255, 255, 255)
	SetTextDropshadow(0, 0, 0, 0, 255)
	SetTextEdge(1, 0, 0, 0, 255)
	SetTextDropShadow()
	SetTextOutline()
	SetTextEntry("STRING")
	AddTextComponentString("Model: "..vehname.."\nPlate: "..licenseplate)
	DrawText(0.45, 0.9)
end

-- function HandleSpotlight(cam)
-- if IsControlJustPressed(0, toggle_spotlight) then
	-- PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
	-- spotlight_state = not spotlight_state
-- end
-- if spotlight_state then
	-- local rotation = GetCamRot(cam, 2)
	-- local forward_vector = RotAnglesToVec(rotation)
	-- local camcoords = GetCamCoord(cam)
	-- DrawSpotLight(camcoords, forward_vector, 255, 255, 255, 300.0, 10.0, 0.0, 2.0, 1.0)
-- end
-- end

function RotAnglesToVec(rot) -- input vector3
	local z = math.rad(rot.z)
	local x = math.rad(rot.x)
	local num = math.abs(math.cos(x))
	return vector3(-math.sin(z)*num, math.cos(z)*num, math.sin(x))
end

-- No Ai Police --

local pedDensity = 0.4
 
local trafficDensity = 0.5
local parkedVehicleDensity = 0.3
local randomVehicleDensity = 0.3

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if GetPlayerWantedLevel(PlayerId()) ~= 0 then
            SetPlayerWantedLevel(PlayerId(), 0, false)
            SetPlayerWantedLevelNow(PlayerId(), false)
        end
    end
end)

Citizen.CreateThread(function()
    for i = 1, 12 do
        Citizen.InvokeNative(0xDC0F817884CDD856, i, false)
    end
end)


Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
  SetCreateRandomCops(0)
  SetCreateRandomCopsOnScenarios(0)
  SetCreateRandomCopsNotOnScenarios(0)

  DisablePlayerVehicleRewards(PlayerId())
      SetPedDensityMultiplierThisFrame(pedDensity)
 
    -- Vehicle
    SetVehicleDensityMultiplierThisFrame(trafficDensity)
    SetRandomVehicleDensityMultiplierThisFrame(randomVehicleDensity)
    SetParkedVehicleDensityMultiplierThisFrame(parkedVehicleDensity)
 

end
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		SetEveryoneIgnorePlayer(GetPlayerPed(-1), true)
	end
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		SetParkedVehicleDensityMultiplierThisFrame(0.0)
	end
end)

RegisterCommand("tpcoords", function(source, args)
	print("command")
	print(args[1])
	SetPedCoordsKeepVehicle(GetPlayerPed(-1), args[1], args[2], args[3])
end)


-- Configuration

local button = 15 -- 167 (F6 by default)
local commandEnabled = false -- (false by default) If you set this to true, typing "/engine" in chat will also toggle your engine.


Citizen.CreateThread(function()
    if commandEnabled then
        RegisterCommand('engine', function() 
            toggleEngine()
        end, false)
    end
    while true do
        Citizen.Wait(0)
        local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
        
        if (IsControlJustReleased(0, button) or IsDisabledControlJustReleased(0, button)) and vehicle ~= nil and vehicle ~= 0 and GetPedInVehicleSeat(vehicle, 0) then
            toggleEngine()
        end
        
    end
end)

function toggleEngine()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle ~= nil and vehicle ~= 0 and GetPedInVehicleSeat(vehicle, 0) then
        SetVehicleEngineOn(vehicle, (not GetIsVehicleEngineRunning(vehicle)), false, true)
    end
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local pl = GetEntityCoords(GetPlayerPed(-1))
        if GetDistanceBetweenCoords(pl.x, pl.y, pl.z, 21.01, -1392.06, 29.33) < 2.0 then 
        DrawText3d(21.01, -1392.06, 29.33, "~w~[~g~E~w~] to clean your car") 
        if IsControlJustReleased(1, 38) then 
            SetVehicleDirtLevel(GetVehiclePedIsIn(GetPlayerPed(-1), false), 0)
            end
        end
    end
end)