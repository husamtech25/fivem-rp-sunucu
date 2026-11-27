-- client.lua: Sunucudan gelen hava ve saati oyuna uygular.
-- GTA kendi kafasına göre havayı/saati değiştirmeye çalışır; biz her saniye sunucununkini zorluyoruz.

local durum = nil          -- sunucudan gelen son durum
local suankiHava = nil     -- oyunda şu an ayarlı hava
local gecisBitis = 0       -- hava geçişinin biteceği zaman

RegisterNetEvent('dunya:durum', function(yeniDurum)
    durum = yeniDurum
end)

-- Oyuna girince sunucudan mevcut durumu iste
CreateThread(function()
    TriggerServerEvent('dunya:iste')
end)

CreateThread(function()
    while true do
        Wait(1000)
        if durum then
            -- Hava değiştiyse 15 saniyede yumuşak geçiş yap
            if durum.hava ~= suankiHava then
                SetWeatherTypeOvertimePersist(durum.hava, 15.0)
                suankiHava = durum.hava
                gecisBitis = GetGameTimer() + 15000   -- GetGameTimer: milisaniye cinsinden zaman

                -- Karlı havalarda yerde iz kalsın
                local karli = (durum.hava == 'XMAS' or durum.hava == 'BLIZZARD')
                SetForceVehicleTrails(karli)
                SetForcePedFootstepsTracks(karli)
            elseif GetGameTimer() > gecisBitis then
                -- Geçiş bittikten sonra havayı sabitle, oyun değiştirmesin
                ClearOverrideWeather()
                ClearWeatherTypePersist()
                SetWeatherTypePersist(suankiHava)
                SetWeatherTypeNow(suankiHava)
                SetWeatherTypeNowPersist(suankiHava)
            end

            -- Saati sunucununkine eşitle
            NetworkOverrideClockTime(durum.saat, durum.dakika, 0)
        end
    end
end)

-- Sohbette komut önerileri
TriggerEvent('chat:addSuggestion', '/hava', 'Havayı değiştirir (admin)', {
    { name = 'tür', help = 'gunesli, acik, bulutlu, kapali, yagmur, firtina, sis, kar, tipi, cadilar' }
})
TriggerEvent('chat:addSuggestion', '/saat', 'Saati ayarlar (admin)', {
    { name = 'saat', help = '0-23' },
    { name = 'dakika', help = '0-59 (isteğe bağlı)' },
})
TriggerEvent('chat:addSuggestion', '/gece', 'Saati 23:00 yapar (admin)')
TriggerEvent('chat:addSuggestion', '/gunduz', 'Saati 12:00 yapar (admin)')
TriggerEvent('chat:addSuggestion', '/saatdondur', 'Saati durdurur / tekrar akıtır (admin)')
