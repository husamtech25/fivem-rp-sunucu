-- server.lua: Oyuncuların konumlarını bir dosyaya kaydeder.
-- Konumlar bu scriptin klasöründeki "konumlar.json" dosyasında durur.
-- Sunucu kapanıp açılsa bile kaybolmaz.

local DOSYA = 'konumlar.json'
local SCRIPT = GetCurrentResourceName()

-- Dosyayı oku. Dosya yoksa boş bir tabloyla başla.
-- json.decode: yazıyı ('{"a":1}') Lua tablosuna çevirir.
local konumlar = json.decode(LoadResourceFile(SCRIPT, DOSYA) or '{}') or {}

-- Yerine yerleşmiş oyuncular. Yeni giren oyuncu eski konumuna ışınlanmadan
-- konumunu kaydedersek, doğduğu yer eski konumunun üstüne yazılır. Bunu engelliyoruz.
local hazir = {}

-- Oyuncunun kalıcı kimliği. Oyuncu numarası (1, 2, 3...) her girişte değişir,
-- ama "license" kimliği hep aynı kalır. Konumu buna göre saklıyoruz.
local function kimlik(oyuncuId)
    return GetPlayerIdentifierByType(oyuncuId, 'license')
        or GetPlayerIdentifierByType(oyuncuId, 'fivem')
end

local function konumuAl(oyuncuId)
    if not hazir[oyuncuId] then return end

    local karakter = GetPlayerPed(oyuncuId)
    if karakter == 0 then return end

    local id = kimlik(oyuncuId)
    if not id then return end

    local k = GetEntityCoords(karakter)
    konumlar[id] = { x = k.x, y = k.y, z = k.z, yon = GetEntityHeading(karakter) }
end

local function dosyayaYaz()
    -- json.encode: Lua tablosunu yazıya çevirir. -1 = yazının tamamını kaydet.
    SaveResourceFile(SCRIPT, DOSYA, json.encode(konumlar), -1)
end

-- Oyuncu girip doğunca client bu olayla kayıtlı konumunu ister
RegisterNetEvent('konum:iste', function()
    local oyuncuId = source
    local id = kimlik(oyuncuId)
    -- Kayıtlı konum varsa gönder, yoksa nil gider (ilk kez giriyordur)
    TriggerClientEvent('konum:gonder', oyuncuId, id and konumlar[id] or nil)
end)

-- Client ışınlanmayı bitirince haber verir, artık konumunu kaydedebiliriz
RegisterNetEvent('konum:yerlesti', function()
    hazir[source] = true
end)

-- Script, oyuncular zaten oyundayken başlatıldıysa (örneğin "restart konumkaydet")
-- onlar için doğma olayı gelmez. O anda sunucuda olan herkesi "hazır" say.
AddEventHandler('onResourceStart', function(script)
    if script ~= SCRIPT then return end
    for _, oyuncuId in ipairs(GetPlayers()) do
        hazir[tonumber(oyuncuId)] = true
    end
end)

-- Oyuncu çıkarken son konumunu kaydet
AddEventHandler('playerDropped', function()
    local oyuncuId = source
    konumuAl(oyuncuId)
    hazir[oyuncuId] = nil
    dosyayaYaz()
end)

-- Oyun çökerse ya da sunucu kapanırsa diye 30 saniyede bir herkesi kaydet
CreateThread(function()
    while true do
        Wait(30000)
        for _, oyuncuId in ipairs(GetPlayers()) do
            konumuAl(tonumber(oyuncuId))
        end
        dosyayaYaz()
    end
end)
