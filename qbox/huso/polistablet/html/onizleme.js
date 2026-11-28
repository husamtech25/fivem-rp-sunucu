'use strict';
// Sadece tarayıcıda tasarımı denemek için sahte veri. Oyunda bu dosya yüklenmez.
(() => {
    let id = 3;
    const simdi = () => Math.floor(Date.now() / 1000);
    const veri = {
        ihbarlar: [
            { id: 3, yazi: 'Silah sesleri ihbarı', sokak: 'Strawberry Ave / Davis Ave, Davis', x: 100, y: -1500, z: 29, zaman: simdi() - 40, durum: 'yeni' },
            { id: 2, yazi: 'Acil çağrı: arkadaşım vuruldu', sokak: 'Vespucci Blvd, Little Seoul', x: -600, y: -900, z: 25, zaman: simdi() - 700, durum: 'ilgileniliyor', ilgilenen: '[101] Hüsamettin Özçelik' },
            { id: 1, yazi: 'Plaka radarı: 46ABC123', sokak: 'Del Perro Fwy, Del Perro', x: -1500, y: -500, z: 30, zaman: simdi() - 3000, durum: 'kapandi', kapatan: 'Ali Kaya' },
        ],
        ekip: [
            { ad: '[101] Hüsamettin Özçelik', rutbe: 'Chief', birim: 'LSPD', x: 441, y: -982, z: 30, ben: true },
            { ad: '[214] Ali Kaya', rutbe: 'Officer', birim: 'LSPD', x: 1850, y: 3686, z: 34 },
        ],
        ben: { ad: '[101] Hüsamettin Özçelik', gorevde: true, x: 441, y: -982, z: 30 },
    };
    window.onizlemeNui = async (ad, v) => {
        if (ad === 'getir') return { ...JSON.parse(JSON.stringify(veri)), simdi: simdi() };
        if (ad === 'islem') {
            const i = veri.ihbarlar.find((x) => x.id === v.id);
            if (v.tip === 'ustlen') Object.assign(i, { durum: 'ilgileniliyor', ilgilenen: veri.ben.ad });
            if (v.tip === 'birak') Object.assign(i, { durum: 'yeni', ilgilenen: null });
            if (v.tip === 'kapat') Object.assign(i, { durum: 'kapandi', kapatan: veri.ben.ad });
            if (v.tip === 'ac') Object.assign(i, { durum: i.ilgilenen ? 'ilgileniliyor' : 'yeni' });
            return { ok: true };
        }
        return true;
    };
    // 5 saniye sonra yeni bir ihbar gelsin (bildirimi görmek için)
    setTimeout(() => veri.ihbarlar.unshift({ id: ++id, yazi: 'Silah sesleri ihbarı', sokak: 'Grove St, Davis', x: 100, y: -1900, z: 20, zaman: simdi(), durum: 'yeni' }), 5000);
    window.postMessage({ islem: 'ac', konumlar: [
        { kategori: 'Karakollar', liste: [{ ad: 'Mission Row Karakolu (MRPD)', x: 441, y: -982, z: 30 }, { ad: 'Sandy Shores Şerifliği', x: 1853, y: 3686, z: 34 }] },
        { kategori: 'Hastaneler', liste: [{ ad: 'Pillbox Hastanesi', x: 298, y: -584, z: 43 }] },
    ] }, '*');
})();
