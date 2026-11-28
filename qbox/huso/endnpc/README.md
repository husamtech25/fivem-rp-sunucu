# endnpc – NPC Yönetim ve Savaş Sistemi (Endcore RP)

Adminler için oyun içi panel: NPC oluştur / düzenle / sil, gruplara ayır, gruplar arası
ilişkileri (dost / tarafsız / düşman) belirle. Düşman gruplar birbirini görünce kendiliğinden çatışır.

## Açma
- `/npcpanel` veya **F7** (önce F6 ile admin görevini aç). Sadece `group.admin`.

## Sekmeler
- **NPC'ler**: liste, arama, grup/durum filtresi, çoklu seçim → toplu düzenle / doğur / etkinleştir / kapat / sil.
  Düzenlemede: ad, grup, model (hazır liste veya elle), can, zırh, öfke (veya grubunki), silah, davranış, konum.
  Konum: *Bulunduğum yer*, *Nişan alarak seç* (E koy, tekerlek döndür, Backspace iptal), *Harita işareti*.
- **Gruplar**: isim, renk, oyunculara karşı tavır, görüş / saldırı mesafesi, öfke, saldırı sıklığı, isabet,
  hareket tarzı, en fazla takip mesafesi, düşük can eşiği ve o zamanki davranış. Birden çok grubu toplu düzenleme.
- **İlişkiler**: grup × grup tablosu + oyunculara karşı sütunu.
- **Şablonlar**: hazır ekipler (Çete baskını, Askerî kontrol noktası, Polis devriye ekibi, Motorcu çetesi,
  Keskin nişancı ikilisi). *Yerleştir* → grup, isim ön eki ve konum seç; ekip baktığın yöne dönük kurulur.
  Kendi şablonun: NPC'ler sekmesinde NPC'leri seç → *Şablon olarak kaydet* (diziliş ilk NPC'ye göre saklanır).
- **Bölgeler**: bir grubun koruduğu daire (merkez + yarıçap). Düşman grup NPC'si (veya ayara göre herhangi bir oyuncu)
  girince bölgedeki o grup ve dost grupları görüş mesafesine bakmadan saldırır; misafir çıksa da alarm süresi boyunca kovalar.
- **Rota**: NPC düzenlemede rota noktaları ekle (bulunduğun yer / nişan al / harita işareti), davranışı *Rota* yap.
  Döngü veya gidip-gel, her noktada bekleme süresi. İsim etiketleri açıkken rota yerde yeşil çizgiyle görünür.
- **Araç**: NPC'ye araç seç (araba veya motor). Aracıyla doğar; devriye/avcı araçla gezer, rota araçla sürülür,
  düşmanı araçla kovalar, savaşmak için iner, savaş bitince geri biner. Araç kilitli doğar.
- **Ayarlar**: NPC limiti, yapay zeka aralığı, ceset süresi, ölünce ne olacağı (sil / yeniden doğ / kapalı beklesin),
  yeniden doğma süresi. Kendi ekranın için harita işaretleri ve isim etiketleri.

## Nasıl çalışıyor
- NPC'ler **sunucuda** oluşturulur (OneSync), herkes aynı NPC'yi görür. Kayıtlar `data.json`'da.
- Yapay zekayı NPC'nin yakınındaki oyuncunun oyunu çalıştırır (FiveM'de NPC'nin "sahibi").
  Sahip değişince ayarlar yeni sahipte otomatik uygulanır; can sadece doğarken / panelden değişince dolar.
- Savaşın kendisi GTA'nın savaş yapay zekası (siper, takip, nişan); script ona görüş/saldırı mesafesi,
  evden uzaklaşma sınırı, düşük can davranışı ve ölüm takibi ekler.
- Ölüm: NPC'nin sahibi sunucuya bildirir (sadece gerçek sahip bildirebilir), ceset süresi dolunca silinir.

## Dosyalar
| Dosya | Görevi |
|---|---|
| `config.lua` | Varsayılanlar, sınırlar, model / silah / renk listeleri |
| `server/veri.lua` | data.json okuma-yazma, doğrulama yardımcıları |
| `server/npc.lua` | Doğurma, ölüm ve ceset takibi, oyunculara senkron |
| `server/islemler.lua` | Panel işlemleri (yetki kontrolü burada), `/npcpanel` |
| `client/ai.lua` | Grup ilişkileri ve savaş yapay zekası |
| `client/yerlestirme.lua` | Nişan alarak yerleştirme |
| `client/panel.lua` | Panel köprüsü, harita işaretleri, isim etiketleri, F7 |
| `html/` | Panel arayüzü (`onizleme.js` sadece tarayıcıda deneme için) |
