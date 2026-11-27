# FiveM RP Sunucusu (huso-sunucu)

Qbox tabanlı, Türkçe bir GTA V roleplay sunucusunun kendi yazdığımız scriptleri ve yaptığımız değişiklikler.
Hazır Qbox scriptlerinin tamamı burada değil; onlar kendi GitHub depolarında duruyor (aşağıda listesi var).

## Klasörler

| Klasör | İçerik |
|---|---|
| `qbox/huso/polisyardim` | Polis noktalarına yer işaretleri + `/npckoy` ile yerleştirilen NPC'ler (mesai, cephanelik, dolap, giyim, kıyafet, berber, dövme, estetik) |
| `qbox/degisiklikler` | Hazır Qbox scriptlerinde değiştirdiğimiz dosyalar (açıklamalar aşağıda) |
| `qbox/cfg` | `ox.cfg`, `permissions.cfg` ve lisans anahtarı silinmiş `server.cfg.ornek` |
| `ilk-sunucu` | Framework'süz ilk sunucuda Lua öğrenirken yazdığımız scriptler |

## Qbox'ta yaptığımız değişiklikler

| Dosya | Değişiklik | Neden |
|---|---|---|
| `qbx_ambulancejob/server/main.lua` | Eczane/dolap kaydı 30 sn'ye kadar tekrar deneniyor | Sunucu açılışında `No such export RegisterShop in resource ox_inventory` hatası |
| `qbx_vehiclekeys/client/main.lua` | Motor tuşu varsayılanı `J` | `config.keySearchBind` tanımlı değildi, motorun tuşu boş kalıyordu |
| `ox_lib/.../textui.lua` | `[E]` yazıları büyütüldü | Varsayılan yazı çok küçüktü |
| `illenium-appearance/shared/config.lua` | `UseTarget = true`, `EnablePedsForShops = false` | Mağaza satıcılarını `/npckoy` ile kasaya biz koyuyoruz |
| `illenium-appearance/shared/blacklist.lua` | Boş (açıklamalı) | Denenen polis kıyafet paketi FiveM'de çalışmadı |
| `cfg/ox.cfg`, `server.cfg` | `ox:locale "tr"`, `qb_locale "tr"` | Türkçe dil |

Bu dosyaları kurmak için Qbox'taki aynı yoldaki dosyanın yerine kopyala. Qbox güncellenirse değişiklikleri yeniden uygulamak gerekir.

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
- Veritabanı: MariaDB, `root@localhost`, veritabanı adı `Qbox_0969A6`.
- `[huso]` klasörünü `resources` içine koy; `server.cfg`'de `ensure [huso]` var.

## Kullanılan hazır kaynaklar

Qbox txAdmin recipe: https://github.com/Qbox-project/txAdminRecipe (qbx_*, ox_lib, ox_inventory, ox_target, illenium-appearance, Renewed-Banking, scully_emotemenu, pma-voice, npwd ve diğerleri).
