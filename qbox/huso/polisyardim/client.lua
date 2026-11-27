-- client.lua
-- 1) Polis noktalarının (mesai, garaj, helikopter, parmak izi, çekilmiş araçlar) yerine
--    mavi bir daire çizer. Sadece polisler görür.
-- 2) Sunucudan gelen NPC memurları oluşturur. Polisler NPC'ye Sol Alt ile bakıp
--    "Göreve başla / bitir" diyebilir.

-- ================= NOKTALARI qbx_police'in kendi ayarından oku =================
-- Koordinatları elle kopyalamak yerine qbx_police'in ayar dosyasını okuyoruz.
-- Böylece biri o ayarı değiştirirse işaretler de kendiliğinden yer değiştirir.
local noktalar = {}

local function noktalariYukle()
    local yazi = LoadResourceFile('qbx_police', 'config/shared.lua')
    local tamam, ayar = pcall(function() return load(yazi)() end)
    if not tamam or type(ayar) ~= 'table' then
        print('^1[polisyardim] qbx_police ayarı okunamadı, işaretler gösterilmeyecek.^0')
        return
    end

    -- Hangi grup, hangi renk ve ne yazsın
    local gruplar = {
        { anahtar = 'duty',        renk = { 66, 135, 245 }, yazi = 'Mesai' },
        { anahtar = 'vehicle',     renk = { 66, 200, 120 }, yazi = 'Garaj' },
        { anahtar = 'helicopter',  renk = { 245, 200, 66 }, yazi = 'Helikopter' },
        { anahtar = 'impound',     renk = { 245, 130, 66 }, yazi = 'Çekilmiş araçlar' },
        { anahtar = 'fingerprint', renk = { 180, 100, 245 }, yazi = 'Parmak izi' },
    }

    for _, grup in ipairs(gruplar) do
        for _, k in ipairs(ayar.locations[grup.anahtar] or {}) do
            noktalar[#noktalar + 1] = { konum = vector3(k.x, k.y, k.z), renk = grup.renk, yazi = grup.yazi }
        end
    end
end

-- Polis miyim? qbx_core'dan oyuncu bilgisini alıyoruz.
local function polisMiyim()
    local veri = exports.qbx_core:GetPlayerData()
    return veri and veri.job and veri.job.type == 'leo'
end

-- 3D dünyada yazı göstermek için yardımcı fonksiyon
local function dunyayaYaz(konum, yazi)
    local gorunuyor, x, y = World3dToScreen2d(konum.x, konum.y, konum.z)
    if not gorunuyor then return end
    SetTextScale(0.0, 0.45)
    SetTextFont(4)
    SetTextOutline()
    SetTextCentre(true)
    SetTextColour(255, 255, 255, 230)
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(yazi)
    EndTextCommandDisplayText(x, y)
end

CreateThread(function()
    noktalariYukle()

    while true do
        local bekle = 1000   -- yakında işaret yoksa saniyede bir kontrol et
        if polisMiyim() then
            local benim = GetEntityCoords(PlayerPedId())
            for _, n in ipairs(noktalar) do
                local mesafe = #(benim - n.konum)
                if mesafe < 25.0 then
                    bekle = 0   -- yakında işaret var: her karede çiz
                    -- DrawMarker(tip 1 = silindir, konum, yön, dönüş, boyut, renk, ...)
                    DrawMarker(1, n.konum.x, n.konum.y, n.konum.z - 0.98,
                        0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                        1.6, 1.6, 0.35,
                        n.renk[1], n.renk[2], n.renk[3], 120,
                        false, false, 2, false, nil, nil, false)
                    if mesafe < 8.0 then
                        dunyayaYaz(n.konum + vector3(0.0, 0.0, 0.4), n.yazi)
                    end
                end
            end
        end
        Wait(bekle)
    end
end)


-- ================= NPC MEMURLAR =================
local MODEL = `s_m_y_cop_01`   -- GTA'nın polis memuru modeli
local olusanlar = {}           -- şu an oyunda duran NPC'ler

local function npcleriTemizle()
    for _, ped in ipairs(olusanlar) do
        exports.ox_target:removeLocalEntity(ped)
        DeleteEntity(ped)
    end
    olusanlar = {}
end

local function goreveBaslaBitir()
    TriggerServerEvent('QBCore:ToggleDuty')
    TriggerServerEvent('police:server:UpdateCurrentCops')
end

-- Her NPC türü: hangi model, ne yapıyor (senaryo), bakınca ne açılıyor, kimler görebilir.
--   grup = 'police' -> sadece polisler seçeneği görür; nil -> herkes görür
-- Yeni tür eklemek istersen buraya bir blok, server.lua'daki TURLER listesine de adını ekle.
local TURLER = {
    -- ---- Polis ----
    mesai = {
        model = MODEL, senaryo = 'WORLD_HUMAN_COP_IDLES', grup = 'police',
        label = 'Göreve başla / bitir', icon = 'fa-solid fa-clipboard-user',
        onSelect = goreveBaslaBitir,
    },
    cephanelik = {
        model = MODEL, senaryo = 'WORLD_HUMAN_COP_IDLES', grup = 'police',
        label = 'Cephaneliği aç', icon = 'fa-solid fa-gun',
        -- ox_inventory'deki "PoliceArmoury" dükkanını açar (1 = MRPD'deki ilk konum)
        onSelect = function() exports.ox_inventory:openInventory('shop', { type = 'PoliceArmoury', id = 1 }) end,
    },
    dolap = {
        model = MODEL, senaryo = 'WORLD_HUMAN_COP_IDLES', grup = 'police',
        label = 'Kişisel dolabı aç', icon = 'fa-solid fa-box-archive',
        onSelect = function() exports.ox_inventory:openInventory('stash', 'policelocker') end,
    },
    giyim = {
        model = MODEL, senaryo = 'WORLD_HUMAN_CLIPBOARD', grup = 'police',
        label = 'Kıyafet menüsü (polis)', icon = 'fa-solid fa-shirt',
        -- Kıyafet scriptinin tam menüsünü açar: kıyafet değiştir, kombin kaydet / giy
        onSelect = function() TriggerEvent('illenium-appearance:client:openClothingShopMenu') end,
    },
    sus = { model = MODEL, senaryo = 'WORLD_HUMAN_COP_IDLES' },   -- sadece görüntü

    -- ---- Mağazalar (herkes kullanabilir) ----
    -- illenium-appearance'ın kendi olaylarını tetikliyoruz
    kiyafet = {
        model = `s_f_m_shop_high`, senaryo = 'WORLD_HUMAN_STAND_IMPATIENT',
        label = 'Kıyafet mağazası', icon = 'fa-solid fa-shirt',
        onSelect = function() TriggerEvent('illenium-appearance:client:openClothingShopMenu') end,
    },
    berber = {
        model = `s_m_m_hairdress_01`, senaryo = 'WORLD_HUMAN_STAND_IMPATIENT',
        label = 'Berber', icon = 'fa-solid fa-scissors',
        onSelect = function() TriggerEvent('illenium-appearance:client:OpenBarberShop') end,
    },
    dovme = {
        model = `u_m_y_tattoo_01`, senaryo = 'WORLD_HUMAN_STAND_IMPATIENT',
        label = 'Dövme salonu', icon = 'fa-solid fa-pen-nib',
        onSelect = function() TriggerEvent('illenium-appearance:client:OpenTattooShop') end,
    },
    estetik = {
        model = `s_m_m_doctor_01`, senaryo = 'WORLD_HUMAN_STAND_IMPATIENT',
        label = 'Estetik cerrah', icon = 'fa-solid fa-user-doctor',
        onSelect = function() TriggerEvent('illenium-appearance:client:OpenSurgeonShop') end,
    },
}

local function npcleriOlustur(liste)
    npcleriTemizle()

    for _, npc in ipairs(liste) do
        -- Eski NPC'lerde tür yoktu; onlar "mesai" sayılır.
        local turAdi = npc.tur or 'mesai'
        local tur = TURLER[turAdi] or TURLER.sus

        lib.requestModel(tur.model)
        -- false, false: sadece bu oyuncunun ekranında (yerel) oluştur; herkes kendi kopyasını görür
        local ped = CreatePed(4, tur.model, npc.x, npc.y, npc.z, npc.yon, false, false)
        FreezeEntityPosition(ped, true)             -- yerinden oynamasın
        SetEntityInvincible(ped, true)              -- ölmesin
        SetBlockingOfNonTemporaryEvents(ped, true)  -- silah sesinde kaçmasın
        TaskStartScenarioInPlace(ped, tur.senaryo, 0, true)
        SetModelAsNoLongerNeeded(tur.model)

        -- Sol Alt ile bakınca çıkacak seçenek
        if tur.onSelect then
            exports.ox_target:addLocalEntity(ped, {
                {
                    name = 'polisyardim_' .. turAdi,
                    label = tur.label,
                    icon = tur.icon,
                    groups = tur.grup,
                    distance = 2.5,
                    onSelect = tur.onSelect,
                },
            })
        end

        olusanlar[#olusanlar + 1] = ped
    end
end

RegisterNetEvent('polisyardim:npcler', npcleriOlustur)

CreateThread(function()
    TriggerServerEvent('polisyardim:iste')
end)

-- Script durdurulursa NPC'leri temizle (yoksa havada asılı kalırlar)
AddEventHandler('onResourceStop', function(script)
    if script == GetCurrentResourceName() then npcleriTemizle() end
end)
