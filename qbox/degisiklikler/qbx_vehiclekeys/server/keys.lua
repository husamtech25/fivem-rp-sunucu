local config = require 'config.server'
local debug = GetConvarInt(('%s-debug'):format(GetCurrentResourceName()), 0) == 1

---@alias CitizenId string
---@alias SessionId integer
---@type table<CitizenId, table<SessionId, boolean>>
local loggedOutKeys = {} ---holds key status for some time after player logs out (Prevents frustration by crashing the client)

---@alias LogoutTime integer
---@type table<CitizenId, LogoutTime>
local logedOutTime = {} ---Life timestamp of the keys of a character who has logged out

---Gets Citizen Id based on source
---@param source number ID of the player
---@return string? citizenid The player CitizenID, nil otherwise.
local function getCitizenId(source)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return end

    return player.PlayerData.citizenid
end

RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    local src = source
    local citizenId = getCitizenId(src)
    if not citizenId then return end
    if loggedOutKeys[citizenId] then
        Player(src).state:set('keysList', loggedOutKeys[citizenId], true)
        loggedOutKeys[citizenId] = nil
        logedOutTime[citizenId] = nil
    end
end)

local function onPlayerUnload(src)
    local citizenId = getCitizenId(src)
    if not citizenId then return end
    loggedOutKeys[citizenId] = Player(src).state.keysList
    logedOutTime[citizenId] = os.time()
end

RegisterNetEvent('QBCore:Server:OnPlayerUnload', onPlayerUnload)

AddEventHandler('playerDropped', function()
    onPlayerUnload(source)
end)

---Removes old keys from server memory
lib.cron.new('*/'..config.runClearCronMinutes ..' * * * *', function ()
    local time = os.time()
    local seconds = config.runClearCronMinutes * 60
    for citizenId, lifetime in pairs(logedOutTime) do
        if lifetime + seconds < time then
            loggedOutKeys[citizenId] = nil
            logedOutTime[citizenId] = nil
        end
    end
end, {debug = debug})

-- ================= [Huso] Fiziksel araç anahtarı =================
-- Envanterde 'arac_anahtari' eşyası, metadata.plate = aracın plakası.
-- Anahtar kimdeyse araç ona açılır (HasKeys). Anahtar verilince (GiveKeys) envantere fiziksel anahtar da düşer.

local ANAHTAR = 'arac_anahtari'

local function plakaOku(vehicle)
    local plaka = GetVehicleNumberPlateText(vehicle)
    return plaka and plaka:gsub('^%s+', ''):gsub('%s+$', '') or nil
end

---Oyuncunun envanterinde bu plakaya ait anahtar var mı?
local function fizikselAnahtarVar(source, plaka)
    if not plaka or GetResourceState('ox_inventory') ~= 'started' then return false end
    return (exports.ox_inventory:Search(source, 'count', ANAHTAR, { plate = plaka }) or 0) > 0
end

---Oyuncuya bu aracın anahtarını ver (zaten varsa ikinci kez vermez)
local function fizikselAnahtarVer(source, vehicle)
    if GetResourceState('ox_inventory') ~= 'started' then return end
    local plaka = plakaOku(vehicle)
    if not plaka or plaka == '' or fizikselAnahtarVar(source, plaka) then return end

    local model
    local vehicleId = Entity(vehicle).state.vehicleid
    if vehicleId and GetResourceState('qbx_vehicles') == 'started' then
        local kayit = exports.qbx_vehicles:GetPlayerVehicle(vehicleId)
        model = kayit and kayit.modelName
    end

    local metadata = {
        plate = plaka,
        label = ('Anahtar · %s'):format(plaka),
        description = model and ('Plaka: %s · Model: %s'):format(plaka, model) or ('Plaka: %s'):format(plaka),
    }
    if exports.ox_inventory:CanCarryItem(source, ANAHTAR, 1, metadata) then
        exports.ox_inventory:AddItem(source, ANAHTAR, 1, metadata)
    else
        exports.qbx_core:Notify(source, 'Envanterin dolu, araç anahtarını alamadın.', 'error')
    end
end

--- Removing the vehicle keys from the user
---@param source number ID of the player
---@param vehicle number
---@param skipNotification? boolean
function RemoveKeys(source, vehicle, skipNotification)
    local citizenid = getCitizenId(source)
    if not citizenid then return end

    local keys = Player(source).state.keysList
    if not keys then return end

    local sessionId = Entity(vehicle).state.sessionId
    if not keys[sessionId] then return end
    keys[sessionId] = nil

    Player(source).state:set('keysList', keys, true)

    TriggerClientEvent('qbx_vehiclekeys:client:OnLostKeys', source)
    if not skipNotification then
        exports.qbx_core:Notify(source, locale('notify.keys_removed'))
    end

    return true
end

exports('RemoveKeys', RemoveKeys)

---@param source number
---@param vehicle number
---@param skipNotification? boolean
---@param fizikselAnahtarYok? boolean [Huso] true: envantere fiziksel anahtar verme (araç sahibinin otomatik erişimi)
function GiveKeys(source, vehicle, skipNotification, fizikselAnahtarYok)
    local citizenid = getCitizenId(source)
    if not citizenid then return end

    -- [Huso] Anahtar verilen oyuncunun envanterine fiziksel anahtar (zaten varsa vermez)
    if not fizikselAnahtarYok then fizikselAnahtarVer(source, vehicle) end

    local sessionId = Entity(vehicle).state.sessionId or exports.qbx_core:CreateSessionId(vehicle)
    local keys = Player(source).state.keysList or {}
    if keys[sessionId] then return end

    keys[sessionId] = true

    Player(source).state:set('keysList', keys, true)
    if not skipNotification then
        exports.qbx_core:Notify(source, locale('notify.keys_taken'))
    end
    return true
end

exports('GiveKeys', GiveKeys)

---@param src number
---@param vehicle number
---@return boolean
function HasKeys(src, vehicle)
    local keysList = Player(src).state.keysList
    if keysList then
        local sessionId = Entity(vehicle).state.sessionId
        if keysList[sessionId] then
            return true
        end
    end

    -- [Huso] Envanterinde bu aracın fiziksel anahtarı varsa
    if fizikselAnahtarVar(src, plakaOku(vehicle)) then
        return true
    end

    local owner = Entity(vehicle).state.owner
    if owner and getCitizenId(src) == owner then
        GiveKeys(src, vehicle, nil, true)   -- [Huso] sahibin otomatik erişimi: yeni fiziksel anahtar üretme
        return true
    end

    return false
end

exports('HasKeys', HasKeys)

-- [Huso] Fiziksel anahtar oyuncunun elinden çıkınca (yere atma, başkasına verme, depoya koyma)
-- o araca erişimi de gider. (Araç sahibi kendi aracını yine kullanabilir.)
CreateThread(function()
    while GetResourceState('ox_inventory') ~= 'started' do Wait(1000) end
    exports.ox_inventory:registerHook('swapItems', function(payload)
        if payload.fromType ~= 'player' or payload.toInventory == payload.fromInventory then return true end
        local kaynak = tonumber(payload.fromInventory)
        local plaka = payload.fromSlot and payload.fromSlot.metadata and payload.fromSlot.metadata.plate
        if not kaynak or not plaka then return true end
        SetTimeout(300, function()   -- taşıma bittikten sonra bak
            if fizikselAnahtarVar(kaynak, plaka) then return end   -- elinde başka kopyası var
            local liste = Player(kaynak).state.keysList
            if not liste then return end
            for _, arac in ipairs(GetAllVehicles()) do
                if plakaOku(arac) == plaka then RemoveKeys(kaynak, arac, true) end
            end
        end)
        return true
    end, { itemFilter = { [ANAHTAR] = true } })
end)

-- Oyuncu anahtar eşyasını kullanınca: istemci yakındaki aracı arar (bkz. client/main.lua anahtarKullan)

---Checks whether the player's ped is close enough to a vehicle to legitimately request keys for it.
---Server-side key-grant events are triggered by the client, so without this check a player could
---grant themselves keys to any vehicle on the server by spoofing its network id.
---@param source number ID of the player
---@param vehicle number
---@return boolean
function IsPlayerNearVehicle(source, vehicle)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return false end
    local ped = GetPlayerPed(source)
    if ped == 0 then return false end
    return #(GetEntityCoords(ped) - GetEntityCoords(vehicle)) <= config.distanceToVehicle
end

exports('IsPlayerNearVehicle', IsPlayerNearVehicle)

lib.callback.register('qbx_vehiclekeys:server:giveKeys', function(source, netId)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if not IsPlayerNearVehicle(source, vehicle) then return end
    -- [Huso] Bu geri çağrıyı istemci sadece "araç benim" durumunda çağırır (client/functions.lua HasKeys):
    -- sahibin otomatik erişimi, her seferinde yeni fiziksel anahtar üretmesin
    local owner = Entity(vehicle).state.owner
    local sahibi = owner and getCitizenId(source) == owner
    GiveKeys(source, vehicle, nil, sahibi)
end)

AddStateBagChangeHandler('vehicleid', '', function(bagName, _, vehicleId)
    local vehicle = GetEntityFromStateBagName(bagName)
    if not vehicle or vehicle == 0 then return end
    local owner = exports.qbx_vehicles:GetPlayerVehicle(vehicleId)?.citizenid
    if not owner then return end
    Entity(vehicle).state:set('owner', owner, true)
end)
