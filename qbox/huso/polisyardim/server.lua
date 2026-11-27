-- server.lua: NPC memurların yerlerini dosyada saklar ve herkese gönderir.
--   /npckoy        -> (admin) bulunduğun yere, baktığın yöne bir memur NPC koyar
--   /npcsil        -> (admin) sana en yakın NPC'yi siler
-- NPC'ler npcler.json dosyasında durur; sunucu yeniden açılınca da yerinde olur.

local DOSYA = 'npcler.json'
local SCRIPT = GetCurrentResourceName()

local npcler = json.decode(LoadResourceFile(SCRIPT, DOSYA) or '[]') or {}

local function kaydetVeGonder()
    SaveResourceFile(SCRIPT, DOSYA, json.encode(npcler, { indent = true }), -1)
    TriggerClientEvent('polisyardim:npcler', -1, npcler)
end

-- Yeni giren oyuncu listeyi ister
RegisterNetEvent('polisyardim:iste', function()
    TriggerClientEvent('polisyardim:npcler', source, npcler)
end)

-- lib.addCommand: ox_lib'in komut sistemi. restricted = sadece bu gruptakiler kullanabilir.
-- NPC türleri: her biri Sol Alt ile bakınca farklı bir şey açar (client.lua'da tanımlı)
local TURLER = {
    mesai = true, cephanelik = true, dolap = true, giyim = true, sus = true,   -- polis
    kiyafet = true, berber = true, dovme = true, estetik = true,        -- mağazalar
}

lib.addCommand('npckoy', {
    help = 'Bulunduğun yere memur NPC koyar (sonra kenara çekil)',
    params = {
        { name = 'tur', type = 'string', help = 'mesai | cephanelik | dolap | giyim | sus | kiyafet | berber | dovme | estetik' },
    },
    restricted = 'group.admin',
}, function(source, args)
    local tur = args.tur and args.tur:lower()
    if not TURLER[tur] then
        exports.qbx_core:Notify(source, 'Tür yanlış. Türler: mesai, cephanelik, dolap, giyim, sus, kiyafet, berber, dovme, estetik', 'error')
        return
    end

    local karakter = GetPlayerPed(source)
    local k = GetEntityCoords(karakter)
    npcler[#npcler + 1] = {
        x = k.x, y = k.y, z = k.z - 1.0,          -- -1: NPC'nin ayakları yere bassın
        yon = GetEntityHeading(karakter),
        tur = tur,
    }
    kaydetVeGonder()
    exports.qbx_core:Notify(source, 'NPC (' .. tur .. ') konuldu. Biraz kenara çekil.', 'success')
end)

lib.addCommand('npcsil', {
    help = 'Sana en yakın memur NPC\'yi siler',
    restricted = 'group.admin',
}, function(source)
    local k = GetEntityCoords(GetPlayerPed(source))
    local enYakin, enYakinMesafe = nil, 5.0   -- en fazla 5 metre uzaktakini siler
    for i, npc in ipairs(npcler) do
        local mesafe = #(k - vector3(npc.x, npc.y, npc.z))
        if mesafe < enYakinMesafe then
            enYakin, enYakinMesafe = i, mesafe
        end
    end
    if not enYakin then
        exports.qbx_core:Notify(source, '5 metre içinde NPC yok.', 'error')
        return
    end
    table.remove(npcler, enYakin)
    kaydetVeGonder()
    exports.qbx_core:Notify(source, 'NPC silindi.', 'success')
end)
