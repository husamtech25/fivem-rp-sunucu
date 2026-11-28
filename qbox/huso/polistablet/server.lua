-- server.lua: İhbarları saklar ve tablete gönderir.
--
-- İhbarlar nereden geliyor? Sunucudaki bütün ihbarlar (qbx_police: memur yaralandı, 911, plaka radarı;
-- endnpc: silah sesleri ihbarı) görevdeki polislerin oyununa "police:client:policeAlert" olarak gider.
-- Tabletin client.lua'sı bunu yakalayıp buraya iletir. Birden fazla polis aynı ihbarı iletirse
-- burada tek ihbar sayılır.

local ihbarlar = {}   -- eskiden yeniye: { id, yazi, sokak, x, y, z, zaman, durum, ilgilenen }
local sonId = 0

local function oyuncu(kaynak)
    return exports.qbx_core:GetPlayer(kaynak)
end

-- Polis mi? (görevde olsun olmasın; tableti sadece polisler kullanır)
local function polisMi(kaynak)
    local p = oyuncu(kaynak)
    return p and p.PlayerData.job and p.PlayerData.job.type == 'leo'
end

local function gorevdeMi(kaynak)
    local p = oyuncu(kaynak)
    return p and p.PlayerData.job and p.PlayerData.job.type == 'leo' and p.PlayerData.job.onduty
end

local function memurAdi(kaynak)
    local p = oyuncu(kaynak)
    if not p then return 'Bilinmiyor' end
    local c = p.PlayerData.charinfo or {}
    local cagri = p.PlayerData.metadata and p.PlayerData.metadata.callsign
    local ad = ('%s %s'):format(c.firstname or '', c.lastname or ''):gsub('^%s+', ''):gsub('%s+$', '')
    if cagri and cagri ~= '' and cagri ~= 'NO CALLSIGN' then ad = ('[%s] %s'):format(cagri, ad) end
    return ad
end

local function eskileriTemizle()
    local sinir = os.time() - Ayar.IhbarOmru * 60
    for i = #ihbarlar, 1, -1 do
        if ihbarlar[i].zaman < sinir then table.remove(ihbarlar, i) end
    end
    while #ihbarlar > Ayar.EnFazlaIhbar do table.remove(ihbarlar, 1) end
end

-- Görevdeki bir polisin oyunu yeni bir ihbar aldığını bildirir
RegisterNetEvent('polistablet:ihbarGeldi', function(konum, yazi, sokak)
    local kaynak = source
    if not gorevdeMi(kaynak) then return end   -- polis olmayanlar sahte ihbar ekleyemez
    if type(konum) ~= 'table' or type(yazi) ~= 'string' then return end
    local x, y, z = tonumber(konum.x), tonumber(konum.y), tonumber(konum.z)
    if not (x and y and z) then return end
    yazi = yazi:sub(1, 200)
    sokak = type(sokak) == 'string' and sokak:sub(1, 100) or ''

    local simdi = os.time()
    local yeni = vector3(x, y, z)
    for i = #ihbarlar, 1, -1 do
        local ihbar = ihbarlar[i]
        if simdi - ihbar.zaman > Ayar.AyniIhbarSure then break end
        if ihbar.yazi == yazi and #(vector3(ihbar.x, ihbar.y, ihbar.z) - yeni) < Ayar.AyniIhbarMesafe then
            return   -- başka bir polis bu ihbarı zaten iletti
        end
    end

    sonId = sonId + 1
    ihbarlar[#ihbarlar + 1] = { id = sonId, yazi = yazi, sokak = sokak, x = x, y = y, z = z, zaman = simdi, durum = 'yeni' }
    eskileriTemizle()
end)

-- Tablet açıkken birkaç saniyede bir istenir
lib.callback.register('polistablet:getir', function(kaynak)
    if not polisMi(kaynak) then return nil end
    eskileriTemizle()

    local liste = {}
    for i = #ihbarlar, 1, -1 do liste[#liste + 1] = ihbarlar[i] end   -- yeniden eskiye

    local ekip = {}
    local _, gorevdekiler = exports.qbx_core:GetDutyCountType('leo')
    for _, polis in ipairs(gorevdekiler or {}) do
        local p = oyuncu(polis)
        if p then
            local k = GetEntityCoords(GetPlayerPed(polis))
            ekip[#ekip + 1] = {
                ad = memurAdi(polis),
                rutbe = p.PlayerData.job.grade and p.PlayerData.job.grade.name or '',
                birim = p.PlayerData.job.label or '',
                x = k.x, y = k.y, z = k.z,
                ben = polis == kaynak,
            }
        end
    end

    local benim = GetEntityCoords(GetPlayerPed(kaynak))
    return {
        ihbarlar = liste,
        ekip = ekip,
        ben = { ad = memurAdi(kaynak), gorevde = gorevdeMi(kaynak) == true, x = benim.x, y = benim.y, z = benim.z },
        simdi = os.time(),
    }
end)

-- İhbar üzerinde işlem: üstlen, bırak, kapat, yeniden aç
lib.callback.register('polistablet:islem', function(kaynak, tip, id)
    if not gorevdeMi(kaynak) then return { ok = false, mesaj = 'İhbarlarla ilgilenmek için görevde olmalısın.' } end
    local ihbar
    for _, i in ipairs(ihbarlar) do
        if i.id == id then ihbar = i break end
    end
    if not ihbar then return { ok = false, mesaj = 'İhbar bulunamadı (süresi dolmuş olabilir).' } end

    local ad = memurAdi(kaynak)
    if tip == 'ustlen' then
        ihbar.durum, ihbar.ilgilenen = 'ilgileniliyor', ad
    elseif tip == 'birak' then
        ihbar.durum, ihbar.ilgilenen = 'yeni', nil
    elseif tip == 'kapat' then
        ihbar.durum, ihbar.kapatan = 'kapandi', ad
    elseif tip == 'ac' then
        ihbar.durum, ihbar.kapatan = ihbar.ilgilenen and 'ilgileniliyor' or 'yeni', nil
    else
        return { ok = false, mesaj = 'Bilinmeyen işlem.' }
    end
    return { ok = true }
end)
