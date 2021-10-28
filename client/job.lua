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

RegisterNetEvent('rdx:setJob')
AddEventHandler('rdx:setJob', function(job)
	RDX.PlayerData.job = job
end)

local HasAlreadyEnteredMarker, LastZone, CurrentAction, CurrentActionMsg, CurrentActionData = nil, nil, nil, '', {}

function OpenAmbulanceActionsMenu()
	local elements = {
		{label = _U('cloakroom'), value = 'Hallinta'}
	}

	if Config.EnablePlayerManagement and RDX.PlayerData.job.grade_name == 'boss' then
		table.insert(elements, {label = _U('boss_actions'), value = 'boss_actions'})
	end

	RDX.UI.Menu.CloseAll()

	RDX.UI.Menu.Open('default', GetCurrentResourceName(), 'ambulance_actions',
	{
		title		= _U('ambulance'),
		align		= 'bottom-right',
		elements	= elements
	}, function(data, menu)
		if data.current.value == 'cloakroom' then
			OpenCloakroomMenu()
		elseif data.current.value == 'boss_actions' then
			TriggerEvent('rdx_society:openBossMenu', 'ambulance', function(data, menu)
				menu.close()
			end, {wash = false})
		end
	end, function(data, menu)
		menu.close()

		CurrentAction		= 'ambulance_actions_menu'
		CurrentActionMsg	= _U('open_menu')
		CurrentActionData	= {}
	end)
end

function OpenMobileAmbulanceActionsMenu()

	RDX.UI.Menu.CloseAll()

	RDX.UI.Menu.Open('default', GetCurrentResourceName(), 'mobile_ambulance_actions',
	{
		title		= _U('ambulance'),
		align		= 'bottom-right',
		elements	= {
			{label = _U('ems_menu'), value = 'citizen_interaction'}
		}
	}, function(data, menu)
		if data.current.value == 'citizen_interaction' then
			RDX.UI.Menu.Open('default', GetCurrentResourceName(), 'citizen_interaction',
			{
				title		= _U('ems_menu_title'),
				align		= 'bottom-right',
				elements	= {
					{label = _U('ems_menu_revive'), value = 'revive'},
					{label = _U('ems_menu_small'), value = 'small'},
					{label = _U('ems_menu_big'), value = 'big'},
					{label = _U('ems_menu_putincar'), value = 'put_in_vehicle'}
				}
			}, 	
    function(data, menu)
      if IsBusy then return end

      if data.current.value == 'billing' then
        RDX.UI.Menu.Open(
          'dialog', GetCurrentResourceName(), 'billing',
          {
            title = _U('invoice_amount')
          },
          function(data, menu)
            local amount = tonumber(data.value)
            if amount == nil or amount < 0 then
              RDX.ShowNotification(_U('amount_invalid'))
            else
              local closestPlayer, closestDistance = RDX.Game.GetClosestPlayer()
              print(closestPlayer)
              if closestPlayer == -1 or closestDistance > 3.0 then
              	print(closestDistance)
              	print("noCosePlayers")
                RDX.ShowNotification(_U('no_players_nearby'))
			  else
				menu.close()
				print("SendBill")
                TriggerServerEvent('rdx_billing:sendBill', GetPlayerServerId(closestPlayer), 'society_ambulance', ('Ensiapu'), amount)
                print("SendbillToClosestplayer")
                print(closestPlayer)
              end
            end
          end,
        function(data, menu)
          menu.close()
        end
        )
      end
                         -- function(data, menu)
				if IsBusy then return end

				local closestPlayer, closestDistance = RDX.Game.GetClosestPlayer()

				if closestPlayer == -1 or closestDistance > 3.0 then
					RDX.ShowNotification(_U('no_players'))
				else

					if data.current.value == 'revive' then

						RDX.TriggerServerCallback('rdx_ambulancejob:getItemAmount', function(quantity)
							if quantity > 0 then
								local closestPlayerPed = GetPlayerPed(closestPlayer)

								if IsPedDeadOrDying(closestPlayerPed, 1) then
									local playerPed = PlayerPedId()

									IsBusy = true
									RDX.ShowNotification(_U('revive_inprogress'))
									TaskStartScenarioInPlace(playerPed, 'CODE_HUMAN_MEDIC_TEND_TO_DEAD', 0, true)
									Citizen.Wait(10000)
									ClearPedTasks(playerPed)

									TriggerServerEvent('rdx_ambulancejob:removeItem', 'medikit')
									TriggerServerEvent('rdx_ambulancejob:revive', GetPlayerServerId(closestPlayer))
									IsBusy = false

									-- Show revive award?
									if Config.ReviveReward > 0 then
										RDX.ShowNotification(_U('revive_complete_award', GetPlayerName(closestPlayer), Config.ReviveReward))
									else
										RDX.ShowNotification(_U('revive_complete', GetPlayerName(closestPlayer)))
									end
								else
									RDX.ShowNotification(_U('player_not_unconscious'))
								end
							else
								RDX.ShowNotification(_U('not_enough_medikit'))
							end
						end, 'medikit')

					elseif data.current.value == 'small' then

						RDX.TriggerServerCallback('rdx_ambulancejob:getItemAmount', function(quantity)
							if quantity > 0 then
								local closestPlayerPed = GetPlayerPed(closestPlayer)
								local health = GetEntityHealth(closestPlayerPed)

								if health > 0 then
									local playerPed = PlayerPedId()

									IsBusy = true
									RDX.ShowNotification(_U('heal_inprogress'))
									TaskStartScenarioInPlace(playerPed, 'CODE_HUMAN_MEDIC_TEND_TO_DEAD', 0, true)
									Citizen.Wait(10000)
									ClearPedTasks(playerPed)

									TriggerServerEvent('rdx_ambulancejob:removeItem', 'bandage')
									TriggerServerEvent('rdx_ambulancejob:heal', GetPlayerServerId(closestPlayer), 'small')
									RDX.ShowNotification(_U('heal_complete', GetPlayerName(closestPlayer)))
									IsBusy = false
								else
									RDX.ShowNotification(_U('player_not_conscious'))
								end
							else
								RDX.ShowNotification(_U('not_enough_bandage'))
							end
						end, 'bandage')

					elseif data.current.value == 'big' then

						RDX.TriggerServerCallback('rdx_ambulancejob:getItemAmount', function(quantity)
							if quantity > 0 then
								local closestPlayerPed = GetPlayerPed(closestPlayer)
								local health = GetEntityHealth(closestPlayerPed)

								if health > 0 then
									local playerPed = PlayerPedId()

									IsBusy = true
									RDX.ShowNotification(_U('heal_inprogress'))
									TaskStartScenarioInPlace(playerPed, 'CODE_HUMAN_MEDIC_TEND_TO_DEAD', 0, true)
									Citizen.Wait(10000)
									ClearPedTasks(playerPed)

									TriggerServerEvent('rdx_ambulancejob:removeItem', 'medikit')
									TriggerServerEvent('rdx_ambulancejob:heal', GetPlayerServerId(closestPlayer), 'big')
									RDX.ShowNotification(_U('heal_complete', GetPlayerName(closestPlayer)))
									IsBusy = false
								else
									RDX.ShowNotification(_U('player_not_conscious'))
								end
							else
								RDX.ShowNotification(_U('not_enough_medikit'))
							end
						end, 'medikit')

					elseif data.current.value == 'put_in_vehicle' then
						TriggerServerEvent('rdx_ambulancejob:putInVehicle', GetPlayerServerId(closestPlayer))
					end
				end
			end, function(data, menu)
				menu.close()
			end)
		end

	end, function(data, menu)
		menu.close()
	end)
end


AddEventHandler('rdx_ambulancejob:hasEnteredMarker', function(zone)
	if zone == 'AmbulanceActions' then
		CurrentAction		= 'ambulance_actions_menu'
		CurrentActionMsg	= _U('open_menu')
		CurrentActionData	= {}
	elseif zone == 'Pharmacy' then
		CurrentAction		= 'pharmacy'
		CurrentActionMsg	= _U('open_pharmacy')
		CurrentActionData	= {}
	elseif zone == 'VehicleDeleter' then
		local playerPed = PlayerPedId()
		local coords	= GetEntityCoords(playerPed)
	end
end)

AddEventHandler('rdx_ambulancejob:hasExitedMarker', function(zone)
	RDX.UI.Menu.CloseAll()
	CurrentAction = nil
end)

Citizen.CreateThread(function()
        local blip = N_0x554d9d53f696d002(1664425300, -284.47, 807.46, 119.44)
        SetBlipSprite(blip, -1739686743, 1)
        SetBlipScale(blip, Config.BlipScale)
        Citizen.InvokeNative(0x9CB1A1623062F402, blip, "Hospital")
end)

-- Display markers
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)

		local coords = GetEntityCoords(PlayerPedId())
		for k,v in pairs(Config.Zones) do
			if(v.Type ~= -1 and GetDistanceBetweenCoords(coords, v.Pos.x, v.Pos.y, v.Pos.z, true) < 3) then
				if RDX.PlayerData.job ~= nil and RDX.PlayerData.job.name == 'ambulance' then
					Citizen.InvokeNative(0x2A32FAA57B937173, -1795314153, v.Pos.x, v.Pos.y, v.Pos.z-1, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 1.5, 1.5, 0.75, 100, 50, 75, 75, false, true, 2, false, false, false, false)
				elseif k ~= 'AmbulanceActions' and k ~= 'Pharmacy' then
					Citizen.InvokeNative(0x2A32FAA57B937173, -1795314153, v.Pos.x, v.Pos.y, v.Pos.z-1, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 1.5, 1.5, 0.75, 100, 50, 75, 75, false, true, 2, false, false, false, false)
				end
			end
		end
	end
end)

-- Activate menu when player is inside marker
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(10)

		local coords		= GetEntityCoords(PlayerPedId())
		local isInMarker	= false
		local currentZone	= nil

		for k,v in pairs(Config.Zones) do
			if RDX.PlayerData.job ~= nil and RDX.PlayerData.job.name == 'ambulance' then
				if(GetDistanceBetweenCoords(coords, v.Pos.x, v.Pos.y, v.Pos.z, true) < 3) then
					isInMarker	= true
					currentZone = k
				end
			elseif k ~= 'AmbulanceActions' and k ~= 'Pharmacy' then
				if(GetDistanceBetweenCoords(coords, v.Pos.x, v.Pos.y, v.Pos.z, true) < 3) then
					isInMarker	= true
					currentZone = k
				end
			end
		end

		if isInMarker and not hasAlreadyEnteredMarker then
			hasAlreadyEnteredMarker = true
			lastZone				= currentZone
			TriggerEvent('rdx_ambulancejob:hasEnteredMarker', currentZone)
		end

		if not isInMarker and hasAlreadyEnteredMarker then
			hasAlreadyEnteredMarker = false
			TriggerEvent('rdx_ambulancejob:hasExitedMarker', lastZone)
		end
	end
end)



-- Key Controls
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(10)

		if CurrentAction ~= nil then
			-- RDX.ShowHelpNotification(CsurrentActionMsg)

			if IsControlJustReleased(0, 0xCEFD9220) and RDX.PlayerData.job ~= nil and RDX.PlayerData.job.name == 'ambulance' then --E

				if CurrentAction == 'ambulance_actions_menu' then
					OpenAmbulanceActionsMenu()
				elseif CurrentAction == 'pharmacy' then
					OpenPharmacyMenu()
				end

				CurrentAction = nil

			end

		end

		if IsControlJustReleased(0, 0x446258B6) and RDX.PlayerData.job ~= nil and RDX.PlayerData.job.name == 'ambulance' and not IsDead then -- Home
			OpenMobileAmbulanceActionsMenu()
		end
	end
end)

RegisterNetEvent('rdx_ambulancejob:putInVehicle')
AddEventHandler('rdx_ambulancejob:putInVehicle', function()
	local playerPed = PlayerPedId()
	local coords    = GetEntityCoords(playerPed)

	if IsAnyVehicleNearPoint(coords.x, coords.y, coords.z, 5.0) then
		local vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 5.0, 0, 71)

		if DoesEntityExist(vehicle) then
			local maxSeats = GetVehicleMaxNumberOfPassengers(vehicle)
			local freeSeat = nil

			for i=maxSeats - 1, 0, -1 do
				if IsVehicleSeatFree(vehicle, i) then
					freeSeat = i
					break
				end
			end

			if freeSeat ~= nil then
				TaskWarpPedIntoVehicle(playerPed, vehicle, freeSeat)
			end
		end
	end
end)


function OpenCloakroomMenu()
	RDX.UI.Menu.Open('default', GetCurrentResourceName(), 'cloakroom',
	{
		title		= _U('cloakroom'),
		align		= 'bottom-right',
		elements = {
			{label = _U('ems_clothes_civil'), value = 'citizen_wear'},
			{label = _U('ems_clothes_ems'), value = 'ambulance_wear'},
		}
	}, function(data, menu)
		if data.current.value == 'citizen_wear' then
			RDX.TriggerServerCallback('rdx_skin:getPlayerSkin', function(skin, jobSkin)
				TriggerEvent('skinchanger:loadSkin', skin)
			end)
		elseif data.current.value == 'ambulance_wear' then
			RDX.TriggerServerCallback('rdx_skin:getPlayerSkin', function(skin, jobSkin)
				if skin.sex == 0 then
					TriggerEvent('skinchanger:loadClothes', skin, jobSkin.skin_male)
				else
					TriggerEvent('skinchanger:loadClothes', skin, jobSkin.skin_female)
				end
			end)
		end

		menu.close()
		CurrentAction		= 'ambulance_actions_menu'
		CurrentActionMsg	= _U('open_menu')
		CurrentActionData	= {}
	end, function(data, menu)
		menu.close()
	end)
end

function OpenVehicleSpawnerMenu()

	RDX.UI.Menu.CloseAll()

	if Config.EnableSocietyOwnedVehicles then

		local elements = {}

		RDX.TriggerServerCallback('rdx_society:getVehiclesInGarage', function(vehicles)
			for i=1, #vehicles, 1 do
				table.insert(elements, {label = GetDisplayNameFromVehicleModel(vehicles[i].model) .. ' [' .. vehicles[i].plate .. ']', value = vehicles[i]})
			end

			RDX.UI.Menu.Open('default', GetCurrentResourceName(), 'vehicle_spawner',
			{
				title		= _U('veh_menu'),
				align		= 'bottom-right',
				elements = elements
			}, function(data, menu)
				menu.close()

				local vehicleProps = data.current.value
				RDX.Game.SpawnVehicle(vehicleProps.model, Config.Zones.VehicleSpawnPoint.Pos, 270.0, function(vehicle)
					RDX.Game.SetVehicleProperties(vehicle, vehicleProps)
					SetVehicleNumberPlateText(vehicle, "EMS-" .. math.random(100,999))
					local playerPed = PlayerPedId()
					--TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
				end)
				TriggerServerEvent('rdx_society:removeVehicleFromGarage', 'ambulance', vehicleProps)
			end, function(data, menu)
				menu.close()
				CurrentAction		= 'vehicle_spawner_menu'
				CurrentActionMsg	= _U('veh_spawn')
				CurrentActionData	= {}
			end)
		end, 'ambulance')

	else -- not society vehicles

		RDX.UI.Menu.Open('default', GetCurrentResourceName(), 'vehicle_spawner',
		{
			title		= _U('veh_menu'),
			align		= 'bottom-right',
			elements	= Config.AuthorizedVehicles
		}, function(data, menu)
			menu.close()

			local model = data.current.name

			RDX.Game.SpawnVehicle(model, Config.Zones.VehicleSpawnPoint.Pos, 230.0, function(vehicle)
				SetVehicleNumberPlateText(vehicle, "EMS-" .. math.random(100,999))
				local playerPed = PlayerPedId()
				--TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
			end)
		end, function(data, menu)
			menu.close()
			CurrentAction		= 'vehicle_spawner_menu'
			CurrentActionMsg	= _U('veh_spawn')
			CurrentActionData	= {}
		end)

	end
end


function OpenPharmacyMenu()
	RDX.UI.Menu.CloseAll()

	RDX.UI.Menu.Open('default', GetCurrentResourceName(), 'pharmacy',
	{
		title		= _U('pharmacy_menu_title'),
		align		= 'bottom-right',
		elements = {
			{label = _U('pharmacy_take') .. ' ' .. _('medikit'), value = 'medikit'},
			{label = _U('pharmacy_take') .. ' ' .. _('bandage'), value = 'bandage'}
		}
	}, function(data, menu)
		TriggerServerEvent('rdx_ambulancejob:giveItem', data.current.value)
	end, function(data, menu)
		menu.close()
		CurrentAction		= 'pharmacy'
		CurrentActionMsg	= _U('open_pharmacy')
		CurrentActionData	= {}
	end)
end

function WarpPedInClosestVehicle(ped)
	local coords = GetEntityCoords(ped)

	local vehicle, distance = RDX.Game.GetClosestVehicle({
		x = coords.x,
		y = coords.y,
		z = coords.z
	})

	if distance ~= -1 and distance <= 5.0 then
		local maxSeats = GetVehicleMaxNumberOfPassengers(vehicle)
		local freeSeat = nil

		for i=maxSeats - 1, 0, -1 do
			if IsVehicleSeatFree(vehicle, i) then
				freeSeat = i
				break
			end
		end

		if freeSeat ~= nil then
			TaskWarpPedIntoVehicle(ped, vehicle, freeSeat)
		end
	else
		RDX.ShowNotification(_U('no_vehicles'))
	end
end

RegisterNetEvent('rdx_ambulancejob:heal')
AddEventHandler('rdx_ambulancejob:heal', function(healType)
	local playerPed = PlayerPedId()
	local maxHealth = GetEntityMaxHealth(playerPed)

	if healType == 'small' then
		local health = GetEntityHealth(playerPed)
		local newHealth = math.min(maxHealth , math.floor(health + maxHealth/8))
		SetEntityHealth(playerPed, newHealth)
	elseif healType == 'big' then
		SetEntityHealth(playerPed, maxHealth)
	end

	RDX.ShowNotification(_U('healed'))
end)
