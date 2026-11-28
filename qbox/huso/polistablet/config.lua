-- config.lua: Polis tableti ayarları

Ayar = {}

Ayar.Esya = 'polis_tablet'      -- ox_inventory'deki eşya adı (data/items.lua)
Ayar.EnFazlaIhbar = 60          -- tablette en fazla kaç ihbar tutulur (eskiler silinir)
Ayar.IhbarOmru = 120            -- dakika: bundan eski ihbarlar silinir
Ayar.AyniIhbarMesafe = 30.0     -- metre: aynı yazılı ve bu kadar yakın ihbarlar tek ihbar sayılır
Ayar.AyniIhbarSure = 20         -- saniye: (her polisin oyunu ihbarı ayrı bildirdiği için)

-- Konumlar sekmesindeki yerler. "GPS" düğmesi haritaya işaret koyar.
Ayar.Konumlar = {
    { kategori = 'Karakollar', liste = {
        { ad = 'Mission Row Karakolu (MRPD)', x = 441.0,   y = -982.0,  z = 30.7 },
        { ad = 'Vespucci Karakolu',           x = -1108.4, y = -845.2,  z = 19.3 },
        { ad = 'Sandy Shores Şerifliği',      x = 1853.9,  y = 3686.9,  z = 34.3 },
        { ad = 'Paleto Bay Şerifliği',        x = -448.6,  y = 6012.9,  z = 31.7 },
    } },
    { kategori = 'Hastaneler', liste = {
        { ad = 'Pillbox Hastanesi',           x = 298.5,   y = -584.5,  z = 43.3 },
        { ad = 'Sandy Shores Sağlık Merkezi', x = 1839.6,  y = 3672.9,  z = 34.3 },
        { ad = 'Paleto Bay Sağlık Merkezi',   x = -254.5,  y = 6331.8,  z = 32.4 },
    } },
    { kategori = 'Riskli yerler', liste = {
        { ad = 'Pacific Standard Bankası',    x = 235.0,   y = 216.0,   z = 106.3 },
        { ad = 'Fleeca Bankası (Legion)',     x = 149.9,   y = -1040.5, z = 29.4 },
        { ad = 'Vangelico Kuyumcusu',         x = -630.0,  y = -236.0,  z = 38.0 },
        { ad = 'Liman',                       x = 1000.0,  y = -3100.0, z = 5.9 },
    } },
    { kategori = 'Diğer', liste = {
        { ad = 'Bolingbroke Hapishanesi',     x = 1847.0,  y = 2586.0,  z = 45.7 },
        { ad = 'Çekilmiş araçlar (Davis)',    x = 409.0,   y = -1623.0, z = 29.3 },
        { ad = 'Los Santos Havalimanı',       x = -1037.0, y = -2737.0, z = 20.2 },
    } },
}
