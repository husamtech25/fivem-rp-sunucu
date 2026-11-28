-- server/koruma.lua
-- Kiralık koruma: oyuncu ajanstaki NPC'ye para verir, süre boyunca peşinden gelen koruma(lar) tutar.
-- Korumaları oyuncunun kendi oyunu oluşturur (GTA'nın "grup üyesi" sistemiyle takip eder ve korur);
-- sunucu ödemeyi alır, kaç koruma olduğunu ve süresini takip eder, süre dolunca siler.

local Korumalar = {}   -- [oyuncu] = { bitis = os.time(), hak = izin verilen sayı, netIds = {} }

function KorumaSayisi()
    local sayi = 0
    for _, k in pairs(Korumalar) do sayi = sayi + #k.netIds end
    return sayi
end

local function korumalariSil(oyuncu, sebep)
    local k = Korumalar[oyuncu]
    if not k then return end
    for _, netId in ipairs(k.netIds) do
        local ent = NetworkGetEntityFromNetworkId(netId)
        if ent ~= 0 and DoesEntityExist(ent) then DeleteEntity(ent) end
    end
    Korumalar[oyuncu] = nil
    if sebep then TriggerClientEvent('endnpc:korumaBitti', oyuncu, sebep) end
end

-- Para: önce nakitten, yetmezse bankadan
local function odemeAl(oyuncu, tutar)
    if tutar <= 0 then return true end
    if exports.qbx_core:RemoveMoney(oyuncu, 'cash', tutar, 'endnpc-koruma') then return true end
    return exports.qbx_core:RemoveMoney(oyuncu, 'bank', tutar, 'endnpc-koruma')
end

lib.callback.register('endnpc:korumaKirala', function(oyuncu, adet)
    local ayar = Veri.ayarlar.koruma
    if not ayar.aktif or not ayar.ajans then return { ok = false, mesaj = 'Ajans şu an kapalı.' } end

    local a = ayar.ajans
    if #(GetEntityCoords(GetPlayerPed(oyuncu)) - vector3(a.x, a.y, a.z)) > 6.0 then
        return { ok = false, mesaj = 'Ajansa çok uzaksın.' }
    end

    local mevcut = Korumalar[oyuncu] and #Korumalar[oyuncu].netIds or 0
    local bos = ayar.enFazla - mevcut
    adet = math.floor(tonumber(adet) or 1)
    if bos <= 0 then return { ok = false, mesaj = ('En fazla %d koruma tutabilirsin.'):format(ayar.enFazla) } end
    adet = math.max(1, math.min(adet, bos))

    local tutar = ayar.fiyat * adet
    if not odemeAl(oyuncu, tutar) then
        return { ok = false, mesaj = ('Yeterli paran yok ($%d gerekiyor).'):format(tutar) }
    end

    -- Yeni kiralama süreyi baştan başlatır (eski korumalar da uzar)
    local k = Korumalar[oyuncu] or { netIds = {} }
    k.bitis = os.time() + ayar.sure * 60
    k.hak = mevcut + adet
    Korumalar[oyuncu] = k

    return {
        ok = true,
        adet = adet,
        tutar = tutar,
        sure = ayar.sure,
        model = ayar.model,
        silah = ayar.silah,
        can = ayar.can,
        zirh = ayar.zirh,
    }
end)

-- Oyuncunun oyunu korumaları oluşturunca kimlik numaralarını bildirir
RegisterNetEvent('endnpc:korumaKaydet', function(netIds)
    local oyuncu = source
    local k = Korumalar[oyuncu]
    if not k or type(netIds) ~= 'table' then return end
    for _, netId in ipairs(netIds) do
        netId = tonumber(netId)
        local ent = netId and NetworkGetEntityFromNetworkId(netId)
        -- sadece ödediği kadar, kendi oluşturduğu NPC'leri kabul et
        if ent and ent ~= 0 and DoesEntityExist(ent) and GetEntityType(ent) == 1 and #k.netIds < k.hak then
            k.netIds[#k.netIds + 1] = netId
            Entity(ent).state:set('endnpcKoruma', oyuncu, true)
        end
    end
end)

RegisterNetEvent('endnpc:korumaGonder', function()
    korumalariSil(source, 'gonderildi')
end)

AddEventHandler('playerDropped', function()
    korumalariSil(source)
end)

-- Süresi dolanları ve ölen korumaları temizle
CreateThread(function()
    while true do
        Wait(5000)
        local simdi = os.time()
        for oyuncu, k in pairs(Korumalar) do
            if simdi >= k.bitis then
                korumalariSil(oyuncu, 'sure')
            else
                for i = #k.netIds, 1, -1 do
                    local ent = NetworkGetEntityFromNetworkId(k.netIds[i])
                    local yok = ent == 0 or not DoesEntityExist(ent)
                    if yok or GetEntityHealth(ent) <= 0 then   -- kayboldu veya öldü
                        if not yok then DeleteEntity(ent) end
                        table.remove(k.netIds, i)
                        k.hak = k.hak - 1
                    end
                end
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(kaynak)
    if kaynak ~= GetCurrentResourceName() then return end
    for oyuncu in pairs(Korumalar) do korumalariSil(oyuncu) end
end)
