RDX = nil

TriggerEvent('rdx:getSharedObject', function(obj) RDX = obj end)


RegisterServerEvent('rdx_ambulancejob:revive')
AddEventHandler('rdx_ambulancejob:revive', function(target)
	local _source = source
	local xPlayer = RDX.GetPlayerFromId(_source)

	xPlayer.addMoney(Config.ReviveReward)
	TriggerClientEvent('rdx_ambulancejob:revive', target)
end)

RegisterServerEvent('rdx_ambulancejob:heal')
AddEventHandler('rdx_ambulancejob:heal', function(target, type)
	TriggerClientEvent('rdx_ambulancejob:heal', target, type)
end)

RegisterServerEvent('rdx_ambulancejob:putInVehicle')
AddEventHandler('rdx_ambulancejob:putInVehicle', function(target)

	TriggerClientEvent('rdx_ambulancejob:putInVehicle', target)
end)

RDX.RegisterServerCallback('rdx_ambulancejob:removeItemsAfterRPDeath', function(source, cb)
	local xPlayer = RDX.GetPlayerFromId(source)

	if Config.RemoveCashAfterRPDeath then
		if xPlayer.getMoney() > 0 then
			xPlayer.removeMoney(xPlayer.getMoney())
		end

		if xPlayer.getAccount('black_money').money > 0 then
			xPlayer.setAccountMoney('black_money', 0)
		end
	end

	if Config.RemoveItemsAfterRPDeath then
		for i=1, #xPlayer.inventory, 1 do
			if xPlayer.inventory[i].count > 0 then
				xPlayer.setInventoryItem(xPlayer.inventory[i].name, 0)
			end
		end
	end

	local playerLoadout = {}
	if Config.RemoveWeaponsAfterRPDeath then
		for i=1, #xPlayer.loadout, 1 do
			xPlayer.removeWeapon(xPlayer.loadout[i].name)
		end
	else -- save weapons & restore em' since spawnmanager removes them
		for i=1, #xPlayer.loadout, 1 do
			table.insert(playerLoadout, xPlayer.loadout[i])
		end

		-- give back wepaons after a couple of seconds
		Citizen.CreateThread(function()
			Citizen.Wait(5000)
			for i=1, #playerLoadout, 1 do
				if playerLoadout[i].label ~= nil then
					xPlayer.addWeapon(playerLoadout[i].name, playerLoadout[i].ammo)
				end
			end
		end)
	end

	cb()
end)

if Config.EarlyRespawn and Config.EarlyRespawnFine then
	RDX.RegisterServerCallback('rdx_ambulancejob:checkBalance', function(source, cb)
		local xPlayer = RDX.GetPlayerFromId(source)
		local bankBalance = xPlayer.getAccount('bank').money

		cb(bankBalance >= Config.EarlyRespawnFineAmount)
	end)

	RDX.RegisterServerCallback('rdx_ambulancejob:payFine', function(source, cb)
		local xPlayer = RDX.GetPlayerFromId(source)
		TriggerClientEvent('rdx:showNotification', xPlayer.source, _U('respawn_fine', Config.EarlyRespawnFineAmount))
		xPlayer.removeAccountMoney('bank', Config.EarlyRespawnFineAmount)

		cb()
	end)
end

RDX.RegisterServerCallback('rdx_ambulancejob:getItemAmount', function(source, cb, item)
	local xPlayer = RDX.GetPlayerFromId(source)
	local quantity = xPlayer.getInventoryItem(item).count

	cb(quantity)
end)

RegisterServerEvent('rdx_ambulancejob:removeItem')
AddEventHandler('rdx_ambulancejob:removeItem', function(item)
	local _source = source
	local xPlayer = RDX.GetPlayerFromId(_source)

	xPlayer.removeInventoryItem(item, 1)

	if item == 'bandage' then
		TriggerClientEvent('rdx:showNotification', _source, _U('used_bandage'))
	elseif item == 'medikit' then
		TriggerClientEvent('rdx:showNotification', _source, _U('used_medikit'))
	end
end)

RegisterServerEvent('rdx_ambulancejob:giveItem')
AddEventHandler('rdx_ambulancejob:giveItem', function(itemName)
	local _source = source
    local xPlayer = RDX.GetPlayerFromId(_source)
		  xPlayer.addInventoryItem("medikit", 1)
end)

RDX.RegisterCommand('revive', 'admin', function(source, args)
	if args[1] ~= nil then
		if GetPlayerName(tonumber(args[1])) ~= nil then
			TriggerClientEvent('rdx_ambulancejob:revive', tonumber(args[1]))
		end
	else
		TriggerClientEvent('rdx_ambulancejob:revive', source)
	end
end, function(source, args)
	TriggerClientEvent('chat:addMessage', source, { args = { '^1SYSTEM', 'Insufficient Permissions.' } })
end)

RDX.RegisterUsableItem('medikit', function(source)
	local _source = source
	local xPlayer = RDX.GetPlayerFromId(_source)
	xPlayer.removeInventoryItem('medikit', 1)
	TriggerClientEvent('rdx_ambulancejob:heal', _source, 'big')
	TriggerClientEvent('rdx:showNotification', _source, _U('used_medikit'))
end)

RDX.RegisterUsableItem('bandage', function(source)
	local _source = source
	local xPlayer = RDX.GetPlayerFromId(_source)
	xPlayer.removeInventoryItem('bandage', 1)
	TriggerClientEvent('rdx_ambulancejob:heal', _source, 'small')
	TriggerClientEvent('rdx:showNotification', _source, _U('used_bandage'))
end)

RegisterServerEvent('rdx_ambulancejob:firstSpawn')
AddEventHandler('rdx_ambulancejob:firstSpawn', function()
	local _source    = source
	local identifier = GetPlayerIdentifiers(_source)[1]
	MySQL.Async.fetchScalar('SELECT isDead FROM users WHERE identifier=@identifier',
	{
		['@identifier'] = identifier
	}, function(isDead)
		if isDead == 1 then
			print('rdx_ambulancejob: ' .. GetPlayerName(_source) .. ' (' .. identifier .. ') attempted combat logging!')
			TriggerClientEvent('rdx_ambulancejob:requestDeath', _source)
		end
	end)
end)

RegisterServerEvent('rdx_ambulancejob:setDeathStatus')
AddEventHandler('rdx_ambulancejob:setDeathStatus', function(isDead)
	local _source = source
	MySQL.Sync.execute("UPDATE users SET isDead=@isDead WHERE identifier=@identifier",
	{
		['@identifier'] = GetPlayerIdentifiers(_source)[1],
		['@isDead'] = isDead
	})
end)