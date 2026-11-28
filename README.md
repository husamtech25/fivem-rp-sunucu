# Endcore RP

Qbox tabanlı, Türkçe bir GTA V roleplay sunucusunun kendi yazdığımız scriptleri ve yaptığımız değişiklikler.
Hazır Qbox scriptlerinin tamamı burada değil; onlar kendi GitHub depolarında duruyor (aşağıda listesi var).

## Klasörler

| Klasör | İçerik |
|---|---|
| `qbox/huso/polisyardim` | Polis noktalarına yer işaretleri + `/npckoy <tür>` ile yerleştirilen NPC'ler |
| `qbox/huso/kisayollar` | Admin kısayolları: F6 admin görevi (`/optin`), F10 admin menüsü (`/admin`) |
| `qbox/huso/endnpc` | NPC yönetim paneli (`/npcpanel`, F7): NPC'ler, gruplar, grup ilişkileri, otomatik NPC savaşı, hazır ekip şablonları, devriye rotası, araçlı NPC'ler ve korunan bölgeler. Ayrıntı: klasördeki README |
| `qbox/degisiklikler` | Hazır Qbox scriptlerinde değiştirdiğimiz dosyalar (açıklamalar aşağıda) |
| `qbox/cfg` | `ox.cfg`, `permissions.cfg` ve lisans anahtarı silinmiş `server.cfg.ornek` |
| `qbox/sql/mrpd_kapilar.sql` | MRPD'nin 31 kapı kilidi (ox_doorlock tablosuna) |
| `ilk-sunucu` | Framework'süz ilk sunucuda Lua öğrenirken yazdığımız scriptler |
| `SunucuyuBaslat.bat` | Sunucuyu kendi penceresinde başlatır |

## NPC türleri (`/npckoy <tür>`, admin)

| Tür | Kim görür | Ne açar |
|---|---|---|
| `mesai` | Polis | Göreve başla / bitir |
| `cephanelik` | Polis | Polis cephaneliği |
| `dolap` | Polis | Kişisel dolap |
| `giyim` | Polis | Kıyafet menüsü |
| `sef` | Polis rütbe 4 | Departman yönetimi (qbx_management) |
| `sus` | — | Sadece görüntü |
| `kiyafet`, `berber`, `dovme`, `estetik` | Herkes | illenium-appearance mağazaları |
| `doktor` | Herkes | Hastane check-in (en yakın hastane) |
| `eczane` | Herkes | Eczane dükkanı (bandaj, ağrı kesici, ilk yardım) |
| `ems_mesai`, `ems_depo`, `ems_dolap` | Ambulans | EMS mesai, malzeme deposu, kişisel dolap |
| `mekanik_mesai`, `mekanik_depo` | Mekanik | Mekanik mesai ve deposu |

NPC'ler `npcler.json` dosyasında saklanır; `/npcsil` en yakın NPC'yi siler.

## Qbox'ta yaptığımız değişiklikler

| Dosya | Değişiklik | Neden |
|---|---|---|
| `qbx_ambulancejob/server/main.lua` | Eczane/dolap kaydı 30 sn'ye kadar tekrar deneniyor | Açılışta `No such export RegisterShop in resource ox_inventory` hatası |
| `qbx_vehiclekeys/client/main.lua` | Motor tuşu varsayılanı `J` | `config.keySearchBind` tanımlı değildi |
| `ox_lib/.../textui.lua` | `[E]` yazıları büyütüldü | Varsayılan yazı çok küçüktü |
| `ox_doorlock/config.lua` | `DrawTextUI = true` | Kapıda "[E] Kilidi aç" yazısı çıksın |
| `ox_inventory/data/shops.lua` | `Eczane` dükkanı eklendi | `eczane` NPC'si için, konumsuz |
| `qbx_police/config/shared.lua` | MRPD mesai noktası kapatıldı | Yerine mesai NPC'si |
| `qbx_management`, `qbx_cityhall`, `qbx_ambulancejob`, `qbx_mechanicjob` `config/client.lua` | `useTarget = true` | E yazıları yerine Sol Alt, NPC'lerle çakışmasın |
| `qbx_core/config/shared.lua` | `serverName = 'Endcore RP'` | Sunucu adı |
| `illenium-appearance/shared/config.lua` | `UseTarget = true`, `EnablePedsForShops = false` | Satıcıları `/npckoy` ile kasaya koyuyoruz |
| `illenium-appearance/locales/tr.lua` + `fxmanifest.lua` | Türkçe çeviri | Kıyafet editörü Türkçe |
| `scully_emotemenu/locales/tr.json`, `scully_emotemenu.cfg` | Türkçe çeviri, `pointKey ""` | Emote menüsü Türkçe; B tuşu emniyet kemerine kaldı |
| `mm_radio/locales/tr.json`, `npwd_qbx_garages/locales/tr.json` | Türkçe çeviri | Telsiz ve telefon garajı Türkçe |
| `loadscreen/html/assets/logo.png` | Endcore RP logosu | Yükleme ekranı |
| `cfg/ox.cfg`, `server.cfg` | `tr` dil ayarları, Endcore yükleme ekranı teması | Türkçe ve tema |

Bu dosyaları kurmak için Qbox'taki aynı yoldaki dosyanın yerine kopyala. Qbox güncellenirse değişiklikleri yeniden uygulamak gerekir.

## Tuşlar

| Tuş | İş |
|---|---|
| Sol Alt | Etkileşim (NPC, kapı değil) |
| E | Kapı kilidi, garaj noktaları |
| TAB / F1 | Envanter / hızlı slotlar |
| Z | Radyal menü |
| M | Telefon |
| F5 | Emote menüsü |
| B | Emniyet kemeri |
| J | Motor |
| L | Araç kilidi |
| F6 / F10 | Admin görevi / admin menüsü |

## İlk sunucu scriptleri (öğrenme)

| Script | Komutlar |
|---|---|
| `araba` | `/araba <model>`, `/garaj` (F5 menü), `/sil`; yeni araç çıkınca eskisi silinir |
| `komutlar` | `/tp`, `/can`, `/tamir` |
| `hizgostergesi` | Araçta km/s, vites, devir |
| `konumkaydet` | Çıktığın yerden devam |
| `dunya` | `/hava`, `/saat`, `/gece`, `/gunduz`, `/saatdondur` (admin) |
| `emote` | `/e <kod>`, F3 menü, X iptal |

## Kurulum notları

- `server.cfg.ornek` → `server.cfg` olarak kopyala, `LISANS_ANAHTARINI_BURAYA_YAZ` ve `FIVEM_ID` yerlerini doldur.
- Veritabanı: MariaDB, `root@localhost`, veritabanı adı `Qbox_0969A6`. MRPD kapıları için `qbox/sql/mrpd_kapilar.sql` çalıştır.
- `[huso]` klasörünü `resources` içine koy; `server.cfg`'de `ensure [huso]` var.

## Kullanılan hazır kaynaklar

Qbox txAdmin recipe: https://github.com/Qbox-project/txAdminRecipe (qbx_*, ox_lib, ox_inventory, ox_target, ox_doorlock, illenium-appearance, Renewed-Banking, scully_emotemenu, pma-voice, mm_radio, npwd ve diğerleri). Pillbox iç mekanı: Lorenc95 (NFRL lisansı).
