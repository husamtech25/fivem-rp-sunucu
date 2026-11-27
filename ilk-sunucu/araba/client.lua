-- client.lua: Oyuncunun bilgisayarında çalışan kod.
-- Komutlar:
--   /araba adder   -> adını yazdığın aracı çıkarır
--   /garaj  (F5)   -> araç seçme menüsünü açar

-- Sohbete yeşil [Araba] etiketiyle mesaj yazan yardımcı fonksiyon.
local function mesaj(yazi)
    TriggerEvent('chat:addMessage', { args = { '^2[Araba]', yazi } })
end

-- Araç çıkarma işini bir fonksiyona taşıdık.
-- Böylece hem /araba komutu hem de menü aynı kodu kullanıyor (kodu iki kere yazmıyoruz).
local function aracCikar(aracAdi)
    -- GTA'da her aracın bir "model hash"i (sayısal kimliği) vardır. İsmi sayıya çeviriyoruz.
    local model = GetHashKey(aracAdi)

    -- Böyle bir araç gerçekten var mı?
    if not IsModelInCdimage(model) or not IsModelAVehicle(model) then
        mesaj('"' .. aracAdi .. '" diye bir araç bulamadım.')
        return
    end

    -- Aracın modelini oyuna yükle ve yüklenene kadar bekle
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(10)  -- 10 milisaniye bekle, sonra tekrar kontrol et
    end

    -- Oyuncunun karakteri (ped), konumu ve baktığı yön
    local oyuncu = PlayerPedId()
    local konum = GetEntityCoords(oyuncu)
    local yon = GetEntityHeading(oyuncu)

    -- Aracı oyuncunun olduğu yerde oluştur
    local arac = CreateVehicle(model, konum.x, konum.y, konum.z, yon, true, false)

    -- Aracın ağa kaydolmasını bekle (en fazla 1 saniye).
    -- Ağa kayıtlı araçların bir "ağ kimliği" (netId) olur, sunucu aracı bununla tanır.
    local bekle = 0
    while not NetworkGetEntityIsNetworked(arac) and bekle < 100 do
        Wait(10)
        bekle = bekle + 1
    end

    -- Sunucuya "yeni aracım bu" de. Sunucu eskisini haritanın neresinde olursa olsun siler.
    TriggerServerEvent('araba:yeniArac', NetworkGetNetworkIdFromEntity(arac))

    -- Oyuncuyu sürücü koltuğuna oturt (-1 = sürücü koltuğu)
    SetPedIntoVehicle(oyuncu, arac, -1)

    -- Modeli bellekten serbest bırak (artık ihtiyacımız yok)
    SetModelAsNoLongerNeeded(model)

    mesaj(aracAdi .. ' hazır, iyi sürüşler!')
end

-- /araba komutu: "/araba sultan" yazarsan args[1] = "sultan" olur.
RegisterCommand('araba', function(source, args)
    aracCikar(args[1] or 'adder')
end, false)
-- Sondaki false: Bu komutu herkes kullanabilir (sadece adminler değil).

-- /sil komutu: Silme işini sunucu yapıyor, biz sadece haber veriyoruz.
RegisterCommand('sil', function()
    TriggerServerEvent('araba:sil')
end, false)


-- ================= GARAJ MENÜSÜ =================

-- Menüyü aç/kapat. SetNuiFocus(klavye, fare): menü açıkken fare ve klavye menüye gider.
local function menuAc()
    SetNuiFocus(true, true)
    SendNUIMessage({ islem = 'ac' })
end

local function menuKapat()
    SetNuiFocus(false, false)
    SendNUIMessage({ islem = 'kapat' })
end

RegisterCommand('garaj', menuAc, false)

-- F5 tuşuna /garaj komutunu bağla.
-- Oyuncu bunu GTA Ayarlar > Tuş Atamaları > FiveM kısmından değiştirebilir.
RegisterKeyMapping('garaj', 'Garaj menüsünü aç', 'keyboard', 'F5')

-- Menüde bir araca tıklanınca script.js buraya "sec" mesajı gönderir.
RegisterNUICallback('sec', function(veri, cevap)
    cevap('ok')  -- script.js'e hemen "aldım" diye cevap ver
    menuKapat()
    -- CreateThread: Kodu ayrı bir "iş parçacığında" çalıştırır.
    -- aracCikar içinde Wait() ile bekleme yapıyoruz; menü callback'inin içinde
    -- beklemek sorun çıkarabildiği için işi ayrı bir thread'e veriyoruz.
    CreateThread(function()
        aracCikar(veri.model)
    end)
end)

-- Menüdeki "Aracımı sil" butonuna basılınca
RegisterNUICallback('sil', function(veri, cevap)
    menuKapat()
    TriggerServerEvent('araba:sil')
    cevap('ok')
end)

-- Menüdeki X'e veya ESC'ye basılınca
RegisterNUICallback('kapat', function(veri, cevap)
    menuKapat()
    cevap('ok')
end)

-- Sohbette /ga yazınca komutun açıklaması görünsün
TriggerEvent('chat:addSuggestion', '/garaj', 'Araç seçme menüsünü açar (kısayol: F5)')
TriggerEvent('chat:addSuggestion', '/sil', 'Çıkardığın son aracı siler')
TriggerEvent('chat:addSuggestion', '/araba', 'Adını yazdığın aracı çıkarır', {
    { name = 'model', help = 'Örnek: adder, sultan, bati, maverick' }
})
