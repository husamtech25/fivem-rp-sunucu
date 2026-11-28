-- client/etkinlik.lua
-- Etkinlik duyuruları (ekranın üstünde bildirim + ses) ve süren etkinliğin haritadaki işareti.

RegisterNetEvent('endnpc:duyuru', function(baslik, mesaj, tur)
    lib.notify({
        title = baslik,
        description = mesaj,
        type = tur,
        position = 'top',
        duration = 9000,
    })
    PlaySoundFrontend(-1, 'CHECKPOINT_PERFECT', 'HUD_MINI_GAME_SOUNDSET', true)
end)

local daire, isaret
local sonEtkinlik

local function isaretleriKaldir()
    if daire then RemoveBlip(daire) daire = nil end
    if isaret then RemoveBlip(isaret) isaret = nil end
end

AddEventHandler('endnpc:senkGeldi', function()
    local e = Senk.etkinlik
    local anahtar = e and ('%s|%d'):format(e.ad, e.dalga or 0)
    if anahtar == sonEtkinlik then return end
    sonEtkinlik = anahtar
    isaretleriKaldir()
    if not e then return end

    daire = AddBlipForRadius(e.x, e.y, e.z, 80.0)
    SetBlipColour(daire, 1)
    SetBlipAlpha(daire, 110)
    SetBlipFlashes(daire, true)

    isaret = AddBlipForCoord(e.x, e.y, e.z)
    SetBlipSprite(isaret, 84)
    SetBlipColour(isaret, 1)
    SetBlipScale(isaret, 1.0)
    SetBlipAsShortRange(isaret, false)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(('Etkinlik: %s (dalga %d/%d)'):format(e.ad, e.dalga or 0, e.dalgaSayisi or 0))
    EndTextCommandSetBlipName(isaret)
end)

AddEventHandler('onResourceStop', function(kaynak)
    if kaynak == GetCurrentResourceName() then isaretleriKaldir() end
end)
