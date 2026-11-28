-- server/npc.lua
-- NPC'leri haritada oluşturur (sunucu tarafında, OneSync ile herkes aynı NPC'yi görür),
-- ölümlerini takip eder ve oyunculara güncel listeyi gönderir.
--
-- Yapay zekayı sunucu değil, NPC'nin "sahibi" olan oyuncunun oyunu çalıştırır
-- (FiveM'de bir NPC'yi ona en yakın oyuncu yönetir). Bkz. client/ai.lua

Canli = {}     -- [npcId] = { ent, netId, durum = 'doguyor' | 'canli' | 'olu', olumZamani, canSurum, jeton }
Bekleyen = {}  -- [npcId] = yeniden doğacağı zaman (os.time)
Hatalar = {}   -- [npcId] = son doğma hatası (panelde gösterilir)

local senkSurum = 0
local canSayaci = 0

-- Haritada olan (doğuyor / canlı / ceset) NPC sayısı. Limit buna göre kontrol edilir.
function AktifSayisi()
    local sayi = 0
    for _ in pairs(Canli) do sayi = sayi + 1 end
    return sayi
end

-- ================= Oyunculara senkron =================

local function senkPaketi()
    local npcler = {}
    for id, c in pairs(Canli) do
        local n = Veri.npcler[id]
        if n and c.netId then
            npcler[id] = {
                netId = c.netId,
                ad = n.ad,
                grup = n.grup,
                davranis = n.davranis,
                ofke = n.ofke,          -- nil ise oyuncu tarafı grubun öfkesini kullanır
                silah = n.silah,
                can = n.can,
                zirh = n.zirh,
                canSurum = c.canSurum,
                ev = { x = n.x, y = n.y, z = n.z },
                h = n.h,
                olu = c.durum == 'olu',
                aracNetId = c.aracNetId,
                rota = n.rota,
                rotaTur = n.rotaTur,
                rotaBekleme = n.rotaBekleme,
                hedef = n.hedef,
            }
        end
    end
    local bolgeler = {}
    for id, b in pairs(Veri.bolgeler) do
        if b.aktif then bolgeler[id] = b end
    end
    return {
        surum = senkSurum,
        gruplar = Veri.gruplar,
        iliskiler = Veri.iliskiler,
        bolgeler = bolgeler,
        ayarlar = { aiAralik = Veri.ayarlar.aiAralik, koruma = Veri.ayarlar.koruma },
        etkinlik = EtkinlikSenkBilgisi and EtkinlikSenkBilgisi() or nil,
        npcler = npcler,
    }
end

-- Arka arkaya çok değişiklik olursa tek paket gitsin diye kısa bekler.
local senkBekliyor = false
function SenkGonder(hedef)
    if hedef then
        TriggerClientEvent('endnpc:senk', hedef, senkPaketi())
        return
    end
    if senkBekliyor then return end
    senkBekliyor = true
    SetTimeout(150, function()
        senkBekliyor = false
        senkSurum = senkSurum + 1
        TriggerClientEvent('endnpc:senk', -1, senkPaketi())
    end)
end

RegisterNetEvent('endnpc:senkIste', function()
    SenkGonder(source)
end)

-- ================= Doğurma / kaldırma =================

function SilahVer(ent, silah)
    RemoveAllPedWeapons(ent, true)
    if silah ~= 'WEAPON_UNARMED' then
        GiveWeaponToPed(ent, GetHashKey(silah), 9999, false, true)
    end
end

-- Can / zırh değişince oyuncu tarafı yeniden uygulasın diye sürüm numarası artar
function CanGuncelle(id)
    local c = Canli[id]
    if not c then return end
    canSayaci = canSayaci + 1
    c.canSurum = canSayaci
end

local function varlikSil(ent)
    if ent and DoesEntityExist(ent) then DeleteEntity(ent) end
end

function Kaldir(id)
    local c = Canli[id]
    if c then
        varlikSil(c.ent)
        varlikSil(c.arac)
    end
    Canli[id] = nil
    SenkGonder()
end

local function bekleVarOlsun(ent)
    local bitis = GetGameTimer() + 5000
    while not DoesEntityExist(ent) and GetGameTimer() < bitis do Wait(50) end
    return DoesEntityExist(ent)
end

function Dogur(id)
    local n = Veri.npcler[id]
    if not n or not n.aktif then return end

    Kaldir(id)
    Bekleyen[id] = nil
    Hatalar[id] = nil

    if AktifSayisi() >= Veri.ayarlar.maxNpc then
        Hatalar[id] = 'NPC limiti dolu'
        return
    end

    -- jeton: bu doğma işlemi sürerken NPC silinir / tekrar doğurulursa eski işlemi iptal etmek için
    local jeton = {}
    canSayaci = canSayaci + 1
    Canli[id] = { durum = 'doguyor', jeton = jeton, canSurum = canSayaci }

    CreateThread(function()
        -- Araçlı NPC: önce aracı oluştur
        local arac
        if n.arac then
            arac = CreateVehicleServerSetter(GetHashKey(n.arac), n.aracTur or 'automobile', n.x + 0.0, n.y + 0.0, n.z + 0.6, n.h + 0.0)
            if not bekleVarOlsun(arac) then arac = nil end
        end

        -- z + 1.0: kayıtlı konum ayak hizası, NPC'nin merkezi bir metre yukarıda
        local ent = CreatePed(4, GetHashKey(n.model), n.x + 0.0, n.y + 0.0, n.z + 1.0, n.h + 0.0, true, true)
        bekleVarOlsun(ent)

        local c = Canli[id]
        if not c or c.jeton ~= jeton then
            varlikSil(ent)   -- bu arada iptal edildi
            varlikSil(arac)
            return
        end
        if not DoesEntityExist(ent) then
            varlikSil(arac)
            Canli[id] = nil
            Hatalar[id] = 'NPC oluşturulamadı (model geçersiz olabilir)'
            return
        end

        -- Kimse yakında değilken de silinmesin
        if SetEntityOrphanMode then SetEntityOrphanMode(ent, 2) end
        SetPedArmour(ent, n.zirh)
        SilahVer(ent, n.silah)
        Entity(ent).state:set('endnpc', id, true)

        if arac then
            if SetEntityOrphanMode then SetEntityOrphanMode(arac, 2) end
            SetVehicleDoorsLocked(arac, 2)          -- oyuncular NPC'nin aracını çalamasın
            SetPedIntoVehicle(ent, arac, -1)        -- -1 = şoför koltuğu
            Entity(arac).state:set('endnpcArac', id, true)
            c.arac = arac
            c.aracNetId = NetworkGetNetworkIdFromEntity(arac)
        elseif n.arac then
            Hatalar[id] = 'Araç oluşturulamadı, NPC yaya doğdu'
        end

        c.ent = ent
        c.netId = NetworkGetNetworkIdFromEntity(ent)
        c.durum = 'canli'
        SenkGonder()
    end)
end

local function netIddenBul(netId)
    netId = tonumber(netId)
    if not netId then return end
    for id, c in pairs(Canli) do
        if c.netId == netId then return id, c end
    end
end

-- Olayı gönderen oyuncu bu NPC'nin sahibi mi? (Başkası sahte bildirim yapamasın)
local function sahibiMi(kaynak, c)
    return c.ent and DoesEntityExist(c.ent) and NetworkGetEntityOwner(c.ent) == kaynak
end

-- ================= Ölüm =================

local function olduIsaretle(id)
    local c = Canli[id]
    if not c or c.durum ~= 'canli' then return end
    c.durum = 'olu'
    c.olumZamani = os.time()
    if GanimetHazirla then GanimetHazirla(id, c) end
    if EtkinlikNpcOldu then EtkinlikNpcOldu(id) end
    SenkGonder()
end

-- NPC'yi yöneten oyuncunun oyunu "öldü" der
RegisterNetEvent('endnpc:oldu', function(netId)
    local id, c = netIddenBul(netId)
    if id and sahibiMi(source, c) then olduIsaretle(id) end
end)

-- NPC'yi yöneten oyuncu canı / zırhı uyguladı: tekrar uygulanmasın diye işaretle
RegisterNetEvent('endnpc:canUygulandi', function(netId, surum)
    local id, c = netIddenBul(netId)
    if id and sahibiMi(source, c) and c.canSurum == surum then
        Entity(c.ent).state:set('endnpcCan', surum, true)
    end
end)

-- Saniyede bir: cesetleri kaldır, kaybolanları ve süresi gelenleri yeniden doğur
CreateThread(function()
    while true do
        Wait(1000)
        local simdi = os.time()
        local ayar = Veri.ayarlar

        for id, c in pairs(Canli) do
            if c.durum == 'canli' and not DoesEntityExist(c.ent) then
                -- Oyun bir sebeple NPC'yi sildi: 3 saniye sonra yeniden oluştur
                Canli[id] = nil
                Bekleyen[id] = simdi + 3
                SenkGonder()
            elseif c.durum == 'olu' and simdi - c.olumZamani >= ayar.cesetSuresi then
                varlikSil(c.ent)
                varlikSil(c.arac)
                Canli[id] = nil
                local n = Veri.npcler[id]
                if n then
                    if n.gecici or ayar.olumDavranisi == 'sil' then   -- etkinlik NPC'si hep silinir
                        Veri.npcler[id] = nil
                    elseif ayar.olumDavranisi == 'yenidenDog' then
                        Bekleyen[id] = simdi + ayar.yenidenDogmaSuresi
                    else
                        n.aktif = false
                    end
                    Kaydet()
                end
                SenkGonder()
            end
        end

        for id, zaman in pairs(Bekleyen) do
            if simdi >= zaman then
                Bekleyen[id] = nil
                local n = Veri.npcler[id]
                if n and n.aktif then Dogur(id) end
            end
        end
    end
end)

-- ================= Açılış / kapanış =================

CreateThread(function()
    Wait(1500)
    for id, n in pairs(Veri.npcler) do
        if n.aktif then Dogur(id) end
    end
end)

AddEventHandler('onResourceStop', function(kaynak)
    if kaynak ~= GetCurrentResourceName() then return end
    for _, c in pairs(Canli) do
        varlikSil(c.ent)
        varlikSil(c.arac)
    end
    HemenKaydet()
end)
