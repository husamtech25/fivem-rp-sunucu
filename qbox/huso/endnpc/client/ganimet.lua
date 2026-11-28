-- client/ganimet.lua
-- Ganimeti olan ölü NPC'ye Sol Alt ile bakınca "Üstünü ara" çıkar.
-- Arama birkaç saniye sürer (çömelme animasyonu); eşyaları sunucu verir.

exports.ox_target:addGlobalPed({
    {
        name = 'endnpc_yagmala',
        label = 'Üstünü ara',
        icon = 'fa-solid fa-hand-holding-dollar',
        distance = 2.0,
        canInteract = function(ped)
            return IsEntityDead(ped) and NetworkGetEntityIsNetworked(ped) and Entity(ped).state.endnpcGanimet == true
        end,
        onSelect = function(data)
            local netId = NetworkGetNetworkIdFromEntity(data.entity)
            local bitti = lib.progressCircle({
                duration = 4000,
                label = 'Üstünü arıyorsun...',
                position = 'bottom',
                canCancel = true,
                disable = { move = true, car = true, combat = true },
                anim = { dict = 'amb@medic@standing@kneel@base', clip = 'base' },
            })
            if not bitti then return end
            local sonuc = lib.callback.await('endnpc:yagmala', false, netId)
            if sonuc then
                lib.notify({ description = sonuc.mesaj, type = sonuc.ok and 'success' or 'error' })
            end
        end,
    },
})

AddEventHandler('onResourceStop', function(kaynak)
    if kaynak == GetCurrentResourceName() then
        exports.ox_target:removeGlobalPed('endnpc_yagmala')
    end
end)
