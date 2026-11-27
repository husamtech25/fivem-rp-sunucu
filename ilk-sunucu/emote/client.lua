-- client.lua: Emote sistemi
--   /e dans     -> "dans" emote'unu yapar
--   /e          -> tüm emote kodlarını listeler
--   F3          -> emote menüsü
--   X           -> emote'u durdurur

-- ================= EMOTE LİSTESİ =================
-- İki tür emote var:
--   1) Animasyon: dict (animasyon paketi) + anim (paketteki hareket) + flag (nasıl oynatılacağı)
--   2) Senaryo:   GTA'nın hazır sahneleri. Eşyaları (sigara, kahve, gitar...) oyun kendisi verir.
--
-- flag değerleri (toplanarak kullanılır):
--   1  = döngü (sen durdurana kadar devam eder)
--   16 = sadece üst gövde (bacaklar serbest)
--   32 = hareket edebilirsin (yürürken yapılabilir)
--   Örnek: 49 = 1 + 16 + 32 -> döngü, üst gövde, yürüyebilirsin
--
-- Yeni emote eklemek istersen bu listeye bir satır eklemen yeterli.

local EMOTELAR = {
    -- Hareketler
    { kod = 'selam',    ad = 'El salla',            kategori = 'Hareket', dict = 'friends@frj@ig_1', anim = 'wave_a', flag = 48 },
    { kod = 'eller',    ad = 'Eller yukarı',        kategori = 'Hareket', dict = 'random@mugging3', anim = 'handsup_standing_base', flag = 49 },
    { kod = 'kollar',   ad = 'Kollar bağlı',        kategori = 'Hareket', dict = 'amb@world_human_hang_out_street@female_arms_crossed@base', anim = 'base', flag = 49 },
    { kod = 'asker',    ad = 'Asker selamı',        kategori = 'Hareket', dict = 'anim@mp_player_intincarsalutestd@ds@', anim = 'idle_a', flag = 49 },
    { kod = 'super',    ad = 'Başparmak yukarı',    kategori = 'Hareket', dict = 'anim@mp_player_intincarthumbs_upstd@ds@', anim = 'idle_a', flag = 48 },
    { kod = 'goster',   ad = 'Parmakla göster',     kategori = 'Hareket', dict = 'gestures@f@standing@casual', anim = 'gesture_point', flag = 48 },
    { kod = 'omuz',     ad = 'Omuz silk',           kategori = 'Hareket', dict = 'gestures@f@standing@casual', anim = 'gesture_shrug_hard', flag = 48 },
    { kod = 'hayir',    ad = 'Asla!',               kategori = 'Hareket', dict = 'gestures@m@standing@casual', anim = 'gesture_no_way', flag = 48 },
    { kod = 'gel',      ad = 'Buraya gel',          kategori = 'Hareket', dict = 'gestures@m@standing@casual', anim = 'gesture_come_here_soft', flag = 48 },
    { kod = 'facepalm', ad = 'Facepalm',            kategori = 'Hareket', dict = 'anim@mp_player_intcelebrationmale@face_palm', anim = 'face_palm', flag = 48 },
    { kod = 'alkis',    ad = 'Yavaş alkış',         kategori = 'Hareket', dict = 'anim@mp_player_intcelebrationmale@slow_clap', anim = 'slow_clap', flag = 48 },
    { kod = 'opucuk',   ad = 'Öpücük at',           kategori = 'Hareket', dict = 'anim@mp_player_intcelebrationfemale@blow_kiss', anim = 'blow_kiss', flag = 48 },

    -- Dans
    { kod = 'dans',     ad = 'Dans 1',              kategori = 'Dans', dict = 'anim@amb@nightclub@dancers@podium_dancers@', anim = 'hi_dance_facedj_17_v2_male^5', flag = 1 },
    { kod = 'dans2',    ad = 'Dans 2',              kategori = 'Dans', dict = 'anim@amb@nightclub@mini@dance@dance_solo@male@var_b@', anim = 'high_center_down', flag = 1 },
    { kod = 'dans3',    ad = 'Dans 3',              kategori = 'Dans', dict = 'anim@amb@nightclub@mini@dance@dance_solo@male@var_a@', anim = 'high_center', flag = 1 },
    { kod = 'parti',    ad = 'Parti',               kategori = 'Dans', senaryo = 'WORLD_HUMAN_PARTYING' },
    { kod = 'tezahurat',ad = 'Tezahürat',           kategori = 'Dans', senaryo = 'WORLD_HUMAN_CHEERING' },

    -- Oturma / uzanma
    { kod = 'otur',     ad = 'Yere otur',           kategori = 'Oturma', dict = 'anim@heists@fleeca_bank@ig_7_jetski_owner', anim = 'owner_idle', flag = 1 },
    { kod = 'piknik',   ad = 'Piknik',              kategori = 'Oturma', senaryo = 'WORLD_HUMAN_PICNIC' },
    { kod = 'uzan',     ad = 'Sırtüstü uzan',       kategori = 'Oturma', senaryo = 'WORLD_HUMAN_SUNBATHE_BACK' },
    { kod = 'yasla',    ad = 'Duvara yaslan',       kategori = 'Oturma', senaryo = 'WORLD_HUMAN_LEANING' },
    { kod = 'sarhos',   ad = 'Sızmış',              kategori = 'Oturma', senaryo = 'WORLD_HUMAN_STUPOR' },
    { kod = 'evsiz',    ad = 'Çökmüş otur',         kategori = 'Oturma', senaryo = 'WORLD_HUMAN_BUM_SLUMPED' },

    -- Eşyalı (senaryolar)
    { kod = 'sigara',   ad = 'Sigara iç',           kategori = 'Eşyalı', senaryo = 'WORLD_HUMAN_SMOKING' },
    { kod = 'kahve',    ad = 'Kahve iç',            kategori = 'Eşyalı', senaryo = 'WORLD_HUMAN_AA_COFFEE' },
    { kod = 'ic',       ad = 'İçecek iç',           kategori = 'Eşyalı', senaryo = 'WORLD_HUMAN_DRINKING' },
    { kod = 'telefon',  ad = 'Telefona bak',        kategori = 'Eşyalı', senaryo = 'WORLD_HUMAN_STAND_MOBILE' },
    { kod = 'foto',     ad = 'Fotoğraf çek',        kategori = 'Eşyalı', senaryo = 'WORLD_HUMAN_PAPARAZZI' },
    { kod = 'durbun',   ad = 'Dürbün',              kategori = 'Eşyalı', senaryo = 'WORLD_HUMAN_BINOCULARS' },
    { kod = 'harita',   ad = 'Harita oku',          kategori = 'Eşyalı', senaryo = 'WORLD_HUMAN_TOURIST_MAP' },
    { kod = 'not',      ad = 'Not al (pano)',       kategori = 'Eşyalı', senaryo = 'WORLD_HUMAN_CLIPBOARD' },
    { kod = 'gitar',    ad = 'Gitar çal',           kategori = 'Eşyalı', senaryo = 'WORLD_HUMAN_MUSICIAN' },
    { kod = 'cekic',    ad = 'Çekiç vur',           kategori = 'Eşyalı', senaryo = 'WORLD_HUMAN_HAMMERING' },
    { kod = 'kaynak',   ad = 'Kaynak yap',          kategori = 'Eşyalı', senaryo = 'WORLD_HUMAN_WELDING' },
    { kod = 'bahce',    ad = 'Bahçe işi',           kategori = 'Eşyalı', senaryo = 'WORLD_HUMAN_GARDENER_PLANT' },

    -- Spor
    { kod = 'sinav',    ad = 'Şınav',               kategori = 'Spor', senaryo = 'WORLD_HUMAN_PUSH_UPS' },
    { kod = 'mekik',    ad = 'Mekik',               kategori = 'Spor', senaryo = 'WORLD_HUMAN_SIT_UPS' },
    { kod = 'yoga',     ad = 'Yoga',                kategori = 'Spor', senaryo = 'WORLD_HUMAN_YOGA' },
    { kod = 'kosu',     ad = 'Yerinde koş',         kategori = 'Spor', senaryo = 'WORLD_HUMAN_JOG_STANDING' },
    { kod = 'dambil',   ad = 'Dambıl çalış',        kategori = 'Spor', senaryo = 'WORLD_HUMAN_MUSCLE_FREE_WEIGHTS' },
    { kod = 'kas',      ad = 'Kas göster',          kategori = 'Spor', senaryo = 'WORLD_HUMAN_MUSCLE_FLEX' },

    -- Meslek / RP
    { kod = 'nobet',    ad = 'Nöbet tut',           kategori = 'RP', senaryo = 'WORLD_HUMAN_GUARD_STAND' },
    { kod = 'polis',    ad = 'Polis bekleyişi',     kategori = 'RP', senaryo = 'WORLD_HUMAN_COP_IDLES' },
    { kod = 'takil',    ad = 'Sokakta takıl',       kategori = 'RP', senaryo = 'WORLD_HUMAN_HANG_OUT_STREET' },
}

-- Koda göre hızlı bulmak için ikinci bir tablo: KODLA['dans'] -> dans emote'u
local KODLA = {}
for _, emote in ipairs(EMOTELAR) do
    KODLA[emote.kod] = emote
end

local function mesaj(yazi)
    TriggerEvent('chat:addMessage', { args = { '^6[Emote]', yazi } })
end

-- ================= OYNATMA / DURDURMA =================

local function emoteDurdur()
    -- ClearPedTasks: karakterin yaptığı işi bitirir. Senaryolarda eşyayı da bırakır.
    ClearPedTasks(PlayerPedId())
end

local function emoteOynat(kod)
    local emote = KODLA[kod]
    if not emote then
        mesaj('"' .. tostring(kod) .. '" diye bir emote yok. Liste için: /e')
        return
    end

    local karakter = PlayerPedId()
    if IsPedInAnyVehicle(karakter, false) then
        mesaj('Araçtayken emote yapamazsın.')
        return
    end

    ClearPedTasks(karakter)  -- önceki emote varsa bitir

    -- Senaryo ise tek satır yeter, oyun gerisini halleder
    if emote.senaryo then
        TaskStartScenarioInPlace(karakter, emote.senaryo, 0, true)
        return
    end

    -- Animasyon paketini yükle (en fazla 2 saniye bekle)
    RequestAnimDict(emote.dict)
    local bekle = 0
    while not HasAnimDictLoaded(emote.dict) and bekle < 200 do
        Wait(10)
        bekle = bekle + 1
    end
    if not HasAnimDictLoaded(emote.dict) then
        mesaj('Animasyon yüklenemedi: ' .. kod)
        return
    end

    -- TaskPlayAnim(karakter, paket, hareket, giriş hızı, çıkış hızı, süre(-1 = animasyon kadar), flag, ...)
    TaskPlayAnim(karakter, emote.dict, emote.anim, 3.0, 3.0, -1, emote.flag, 0, false, false, false)
    RemoveAnimDict(emote.dict)  -- paketi bellekte tutmaya gerek yok, animasyon zaten başladı
end

-- ================= KOMUTLAR =================

RegisterCommand('e', function(source, args)
    local kod = args[1] and args[1]:lower()

    if not kod then
        local kodlar = {}
        for _, emote in ipairs(EMOTELAR) do kodlar[#kodlar + 1] = emote.kod end
        mesaj('Emoteler: ' .. table.concat(kodlar, ', '))
        mesaj('Kullanım: /e dans  ·  Menü: F3  ·  Durdur: X')
        return
    end

    if kod == 'dur' or kod == 'iptal' then
        emoteDurdur()
        return
    end

    emoteOynat(kod)
end, false)

-- X tuşu ile durdur (GTA Ayarlar > Tuş Atamaları > FiveM'den değiştirilebilir)
RegisterCommand('emotedur', emoteDurdur, false)
RegisterKeyMapping('emotedur', 'Emote durdur', 'keyboard', 'X')

-- ================= MENÜ =================

local function menuKapat()
    SetNuiFocus(false, false)
    SendNUIMessage({ islem = 'kapat' })
end

RegisterCommand('emotemenu', function()
    SetNuiFocus(true, true)
    -- Listeyi menüye buradan gönderiyoruz; böylece emote listesi tek bir yerde (bu dosyada) duruyor
    SendNUIMessage({ islem = 'ac', emotelar = EMOTELAR })
end, false)
RegisterKeyMapping('emotemenu', 'Emote menüsünü aç', 'keyboard', 'F3')

RegisterNUICallback('oynat', function(veri, cevap)
    cevap('ok')
    menuKapat()
    CreateThread(function()
        emoteOynat(veri.kod)
    end)
end)

RegisterNUICallback('durdur', function(veri, cevap)
    cevap('ok')
    menuKapat()
    emoteDurdur()
end)

RegisterNUICallback('kapat', function(veri, cevap)
    cevap('ok')
    menuKapat()
end)

TriggerEvent('chat:addSuggestion', '/e', 'Emote yapar (liste için boş bırak)', {
    { name = 'kod', help = 'Örnek: dans, selam, otur, sigara, sinav · durdurmak için: dur' }
})
