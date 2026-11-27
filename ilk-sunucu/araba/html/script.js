// script.js: Menünün beyni. Listeyi oluşturur, tıklamaları oyuna (client.lua) iletir.

// ---- Araç listesi ----
// Yeni araç eklemek istersen ilgili kategoriye { ad: 'Görünen isim', model: 'oyundaki_model_adi' } ekle.
const ARACLAR = {
    'Süper': [
        { ad: 'Adder', model: 'adder' },
        { ad: 'Zentorno', model: 'zentorno' },
        { ad: 'T20', model: 't20' },
        { ad: 'Osiris', model: 'osiris' },
        { ad: 'Turismo R', model: 'turismor' },
        { ad: 'Entity XF', model: 'entityxf' },
        { ad: 'Krieger', model: 'krieger' },
        { ad: 'Emerus', model: 'emerus' },
        { ad: 'Tezeract', model: 'tezeract' },
        { ad: 'Nero', model: 'nero' },
    ],
    'Spor': [
        { ad: 'Elegy RH8', model: 'elegy2' },
        { ad: 'Sultan', model: 'sultan' },
        { ad: 'Jester', model: 'jester' },
        { ad: 'Comet', model: 'comet2' },
        { ad: 'Banshee', model: 'banshee' },
        { ad: 'Carbonizzare', model: 'carbonizzare' },
        { ad: 'Kuruma', model: 'kuruma' },
        { ad: 'Feltzer', model: 'feltzer2' },
        { ad: '9F', model: 'ninef' },
        { ad: 'Massacro', model: 'massacro' },
    ],
    'Kas': [
        { ad: 'Dominator', model: 'dominator' },
        { ad: 'Gauntlet', model: 'gauntlet' },
        { ad: 'Buffalo', model: 'buffalo' },
        { ad: 'Dukes', model: 'dukes' },
        { ad: 'Sabre Turbo', model: 'sabregt' },
        { ad: 'Vigero', model: 'vigero' },
    ],
    'Arazi': [
        { ad: 'Sandking', model: 'sandking' },
        { ad: 'Rebel', model: 'rebel2' },
        { ad: 'Injection', model: 'bfinjection' },
        { ad: 'Dubsta 6x6', model: 'dubsta3' },
        { ad: 'Kamacho', model: 'kamacho' },
        { ad: 'Trophy Truck', model: 'trophytruck' },
        { ad: 'Monster', model: 'monster' },
    ],
    'Motor': [
        { ad: 'Bati 801', model: 'bati' },
        { ad: 'Akuma', model: 'akuma' },
        { ad: 'Hakuchou', model: 'hakuchou' },
        { ad: 'Double-T', model: 'double' },
        { ad: 'Sanchez (kros)', model: 'sanchez' },
        { ad: 'Faggio (scooter)', model: 'faggio' },
        { ad: 'BMX', model: 'bmx' },
    ],
    'Hizmet': [
        { ad: 'Polis', model: 'police' },
        { ad: 'Polis (Buffalo)', model: 'police2' },
        { ad: 'Ambulans', model: 'ambulance' },
        { ad: 'İtfaiye', model: 'firetruk' },
        { ad: 'Taksi', model: 'taxi' },
        { ad: 'Otobüs', model: 'bus' },
        { ad: 'Limuzin', model: 'stretch' },
    ],
    'Eğlence': [
        { ad: 'Tank (Rhino)', model: 'rhino' },
        { ad: 'Kamyon (Dump)', model: 'dump' },
        { ad: 'Golf arabası', model: 'caddy' },
        { ad: 'Go-kart', model: 'veto' },
    ],
    'Hava': [
        { ad: 'Helikopter (Maverick)', model: 'maverick' },
        { ad: 'Helikopter (Frogger)', model: 'frogger' },
        { ad: 'Uçak (Duster)', model: 'duster' },
        { ad: 'Özel jet (Luxor)', model: 'luxor' },
        { ad: 'Savaş uçağı (Lazer)', model: 'lazer' },
    ],
};

// ---- Oyuna mesaj gönderme ----
// GetParentResourceName() bu scriptin adını verir ("araba").
// fetch ile client.lua'daki RegisterNUICallback'lere istek atıyoruz.
function oyunaGonder(olay, veri = {}) {
    fetch(`https://${GetParentResourceName()}/${olay}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(veri),
    });
}

const menu = document.getElementById('menu');
const kategorilerKutusu = document.getElementById('kategoriler');
const liste = document.getElementById('liste');
const ara = document.getElementById('ara');
let seciliKategori = 'Süper';

// Kategori butonlarını oluştur
function kategorileriCiz() {
    kategorilerKutusu.innerHTML = '';
    for (const isim of Object.keys(ARACLAR)) {
        const buton = document.createElement('button');
        buton.className = 'kategori' + (isim === seciliKategori ? ' aktif' : '');
        buton.textContent = isim;
        buton.onclick = () => {
            seciliKategori = isim;
            ara.value = '';
            kategorileriCiz();
            listeyiCiz();
        };
        kategorilerKutusu.appendChild(buton);
    }
}

// Araç listesini oluştur. Arama kutusu doluysa tüm kategorilerde arar.
function listeyiCiz() {
    const aranan = ara.value.trim().toLowerCase();
    let araclar;
    if (aranan) {
        araclar = Object.values(ARACLAR).flat().filter(a =>
            a.ad.toLowerCase().includes(aranan) || a.model.includes(aranan));
    } else {
        araclar = ARACLAR[seciliKategori];
    }

    liste.innerHTML = '';
    for (const arac of araclar) {
        const satir = document.createElement('div');
        satir.className = 'arac';
        satir.innerHTML = `<span>${arac.ad}</span><span class="model">${arac.model}</span>`;
        satir.onclick = () => oyunaGonder('sec', { model: arac.model });
        liste.appendChild(satir);
    }
}

ara.addEventListener('input', listeyiCiz);
document.getElementById('kapat').onclick = () => oyunaGonder('kapat');
document.getElementById('sil').onclick = () => oyunaGonder('sil');

// ESC'ye basınca kapat
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') oyunaGonder('kapat');
});

// client.lua'dan gelen mesajları dinle (SendNUIMessage)
window.addEventListener('message', (e) => {
    if (e.data.islem === 'ac') {
        menu.classList.remove('gizli');
        ara.value = '';
        ara.focus();
        listeyiCiz();
    } else if (e.data.islem === 'kapat') {
        menu.classList.add('gizli');
    }
});

kategorileriCiz();
listeyiCiz();
