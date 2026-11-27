-- client.lua: Oyuna girince kayıtlı konumunu sunucudan ister ve oraya ışınlar.

local ilkDogus = true

-- "playerSpawned": Oyuncu her doğduğunda tetiklenir (girişte ve öldükten sonra).
-- Biz sadece oyuna ilk girişte ışınlamak istiyoruz, öldükten sonra değil.
AddEventHandler('playerSpawned', function()
    if not ilkDogus then return end
    ilkDogus = false
    TriggerServerEvent('konum:iste')
end)

-- Sunucu kayıtlı konumu gönderince
RegisterNetEvent('konum:gonder', function(konum)
    if konum then
        local karakter = PlayerPedId()

        DoScreenFadeOut(300)
        Wait(300)
        FreezeEntityPosition(karakter, true)

        -- Önce oraya git, sonra zeminin yüklenmesini bekle (en fazla 3 saniye),
        -- yoksa yüklenmemiş zeminden aşağı düşebilirsin.
        SetEntityCoords(karakter, konum.x, konum.y, konum.z, false, false, false, false)
        SetEntityHeading(karakter, konum.yon or 0.0)
        local bekle = 0
        while not HasCollisionLoadedAroundEntity(karakter) and bekle < 300 do
            RequestCollisionAtCoord(konum.x, konum.y, konum.z)
            Wait(10)
            bekle = bekle + 1
        end

        FreezeEntityPosition(karakter, false)
        DoScreenFadeIn(500)
        TriggerEvent('chat:addMessage', { args = { '^5[Konum]', 'Kaldığın yere döndün.' } })
    end

    -- Sunucuya "yerleştim, artık konumumu kaydedebilirsin" de
    TriggerServerEvent('konum:yerlesti')
end)
