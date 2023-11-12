local FirstSpawn, IsBusy = true, false

isDead = false
RDX = nil

Citizen.CreateThread(function()
	while RDX == nil do
		TriggerEvent('rdx:getSharedObject', function(obj) RDX = obj end)
		Citizen.Wait(0)
	end

	while RDX.GetPlayerData().job == nil do
		Citizen.Wait(100)
	end

	RDX.PlayerData = RDX.GetPlayerData()
end)

RegisterNetEvent('rdx:playerLoaded')
AddEventHandler('rdx:playerLoaded', function(xPlayer)
	RDX.PlayerData = xPlayer
end)

RegisterNetEvent('rdx:onPlayerLogout')
AddEventHandler('rdx:onPlayerLogout', function()
	RDX.PlayerLoaded = false
	RDX.PlayerData = {}
	FirstSpawn = true
end)

RegisterNetEvent('rdx:setJob')
AddEventHandler('rdx:setJob', function(job)
	RDX.PlayerData.job = job
end)

function SetAttributeCoreValue(ped, coreIndex, value)
    Citizen.InvokeNative(0xC6258F41D86676E0, ped, coreIndex, value)
end

function setStamina(value)
    if value > 100 then
        value = 100
    end
    SetAttributeCoreValue(PlayerPedId(), 1, value)
end

function restoreStamina()
    RestorePlayerStamina(PlayerId(), 1.0) --outer
    setStamina(100) -- inner core
end

function setPlayerHealth(value)
    -- Overpower should be disable to make entity health work (edit: ??? not sure now if needed)
    Citizen.InvokeNative(0xF6A7C08DF2E28B28, PlayerPedId(), 0, 0.0, true) -- EnableAttributeOverpower
    -- Core should be set to 100 
    SetAttributeCoreValue(PlayerPedId(), 0, 100)
    SetEntityHealth(PlayerPedId(), value)
end

function setPlayerMaxHealth(value)
    value = value - 550
    SetEntityMaxHealth(PlayerPedId(), value)
end

function getPlayerMaxHealth()
    return GetEntityMaxHealth(PlayerPedId())
end

function getPlayerHealth()
    return GetEntityHealth(PlayerPedId())
end

function restoreHealth()
    setPlayerHealth(getPlayerMaxHealth())
end

AddEventHandler('playerSpawned', function()
	isDead = false

	if FirstSpawn then
		TriggerServerEvent('rdx_ambulancejob:firstSpawn')
		exports.spawnmanager:setAutoSpawn(false) -- disable respawn
		SetPlayerInvincible(ped, false)
		ClearPedBloodDamage(ped)
		ClearPedSecondaryTask(playerPed)
		SetEnableHandcuffs(playerPed, false)
		DisablePlayerFiring(playerPed, false)
		SetPedCanPlayGestureAnims(playerPed, true)
		FreezeEntityPosition(playerPed, false)
		DisplayRadar(true)
		restoreHealth()
                restoreStamina()
		FirstSpawn = false
	end
end)

function OnPlayerDeath()
    isDead = true
    TriggerServerEvent('rdx_ambulancejob:setDeathStatus',true)
    if Config.ShowDeathTimer == true then
       ShowDeathTimer()
    end	
    ClearPedTasksImmediately(PlayerPedId())
end

function ShowDeathTimer()
	local respawnTimer = Config.EarlyRespawnTimer
	print(respawnTimer)
	Citizen.CreateThread(function()
		while respawnTimer > 0 and isDead do
			Citizen.Wait(0)

			raw_seconds = respawnTimer/1000
			raw_minutes = raw_seconds/60
			minutes = stringsplit(raw_minutes, ".")[1]
			seconds = stringsplit(raw_seconds-(minutes*60), ".")[1]

			DrawTxt("Você está inconsciente, mas sobreviva! Esperar "..minutes.." minutos "..seconds.." segundos ", 0.50, 0.90, 0.7, 0.7, true, 255, 255, 255, 255, true)
			respawnTimer = respawnTimer - 15
		end
		Citizen.Wait(0)
			StartRespawnToHospitalMenuTimer()
	end)
end

function DrawTxt(text,x,y)
    SetTextScale(0.45,0.45) --Text Size
    SetTextColor(255, 0, 0, 255)--r,g,b,a
    SetTextCentre(true)
    SetTextDropshadow(1,0,0,0,200)
    SetTextFontForCurrentCommand(7)
    DisplayText(CreateVarString(10, "LITERAL_STRING", text), x, y)
end

function StartRespawnToHospitalMenuTimer()
    local respawnTimer = Config.EarlyRespawnTimer
		if respawnTimer > 0 and isDead then
			RDX.UI.Menu.Open('default', GetCurrentResourceName(), 'respawn_hospital',
			{
				title = _U('respawn_at_hospital'),
				align = 'bottom-right',
				elements = {
					{label = _U('no'),  value = 'no'},
					{label = _U('yes'), value = 'yes'}
				}
			}, function(data, menu)
				if data.current.value == 'yes' then
					RemoveItemsAfterRPDeath()
				end
				menu.close()
			end)
		end
end

function RemoveItemsAfterRPDeath()
	TriggerServerEvent('rdx_ambulancejob:setDeathStatus',false)

	Citizen.CreateThread(function()
		DoScreenFadeOut(800)

		while not IsScreenFadedOut() do
			Citizen.Wait(10)
		end

		RDX.TriggerServerCallback('rdx_ambulancejob:removeItemsAfterRPDeath', function()
			local formattedCoords = {
				x = Config.RespawnPoint.coords.x,
				y = Config.RespawnPoint.coords.y,
				z = Config.RespawnPoint.coords.z
			}
			RDX.SetPlayerData('loadout', {})
			RespawnPed(PlayerPedId(), formattedCoords, Config.RespawnPoint.heading)
			DoScreenFadeIn(800)
		end)
	end)
end

RegisterCommand("kill", function(source, args, rawCommand) -- KILL YOURSELF COMMAND
    local _source = source
    local pl = Citizen.InvokeNative(0x217E9DC48139933D)
    local ped = Citizen.InvokeNative(0x275F255ED201B937, pl)
    Citizen.InvokeNative(0x697157CED63F18D4, ped, 500000, false, true, true)
    TriggerServerEvent('rdx_ambulancejob:setDeathStatus',true)
end)

function RespawnPed(ped, coords)
	SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, false, false, false, true)
	NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, coords.heading, true, false)
	SetPlayerInvincible(ped, false)
	TriggerEvent('playerSpawned', coords.x, coords.y, coords.z, coords.heading)
	ClearPedBloodDamage(ped)
	ClearPedSecondaryTask(playerPed)
	SetEnableHandcuffs(playerPed, false)
	DisablePlayerFiring(playerPed, false)
	SetPedCanPlayGestureAnims(playerPed, true)
	FreezeEntityPosition(playerPed, false)
	DisplayRadar(true)
	restoreHealth()
        restoreStamina()
	RDX.UI.Menu.CloseAll()
end

function TeleportFadeEffect(entity, coords)
	Citizen.CreateThread(function()
		DoScreenFadeOut(800)

		while not IsScreenFadedOut() do
			Citizen.Wait(0)
		end

		RDX.Game.Teleport(entity, coords, function()
			DoScreenFadeIn(800)
		end)
	end)
end

AddEventHandler('rdx:onPlayerDeath', function(reason)
	OnPlayerDeath()
end)

RegisterNetEvent('rdx_ambulancejob:revive')
AddEventHandler('rdx_ambulancejob:revive', function()
	local playerPed = PlayerPedId()
	local coords	= GetEntityCoords(playerPed)
	TriggerServerEvent('rdx_ambulancejob:setDeathStatus', false)

	Citizen.CreateThread(function()
		DoScreenFadeOut(800)

		while not IsScreenFadedOut() do
			Citizen.Wait(0)
		end

		RDX.SetPlayerData('lastPosition', {
			x = coords.x,
			y = coords.y,
			z = coords.z
		})

		TriggerServerEvent('rdx:updateLastPosition', {
			x = coords.x,
			y = coords.y,
			z = coords.z
		})

		RespawnPed(playerPed, {
			x = coords.x,
			y = coords.y,
			z = coords.z
		})

		DoScreenFadeIn(800)
	end)
end)


RegisterNetEvent('rdx_ambulancejob:requestDeath')
AddEventHandler('rdx_ambulancejob:requestDeath', function()
	if Config.AntiCombatLog then
		Citizen.Wait(5000)
		SetEntityHealth(PlayerPedId(), 0)
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

function OpenArmoryMenu(station)

	if Config.EnableArmoryManagement then

		local elements = {
			{label = _U('get_weapon'),     value = 'get_weapon'},
			{label = _U('put_weapon'),     value = 'put_weapon'},
			{label = _U('remove_object'),  value = 'get_stock'},
			{label = _U('deposit_object'), value = 'put_stock'}
		}

		if PlayerData.job.grade_name == 'boss' then
			table.insert(elements, {label = _U('buy_weapons'), value = 'buy_weapons'})
		end

		RDX.UI.Menu.CloseAll()

		RDX.UI.Menu.Open('default', GetCurrentResourceName(), 'armory',
		{
			title    = _U('armory'),
			align    = 'bottom-right',
			elements = elements
		}, function(data, menu)

			if data.current.value == 'get_weapon' then
				OpenGetWeaponMenu()
			elseif data.current.value == 'put_weapon' then
				OpenPutWeaponMenu()
			elseif data.current.value == 'buy_weapons' then
				OpenBuyWeaponsMenu(station)
			elseif data.current.value == 'put_stock' then
				OpenPutStocksMenu()
			elseif data.current.value == 'get_stock' then
				OpenGetStocksMenu()
			end

		end, function(data, menu)
			menu.close()

			CurrentAction     = 'menu_armory'
			CurrentActionMsg  = _U('open_armory')
			CurrentActionData = {station = station}
		end)

	else

		local elements = {}

		for i=1, #Config.PoliceStations[station].AuthorizedWeapons, 1 do
			local weapon = Config.PoliceStations[station].AuthorizedWeapons[i]

			table.insert(elements, {
				label = RDX.GetWeaponLabel(weapon.name),
				value = weapon.name
			})
		end

		RDX.UI.Menu.CloseAll()

		RDX.UI.Menu.Open('default', GetCurrentResourceName(), 'armory',
		{
			title    = _U('armory'),
			align    = 'bottom-right',
			elements = elements
		}, function(data, menu)
			local weapon = data.current.value
			TriggerServerEvent('rdx_policejob:giveWeapon', weapon, 1000)
		end, function(data, menu)
			menu.close()

			CurrentAction     = 'menu_armory'
			CurrentActionMsg  = _U('open_armory')
			CurrentActionData = {station = station}
		end)

	end

end
