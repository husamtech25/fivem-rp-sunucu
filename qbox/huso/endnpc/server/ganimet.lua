-- server/ganimet.lua
-- NPC ölünce grubunun ganimet ayarına göre üstüne para / eşya konur.
-- Oyuncu cesede Sol Alt ile "Üstünü ara" der; sunucu mesafeyi kontrol edip eşyaları verir.

function GanimetHazirla(id, c)
    local n = Veri.npcler[id]
    local g = n and Veri.gruplar[n.grup]
    if not g or not c.ent or not DoesEntityExist(c.ent) then return end

    local ganimet = { para = 0, esyalar = {} }
    if (g.ganimetParaMax or 0) > 0 then
        ganimet.para = math.random(g.ganimetParaMin or 0, g.ganimetParaMax)
    end
    for _, e in ipairs(g.ganimetEsyalar or {}) do
        if math.random(100) <= (e.sans or 100) then
            ganimet.esyalar[#ganimet.esyalar + 1] = { item = e.item, adet = math.random(e.min or 1, e.max or 1) }
        end
    end
    if g.ganimetSilah and n.silah ~= 'WEAPON_UNARMED' then
        ganimet.esyalar[#ganimet.esyalar + 1] = { item = n.silah, adet = 1 }
    end

    if ganimet.para > 0 or #ganimet.esyalar > 0 then
        c.ganimet = ganimet
        Entity(c.ent).state:set('endnpcGanimet', true, true)   -- oyuncular "Üstünü ara" seçeneğini görsün
    end
end

lib.callback.register('endnpc:yagmala', function(kaynak, netId)
    netId = tonumber(netId)
    local hedef
    for _, c in pairs(Canli) do
        if c.netId == netId then hedef = c break end
    end
    if not hedef or hedef.durum ~= 'olu' or not hedef.ganimet then
        return { ok = false, mesaj = 'Üstünde bir şey yok.' }
    end
    if not DoesEntityExist(hedef.ent) or #(GetEntityCoords(GetPlayerPed(kaynak)) - GetEntityCoords(hedef.ent)) > 4.0 then
        return { ok = false, mesaj = 'Cesede çok uzaksın.' }
    end

    -- Önce ganimeti al ki iki oyuncu aynı anda alamasın
    local ganimet = hedef.ganimet
    hedef.ganimet = nil
    Entity(hedef.ent).state:set('endnpcGanimet', false, true)

    local alinan, sigmayan = {}, 0
    if ganimet.para > 0 then
        exports.qbx_core:AddMoney(kaynak, 'cash', ganimet.para, 'endnpc-ganimet')
        alinan[#alinan + 1] = ('$%d'):format(ganimet.para)
    end
    for _, e in ipairs(ganimet.esyalar) do
        local bilgi = exports.ox_inventory:Items(e.item)
        if bilgi and exports.ox_inventory:CanCarryItem(kaynak, e.item, e.adet) then
            exports.ox_inventory:AddItem(kaynak, e.item, e.adet)
            alinan[#alinan + 1] = ('%dx %s'):format(e.adet, bilgi.label or e.item)
        elseif bilgi then
            sigmayan = sigmayan + 1
        end
    end

    if #alinan == 0 then
        return { ok = false, mesaj = sigmayan > 0 and 'Envanterin dolu, hiçbir şey alamadın.' or 'Üstünde işe yarar bir şey yok.' }
    end
    local mesaj = 'Buldun: ' .. table.concat(alinan, ', ')
    if sigmayan > 0 then mesaj = mesaj .. (' (%d eşya envanterine sığmadı)'):format(sigmayan) end
    return { ok = true, mesaj = mesaj }
end)
