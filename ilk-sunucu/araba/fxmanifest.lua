-- fxmanifest.lua: Her scriptin "kimlik kartı".
-- FiveM bu dosyaya bakarak scriptin hangi dosyalardan oluştuğunu öğrenir.

fx_version 'cerulean'   -- FiveM'in kullandığı manifest sürümü (hep bu kalabilir)
game 'gta5'             -- Bu script GTA V için

author 'Huso'
description '/araba komutu ve /garaj menüsü ile araç çıkarma'

-- client_script: Oyuncunun kendi bilgisayarında çalışan kod.
client_script 'client.lua'

-- server_script: Sunucuda çalışan kod (eski araçları silmek için)
server_script 'server.lua'

-- ui_page: Oyunun üstünde gösterilecek web sayfası (NUI = oyun içi arayüz)
ui_page 'html/index.html'

-- files: Oyuncuya gönderilecek ek dosyalar (arayüzün dosyaları)
files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
}
