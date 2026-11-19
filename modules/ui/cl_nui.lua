SX.UI = {}
SX.Modules:Register("UI", 5)

function SX.UI:Send(action, data)
    SendNUIMessage({
        action = action,
        data = data or {}
    })
end

function SX.UI:GetUnits()
    if Config.Units == 'metric' or Config.Units == 'imperial' then
        return Config.Units
    end

    return ShouldUseMetricMeasurements() and 'metric' or 'imperial'
end

function SX.UI:Initialize()
    RegisterNUICallback('nuiReady', function(_, cb)
        cb({ ok = true })
    end)
end
