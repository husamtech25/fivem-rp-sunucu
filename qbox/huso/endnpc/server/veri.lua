-- server/veri.lua
-- Tüm kalıcı bilgiler (ayarlar, gruplar, ilişkiler, NPC'ler) data.json dosyasında durur.
-- Sunucu yeniden açılınca buradan okunur. Diğer sunucu dosyaları "Veri" tablosunu kullanır.

local KAYNAK = GetCurrentResourceName()
local DOSYA = 'data.json'

Veri = {
    ayarlar = {},
    gruplar = {},   -- [grupId] = { id, ad, renk, ... }
    iliskiler = {}, -- ['g1|g2'] = 'dost' | 'dusman'  (yazmayanlar tarafsız sayılır)
    npcler = {},    -- [npcId] = { id, ad, grup, model, x, y, z, h, ... }
    sablonlar = {}, -- [sablonId] = { id, ad, aciklama, uyeler = { { model, silah, ..., dx, dy, dz, dh } } }
    bolgeler = {},  -- [bolgeId] = { id, ad, grup, x, y, z, yaricap, oyuncuAlarm, alarmSuresi, aktif }
    sonId = 0,
}

-- ================= Yardımcılar =================

-- hedef tablosunda eksik olan alanları varsayılandan doldurur
local function eksikleriDoldur(hedef, varsayilan)
    for k, v in pairs(varsayilan) do
        if hedef[k] == nil then hedef[k] = v end
    end
    return hedef
end

function Kopyala(t)
    local yeni = {}
    for k, v in pairs(t) do yeni[k] = v end
    return yeni
end

function YeniId(onek)
    Veri.sonId = Veri.sonId + 1
    return onek .. Veri.sonId
end

-- İki grubun ilişki anahtarı: sıralı olsun ki 'g1|g2' ile 'g2|g1' aynı olsun
function IliskiAnahtari(a, b)
    if a > b then a, b = b, a end
    return a .. '|' .. b
end

function IliskiGetir(a, b)
    if a == b then return 'dost' end
    return Veri.iliskiler[IliskiAnahtari(a, b)] or 'tarafsiz'
end

-- Sayıyı Ayar.Sinirlar'daki aralığa sıkıştırır. Sayı değilse varsayılanı döner.
function Sayi(deger, alan, varsayilan)
    deger = tonumber(deger)
    if not deger or deger ~= deger then return varsayilan end -- deger ~= deger: NaN kontrolü
    local s = Ayar.Sinirlar[alan]
    if s then deger = math.max(s[1], math.min(s[2], deger)) end
    return deger
end

-- Değer listede varsa onu, yoksa varsayılanı döner
function Secenek(deger, liste, varsayilan)
    for _, v in ipairs(liste) do
        if v == deger then return deger end
    end
    return varsayilan
end

-- Yazıyı temizler (kontrol karakterleri ve < > atılır) ve en fazla "uzunluk" harfe kısaltır
function Metin(deger, uzunluk, varsayilan)
    if type(deger) ~= 'string' then return varsayilan end
    deger = (deger:gsub('[%c<>]', ''))
    deger = (deger:gsub('^%s+', ''):gsub('%s+$', ''))
    if deger == '' then return varsayilan end
    local kes = utf8.offset(deger, uzunluk + 1)  -- Türkçe harfler 2 bayt; harf sayısına göre kes
    if kes then deger = deger:sub(1, kes - 1) end
    return deger
end

local silahlar = {}
for _, s in ipairs(Ayar.Silahlar) do silahlar[s.ad] = true end
function SilahGecerli(ad) return type(ad) == 'string' and silahlar[ad] == true end

local renkler = {}
for _, r in ipairs(Ayar.Renkler) do renkler[r.hex] = true end
function RenkGecerli(hex) return type(hex) == 'string' and renkler[hex] == true end

-- ================= Kaydetme =================
-- Arka arkaya çok değişiklik olursa dosyaya bir kere yazsın diye 1 saniye bekler.

function HemenKaydet()
    SaveResourceFile(KAYNAK, DOSYA, json.encode(Veri, { indent = true }), -1)
end

local kayitBekliyor = false
function Kaydet()
    if kayitBekliyor then return end
    kayitBekliyor = true
    SetTimeout(1000, function()
        kayitBekliyor = false
        HemenKaydet()
    end)
end

-- ================= Yükleme =================

local function ornekGruplar()
    local a, b = YeniId('g'), YeniId('g')
    Veri.gruplar[a] = eksikleriDoldur({ id = a, ad = 'Güvenlik', renk = '#3466e0', hareket = 'savunmaci' }, Ayar.VarsayilanGrup)
    Veri.gruplar[b] = eksikleriDoldur({ id = b, ad = 'Çete', renk = '#e74c3c', ofke = 70 }, Ayar.VarsayilanGrup)
    Veri.iliskiler[IliskiAnahtari(a, b)] = 'dusman'
end

local function hazirSablonlar()
    for _, s in ipairs(Ayar.HazirSablonlar) do
        local id = YeniId('s')
        Veri.sablonlar[id] = { id = id, ad = s.ad, aciklama = s.aciklama, uyeler = s.uyeler }
    end
end

local function yukle()
    local yazi = LoadResourceFile(KAYNAK, DOSYA)
    local okunan
    if yazi then
        local tamam, sonuc = pcall(json.decode, yazi)
        if tamam then
            okunan = sonuc
        else
            -- bozuk dosyayı kaybetmemek için yedeğini al
            SaveResourceFile(KAYNAK, 'data.bozuk.json', yazi, -1)
            print('^1[endnpc] data.json bozuk; data.bozuk.json olarak yedeklendi, yenisi oluşturuluyor.^0')
        end
    end

    if type(okunan) == 'table' then
        Veri.ayarlar = type(okunan.ayarlar) == 'table' and okunan.ayarlar or {}
        Veri.gruplar = type(okunan.gruplar) == 'table' and okunan.gruplar or {}
        Veri.iliskiler = type(okunan.iliskiler) == 'table' and okunan.iliskiler or {}
        Veri.npcler = type(okunan.npcler) == 'table' and okunan.npcler or {}
        Veri.bolgeler = type(okunan.bolgeler) == 'table' and okunan.bolgeler or {}
        Veri.sonId = tonumber(okunan.sonId) or 0
        if type(okunan.sablonlar) == 'table' then
            Veri.sablonlar = okunan.sablonlar
        else
            hazirSablonlar()   -- eski kayıt dosyasında şablon yoktu
        end
    else
        ornekGruplar()   -- ilk açılış: deneme için iki düşman grup
        hazirSablonlar()
    end

    eksikleriDoldur(Veri.ayarlar, Ayar.VarsayilanAyarlar)
    for id, g in pairs(Veri.gruplar) do
        g.id = id
        eksikleriDoldur(g, Ayar.VarsayilanGrup)
    end
    for id, n in pairs(Veri.npcler) do
        n.id = id
        eksikleriDoldur(n, Ayar.VarsayilanNpc)
        if not Veri.gruplar[n.grup] then n.aktif = false end   -- grubu silinmişse kapalı kalsın
    end
    for id, s in pairs(Veri.sablonlar) do
        s.id = id
        s.uyeler = type(s.uyeler) == 'table' and s.uyeler or {}
    end
    for id, b in pairs(Veri.bolgeler) do
        b.id = id
        eksikleriDoldur(b, Ayar.VarsayilanBolge)
        if not Veri.gruplar[b.grup] then b.aktif = false end
    end

    HemenKaydet()
end

yukle()
