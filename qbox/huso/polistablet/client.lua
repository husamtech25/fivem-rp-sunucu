-- client.lua
-- 1) Envanterde "Polis Tableti" kullanılınca tablet elde açılır (animasyon + tablet objesi) ve ekran gelir.
-- 2) Gelen her polis ihbarını (police:client:policeAlert) sokak adıyla sunucuya iletir; tablette listelenir.

local acik = false
local tabletObjesi

local ANIM_SOZLUK = 'amb@code_human_in_bus_passenger_idles@female@tablet@base'
local ANIM = 'base'
local OBJE = `prop_cs_tablet`

local function polisMiyim()
    local veri = exports.qbx_core:GetPlayerData()
    return veri and veri.job and veri.job.type == 'leo'
end

-- ================= Elde tablet =================

local function tabletiEleAl()
    local ped = PlayerPedId()
    lib.requestAnimDict(ANIM_SOZLUK)
    lib.requestModel(OBJE)
    tabletObjesi = CreateObject(OBJE, 0.0, 0.0, 0.0, true, true, false)
    -- 60309 = sol el kemiği
    AttachEntityToEntity(tabletObjesi, ped, GetPedBoneIndex(ped, 60309), 0.03, 0.002, -0.0, 10.0, 160.0, 0.0, true, false, false, false, 2, true)
    SetModelAsNoLongerNeeded(OBJE)
    TaskPlayAnim(ped, ANIM_SOZLUK, ANIM, 3.0, 3.0, -1, 49, 0, false, false, false)   -- 49: yürürken de oynasın
    RemoveAnimDict(ANIM_SOZLUK)
end

local function tabletiBirak()
    local ped = PlayerPedId()
    StopAnimTask(ped, ANIM_SOZLUK, ANIM, 1.0)
    if tabletObjesi and DoesEntityExist(tabletObjesi) then DeleteEntity(tabletObjesi) end
    tabletObjesi = nil
end

-- ================= Açma / kapama =================

local function tabletiAc()
    if acik then return end
    if not polisMiyim() then
        lib.notify({ description = 'Bu tableti sadece polisler kullanabilir.', type = 'error' })
        return
    end
    if IsPedInAnyVehicle(PlayerPedId(), false) == false then tabletiEleAl() end
    acik = true
    SetNuiFocus(true, true)
    SendNUIMessage({ islem = 'ac', konumlar = Ayar.Konumlar })
end

local function tabletiKapat()
    if not acik then return end
    acik = false
    SetNuiFocus(false, false)
    SendNUIMessage({ islem = 'kapat' })
    tabletiBirak()
end

-- ox_inventory eşyayı kullanınca bunu çağırır (data/items.lua: client.export = 'polistablet.tabletKullan')
exports('tabletKullan', function()
    tabletiAc()
end)

-- ================= Sayfadan gelenler =================

RegisterNUICallback('kapat', function(_, cb)
    tabletiKapat()
    cb(true)
end)

RegisterNUICallback('getir', function(_, cb)
    cb(lib.callback.await('polistablet:getir', false) or false)
end)

RegisterNUICallback('islem', function(veri, cb)
    cb(lib.callback.await('polistablet:islem', false, veri.tip, tonumber(veri.id)) or { ok = false, mesaj = 'Sunucu yanıt vermedi.' })
end)

RegisterNUICallback('gps', function(veri, cb)
    local x, y = tonumber(veri.x), tonumber(veri.y)
    if x and y then
        SetNewWaypoint(x, y)
        lib.notify({ description = ('GPS ayarlandı: %s'):format(veri.ad or 'konum'), type = 'inform' })
    end
    cb(true)
end)

-- ================= İhbarları yakala =================

local function sokakAdi(k)
    local s1, s2 = GetStreetNameAtCoord(k.x, k.y, k.z)
    local ad1, ad2 = GetStreetNameFromHashKey(s1), GetStreetNameFromHashKey(s2)
    local bolge = GetLabelText(GetNameOfZone(k.x, k.y, k.z))
    local sokak = ad1
    if ad2 and ad2 ~= '' then sokak = sokak .. ' / ' .. ad2 end
    if bolge and bolge ~= 'NULL' then sokak = sokak .. ', ' .. bolge end
    return sokak
end

-- Bütün polis ihbarları görevdeki polislere bu olayla gelir (qbx_police ve endnpc)
RegisterNetEvent('police:client:policeAlert', function(konum, yazi)
    if not konum or not yazi then return end
    local k = { x = konum.x + 0.0, y = konum.y + 0.0, z = konum.z + 0.0 }
    TriggerServerEvent('polistablet:ihbarGeldi', k, tostring(yazi), sokakAdi(k))
end)

AddEventHandler('onResourceStop', function(kaynak)
    if kaynak == GetCurrentResourceName() and acik then
        SetNuiFocus(false, false)
        tabletiBirak()
    end
end)
