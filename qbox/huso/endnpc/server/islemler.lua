-- server/islemler.lua
-- Panelden gelen her istek buradan geçer. Her istekte yetki kontrol edilir;
-- gelen değerler doğrulanır (sınır dışı sayı, olmayan grup vb. kabul edilmez).

local Islemler = {}

local function yetkili(kaynak)
    return IsPlayerAceAllowed(kaynak, 'command.' .. Ayar.Komut)
end

local function limitMesaji()
    return ('NPC limiti dolu (%d). Ayarlar sekmesinden artırabilirsin.'):format(Veri.ayarlar.maxNpc)
end

local function grupSayisi()
    local sayi = 0
    for _ in pairs(Veri.gruplar) do sayi = sayi + 1 end
    return sayi
end

-- ================= NPC =================

-- Gelen veriyi kontrol edip temiz bir NPC kaydı hazırlar.
-- eski: düzenlenen NPC (yoksa varsayılanlar). Gönderilmeyen alanlar eskisinden kalır.
local function npcHazirla(veri, eski)
    local temel = eski or Ayar.VarsayilanNpc
    local n = { id = eski and eski.id }

    n.ad = Metin(veri.ad, 32, temel.ad)

    if veri.grup ~= nil then
        if type(veri.grup) ~= 'string' or not Veri.gruplar[veri.grup] then return nil, 'Geçerli bir grup seç.' end
        n.grup = veri.grup
    else
        n.grup = temel.grup
    end
    if not n.grup or not Veri.gruplar[n.grup] then return nil, 'Geçerli bir grup seç.' end

    if veri.model ~= nil then
        if type(veri.model) ~= 'string' then return nil, 'Model adı geçersiz.' end
        local model = veri.model:lower()
        if #model > 40 or not model:match('^[%w_]+$') then return nil, 'Model adı geçersiz.' end
        n.model = model
    else
        n.model = temel.model
    end

    if veri.silah ~= nil and not SilahGecerli(veri.silah) then return nil, 'Silah geçersiz.' end
    n.silah = veri.silah or temel.silah
    n.davranis = Secenek(veri.davranis, Ayar.Secenekler.davranis, temel.davranis)
    n.can = math.floor(Sayi(veri.can, 'can', temel.can))
    n.zirh = math.floor(Sayi(veri.zirh, 'zirh', temel.zirh))

    if veri.ofkeGrup then
        n.ofke = nil                                  -- grubun ayarını kullan
    elseif veri.ofke ~= nil then
        n.ofke = math.floor(Sayi(veri.ofke, 'ofke', 50))
    else
        n.ofke = eski and eski.ofke or nil
    end

    if veri.x ~= nil then
        local x, y, z, h = tonumber(veri.x), tonumber(veri.y), tonumber(veri.z), tonumber(veri.h)
        if not (x and y and z) or math.abs(x) > 20000 or math.abs(y) > 20000 or math.abs(z) > 3000 then
            return nil, 'Konum geçersiz.'
        end
        n.x, n.y, n.z, n.h = x, y, z, (h or 0.0) % 360
    elseif eski then
        n.x, n.y, n.z, n.h = eski.x, eski.y, eski.z, eski.h
    else
        return nil, 'Önce bir konum seç.'
    end

    if veri.aktif == nil then
        n.aktif = temel.aktif ~= false
    else
        n.aktif = veri.aktif == true
    end

    -- Araç: '' veya false = yaya
    if veri.arac ~= nil then
        if veri.arac == '' or veri.arac == false then
            n.arac, n.aracTur = nil, nil
        else
            if type(veri.arac) ~= 'string' then return nil, 'Araç modeli geçersiz.' end
            local arac = veri.arac:lower()
            if #arac > 40 or not arac:match('^[%w_]+$') then return nil, 'Araç modeli geçersiz.' end
            n.arac = arac
            n.aracTur = Secenek(veri.aracTur, Ayar.Secenekler.aracTur, 'automobile')
        end
    else
        n.arac, n.aracTur = temel.arac, temel.aracTur
    end

    -- Devriye rotası
    if veri.rota ~= nil then
        if type(veri.rota) ~= 'table' then return nil, 'Rota geçersiz.' end
        local rota = {}
        for i, p in ipairs(veri.rota) do
            if i > Ayar.RotaEnFazla then break end
            local x, y, z = tonumber(type(p) == 'table' and p.x), tonumber(type(p) == 'table' and p.y), tonumber(type(p) == 'table' and p.z)
            if not (x and y and z) then return nil, 'Rota noktası geçersiz.' end
            rota[#rota + 1] = { x = x, y = y, z = z }
        end
        n.rota = #rota > 0 and rota or nil
    else
        n.rota = temel.rota
    end
    n.rotaTur = Secenek(veri.rotaTur, Ayar.Secenekler.rotaTur, temel.rotaTur or 'dongu')
    n.rotaBekleme = math.floor(Sayi(veri.rotaBekleme, 'rotaBekleme', temel.rotaBekleme or 3))

    -- Hücum hedefi (etkinlikte saldırılacak nokta). Yoksa hücum NPC'si doğduğu yeri hedef alır.
    if type(veri.hedef) == 'table' and tonumber(veri.hedef.x) and tonumber(veri.hedef.y) and tonumber(veri.hedef.z) then
        n.hedef = { x = tonumber(veri.hedef.x), y = tonumber(veri.hedef.y), z = tonumber(veri.hedef.z) }
    else
        n.hedef = temel.hedef
    end
    n.gecici = temel.gecici   -- etkinlik NPC'si işareti (panelden değiştirilemez)

    return n
end

-- Hazırlanan kaydı kaydeder ve haritadaki NPC'yi buna göre günceller
local function npcUygula(n, eski)
    local id = n.id
    local c = id and Canli[id]

    -- Haritada değilse ve etkinse doğması gerekecek: önce limiti kontrol et
    local dogmaGerek = n.aktif and not c and not (id and Bekleyen[id])
    if dogmaGerek and AktifSayisi() >= Veri.ayarlar.maxNpc then
        return false, limitMesaji()
    end

    id = id or YeniId('n')
    n.id = id
    Veri.npcler[id] = n
    Kaydet()

    if not n.aktif then
        Bekleyen[id] = nil
        Kaldir(id)
        return true, id
    end

    local yeriDegisti = eski and (eski.model ~= n.model or eski.x ~= n.x or eski.y ~= n.y or eski.z ~= n.z or eski.h ~= n.h
        or eski.arac ~= n.arac)
    if dogmaGerek or (c and c.durum ~= 'olu' and yeriDegisti) then
        Dogur(id)
    elseif c and c.durum == 'canli' then
        if eski.silah ~= n.silah then SilahVer(c.ent, n.silah) end
        if eski.can ~= n.can or eski.zirh ~= n.zirh then CanGuncelle(id) end
        SenkGonder()
    end
    return true, id
end

-- Etkinlik dosyası da kullanır
NpcHazirla, NpcUygula = npcHazirla, npcUygula

local function idListesi(veri)
    local liste = {}
    if type(veri.ids) == 'table' then
        for _, id in ipairs(veri.ids) do
            if type(id) == 'string' and Veri.npcler[id] then liste[#liste + 1] = id end
        end
    end
    return liste
end

function Islemler.npcKaydet(_, veri)
    local eski
    if veri.id ~= nil then
        eski = Veri.npcler[veri.id]
        if not eski then return false, 'NPC bulunamadı (silinmiş olabilir).' end
        eski = Kopyala(eski)
    end
    local n, hata = npcHazirla(veri, eski)
    if not n then return false, hata end
    return npcUygula(n, eski)
end

function Islemler.npcTopluDuzenle(_, veri)
    local alanlar = type(veri.alanlar) == 'table' and veri.alanlar or {}
    alanlar.id, alanlar.x, alanlar.y, alanlar.z, alanlar.h, alanlar.ad, alanlar.model = nil, nil, nil, nil, nil, nil, nil
    alanlar.rota = nil   -- rota her NPC'ye özel, toplu değişmez
    local tamam, hatalar, sonHata = 0, 0, nil
    for _, id in ipairs(idListesi(veri)) do
        local eski = Kopyala(Veri.npcler[id])
        local n, hata = npcHazirla(alanlar, eski)
        local ok, mesaj = false, hata
        if n then ok, mesaj = npcUygula(n, eski) end
        if ok then tamam = tamam + 1 else hatalar = hatalar + 1; sonHata = mesaj end
    end
    if hatalar > 0 then
        return false, ('%d NPC güncellendi, %d NPC güncellenemedi: %s'):format(tamam, hatalar, sonHata)
    end
    return true, tamam
end

function Islemler.npcSil(_, veri)
    local ids = idListesi(veri)
    for _, id in ipairs(ids) do
        Bekleyen[id] = nil
        Kaldir(id)
        Veri.npcler[id] = nil
    end
    Kaydet()
    return true, #ids
end

function Islemler.npcYenidenDogur(_, veri)
    local ids = idListesi(veri)
    local dogan = 0
    for _, id in ipairs(ids) do
        local n = Veri.npcler[id]
        local zatenVar = Canli[id] ~= nil
        if zatenVar or AktifSayisi() < Veri.ayarlar.maxNpc then
            n.aktif = true
            Dogur(id)
            dogan = dogan + 1
        end
    end
    Kaydet()
    if dogan < #ids then
        return false, ('%d NPC doğdu. %s'):format(dogan, limitMesaji())
    end
    return true, dogan
end

function Islemler.hepsiniYenidenDogur()
    local ids = {}
    for id, n in pairs(Veri.npcler) do
        if n.aktif then ids[#ids + 1] = id end
    end
    return Islemler.npcYenidenDogur(nil, { ids = ids })
end

function Islemler.konumGetir(_, veri)
    local n = Veri.npcler[veri.id]
    if not n then return false, 'NPC bulunamadı.' end
    local c = Canli[veri.id]
    if c and c.ent and DoesEntityExist(c.ent) then
        local k = GetEntityCoords(c.ent)
        return true, { x = k.x, y = k.y, z = k.z }
    end
    return true, { x = n.x, y = n.y, z = n.z + 1.0 }
end

-- ================= Gruplar =================

local SAYI_ALANLARI = { 'gorusMesafesi', 'saldiriMesafesi', 'ofke', 'saldiriSikligi', 'isabet', 'takipMesafesi', 'dusukCanEsigi',
    'ganimetParaMin', 'ganimetParaMax' }

local function evetHayir(deger, varsayilan)
    if deger == nil then return varsayilan == true end
    return deger == true
end

-- Ganimet eşya listesi: sadece envanterde gerçekten olan eşyalar kabul edilir
local function ganimetListesi(liste)
    local sonuc = {}
    if type(liste) ~= 'table' then return sonuc end
    for _, e in ipairs(liste) do
        if #sonuc >= 15 then break end
        local ad = type(e) == 'table' and type(e.item) == 'string' and e.item:lower() or nil
        if ad and ad:match('^[%w_]+$') and exports.ox_inventory:Items(ad) then
            local en = math.floor(Sayi(e.min, 'ganimetAdet', 1))
            local ec = math.floor(Sayi(e.max, 'ganimetAdet', en))
            sonuc[#sonuc + 1] = {
                item = ad,
                min = math.min(en, ec),
                max = math.max(en, ec),
                sans = math.floor(Sayi(e.sans, 'ganimetSans', 100)),
            }
        end
    end
    return sonuc
end

local function grupHazirla(veri, eski)
    local temel = eski or Ayar.VarsayilanGrup
    local g = { id = eski and eski.id }
    g.ad = Metin(veri.ad, 24, temel.ad)
    g.renk = RenkGecerli(veri.renk) and veri.renk or temel.renk
    g.oyuncuIliskisi = Secenek(veri.oyuncuIliskisi, Ayar.Secenekler.iliski, temel.oyuncuIliskisi)
    g.hareket = Secenek(veri.hareket, Ayar.Secenekler.hareket, temel.hareket)
    g.dusukCanDavranisi = Secenek(veri.dusukCanDavranisi, Ayar.Secenekler.dusukCanDavranisi, temel.dusukCanDavranisi)
    for _, alan in ipairs(SAYI_ALANLARI) do
        g[alan] = math.floor(Sayi(veri[alan], alan, temel[alan] or 0))
    end
    if g.ganimetParaMin > g.ganimetParaMax then g.ganimetParaMin, g.ganimetParaMax = g.ganimetParaMax, g.ganimetParaMin end
    g.ihbar = evetHayir(veri.ihbar, temel.ihbar)
    g.ganimetSilah = evetHayir(veri.ganimetSilah, temel.ganimetSilah)
    if veri.ganimetEsyalar ~= nil then
        g.ganimetEsyalar = ganimetListesi(veri.ganimetEsyalar)
    else
        g.ganimetEsyalar = temel.ganimetEsyalar or {}
    end
    return g
end

function Islemler.grupKaydet(_, veri)
    local eski
    if veri.id ~= nil then
        eski = Veri.gruplar[veri.id]
        if not eski then return false, 'Grup bulunamadı.' end
    end
    local g = grupHazirla(veri, eski)
    g.id = g.id or YeniId('g')
    Veri.gruplar[g.id] = g
    Kaydet()
    SenkGonder()
    return true, g.id
end

function Islemler.grupTopluDuzenle(_, veri)
    local alanlar = type(veri.alanlar) == 'table' and veri.alanlar or {}
    alanlar.ad, alanlar.renk = nil, nil   -- isim ve renk toplu değişmez
    local sayi = 0
    if type(veri.ids) == 'table' then
        for _, id in ipairs(veri.ids) do
            local eski = type(id) == 'string' and Veri.gruplar[id]
            if eski then
                Veri.gruplar[id] = grupHazirla(alanlar, eski)
                Veri.gruplar[id].id = id
                sayi = sayi + 1
            end
        end
    end
    Kaydet()
    SenkGonder()
    return true, sayi
end

function Islemler.grupSil(_, veri)
    local id = veri.id
    if type(id) ~= 'string' or not Veri.gruplar[id] then return false, 'Grup bulunamadı.' end

    local tasi = veri.npcIslem == 'tasi'
    if tasi and (veri.hedef == id or not Veri.gruplar[veri.hedef]) then
        return false, 'NPC\'lerin taşınacağı grubu seç.'
    end

    for npcId, n in pairs(Veri.npcler) do
        if n.grup == id then
            if tasi then
                n.grup = veri.hedef
            else
                Bekleyen[npcId] = nil
                Kaldir(npcId)
                Veri.npcler[npcId] = nil
            end
        end
    end

    -- bu grubun koruduğu bölgeler: taşınıyorsa yeni gruba geçer, yoksa silinir
    for bolgeId, b in pairs(Veri.bolgeler) do
        if b.grup == id then
            if tasi then b.grup = veri.hedef else Veri.bolgeler[bolgeId] = nil end
        end
    end

    -- bu grubun ilişkilerini de temizle
    for anahtar in pairs(Veri.iliskiler) do
        local a, b = anahtar:match('^(.-)|(.+)$')
        if a == id or b == id then Veri.iliskiler[anahtar] = nil end
    end

    Veri.gruplar[id] = nil
    Kaydet()
    SenkGonder()
    return true
end

function Islemler.iliskiAyarla(_, veri)
    local a, b = veri.a, veri.b
    if type(a) ~= 'string' or type(b) ~= 'string' or a == b or not Veri.gruplar[a] or not Veri.gruplar[b] then
        return false, 'Grup geçersiz.'
    end
    local deger = Secenek(veri.deger, Ayar.Secenekler.iliski, nil)
    if not deger then return false, 'İlişki geçersiz.' end
    Veri.iliskiler[IliskiAnahtari(a, b)] = deger ~= 'tarafsiz' and deger or nil
    Kaydet()
    SenkGonder()
    return true
end

-- ================= Şablonlar =================
-- Şablon üyelerinin konumu ilk üyeye göre "sağa (dx) / ileri (dy)" metre olarak saklanır.
-- Böylece şablon hangi yöne bakılarak yerleştirilirse ekip de o yöne dönük kurulur.

local UYE_ALANLARI = { 'ad', 'model', 'silah', 'davranis', 'can', 'zirh', 'ofke', 'arac', 'aracTur' }

local function yuvarla(s) return math.floor(s * 100 + 0.5) / 100 end

function Islemler.sablonOlustur(_, veri)
    local ids = idListesi(veri)
    if #ids == 0 then return false, 'Önce NPC seç.' end
    if #ids > 30 then return false, 'Bir şablonda en fazla 30 NPC olabilir.' end

    local ilk = Veri.npcler[ids[1]]
    local aci = math.rad(ilk.h)
    local cosA, sinA = math.cos(aci), math.sin(aci)
    local uyeler = {}
    for _, id in ipairs(ids) do
        local n = Veri.npcler[id]
        local uye = {}
        for _, alan in ipairs(UYE_ALANLARI) do uye[alan] = n[alan] end
        local wx, wy = n.x - ilk.x, n.y - ilk.y
        uye.dx = yuvarla(wx * cosA + wy * sinA)   -- sağa
        uye.dy = yuvarla(-wx * sinA + wy * cosA)  -- ileri
        uye.dz = yuvarla(n.z - ilk.z)
        uye.dh = yuvarla((n.h - ilk.h) % 360)
        if uye.davranis == 'rota' then uye.davranis = 'devriye' end   -- rota noktaları şablona taşınmaz
        uyeler[#uyeler + 1] = uye
    end

    local id = YeniId('s')
    Veri.sablonlar[id] = {
        id = id,
        ad = Metin(veri.ad, 32, 'Yeni şablon'),
        aciklama = Metin(veri.aciklama, 80, #uyeler .. ' NPC'),
        uyeler = uyeler,
    }
    Kaydet()
    return true, id
end

function Islemler.sablonDuzenle(_, veri)
    local s = Veri.sablonlar[veri.id]
    if not s then return false, 'Şablon bulunamadı.' end
    s.ad = Metin(veri.ad, 32, s.ad)
    s.aciklama = Metin(veri.aciklama, 80, s.aciklama)
    Kaydet()
    return true
end

function Islemler.sablonSil(_, veri)
    if not Veri.sablonlar[veri.id] then return false, 'Şablon bulunamadı.' end
    Veri.sablonlar[veri.id] = nil
    Kaydet()
    return true
end

function Islemler.sablonYerlestir(_, veri)
    local s = Veri.sablonlar[veri.id]
    if not s then return false, 'Şablon bulunamadı.' end
    if type(veri.grup) ~= 'string' or not Veri.gruplar[veri.grup] then return false, 'Bir grup seç.' end
    local x, y, z, h = tonumber(veri.x), tonumber(veri.y), tonumber(veri.z), tonumber(veri.h) or 0.0
    if not (x and y and z) then return false, 'Önce bir konum seç.' end
    if AktifSayisi() + #s.uyeler > Veri.ayarlar.maxNpc then
        return false, ('Bu şablon %d NPC; limit yetmiyor (%d / %d dolu).'):format(#s.uyeler, AktifSayisi(), Veri.ayarlar.maxNpc)
    end

    local aci = math.rad(h)
    local cosA, sinA = math.cos(aci), math.sin(aci)
    local onEk = Metin(veri.onEk, 16, nil)
    local olusan = 0
    for _, u in ipairs(s.uyeler) do
        local dx, dy = tonumber(u.dx) or 0, tonumber(u.dy) or 0
        local kayit = {}
        for _, alan in ipairs(UYE_ALANLARI) do kayit[alan] = u[alan] end
        kayit.ad = onEk and (onEk .. ' ' .. (u.ad or 'NPC')) or u.ad
        kayit.ofkeGrup = u.ofke == nil
        kayit.grup = veri.grup
        kayit.aktif = true
        kayit.x = x + dx * cosA - dy * sinA
        kayit.y = y + dx * sinA + dy * cosA
        kayit.z = z + (tonumber(u.dz) or 0)
        kayit.h = h + (tonumber(u.dh) or 0)
        local n = npcHazirla(kayit, nil)
        if n and npcUygula(n, nil) then olusan = olusan + 1 end
    end
    return true, olusan
end

-- ================= Bölgeler =================

local function bolgeHazirla(veri, eski)
    local temel = eski or Ayar.VarsayilanBolge
    local b = { id = eski and eski.id }
    b.ad = Metin(veri.ad, 24, temel.ad)
    local grupId = veri.grup ~= nil and veri.grup or temel.grup
    if type(grupId) ~= 'string' or not Veri.gruplar[grupId] then return nil, 'Bölgeyi koruyacak grubu seç.' end
    b.grup = grupId
    b.yaricap = math.floor(Sayi(veri.yaricap, 'yaricap', temel.yaricap))
    b.alarmSuresi = math.floor(Sayi(veri.alarmSuresi, 'alarmSuresi', temel.alarmSuresi))
    if veri.oyuncuAlarm == nil then b.oyuncuAlarm = temel.oyuncuAlarm == true else b.oyuncuAlarm = veri.oyuncuAlarm == true end
    if veri.aktif == nil then b.aktif = temel.aktif ~= false else b.aktif = veri.aktif == true end
    if veri.x ~= nil then
        local x, y, z = tonumber(veri.x), tonumber(veri.y), tonumber(veri.z)
        if not (x and y and z) then return nil, 'Konum geçersiz.' end
        b.x, b.y, b.z = x, y, z
    elseif eski then
        b.x, b.y, b.z = eski.x, eski.y, eski.z
    else
        return nil, 'Bölgenin merkezini seç.'
    end
    return b
end

function Islemler.bolgeKaydet(_, veri)
    local eski
    if veri.id ~= nil then
        eski = Veri.bolgeler[veri.id]
        if not eski then return false, 'Bölge bulunamadı.' end
    end
    local b, hata = bolgeHazirla(veri, eski)
    if not b then return false, hata end
    b.id = b.id or YeniId('b')
    Veri.bolgeler[b.id] = b
    Kaydet()
    SenkGonder()
    return true, b.id
end

function Islemler.bolgeSil(_, veri)
    if not Veri.bolgeler[veri.id] then return false, 'Bölge bulunamadı.' end
    Veri.bolgeler[veri.id] = nil
    Kaydet()
    SenkGonder()
    return true
end

-- ================= Genel ayarlar =================

function Islemler.ayarKaydet(_, veri)
    local a = Veri.ayarlar
    a.maxNpc = math.floor(Sayi(veri.maxNpc, 'maxNpc', a.maxNpc))
    a.aiAralik = math.floor(Sayi(veri.aiAralik, 'aiAralik', a.aiAralik))
    a.cesetSuresi = math.floor(Sayi(veri.cesetSuresi, 'cesetSuresi', a.cesetSuresi))
    a.yenidenDogmaSuresi = math.floor(Sayi(veri.yenidenDogmaSuresi, 'yenidenDogmaSuresi', a.yenidenDogmaSuresi))
    a.olumDavranisi = Secenek(veri.olumDavranisi, Ayar.Secenekler.olumDavranisi, a.olumDavranisi)
    Kaydet()
    SenkGonder()
    return true
end

-- ================= Kiralık koruma ayarları =================

function Islemler.korumaKaydet(_, veri)
    local k = Veri.ayarlar.koruma
    k.fiyat = math.floor(Sayi(veri.fiyat, 'fiyat', k.fiyat))
    k.sure = math.floor(Sayi(veri.sure, 'sure', k.sure))
    k.enFazla = math.floor(Sayi(veri.enFazla, 'enFazla', k.enFazla))
    k.can = math.floor(Sayi(veri.can, 'can', k.can))
    k.zirh = math.floor(Sayi(veri.zirh, 'zirh', k.zirh))
    if SilahGecerli(veri.silah) then k.silah = veri.silah end
    if type(veri.model) == 'string' and veri.model:match('^[%w_]+$') and #veri.model <= 40 then k.model = veri.model:lower() end
    if veri.x ~= nil then
        local x, y, z = tonumber(veri.x), tonumber(veri.y), tonumber(veri.z)
        if not (x and y and z) then return false, 'Ajans konumu geçersiz.' end
        k.ajans = { x = x, y = y, z = z, h = (tonumber(veri.h) or 0.0) % 360 }
    end
    k.aktif = veri.aktif == true
    if k.aktif and not k.ajans then
        k.aktif = false
        return false, 'Önce ajansın konumunu seç.'
    end
    Kaydet()
    SenkGonder()
    return true
end

-- ================= Dalga etkinlikleri =================

local ETKINLIK_SAYILARI = { 'dalgaSayisi', 'ilkDalga', 'artis', 'dalgaArasi', 'sureDk' }

function Islemler.etkinlikKaydet(_, veri)
    local eski
    if veri.id ~= nil then
        eski = Veri.etkinlikler[veri.id]
        if not eski then return false, 'Etkinlik bulunamadı.' end
        if EtkinlikAktifMi(veri.id) then return false, 'Etkinlik sürerken düzenlenemez, önce durdur.' end
    end
    local temel = eski or Ayar.VarsayilanEtkinlik
    local e = { id = eski and eski.id }
    e.ad = Metin(veri.ad, 32, temel.ad)
    local grupId = veri.grup ~= nil and veri.grup or temel.grup
    if type(grupId) ~= 'string' or not Veri.gruplar[grupId] then return false, 'Saldıracak grubu seç.' end
    e.grup = grupId
    local sablon = veri.sablon ~= nil and veri.sablon or temel.sablon
    if type(sablon) ~= 'string' or not Veri.sablonlar[sablon] then return false, 'Düşmanların şablonunu seç.' end
    e.sablon = sablon
    for _, alan in ipairs(ETKINLIK_SAYILARI) do
        e[alan] = math.floor(Sayi(veri[alan], alan, temel[alan]))
    end
    e.duyuru = evetHayir(veri.duyuru, temel.duyuru)

    if veri.x ~= nil then
        local x, y, z = tonumber(veri.x), tonumber(veri.y), tonumber(veri.z)
        if not (x and y and z) then return false, 'Merkez konumu geçersiz.' end
        e.x, e.y, e.z = x, y, z
    elseif eski then
        e.x, e.y, e.z = eski.x, eski.y, eski.z
    else
        return false, 'Savunulacak merkezi seç.'
    end

    local dogma = {}
    local kaynak = veri.dogma ~= nil and veri.dogma or (eski and eski.dogma) or {}
    if type(kaynak) == 'table' then
        for i, p in ipairs(kaynak) do
            if i > Ayar.RotaEnFazla then break end
            local x, y, z = tonumber(type(p) == 'table' and p.x), tonumber(type(p) == 'table' and p.y), tonumber(type(p) == 'table' and p.z)
            if x and y and z then dogma[#dogma + 1] = { x = x, y = y, z = z } end
        end
    end
    if #dogma == 0 then return false, 'Düşmanların doğacağı en az bir nokta ekle.' end
    e.dogma = dogma

    e.id = e.id or YeniId('e')
    Veri.etkinlikler[e.id] = e
    Kaydet()
    return true, e.id
end

function Islemler.etkinlikSil(_, veri)
    if not Veri.etkinlikler[veri.id] then return false, 'Etkinlik bulunamadı.' end
    if EtkinlikAktifMi(veri.id) then return false, 'Etkinlik sürerken silinemez, önce durdur.' end
    Veri.etkinlikler[veri.id] = nil
    Kaydet()
    return true
end

function Islemler.etkinlikBaslat(_, veri)
    return EtkinlikBaslat(veri.id)
end

function Islemler.etkinlikDurdur()
    return EtkinlikBitir('durduruldu')
end

-- ================= Panel verisi =================

local function durumBilgisi(id, n)
    local c = Canli[id]
    local simdi = os.time()
    if c then
        if c.durum == 'canli' and c.ent and DoesEntityExist(c.ent) then
            local saglik = GetEntityHealth(c.ent)
            local k = GetEntityCoords(c.ent)
            return {
                durum = 'canli',
                -- kimse yakında değilse sunucu canı bilemez (0 döner)
                can = saglik > 0 and math.max(0, saglik - 100) or nil,
                konum = { x = k.x, y = k.y, z = k.z },
            }
        elseif c.durum == 'olu' then
            return { durum = 'olu', kalan = math.max(0, Veri.ayarlar.cesetSuresi - (simdi - c.olumZamani)) }
        end
        return { durum = 'doguyor' }
    end
    if Bekleyen[id] then return { durum = 'bekliyor', kalan = math.max(0, Bekleyen[id] - simdi) } end
    if not n.aktif then return { durum = 'kapali' } end
    return { durum = 'hata', mesaj = Hatalar[id] or 'Haritada değil' }
end

function Islemler.getir()
    local npcler = {}
    for id, n in pairs(Veri.npcler) do
        local k = Kopyala(n)
        k.durumBilgi = durumBilgisi(id, n)
        npcler[id] = k
    end
    return true, {
        ayarlar = Veri.ayarlar,
        gruplar = Veri.gruplar,
        iliskiler = Veri.iliskiler,
        npcler = npcler,
        sablonlar = Veri.sablonlar,
        bolgeler = Veri.bolgeler,
        etkinlikler = Veri.etkinlikler,
        aktifEtkinlik = EtkinlikDurumu(),
        koruma = Veri.ayarlar.koruma,
        kiralananKoruma = KorumaSayisi(),
        aktif = AktifSayisi(),
        grupSayisi = grupSayisi(),
    }
end

-- ================= Bağlantılar =================

lib.callback.register('endnpc:islem', function(kaynak, tip, veri)
    if not yetkili(kaynak) then return { ok = false, mesaj = 'Bu paneli kullanma yetkin yok.' } end
    local islem = type(tip) == 'string' and Islemler[tip]
    if not islem then return { ok = false, mesaj = 'Bilinmeyen işlem.' } end

    local calisti, ok, sonuc = pcall(islem, kaynak, type(veri) == 'table' and veri or {})
    if not calisti then
        print(('^1[endnpc] "%s" işleminde hata: %s^0'):format(tip, ok))
        return { ok = false, mesaj = 'Sunucu hatası oluştu, sunucu konsoluna bak.' }
    end
    if ok == false then return { ok = false, mesaj = sonuc } end
    return { ok = true, veri = sonuc }
end)

lib.addCommand(Ayar.Komut, {
    help = 'NPC yönetim panelini açar',
    restricted = Ayar.Yetki,
}, function(kaynak)
    TriggerClientEvent('endnpc:paneliAc', kaynak)
end)
