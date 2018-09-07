ESX = nil
local vehList ={}
local whiteList ={}

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

function sendToDiscorda (name,message,text,color)
  local DiscordWebHook = Config.webhook
  -- Modify here your discordWebHook username = name, content = message,embeds = embeds

local embeds = {
    {
        ["title"]=message,
				["description"]=text,
        ["type"]="rich",
        ["color"] =color,
        ["footer"]=  {
            ["text"]= os.date("%d/%m/%Y %H:%M:%S"),
       },
    }
}



  if message == nil or message == '' then return FALSE end
  PerformHttpRequest(DiscordWebHook, function(err, text, headers) end, 'POST', json.encode({ username = name,embeds = embeds}), { ['Content-Type'] = 'application/json' })
end

RegisterServerEvent('esx_jb_radars:botalert')
AddEventHandler('esx_jb_radars:botalert',function(name,message,text,color)
	sendToDiscorda(name,message,text,Config.red)

end)





MySQL.ready(function ()
  local vehicles   = MySQL.Sync.fetchAll('SELECT * FROM owned_vehicles')
  for i=1, #vehicles, 1 do
    local vehicle = json.decode(vehicles[i].vehicle)
    if vehicle.plate ~= nil then
      table.insert(vehList, {plate = vehicle.plate,owner = vehicles[i].owner} )
    end
  end
end)


function GetOwnedVehicle(plate)
  local owner = 0
	for i=1, #vehList, 1 do
  		if string.match(vehList[i].plate,plate) ~= nil  then
  			owner = vehList[i].owner
        break
  		end
	end
	return owner
end

function GetSocietyVehicle(plate)
	for i=1,#Config.Plate_Soc, 1 do
		if string.find(plate,Config.Plate_Soc[i]) ~= nil then
			return true
		end
	end
end

function Bill(identifier,amount,plate,kmhspeed,maxspeed,player)
	Citizen.Wait(10000)
	MySQL.Async.execute(
		'INSERT INTO billing (identifier, sender, target_type, target, label, amount) VALUES (@identifier, @sender, @target_type, @target, @label, @amount)',
		{
			['@identifier']  = identifier,
			['@sender']      = "Radar fixe",
			['@target_type'] = 'society',
			['@target']      = 'society_police',
			['@label']       =  plate..", "..kmhspeed.."km/h a la place de "..maxspeed,
			['@amount']      = amount
		},
		function(rowsChanged)
		end
	)

end

function GetAmount(speed)
	if speed >= 50 then
		return 1000
	elseif speed >= 40 then
		return 500
	elseif speed >= 30 then
		return 300
	elseif speed >= 20  then
		return 200
	else
		return 100
	end
end

function IsWhiteList(plate)
  local found = false
  if plate ~= nil then
    for i = 1,#whiteList,1 do
      if string.find(plate,whiteList[i]) ~= nil then
        found = true
      end
    end
  end
  return found
end


RegisterServerEvent('esx_jb_radars:PayFine')
AddEventHandler('esx_jb_radars:PayFine', function (plate, kmhspeed, maxspeed, model,street1, street2,color)
	local _source = source
  local plate = plate
	local xPlayer = ESX.GetPlayerFromId(_source)
	local isVehSoc = GetSocietyVehicle(plate)
	local title = nil
	local color = Config.orange
	local speed = kmhspeed-maxspeed
	local amount = GetAmount(speed)
  local owner = GetOwnedVehicle(plate)
  if not IsWhiteList(plate) then
  	if isVehSoc then
  		title = 'Vehicule entreprise'
  		Bill(xPlayer.identifier,amount,plate,kmhspeed,maxspeed)
  		TriggerClientEvent('esx:showNotification', _source, "Votre vehicule de société a été ~r~flashé.")
  	elseif owner ~=0 then
  		title = 'Vehicule civile'
  		Bill(owner,amount,plate,kmhspeed,maxspeed)
  		TriggerClientEvent('esx:showNotification', _source, "Votre vehicule a été ~r~flashé.")
  	else
  		title = 'Vehicule inconnu'
  		color = Config.purple
  	end
    if speed >= 50 then
      color = Config.red
    end
  	sendToDiscorda('Excès de vitesse',title,'Modele : '..model..'\n Plaque : '..plate..'\nVitesse : '..kmhspeed.. '\nVitesse max : '..maxspeed..'\n Radar : '..street1  ,color)
  end
end)


local IsEnnabled = false
ESX.RegisterUsableItem('coyotte', function(source)
  local source = source
	if not IsEnnabled then
		IsEnnabled  = true
		TriggerClientEvent('esx_jb_radars:ShowRadarBlip', source)
		TriggerClientEvent('esx:ShowNotification',source, "Tu as activé ton coyotte.")
	else
		TriggerClientEvent('esx_jb_radars:RemoveRadarBlip', source)
		IsEnnabled = false
	end
end)

RegisterServerEvent('esx:onRemoveInventoryItem')
AddEventHandler('esx:onRemoveInventoryItem', function(source, item, count)
  if item.name ~= nil and item.name == 'coyotte' and item.count == 0 then
	IsEnnabled = false
	TriggerClientEvent('esx_jb_radars:RemoveRadarBlip', source)
	-- TriggerClientEvent('esx:showNotification', source, "Ton coyotte est désactifé.")
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


---hack des radars
RegisterServerEvent('esx_jb_radars:setWhiteList')
AddEventHandler('esx_jb_radars:setWhiteList', function (plate)
  if plate ~= nil then
    table.insert(whiteList,plate)
  end
end)

ESX.RegisterServerCallback('esx_jb_radars:getWhiteList', function(source, cb, WL)
  local list = {}
    if whiteList[1] ~= nil then
      for i=1,#whiteList do
        table.insert(list,whiteList[i])
      end
    end
    cb(WL,list)
end)

RegisterServerEvent('esx_jb_radars:getStautRadar')
AddEventHandler('esx_jb_radars:getStautRadar',function()
  local source = source
  for i=1,#Config.Radars do
    TriggerClientEvent('esx_jb_radars:changeEtatCli',source,i,Config.Radars[i].disable)
  end
end)

function timer(number)
  Citizen.Wait(1800000)
  Config.Radars[number].disable = false
  TriggerClientEvent('esx_jb_radars:changeEtatCli',-1,number,false)
  sendToDiscorda('Equipe de maintenance','Le radar numero '..number..' est en service','maintenance terminée'  ,Config.green)
end


RegisterServerEvent('esx_jb_radars:disable')
AddEventHandler('esx_jb_radars:disable', function (number)
  local source = source
  if number ~= nil then
    Config.Radars[number].disable = true
    TriggerClientEvent('esx_jb_radars:changeEtatCli',-1,number,true)
    sendToDiscorda('Erreur radar','Le radar numero '..number..' est hors service','Le service de maintenance est en route'  ,Config.red)
    timer(number)
  end
end)

ESX.RegisterUsableItem('bombe_p', function(source)
  TriggerClientEvent('esx_jb_radars:bombeRadar',source)
end)
