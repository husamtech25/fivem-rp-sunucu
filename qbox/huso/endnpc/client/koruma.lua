-- client/koruma.lua
-- 1) Ajans: panelde seçilen yerde duran NPC. Sol Alt → "Koruma kirala" → kaç kişi?
-- 2) Kiralanan korumalar: GTA'nın "grup üyesi" sistemiyle peşinden gelir, arabana biner,
--    sana saldıranlara ve senin saldırdıklarına saldırır. Süre dolunca sunucu siler.

local ajans            -- ajansta duran (sadece bizim ekranımızdaki) NPC
local ajansAyari       -- son oluşturulan ajansın ayarı (değişince yeniden oluşturulur)
local korumalarim = {} -- kiraladığımız korumaların ped'leri

-- ================= Ajans =================

local function ajansiKaldir()
    if ajans and DoesEntityExist(ajans) then
        exports.ox_target:removeLocalEntity(ajans)
        DeleteEntity(ajans)
    end
    ajans = nil
end

local function korumaKirala()
    local k = Senk.ayarlar.koruma
    local cevap = lib.inputDialog('Kiralık koruma', {
        {
            type = 'number',
            label = 'Kaç koruma?',
            description = ('Kişi başı $%d · %d dakika · en fazla %d'):format(k.fiyat, k.sure, k.enFazla),
            default = 1, min = 1, max = k.enFazla, required = true,
        },
    })
    if not cevap then return end

    local sonuc = lib.callback.await('endnpc:korumaKirala', false, cevap[1])
    if not sonuc or not sonuc.ok then
        lib.notify({ description = sonuc and sonuc.mesaj or 'Ajans cevap vermedi.', type = 'error' })
        return
    end

    -- Korumaları yanımızda oluştur ve grubumuza al
    local hash = GetHashKey(sonuc.model)
    lib.requestModel(hash, 10000)
    local ben = PlayerPedId()
    local grup = GetPedGroupIndex(ben)
    local benimIliskim = GetPedRelationshipGroupHash(ben)
    local netIds = {}

    for i = 1, sonuc.adet do
        local k = GetOffsetFromEntityInWorldCoords(ben, (i % 2 == 0) and 1.5 or -1.5, -1.5 - i * 0.5, 0.0)
        local ped = CreatePed(4, hash, k.x, k.y, k.z, GetEntityHeading(ben), true, true)
        local bitis = GetGameTimer() + 3000
        while not DoesEntityExist(ped) and GetGameTimer() < bitis do Wait(0) end
        if DoesEntityExist(ped) then
            SetPedAsGroupMember(ped, grup)
            SetPedNeverLeavesGroup(ped, true)
            SetPedCanTeleportToGroupLeader(ped, grup, true)
            SetPedRelationshipGroupHash(ped, benimIliskim)   -- sana düşman olanlar ona da düşman
            SetPedMaxHealth(ped, 100 + sonuc.can)
            SetEntityMaxHealth(ped, 100 + sonuc.can)
            SetEntityHealth(ped, 100 + sonuc.can)
            SetPedArmour(ped, sonuc.zirh)
            if sonuc.silah ~= 'WEAPON_UNARMED' then
                local silah = GetHashKey(sonuc.silah)
                GiveWeaponToPed(ped, silah, 9999, false, true)
                SetPedInfiniteAmmo(ped, true, silah)
            end
            SetPedCombatAbility(ped, 2)
            SetPedCombatMovement(ped, 2)
            SetPedCombatRange(ped, 1)
            SetPedAccuracy(ped, 55)
            SetPedCombatAttributes(ped, 0, true)    -- siper
            SetPedCombatAttributes(ped, 5, true)    -- silahsız da dövüşür
            SetPedCombatAttributes(ped, 46, true)   -- her zaman savaşır
            SetPedFleeAttributes(ped, 0, false)     -- kaçmaz
            SetPedDropsWeaponsWhenDead(ped, false)
            SetPedDiesWhenInjured(ped, true)
            exports.ox_target:addLocalEntity(ped, {
                {
                    name = 'endnpc_koruma_gonder',
                    label = 'Korumaları gönder',
                    icon = 'fa-solid fa-user-xmark',
                    distance = 2.5,
                    onSelect = function()
                        TriggerServerEvent('endnpc:korumaGonder')
                    end,
                },
            })
            korumalarim[#korumalarim + 1] = ped
            netIds[#netIds + 1] = NetworkGetNetworkIdFromEntity(ped)
        end
    end
    SetModelAsNoLongerNeeded(hash)
    SetGroupFormation(grup, 1)   -- etrafında dağınık dursunlar
    TriggerServerEvent('endnpc:korumaKaydet', netIds)

    lib.notify({
        title = 'Koruma ajansı',
        description = ('%d koruma tuttun ($%d). %d dakika yanında kalacaklar. Göndermek için Sol Alt ile korumaya bak.'):format(#netIds, sonuc.tutar, sonuc.sure),
        type = 'success',
        duration = 8000,
    })
end

local function ajansiOlustur()
    local k = Senk.ayarlar.koruma
    local isaret = k and k.aktif and k.ajans and ('%s|%.1f|%.1f|%.1f|%.1f'):format(k.ajansModel, k.ajans.x, k.ajans.y, k.ajans.z, k.ajans.h)
    if isaret == ajansAyari then return end   -- değişiklik yok
    ajansiKaldir()
    ajansAyari = isaret
    if not isaret then return end

    local hash = GetHashKey(k.ajansModel)
    if not IsModelInCdimage(hash) then return end
    lib.requestModel(hash, 10000)
    ajans = CreatePed(4, hash, k.ajans.x, k.ajans.y, k.ajans.z, k.ajans.h, false, false)
    SetModelAsNoLongerNeeded(hash)
    FreezeEntityPosition(ajans, true)
    SetEntityInvincible(ajans, true)
    SetBlockingOfNonTemporaryEvents(ajans, true)
    TaskStartScenarioInPlace(ajans, 'WORLD_HUMAN_CLIPBOARD', 0, true)
    exports.ox_target:addLocalEntity(ajans, {
        {
            name = 'endnpc_koruma_kirala',
            label = 'Koruma kirala',
            icon = 'fa-solid fa-user-shield',
            distance = 2.5,
            onSelect = korumaKirala,
        },
    })
end

local ajansBlip
local function ajansBlipGuncelle()
    local k = Senk.ayarlar.koruma
    if ajansBlip then RemoveBlip(ajansBlip) ajansBlip = nil end
    if not (k and k.aktif and k.ajans) then return end
    ajansBlip = AddBlipForCoord(k.ajans.x, k.ajans.y, k.ajans.z)
    SetBlipSprite(ajansBlip, 487)
    SetBlipColour(ajansBlip, 4)
    SetBlipScale(ajansBlip, 0.8)
    SetBlipAsShortRange(ajansBlip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('Koruma ajansı')
    EndTextCommandSetBlipName(ajansBlip)
end

AddEventHandler('endnpc:senkGeldi', function()
    ajansiOlustur()
    ajansBlipGuncelle()
end)

-- ================= Süre bitti / gönderildi =================

RegisterNetEvent('endnpc:korumaBitti', function(sebep)
    for _, ped in ipairs(korumalarim) do
        if DoesEntityExist(ped) then exports.ox_target:removeLocalEntity(ped) end
    end
    korumalarim = {}
    lib.notify({
        title = 'Koruma ajansı',
        description = sebep == 'sure' and 'Korumalarının süresi doldu, ayrıldılar.' or 'Korumaları gönderdin.',
        type = 'inform',
    })
end)

AddEventHandler('onResourceStop', function(kaynak)
    if kaynak ~= GetCurrentResourceName() then return end
    ajansiKaldir()
    if ajansBlip then RemoveBlip(ajansBlip) end
end)
