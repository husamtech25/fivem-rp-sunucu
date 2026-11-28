-- client/ai.lua
-- NPC'lerin beyni. FiveM'de her NPC'yi ona en yakın oyuncunun oyunu yönetir ("sahip").
-- Bu dosya sadece BİZİM sahibi olduğumuz NPC'lere komut verir; sahip değişirse
-- yeni sahibin oyunu aynı ayarları otomatik uygular.
--
-- Savaş iki katmanlı:
--   1) GTA'nın kendi savaş yapay zekası: gruplar arası "ilişki" (dost / tarafsız / düşman) ayarlanır,
--      düşman NPC'ler birbirini görünce kendileri çatışır, siper alır, takip eder.
--   2) Bizim kontrolümüz: görüş / saldırı mesafesi, evden fazla uzaklaşınca geri dönme,
--      canı azalınca davranış değiştirme, devriye rotası, araç sürme, bölge alarmı, ölüm bildirimi.

Senk = { surum = -1, gruplar = {}, iliskiler = {}, ayarlar = {}, npcler = {}, bolgeler = {}, etkinlik = nil }

local OYUNCU_GRUBU = GetHashKey('PLAYER')
local ILISKI_DEGERI = { dost = 1, tarafsiz = 3, dusman = 5 }  -- GTA: 0 arkadaş, 1 saygı, 3 tarafsız, 5 nefret
local HAREKET_DEGERI = { sabit = 0, savunmaci = 1, saldirgan = 2 } -- GTA: 3 = intihar saldırısı
local SURUS_STILI = 786603   -- trafik kurallarına uyan normal sürüş
local kurulanGruplar = {}
local durumlar = {}   -- [npcId] = bu NPC için tuttuğumuz geçici bilgiler (sadece sahibiysek)

-- ================= Gruplar arası ilişkiler =================

-- Her grubun iki GTA grubu var: normal ve "pasif" (pasif davranışlı NPC'ler kimseye saldırmasın,
-- ama düşmanları yine onlara saldırabilsin diye)
function GrupHash(id, pasif)
    return GetHashKey('ENDNPC_' .. id .. (pasif and '_P' or ''))
end

function Iliski(a, b)
    if a == b then return 'dost' end
    if a > b then a, b = b, a end
    return Senk.iliskiler[a .. '|' .. b] or 'tarafsiz'
end

local function iliskileriKur()
    for id in pairs(Senk.gruplar) do
        if not kurulanGruplar[id] then
            AddRelationshipGroup('ENDNPC_' .. id)
            AddRelationshipGroup('ENDNPC_' .. id .. '_P')
            kurulanGruplar[id] = true
        end
    end

    for a, grupA in pairs(Senk.gruplar) do
        local anaA, pasifA = GrupHash(a), GrupHash(a, true)
        for b in pairs(Senk.gruplar) do
            local anaB, pasifB = GrupHash(b), GrupHash(b, true)
            local deger = a == b and 0 or ILISKI_DEGERI[Iliski(a, b)]
            local pasifDeger = deger == 5 and 3 or deger   -- pasifler kimseden nefret etmez
            SetRelationshipBetweenGroups(deger, anaA, anaB)
            SetRelationshipBetweenGroups(deger, anaA, pasifB)
            SetRelationshipBetweenGroups(pasifDeger, pasifA, anaB)
            SetRelationshipBetweenGroups(pasifDeger, pasifA, pasifB)
        end

        local oyuncu = ILISKI_DEGERI[grupA.oyuncuIliskisi] or 3
        SetRelationshipBetweenGroups(oyuncu, anaA, OYUNCU_GRUBU)
        SetRelationshipBetweenGroups(oyuncu, OYUNCU_GRUBU, anaA)
        SetRelationshipBetweenGroups(oyuncu == 5 and 3 or oyuncu, pasifA, OYUNCU_GRUBU)
        SetRelationshipBetweenGroups(oyuncu, OYUNCU_GRUBU, pasifA)
    end
end

RegisterNetEvent('endnpc:senk', function(paket)
    Senk.gruplar = paket.gruplar or {}
    Senk.iliskiler = paket.iliskiler or {}
    Senk.ayarlar = paket.ayarlar or {}
    Senk.npcler = paket.npcler or {}
    Senk.bolgeler = paket.bolgeler or {}
    Senk.etkinlik = paket.etkinlik
    Senk.surum = paket.surum or 0
    iliskileriKur()
    TriggerEvent('endnpc:senkGeldi')   -- koruma ajansı ve etkinlik işareti güncellensin
end)

CreateThread(function()
    TriggerServerEvent('endnpc:senkIste')
end)

-- ================= Yardımcılar =================

-- Bizim oyunumuzda var olan NPC'lerin listesi (uzaktakiler oyunumuzda yüklü değildir)
function YereldekiNpcler()
    local liste = {}
    for id, n in pairs(Senk.npcler) do
        local g = Senk.gruplar[n.grup]
        if g and n.netId and NetworkDoesNetworkIdExist(n.netId) then
            local ped = NetworkGetEntityFromNetworkId(n.netId)
            if ped ~= 0 and DoesEntityExist(ped) then
                liste[#liste + 1] = { id = id, ped = ped, n = n, g = g }
            end
        end
    end
    return liste
end

local function olu(ped)
    return IsEntityDead(ped) or IsPedFatallyInjured(ped)
end

-- NPC'nin aracı (yoksa, uzaktaysa veya patladıysa nil)
local function aracGetir(n)
    if not n.aracNetId or not NetworkDoesNetworkIdExist(n.aracNetId) then return nil end
    local arac = NetworkGetEntityFromNetworkId(n.aracNetId)
    if arac == 0 or not DoesEntityExist(arac) or not IsVehicleDriveable(arac, false) then return nil end
    return arac
end

-- Oyuncu "saldırılabilir" mi? (ölü ve görünmez / noclip'teki adminler hariç)
local function oyuncuHedeflenebilir(p)
    return p ~= 0 and not olu(p) and IsEntityVisible(p)
end

-- ================= Ayarları NPC'ye uygula =================

local function silahHazirla(ped, silah)
    if silah == 'WEAPON_UNARMED' then return end
    local hash = GetHashKey(silah)
    if not HasPedGotWeapon(ped, hash, false) then
        GiveWeaponToPed(ped, hash, 9999, false, true)
    end
    SetPedInfiniteAmmo(ped, true, hash)
    SetCurrentPedWeapon(ped, hash, true)
end

local function yapilandir(ped, n, g)
    local pasif = n.davranis == 'pasif'
    local ofke = n.ofke or g.ofke

    SetPedRelationshipGroupHash(ped, GrupHash(n.grup, pasif))

    -- Algılama
    SetPedSeeingRange(ped, g.gorusMesafesi + 0.0)
    SetPedHearingRange(ped, g.gorusMesafesi + 0.0)
    SetPedAlertness(ped, ofke >= 50 and 3 or 2)

    -- Savaş yeteneği ve mesafesi
    SetPedCombatAbility(ped, ofke < 34 and 0 or (ofke < 67 and 1 or 2))
    SetPedCombatRange(ped, g.saldiriMesafesi < 15 and 0 or (g.saldiriMesafesi < 40 and 1 or 2))
    SetPedAccuracy(ped, math.floor(g.isabet))
    SetPedShootRate(ped, math.floor(20 + g.saldiriSikligi * 9.8))   -- 0-100 -> 20-1000

    local hareket = HAREKET_DEGERI[g.hareket] or 2
    if n.davranis == 'sabit' then hareket = 0
    elseif n.davranis == 'saldirgan' then hareket = math.max(hareket, 2) end
    if hareket == 2 and ofke >= 90 then hareket = 3 end
    SetPedCombatMovement(ped, hareket)

    -- Savaş davranışları (GTA "combat attribute" numaraları)
    SetPedCombatAttributes(ped, 0, true)                      -- siper kullanabilir
    SetPedCombatAttributes(ped, 1, true)                      -- araç kullanabilir
    SetPedCombatAttributes(ped, 2, true)                      -- araçtan ateş edebilir
    SetPedCombatAttributes(ped, 3, true)                      -- savaşmak için araçtan inebilir
    SetPedCombatAttributes(ped, 5, true)                      -- silahsızken de dövüşür
    SetPedCombatAttributes(ped, 46, not pasif and ofke >= 50) -- her zaman savaşır
    SetPedCombatAttributes(ped, 58, not pasif and ofke >= 50) -- savaştan kaçmaz
    SetPedCombatAttributes(ped, 17, pasif or ofke < 20)       -- hep kaçar
    SetPedFleeAttributes(ped, 0, pasif or ofke < 20)

    -- Ölünce yerde sürünmesin, doğrudan ölsün (ölüm algılaması net olsun); silahını düşürmesin
    SetPedDiesWhenInjured(ped, true)
    SetPedDropsWeaponsWhenDead(ped, false)
    SetPedKeepTask(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, false)
    SetDriverAbility(ped, 1.0)
    SetDriverAggressiveness(ped, ofke / 100)

    silahHazirla(ped, n.silah)
end

-- Can azalınca değişen davranış
local function dusukCanUygula(ped, n, g)
    local tur = g.dusukCanDavranisi
    if tur == 'kac' then
        SetPedCombatAttributes(ped, 46, false)
        SetPedCombatAttributes(ped, 58, false)
        SetPedCombatAttributes(ped, 17, true)
        SetPedFleeAttributes(ped, 0, true)
        ClearPedTasks(ped)
        local k = GetEntityCoords(ped)
        TaskSmartFleeCoord(ped, k.x, k.y, k.z, 150.0, -1, false, false)
    elseif tur == 'siper' then
        SetPedCombatMovement(ped, 1)
        SetPedCombatAttributes(ped, 0, true)
        SetPedCombatRange(ped, 2)
    elseif tur == 'cildir' then
        SetPedCombatMovement(ped, 3)
        SetPedCombatAbility(ped, 2)
        SetPedShootRate(ped, 1000)
        SetPedAccuracy(ped, math.min(100, math.floor(g.isabet) + 25))
        SetPedCombatAttributes(ped, 46, true)
        SetPedCombatAttributes(ped, 58, true)
    end
end

-- ================= Düşman arama (kendi görüşüyle) =================

local function dusmanBul(ben, liste, konum)
    local menzil = ben.g.gorusMesafesi
    local adaylar = {}

    for _, o in ipairs(liste) do
        if o.n.grup ~= ben.n.grup and not o.n.olu and Iliski(ben.n.grup, o.n.grup) == 'dusman' and not olu(o.ped) then
            local m = #(konum - GetEntityCoords(o.ped))
            if m <= menzil then adaylar[#adaylar + 1] = { ped = o.ped, m = m } end
        end
    end

    if ben.g.oyuncuIliskisi == 'dusman' then
        for _, oyuncu in ipairs(GetActivePlayers()) do
            local p = GetPlayerPed(oyuncu)
            if oyuncuHedeflenebilir(p) then
                local m = #(konum - GetEntityCoords(p))
                if m <= menzil then adaylar[#adaylar + 1] = { ped = p, m = m } end
            end
        end
    end

    table.sort(adaylar, function(a, b) return a.m < b.m end)
    -- Görüş hattı kontrolü pahalı: sadece en yakın 3 adaya bak
    for i = 1, math.min(3, #adaylar) do
        local a = adaylar[i]
        if a.m < 8.0 or HasEntityClearLosToEntity(ben.ped, a.ped, 17) then return a.ped, a.m end
    end
end

-- ================= Bölgeler =================
-- Her düşünme turunda bir kere: hangi bölgeye kim izinsiz girmiş?

local function bolgeleriTara(liste)
    local sonuc = {}
    for id, b in pairs(Senk.bolgeler) do
        local g = Senk.gruplar[b.grup]
        if b.aktif and g then
            local merkez = vector3(b.x, b.y, b.z)
            local izinsiz = {}
            for _, o in ipairs(liste) do
                if not o.n.olu and o.n.grup ~= b.grup and Iliski(b.grup, o.n.grup) == 'dusman' and not olu(o.ped)
                    and #(GetEntityCoords(o.ped) - merkez) <= b.yaricap then
                    izinsiz[#izinsiz + 1] = o.ped
                end
            end
            if g.oyuncuIliskisi == 'dusman' or b.oyuncuAlarm then
                for _, oyuncu in ipairs(GetActivePlayers()) do
                    local p = GetPlayerPed(oyuncu)
                    if oyuncuHedeflenebilir(p) and #(GetEntityCoords(p) - merkez) <= b.yaricap then
                        izinsiz[#izinsiz + 1] = p
                    end
                end
            end
            sonuc[id] = { b = b, merkez = merkez, izinsiz = izinsiz }
        end
    end
    return sonuc
end

-- Bu NPC'nin koruduğu (kendi grubunun veya dost grubun) bir bölgede alarm var mı?
-- Varsa en yakın davetsiz misafiri ve kovalama sınırını döner.
local function bolgeAlarmi(ben, konum, d, tarama)
    local simdi = GetGameTimer()
    local hedef, hedefM, sinir
    for _, t in pairs(tarama) do
        local b = t.b
        if #t.izinsiz > 0 and Iliski(b.grup, ben.n.grup) == 'dost' and #(konum - t.merkez) <= b.yaricap + 40.0 then
            d.alarmBitis = simdi + b.alarmSuresi * 1000
            d.alarmSinir = b.yaricap + ben.g.takipMesafesi
            for _, p in ipairs(t.izinsiz) do
                local m = #(konum - GetEntityCoords(p))
                if not hedefM or m < hedefM then hedef, hedefM, sinir = p, m, d.alarmSinir end
            end
        end
    end
    if hedef then
        d.alarmHedef = hedef
        return hedef, hedefM, sinir
    end
    -- Misafir bölgeden çıktı: alarm süresi bitene kadar kovalamaya devam
    local eski = d.alarmHedef
    if eski and d.alarmBitis and simdi < d.alarmBitis and DoesEntityExist(eski) and not olu(eski) then
        return eski, #(konum - GetEntityCoords(eski)), d.alarmSinir
    end
    d.alarmHedef = nil
end

-- ================= Rota =================

local function rotaGetir(n)
    if n.davranis == 'rota' and type(n.rota) == 'table' and #n.rota > 0 then return n.rota end
end

local function enYakinNokta(rota, konum)
    local enIyi, enIyiM = 1, nil
    for i, p in ipairs(rota) do
        local m = #(konum - vector3(p.x, p.y, p.z))
        if not enIyiM or m < enIyiM then enIyi, enIyiM = i, m end
    end
    return enIyi
end

local function sonrakiNokta(n, d)
    local sayi = #n.rota
    if sayi == 1 then return end
    if n.rotaTur == 'gidipGel' then
        d.rotaYon = d.rotaYon or 1
        local yeni = d.rotaIdx + d.rotaYon
        if yeni < 1 or yeni > sayi then
            d.rotaYon = -d.rotaYon
            yeni = d.rotaIdx + d.rotaYon
        end
        d.rotaIdx = yeni
    else
        d.rotaIdx = d.rotaIdx % sayi + 1
    end
end

local function rotaGorevi(ped, n, d, konum, arac, aractami)
    local p = n.rota[d.rotaIdx]
    local yakinlik = aractami and 12.0 or 2.0
    local simdi = GetGameTimer()

    if #(konum - vector3(p.x, p.y, p.z)) <= yakinlik then
        -- noktaya vardı: biraz bekle, sonra sıradakine geç
        if not d.beklemeBitis then
            d.beklemeBitis = simdi + (n.rotaBekleme or 3) * 1000
            if aractami then TaskVehicleTempAction(ped, arac, 27, (n.rotaBekleme or 3) * 1000)
            else TaskStandStill(ped, (n.rotaBekleme or 3) * 1000) end
        end
        if simdi >= d.beklemeBitis then
            d.beklemeBitis = nil
            d.rotaGorev = nil
            sonrakiNokta(n, d)
        end
        return
    end

    d.beklemeBitis = nil
    if d.rotaGorev == d.rotaIdx and simdi < (d.rotaYenile or 0) then return end
    if aractami then
        TaskVehicleDriveToCoordLongrange(ped, arac, p.x, p.y, p.z, 14.0, SURUS_STILI, yakinlik * 0.7)
    else
        TaskGoToCoordAnyMeans(ped, p.x, p.y, p.z + 1.0, 1.0, 0, false, 786603, 0xbf800000)
    end
    d.rotaGorev, d.rotaYenile = d.rotaIdx, simdi + 20000
end

-- ================= Boştayken ne yapsın =================

local function bostaGorevi(ped, n, g, d, ev, evMesafe, arac, aractami)
    local simdi = GetGameTimer()
    local anahtar

    if aractami then
        if n.davranis == 'devriye' or n.davranis == 'saldirgan' then anahtar = 'arac_gez'
        elseif evMesafe > 15.0 then anahtar = 'arac_git'
        else anahtar = 'arac_dur' end
    elseif n.davranis == 'hucum' then
        anahtar = evMesafe > 12.0 and 'hucum_kos' or 'hucum_dur'
    else
        anahtar = n.davranis
        if n.davranis == 'nobetci' or n.davranis == 'sabit' or n.davranis == 'pasif' or n.davranis == 'rota' then
            anahtar = (n.davranis == 'rota' and 'nobetci' or n.davranis) .. (evMesafe > 2.5 and '_git' or '_dur')
        end
    end

    if d.bosta == anahtar and simdi < d.bostaYenile then return end
    d.bosta, d.bostaYenile = anahtar, simdi + 15000

    if anahtar == 'hucum_kos' then
        -- hedefe koşarak git (yolda düşman görürse saldırı kısmı devreye girer)
        if aractami then
            TaskVehicleDriveToCoordLongrange(ped, arac, ev.x, ev.y, ev.z, 22.0, SURUS_STILI, 10.0)
        else
            TaskGoToCoordAnyMeans(ped, ev.x, ev.y, ev.z + 1.0, 2.0, 0, false, 786603, 0xbf800000)
        end
        d.bostaYenile = simdi + 6000
    elseif anahtar == 'hucum_dur' then
        TaskWanderInArea(ped, ev.x, ev.y, ev.z, 15.0, 1.0, 2.0)
    elseif anahtar == 'arac_gez' then
        TaskVehicleDriveWander(ped, arac, n.davranis == 'saldirgan' and 18.0 or 12.0, SURUS_STILI)
    elseif anahtar == 'arac_git' then
        TaskVehicleDriveToCoordLongrange(ped, arac, ev.x, ev.y, ev.z, 14.0, SURUS_STILI, 8.0)
    elseif anahtar == 'arac_dur' then
        TaskVehicleTempAction(ped, arac, 27, 15000)   -- fren yapıp beklesin
    elseif anahtar:sub(-4) == '_git' then
        TaskGoToCoordAnyMeans(ped, ev.x, ev.y, ev.z + 1.0, 1.0, 0, false, 786603, 0xbf800000)
    elseif anahtar == 'nobetci_dur' then
        SetEntityHeading(ped, n.h + 0.0)
        TaskGuardCurrentPosition(ped, 10.0, 10.0, true)
    elseif anahtar == 'sabit_dur' then
        SetEntityHeading(ped, n.h + 0.0)
        TaskStandStill(ped, -1)
    elseif anahtar == 'pasif_dur' then
        SetEntityHeading(ped, n.h + 0.0)
        TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_STAND_IMPATIENT', 0, true)
    elseif anahtar == 'devriye' then
        TaskWanderInArea(ped, ev.x, ev.y, ev.z, 25.0, 2.0, 5.0)
    elseif anahtar == 'saldirgan' then
        TaskWanderInArea(ped, ev.x, ev.y, ev.z, math.min(g.takipMesafesi, 60) + 0.0, 1.0, 3.0)
    end
end

-- Aracından indiyse (savaş bitti) tekrar binsin
local function araca_bin(ped, d, arac, konum)
    local simdi = GetGameTimer()
    if simdi < (d.binisYenile or 0) then return true end
    local m = #(konum - GetEntityCoords(arac))
    if m > 60.0 then return false end   -- araç çok uzakta kaldı: yaya devam
    if not d.ilkBinis and m < 10.0 then
        TaskWarpPedIntoVehicle(ped, arac, -1)   -- doğduğu an: anında bin
    else
        TaskEnterVehicle(ped, arac, 20000, -1, 2.0, 1, 0)
    end
    d.ilkBinis = true
    d.binisYenile = simdi + 8000
    d.bosta, d.rotaGorev = nil, nil
    return true
end

-- Düşmana saldır veya ona doğru git
local function saldir(ped, n, g, d, hedef, mesafe, arac, aractami)
    d.bosta, d.rotaGorev, d.beklemeBitis = nil, nil, nil
    local simdi = GetGameTimer()
    if mesafe <= g.saldiriMesafesi then
        TaskCombatPed(ped, hedef, 0, 16)
        return
    end
    if n.davranis == 'sabit' or g.hareket == 'sabit' then return end   -- yerinden kıpırdamaz
    if d.yaklasilan == hedef and simdi < (d.yaklasmaZamani or 0) then return end
    if aractami then
        TaskVehicleChase(ped, hedef)   -- araçla kovala
        d.yaklasmaZamani = simdi + 3000
    else
        local hiz = g.hareket == 'saldirgan' and 3.0 or 2.0
        TaskGoToEntity(ped, hedef, -1, g.saldiriMesafesi * 0.8, hiz, 1073741824, 0)
        d.yaklasmaZamani = simdi + 2000
    end
    d.yaklasilan = hedef
end

-- ================= Her NPC için bir düşünme adımı =================

local function dusun(ben, liste, tarama)
    local ped, n, g = ben.ped, ben.n, ben.g

    -- Bu NPC yeni doğduysa (farklı ped) eski bilgileri at
    local d = durumlar[ben.id]
    if not d or d.ped ~= ped then
        d = { ped = ped }
        durumlar[ben.id] = d
    end

    if n.olu then return end
    if olu(ped) then
        if not d.oldu then
            d.oldu = true
            TriggerServerEvent('endnpc:oldu', n.netId)
        end
        return
    end

    -- Ayarlar değiştiyse yeniden uygula
    if d.surum ~= Senk.surum then
        yapilandir(ped, n, g)
        d.surum = Senk.surum
        d.bosta, d.rotaGorev = nil, nil
        if d.rotaIdx and (not n.rota or d.rotaIdx > #n.rota) then d.rotaIdx = nil end
        if d.dusukCan then dusukCanUygula(ped, n, g) end
    end

    -- Can / zırh: sadece doğunca ve panelden değişince uygulanır (sahip değişince yeniden dolmasın)
    if Entity(ped).state.endnpcCan ~= n.canSurum and d.canSurum ~= n.canSurum then
        local maks = 100 + n.can   -- GTA'da NPC canı 100'ün altına inince ölür
        SetPedMaxHealth(ped, maks)
        SetEntityMaxHealth(ped, maks)
        SetEntityHealth(ped, maks)
        SetPedArmour(ped, n.zirh)
        d.canSurum = n.canSurum
        TriggerServerEvent('endnpc:canUygulandi', n.netId, n.canSurum)
    end

    local konum = GetEntityCoords(ped)
    local arac = aracGetir(n)
    local aractami = arac ~= nil and GetVehiclePedIsIn(ped, false) == arac

    -- "Ev": rotası varsa sıradaki rota noktası, yoksa doğduğu yer
    local rota = rotaGetir(n)
    local ev
    if rota then
        d.rotaIdx = d.rotaIdx or enYakinNokta(rota, konum)
        local p = rota[d.rotaIdx]
        ev = vector3(p.x, p.y, p.z)
    elseif n.davranis == 'hucum' and n.hedef then
        ev = vector3(n.hedef.x, n.hedef.y, n.hedef.z)   -- hücum edenin "evi" saldırdığı nokta
    else
        ev = vector3(n.ev.x, n.ev.y, n.ev.z)
    end
    local evMesafe = #(konum - ev)

    -- Polise ihbar: bu grup çatışınca (en fazla 30 saniyede bir; sunucu ayrıca bölgeye göre süzer)
    if g.ihbar and GetGameTimer() > (d.ihbarZamani or 0) and (IsPedInCombat(ped, 0) or IsPedShooting(ped)) then
        d.ihbarZamani = GetGameTimer() + 30000
        TriggerServerEvent('endnpc:catisma', n.netId)
    end

    -- Can eşiğin altına indi mi?
    if not d.dusukCan and g.dusukCanEsigi > 0 then
        local oran = (GetEntityHealth(ped) - 100) / math.max(1, n.can) * 100
        if oran <= g.dusukCanEsigi then
            d.dusukCan = true
            dusukCanUygula(ped, n, g)
        end
    end
    if d.dusukCan and g.dusukCanDavranisi == 'kac' then return end   -- kaçıyor, karışma

    if n.davranis == 'pasif' then
        if not IsPedInCombat(ped, 0) and not IsPedFleeing(ped) then
            bostaGorevi(ped, n, g, d, ev, evMesafe, arac, aractami)
        end
        return
    end

    -- Bölgesinde alarm var mı? (görüş mesafesinden bağımsız, bölgeye giren herkese saldırır)
    local alarmHedef, alarmMesafe, alarmSinir = bolgeAlarmi(ben, konum, d, tarama)

    -- Kovalama sınırı: evinden bu kadar uzaklaşırsa geri döner
    local sinir = g.takipMesafesi * (n.davranis == 'saldirgan' and 2 or 1)
    if aractami and (n.davranis == 'devriye' or n.davranis == 'saldirgan') then sinir = sinir * 4 end
    if rota then sinir = sinir + 30.0 end
    if n.davranis == 'hucum' then sinir = math.max(sinir * 3, 300.0) end   -- hücum edenler kolay geri dönmez
    if alarmSinir then sinir = math.max(sinir, alarmSinir) end

    -- Evine dönüyor mu?
    if d.donuyor then
        if evMesafe < (aractami and 15.0 or 4.0) or (alarmHedef and evMesafe < sinir * 0.8) then
            d.donuyor = false
            d.bosta, d.rotaGorev = nil, nil
            SetBlockingOfNonTemporaryEvents(ped, false)
        else
            return
        end
    end

    if n.davranis ~= 'sabit' and evMesafe > sinir then
        d.donuyor = true
        ClearPedTasks(ped)
        SetBlockingOfNonTemporaryEvents(ped, true)   -- dönerken ateşe karşılık verip tekrar kovalamasın
        if aractami then
            TaskVehicleDriveToCoordLongrange(ped, arac, ev.x, ev.y, ev.z, 20.0, SURUS_STILI, 10.0)
        else
            TaskGoToCoordAnyMeans(ped, ev.x, ev.y, ev.z + 1.0, 2.0, 0, false, 786603, 0xbf800000)
        end
        return
    end

    -- Zaten çatışıyorsa GTA'nın savaş yapay zekası idare ediyor
    if IsPedInCombat(ped, 0) then
        d.bosta, d.rotaGorev = nil, nil
        return
    end

    local hedef, mesafe = alarmHedef, alarmMesafe
    if not hedef then hedef, mesafe = dusmanBul(ben, liste, konum) end
    if hedef then
        saldir(ped, n, g, d, hedef, mesafe, arac, aractami)
        return
    end
    d.yaklasilan = nil

    -- Aracı var ama içinde değil: tekrar bin
    if arac and not aractami and not IsPedInAnyVehicle(ped, true) then
        if araca_bin(ped, d, arac, konum) then return end
    end

    if rota then
        rotaGorevi(ped, n, d, konum, arac, aractami)
    else
        bostaGorevi(ped, n, g, d, ev, evMesafe, arac, aractami)
    end
end

-- ================= Ana döngü =================

CreateThread(function()
    while true do
        local bekle = 2000
        if next(Senk.npcler) then
            bekle = Senk.ayarlar.aiAralik or 500
            local liste = YereldekiNpcler()
            local ben = PlayerId()
            local gorulen = {}
            local tarama
            for _, npc in ipairs(liste) do
                if NetworkGetEntityOwner(npc.ped) == ben then
                    tarama = tarama or bolgeleriTara(liste)   -- sadece sahibi olduğumuz NPC varsa tara
                    gorulen[npc.id] = true
                    dusun(npc, liste, tarama)
                end
            end
            -- sahibi olmadığımız veya artık olmayan NPC'lerin bilgilerini temizle
            -- (sahipliği geri alırsak ayarlar baştan uygulanır)
            for id in pairs(durumlar) do
                if not gorulen[id] then durumlar[id] = nil end
            end
        end
        Wait(bekle)
    end
end)
