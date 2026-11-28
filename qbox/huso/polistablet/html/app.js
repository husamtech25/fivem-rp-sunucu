'use strict';
// Polis tableti ekranı. Açıkken 3 saniyede bir sunucudan ihbarları ve ekibi ister.

const OYUNDA = typeof GetParentResourceName === 'function';
const KAYNAK = OYUNDA ? GetParentResourceName() : 'polistablet';

const S = { sekme: 'ihbar', filtre: 'acik', veri: null, konumlar: [], sonId: 0, ilkYukleme: true, zamanlayici: null, saatZamanlayici: null };

const $ = (s, k = document) => k.querySelector(s);
const $$ = (s, k = document) => [...k.querySelectorAll(s)];
const e = (v) => String(v ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));

async function nui(ad, veri = {}) {
    if (!OYUNDA) return window.onizlemeNui ? window.onizlemeNui(ad, veri) : null;
    try {
        const r = await fetch(`https://${KAYNAK}/${ad}`, { method: 'POST', headers: { 'Content-Type': 'application/json; charset=UTF-8' }, body: JSON.stringify(veri) });
        return await r.json();
    } catch { return null; }
}

function bildir(yazi, tur = 'basari') {
    const el = document.createElement('div');
    el.className = `bildirim ${tur}`;
    el.textContent = yazi;
    $('#bildirimler').appendChild(el);
    setTimeout(() => el.remove(), 3500);
}

// Yeni ihbarda kısa "bip bip" (dosya gerekmesin diye tarayıcının ses üreteciyle)
function bip() {
    try {
        const ses = new (window.AudioContext || window.webkitAudioContext)();
        [0, 0.18].forEach((gecikme) => {
            const o = ses.createOscillator(), g = ses.createGain();
            o.frequency.value = 880;
            g.gain.setValueAtTime(0.08, ses.currentTime + gecikme);
            g.gain.exponentialRampToValueAtTime(0.0001, ses.currentTime + gecikme + 0.14);
            o.connect(g).connect(ses.destination);
            o.start(ses.currentTime + gecikme);
            o.stop(ses.currentTime + gecikme + 0.15);
        });
    } catch { /* ses yoksa önemli değil */ }
}

function onceYazi(saniye) {
    if (saniye < 60) return 'az önce';
    const dk = Math.floor(saniye / 60);
    if (dk < 60) return `${dk} dk önce`;
    return `${Math.floor(dk / 60)} sa ${dk % 60} dk önce`;
}

function mesafe(a, b) {
    if (!a || !b) return '';
    const m = Math.hypot(a.x - b.x, a.y - b.y);
    return m < 1000 ? `${Math.round(m)} m` : `${(m / 1000).toFixed(1)} km`;
}

const DURUM_YAZI = { yeni: 'Yeni', ilgileniliyor: 'İlgileniliyor', kapandi: 'Kapandı' };

// ================= Veri =================

async function yenile() {
    const v = await nui('getir');
    if (!v) return;
    // Lua'dan boş liste bazen {} olarak gelir: her zaman diziye çevir
    const dizi = (x) => (Array.isArray(x) ? x : Object.values(x || {}));
    v.ihbarlar = dizi(v.ihbarlar);
    v.ekip = dizi(v.ekip);
    const enYeni = v.ihbarlar.reduce((m, i) => Math.max(m, i.id), 0);
    const yeniGelenler = S.ilkYukleme ? [] : v.ihbarlar.filter((i) => i.id > S.sonId);
    S.sonId = Math.max(S.sonId, enYeni);
    S.veri = v;
    if (yeniGelenler.length) {
        bip();
        bildir(`Yeni ihbar: ${yeniGelenler[0].yazi}`, 'hata');
    }
    ciz(new Set(yeniGelenler.map((i) => i.id)));
    S.ilkYukleme = false;
}

function ciz(yeniIdler = new Set()) {
    if (!S.veri) return;
    const ben = S.veri.ben;
    $('#memur').innerHTML = `Memur: <b>${e(ben.ad)}</b>`;
    $('#gorevDurum').innerHTML = ben.gorevde
        ? `<span class="nokta" style="background:var(--yesil)"></span>Görevde`
        : `<span class="nokta" style="background:var(--kirmizi)"></span>Görevde değilsin<br><small>İhbar almak ve üstlenmek için mesaiye gir.</small>`;
    const acikSayi = S.veri.ihbarlar.filter((i) => i.durum === 'yeni').length;
    $('#ihbarSayac').textContent = acikSayi;
    $('#ihbarSayac').classList.toggle('gizli', acikSayi === 0);

    if (S.sekme === 'ihbar') cizIhbarlar(yeniIdler);
    if (S.sekme === 'ekip') cizEkip();
}

function cizIhbarlar(yeniIdler) {
    const ben = S.veri.ben;
    const liste = S.veri.ihbarlar.filter((i) => {
        if (S.filtre === 'acik') return i.durum !== 'kapandi';
        if (S.filtre === 'benim') return i.ilgilenen === ben.ad && i.durum === 'ilgileniliyor';
        return true;
    });
    if (liste.length === 0) {
        $('#ihbarListe').innerHTML = `<div class="bos">${S.filtre === 'acik' ? 'Açık ihbar yok. Her şey sakin.' : 'Burada ihbar yok.'}</div>`;
        return;
    }
    $('#ihbarListe').innerHTML = liste.map((i) => {
        const benim = i.ilgilenen === ben.ad;
        let dugmeler = `<button class="birincil" data-gps="${i.id}">GPS</button>`;
        if (i.durum === 'yeni') dugmeler += `<button data-islem="ustlen" data-id="${i.id}">Üstlen</button>`;
        if (i.durum === 'ilgileniliyor' && benim) dugmeler += `<button data-islem="birak" data-id="${i.id}">Bırak</button>`;
        if (i.durum !== 'kapandi') dugmeler += `<button class="tehlike" data-islem="kapat" data-id="${i.id}">Kapat</button>`;
        else dugmeler += `<button data-islem="ac" data-id="${i.id}">Yeniden aç</button>`;
        let kim = '';
        if (i.durum === 'ilgileniliyor') kim = `<span>İlgilenen: <b>${e(i.ilgilenen)}</b></span>`;
        if (i.durum === 'kapandi' && i.kapatan) kim = `<span>Kapatan: ${e(i.kapatan)}</span>`;
        return `<div class="ihbar ${i.durum} ${yeniIdler.has(i.id) ? 'yeni-geldi' : ''}">
            <div class="ihbar-bilgi">
                <div><span class="durum ${i.durum}">${DURUM_YAZI[i.durum]}</span> <b>${e(i.yazi)}</b></div>
                <div class="sokak">${e(i.sokak || 'Bilinmeyen konum')}</div>
                <div class="alt">
                    <span>#${i.id}</span>
                    <span>${onceYazi(S.veri.simdi - i.zaman)}</span>
                    <span>Uzaklık: ${mesafe(ben, i)}</span>
                    ${kim}
                </div>
            </div>
            <div class="ihbar-dugmeler">${dugmeler}</div>
        </div>`;
    }).join('');
}

function cizEkip() {
    const ekip = S.veri.ekip;
    $('#ekipSayi').textContent = `${ekip.length} memur görevde`;
    $('#ekipListe').innerHTML = ekip.length === 0
        ? `<div class="bos">Şu an görevde kimse yok.</div>`
        : ekip.map((m, i) => `<div class="satir ${m.ben ? 'ben' : ''}">
            <div class="ad"><b>${e(m.ad)}${m.ben ? ' (sen)' : ''}</b><small>${e(m.birim)} · ${e(m.rutbe)}</small></div>
            <span class="mesafe">${m.ben ? '' : mesafe(S.veri.ben, m)}</span>
            ${m.ben ? '' : `<button data-ekip="${i}">GPS</button>`}
        </div>`).join('');
}

function cizKonumlar() {
    const ara = $('#konumAra').value.trim().toLocaleLowerCase('tr');
    const html = S.konumlar.map((k, ki) => {
        const yerler = k.liste.map((y, yi) => ({ y, yi })).filter(({ y }) => !ara || y.ad.toLocaleLowerCase('tr').includes(ara));
        if (!yerler.length) return '';
        return `<div class="kategori">${e(k.kategori)}</div>` + yerler.map(({ y, yi }) => `<div class="satir">
            <div class="ad"><b>${e(y.ad)}</b></div>
            <span class="mesafe">${mesafe(S.veri?.ben, y)}</span>
            <button data-konum="${ki}-${yi}">GPS</button>
        </div>`).join('');
    }).join('');
    $('#konumListe').innerHTML = html || `<div class="bos">Sonuç yok.</div>`;
}

// ================= Açma / kapama =================

function saatiGuncelle() {
    const d = new Date();
    $('#saat').textContent = `${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`;
}

function ac(veri) {
    S.konumlar = veri.konumlar || [];
    S.ilkYukleme = S.sonId === 0;
    $('#tablet').classList.remove('gizli');
    saatiGuncelle();
    clearInterval(S.saatZamanlayici);
    S.saatZamanlayici = setInterval(saatiGuncelle, 10000);
    yenile();
    clearInterval(S.zamanlayici);
    S.zamanlayici = setInterval(yenile, 3000);
    sekmeyeGec(S.sekme);
}

function kapat(bildirsin = true) {
    clearInterval(S.zamanlayici);
    clearInterval(S.saatZamanlayici);
    $('#tablet').classList.add('gizli');
    if (bildirsin) nui('kapat');
}

function sekmeyeGec(ad) {
    S.sekme = ad;
    $$('.yan button[data-sekme]').forEach((b) => b.classList.toggle('aktif', b.dataset.sekme === ad));
    $$('.sekme').forEach((s) => s.classList.toggle('gizli', s.id !== `sekme-${ad}`));
    if (ad === 'konum') cizKonumlar();
    else ciz();
}

// ================= Olaylar =================

window.addEventListener('message', (ev) => {
    const d = ev.data || {};
    if (d.islem === 'ac') ac(d);
    if (d.islem === 'kapat') kapat(false);
});

document.addEventListener('keydown', (ev) => {
    if (ev.key === 'Escape' && !$('#tablet').classList.contains('gizli')) kapat();
});

$('#kapatBtn').onclick = () => kapat();
$$('.yan button[data-sekme]').forEach((b) => (b.onclick = () => sekmeyeGec(b.dataset.sekme)));
$$('.filtre button').forEach((b) => (b.onclick = () => {
    S.filtre = b.dataset.filtre;
    $$('.filtre button').forEach((x) => x.classList.toggle('aktif', x === b));
    ciz();
}));
$('#konumAra').oninput = () => cizKonumlar();

$('#ihbarListe').onclick = async (ev) => {
    const gps = ev.target.closest('[data-gps]');
    if (gps) {
        const i = S.veri.ihbarlar.find((x) => x.id === Number(gps.dataset.gps));
        if (i) nui('gps', { x: i.x, y: i.y, ad: i.yazi });
        return;
    }
    const btn = ev.target.closest('[data-islem]');
    if (!btn) return;
    btn.disabled = true;
    const r = await nui('islem', { tip: btn.dataset.islem, id: Number(btn.dataset.id) });
    if (!r || !r.ok) bildir(r?.mesaj || 'İşlem yapılamadı.', 'hata');
    await yenile();
};

$('#ekipListe').onclick = (ev) => {
    const btn = ev.target.closest('[data-ekip]');
    const m = btn && S.veri.ekip[Number(btn.dataset.ekip)];
    if (m) nui('gps', { x: m.x, y: m.y, ad: m.ad });
};

$('#konumListe').onclick = (ev) => {
    const btn = ev.target.closest('[data-konum]');
    if (!btn) return;
    const [ki, yi] = btn.dataset.konum.split('-').map(Number);
    const y = S.konumlar[ki]?.liste[yi];
    if (y) nui('gps', { x: y.x, y: y.y, ad: y.ad });
};

if (!OYUNDA) {
    const s = document.createElement('script');
    s.src = 'onizleme.js';
    document.body.appendChild(s);
}
