local Keys = {
  ["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57,
  ["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177,
  ["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
  ["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
  ["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
  ["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70,
  ["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
  ["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
  ["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
}

ESX				= nil
PlayerData = nil
RadarBlip		= {}
HasAlreadyEnteredMarker = false
Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end
  for k, v in pairs(Config.Radars) do
		--radar
		RequestModel("prop_cctv_pole_01a")
		while not HasModelLoaded("prop_cctv_pole_01a") do
		Wait(1)
		end

		Radar = CreateObject(GetHashKey('prop_cctv_pole_01a'), v.x,v.y,v.z-7, true, true, true) -- http://gtan.codeshock.hu/objects/index.php?page=1&search=prop_cctv_pole_01a
		SetObjectTargettable(Radar, true)
		SetEntityHeading(Radar, v.heading-115)
		SetEntityAsMissionEntity(Radar, true, true)
		FreezeEntityPosition(Radar, true)
	end
  TriggerServerEvent('esx_jb_radars:getStautRadar')
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
  PlayerData = xPlayer
  if PlayerData.job.name == 'police' then
    TriggerEvent('esx_jb_radars:ShowRadarBlip')
  end
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
  PlayerData.job = job
  if PlayerData.job.name == 'police' then
    TriggerEvent('esx_jb_radars:ShowRadarBlip')
  else
    TriggerEvent('esx_jb_radars:RemoveRadarBlip')
  end
end)


RegisterNetEvent('esx_jb_radars:ShowRadarBlip')
AddEventHandler('esx_jb_radars:ShowRadarBlip', function()

	for k, v in pairs(Config.Radars) do
		--blip
		RadarBlip[k] = AddBlipForCoord(v.x,v.y,v.z)
		SetBlipColour(RadarBlip[k], 69)
		SetBlipScale(RadarBlip[k], 0.8)
		SetBlipAsShortRange(RadarBlip[k], true)
		BeginTextCommandSetBlipName("STRING")
		AddTextComponentString("Cam: " ..k.." ("..v.maxspeed..")")
		EndTextCommandSetBlipName(RadarBlip[k])
		-- SetBlipFlashTimer(RadarBlip[k], 10000)
	end
end)

RegisterNetEvent('esx_jb_radars:ShowRadarProp')
AddEventHandler('esx_jb_radars:ShowRadarProp', function()

	for k, v in pairs(Config.Radars) do
		--radar
		RequestModel("prop_cctv_pole_01a")
		while not HasModelLoaded("prop_cctv_pole_01a") do
		Wait(1)
		end

		Radar = CreateObject(GetHashKey('prop_cctv_pole_01a'), v.x,v.y,v.z-7, true, true, true) -- http://gtan.codeshock.hu/objects/index.php?page=1&search=prop_cctv_pole_01a
		SetObjectTargettable(Radar, true)
		SetEntityHeading(Radar, v.heading-115)
		SetEntityAsMissionEntity(Radar, true, true)
		FreezeEntityPosition(Radar, true)
	end
end)

RegisterNetEvent('esx_jb_radars:RemoveRadarBlip')
AddEventHandler('esx_jb_radars:RemoveRadarBlip', function()
	for k, v in pairs(Config.Radars) do
		RemoveBlip(RadarBlip[k])
	end
end)

local lastradar = nil
-- Determines if player is close enough to trigger cam
function HandleSpeedcam(speedcam, hasBeenFucked)
	local myPed = GetPlayerPed(-1)
	local playerPos = GetEntityCoords(myPed)
	local isInMarker  = false
	-- DrawMarker(1, speedcam.x, speedcam.y, speedcam.z, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 30.0, 30.0,1.0, 255.0, 0.0, 0.0, 100, false, true, 2, false, false, false, false)
	if (GetDistanceBetweenCoords(playerPos, speedcam.x, speedcam.y, speedcam.z, true) < Config.SpeedCamRange) and speedcam.disable ==false then
		isInMarker  = true
	end
	if isInMarker and not HasAlreadyEnteredMarker and lastradar==nil then
		HasAlreadyEnteredMarker = true
		lastradar = hasBeenFucked

		local vehicle = GetPlayersLastVehicle() -- gets the current vehicle the player is in.
		if (vehicle ~=nil) then
			if GetPedInVehicleSeat( vehicle, -1 ) == myPed then
				if GetVehicleClass(vehicle) ~= 18 then
					local kmhspeed = math.ceil(GetEntitySpeed(vehicle)* 3.6)

							if (tonumber(kmhspeed) > tonumber(speedcam.maxspeed)) then
                local vehicleProps  = ESX.Game.GetVehicleProperties(vehicle)
                local numberplate = GetVehicleNumberPlateText(vehicle)
                local driver = GetPedInVehicleSeat(vehicle, -1)
                local model = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))
                local s1, s2 = Citizen.InvokeNative( 0x2EB41072B4C1E4C0,speedcam.x, speedcam.y, speedcam.z, Citizen.PointerValueInt(), Citizen.PointerValueInt() )
      					local street1 = GetStreetNameFromHashKey(s1)
      					local street2 = GetStreetNameFromHashKey(s2)
                local primary, secondary = GetVehicleColours(vehicle)
                primary = Config.colorNames[tostring(primary)]
                secondary = Config.colorNames[tostring(secondary)]
                StartScreenEffect('RaceTurbo',  0,  false)
								TriggerServerEvent('esx_jb_radars:PayFine', numberplate, kmhspeed, speedcam.maxspeed, model,street1, street2 or 0)

							end
				end
			end

		end
	end

	if not isInMarker and HasAlreadyEnteredMarker and lastradar==hasBeenFucked then
		HasAlreadyEnteredMarker = false
		lastradar=nil
	end
end

-- -----------------------------------------------------------------------
-- ---------------------Threads-------------------------------------------
-- -----------------------------------------------------------------------

-- Thread to loop speedcams
Citizen.CreateThread(function()
  while true do
    Wait(0)
    for key, value in pairs(Config.Radars) do
        HandleSpeedcam(value, key)
    end
  end
end)


function dump(o, nb)
  if nb == nil then
    nb = 0
  end
   if type(o) == 'table' then
      local s = ''
      for i = 1, nb + 1, 1 do
        s = s .. "    "
      end
      s = '{\n'
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
          for i = 1, nb, 1 do
            s = s .. "    "
          end
         s = s .. '['..k..'] = ' .. dump(v, nb + 1) .. ',\n'
      end
      for i = 1, nb, 1 do
        s = s .. "    "
      end
      return s .. '}'
   else
      return tostring(o)
   end
end

RegisterNetEvent('esx_jb_radars:changeEtatCli')
AddEventHandler('esx_jb_radars:changeEtatCli',function(number,state)
  Config.Radars[number].disable = state
end)

RegisterNetEvent('esx_jb_radars:bombeRadar')
AddEventHandler('esx_jb_radars:bombeRadar',function()
  local radar = nil
  local myPed = GetPlayerPed(-1)
	local playerPos = GetEntityCoords(myPed)
  for i=1,#Config.Radars do

    if GetDistanceBetweenCoords(playerPos, Config.Radars[i].x, Config.Radars[i].y, Config.Radars[i].z, true) < 1.5 then
      radar = i
      break
    end
  end

  if radar ~= nil then
    if Config.Radars[radar].disable == false then
      TriggerServerEvent('esx_jb_radars:disable', radar)
      TriggerEvent('esx:showNotification','Vous avez taggé le radar')
    else
      TriggerEvent('esx:showNotification','Le radar est deja taggé')
    end
  else
      TriggerEvent('esx:showNotification','Pas de radar à proximité')
  end
end)





---------ajout whitelist
