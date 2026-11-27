// script.js: Emote menüsü. Liste client.lua'dan gelir (SendNUIMessage ile).

let emotelar = [];
let seciliKategori = null;

const menu = document.getElementById('menu');
const kategorilerKutusu = document.getElementById('kategoriler');
const liste = document.getElementById('liste');
const ara = document.getElementById('ara');

function oyunaGonder(olay, veri = {}) {
    fetch(`https://${GetParentResourceName()}/${olay}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(veri),
    });
}

// Listedeki kategorileri sırasını bozmadan çıkar: ['Hareket', 'Dans', ...]
function kategoriler() {
    return [...new Set(emotelar.map(e => e.kategori))];
}

function kategorileriCiz() {
    kategorilerKutusu.innerHTML = '';
    for (const isim of kategoriler()) {
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

function listeyiCiz() {
    const aranan = ara.value.trim().toLowerCase();
    const gosterilecek = aranan
        ? emotelar.filter(e => e.ad.toLowerCase().includes(aranan) || e.kod.includes(aranan))
        : emotelar.filter(e => e.kategori === seciliKategori);

    liste.innerHTML = '';
    for (const emote of gosterilecek) {
        const satir = document.createElement('div');
        satir.className = 'emote';
        satir.innerHTML = `<span>${emote.ad}</span><span class="kod">/e ${emote.kod}</span>`;
        satir.onclick = () => oyunaGonder('oynat', { kod: emote.kod });
        liste.appendChild(satir);
    }
}

ara.addEventListener('input', listeyiCiz);
document.getElementById('kapat').onclick = () => oyunaGonder('kapat');
document.getElementById('durdur').onclick = () => oyunaGonder('durdur');
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') oyunaGonder('kapat');
});

window.addEventListener('message', (e) => {
    if (e.data.islem === 'ac') {
        emotelar = e.data.emotelar || [];
        if (!seciliKategori) seciliKategori = kategoriler()[0];
        menu.classList.remove('gizli');
        ara.value = '';
        ara.focus();
        kategorileriCiz();
        listeyiCiz();
    } else if (e.data.islem === 'kapat') {
        menu.classList.add('gizli');
    }
});
