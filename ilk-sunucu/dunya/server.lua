-- server.lua: Hava ve saat SUNUCUDA tutulur, herkese aynısı gönderilir.
-- Böylece sen gece yapınca arkadaşlarında da gece olur.
--
-- Admin komutları:
--   /hava yagmur       -> havayı değiştirir
--   /saat 18 30        -> saati 18:30 yapar
--   /gece, /gunduz     -> hızlıca 23:00 / 12:00
--   /saatdondur        -> saati durdurur / tekrar akıtır

-- Dünyanın şu anki durumu
local durum = {
    hava = 'EXTRASUNNY',
    saat = 12,
    dakika = 0,
    donuk = false,   -- true ise saat ilerlemez
}

-- Türkçe isim -> GTA'daki hava adı
local HAVALAR = {
    gunesli = 'EXTRASUNNY',
    acik    = 'CLEAR',
    bulutlu = 'CLOUDS',
    kapali  = 'OVERCAST',
    yagmur  = 'RAIN',
    firtina = 'THUNDER',
    sis     = 'FOGGY',
    kar     = 'XMAS',
    tipi    = 'BLIZZARD',
    cadilar = 'HALLOWEEN',
}

-- Durumu herkese gönder. -1 = "bütün oyuncular" demek.
local function herkeseGonder()
    TriggerClientEvent('dunya:durum', -1, durum)
end

-- Herkesin sohbetine duyuru yaz
local function duyur(yazi)
    TriggerClientEvent('chat:addMessage', -1, { args = { '^1[Admin]', yazi } })
end

-- Sadece komutu yazana cevap ver. source 0 ise komut sunucu konsolundan yazılmıştır.
local function cevap(oyuncuId, yazi)
    if oyuncuId == 0 then
        print(yazi)
    else
        TriggerClientEvent('chat:addMessage', oyuncuId, { args = { '^1[Admin]', yazi } })
    end
end

-- Saati ayarlayan ortak fonksiyon
local function saatAyarla(saat, dakika)
    durum.saat = saat
    durum.dakika = dakika
    herkeseGonder()
    duyur(('Saat %02d:%02d yapıldı.'):format(saat, dakika))
end


-- RegisterCommand'ın sonundaki "true": KISITLI komut.
-- Sadece izni olanlar kullanabilir. server.cfg'de "group.admin" grubuna
-- tüm komutların izni verildi ve sen o gruptasın. Yani bu komutları sadece adminler kullanır.

RegisterCommand('hava', function(source, args)
    local secim = args[1] and args[1]:lower()
    local tur = HAVALAR[secim]
    if not tur then
        local isimler = {}
        for isim in pairs(HAVALAR) do isimler[#isimler + 1] = isim end
        table.sort(isimler)
        cevap(source, 'Kullanım: /hava ' .. table.concat(isimler, ' | '))
        return
    end
    durum.hava = tur
    herkeseGonder()
    duyur('Hava değişiyor: ' .. secim)
end, true)

RegisterCommand('saat', function(source, args)
    local saat = tonumber(args[1])
    local dakika = tonumber(args[2]) or 0
    if not saat or saat < 0 or saat > 23 or dakika < 0 or dakika > 59 then
        cevap(source, 'Kullanım: /saat 0-23 [dakika]   örnek: /saat 18 30')
        return
    end
    saatAyarla(math.floor(saat), math.floor(dakika))
end, true)

RegisterCommand('gece', function() saatAyarla(23, 0) end, true)
RegisterCommand('gunduz', function() saatAyarla(12, 0) end, true)

RegisterCommand('saatdondur', function()
    durum.donuk = not durum.donuk   -- "not": true'yu false, false'u true yapar
    herkeseGonder()
    duyur(durum.donuk and 'Saat donduruldu.' or 'Saat tekrar akıyor.')
end, true)


-- Yeni giren oyuncu mevcut durumu ister
RegisterNetEvent('dunya:iste', function()
    TriggerClientEvent('dunya:durum', source, durum)
end)

-- Saati ilerlet: GTA'da normalde 1 oyun dakikası = 2 gerçek saniye
CreateThread(function()
    while true do
        Wait(2000)
        if not durum.donuk then
            durum.dakika = durum.dakika + 1
            if durum.dakika >= 60 then
                durum.dakika = 0
                durum.saat = (durum.saat + 1) % 24   -- %: 24 olunca 0'a döner
            end
        end
        herkeseGonder()
    end
end)
