-- [Huso] Endcore HUD – kare minimap'in konumu, boyutu ve çerçevesi.
--
-- Harita GTA'nın kendi minimap'i; burada sadece qbx_hud'un kare harita ayarları (SetMinimapComponentPosition)
-- oyuncunun seçtiği kaydırma / boyutla uygulanır. GPS rotası, yön, ikonlar aynen çalışır.
-- Çerçeve, haritanın ekrandaki yerine göre sayfada (NUI) çizilir; harita gizlenince, büyük harita
-- açılınca veya duraklatma menüsünde çerçeve de gizlenir.
--
-- Ayarlar oyuncunun bilgisayarında saklanır (KVP) ve HUD menüsünden (I) değiştirilir.

local sharedConfig = require 'config.shared'   -- main.lua ile aynı tablo (require önbelleği)

local VARSAYILAN = {
    x = -10,          -- yatay kaydırma (1080p'ye göre piksel). -10: ekran kenarına biraz daha yakın
    y = 0,            -- dikey kaydırma (yukarı +). 0 = qbx_hud orijinal yeri (GTA zemini en düzgün burada)
    genislik = 100,   -- %
    yukseklik = 100,  -- %
    cerceve = true,   -- ince yuvarlak çerçeve
    -- Çerçeve ince ayarı (ekran pikseli): hesap ekranına tam oturmazsa oyuncu menüden düzeltir
    -- 33 / 14: 1920x1200 ekranda oyunda elle oturtulan değerler (herkes için varsayılan)
    ix = 33, iy = 14, iw = 0, ih = 0,
}

local ayar = {}
do
    local tamam, okunan = pcall(json.decode, GetResourceKvpString('endHarita') or '')
    if tamam and type(okunan) == 'table' then ayar = okunan end
    for k, v in pairs(VARSAYILAN) do
        if ayar[k] == nil then ayar[k] = v end
    end
    -- Eski denemelerden kalan kayıt (harita 50 px yukarıda): orijinal yere dön
    if (ayar.surum or 0) < 3 then
        ayar.x, ayar.y, ayar.surum = -10, 0, 3
        SetResourceKvp('endHarita', json.encode(ayar))
    end
    -- Çerçeve ince ayarı varsayılanı (oyunda elle oturtuldu). Kendi ince ayarını yapmış oyuncuya dokunma.
    if (ayar.surum or 0) < 4 then
        if ayar.ix == 0 and ayar.iy == 0 then ayar.ix, ayar.iy = 33, 14 end
        ayar.surum = 4
        SetResourceKvp('endHarita', json.encode(ayar))
    end
end

-- qbx_hud'un kare harita değerleri (client/main.lua, hud:client:LoadMap)
local KARE = {
    minimap = { 0.0, -0.047, 0.1638, 0.183 },
    maske   = { 0.0, 0.0, 0.128, 0.20 },
    bulanik = { -0.01, 0.025, 0.262, 0.300 },   -- haritanın koyu zemini; küçültülürse GTA zemini çizmiyor (harita saydam kalır)
}

local genisOfset = 0   -- ultra geniş ekranlar için qbx_hud'un hesapladığı kaydırma

-- Seçilen ayarlarla harita bileşenlerinin GTA değerleri
local function degerler()
    local sw, sh = ayar.genislik / 100, ayar.yukseklik / 100
    local dx, dy = ayar.x / 1920, ayar.y / 1080
    local m, k, b = KARE.minimap, KARE.maske, KARE.bulanik
    return {
        minimap = { m[1] * sw + genisOfset + dx, m[2] * sh - dy, m[3] * sw, m[4] * sh },
        maske   = { k[1] * sw + genisOfset + dx, k[2] * sh - dy, k[3] * sw, k[4] * sh },
        bulanik = { b[1] * sw + genisOfset + dx, b[2] * sh - dy, b[3] * sw, b[4] * sh },
    }
end

-- qbx_hud kare haritayı yüklerken bunu çağırır (main.lua'daki eski üç satırın yerine)
function EndHaritaKonumla(minimapOffset)
    genisOfset = minimapOffset or 0
    local d = degerler()
    SetMinimapComponentPosition('minimap', 'L', 'B', d.minimap[1], d.minimap[2], d.minimap[3], d.minimap[4])
    SetMinimapComponentPosition('minimap_mask', 'L', 'B', d.maske[1], d.maske[2], d.maske[3], d.maske[4])
    -- Haritanın koyu zemini: qbx_hud'un orijinal ölçüsü, haritayla birlikte kayar ve büyür.
    -- (Haritanın boyuna küçültünce GTA zemini hiç çizmedi, harita saydam göründü.)
    SetMinimapComponentPosition('minimap_blur', 'L', 'B', d.bulanik[1], d.bulanik[2], d.bulanik[3], d.bulanik[4])
end

-- Haritanın ekrandaki yeri (ekranın oranı olarak).
-- GTA yatay değerleri ekran genişliğine göre alır; ekran 16:9'dan genişse (ultra geniş) ortadaki 16:9 alana göre.
-- 1920x1200 ekranda ölçüldü: görünen harita yatayda "minimap" bileşeni kadar; dikeyde alt kenarı
-- "minimap_mask"ın altı, üst kenarı "minimap"ın tepesi (yükseklik = mask y - minimap y + minimap h).
local function dikdortgen()
    local W, H = GetActiveScreenResolution()
    local kenar = (1.0 - GetSafeZoneSize()) * 0.5
    local sanal = math.min(W, H * 16 / 9)
    local d = degerler()
    local m, k = d.minimap, d.maske
    local solPx = kenar * W + m[1] * sanal
    if W > sanal then solPx = (W - sanal) / 2 + kenar * sanal + m[1] * sanal end   -- ultra geniş
    return {
        sol = (solPx + ayar.ix) / W,
        alt = (kenar * H - k[2] * H + ayar.iy) / H,
        gen = (m[3] * sanal + ayar.iw) / W,
        yuk = ((k[2] - m[2] + m[4]) * H + ayar.ih) / H,
    }
end

local function kareMi()
    return sharedConfig.menu.isToggleMapShapeChecked == 'square'
end

local sonDurum
local function durumGonder(zorla)
    local goster = ayar.cerceve and kareMi() and LocalPlayer.state.isLoggedIn
        and not IsRadarHidden() and not IsBigmapActive() and not IsPauseMenuActive()
    local W, H = GetActiveScreenResolution()
    local anahtar = ('%s|%d|%d|%.4f'):format(tostring(goster), W, H, GetSafeZoneSize())
    if not zorla and anahtar == sonDurum then return end
    sonDurum = anahtar
    SendNUIMessage({ action = 'endHarita', goster = goster == true, kutu = dikdortgen(), ayar = ayar })
end

-- Harita göründü / gizlendi / büyük harita açıldı mı? (çeyrek saniyede bir, sadece değişince mesaj gider)
CreateThread(function()
    while true do
        durumGonder(false)
        Wait(250)
    end
end)

-- Menüden gelen ayar
RegisterNUICallback('endHaritaAyar', function(veri, cb)
    local function sinir(d, a, b, v) d = tonumber(d) or v; return math.max(a, math.min(b, d)) end
    ayar.x = math.floor(sinir(veri.x, -400, 1200, -10))
    ayar.y = math.floor(sinir(veri.y, -100, 700, 0))
    ayar.genislik = math.floor(sinir(veri.genislik, 60, 200, 100))
    ayar.yukseklik = math.floor(sinir(veri.yukseklik, 60, 200, 100))
    ayar.cerceve = veri.cerceve ~= false
    ayar.ix = math.floor(sinir(veri.ix, -100, 100, 33))
    ayar.iy = math.floor(sinir(veri.iy, -100, 100, 14))
    ayar.iw = math.floor(sinir(veri.iw, -150, 150, 0))
    ayar.ih = math.floor(sinir(veri.ih, -150, 150, 0))
    SetResourceKvp('endHarita', json.encode(ayar))
    EndHaritaUygula()   -- GTA haritayı yeni yerine ancak büyük harita açılıp kapanınca çizer
    durumGonder(true)
    cb(true)
end)

-- Haritayı seçilen yere koy ve GTA'nın yeniden çizmesini sağla.
-- qbx_hud bunu sadece oyuna girişte (ve kayıtlı HUD ayarı varsa script yeniden başlayınca) yapıyor;
-- script yeniden başlatıldığında harita eski yerinde kalıp çerçeveyle kayıyordu.
function EndHaritaUygula() -- (global: menü geri çağrısı dosyada daha yukarıda)
    if not kareMi() then return end
    local W, H = GetActiveScreenResolution()
    local oran = W / H
    local varsayilanOran = 1920 / 1080
    local ofset = 0
    if oran > varsayilanOran then ofset = ((varsayilanOran - oran) / 3.6) - 0.008 end   -- qbx_hud ile aynı hesap
    SetMinimapClipType(0)
    EndHaritaKonumla(ofset)
    SetBlipAlpha(GetNorthRadarBlip(), 0)   -- haritanın kenarındaki "N" işareti (qbx_hud da gizler)
    SetBigmapActive(true, false)
    Wait(50)
    SetBigmapActive(false, false)
    durumGonder(true)
end

CreateThread(function()
    while not LocalPlayer.state.isLoggedIn do Wait(1000) end
    Wait(4500)   -- qbx_hud'un kendi harita yüklemesi bitsin
    EndHaritaUygula()
end)

-- Sayfa açılınca mevcut ayarları ve çerçeveyi iste
RegisterNUICallback('endHaritaIste', function(_, cb)
    durumGonder(true)
    cb(true)
end)
