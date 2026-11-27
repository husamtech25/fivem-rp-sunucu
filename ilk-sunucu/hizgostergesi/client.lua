-- client.lua: Hız göstergesi
-- Araçtayken her 100 milisaniyede bir hızı, vitesi ve devri ölçüp arayüze (html) gönderir.

local gorunur = false  -- gösterge şu an ekranda mı?

-- CreateThread + while true: Oyun açık olduğu sürece sürekli dönen bir döngü.
-- İçinde mutlaka Wait() olmalı, yoksa oyun donar!
CreateThread(function()
    while true do
        local oyuncu = PlayerPedId()
        local arac = GetVehiclePedIsIn(oyuncu, false)

        if arac ~= 0 then
            -- GetEntitySpeed metre/saniye verir. km/s için 3.6 ile çarpıyoruz.
            local hiz = GetEntitySpeed(arac) * 3.6

            SendNUIMessage({
                islem = 'guncelle',
                hiz = math.floor(hiz),                 -- küsuratı at: 87.6 -> 87
                vites = GetVehicleCurrentGear(arac),   -- 0 = geri vites
                devir = GetVehicleCurrentRpm(arac),    -- 0.0 ile 1.0 arası
                motorHasari = GetVehicleEngineHealth(arac) < 400, -- motor kötüyse uyarı
            })

            if not gorunur then
                SendNUIMessage({ islem = 'goster' })
                gorunur = true
            end
            Wait(100)
        else
            if gorunur then
                SendNUIMessage({ islem = 'gizle' })
                gorunur = false
            end
            Wait(500)  -- araçta değilken daha seyrek kontrol et, bilgisayarı yormayalım
        end
    end
end)
