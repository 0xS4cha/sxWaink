Bridge = {}
Bridge.Name = 'standalone'

local ESX = nil

local function detectFramework()
    if Config.Framework == 'standalone' then return 'standalone' end

    if Config.Framework == 'esx' or GetResourceState('es_extended') ~= 'missing' then
        local ok, obj = pcall(function()
            return exports.es_extended:getSharedObject()
        end)
        if ok and obj then
            ESX = obj
            return 'esx'
        end

        if Config.Framework == 'esx' then
            Logger:error('BRIDGE', "Config.Framework is 'esx' but es_extended could not be loaded")
        end
    end

    return 'standalone'
end

Bridge.Name = detectFramework()
Logger:info('BRIDGE', "Framework:", Bridge.Name)

local function getPlayer(source)
    if not ESX then return nil end
    return ESX.GetPlayerFromId(source)
end

local function hasDatabase()
    return GetResourceState('oxmysql') == 'started'
end

local function query(sql, params)
    local p = promise.new()
    exports.oxmysql:query(sql, params or {}, function(result)
        p:resolve(result)
    end)
    return Citizen.Await(p)
end

function Bridge.GetIdentifier(source)
    local xPlayer = getPlayer(source)
    if xPlayer and xPlayer.identifier then
        return xPlayer.identifier
    end
    if ESX then return nil end

    return GetPlayerIdentifierByType(source, 'license')
end

function Bridge.GetJob(source)
    local xPlayer = getPlayer(source)
    if not xPlayer then return nil, 0 end

    local job = xPlayer.getJob and xPlayer.getJob() or xPlayer.job
    if not job then return nil, 0 end

    return job.name, tonumber(job.grade) or 0
end

function Bridge.GetVehicleOwner(plate)
    if not ESX or not hasDatabase() then return nil end

    local rows = query([[
        SELECT u.firstname, u.lastname
        FROM owned_vehicles ov
        LEFT JOIN users u ON u.identifier = ov.owner
        WHERE TRIM(ov.plate) = ?
        LIMIT 1
    ]], { plate })

    local row = rows and rows[1]
    if not row or not row.firstname then return nil end

    return Utils.Trim(('%s %s'):format(row.firstname, row.lastname or ''))
end

function Bridge.Notify(source, message, kind)
    TriggerClientEvent('sxWaink:notify', source, message, kind or 'info')
end
