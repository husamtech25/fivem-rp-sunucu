-- server.lua: SUNUCUDA çalışan kod.
-- Client (oyuncunun bilgisayarı) sadece yakınındaki araçları görür.
-- Sunucu ise haritadaki bütün araçları görür. O yüzden eski aracı silme işini burada yapıyoruz.

-- Her oyuncunun son çıkardığı aracı tutan tablo.
-- Örnek: sonAraclar[3] = 1234  ->  3 numaralı oyuncunun son aracının ağ kimliği 1234
local sonAraclar = {}

-- Bir oyuncunun eski aracını silen yardımcı fonksiyon
local function eskiAraciSil(oyuncuId)
    local netId = sonAraclar[oyuncuId]
    if netId then
        -- Ağ kimliğinden (netId) sunucudaki aracı bul
        local arac = NetworkGetEntityFromNetworkId(netId)
        if arac ~= 0 and DoesEntityExist(arac) then
            DeleteEntity(arac)
        end
        sonAraclar[oyuncuId] = nil
    end
end

-- Client yeni araç çıkardığında bu olayı (event) tetikler ve aracın ağ kimliğini gönderir.
RegisterNetEvent('araba:yeniArac', function(netId)
    local oyuncuId = source   -- olayı gönderen oyuncunun numarası (FiveM otomatik verir)
    eskiAraciSil(oyuncuId)
    sonAraclar[oyuncuId] = netId
end)

-- Client "/sil" yazınca bu olayı tetikler: oyuncunun son aracını sil
RegisterNetEvent('araba:sil', function()
    local oyuncuId = source
    if sonAraclar[oyuncuId] then
        eskiAraciSil(oyuncuId)
        TriggerClientEvent('chat:addMessage', oyuncuId, { args = { '^2[Araba]', 'Aracın silindi.' } })
    else
        TriggerClientEvent('chat:addMessage', oyuncuId, { args = { '^2[Araba]', 'Silinecek aracın yok.' } })
    end
end)

-- Oyuncu sunucudan çıkınca onun aracını da temizle
AddEventHandler('playerDropped', function()
    eskiAraciSil(source)
end)
