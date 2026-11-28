-- server/ihbar.lua
-- "İhbar" açık bir grubun NPC'si çatışmaya girince, onu yöneten oyuncunun oyunu buraya haber verir.
-- Görevdeki polislere qbx_police'in kendi ihbar bildirimi (harita işareti + ses) gönderilir.
-- Aynı bölgeden kısa sürede tekrar ihbar gitmez.

local sonIhbarlar = {}   -- { { konum = vector3, zaman = os.time() } }

RegisterNetEvent('endnpc:catisma', function(netId)
    local kaynak = source
    netId = tonumber(netId)
    local id, c
    for npcId, kayit in pairs(Canli) do
        if kayit.netId == netId then id, c = npcId, kayit break end
    end
    if not id or not c.ent or not DoesEntityExist(c.ent) then return end
    if NetworkGetEntityOwner(c.ent) ~= kaynak then return end   -- sadece NPC'nin sahibi bildirebilir

    local n = Veri.npcler[id]
    local g = n and Veri.gruplar[n.grup]
    if not g or not g.ihbar then return end

    local simdi = os.time()
    local konum = GetEntityCoords(c.ent)
    for i = #sonIhbarlar, 1, -1 do
        local ihbar = sonIhbarlar[i]
        if simdi - ihbar.zaman > Ayar.Ihbar.bekleme then
            table.remove(sonIhbarlar, i)
        elseif #(ihbar.konum - konum) < Ayar.Ihbar.alan then
            return   -- bu bölgeden yakın zamanda zaten ihbar gitti
        end
    end
    sonIhbarlar[#sonIhbarlar + 1] = { konum = konum, zaman = simdi }

    local _, polisler = exports.qbx_core:GetDutyCountType('leo')
    for _, polis in ipairs(polisler or {}) do
        TriggerClientEvent('police:client:policeAlert', polis, konum, Ayar.Ihbar.yazi)
    end
end)
