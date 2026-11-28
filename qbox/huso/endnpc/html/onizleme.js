'use strict';
// Sadece tarayıcıda tasarımı denemek için sahte veri. Oyunda bu dosya yüklenmez.
(() => {
    const ayar = {
        modeller: [{ kategori: 'Çete', liste: [{ ad: 'g_m_y_mexgoon_01', etiket: 'Meksikalı 1' }, { ad: 'g_m_y_lost_01', etiket: 'Lost MC 1' }] },
            { kategori: 'Asker / Güvenlik', liste: [{ ad: 's_m_y_marine_01', etiket: 'Asker 1' }, { ad: 's_m_y_swat_01', etiket: 'SWAT' }] }],
        silahlar: [{ ad: 'WEAPON_UNARMED', etiket: 'Silahsız (yumruk)' }, { ad: 'WEAPON_PISTOL', etiket: 'Tabanca' }, { ad: 'WEAPON_CARBINERIFLE', etiket: 'Karabina (M4)' }],
        renkler: [{ hex: '#e74c3c', ad: 'Kırmızı' }, { hex: '#ff7a1a', ad: 'Turuncu' }, { hex: '#2ecc71', ad: 'Yeşil' }, { hex: '#3466e0', ad: 'Mavi' }, { hex: '#9b59b6', ad: 'Mor' }],
        secenekler: {
            iliski: ['dost', 'tarafsiz', 'dusman'], hareket: ['saldirgan', 'savunmaci', 'sabit'],
            davranis: ['nobetci', 'devriye', 'rota', 'saldirgan', 'sabit', 'pasif'], rotaTur: ['dongu', 'gidipGel'], dusukCanDavranisi: ['devam', 'siper', 'kac', 'cildir'],
            olumDavranisi: ['sil', 'yenidenDog', 'bekle'],
        },
        etiketler: {
            iliski: { dost: 'Dost', tarafsiz: 'Tarafsız', dusman: 'Düşman' },
            hareket: { saldirgan: 'Saldırgan – üstüne gider', savunmaci: 'Savunmacı – siper alır', sabit: 'Sabit – yerinden oynamaz' },
            davranis: { nobetci: 'Nöbetçi – yerini korur', devriye: 'Devriye – dolaşır', rota: 'Rota – noktalar arasında gezer', saldirgan: 'Avcı – düşman arar', sabit: 'Sabit – yürümez', pasif: 'Pasif – saldırmaz' },
            dusukCanDavranisi: { devam: 'Değişmesin', siper: 'Siper alsın', kac: 'Kaçsın', cildir: 'Çıldırsın' },
            rotaTur: { dongu: 'Döngü', gidipGel: 'Gidip gel' }, olumDavranisi: { sil: 'Kaydı sil', yenidenDog: 'Yeniden doğsun', bekle: 'Kapalı beklesin' },
        },
        sinirlar: { can: [1, 1000], zirh: [0, 100], ofke: [0, 100], gorusMesafesi: [5, 300], saldiriMesafesi: [2, 200], saldiriSikligi: [0, 100],
            isabet: [0, 100], takipMesafesi: [5, 500], dusukCanEsigi: [0, 100], maxNpc: [1, 150], aiAralik: [200, 3000], cesetSuresi: [0, 600], yenidenDogmaSuresi: [5, 3600], yaricap: [5, 300], alarmSuresi: [0, 600], rotaBekleme: [0, 300] },
        varsayilanNpc: { ad: 'NPC', model: 'g_m_y_mexgoon_01', can: 200, zirh: 0, silah: 'WEAPON_PISTOL', davranis: 'nobetci', aktif: true },
        araclar: [{ ad: 'police', etiket: 'Polis aracı' }, { ad: 'daemon', etiket: 'Daemon (motor)' }], rotaEnFazla: 20, varsayilanBolge: { ad: 'Yeni bölge', yaricap: 40, oyuncuAlarm: false, alarmSuresi: 30, aktif: true },
        varsayilanGrup: { ad: 'Yeni grup', renk: '#ff7a1a', oyuncuIliskisi: 'tarafsiz', gorusMesafesi: 60, saldiriMesafesi: 40, ofke: 50,
            saldiriSikligi: 50, isabet: 40, hareket: 'saldirgan', takipMesafesi: 80, dusukCanEsigi: 25, dusukCanDavranisi: 'siper' },
    };
    let sonId = 10;
    const g = (id, ad, renk, ek = {}) => ({ id, ad, renk, ...ayar.varsayilanGrup, ...ek, ad, renk });
    const veri = {
        ayarlar: { maxNpc: 40, aiAralik: 500, cesetSuresi: 20, olumDavranisi: 'sil', yenidenDogmaSuresi: 60 },
        gruplar: { g1: g('g1', 'Güvenlik', '#3466e0', { hareket: 'savunmaci' }), g2: g('g2', 'Çete', '#e74c3c', { ofke: 70, oyuncuIliskisi: 'dusman' }) },
        iliskiler: { 'g1|g2': 'dusman' },
        sablonlar: { s1: { id: 's1', ad: 'Çete baskını', aciklama: '5 kişilik çete', uyeler: [{ ad: 'Elebaşı', model: 'g_m_y_mexgoon_01', silah: 'WEAPON_PISTOL' }, { ad: 'Tetikçi', model: 'g_m_y_mexgoon_01', silah: 'WEAPON_PISTOL', arac: 'daemon' }] } },
        bolgeler: { b1: { id: 'b1', ad: 'Liman', grup: 'g2', x: 441, y: -982, z: 30, yaricap: 40, alarmSuresi: 30, oyuncuAlarm: true, aktif: true } },
        npcler: {
            n3: { id: 'n3', ad: 'Nöbetçi 1', grup: 'g1', model: 's_m_y_marine_01', can: 200, zirh: 50, silah: 'WEAPON_CARBINERIFLE', davranis: 'nobetci', aktif: true, x: 441.2, y: -981.9, z: 29.7, h: 90, durumBilgi: { durum: 'canli', can: 140 } },
            n4: { id: 'n4', ad: 'Tetikçi', grup: 'g2', model: 'g_m_y_mexgoon_01', can: 150, zirh: 0, ofke: 90, silah: 'WEAPON_PISTOL', davranis: 'saldirgan', aktif: true, x: 450, y: -990, z: 29.7, h: 0, durumBilgi: { durum: 'olu', kalan: 12 } },
            n5: { id: 'n5', ad: 'Yedek', grup: 'g2', model: 'g_m_y_lost_01', can: 200, zirh: 0, silah: 'WEAPON_UNARMED', davranis: 'devriye', aktif: false, x: 452, y: -992, z: 29.7, h: 0, durumBilgi: { durum: 'kapali' } },
        },
    };
    const durumEkle = () => { veri.aktif = Object.values(veri.npcler).filter((n) => n.aktif).length; return JSON.parse(JSON.stringify(veri)); };
    const islemler = {
        getir: () => durumEkle(),
        npcKaydet: (v) => {
            const id = v.id || `n${++sonId}`;
            const eski = veri.npcler[id] || {};
            const n = { ...eski, ...v, id, durumBilgi: v.aktif === false ? { durum: 'kapali' } : { durum: 'canli', can: v.can ?? eski.can } };
            if (v.ofkeGrup) delete n.ofke;
            delete n.ofkeGrup;
            veri.npcler[id] = n;
            return id;
        },
        npcTopluDuzenle: ({ ids, alanlar }) => { ids.forEach((id) => islemler.npcKaydet({ ...veri.npcler[id], ...alanlar, id })); return ids.length; },
        npcSil: ({ ids }) => { ids.forEach((id) => delete veri.npcler[id]); return ids.length; },
        npcYenidenDogur: ({ ids }) => { ids.forEach((id) => { veri.npcler[id].aktif = true; veri.npcler[id].durumBilgi = { durum: 'doguyor' }; }); return ids.length; },
        hepsiniYenidenDogur: () => Object.keys(veri.npcler).length,
        konumGetir: ({ id }) => veri.npcler[id],
        grupKaydet: (v) => { const id = v.id || `g${++sonId}`; veri.gruplar[id] = { ...(veri.gruplar[id] || ayar.varsayilanGrup), ...v, id }; return id; },
        grupTopluDuzenle: ({ ids, alanlar }) => { ids.forEach((id) => Object.assign(veri.gruplar[id], alanlar)); return ids.length; },
        grupSil: ({ id, npcIslem, hedef }) => {
            for (const n of Object.values(veri.npcler)) if (n.grup === id) { if (npcIslem === 'tasi') n.grup = hedef; else delete veri.npcler[n.id]; }
            delete veri.gruplar[id];
            return true;
        },
        iliskiAyarla: ({ a, b, deger }) => { veri.iliskiler[a < b ? `${a}|${b}` : `${b}|${a}`] = deger; return true; },
        sablonOlustur: ({ ids, ad }) => { veri.sablonlar['s' + (++sonId)] = { id: 's' + sonId, ad, uyeler: ids.map((id) => ({ ...veri.npcler[id] })) }; return true; },
        sablonDuzenle: (v) => { Object.assign(veri.sablonlar[v.id], v); return true; },
        sablonSil: ({ id }) => { delete veri.sablonlar[id]; return true; },
        sablonYerlestir: (v) => { veri.sablonlar[v.id].uyeler.forEach((u, i) => islemler.npcKaydet({ ...u, grup: v.grup, ad: (v.onEk ? v.onEk + ' ' : '') + u.ad, x: v.x + i * 2, y: v.y, z: v.z, h: v.h, aktif: true })); return veri.sablonlar[v.id].uyeler.length; },
        bolgeKaydet: (v) => { const id = v.id || 'b' + (++sonId); veri.bolgeler[id] = { ...(veri.bolgeler[id] || {}), ...v, id }; return id; },
        bolgeSil: ({ id }) => { delete veri.bolgeler[id]; return true; },
        ayarKaydet: (v) => { Object.assign(veri.ayarlar, v); return true; },
    };
    window.onizlemeNui = async (ad, v) => {
        if (ad === 'islem') return { ok: true, veri: islemler[v.tip]?.(v.veri) ?? true };
        if (ad === 'benimKonumum' || ad === 'konumSec') return { x: 440.5, y: -985.2, z: 29.69, h: 180 };
        if (ad === 'waypoint') return { hata: 'Haritada işaret (waypoint) yok.' };
        if (ad === 'modelDogrula') return true;
        if (ad === 'aracDogrula') return v.model === 'daemon' ? { tur: 'bike' } : { tur: 'automobile' };
        return true;
    };
    window.postMessage({ islem: 'ac', ayar, gorsel: { blip: false, etiket: false } }, '*');
})();
