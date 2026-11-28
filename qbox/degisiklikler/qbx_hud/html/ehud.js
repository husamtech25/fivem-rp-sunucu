'use strict';
// [Huso] Endcore HUD – yeni gösterge tasarımı.
// Mantık qbx_hud'un kendi app.js'inde (hudTick) aynen duruyor; bu dosya sadece görünümü sağlar:
//   - aynı çizgi stilinde SVG ikonlar
//   - değere göre yumuşak renk geçişi (can / açlık / susuzluk azaldıkça kırmızıya döner)
//   - ince yuvarlak gösterge bileşeni (<e-gosterge>)
//   - konum / ölçek ayarları (HUD menüsünden değiştirilir, tarayıcı hafızasında saklanır)

// ================= İkonlar (24x24, çizgi stili) =================
const EHUD_IKONLAR = {
    kalp: '<path d="M19 14c1.49-1.46 3-3.21 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.76 0-3 .5-4.5 2-1.5-1.5-2.74-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.3 1.5 4.05 3 5.5l7 7Z"/>',
    kalkan: '<path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/>',
    yemek: '<path d="M3 2v7c0 1.1.9 2 2 2h4a2 2 0 0 0 2-2V2"/><path d="M7 2v20"/><path d="M21 15V2a5 5 0 0 0-5 5v6c0 1.1.9 2 2 2h3Zm0 0v7"/>',
    damla: '<path d="M12 22a7 7 0 0 0 7-7c0-2-1-3.9-3-5.5s-3.5-4-4-6.5c-.5 2.5-2 4.9-4 6.5C6 11.1 5 13 5 15a7 7 0 0 0 7 7z"/>',
    simsek: '<path d="M13 2 3 14h9l-1 8 10-12h-9l1-8z"/>',
    baloncuk: '<circle cx="9" cy="14" r="5"/><circle cx="17" cy="7" r="3"/><circle cx="18.5" cy="16.5" r="2"/>',
    mikrofon: '<rect x="9" y="2" width="6" height="12" rx="3"/><path d="M19 10v1a7 7 0 0 1-14 0v-1"/><path d="M12 18v4"/>',
    kulaklik: '<path d="M3 14h3a2 2 0 0 1 2 2v3a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-7a9 9 0 0 1 18 0v7a2 2 0 0 1-2 2h-1a2 2 0 0 1-2-2v-3a2 2 0 0 1 2-2h3"/>',
    nabiz: '<path d="M22 12h-4l-3 9L9 3l-3 9H2"/>',
    nisan: '<circle cx="12" cy="12" r="8"/><path d="M22 12h-4M6 12H2M12 6V2M12 22v-4"/>',
    parasut: '<path d="M3 11a9 9 0 0 1 18 0"/><path d="M3 11l9 9 9-9M12 11v9"/>',
    anahtar: '<path d="M14.7 6.3a1 1 0 0 0 0 1.4l1.6 1.6a1 1 0 0 0 1.4 0l3.77-3.77a6 6 0 0 1-7.94 7.94l-6.91 6.91a2.12 2.12 0 0 1-3-3l6.91-6.91a6 6 0 0 1 7.94-7.94l-3.76 3.76z"/>',
    kemer: '<rect x="3" y="8" width="18" height="8" rx="4"/><path d="M12 8v8"/>',
    hiz: '<path d="m12 14 4-4"/><path d="M3.34 19a10 10 0 1 1 17.32 0"/>',
    alev: '<path d="M8.5 14.5A2.5 2.5 0 0 0 11 12c0-1.38-.5-2-1-3-1.07-2.14-.22-4.05 2-6 .5 2.5 2 4.9 4 6.5 2 1.6 3 3.5 3 5.5a7 7 0 1 1-14 0c0-1.15.43-2.29 1-3a2.5 2.5 0 0 0 2.5 2.5z"/>',
    terminal: '<path d="m4 17 6-6-6-6"/><path d="M12 19h8"/>',
    // araç HUD'u
    yakit: '<path d="M3 22V5a2 2 0 0 1 2-2h7a2 2 0 0 1 2 2v17"/><path d="M2 22h13"/><path d="M14 11h2a2 2 0 0 1 2 2v3a2 2 0 0 0 4 0V9l-3-3"/><path d="M6 8h5"/>',
    motor: '<path d="M12 2v10"/><path d="M18.4 6.6a9 9 0 1 1-12.77.04"/>',
    far: '<path d="M10 6c-4 0-6 3-6 6s2 6 6 6c2 0 3-1 3-6s-1-6-3-6z"/><path d="M16 8h5M16 12h6M16 16h5"/>',
    emniyet: '<path d="M6 3l12 18"/><circle cx="12" cy="12" r="2.5"/><path d="M4 12h5M15 12h5"/>',
};

// ================= Renk geçişi =================
// duraklar: [[değer, '#rrggbb'], ...] küçükten büyüğe. Aradaki değerler karıştırılır.
function ehudRenk(deger, duraklar) {
    const v = Math.max(0, Math.min(100, Number(deger) || 0));
    if (v <= duraklar[0][0]) return duraklar[0][1];
    for (let i = 1; i < duraklar.length; i++) {
        const [b, renkB] = duraklar[i];
        const [a, renkA] = duraklar[i - 1];
        if (v <= b) {
            const t = (v - a) / (b - a);
            const ca = parseInt(renkA.slice(1), 16), cb = parseInt(renkB.slice(1), 16);
            const kar = (kaydir) => Math.round(((ca >> kaydir) & 255) + ((((cb >> kaydir) & 255) - ((ca >> kaydir) & 255)) * t));
            return `rgb(${kar(16)}, ${kar(8)}, ${kar(0)})`;
        }
    }
    return duraklar[duraklar.length - 1][1];
}

const EHUD_PALET = {
    can:          [[0, '#ff3b5c'], [35, '#ff9f3d'], [70, '#3ef08a'], [100, '#3ef08a']],
    aclik:        [[0, '#ff3b5c'], [30, '#ff7a3d'], [100, '#ffb547']],
    susuzluk:     [[0, '#ff3b5c'], [20, '#ff5c8a'], [45, '#8f7bff'], [100, '#3dc8ff']],
    dayaniklilik: [[0, '#ff9f3d'], [40, '#ffe14d'], [100, '#c6ff4d']],
};

// ================= Konum / ölçek ayarları =================
const EHUD_VARSAYILAN = {
    konum: 'sol-alt', olcek: 1, x: 0, y: 0, sayi: false, parlama: true,
    aracKonum: 'sag-alt', aracOlcek: 1,   // araç HUD'u
};

// Araç HUD'u renkleri
const EHUD_PALET_ARAC = {
    devir:  [[0, '#3dc8ff'], [70, '#3dc8ff'], [85, '#ffb547'], [100, '#ff3b5c']],
    yakit:  [[0, '#ff3b5c'], [20, '#ff7a3d'], [50, '#ffd23d'], [100, '#c6ff4d']],
    motor:  [[0, '#ff3b5c'], [35, '#ff9f3d'], [70, '#3ef08a'], [100, '#3ef08a']],
};

const hudDuzen = Vue.reactive((() => {
    try {
        return { ...EHUD_VARSAYILAN, ...JSON.parse(localStorage.getItem('endHudDuzen') || '{}') };
    } catch {
        return { ...EHUD_VARSAYILAN };
    }
})());

Vue.watch(hudDuzen, (yeni) => localStorage.setItem('endHudDuzen', JSON.stringify(yeni)), { deep: true });

function hudDuzenSifirla() {
    Object.assign(hudDuzen, EHUD_VARSAYILAN);
}

// ================= Gösterge bileşeni =================
const EGosterge = {
    props: {
        deger: { type: Number, default: 0 },
        max: { type: Number, default: 100 },
        renk: { type: String, default: '#ffffff' },
        ikon: { type: String, default: '' },     // EHUD_IKONLAR'daki ad
        fa: { type: String, default: '' },       // başka scriptlerin eklediği göstergeler için FontAwesome sınıfı
        etiket: { type: String, default: '' },
        kritik: { type: Boolean, default: false },
        sonuk: { type: Boolean, default: false },
    },
    computed: {
        doluluk() {
            const v = (Number(this.deger) || 0) / (this.max || 100) * 100;
            return Math.max(0, Math.min(100, v));
        },
        ikonYolu() { return EHUD_IKONLAR[this.ikon] || ''; },
        duzen() { return hudDuzen; },
    },
    template: `
        <div class="eg" :class="{ 'eg-kritik': kritik, 'eg-sonuk': sonuk, 'eg-parlak': duzen.parlama }" :style="{ '--renk': renk }" :title="etiket">
            <svg class="eg-halka" viewBox="0 0 44 44" aria-hidden="true">
                <circle class="eg-iz" cx="22" cy="22" r="19" pathLength="100"></circle>
                <circle class="eg-dolu" cx="22" cy="22" r="19" pathLength="100" :style="{ strokeDashoffset: 100 - doluluk }"></circle>
            </svg>
            <span class="eg-ikon">
                <svg v-if="ikonYolu" viewBox="0 0 24 24" v-html="ikonYolu"></svg>
                <i v-else :class="fa"></i>
            </span>
            <span v-if="duzen.sayi" class="eg-sayi">{{ Math.round(doluluk) }}</span>
        </div>`,
};

// ================= Harita (minimap) çerçevesi ve ayarları =================
// Haritanın kendisini GTA çizer; Lua (client/ehud_harita.lua) haritanın ekrandaki yerini hesaplayıp
// gönderir, burada o kutunun etrafına ince yuvarlak bir çerçeve çizilir.

const haritaDurum = Vue.reactive({ goster: false, kutu: null });
// Araçtayken karakter göstergeleri haritanın sağında yukarıdan aşağı dizilir
const aracDurum = Vue.reactive({ icinde: false });
const haritaAyar = Vue.reactive({ x: -10, y: 0, genislik: 100, yukseklik: 100, cerceve: true, ix: 33, iy: 14, iw: 0, ih: 0 });
let haritaLuadanGeliyor = false;
let haritaZamanlayici = null;

function haritaPost(ad, veri) {
    if (typeof GetParentResourceName !== 'function') return;
    fetch(`https://${GetParentResourceName()}/${ad}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(veri || {}),
    }).catch(() => {});
}

window.addEventListener('message', (olay) => {
    const d = olay.data || {};
    if (d.action !== 'endHarita') return;
    haritaDurum.goster = d.goster === true;
    haritaDurum.kutu = d.kutu || null;
    if (d.ayar) {
        haritaLuadanGeliyor = true;
        Object.assign(haritaAyar, d.ayar);
        Vue.nextTick(() => { haritaLuadanGeliyor = false; });
    }
});

// Menüde kaydırıcı oynatılınca Lua'ya gönder (çok sık gitmesin diye kısa bekleme)
Vue.watch(haritaAyar, () => {
    if (haritaLuadanGeliyor) return;
    clearTimeout(haritaZamanlayici);
    haritaZamanlayici = setTimeout(() => haritaPost('endHaritaAyar', { ...haritaAyar }), 250);
}, { deep: true });

function haritaSifirla() {
    Object.assign(haritaAyar, { x: -10, y: 0, genislik: 100, yukseklik: 100, cerceve: true, ix: 33, iy: 14, iw: 0, ih: 0 });
}

const EHarita = {
    data() { return { durum: haritaDurum, duzen: hudDuzen }; },
    computed: {
        stil() {
            const k = this.durum.kutu;
            if (!k) return {};
            return {
                left: `${k.sol * 100}vw`,
                bottom: `${k.alt * 100}vh`,
                width: `${k.gen * 100}vw`,
                height: `${k.yuk * 100}vh`,
            };
        },
    },
    template: `
        <transition name="ehud-gecis">
            <div v-if="durum.goster && durum.kutu" class="eharita" :class="{ 'eg-parlak': duzen.parlama }" :style="stil">
                <div class="eharita-pencere"></div>
                <span class="eharita-k"></span>
            </div>
        </transition>`,
};

document.addEventListener('DOMContentLoaded', () => {
    const yer = document.getElementById('ehud-harita');
    if (yer) Vue.createApp(EHarita).mount(yer);
    haritaPost('endHaritaIste');
});
