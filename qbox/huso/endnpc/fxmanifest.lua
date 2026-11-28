fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Huso'
description 'Endcore RP - NPC yönetim paneli, grup sistemi ve yapay zeka savaş sistemi'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

server_scripts {
    'server/veri.lua',      -- kayıt dosyası, doğrulama yardımcıları
    'server/npc.lua',       -- NPC'leri doğurma, ölüm takibi, senkron
    'server/islemler.lua',  -- panelden gelen işlemler + /npcpanel komutu
    'server/ganimet.lua',   -- ölen NPC'nin üstünden çıkanlar
    'server/ihbar.lua',     -- çatışmada polise ihbar
    'server/koruma.lua',    -- kiralık koruma
    'server/etkinlik.lua',  -- dalga etkinliği
}

client_scripts {
    'client/ai.lua',          -- gruplar arası ilişkiler + savaş yapay zekası
    'client/yerlestirme.lua', -- nişan alarak NPC yerleştirme
    'client/panel.lua',       -- panel (NUI), harita işaretleri, isim etiketleri
    'client/ganimet.lua',     -- cesedin üstünü arama
    'client/koruma.lua',      -- koruma ajansı ve kiralanan korumalar
    'client/etkinlik.lua',    -- etkinlik duyuruları ve harita işareti
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
}

dependencies {
    'ox_lib',
    'qbx_core',
    'ox_inventory',
    'ox_target',
}
