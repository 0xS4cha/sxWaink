SX.Scan = {}
SX.Modules:Register("Scan", 20)

local registeredOwners = {}
local ownerCache = {}
local lastScan = {}

local function normalizePlate(plate)
    return Utils.Trim(tostring(plate or '')):upper()
end

function SX.Scan:CanUse(source)
    if next(Config.Access.jobs or {}) == nil then return true end

    if Config.Access.ace and IsPlayerAceAllowed(source, Config.Access.ace) then
        return true
    end

    local job, grade = Bridge.GetJob(source)
    local minGrade = job and Config.Access.jobs[job]
    return minGrade ~= nil and grade >= minGrade
end

function SX.Scan:SetOwner(plate, name)
    plate = normalizePlate(plate)
    if plate == '' then return end
    registeredOwners[plate] = name
    ownerCache[plate] = nil
end

function SX.Scan:GetOwner(plate)
    plate = normalizePlate(plate)
    if plate == '' or not Config.Owner.enabled then return nil end

    if registeredOwners[plate] then
        return registeredOwners[plate]
    end

    local cached = ownerCache[plate]
    if cached and os.time() - cached.time < Config.Owner.cacheSeconds then
        return cached.name or nil
    end

    local ok, name = pcall(Bridge.GetVehicleOwner, plate)
    if not ok then
        Logger:error('SCAN', 'Owner lookup failed:', name)
        name = nil
    end

    ownerCache[plate] = { name = name or false, time = os.time() }
    return name
end

local function scan(source, netId)
    if not SX.Scan:CanUse(source) then
        return { ok = false, error = 'not_allowed' }
    end

    local now = GetGameTimer()
    if lastScan[source] and now - lastScan[source] < Config.Scan.cooldown - 250 then
        return { ok = false, error = 'cooldown' }
    end

    netId = tonumber(netId) or 0
    local entity = netId > 0 and NetworkGetEntityFromNetworkId(netId) or 0
    if entity == 0 or not DoesEntityExist(entity) or GetEntityType(entity) ~= 2 then
        lastScan[source] = now
        return { ok = true, data = {} }
    end

    local distance = #(GetEntityCoords(GetPlayerPed(source)) - GetEntityCoords(entity))
    if distance > Config.Scan.distance + 10.0 then
        return { ok = false, error = 'too_far' }
    end

    lastScan[source] = now
    local plate = normalizePlate(GetVehicleNumberPlateText(entity))
    return { ok = true, data = { plate = plate, owner = SX.Scan:GetOwner(plate) } }
end

function SX.Scan:Initialize()
    RegisterServerCallback('sxWaink:getProfile', function(source)
        return {
            ok = true,
            data = {
                identifier = Bridge.GetIdentifier(source),
                allowed = SX.Scan:CanUse(source),
            }
        }
    end)

    RegisterServerCallback('sxWaink:scan', scan)

    AddEventHandler('playerDropped', function()
        lastScan[source] = nil
    end)
end
