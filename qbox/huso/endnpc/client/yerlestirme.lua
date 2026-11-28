-- client/yerlestirme.lua
-- "Nişan alarak yerleştir": ekranın ortasının baktığı yere yarı saydam bir NPC önizlemesi koyar.
--   [E] yerleştir   [Fare tekerleği] döndür   [Backspace / Sağ tık] iptal
-- Sonuç: { x, y, z (ayak hizası), h } veya iptal edilirse nil

local function yonVektoru(rot)
    local x, z = math.rad(rot.x), math.rad(rot.z)
    local c = math.abs(math.cos(x))
    return vector3(-math.sin(z) * c, math.cos(z) * c, math.sin(x))
end

-- Kameranın baktığı noktaya ışın gönderir, bir yüzeye çarparsa o noktayı döner
local function bakilanNokta(haric)
    local kamera = GetGameplayCamCoord()
    local hedef = kamera + yonVektoru(GetGameplayCamRot(2)) * 60.0
    local test = StartExpensiveSynchronousShapeTestLosProbe(kamera.x, kamera.y, kamera.z, hedef.x, hedef.y, hedef.z, 1 + 16, haric, 4)
    local _, carpti, nokta = GetShapeTestResult(test)
    return carpti == 1, nokta
end

-- Bu tuşlar yerleştirirken silah / silah çarkı açmasın
local KAPALI_TUSLAR = { 14, 15, 16, 17, 24, 25, 37, 44, 140, 141, 142, 257 }

function KonumSec(model)
    local hash = GetHashKey(model)
    if not IsModelInCdimage(hash) or not IsModelAPed(hash) then return nil end
    RequestModel(hash)
    local bitis = GetGameTimer() + 5000
    while not HasModelLoaded(hash) and GetGameTimer() < bitis do Wait(0) end
    if not HasModelLoaded(hash) then return nil end

    local benim = PlayerPedId()
    local baslangic = GetEntityCoords(benim)
    -- false, false: sadece bizim ekranımızda, ağa gönderilmeyen önizleme
    local hayalet = CreatePed(4, hash, baslangic.x, baslangic.y, baslangic.z, 0.0, false, false)
    SetModelAsNoLongerNeeded(hash)
    SetEntityAlpha(hayalet, 150, false)
    SetEntityCollision(hayalet, false, false)
    FreezeEntityPosition(hayalet, true)
    SetEntityInvincible(hayalet, true)
    SetBlockingOfNonTemporaryEvents(hayalet, true)

    local yon = (GetEntityHeading(benim) + 180.0) % 360   -- varsayılan: sana dönük dursun
    lib.showTextUI('[E] Yerleştir  ·  [Tekerlek] Döndür  ·  [Backspace] İptal', { position = 'top-center' })

    local sonuc
    while true do
        Wait(0)
        for _, tus in ipairs(KAPALI_TUSLAR) do DisableControlAction(0, tus, true) end

        local carpti, nokta = bakilanNokta(benim)
        if carpti then
            SetEntityCoordsNoOffset(hayalet, nokta.x, nokta.y, nokta.z + 1.0, false, false, false)
            SetEntityHeading(hayalet, yon)
            DrawMarker(25, nokta.x, nokta.y, nokta.z + 0.02, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                1.2, 1.2, 1.0, 255, 122, 26, 160, false, false, 2, false, nil, nil, false)
        end

        if IsDisabledControlJustPressed(0, 15) then yon = (yon + 10.0) % 360 end   -- tekerlek yukarı
        if IsDisabledControlJustPressed(0, 14) then yon = (yon - 10.0) % 360 end   -- tekerlek aşağı

        if carpti and IsControlJustPressed(0, 38) then                              -- E
            sonuc = { x = nokta.x, y = nokta.y, z = nokta.z, h = yon }
            break
        end
        if IsControlJustPressed(0, 177) or IsDisabledControlJustPressed(0, 25) then -- Backspace / sağ tık
            break
        end
    end

    lib.hideTextUI()
    DeleteEntity(hayalet)
    return sonuc
end
