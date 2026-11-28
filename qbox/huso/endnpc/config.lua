-- config.lua: Hem sunucu hem oyuncu tarafında okunan ayarlar.
-- Buradaki değerler sadece VARSAYILAN; asıl ayarlar oyun içinden panelle değiştirilir
-- ve data.json dosyasına kaydedilir.

Ayar = {}

Ayar.Komut = 'npcpanel'     -- /npcpanel ile panel açılır
Ayar.Tus = 'F7'             -- kısayol tuşu (ESC > Ayarlar > Tuş Atamaları > FiveM'den değiştirilebilir)
Ayar.Yetki = 'group.admin'  -- paneli sadece adminler kullanabilir

-- Genel ayarlar
Ayar.VarsayilanAyarlar = {
    maxNpc = 40,              -- aynı anda haritada olabilecek en fazla NPC
    aiAralik = 500,           -- yapay zeka kaç milisaniyede bir düşünür (küçük = daha akıllı, daha çok işlemci)
    cesetSuresi = 20,         -- ölen NPC'nin cesedi kaç saniye yerde kalır
    olumDavranisi = 'sil',    -- ölünce: 'sil' (kaydı sil), 'yenidenDog' (bir süre sonra tekrar doğ), 'bekle' (kapalı kalsın)
    yenidenDogmaSuresi = 60,  -- 'yenidenDog' seçiliyse kaç saniye sonra doğar
}

-- Yeni grup açılınca gelen değerler
Ayar.VarsayilanGrup = {
    ad = 'Yeni grup',
    renk = '#ff7a1a',
    oyuncuIliskisi = 'tarafsiz', -- oyunculara karşı: dost / tarafsiz / dusman
    gorusMesafesi = 60,          -- metre: düşmanı bu mesafeden fark eder
    saldiriMesafesi = 40,        -- metre: bu mesafeye girince ateş eder (dışındaysa yaklaşır)
    ofke = 50,                   -- 0-100: yüksekse kaçmaz, daha saldırgan dövüşür
    saldiriSikligi = 50,         -- 0-100: ne kadar sık ateş eder
    isabet = 40,                 -- 0-100: atış isabeti
    hareket = 'saldirgan',       -- saldirgan (üstüne gider) / savunmaci (siper alır) / sabit (yerinden oynamaz)
    takipMesafesi = 80,          -- metre: evinden bu kadar uzaklaşınca kovalamayı bırakıp geri döner
    dusukCanEsigi = 25,          -- can yüzde kaçın altına düşünce davranış değişir
    dusukCanDavranisi = 'siper', -- devam / siper / kac / cildir
    ihbar = false,               -- bu grubun NPC'leri çatışınca polise ihbar gitsin mi
    ganimetParaMin = 0,          -- ölünce üstünden çıkan nakit (en az / en çok). 0 / 0 = para yok
    ganimetParaMax = 0,
    ganimetSilah = false,        -- elindeki silah da çıksın mı
    ganimetEsyalar = {},         -- { { item = 'bandage', min = 1, max = 2, sans = 50 } }  sans = yüzde ihtimal
}

-- Polise ihbar: aynı bölgeden en fazla bu kadar saniyede bir ihbar gider (polisler boğulmasın)
Ayar.Ihbar = {
    bekleme = 90,      -- saniye
    alan = 150.0,      -- metre: bu mesafedeki çatışmalar "aynı olay" sayılır
    yazi = 'Silah sesleri ihbarı',
}

-- Kiralık koruma (panelde Ayarlar sekmesinden değiştirilir)
Ayar.VarsayilanKoruma = {
    aktif = false,               -- ajans konumu seçilip etkinleştirilince açılır
    fiyat = 500,                 -- koruma başına
    sure = 15,                   -- dakika
    enFazla = 2,                 -- bir oyuncu aynı anda en fazla kaç koruma tutabilir
    model = 's_m_m_highsec_01',
    silah = 'WEAPON_PISTOL',
    can = 200,
    zirh = 50,
    ajansModel = 's_m_m_highsec_02',   -- ajansta duran, konuşulan NPC
}

-- Dalga etkinliği varsayılanları
Ayar.VarsayilanEtkinlik = {
    ad = 'Yeni etkinlik',
    dalgaSayisi = 3,
    ilkDalga = 4,          -- ilk dalgada kaç düşman
    artis = 2,             -- her dalgada kaç düşman daha
    dalgaArasi = 20,       -- bir dalga temizlenince sıradakine kaç saniye
    sureDk = 15,           -- en fazla süre (dakika); dolunca etkinlik biter
    duyuru = true,         -- bütün oyunculara duyurulsun mu
}

-- Yeni NPC açılınca gelen değerler
Ayar.VarsayilanNpc = {
    ad = 'NPC',
    model = 'g_m_y_mexgoon_01',
    can = 200,
    zirh = 0,
    ofke = nil,                  -- nil = grubun öfke ayarını kullan
    silah = 'WEAPON_PISTOL',
    davranis = 'nobetci',
    arac = nil,                  -- araç modeli (nil = yaya)
    rotaTur = 'dongu',           -- devriye rotası: dongu (son noktadan başa) / gidipGel (ileri-geri)
    rotaBekleme = 3,             -- her rota noktasında kaç saniye beklesin
    aktif = true,
}

-- Yeni bölge açılınca gelen değerler
Ayar.VarsayilanBolge = {
    ad = 'Yeni bölge',
    yaricap = 40,                -- metre
    oyuncuAlarm = false,         -- true: oyuncular girince de saldırsınlar (grup oyunculara tarafsız olsa bile)
    alarmSuresi = 30,            -- saniye: davetsiz misafir çıktıktan sonra da bu kadar kovalarlar
    aktif = true,
}

Ayar.RotaEnFazla = 20            -- bir rotada en fazla kaç nokta olabilir

-- Sayı ayarlarının alt / üst sınırları (sunucu bu aralığın dışını kabul etmez)
Ayar.Sinirlar = {
    can = { 1, 1000 },
    zirh = { 0, 100 },
    ofke = { 0, 100 },
    gorusMesafesi = { 5, 300 },
    saldiriMesafesi = { 2, 200 },
    saldiriSikligi = { 0, 100 },
    isabet = { 0, 100 },
    takipMesafesi = { 5, 500 },
    dusukCanEsigi = { 0, 100 },
    maxNpc = { 1, 150 },
    aiAralik = { 200, 3000 },
    cesetSuresi = { 0, 600 },
    yenidenDogmaSuresi = { 5, 3600 },
    rotaBekleme = { 0, 300 },
    yaricap = { 5, 300 },
    alarmSuresi = { 0, 600 },
    ganimetParaMin = { 0, 100000 },
    ganimetParaMax = { 0, 100000 },
    ganimetAdet = { 1, 100 },
    ganimetSans = { 1, 100 },
    fiyat = { 0, 1000000 },
    sure = { 1, 180 },
    enFazla = { 1, 6 },
    dalgaSayisi = { 1, 20 },
    ilkDalga = { 1, 30 },
    artis = { 0, 10 },
    dalgaArasi = { 5, 300 },
    sureDk = { 1, 120 },
}

-- Seçenekli ayarların izin verilen değerleri
Ayar.Secenekler = {
    iliski = { 'dost', 'tarafsiz', 'dusman' },
    hareket = { 'saldirgan', 'savunmaci', 'sabit' },
    davranis = { 'nobetci', 'devriye', 'rota', 'saldirgan', 'hucum', 'sabit', 'pasif' },
    dusukCanDavranisi = { 'devam', 'siper', 'kac', 'cildir' },
    olumDavranisi = { 'sil', 'yenidenDog', 'bekle' },
    rotaTur = { 'dongu', 'gidipGel' },
    aracTur = { 'automobile', 'bike' },   -- sunucuda araç oluşturma türü (araba / motor)
}

-- Panelde görünen Türkçe yazılar
Ayar.Etiketler = {
    iliski = { dost = 'Dost', tarafsiz = 'Tarafsız', dusman = 'Düşman' },
    hareket = {
        saldirgan = 'Saldırgan – düşmanın üstüne gider',
        savunmaci = 'Savunmacı – siper alarak dövüşür',
        sabit = 'Sabit – yerinden oynamadan ateş eder',
    },
    davranis = {
        nobetci = 'Nöbetçi – yerini korur, uzaklaşırsa geri döner',
        devriye = 'Devriye – çevresinde dolaşır',
        rota = 'Rota – belirlediğin noktalar arasında sırayla devriye gezer',
        saldirgan = 'Avcı – geniş alanda dolaşıp düşman arar, uzağa kovalar',
        hucum = 'Hücum – hedef noktaya koşar, yolda gördüğü düşmanla çatışır (etkinliklerde)',
        sabit = 'Sabit – hiç yürümez, olduğu yerden ateş eder',
        pasif = 'Pasif – kimseye saldırmaz, saldırılınca kaçar',
    },
    dusukCanDavranisi = {
        devam = 'Değişmesin',
        siper = 'Siper alsın',
        kac = 'Kaçsın',
        cildir = 'Çıldırsın (daha sık ve isabetli ateş)',
    },
    olumDavranisi = {
        sil = 'Kaydı tamamen sil',
        yenidenDog = 'Bir süre sonra yeniden doğsun',
        bekle = 'Kayıt kalsın, kapalı beklesin',
    },
    rotaTur = {
        dongu = 'Döngü – son noktadan sonra ilk noktaya döner',
        gidipGel = 'Gidip gel – sona varınca geri yürür',
    },
}

-- Panelde hazır seçilebilen araçlar (sadece araba ve motor; panelden başka model de yazılabilir)
Ayar.Araclar = {
    { ad = 'police',    etiket = 'Polis aracı',        tur = 'automobile' },
    { ad = 'police2',   etiket = 'Polis aracı 2',      tur = 'automobile' },
    { ad = 'sheriff',   etiket = 'Şerif aracı',        tur = 'automobile' },
    { ad = 'fbi',       etiket = 'Sivil ajan aracı',   tur = 'automobile' },
    { ad = 'crusader',  etiket = 'Askerî cip',         tur = 'automobile' },
    { ad = 'mesa3',     etiket = 'Askerî Mesa',        tur = 'automobile' },
    { ad = 'baller',    etiket = 'Baller (SUV)',       tur = 'automobile' },
    { ad = 'cavalcade', etiket = 'Cavalcade (SUV)',    tur = 'automobile' },
    { ad = 'gburrito',  etiket = 'Çete minibüsü',      tur = 'automobile' },
    { ad = 'buffalo',   etiket = 'Buffalo',            tur = 'automobile' },
    { ad = 'sultan',    etiket = 'Sultan',             tur = 'automobile' },
    { ad = 'daemon',    etiket = 'Daemon (motor)',     tur = 'bike' },
    { ad = 'hexer',     etiket = 'Hexer (motor)',      tur = 'bike' },
    { ad = 'sanchez',   etiket = 'Sanchez (kros)',     tur = 'bike' },
}

-- İlk açılışta eklenen hazır şablonlar. dx / dy: ilk üyeye göre metre (dy ileri, dx sağ), dh: yön farkı.
-- Panelden yeni şablon da kaydedilebilir (seçili NPC'lerden).
Ayar.HazirSablonlar = {
    { ad = 'Çete baskını', aciklama = '5 kişilik saldırgan çete ekibi', uyeler = {
        { ad = 'Elebaşı',   model = 'g_m_m_armboss_01', silah = 'WEAPON_ASSAULTRIFLE', davranis = 'saldirgan', can = 300, zirh = 50, dx = 0,  dy = 0,  dh = 0 },
        { ad = 'Tetikçi 1', model = 'g_m_y_mexgoon_01', silah = 'WEAPON_MICROSMG',     davranis = 'saldirgan', can = 200, zirh = 0,  dx = -2, dy = -2, dh = 0 },
        { ad = 'Tetikçi 2', model = 'g_m_y_mexgoon_02', silah = 'WEAPON_MICROSMG',     davranis = 'saldirgan', can = 200, zirh = 0,  dx = 2,  dy = -2, dh = 0 },
        { ad = 'Tetikçi 3', model = 'g_m_y_salvagoon_01', silah = 'WEAPON_PISTOL',     davranis = 'saldirgan', can = 180, zirh = 0,  dx = -3, dy = -4, dh = 0 },
        { ad = 'Tetikçi 4', model = 'g_m_y_armgoon_02', silah = 'WEAPON_SAWNOFFSHOTGUN', davranis = 'saldirgan', can = 180, zirh = 0, dx = 3, dy = -4, dh = 0 },
    } },
    { ad = 'Askerî kontrol noktası', aciklama = '3 nöbetçi asker + 1 keskin nişancı', uyeler = {
        { ad = 'Çavuş',     model = 's_m_y_marine_03',   silah = 'WEAPON_CARBINERIFLE', davranis = 'nobetci', can = 250, zirh = 100, dx = 0,  dy = 0,  dh = 0 },
        { ad = 'Er 1',      model = 's_m_y_marine_01',   silah = 'WEAPON_CARBINERIFLE', davranis = 'nobetci', can = 200, zirh = 100, dx = -4, dy = 0,  dh = -30 },
        { ad = 'Er 2',      model = 's_m_y_marine_01',   silah = 'WEAPON_CARBINERIFLE', davranis = 'nobetci', can = 200, zirh = 100, dx = 4,  dy = 0,  dh = 30 },
        { ad = 'Nişancı',   model = 's_m_y_blackops_01', silah = 'WEAPON_SNIPERRIFLE',  davranis = 'sabit',   can = 150, zirh = 50,  dx = 0,  dy = -8, dh = 0 },
    } },
    { ad = 'Polis devriye ekibi', aciklama = '2 polis, her biri araçla devriye', uyeler = {
        { ad = 'Devriye 1', model = 's_m_y_cop_01', silah = 'WEAPON_COMBATPISTOL', davranis = 'devriye', can = 200, zirh = 50, arac = 'police',  aracTur = 'automobile', dx = 0, dy = 0,  dh = 0 },
        { ad = 'Devriye 2', model = 's_f_y_cop_01', silah = 'WEAPON_COMBATPISTOL', davranis = 'devriye', can = 200, zirh = 50, arac = 'police2', aracTur = 'automobile', dx = 4, dy = -6, dh = 0 },
    } },
    { ad = 'Motorcu çetesi', aciklama = '3 Lost MC üyesi, motorlarıyla avlanır', uyeler = {
        { ad = 'Lider',  model = 'g_m_y_lost_01', silah = 'WEAPON_SAWNOFFSHOTGUN', davranis = 'saldirgan', can = 220, zirh = 25, arac = 'daemon', aracTur = 'bike', dx = 0,  dy = 0,  dh = 0 },
        { ad = 'Üye 1',  model = 'g_m_y_lost_02', silah = 'WEAPON_PISTOL',         davranis = 'saldirgan', can = 180, zirh = 0,  arac = 'hexer',  aracTur = 'bike', dx = -2, dy = -3, dh = 0 },
        { ad = 'Üye 2',  model = 'g_m_y_lost_01', silah = 'WEAPON_MICROSMG',       davranis = 'saldirgan', can = 180, zirh = 0,  arac = 'daemon', aracTur = 'bike', dx = 2,  dy = -3, dh = 0 },
    } },
    { ad = 'Keskin nişancı ikilisi', aciklama = 'Yerinden kıpırdamayan 2 nişancı', uyeler = {
        { ad = 'Nişancı 1', model = 's_m_y_blackops_02', silah = 'WEAPON_SNIPERRIFLE', davranis = 'sabit', can = 150, zirh = 50, dx = 0, dy = 0, dh = 0 },
        { ad = 'Gözcü',     model = 's_m_y_blackops_01', silah = 'WEAPON_CARBINERIFLE', davranis = 'sabit', can = 150, zirh = 50, dx = 2, dy = 0, dh = 0 },
    } },
}

-- Grup renkleri: panelde renk, haritada blip rengi (GTA blip renk numarası)
Ayar.Renkler = {
    { hex = '#e74c3c', blip = 1,  ad = 'Kırmızı' },
    { hex = '#ff7a1a', blip = 17, ad = 'Turuncu' },
    { hex = '#f1c40f', blip = 5,  ad = 'Sarı' },
    { hex = '#2ecc71', blip = 2,  ad = 'Yeşil' },
    { hex = '#5dade2', blip = 18, ad = 'Açık mavi' },
    { hex = '#3466e0', blip = 3,  ad = 'Mavi' },
    { hex = '#9b59b6', blip = 7,  ad = 'Mor' },
    { hex = '#ff5fa2', blip = 8,  ad = 'Pembe' },
    { hex = '#ecf0f1', blip = 4,  ad = 'Beyaz' },
    { hex = '#5f6368', blip = 40, ad = 'Gri' },
}

Ayar.Silahlar = {
    { ad = 'WEAPON_UNARMED',        etiket = 'Silahsız (yumruk)' },
    { ad = 'WEAPON_KNIFE',          etiket = 'Bıçak' },
    { ad = 'WEAPON_BAT',            etiket = 'Beyzbol sopası' },
    { ad = 'WEAPON_MACHETE',        etiket = 'Pala' },
    { ad = 'WEAPON_PISTOL',         etiket = 'Tabanca' },
    { ad = 'WEAPON_COMBATPISTOL',   etiket = 'Savaş tabancası' },
    { ad = 'WEAPON_HEAVYPISTOL',    etiket = 'Ağır tabanca' },
    { ad = 'WEAPON_MICROSMG',       etiket = 'Mikro SMG' },
    { ad = 'WEAPON_SMG',            etiket = 'SMG' },
    { ad = 'WEAPON_ASSAULTRIFLE',   etiket = 'Saldırı tüfeği (AK)' },
    { ad = 'WEAPON_CARBINERIFLE',   etiket = 'Karabina (M4)' },
    { ad = 'WEAPON_SPECIALCARBINE', etiket = 'Özel karabina' },
    { ad = 'WEAPON_PUMPSHOTGUN',    etiket = 'Pompalı tüfek' },
    { ad = 'WEAPON_SAWNOFFSHOTGUN', etiket = 'Kısa pompalı' },
    { ad = 'WEAPON_MG',             etiket = 'Makineli tüfek' },
    { ad = 'WEAPON_COMBATMG',       etiket = 'Savaş makinelisi' },
    { ad = 'WEAPON_SNIPERRIFLE',    etiket = 'Keskin nişancı tüfeği' },
    { ad = 'WEAPON_RPG',            etiket = 'Roketatar (RPG)' },
}

-- Panelde hazır seçilebilen modeller (panelden başka bir model adı da yazılabilir)
Ayar.Modeller = {
    { kategori = 'Çete', liste = {
        { ad = 'g_m_y_ballaeast_01', etiket = 'Ballas 1' },
        { ad = 'g_m_y_ballaorig_01', etiket = 'Ballas 2' },
        { ad = 'g_m_y_famca_01',     etiket = 'Families 1' },
        { ad = 'g_m_y_famdnf_01',    etiket = 'Families 2' },
        { ad = 'g_m_y_mexgoon_01',   etiket = 'Meksikalı 1' },
        { ad = 'g_m_y_mexgoon_02',   etiket = 'Meksikalı 2' },
        { ad = 'g_m_y_lost_01',      etiket = 'Lost MC 1' },
        { ad = 'g_m_y_lost_02',      etiket = 'Lost MC 2' },
        { ad = 'g_m_y_salvagoon_01', etiket = 'Salvadorlu' },
        { ad = 'g_m_y_korean_01',    etiket = 'Koreli' },
        { ad = 'g_m_m_armboss_01',   etiket = 'Ermeni patron' },
        { ad = 'g_m_y_armgoon_02',   etiket = 'Ermeni adam' },
    } },
    { kategori = 'Asker / Güvenlik', liste = {
        { ad = 's_m_y_marine_01',   etiket = 'Asker 1' },
        { ad = 's_m_y_marine_03',   etiket = 'Asker 2' },
        { ad = 's_m_m_marine_01',   etiket = 'Asker 3' },
        { ad = 's_m_y_blackops_01', etiket = 'Özel kuvvet 1' },
        { ad = 's_m_y_blackops_02', etiket = 'Özel kuvvet 2' },
        { ad = 's_m_y_swat_01',     etiket = 'SWAT' },
        { ad = 's_m_m_security_01', etiket = 'Güvenlik görevlisi' },
        { ad = 's_m_m_chemsec_01',  etiket = 'Tesis güvenliği' },
    } },
    { kategori = 'Polis', liste = {
        { ad = 's_m_y_cop_01',      etiket = 'Polis (erkek)' },
        { ad = 's_f_y_cop_01',      etiket = 'Polis (kadın)' },
        { ad = 's_m_y_sheriff_01',  etiket = 'Şerif' },
        { ad = 's_m_y_hwaycop_01',  etiket = 'Trafik polisi' },
        { ad = 's_m_m_ciasec_01',   etiket = 'Ajan' },
        { ad = 's_m_y_ranger_01',   etiket = 'Korucu' },
    } },
    { kategori = 'Sivil', liste = {
        { ad = 'a_m_m_business_01', etiket = 'İş adamı' },
        { ad = 'a_f_y_business_01', etiket = 'İş kadını' },
        { ad = 'a_m_y_hipster_01',  etiket = 'Genç' },
        { ad = 'a_f_y_tourist_01',  etiket = 'Turist' },
        { ad = 'a_m_m_farmer_01',   etiket = 'Çiftçi' },
        { ad = 'a_m_m_hillbilly_01',etiket = 'Köylü' },
        { ad = 'a_m_y_skater_01',   etiket = 'Kaykaycı' },
        { ad = 'a_m_y_beach_01',    etiket = 'Plajcı' },
    } },
    { kategori = 'Diğer', liste = {
        { ad = 'u_m_y_zombie_01',      etiket = 'Zombi' },
        { ad = 's_m_y_clown_01',       etiket = 'Palyaço' },
        { ad = 'u_m_y_juggernaut_01',  etiket = 'Juggernaut' },
        { ad = 's_m_m_movalien_01',    etiket = 'Uzaylı' },
    } },
}
