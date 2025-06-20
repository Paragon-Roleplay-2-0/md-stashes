local invcall = ''

CreateThread(function()
    if GetResourceState('qb-inventory') == 'started' then
		invcall = 'qb-inventory'
	elseif GetResourceState('ps-inventory') == 'started' then
		invcall = 'ps-inventory'
	elseif GetResourceState('lj-inventory') == 'started' then
		invcall = 'inventory'
	end
end)

local QBCore = exports['qb-core']:GetCoreObject()

local function openInventory(name, weight, slot, password)
	if Config.Inv == 'ox' then
		exports.ox_inventory:openInventory('stash', {id = name})
	elseif Config.Inv == 'oldqb' then
		Wait(100)
		TriggerEvent(invcall..":client:SetCurrentStash", name)
		TriggerServerEvent(invcall..":server:OpenInventory", "stash", name, {
			maxweight = weight,
			slots = slot,
		})
	elseif Config.Inv == 'outdated' then
		local other = {maxweight = weight, slots = slot}
		TriggerServerEvent("inventory:server:OpenInventory", "stash", "Stash_"..name, other)
		TriggerEvent("inventory:client:SetCurrentStash", "Stash_"..name)
	elseif Config.Inv == 'qb' then
		TriggerServerEvent('md-stashes:server:OpenStash', name, weight, slot)
	end
end

function OpenStash(name, weight, slot, password)
    if password then
        local input = lib.inputDialog('Password', {{type = 'input', label = 'Password', description = 'What Is The Password', required = true}, })
        if password == input[1] then openInventory(name, weight, slot, password) end
    else
        openInventory(name, weight, slot, password)
    end
end

function StartRay()
    local run = true
	local input = lib.inputDialog('Object Or Location', {
        {type = 'select', label = 'Type Of Stash', options = {{value = true, label = 'Object'}, {value = false, label = 'Location'}}},
       })
	if input[1] then
		local objects = {}
		for k, v in pairs (Config.Objects) do
			table.insert(objects,{
				value = v.value,
				label = v.label
			})
		end
		local objectchoice = lib.inputDialog('Object Or Location', {
			{type = 'select', label = 'What Object', options = objects,searchable = true, }
		   })

		local heading = 180.0
		local created = false
		local obj = objectchoice[1]
		local coord = GetEntityCoords(PlayerPedId())
		lib.requestModel(obj, 30000)
		local entity = CreateObject(obj, coord.x, coord.y, coord.z, false, false)
		repeat
        	local hit, entityHit, endCoords, surfaceNormal, matHash = lib.raycast.cam(511, 4, 10)
        	if not created then
				created = true
				lib.showTextUI('[E] To Place  \n  [DEL] To Cancel  \n  [<-] To Move Left  \n  [->] To Move Right')
			else
				SetEntityCoords(entity, endCoords.x, endCoords.y, endCoords.z)
				SetEntityHeading(entity, heading)
				SetEntityCollision(entity, false, false)
				SetEntityAlpha(entity, 100)
			end
        	if IsControlPressed(0, 174) then
        	    heading = heading - 2
        	end
			if IsControlPressed(0, 175) then
        	    heading = heading + 2
        	end
        	if IsControlPressed(0, 38) then
        	    lib.hideTextUI()
        	    run = false
        	    DeleteEntity(entity)
        	    return endCoords, heading, obj
        	end
        	if IsControlPressed(0, 178) then
        	    lib.hideTextUI()
        	    run = false
        	    DeleteEntity(entity)
        	    return nil
        	end
		until run == false
	else
    	repeat
    	    local Wait = 1
    	    local hit, entityHit, endCoords, surfaceNormal, matHash = lib.raycast.cam(511, 4, 10)
    	    lib.showTextUI('Raycast Coords:  \n X:  ' ..
    	    math.floor(endCoords.x * 100) / 100 .. ',  \n Y:  ' .. math.floor(endCoords.y * 100) / 100 .. ',  \n Z:  ' .. math.floor(endCoords.z * 100) / 100 .. '  \n[E] to copy  \n[DEL] to cancel')
    	    DrawMarker(28, endCoords.x, endCoords.y, endCoords.z, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.1, 0.1, 0.1, 255, 255,
    	    255, 255, false, true, 2, nil, nil, false, false)
    	    if IsControlPressed(0, 38) then
    	        lib.hideTextUI()
    	        run = false
    	        return endCoords, nil, false
    	    end
    	    if IsControlPressed(0, 178) then
    	        lib.hideTextUI()
    	        run = false
    	        return nil
    	    end
    	    Citizen.Wait(Wait)
    	until run == false
	end
end

function AddBoxZone(name, coords, options)
    if Config.Target == 'ox' then
       name = exports.ox_target:addBoxZone({
		name = name,
		coords = vector3(coords.x, coords.y, coords.z-1),
		size = vec3(1,1,1),
		options = {
            {
				label = options.label,
				icon = options.icon,
				distance = 2.0,
				event = options.event or nil,
				onSelect = options.action or nil,
				canInteract = options.canInteract,
			}
       }
	})
    elseif Config.Target == 'qb' then
        exports['qb-target']:AddBoxZone(name, coords, 1.0, 1.0, { name = name, heading = 156.0, minZ = coords.z-1, maxZ = coords.z+1 }, { options = {
                {
					label = options.label,
					icon = options.icon,
					event = options.event or nil,
					action = options.action or nil,
					canInteract = options.canInteract,
				}
            },
			distance = 2.0 })
    elseif Config.Target == 'interaction' then
        exports.interact:AddInteraction({ coords = vector3(coords.x, coords.y,coords.z), distance = 8.0, interactDst = 2.0, id = name, name = name }, { options = {
            {
				label = options.label,
				event = options.event or nil,
				action = options.action or nil,
				canInteract = options.canInteract,
			}
       }
	})
    end
end

function AddEntityTarg(entity, options)
    if Config.Target == 'ox' then
        exports.ox_target:addLocalEntity(entity, {
			label = options.label,
			icon = options.icon,
			event = options.event or nil,
			onSelect = options.action or nil,
			canInteract = options.canInteract
		})
    elseif Config.Target == 'qb' then
        exports['qb-target']:AddTargetEntity(entity, { options = {
			{
				label = options.label,
				icon = options.icon,
				event = options.event or nil,
				action = options.action or nil,
				canInteract = options.canInteract,
			}
		},
		distance = 2.5})
    elseif Config.Target == 'interaction' then
        exports.interact:AddLocalEntityInteraction({
			entity = entity,
			name = entity,
			id = entity,
			distance = 8.0,
			interactDst = 2.0,
			options = {
				{
					icon = options.icon,
					label = options.label,
					event = options.event or nil,
					action = options.action or nil,
					canInteract = options.canInteract,
				}
        }
	})
    end
end

function RemoveZones(spawned)
	local prints = lib.callback.await('md-stashes:server:GetStashes')
	for k, v in pairs (prints) do
		local js = json.decode(v.data)
		if js['object'] == false then
			if Config.Target == 'ox' then
				exports.ox_target:removeZone('mdstashes'..v.name)
			elseif Config.Target == 'qb' then
				exports['qb-target']:RemoveZone('mdstashes'..v.name)
			elseif Config.Target == 'interaction' then
				exports.interact:RemoveInteraction('mdstashes'..v.name)
			end
		else
			DeleteEntity(spawned[k])
		end
	end
end

function check(data)
	local p = QBCore.Functions.GetPlayerData()
	if p.job.name == data['job'] and p.job.grade.level >= data['rank'] or data['job'] == false then
		if p.gang.name == data['gang'] and p.gang.grade.level or data['gang'] == false then
			if data['citizenid'] == false or data['citizenid'] == p.citizenid then
				if data['item'] == false or QBCore.Functions.HasItem(data['item']) then
					return true
				end
			end
		end
	end
end