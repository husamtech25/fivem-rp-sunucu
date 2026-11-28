-- client/panel.lua
-- Yönetim panelini (html klasöründeki sayfa) açar ve sayfa ile sunucu arasında köprü kurar.
-- Ayrıca admin isterse NPC'leri haritada (blip) ve başlarının üstünde isimleriyle gösterir.

local acik = false
local Gorsel = { blip = false, etiket = false, bolge = false }   -- sadece bu oyuncunun ekranı için

local function paneliAc()
    if acik then return end
    acik = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        islem = 'ac',
        gorsel = Gorsel,
        ayar = {
            modeller = Ayar.Modeller,
            silahlar = Ayar.Silahlar,
            renkler = Ayar.Renkler,
            secenekler = Ayar.Secenekler,
            etiketler = Ayar.Etiketler,
            sinirlar = Ayar.Sinirlar,
            varsayilanNpc = Ayar.VarsayilanNpc,
            varsayilanGrup = Ayar.VarsayilanGrup,
            varsayilanBolge = Ayar.VarsayilanBolge,
            araclar = Ayar.Araclar,
            rotaEnFazla = Ayar.RotaEnFazla,
        },
    })
end

local function paneliKapat()
    acik = false
    SetNuiFocus(false, false)
    SendNUIMessage({ islem = 'kapat' })
end

-- Sunucu /npcpanel komutunda yetkiyi kontrol edip bunu gönderir
RegisterNetEvent('endnpc:paneliAc', paneliAc)

-- Kısayol tuşu: sunucu komutunu çalıştıran ara komut (bkz. kisayollar scripti)
RegisterCommand('endnpc_panel', function() ExecuteCommand(Ayar.Komut) end, false)
RegisterKeyMapping('endnpc_panel', 'NPC yönetim paneli', 'keyboard', Ayar.Tus)

-- ================= Sayfadan gelen istekler =================

RegisterNUICallback('kapat', function(_, cb)
    paneliKapat()
    cb(true)
end)

-- Sunucuya giden her işlem (kaydet, sil, getir...) buradan geçer
RegisterNUICallback('islem', function(veri, cb)
    local sonuc = lib.callback.await('endnpc:islem', false, veri.tip, veri.veri)
    cb(sonuc or { ok = false, mesaj = 'Sunucu yanıt vermedi.' })
end)

RegisterNUICallback('modelDogrula', function(veri, cb)
    local hash = GetHashKey(tostring(veri.model or ''))
    cb(IsModelInCdimage(hash) and IsModelAPed(hash))
end)

-- Araç modeli oyunda var mı, araba mı motor mu? (sunucu aracı oluştururken türünü bilmek zorunda)
RegisterNUICallback('aracDogrula', function(veri, cb)
    local hash = GetHashKey(tostring(veri.model or ''))
    if not IsModelInCdimage(hash) or not IsModelAVehicle(hash) then
        return cb({ hata = 'Bu adda bir araç oyunda yok.' })
    end
    if IsThisModelABike(hash) then return cb({ tur = 'bike' }) end
    if IsThisModelACar(hash) and not IsThisModelAQuadbike(hash) then return cb({ tur = 'automobile' }) end
    cb({ hata = 'Sadece araba ve motor kullanılabilir (uçak, tekne, ATV olmaz).' })
end)

RegisterNUICallback('benimKonumum', function(_, cb)
    local ped = PlayerPedId()
    local k = GetEntityCoords(ped)
    cb({ x = k.x, y = k.y, z = k.z - 1.0, h = GetEntityHeading(ped) })
end)

-- Haritadaki işaretin (waypoint) konumu. Yükseklik bilinmediği için zemini arar.
RegisterNUICallback('waypoint', function(_, cb)
    local blip = GetFirstBlipInfoId(8)
    if not DoesBlipExist(blip) then return cb({ hata = 'Haritada işaret (waypoint) yok.' }) end
    local k = GetBlipInfoIdCoord(blip)
    for yukseklik = 1000.0, 0.0, -25.0 do
        RequestCollisionAtCoord(k.x, k.y, yukseklik)
        Wait(0)
        local bulundu, zemin = GetGroundZFor_3dCoord(k.x, k.y, yukseklik, false)
        if bulundu then return cb({ x = k.x, y = k.y, z = zemin, h = 0.0 }) end
    end
    cb({ hata = 'O bölge yüklenmedi. Oraya gidip "Bulunduğum yer" veya "Nişan al" ile yerleştir.' })
end)

-- Nişan alarak yerleştirme: panel gizlenir, yerleştirme bitince geri gelir
RegisterNUICallback('konumSec', function(veri, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({ islem = 'gizle' })
    local sonuc = KonumSec(tostring(veri.model or ''))
    if acik then
        SetNuiFocus(true, true)
        SendNUIMessage({ islem = 'goster' })
    end
    cb(sonuc or { hata = 'Yerleştirme iptal edildi.' })
end)

RegisterNUICallback('isinlan', function(veri, cb)
    local x, y, z = tonumber(veri.x), tonumber(veri.y), tonumber(veri.z)
    if x and y and z then
        paneliKapat()
        SetEntityCoords(PlayerPedId(), x + 1.5, y, z, false, false, false, false)
    end
    cb(true)
end)

RegisterNUICallback('gorsel', function(veri, cb)
    Gorsel.blip = veri.blip == true
    Gorsel.etiket = veri.etiket == true
    Gorsel.bolge = veri.bolge == true
    cb(true)
end)

-- ================= Harita işaretleri (blip) =================

local renkBlip = {}
for _, r in ipairs(Ayar.Renkler) do renkBlip[r.hex] = r.blip end

local blipler = {}   -- [npcId] = { blip, ped }

local function blipleriTemizle()
    for id, b in pairs(blipler) do
        RemoveBlip(b.blip)
        blipler[id] = nil
    end
end

CreateThread(function()
    while true do
        Wait(1000)
        if Gorsel.blip then
            local var = {}
            for _, npc in ipairs(YereldekiNpcler()) do
                if not npc.n.olu then
                    var[npc.id] = true
                    local b = blipler[npc.id]
                    if b and b.ped ~= npc.ped then RemoveBlip(b.blip); b = nil end
                    if not b then
                        local blip = AddBlipForEntity(npc.ped)
                        SetBlipSprite(blip, 1)
                        SetBlipScale(blip, 0.75)
                        SetBlipAsShortRange(blip, false)
                        BeginTextCommandSetBlipName('STRING')
                        AddTextComponentSubstringPlayerName(npc.n.ad .. ' (' .. npc.g.ad .. ')')
                        EndTextCommandSetBlipName(blip)
                        b = { blip = blip, ped = npc.ped }
                        blipler[npc.id] = b
                    end
                    SetBlipColour(b.blip, renkBlip[npc.g.renk] or 17)
                end
            end
            for id, b in pairs(blipler) do
                if not var[id] then RemoveBlip(b.blip); blipler[id] = nil end
            end
        elseif next(blipler) then
            blipleriTemizle()
        end
    end
end)

-- ================= Bölgeler (haritada daire + yerde çember) =================

local bolgeBlipleri = {}
local bolgeSurum = -1

local function bolgeBlipleriniTemizle()
    for _, b in ipairs(bolgeBlipleri) do RemoveBlip(b) end
    bolgeBlipleri = {}
end

CreateThread(function()
    while true do
        if Gorsel.bolge and next(Senk.bolgeler) then
            -- Bölgeler değiştiyse harita işaretlerini yeniden çiz
            if bolgeSurum ~= Senk.surum or #bolgeBlipleri == 0 then
                bolgeBlipleriniTemizle()
                for _, b in pairs(Senk.bolgeler) do
                    local g = Senk.gruplar[b.grup]
                    local daire = AddBlipForRadius(b.x, b.y, b.z, b.yaricap + 0.0)
                    SetBlipColour(daire, g and renkBlip[g.renk] or 17)
                    SetBlipAlpha(daire, 90)
                    local isaret = AddBlipForCoord(b.x, b.y, b.z)
                    SetBlipSprite(isaret, 310)
                    SetBlipScale(isaret, 0.8)
                    SetBlipColour(isaret, g and renkBlip[g.renk] or 17)
                    BeginTextCommandSetBlipName('STRING')
                    AddTextComponentSubstringPlayerName('Bölge: ' .. b.ad)
                    EndTextCommandSetBlipName(isaret)
                    bolgeBlipleri[#bolgeBlipleri + 1] = daire
                    bolgeBlipleri[#bolgeBlipleri + 1] = isaret
                end
                bolgeSurum = Senk.surum
            end
            -- Yakındaki bölgelerin sınırını yerde çiz
            local benim = GetEntityCoords(PlayerPedId())
            local yakinda = false
            for _, b in pairs(Senk.bolgeler) do
                if #(benim - vector3(b.x, b.y, b.z)) < b.yaricap + 80.0 then
                    yakinda = true
                    DrawMarker(1, b.x, b.y, b.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                        b.yaricap * 2.0, b.yaricap * 2.0, 3.0, 255, 122, 26, 35, false, false, 2, false, nil, nil, false)
                end
            end
            Wait(yakinda and 0 or 500)
        else
            if #bolgeBlipleri > 0 then bolgeBlipleriniTemizle() end
            Wait(1000)
        end
    end
end)

-- ================= İsim etiketleri =================

local function dunyayaYaz(k, yazi)
    local gorunuyor, x, y = World3dToScreen2d(k.x, k.y, k.z)
    if not gorunuyor then return end
    SetTextScale(0.0, 0.32)
    SetTextFont(4)
    SetTextOutline()
    SetTextCentre(true)
    SetTextColour(255, 255, 255, 235)
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(yazi)
    EndTextCommandDisplayText(x, y)
end

CreateThread(function()
    local liste, sonGuncelleme = {}, 0
    while true do
        if Gorsel.etiket and next(Senk.npcler) then
            local simdi = GetGameTimer()
            if simdi - sonGuncelleme > 500 then   -- listeyi yarım saniyede bir yenile, her karede değil
                liste, sonGuncelleme = YereldekiNpcler(), simdi
            end
            local benim = GetEntityCoords(PlayerPedId())
            for _, npc in ipairs(liste) do
                if DoesEntityExist(npc.ped) and not npc.n.olu then
                    local k = GetEntityCoords(npc.ped)
                    if #(benim - k) < 40.0 then
                        local can = math.max(0, math.floor((GetEntityHealth(npc.ped) - 100) / math.max(1, npc.n.can) * 100))
                        dunyayaYaz(k + vector3(0.0, 0.0, 1.15),
                            ('%s ~c~[%s]~s~ %d%%'):format(npc.n.ad, npc.g.ad, can))
                    end
                    -- Rotası varsa yerde noktaları birleştiren çizgi
                    local rota = npc.n.davranis == 'rota' and npc.n.rota
                    if rota and #rota > 1 and #(benim - k) < 150.0 then
                        for i = 1, #rota do
                            local a = rota[i]
                            local b = rota[i + 1] or (npc.n.rotaTur ~= 'gidipGel' and rota[1])
                            if b then DrawLine(a.x, a.y, a.z + 0.2, b.x, b.y, b.z + 0.2, 60, 207, 122, 220) end
                            DrawMarker(28, a.x, a.y, a.z + 0.2, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.25, 0.25, 0.25, 60, 207, 122, 200, false, false, 2, false, nil, nil, false)
                        end
                    end
                end
            end
            Wait(0)
        else
            Wait(1000)
        end
    end
end)

AddEventHandler('onResourceStop', function(kaynak)
    if kaynak ~= GetCurrentResourceName() then return end
    blipleriTemizle()
    bolgeBlipleriniTemizle()
    if acik then SetNuiFocus(false, false) end
end)
