-- server/etkinlik.lua
-- Dalga etkinliği: seçilen grup, seçilen şablondaki NPC tipleriyle dalga dalga gelir ve merkeze hücum eder.
-- Bir dalganın hepsi ölünce kısa bir aradan sonra sıradaki (daha kalabalık) dalga gelir.
-- Bütün dalgalar temizlenince oyuncular kazanır; süre dolarsa etkinlik biter.
-- Aynı anda tek etkinlik çalışır. Etkinlik NPC'leri dosyaya kaydedilmez ("gecici").

local Aktif   -- { id, e (tanım), dalga, canlilar = { [npcId] = true }, oldurulen, baslangic, sonrakiDalga }

function EtkinlikAktifMi(id)
    return Aktif ~= nil and (id == nil or Aktif.id == id)
end

local function duyur(baslik, mesaj, tur)
    if Aktif and not Aktif.e.duyuru then return end
    TriggerClientEvent('endnpc:duyuru', -1, baslik, mesaj, tur or 'inform')
end

local function canliSayisi()
    local sayi = 0
    if Aktif then for _ in pairs(Aktif.canlilar) do sayi = sayi + 1 end end
    return sayi
end

-- Panel için özet
function EtkinlikDurumu()
    if not Aktif then return nil end
    local e = Aktif.e
    return {
        id = Aktif.id,
        dalga = Aktif.dalga,
        dalgaSayisi = e.dalgaSayisi,
        kalanDusman = canliSayisi(),
        oldurulen = Aktif.oldurulen,
        kalanSure = math.max(0, e.sureDk * 60 - (os.time() - Aktif.baslangic)),
        sonrakiDalga = Aktif.sonrakiDalga and math.max(0, Aktif.sonrakiDalga - os.time()) or nil,
    }
end

-- Oyuncuların haritasında etkinlik işareti için
function EtkinlikSenkBilgisi()
    if not Aktif then return nil end
    return { ad = Aktif.e.ad, x = Aktif.e.x, y = Aktif.e.y, z = Aktif.e.z, dalga = Aktif.dalga, dalgaSayisi = Aktif.e.dalgaSayisi }
end

function EtkinlikNpcOldu(npcId)
    if Aktif and Aktif.canlilar[npcId] then
        Aktif.canlilar[npcId] = nil
        Aktif.oldurulen = Aktif.oldurulen + 1
    end
end

local function geciciNpcleriTemizle()
    for id, n in pairs(Veri.npcler) do
        if n.gecici then
            Bekleyen[id] = nil
            Kaldir(id)
            Veri.npcler[id] = nil
        end
    end
end

function EtkinlikBitir(sebep)
    if not Aktif then return false, 'Şu an süren bir etkinlik yok.' end
    local e = Aktif.e
    if sebep == 'kazanildi' then
        duyur(e.ad, ('Bütün dalgalar püskürtüldü! %d düşman etkisiz hale getirildi.'):format(Aktif.oldurulen), 'success')
    elseif sebep == 'sure' then
        duyur(e.ad, 'Süre doldu, etkinlik sona erdi.', 'error')
    else
        duyur(e.ad, 'Etkinlik yönetici tarafından durduruldu.', 'inform')
    end
    Aktif = nil
    geciciNpcleriTemizle()
    SenkGonder()
    return true
end

local function dalgaGonder()
    local e = Aktif.e
    local sablon = Veri.sablonlar[e.sablon]
    if not sablon or #sablon.uyeler == 0 or not Veri.gruplar[e.grup] then
        EtkinlikBitir('durduruldu')
        return
    end

    Aktif.dalga = Aktif.dalga + 1
    Aktif.sonrakiDalga = nil
    local istenen = e.ilkDalga + (Aktif.dalga - 1) * e.artis
    local yer = Veri.ayarlar.maxNpc - AktifSayisi()
    local adet = math.min(istenen, yer)
    if adet <= 0 then
        duyur(e.ad, 'NPC limiti dolu, dalga gönderilemedi.', 'error')
        EtkinlikBitir('durduruldu')
        return
    end

    -- Bu dalga hangi doğma noktasından gelecek (sırayla)
    local nokta = e.dogma[(Aktif.dalga - 1) % #e.dogma + 1]
    local hedef = { x = e.x, y = e.y, z = e.z }
    local yon = math.deg(math.atan(-(e.x - nokta.x), e.y - nokta.y)) % 360   -- merkeze dönük

    for i = 1, adet do
        local u = sablon.uyeler[(i - 1) % #sablon.uyeler + 1]
        -- noktanın etrafına halka şeklinde dağıt (üst üste doğmasınlar)
        local aci = (i / adet) * math.pi * 2
        local uzaklik = i == 1 and 0 or 2.5 + (i % 3)
        local kayit = {
            ad = ('%s %d-%d'):format(u.ad or 'Düşman', Aktif.dalga, i),
            grup = e.grup,
            model = u.model,
            silah = u.silah,
            can = u.can,
            zirh = u.zirh,
            ofke = u.ofke,
            ofkeGrup = u.ofke == nil,
            arac = u.arac,
            aracTur = u.aracTur,
            davranis = 'hucum',
            hedef = hedef,
            aktif = true,
            x = nokta.x + math.cos(aci) * uzaklik,
            y = nokta.y + math.sin(aci) * uzaklik,
            z = nokta.z,
            h = yon,
        }
        local n = NpcHazirla(kayit, nil)
        if n then
            n.gecici = Aktif.id
            local ok, id = NpcUygula(n, nil)
            if ok then Aktif.canlilar[id] = true end
        end
    end

    duyur(e.ad, ('%d. dalga geliyor! (%d düşman)'):format(Aktif.dalga, canliSayisi()), 'warning')
    SenkGonder()
end

function EtkinlikBaslat(id)
    if Aktif then return false, 'Zaten süren bir etkinlik var. Önce onu durdur.' end
    local e = Veri.etkinlikler[id]
    if not e then return false, 'Etkinlik bulunamadı.' end
    if not Veri.gruplar[e.grup] then return false, 'Etkinliğin grubu silinmiş, etkinliği düzenle.' end
    local sablon = Veri.sablonlar[e.sablon]
    if not sablon or #sablon.uyeler == 0 then return false, 'Etkinliğin şablonu silinmiş, etkinliği düzenle.' end
    if #e.dogma == 0 then return false, 'Doğma noktası yok.' end

    Aktif = { id = id, e = e, dalga = 0, canlilar = {}, oldurulen = 0, baslangic = os.time(), sonrakiDalga = os.time() + 10 }
    duyur(e.ad, ('Etkinlik başlıyor! %d dalga düşman geliyor, 10 saniye içinde ilk dalga. Haritadaki işarete bak.'):format(e.dalgaSayisi), 'warning')
    SenkGonder()
    return true
end

-- Saniyede bir: dalga temizlendi mi, sıradaki dalga zamanı geldi mi, süre doldu mu?
CreateThread(function()
    while true do
        Wait(1000)
        if Aktif then
            local e = Aktif.e
            local simdi = os.time()
            -- silinmiş / kaybolmuş NPC'leri canlı sayma
            -- (doğamayanlar da: limit dolduysa veya model oluşturulamadıysa haritada hiç yoktur)
            for id in pairs(Aktif.canlilar) do
                if not Veri.npcler[id] or (not Canli[id] and not Bekleyen[id]) then Aktif.canlilar[id] = nil end
            end

            if simdi - Aktif.baslangic >= e.sureDk * 60 then
                EtkinlikBitir('sure')
            elseif canliSayisi() == 0 then
                if Aktif.dalga >= e.dalgaSayisi then
                    EtkinlikBitir('kazanildi')
                elseif not Aktif.sonrakiDalga then
                    Aktif.sonrakiDalga = simdi + e.dalgaArasi
                    duyur(e.ad, ('%d. dalga püskürtüldü! Sıradaki dalga %d saniye sonra.'):format(Aktif.dalga, e.dalgaArasi), 'success')
                elseif simdi >= Aktif.sonrakiDalga then
                    dalgaGonder()
                end
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(kaynak)
    if kaynak == GetCurrentResourceName() and Aktif then
        Aktif = nil
        geciciNpcleriTemizle()
    end
end)
