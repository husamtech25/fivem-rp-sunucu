-- client.lua: Oyuncu komutları
--   /tp     -> Haritada işaretlediğin noktaya ışınlanır
--   /can    -> Canı ve zırhı doldurur
--   /tamir  -> Bindiğin aracı tamir eder ve temizler

local function mesaj(yazi)
    TriggerEvent('chat:addMessage', { args = { '^3[Komut]', yazi } })
end


-- ================= /tp =================
RegisterCommand('tp', function()
    -- Haritada koyduğun işaret (waypoint) bir "blip"tir. 8 = waypoint türü.
    local isaret = GetFirstBlipInfoId(8)
    if not DoesBlipExist(isaret) then
        mesaj('Önce haritada (ESC > Harita) bir yere işaret koy.')
        return
    end

    -- İşaretin x ve y koordinatı. Haritada yükseklik (z) olmadığı için yeri biz bulacağız.
    local hedef = GetBlipInfoIdCoord(isaret)
    local x, y = hedef.x, hedef.y

    -- Araçtaysan aracı, değilsen karakteri ışınlayacağız
    local oyuncu = PlayerPedId()
    local tasinacak = oyuncu
    if IsPedInAnyVehicle(oyuncu, false) then
        tasinacak = GetVehiclePedIsIn(oyuncu, false)
    end

    -- Işınlanırken düşmeyelim diye dondur ve ekranı karart
    FreezeEntityPosition(tasinacak, true)
    DoScreenFadeOut(300)
    Wait(300)

    -- Zemini bulmak için farklı yüksekliklere ışınlanıp "altımda zemin var mı?" diye soruyoruz.
    -- Oyun, uzaktaki bölgelerin zeminini sen oraya yaklaşana kadar yüklemiyor; bu yüzden deneme yapıyoruz.
    local zeminZ = nil
    for yukseklik = 0, 1000, 25 do
        SetEntityCoordsNoOffset(tasinacak, x, y, yukseklik + 0.0, false, false, false)
        RequestCollisionAtCoord(x, y, yukseklik + 0.0)
        Wait(10)
        local bulundu, z = GetGroundZFor_3dCoord(x, y, yukseklik + 0.0, false)
        if bulundu then
            zeminZ = z
            break
        end
    end

    -- Zemin bulunamazsa (örneğin denizin ortası) 100 metre yükseğe koy
    SetEntityCoordsNoOffset(tasinacak, x, y, (zeminZ or 100.0) + 1.0, false, false, false)

    FreezeEntityPosition(tasinacak, false)
    DoScreenFadeIn(300)
    mesaj('Işınlandın!')
end, false)


-- ================= /can =================
RegisterCommand('can', function()
    local oyuncu = PlayerPedId()
    SetEntityHealth(oyuncu, GetEntityMaxHealth(oyuncu))  -- canı en yükseğe çıkar
    SetPedArmour(oyuncu, 100)                            -- zırh: 0-100 arası
    ClearPedBloodDamage(oyuncu)                          -- üstündeki kanı temizle
    mesaj('Can ve zırh dolduruldu.')
end, false)


-- ================= /tamir =================
RegisterCommand('tamir', function()
    local oyuncu = PlayerPedId()
    local arac = GetVehiclePedIsIn(oyuncu, false)  -- 0 dönerse araçta değilsin

    if arac == 0 then
        mesaj('Tamir için bir aracın içinde olmalısın.')
        return
    end

    SetVehicleFixed(arac)                  -- hasarı gider (cam, kapı, tekerlek...)
    SetVehicleDeformationFixed(arac)       -- göçükleri düzelt
    SetVehicleEngineHealth(arac, 1000.0)   -- motor sağlığı: 1000 = sıfır gibi
    SetVehiclePetrolTankHealth(arac, 1000.0)
    SetVehicleDirtLevel(arac, 0.0)         -- çamuru/tozu temizle
    mesaj('Araç tamir edildi ve yıkandı.')
end, false)


-- Sohbette komut yazarken açıklama görünsün
TriggerEvent('chat:addSuggestion', '/tp', 'Haritada işaretlediğin yere ışınlanır')
TriggerEvent('chat:addSuggestion', '/can', 'Canı ve zırhı doldurur')
TriggerEvent('chat:addSuggestion', '/tamir', 'Bindiğin aracı tamir eder ve temizler')
