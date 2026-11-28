'use strict';
// Endcore RP – NPC yönetim paneli (oyun içi sayfa)
// Sayfa oyundaki Lua koduyla "NUI callback" denen POST istekleriyle konuşur (bkz. client/panel.lua).

const OYUNDA = typeof GetParentResourceName === 'function';
const KAYNAK = OYUNDA ? GetParentResourceName() : 'endnpc';

const S = {
    ayar: null,          // config.lua'dan gelen listeler (modeller, silahlar, renkler…)
    veri: null,          // sunucudan gelen güncel durum
    sekme: 'npc',
    seciliNpc: new Set(),
    seciliGrup: new Set(),
    gorsel: { blip: false, etiket: false },
    zamanlayici: null,
    konum: null,         // düzenlenen NPC'nin / bölgenin / şablonun seçilen konumu
    rota: [],            // düzenlenen NPC'nin rota noktaları
    cekmeceKaydet: null,
    modalTamam: null,
    modalVazgec: null,
};

// ================= Yardımcılar =================

const $ = (s, k = document) => k.querySelector(s);
const $$ = (s, k = document) => [...k.querySelectorAll(s)];
const e = (v) => String(v ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const ara = (s) => String(s ?? '').toLocaleLowerCase('tr');

async function nui(ad, veri = {}) {
    if (!OYUNDA) return window.onizlemeNui ? window.onizlemeNui(ad, veri) : null;
    try {
        const yanit = await fetch(`https://${KAYNAK}/${ad}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(veri),
        });
        return await yanit.json();
    } catch {
        return null;
    }
}

// Sunucuya işlem gönderir. Başarılıysa sonucu, değilse null döner (ve hata bildirimi gösterir).
async function islem(tip, veri = {}, sessiz = false) {
    const r = await nui('islem', { tip, veri });
    if (!r) { if (!sessiz) bildir('Sunucuya ulaşılamadı.', 'hata'); return null; }
    if (!r.ok) { if (!sessiz) bildir(r.mesaj || 'İşlem başarısız.', 'hata'); return null; }
    return r.veri ?? true;
}

function bildir(yazi, tur = 'basari') {
    const el = document.createElement('div');
    el.className = `bildirim ${tur}`;
    el.textContent = yazi;
    $('#bildirimler').appendChild(el);
    setTimeout(() => el.remove(), tur === 'hata' ? 6000 : 3000);
}

const etiket = (liste, deger) => S.ayar.etiketler[liste]?.[deger] ?? deger;
const kisaEtiket = (liste, deger) => String(etiket(liste, deger)).split(' – ')[0];
const gruplar = () => Object.values(S.veri?.gruplar || {}).sort((a, b) => a.ad.localeCompare(b.ad, 'tr'));
const npcler = () => Object.values(S.veri?.npcler || {});
const grup = (id) => (S.veri?.gruplar || {})[id];
const silahEtiket = (ad) => S.ayar.silahlar.find((s) => s.ad === ad)?.etiket ?? ad;
const tumModeller = () => S.ayar.modeller.flatMap((k) => k.liste);
const sinir = (ad) => S.ayar.sinirlar[ad] || [0, 100];

function iliski(a, b) {
    if (a === b) return 'dost';
    const [x, y] = a < b ? [a, b] : [b, a];
    return (S.veri.iliskiler || {})[`${x}|${y}`] || 'tarafsiz';
}

function grupNpcSayisi(id) {
    let toplam = 0, canli = 0;
    for (const n of npcler()) {
        if (n.grup !== id) continue;
        toplam++;
        if (n.durumBilgi?.durum === 'canli') canli++;
    }
    return { toplam, canli };
}

// ================= Form oluşturucu =================
// Aynı alan tanımları hem tek kayıt düzenlemede hem toplu düzenlemede kullanılır.

const NPC_ALANLAR = [
    { ad: 'ad', etiket: 'Ad', tip: 'metin', uzunluk: 32, toplu: false },
    { ad: 'grup', etiket: 'Grup', tip: 'grup' },
    { ad: 'model', etiket: 'Model', tip: 'model', toplu: false },
    { ad: 'can', etiket: 'Can', tip: 'sayi', not: 'Normal bir insan ≈ 100–200. Zırh ayrıca eklenir.' },
    { ad: 'zirh', etiket: 'Zırh', tip: 'aralik' },
    { ad: 'ofke', etiket: 'Öfke', tip: 'ofke' },
    { ad: 'silah', etiket: 'Silah', tip: 'silah' },
    { ad: 'arac', etiket: 'Araç', tip: 'arac', not: 'NPC aracıyla doğar. Devriye / avcı araçla gezer, rota araçla sürülür, düşmanı araçla kovalar.' },
    { ad: 'davranis', etiket: 'Davranış', tip: 'secim', liste: 'davranis' },
    { ad: 'rota', etiket: 'Devriye rotası', tip: 'rota', toplu: false, not: 'Sadece "Rota" davranışında kullanılır. Noktaları sırayla ekle.' },
    { ad: 'konum', etiket: 'Doğduğu yer', tip: 'konum', toplu: false },
    { ad: 'aktif', etiket: 'Etkin (haritada bulunsun)', tip: 'onay' },
];

const BOLGE_ALANLAR = [
    { ad: 'ad', etiket: 'Bölge adı', tip: 'metin', uzunluk: 24 },
    { ad: 'grup', etiket: 'Koruyan grup', tip: 'grup', not: 'Bu grubun ve dostlarının bölgedeki NPC\'leri alarma geçer.' },
    { ad: 'konum', etiket: 'Bölgenin merkezi', tip: 'konum' },
    { ad: 'yaricap', etiket: 'Yarıçap', tip: 'aralik', birim: ' m' },
    { ad: 'alarmSuresi', etiket: 'Alarm süresi', tip: 'aralik', birim: ' sn', not: 'Davetsiz misafir bölgeden çıksa da bu kadar süre kovalanır.' },
    { ad: 'oyuncuAlarm', etiket: 'Oyuncular girince de saldırsınlar (grup oyunculara tarafsız olsa bile)', tip: 'onay' },
    { ad: 'aktif', etiket: 'Etkin', tip: 'onay' },
];

const GRUP_ALANLAR = [
    { ad: 'ad', etiket: 'Grup adı', tip: 'metin', uzunluk: 24, toplu: false },
    { ad: 'renk', etiket: 'Renk', tip: 'renk', toplu: false },
    { ad: 'oyuncuIliskisi', etiket: 'Oyunculara karşı', tip: 'secim', liste: 'iliski', not: '"Düşman" seçilirse bu grup oyunculara da saldırır.' },
    { ad: 'gorusMesafesi', etiket: 'Görüş mesafesi', tip: 'aralik', birim: ' m', not: 'Düşmanı bu mesafeden fark eder.' },
    { ad: 'saldiriMesafesi', etiket: 'Saldırı mesafesi', tip: 'aralik', birim: ' m', not: 'Düşman daha uzaktaysa önce yaklaşır.' },
    { ad: 'ofke', etiket: 'Öfke / agresiflik', tip: 'aralik', not: 'Yüksek öfke: kaçmaz, daha iyi dövüşür. 90 üstü gözü kara saldırır.' },
    { ad: 'saldiriSikligi', etiket: 'Saldırı sıklığı', tip: 'aralik', not: 'Ne kadar sık ateş eder.' },
    { ad: 'isabet', etiket: 'İsabet', tip: 'aralik', birim: '%' },
    { ad: 'hareket', etiket: 'Hareket tarzı', tip: 'secim', liste: 'hareket' },
    { ad: 'takipMesafesi', etiket: 'En fazla takip mesafesi', tip: 'aralik', birim: ' m', not: 'NPC yerinden bu kadar uzaklaşınca kovalamayı bırakıp geri döner (avcılar iki katı).' },
    { ad: 'dusukCanEsigi', etiket: 'Düşük can eşiği', tip: 'aralik', birim: '%', not: '0 = kapalı.' },
    { ad: 'dusukCanDavranisi', etiket: 'Canı eşiğin altına inince', tip: 'secim', liste: 'dusukCanDavranisi' },
];

const AYAR_ALANLAR = [
    { ad: 'maxNpc', etiket: 'Aynı anda en fazla NPC', tip: 'sayi', not: 'Performans için 40–60 arası önerilir.' },
    { ad: 'aiAralik', etiket: 'Yapay zeka aralığı (milisaniye)', tip: 'sayi', not: 'Küçük = daha hızlı tepki, daha çok işlemci.' },
    { ad: 'cesetSuresi', etiket: 'Ceset kalma süresi (saniye)', tip: 'sayi' },
    { ad: 'olumDavranisi', etiket: 'NPC ölünce', tip: 'secim', liste: 'olumDavranisi' },
    { ad: 'yenidenDogmaSuresi', etiket: 'Yeniden doğma süresi (saniye)', tip: 'sayi', not: 'Sadece "yeniden doğsun" seçiliyse.' },
];

function secenekler(liste, secili) {
    return S.ayar.secenekler[liste].map((d) => `<option value="${e(d)}" ${d === secili ? 'selected' : ''}>${e(etiket(liste, d))}</option>`).join('');
}

function konumYazi(k) {
    if (!k) return 'Konum seçilmedi';
    return `X ${k.x.toFixed(1)}  Y ${k.y.toFixed(1)}  Z ${k.z.toFixed(1)}  ·  Yön ${Math.round(k.h || 0)}°`;
}

function kontrolHtml(a, d) {
    const [min, max] = sinir(a.ad);
    switch (a.tip) {
        case 'metin':
            return `<input type="text" data-alan="${a.ad}" maxlength="${a.uzunluk || 32}" value="${e(d)}">`;
        case 'sayi':
            return `<input type="number" data-alan="${a.ad}" min="${min}" max="${max}" step="1" value="${e(d)}">`;
        case 'aralik':
            return `<input type="range" data-alan="${a.ad}" min="${min}" max="${max}" step="1" value="${e(d)}">`;
        case 'secim':
            return `<select data-alan="${a.ad}">${secenekler(a.liste, d)}</select>`;
        case 'grup':
            return `<select data-alan="grup">${gruplar().map((g) => `<option value="${e(g.id)}" ${g.id === d ? 'selected' : ''}>${e(g.ad)}</option>`).join('')}</select>`;
        case 'silah':
            return `<select data-alan="silah">${S.ayar.silahlar.map((s) => `<option value="${e(s.ad)}" ${s.ad === d ? 'selected' : ''}>${e(s.etiket)}</option>`).join('')}</select>`;
        case 'model': {
            const hazir = tumModeller().some((m) => m.ad === d);
            const gruplu = S.ayar.modeller.map((k) => `<optgroup label="${e(k.kategori)}">${k.liste.map((m) =>
                `<option value="${e(m.ad)}" ${m.ad === d ? 'selected' : ''}>${e(m.etiket)} (${e(m.ad)})</option>`).join('')}</optgroup>`).join('');
            return `<select data-alan="model">${gruplu}<option value="__ozel" ${hazir ? '' : 'selected'}>Başka model yaz…</option></select>
                <input type="text" data-alan="modelOzel" placeholder="ör. a_m_m_bevhills_01" value="${hazir ? '' : e(d)}" class="${hazir ? 'gizli' : ''}">
                <span class="not">Model adlarını docs.fivem.net/docs/game-references/ped-models adresinde bulabilirsin.</span>`;
        }
        case 'ofke': {
            const grubun = d === null || d === undefined;
            return `<label class="onay"><input type="checkbox" data-alan="ofkeGrup" ${grubun ? 'checked' : ''}> Grubun öfke ayarını kullan</label>
                <input type="range" data-alan="ofke" min="${min}" max="${max}" step="1" value="${grubun ? 50 : e(d)}" ${grubun ? 'disabled' : ''}>`;
        }
        case 'konum':
            return `<div class="konum-kutu ${S.konum ? 'var' : ''}" data-konum-yazi>${e(konumYazi(S.konum))}</div>
                <div class="dugmeler">
                    <button type="button" data-konum-btn="ben">Bulunduğum yer</button>
                    <button type="button" data-konum-btn="nisan">Nişan alarak seç</button>
                    <button type="button" data-konum-btn="waypoint">Harita işareti</button>
                </div>`;
        case 'arac': {
            const yok = !d;
            const hazir = yok || S.ayar.araclar.some((x) => x.ad === d);
            return `<select data-alan="arac">
                    <option value="" ${yok ? 'selected' : ''}>Yok (yaya)</option>
                    ${S.ayar.araclar.map((x) => `<option value="${e(x.ad)}" ${x.ad === d ? 'selected' : ''}>${e(x.etiket)} (${e(x.ad)})</option>`).join('')}
                    <option value="__ozel" ${hazir ? '' : 'selected'}>Başka araç yaz…</option>
                </select>
                <input type="text" data-alan="aracOzel" placeholder="ör. granger" value="${hazir ? '' : e(d)}" class="${hazir ? 'gizli' : ''}">`;
        }
        case 'rota': {
            const v = degerlerSon || {};
            return `<div class="rota-liste" data-rota-liste>${rotaListeHtml()}</div>
                <div class="dugmeler">
                    <button type="button" data-rota-btn="ben">+ Bulunduğum yer</button>
                    <button type="button" data-rota-btn="nisan">+ Nişan al</button>
                    <button type="button" data-rota-btn="waypoint">+ Harita işareti</button>
                    <button type="button" class="yazi" data-rota-btn="temizle">Temizle</button>
                </div>
                <div class="yan-yana">
                    <select data-alan="rotaTur">${secenekler('rotaTur', v.rotaTur || 'dongu')}</select>
                    <label class="onay" style="flex:0 0 auto">Her noktada bekle
                        <input type="number" data-alan="rotaBekleme" min="0" max="300" value="${e(v.rotaBekleme ?? 3)}" style="width:70px"> sn</label>
                </div>`;
        }
        case 'onay':
            return `<label class="onay"><input type="checkbox" data-alan="${a.ad}" ${d ? 'checked' : ''}> ${e(a.etiket)}</label>`;
        case 'renk':
            return `<div class="renkler" data-renkler data-deger="${e(d)}">${S.ayar.renkler.map((r) =>
                `<button type="button" title="${e(r.ad)}" data-renk="${e(r.hex)}" class="${r.hex === d ? 'secili' : ''}" style="background:${e(r.hex)}"></button>`).join('')}</div>`;
    }
    return '';
}

let degerlerSon = null;   // rota alanı rotaTur / rotaBekleme için bütün değerlere bakar

function rotaListeHtml() {
    if (S.rota.length === 0) return `<div class="konum-kutu">Henüz nokta yok</div>`;
    return S.rota.map((p, i) => `<div class="rota-nokta">
        <span class="sira">${i + 1}</span>
        <span class="mono">X ${p.x.toFixed(1)}  Y ${p.y.toFixed(1)}  Z ${p.z.toFixed(1)}</span>
        <button type="button" class="kucuk yazi" data-rota-sil="${i}" title="Noktayı sil">✕</button>
    </div>`).join('');
}

function formHtml(alanlar, degerler, toplu = false) {
    degerlerSon = degerler;
    return alanlar.filter((a) => !toplu || a.toplu !== false).map((a) => {
        const d = degerler[a.ad];
        const gosterge = a.tip === 'aralik' ? `<span class="deger" data-goster="${a.ad}">${e(d)}${e(a.birim || '')}</span>` : '';
        const ofkeGosterge = a.tip === 'ofke' ? `<span class="deger" data-goster="ofke">${d ?? 'grup'}</span>` : '';
        const secici = toplu ? `<input type="checkbox" class="toplu-sec" data-toplu="${a.ad}" title="Bunu değiştir">` : '';
        const baslik = a.tip === 'onay' && !toplu ? '' : `<div class="alan-baslik">${secici}${e(a.etiket)}${gosterge}${ofkeGosterge}</div>`;
        return `<div class="alan ${toplu ? 'kapali-alan' : ''}" data-kutu="${a.ad}" data-birim="${e(a.birim || '')}">
            ${baslik}${kontrolHtml(a, d)}${a.not && a.tip !== 'model' ? `<span class="not">${e(a.not)}</span>` : ''}
        </div>`;
    }).join('');
}

function konumuGoster(kap) {
    const yazi = $('[data-konum-yazi]', kap);
    if (!yazi) return;
    yazi.textContent = konumYazi(S.konum);
    yazi.classList.toggle('var', !!S.konum);
}

// Oyundan bir konum ister: 'ben' (bulunduğun yer), 'waypoint' (harita işareti), 'nisan' (nişan alarak)
async function konumIste(kap, tur) {
    let r;
    if (tur === 'ben') r = await nui('benimKonumum');
    else if (tur === 'waypoint') r = await nui('waypoint');
    else {
        // Nişan alırken önizlemede görünecek model: formdaki model, yoksa kutunun modeli, yoksa varsayılan
        const model = modelOku(kap) || kap.dataset.model || S.ayar.varsayilanNpc.model;
        if (!(await modelGecerliMi(model))) return null;
        r = await nui('konumSec', { model });
    }
    if (!r) { bildir('Konum alınamadı.', 'hata'); return null; }
    if (r.hata) { bildir(r.hata, 'hata'); return null; }
    return { x: r.x, y: r.y, z: r.z, h: r.h ?? 0 };
}

async function konumAl(kap, tur) {
    const k = await konumIste(kap, tur);
    if (!k) return;
    S.konum = k;
    konumuGoster(kap);
    bildir('Konum seçildi.', 'bilgi');
}

async function rotaIslemi(kap, tur) {
    if (tur === 'temizle') S.rota = [];
    else {
        if (S.rota.length >= S.ayar.rotaEnFazla) return bildir(`Bir rotada en fazla ${S.ayar.rotaEnFazla} nokta olabilir.`, 'hata');
        const k = await konumIste(kap, tur);
        if (!k) return;
        S.rota.push({ x: k.x, y: k.y, z: k.z });
        bildir(`${S.rota.length}. nokta eklendi.`, 'bilgi');
        // Rota eklenince davranışı otomatik "Rota" yap
        const dav = $('[data-alan="davranis"]', kap);
        if (dav && dav.value !== 'rota') dav.value = 'rota';
    }
    const liste = $('[data-rota-liste]', kap);
    if (liste) liste.innerHTML = rotaListeHtml();
}

function aracOku(kap) {
    const sec = $('[data-alan="arac"]', kap);
    if (!sec) return undefined;
    return sec.value === '__ozel' ? $('[data-alan="aracOzel"]', kap).value.trim().toLowerCase() : sec.value;
}

// Araç modelini oyunda kontrol eder, türünü (araba / motor) döner. Hata varsa null.
async function aracTuru(model) {
    if (!/^[a-z0-9_]{1,40}$/.test(model)) { bildir('Araç adı sadece harf, rakam ve _ içerebilir.', 'hata'); return null; }
    const r = await nui('aracDogrula', { model });
    if (!r) return 'automobile';
    if (r.hata) { bildir(`${model}: ${r.hata}`, 'hata'); return null; }
    return r.tur;
}

function modelOku(kap) {
    const sec = $('[data-alan="model"]', kap);
    if (!sec) return null;
    return sec.value === '__ozel' ? $('[data-alan="modelOzel"]', kap).value.trim().toLowerCase() : sec.value;
}

async function modelGecerliMi(model) {
    if (!/^[a-z0-9_]{1,40}$/.test(model)) { bildir('Model adı sadece harf, rakam ve _ içerebilir.', 'hata'); return false; }
    const var_ = await nui('modelDogrula', { model });
    if (var_ === false) { bildir(`"${model}" adında bir insan modeli oyunda yok.`, 'hata'); return false; }
    return true;
}

// Form içindeki etkileşimleri bağlar (kaydırıcı değeri, özel model, renk, toplu seçim, konum)
function formuBagla(kap) {
    kap.oninput = (ev) => {
        const el = ev.target;
        if (el.type === 'range') {
            const kutu = el.closest('.alan');
            const g = $(`[data-goster="${el.dataset.alan}"]`, kap);
            if (g) g.textContent = el.value + (el.dataset.alan === 'ofke' ? '' : (kutu?.dataset.birim || ''));
        }
    };
    kap.onchange = (ev) => {
        const el = ev.target;
        if (el.dataset.alan === 'model') $('[data-alan="modelOzel"]', kap).classList.toggle('gizli', el.value !== '__ozel');
        if (el.dataset.alan === 'arac') $('[data-alan="aracOzel"]', kap).classList.toggle('gizli', el.value !== '__ozel');
        if (el.dataset.alan === 'ofkeGrup') {
            const aralik = $('[data-alan="ofke"]', kap);
            aralik.disabled = el.checked;
            $('[data-goster="ofke"]', kap).textContent = el.checked ? 'grup' : aralik.value;
        }
        if (el.classList.contains('toplu-sec')) el.closest('.alan').classList.toggle('kapali-alan', !el.checked);
    };
    kap.onclick = (ev) => {
        const renk = ev.target.closest('[data-renk]');
        if (renk) {
            const kutu = renk.closest('[data-renkler]');
            kutu.dataset.deger = renk.dataset.renk;
            $$('[data-renk]', kutu).forEach((b) => b.classList.toggle('secili', b === renk));
        }
        const konumBtn = ev.target.closest('[data-konum-btn]');
        if (konumBtn) konumAl(kap, konumBtn.dataset.konumBtn);
        const rotaBtn = ev.target.closest('[data-rota-btn]');
        if (rotaBtn) rotaIslemi(kap, rotaBtn.dataset.rotaBtn);
        const rotaSil = ev.target.closest('[data-rota-sil]');
        if (rotaSil) {
            S.rota.splice(Number(rotaSil.dataset.rotaSil), 1);
            $('[data-rota-liste]', kap).innerHTML = rotaListeHtml();
        }
    };
}

// Formdaki değerleri okur. toplu ise sadece işaretlenen alanlar alınır.
function formuOku(kap, alanlar, toplu = false) {
    const sonuc = {};
    for (const a of alanlar) {
        if (toplu && (a.toplu === false || !$(`[data-toplu="${a.ad}"]`, kap)?.checked)) continue;
        const el = $(`[data-alan="${a.ad}"]`, kap);
        switch (a.tip) {
            case 'metin': sonuc[a.ad] = el.value; break;
            case 'sayi':
            case 'aralik': sonuc[a.ad] = Number(el.value); break;
            case 'secim':
            case 'grup':
            case 'silah': sonuc[a.ad] = el.value; break;
            case 'model': sonuc.model = modelOku(kap); break;
            case 'ofke':
                if ($('[data-alan="ofkeGrup"]', kap).checked) sonuc.ofkeGrup = true;
                else sonuc.ofke = Number(el.value);
                break;
            case 'konum': if (S.konum) Object.assign(sonuc, S.konum); break;
            case 'arac': sonuc.arac = aracOku(kap); break;
            case 'rota':
                sonuc.rota = S.rota.slice();
                sonuc.rotaTur = $('[data-alan="rotaTur"]', kap).value;
                sonuc.rotaBekleme = Number($('[data-alan="rotaBekleme"]', kap).value);
                break;
            case 'onay': sonuc[a.ad] = el.checked; break;
            case 'renk': sonuc.renk = $('[data-renkler]', kap).dataset.deger; break;
        }
    }
    return sonuc;
}

// ================= Çekmece ve pencere =================

function cekmeceAc(baslik, html, kaydet) {
    $('#cekmeceBaslik').textContent = baslik;
    const form = $('#cekmeceForm');
    form.innerHTML = html;
    formuBagla(form);
    S.cekmeceKaydet = kaydet;
    $('#cekmece').classList.remove('gizli');
    $('input[type=text]', form)?.focus();
}

function cekmeceKapat() {
    $('#cekmece').classList.add('gizli');
    $('#cekmeceForm').innerHTML = '';
    S.cekmeceKaydet = null;
}

function modalAc(baslik, html, tamam, { tamamYazi = 'Tamam', tehlike = false } = {}) {
    $('#modalBaslik').textContent = baslik;
    const ic = $('#modalIcerik');
    ic.innerHTML = html;
    formuBagla(ic);
    const btn = $('#modalTamam');
    btn.textContent = tamamYazi;
    btn.className = tehlike ? 'tehlike' : 'birincil';
    S.modalTamam = tamam;
    S.modalVazgec = null;
    $('#modal').classList.remove('gizli');
}

function modalKapat() {
    $('#modal').classList.add('gizli');
    $('#modalIcerik').innerHTML = '';
    delete $('#modalIcerik').dataset.model;
    S.modalTamam = null;
}

function onayla(baslik, html, tamamYazi = 'Evet', tehlike = true) {
    return new Promise((coz) => {
        modalAc(baslik, `<p>${html}</p>`, async () => { modalKapat(); coz(true); }, { tamamYazi, tehlike });
        S.modalVazgec = () => coz(false);
    });
}

// ================= Veri yenileme =================

async function yenile() {
    const v = await islem('getir', {}, true);
    if (!v) return;
    S.veri = v;
    // silinmiş kayıtları seçimden çıkar
    for (const id of S.seciliNpc) if (!v.npcler?.[id]) S.seciliNpc.delete(id);
    for (const id of S.seciliGrup) if (!v.gruplar?.[id]) S.seciliGrup.delete(id);
    ciz();
}

function ciz() {
    if (!S.veri) return;
    cizIstatistik();
    grupFiltresiniDoldur();
    if (S.sekme === 'npc') cizNpcler();
    if (S.sekme === 'grup') cizGruplar();
    if (S.sekme === 'iliski' && !$('#iliskiKap').contains(document.activeElement)) cizIliskiler();
    if (S.sekme === 'sablon') cizSablonlar();
    if (S.sekme === 'bolge') cizBolgeler();
}

function cizIstatistik() {
    const liste = npcler();
    const say = (d) => liste.filter((n) => n.durumBilgi?.durum === d).length;
    $('#istatistik').innerHTML = `
        <span>Haritada <b>${S.veri.aktif}</b> / ${S.veri.ayarlar.maxNpc}</span>
        <span>Canlı <b class="r-dost">${say('canli')}</b></span>
        <span>Ölü <b class="r-dusman">${say('olu')}</b></span>
        <span>Kayıtlı <b>${liste.length}</b></span>
        <span>Grup <b>${gruplar().length}</b></span>`;
}

// ================= NPC sekmesi =================

function grupFiltresiniDoldur() {
    const sec = $('#npcGrupFiltre');
    const eski = sec.value;
    const html = `<option value="">Tüm gruplar</option>` + gruplar().map((g) => `<option value="${e(g.id)}">${e(g.ad)}</option>`).join('');
    if (sec.dataset.html !== html) {
        sec.innerHTML = html;
        sec.dataset.html = html;
        sec.value = grup(eski) ? eski : '';
    }
}

function durumHtml(n) {
    const b = n.durumBilgi || {};
    switch (b.durum) {
        case 'canli': {
            if (b.can === undefined || b.can === null) return `<span class="rozet canli">Canlı</span> <span class="soluk">uzakta</span>`;
            const yuzde = Math.max(0, Math.min(100, Math.round(b.can / n.can * 100)));
            return `<span class="rozet canli">Canlı</span> <span class="can-cubuk"><i style="width:${yuzde}%"></i></span> <span class="soluk">${b.can}/${n.can}</span>`;
        }
        case 'olu': return `<span class="rozet olu">Öldü</span> <span class="soluk">ceset ${b.kalan} sn</span>`;
        case 'bekliyor': return `<span class="rozet bekliyor">Doğacak</span> <span class="soluk">${b.kalan} sn</span>`;
        case 'doguyor': return `<span class="rozet doguyor">Doğuyor…</span>`;
        case 'kapali': return `<span class="rozet">Kapalı</span>`;
        default: return `<span class="rozet hata" title="${e(b.mesaj)}">Hata</span> <span class="soluk">${e(b.mesaj)}</span>`;
    }
}

function filtrelenmisNpcler() {
    const metin = ara($('#npcAra').value.trim());
    const gf = $('#npcGrupFiltre').value;
    const df = $('#npcDurumFiltre').value;
    return npcler().filter((n) => {
        if (gf && n.grup !== gf) return false;
        if (df && (n.durumBilgi?.durum || 'hata') !== df) return false;
        if (metin && !ara(`${n.ad} ${n.model} ${silahEtiket(n.silah)} ${grup(n.grup)?.ad}`).includes(metin)) return false;
        return true;
    }).sort((a, b) => (grup(a.grup)?.ad || '').localeCompare(grup(b.grup)?.ad || '', 'tr') || a.ad.localeCompare(b.ad, 'tr'));
}

function cizNpcler() {
    const liste = filtrelenmisNpcler();
    $('#npcListe').innerHTML = liste.map((n) => {
        const g = grup(n.grup);
        const secili = S.seciliNpc.has(n.id);
        return `<tr data-id="${e(n.id)}" class="${secili ? 'secili' : ''}">
            <td><input type="checkbox" data-sec ${secili ? 'checked' : ''}></td>
            <td><b>${e(n.ad)}</b></td>
            <td><span class="grup-etiket"><i class="nokta" style="background:${e(g?.renk)}"></i>${e(g?.ad || '—')}</span></td>
            <td class="mono">${e(n.model)}</td>
            <td>${e(silahEtiket(n.silah))}</td>
            <td>${e(kisaEtiket('davranis', n.davranis))}${n.davranis === 'rota' ? ` <span class="soluk">(${(n.rota || []).length} nokta)</span>` : ''}
                ${n.arac ? `<div class="soluk kucuk-yazi">Araç: ${e(n.arac)}</div>` : ''}</td>
            <td>${durumHtml(n)}</td>
            <td class="sag"><div class="islemler">
                <button class="kucuk" data-islem="duzenle">Düzenle</button>
                <button class="kucuk" data-islem="isinlan" title="Yanına ışınlan">Işınlan</button>
                <button class="kucuk" data-islem="dogur" title="Yeniden doğur (canı dolar)">Doğur</button>
                <button class="kucuk tehlike" data-islem="sil">Sil</button>
            </div></td>
        </tr>`;
    }).join('');

    const hic = npcler().length === 0;
    $('#npcBos').classList.toggle('gizli', !hic);
    $('.tablo', $('#sekme-npc')).classList.toggle('gizli', hic);
    $('#npcHepsiniSec').checked = liste.length > 0 && liste.every((n) => S.seciliNpc.has(n.id));
    topluCubuguGuncelle();
}

function topluCubuguGuncelle() {
    const sayi = S.seciliNpc.size;
    $('#npcTopluCubuk').classList.toggle('gizli', sayi === 0);
    $('#npcSeciliYazi').textContent = `${sayi} NPC seçili`;
}

function npcCekmece(n) {
    if (gruplar().length === 0) return bildir('Önce Gruplar sekmesinden bir grup oluştur.', 'hata');
    const yeni = !n;
    const v = n ? { ...n } : { ...S.ayar.varsayilanNpc, grup: $('#npcGrupFiltre').value || gruplar()[0].id, ad: `NPC ${npcler().length + 1}` };
    S.konum = n ? { x: n.x, y: n.y, z: n.z, h: n.h } : null;
    S.rota = Array.isArray(n?.rota) ? n.rota.map((p) => ({ ...p })) : [];

    cekmeceAc(yeni ? 'Yeni NPC' : `Düzenle: ${n.ad}`, formHtml(NPC_ALANLAR, v), async () => {
        const kap = $('#cekmeceForm');
        const veri = formuOku(kap, NPC_ALANLAR);
        if (!veri.model) return bildir('Bir model seç.', 'hata');
        if (!S.konum) return bildir('Önce bir konum seç.', 'hata');
        if (veri.davranis === 'rota' && veri.rota.length === 0) return bildir('Rota davranışı için en az bir rota noktası ekle.', 'hata');
        if (!(await modelGecerliMi(veri.model))) return;
        if (veri.arac) {
            veri.aracTur = await aracTuru(veri.arac);
            if (!veri.aracTur) return;
        }
        if (n) veri.id = n.id;
        const sonuc = await islem('npcKaydet', veri);
        if (sonuc === null) return;
        bildir(yeni ? 'NPC oluşturuldu.' : 'NPC güncellendi.');
        cekmeceKapat();
        yenile();
    });

    // Yeni NPC'de varsayılan konum: bulunduğun yer
    if (yeni) konumAl($('#cekmeceForm'), 'ben');
}

async function npcIslemi(tip, ids, mesaj) {
    const sonuc = await islem(tip, { ids });
    if (sonuc !== null && mesaj) bildir(mesaj);
    yenile();
    return sonuc;
}

async function npcSatirIslemi(id, tur) {
    const n = S.veri.npcler[id];
    if (!n) return;
    if (tur === 'duzenle') npcCekmece(n);
    if (tur === 'dogur') npcIslemi('npcYenidenDogur', [id], `${n.ad} yeniden doğuyor.`);
    if (tur === 'sil' && await onayla('NPC silinsin mi?', `<b>${e(n.ad)}</b> kalıcı olarak silinecek.`, 'Sil')) {
        S.seciliNpc.delete(id);
        npcIslemi('npcSil', [id], 'NPC silindi.');
    }
    if (tur === 'isinlan') {
        const k = await islem('konumGetir', { id });
        if (k) nui('isinlan', k);
    }
}

function topluNpcDuzenle() {
    const ids = [...S.seciliNpc];
    const ilk = S.veri.npcler[ids[0]];
    modalAc(`Toplu düzenle (${ids.length} NPC)`,
        `<p>Değiştirmek istediğin alanların yanındaki kutuyu işaretle. İşaretsiz alanlar olduğu gibi kalır.</p>
         <div class="form">${formHtml(NPC_ALANLAR, ilk, true)}</div>`,
        async () => {
            const alanlar = formuOku($('#modalIcerik'), NPC_ALANLAR, true);
            if (Object.keys(alanlar).length === 0) return bildir('Değiştirilecek en az bir alan işaretle.', 'hata');
            if (alanlar.arac) {
                alanlar.aracTur = await aracTuru(alanlar.arac);
                if (!alanlar.aracTur) return;
            }
            const sonuc = await islem('npcTopluDuzenle', { ids, alanlar });
            modalKapat();
            if (sonuc !== null) bildir(`${sonuc} NPC güncellendi.`);
            yenile();
        }, { tamamYazi: 'Uygula' });
}

// ================= Grup sekmesi =================

function cizGruplar() {
    const liste = gruplar();
    $('#grupListe').innerHTML = liste.length === 0
        ? `<div class="bos"><p>Henüz grup yok.</p></div>`
        : liste.map((g) => {
            const s = grupNpcSayisi(g.id);
            const secili = S.seciliGrup.has(g.id);
            const dusmanlar = liste.filter((o) => o.id !== g.id && iliski(g.id, o.id) === 'dusman').map((o) => o.ad);
            return `<div class="kart ${secili ? 'secili' : ''}" data-id="${e(g.id)}" style="--renk:${e(g.renk)}">
                <div class="kart-ust">
                    <input type="checkbox" data-sec ${secili ? 'checked' : ''}>
                    <i class="nokta" style="background:${e(g.renk)}"></i>
                    <h3>${e(g.ad)}</h3>
                    <span class="soluk">${s.canli}/${s.toplam} NPC</span>
                </div>
                <div class="kart-bilgi">
                    <span>Oyunculara: <b class="r-${e(g.oyuncuIliskisi)}">${e(etiket('iliski', g.oyuncuIliskisi))}</b></span>
                    <span>Hareket: <b>${e(kisaEtiket('hareket', g.hareket))}</b></span>
                    <span>Görüş: <b>${g.gorusMesafesi} m</b></span>
                    <span>Saldırı: <b>${g.saldiriMesafesi} m</b></span>
                    <span>Öfke: <b>${g.ofke}</b></span>
                    <span>İsabet: <b>${g.isabet}%</b></span>
                    <span style="grid-column: 1 / -1">Düşmanları: <b class="r-dusman">${dusmanlar.length ? e(dusmanlar.join(', ')) : '<span class="soluk">yok</span>'}</b></span>
                </div>
                <div class="kart-alt">
                    <button class="kucuk" data-islem="npcler">NPC'leri</button>
                    <button class="kucuk" data-islem="duzenle">Düzenle</button>
                    <button class="kucuk tehlike" data-islem="sil">Sil</button>
                </div>
            </div>`;
        }).join('');
    $('#grupTopluDuzenleBtn').disabled = S.seciliGrup.size === 0;
}

function grupCekmece(g) {
    const yeni = !g;
    const v = g ? { ...g } : { ...S.ayar.varsayilanGrup };
    cekmeceAc(yeni ? 'Yeni grup' : `Grup: ${g.ad}`, formHtml(GRUP_ALANLAR, v), async () => {
        const veri = formuOku($('#cekmeceForm'), GRUP_ALANLAR);
        if (g) veri.id = g.id;
        if (await islem('grupKaydet', veri) === null) return;
        bildir(yeni ? 'Grup oluşturuldu.' : 'Grup güncellendi.');
        cekmeceKapat();
        yenile();
    });
}

function grupSil(g) {
    const s = grupNpcSayisi(g.id);
    const digerleri = gruplar().filter((o) => o.id !== g.id);
    let html = `<p><b>${e(g.ad)}</b> grubu silinecek.</p>`;
    if (s.toplam > 0) {
        html += `<p>Bu grupta <b>${s.toplam}</b> NPC var. Onlara ne olsun?</p>
            <label class="onay"><input type="radio" name="npcIslem" value="sil" checked> NPC'leri de sil</label>
            ${digerleri.length ? `<label class="onay"><input type="radio" name="npcIslem" value="tasi"> Başka gruba taşı:
                <select id="tasimaHedef">${digerleri.map((o) => `<option value="${e(o.id)}">${e(o.ad)}</option>`).join('')}</select></label>` : ''}`;
    }
    modalAc('Grup silinsin mi?', html, async () => {
        const secim = $('input[name=npcIslem]:checked', $('#modalIcerik'));
        const veri = { id: g.id, npcIslem: secim ? secim.value : 'sil', hedef: $('#tasimaHedef')?.value };
        const sonuc = await islem('grupSil', veri);
        modalKapat();
        if (sonuc !== null) { S.seciliGrup.delete(g.id); bildir('Grup silindi.'); }
        yenile();
    }, { tamamYazi: 'Sil', tehlike: true });
}

function topluGrupDuzenle() {
    const ids = [...S.seciliGrup];
    modalAc(`Toplu düzenle (${ids.length} grup)`,
        `<p>İşaretlediğin ayarlar seçili bütün gruplara uygulanır.</p>
         <div class="form">${formHtml(GRUP_ALANLAR, grup(ids[0]), true)}</div>`,
        async () => {
            const alanlar = formuOku($('#modalIcerik'), GRUP_ALANLAR, true);
            if (Object.keys(alanlar).length === 0) return bildir('Değiştirilecek en az bir alan işaretle.', 'hata');
            const sonuc = await islem('grupTopluDuzenle', { ids, alanlar });
            modalKapat();
            if (sonuc !== null) bildir(`${sonuc} grup güncellendi.`);
            yenile();
        }, { tamamYazi: 'Uygula' });
}

// ================= İlişkiler sekmesi =================

function cizIliskiler() {
    const liste = gruplar();
    const kap = $('#iliskiKap');
    if (liste.length === 0) { kap.innerHTML = `<div class="bos"><p>Önce grup oluştur.</p></div>`; return; }
    const secim = (deger, attr) => `<select class="${deger}" ${attr}>${secenekler('iliski', deger)}</select>`;
    kap.innerHTML = `<table class="tablo matris">
        <thead><tr><th></th>${liste.map((g) => `<th><span class="grup-etiket"><i class="nokta" style="background:${e(g.renk)}"></i>${e(g.ad)}</span></th>`).join('')}
            <th class="oyuncu-sutun">Oyuncular</th></tr></thead>
        <tbody>${liste.map((a) => `<tr>
            <th class="satir"><span class="grup-etiket"><i class="nokta" style="background:${e(a.renk)}"></i>${e(a.ad)}</span></th>
            ${liste.map((b) => a.id === b.id
                ? `<td class="kendi">—</td>`
                : `<td>${secim(iliski(a.id, b.id), `data-a="${e(a.id)}" data-b="${e(b.id)}"`)}</td>`).join('')}
            <td class="oyuncu-sutun">${secim(a.oyuncuIliskisi, `data-oyuncu="${e(a.id)}"`)}</td>
        </tr>`).join('')}</tbody>
    </table>`;
}

async function iliskiDegisti(sel) {
    sel.className = sel.value;
    let sonuc;
    if (sel.dataset.oyuncu) sonuc = await islem('grupKaydet', { id: sel.dataset.oyuncu, oyuncuIliskisi: sel.value });
    else sonuc = await islem('iliskiAyarla', { a: sel.dataset.a, b: sel.dataset.b, deger: sel.value });
    if (sonuc !== null) bildir('İlişki güncellendi.', 'bilgi');
    sel.blur();
    await yenile();
    cizIliskiler();
}

// ================= Şablonlar sekmesi =================

const sablonlar = () => Object.values(S.veri?.sablonlar || {}).sort((a, b) => a.ad.localeCompare(b.ad, 'tr'));

function cizSablonlar() {
    const liste = sablonlar();
    $('#sablonListe').innerHTML = liste.length === 0
        ? `<div class="bos"><p>Henüz şablon yok. NPC'ler sekmesinde NPC seçip "Şablon olarak kaydet" diyebilirsin.</p></div>`
        : liste.map((s) => {
            const uyeler = s.uyeler || [];
            const aracli = uyeler.filter((u) => u.arac).length;
            return `<div class="kart" data-id="${e(s.id)}">
                <div class="kart-ust"><h3>${e(s.ad)}</h3><span class="soluk">${uyeler.length} NPC</span></div>
                <div class="soluk">${e(s.aciklama || '')}</div>
                <div class="uye-listesi">${uyeler.map((u) =>
                    `<span class="uye">${e(u.ad || 'NPC')} · ${e(silahEtiket(u.silah))}${u.arac ? ` · ${e(u.arac)}` : ''}</span>`).join('')}</div>
                ${aracli ? `<div class="soluk kucuk-yazi">${aracli} NPC araçlı</div>` : ''}
                <div class="kart-alt">
                    <button class="kucuk tehlike" data-islem="sil">Sil</button>
                    <button class="kucuk" data-islem="duzenle">Adını değiştir</button>
                    <button class="kucuk birincil" data-islem="yerlestir">Yerleştir</button>
                </div>
            </div>`;
        }).join('');
}

function sablonYerlestir(s) {
    if (gruplar().length === 0) return bildir('Önce bir grup oluştur.', 'hata');
    const ilkModel = s.uyeler?.[0]?.model;
    S.konum = null;
    modalAc(`Yerleştir: ${s.ad}`,
        `<p><b>${(s.uyeler || []).length}</b> NPC seçtiğin konuma, baktığın yöne doğru dizilecek.</p>
         <div class="form">
            ${formHtml([
                { ad: 'grup', etiket: 'Hangi gruba katılsınlar?', tip: 'grup' },
                { ad: 'onEk', etiket: 'İsim ön eki (isteğe bağlı, ör. "Kuzey")', tip: 'metin', uzunluk: 16 },
                { ad: 'konum', etiket: 'Konum ve yön', tip: 'konum' },
            ], { grup: $('#npcGrupFiltre').value || gruplar()[0].id, onEk: '' })}
         </div>`,
        async () => {
            if (!S.konum) return bildir('Önce bir konum seç.', 'hata');
            const kap = $('#modalIcerik');
            const sonuc = await islem('sablonYerlestir', {
                id: s.id, grup: $('[data-alan="grup"]', kap).value, onEk: $('[data-alan="onEk"]', kap).value, ...S.konum,
            });
            if (sonuc === null) return;
            modalKapat();
            bildir(`${sonuc} NPC yerleştirildi.`);
            yenile();
        }, { tamamYazi: 'Yerleştir' });
    if (ilkModel) $('#modalIcerik').dataset.model = ilkModel;
    konumAl($('#modalIcerik'), 'ben');
}

function sablonDuzenle(s) {
    modalAc('Şablonu düzenle',
        `<div class="form">${formHtml([
            { ad: 'ad', etiket: 'Ad', tip: 'metin', uzunluk: 32 },
            { ad: 'aciklama', etiket: 'Açıklama', tip: 'metin', uzunluk: 80 },
        ], s)}</div>`,
        async () => {
            const kap = $('#modalIcerik');
            const sonuc = await islem('sablonDuzenle', { id: s.id, ad: $('[data-alan="ad"]', kap).value, aciklama: $('[data-alan="aciklama"]', kap).value });
            if (sonuc === null) return;
            modalKapat();
            bildir('Şablon güncellendi.');
            yenile();
        }, { tamamYazi: 'Kaydet' });
}

function seciliNpclerdenSablon() {
    const ids = [...S.seciliNpc];
    modalAc(`Şablon olarak kaydet (${ids.length} NPC)`,
        `<p>Seçili NPC'lerin modeli, silahı, davranışı, aracı ve <b>birbirine göre dizilişi</b> kaydedilir.
            Konumlar ilk NPC'ye göre tutulur, böylece şablon her yere aynı düzende kurulur.</p>
         <div class="form">${formHtml([
            { ad: 'ad', etiket: 'Şablon adı', tip: 'metin', uzunluk: 32 },
            { ad: 'aciklama', etiket: 'Açıklama (isteğe bağlı)', tip: 'metin', uzunluk: 80 },
        ], { ad: '', aciklama: '' })}</div>`,
        async () => {
            const kap = $('#modalIcerik');
            const ad = $('[data-alan="ad"]', kap).value.trim();
            if (!ad) return bildir('Şablona bir ad ver.', 'hata');
            const sonuc = await islem('sablonOlustur', { ids, ad, aciklama: $('[data-alan="aciklama"]', kap).value });
            if (sonuc === null) return;
            modalKapat();
            bildir('Şablon kaydedildi. Şablonlar sekmesinden yerleştirebilirsin.');
            yenile();
        }, { tamamYazi: 'Kaydet' });
}

// ================= Bölgeler sekmesi =================

const bolgeler = () => Object.values(S.veri?.bolgeler || {}).sort((a, b) => a.ad.localeCompare(b.ad, 'tr'));

function bolgedekiNpcSayisi(b) {
    let sayi = 0;
    for (const n of npcler()) {
        if (n.grup !== b.grup) continue;
        const k = n.durumBilgi?.konum || n;
        if (Math.hypot(k.x - b.x, k.y - b.y) <= b.yaricap) sayi++;
    }
    return sayi;
}

function cizBolgeler() {
    const liste = bolgeler();
    $('#bolgeListe').innerHTML = liste.length === 0
        ? `<div class="bos"><p>Henüz bölge yok.</p></div>`
        : liste.map((b) => {
            const g = grup(b.grup);
            const dostlar = gruplar().filter((o) => o.id !== b.grup && iliski(b.grup, o.id) === 'dost').map((o) => o.ad);
            const dusmanlar = gruplar().filter((o) => o.id !== b.grup && iliski(b.grup, o.id) === 'dusman').map((o) => o.ad);
            return `<div class="kart" data-id="${e(b.id)}" style="--renk:${e(g?.renk)}">
                <div class="kart-ust">
                    <i class="nokta" style="background:${e(g?.renk)}"></i>
                    <h3>${e(b.ad)}</h3>
                    ${b.aktif ? '<span class="rozet canli">Etkin</span>' : '<span class="rozet">Kapalı</span>'}
                </div>
                <div class="kart-bilgi">
                    <span>Koruyan: <b>${e(g?.ad || '—')}</b></span>
                    <span>Yarıçap: <b>${b.yaricap} m</b></span>
                    <span>İçindeki NPC: <b>${bolgedekiNpcSayisi(b)}</b></span>
                    <span>Alarm: <b>${b.alarmSuresi} sn</b></span>
                    <span style="grid-column: 1 / -1">Saldırdığı: <b class="r-dusman">${e([...dusmanlar, ...((g?.oyuncuIliskisi === 'dusman' || b.oyuncuAlarm) ? ['oyuncular'] : [])].join(', ') || 'kimse (düşman grup yok)')}</b></span>
                    ${dostlar.length ? `<span style="grid-column: 1 / -1">Yardıma gelen dostlar: <b class="r-dost">${e(dostlar.join(', '))}</b></span>` : ''}
                </div>
                <div class="kart-alt">
                    <button class="kucuk tehlike" data-islem="sil">Sil</button>
                    <button class="kucuk" data-islem="isinlan">Işınlan</button>
                    <button class="kucuk" data-islem="duzenle">Düzenle</button>
                </div>
            </div>`;
        }).join('');
}

function bolgeCekmece(b) {
    if (gruplar().length === 0) return bildir('Önce bir grup oluştur.', 'hata');
    const yeni = !b;
    const v = b ? { ...b } : { ...S.ayar.varsayilanBolge, grup: gruplar()[0].id, ad: `Bölge ${bolgeler().length + 1}` };
    S.konum = b ? { x: b.x, y: b.y, z: b.z, h: 0 } : null;
    cekmeceAc(yeni ? 'Yeni bölge' : `Bölge: ${b.ad}`, formHtml(BOLGE_ALANLAR, v), async () => {
        const veri = formuOku($('#cekmeceForm'), BOLGE_ALANLAR);
        if (!S.konum) return bildir('Bölgenin merkezini seç.', 'hata');
        delete veri.h;
        if (b) veri.id = b.id;
        if (await islem('bolgeKaydet', veri) === null) return;
        bildir(yeni ? 'Bölge oluşturuldu.' : 'Bölge güncellendi.');
        cekmeceKapat();
        yenile();
    });
    if (yeni) konumAl($('#cekmeceForm'), 'ben');
}

// ================= Ayarlar sekmesi =================

function cizAyarlar() {
    const kap = $('#ayarForm');
    kap.innerHTML = formHtml(AYAR_ALANLAR, S.veri.ayarlar);
    formuBagla(kap);
    $('#gorselBlip').checked = S.gorsel.blip;
    $('#gorselEtiket').checked = S.gorsel.etiket;
    $('#gorselBolge').checked = !!S.gorsel.bolge;
}

// ================= Sekme / açma / kapama =================

function sekmeyeGec(ad) {
    S.sekme = ad;
    $$('.sekmeler button').forEach((b) => b.classList.toggle('aktif', b.dataset.sekme === ad));
    $$('.sekme').forEach((s) => s.classList.toggle('gizli', s.id !== `sekme-${ad}`));
    if (!S.veri) return;
    if (ad === 'iliski') cizIliskiler();
    if (ad === 'ayar') cizAyarlar();
    ciz();
}

function ac(veri) {
    S.ayar = veri.ayar;
    S.gorsel = veri.gorsel || S.gorsel;
    document.body.classList.remove('sakli');
    $('#panel').classList.remove('gizli');
    yenile().then(() => sekmeyeGec(S.sekme));
    clearInterval(S.zamanlayici);
    S.zamanlayici = setInterval(yenile, 2000);   // durumlar (can, ölüm) canlı güncellensin
}

function kapat(sunucuyaBildir = true) {
    clearInterval(S.zamanlayici);
    cekmeceKapat();
    modalKapat();
    $('#panel').classList.add('gizli');
    if (sunucuyaBildir) nui('kapat');
}

window.addEventListener('message', (ev) => {
    const d = ev.data || {};
    if (d.islem === 'ac') ac(d);
    if (d.islem === 'kapat') kapat(false);
    if (d.islem === 'gizle') document.body.classList.add('sakli');
    if (d.islem === 'goster') document.body.classList.remove('sakli');
});

document.addEventListener('keydown', (ev) => {
    if (ev.key !== 'Escape' || $('#panel').classList.contains('gizli')) return;
    if (!$('#modal').classList.contains('gizli')) { S.modalVazgec?.(); S.modalVazgec = null; modalKapat(); }
    else if (!$('#cekmece').classList.contains('gizli')) cekmeceKapat();
    else kapat();
});

// ================= Olay bağlantıları =================

$$('.sekmeler button').forEach((b) => (b.onclick = () => sekmeyeGec(b.dataset.sekme)));
$('#kapatBtn').onclick = () => kapat();

$$('[data-kapat]').forEach((b) => (b.onclick = () => {
    if (b.dataset.kapat === 'modal') { S.modalVazgec?.(); S.modalVazgec = null; modalKapat(); }
    else cekmeceKapat();
}));
$('#cekmeceKaydet').onclick = async (ev) => {
    if (!S.cekmeceKaydet) return;
    ev.target.disabled = true;
    try { await S.cekmeceKaydet(); } finally { ev.target.disabled = false; }
};
$('#modalTamam').onclick = async (ev) => {
    if (!S.modalTamam) return;
    S.modalVazgec = null;
    ev.target.disabled = true;
    try { await S.modalTamam(); } finally { ev.target.disabled = false; }
};

// NPC sekmesi
['#npcAra', '#npcGrupFiltre', '#npcDurumFiltre'].forEach((s) => ($(s).oninput = () => cizNpcler()));
$('#yeniNpcBtn').onclick = () => npcCekmece(null);
$('#ilkNpcBtn').onclick = () => npcCekmece(null);

$('#npcListe').onclick = (ev) => {
    const satir = ev.target.closest('tr[data-id]');
    if (!satir) return;
    const id = satir.dataset.id;
    if (ev.target.matches('[data-sec]')) {
        ev.target.checked ? S.seciliNpc.add(id) : S.seciliNpc.delete(id);
        satir.classList.toggle('secili', ev.target.checked);
        $('#npcHepsiniSec').checked = filtrelenmisNpcler().every((n) => S.seciliNpc.has(n.id));
        topluCubuguGuncelle();
        return;
    }
    const btn = ev.target.closest('[data-islem]');
    if (btn) npcSatirIslemi(id, btn.dataset.islem);
};
$('#npcListe').ondblclick = (ev) => {
    const satir = ev.target.closest('tr[data-id]');
    if (satir && !ev.target.closest('button, input')) npcSatirIslemi(satir.dataset.id, 'duzenle');
};
$('#npcHepsiniSec').onchange = (ev) => {
    for (const n of filtrelenmisNpcler()) ev.target.checked ? S.seciliNpc.add(n.id) : S.seciliNpc.delete(n.id);
    cizNpcler();
};
$('#npcSecimTemizleBtn').onclick = () => { S.seciliNpc.clear(); cizNpcler(); };
$('#npcTopluDuzenleBtn').onclick = () => topluNpcDuzenle();
$('#npcTopluDogurBtn').onclick = () => npcIslemi('npcYenidenDogur', [...S.seciliNpc], 'Seçili NPC\'ler yeniden doğuyor.');
$('#npcTopluAcBtn').onclick = async () => {
    const sonuc = await islem('npcTopluDuzenle', { ids: [...S.seciliNpc], alanlar: { aktif: true } });
    if (sonuc !== null) bildir(`${sonuc} NPC etkinleştirildi.`);
    yenile();
};
$('#npcTopluKapatBtn').onclick = async () => {
    const sonuc = await islem('npcTopluDuzenle', { ids: [...S.seciliNpc], alanlar: { aktif: false } });
    if (sonuc !== null) bildir(`${sonuc} NPC devre dışı.`);
    yenile();
};
$('#npcTopluSilBtn').onclick = async () => {
    const ids = [...S.seciliNpc];
    if (!(await onayla('Seçili NPC\'ler silinsin mi?', `<b>${ids.length}</b> NPC kalıcı olarak silinecek.`, 'Hepsini sil'))) return;
    S.seciliNpc.clear();
    npcIslemi('npcSil', ids, `${ids.length} NPC silindi.`);
};

// Grup sekmesi
$('#yeniGrupBtn').onclick = () => grupCekmece(null);
$('#grupTopluDuzenleBtn').onclick = () => topluGrupDuzenle();
$('#grupListe').onclick = (ev) => {
    const kart = ev.target.closest('.kart[data-id]');
    if (!kart) return;
    const g = grup(kart.dataset.id);
    if (!g) return;
    if (ev.target.matches('[data-sec]')) {
        ev.target.checked ? S.seciliGrup.add(g.id) : S.seciliGrup.delete(g.id);
        kart.classList.toggle('secili', ev.target.checked);
        $('#grupTopluDuzenleBtn').disabled = S.seciliGrup.size === 0;
        return;
    }
    const tur = ev.target.closest('[data-islem]')?.dataset.islem;
    if (tur === 'duzenle') grupCekmece(g);
    if (tur === 'sil') grupSil(g);
    if (tur === 'npcler') {
        $('#npcGrupFiltre').value = g.id;
        sekmeyeGec('npc');
    }
};

// İlişkiler
$('#iliskiKap').onchange = (ev) => { if (ev.target.tagName === 'SELECT') iliskiDegisti(ev.target); };

// Ayarlar
$('#ayarKaydetBtn').onclick = async () => {
    const veri = formuOku($('#ayarForm'), AYAR_ALANLAR);
    if (await islem('ayarKaydet', veri) === null) return;
    bildir('Ayarlar kaydedildi.');
    await yenile();
    cizAyarlar();
};
$('#gorselBlip').onchange = (ev) => { S.gorsel.blip = ev.target.checked; nui('gorsel', S.gorsel); };
$('#gorselEtiket').onchange = (ev) => { S.gorsel.etiket = ev.target.checked; nui('gorsel', S.gorsel); };
$('#gorselBolge').onchange = (ev) => { S.gorsel.bolge = ev.target.checked; nui('gorsel', S.gorsel); };

// Şablonlar
$('#npcSablonYapBtn').onclick = () => seciliNpclerdenSablon();
$('#sablonListe').onclick = async (ev) => {
    const kart = ev.target.closest('.kart[data-id]');
    const tur = ev.target.closest('[data-islem]')?.dataset.islem;
    const s = kart && S.veri.sablonlar?.[kart.dataset.id];
    if (!s || !tur) return;
    if (tur === 'yerlestir') sablonYerlestir(s);
    if (tur === 'duzenle') sablonDuzenle(s);
    if (tur === 'sil' && await onayla('Şablon silinsin mi?', `<b>${e(s.ad)}</b> şablonu silinecek. Haritadaki NPC'ler etkilenmez.`, 'Sil')) {
        if (await islem('sablonSil', { id: s.id }) !== null) bildir('Şablon silindi.');
        yenile();
    }
};

// Bölgeler
$('#yeniBolgeBtn').onclick = () => bolgeCekmece(null);
$('#bolgeListe').onclick = async (ev) => {
    const kart = ev.target.closest('.kart[data-id]');
    const tur = ev.target.closest('[data-islem]')?.dataset.islem;
    const b = kart && S.veri.bolgeler?.[kart.dataset.id];
    if (!b || !tur) return;
    if (tur === 'duzenle') bolgeCekmece(b);
    if (tur === 'isinlan') nui('isinlan', { x: b.x, y: b.y, z: b.z + 1.0 });
    if (tur === 'sil' && await onayla('Bölge silinsin mi?', `<b>${e(b.ad)}</b> bölgesi silinecek. NPC'ler etkilenmez.`, 'Sil')) {
        if (await islem('bolgeSil', { id: b.id }) !== null) bildir('Bölge silindi.');
        yenile();
    }
};
$('#hepsiniDogurBtn').onclick = async () => {
    if (!(await onayla('Hepsi yeniden doğsun mu?', 'Bütün etkin NPC\'ler silinip yerlerinde canı dolu olarak yeniden doğacak.', 'Doğur', false))) return;
    const sonuc = await islem('hepsiniYenidenDogur');
    if (sonuc !== null) bildir(`${sonuc} NPC yeniden doğuyor.`);
    yenile();
};

// Tarayıcıda (oyun dışında) açılırsa önizleme verisiyle çalış
if (!OYUNDA) {
    const s = document.createElement('script');
    s.src = 'onizleme.js';
    document.body.appendChild(s);
}
