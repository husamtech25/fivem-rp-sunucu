-- client.lua: Komut yazmak yerine tuşla çalıştırma
--
-- Neden ara komut? /admin ve /optin SUNUCUDA tanımlı komutlar. FiveM'in tuş atama sistemi
-- (RegisterKeyMapping) ise sadece oyuncunun bilgisayarında (client) tanımlı komutları tuşa bağlar.
-- O yüzden client'ta küçük ara komutlar tanımlıyoruz; bunlar ExecuteCommand ile asıl komutu
-- çalıştırıyor (sohbete "/admin" yazmakla aynı şey). Yetkisi olmayan biri basarsa komut çalışmaz.
--
-- Oyuncu tuşları ESC > Ayarlar > Tuş Atamaları > FiveM bölümünden değiştirebilir.

local KISAYOLLAR = {
    { ad = 'huso_optin', komut = 'optin', aciklama = 'Admin: görevi aç / kapat', tus = 'F6' },
    { ad = 'huso_admin', komut = 'admin', aciklama = 'Admin: menüyü aç',         tus = 'F10' },
}

for _, k in ipairs(KISAYOLLAR) do
    RegisterCommand(k.ad, function()
        ExecuteCommand(k.komut)
    end, false)
    RegisterKeyMapping(k.ad, k.aciklama, 'keyboard', k.tus)
end
