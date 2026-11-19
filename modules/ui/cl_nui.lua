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

function SX.UI:GetLocalization()
    local locale = GetPreferredLanguageId()
    return {
        locale = locale,
        translations = GetLanguageTable(locale),
        units = self:GetUnits(),
    }
end

function SX.UI:SendLocalization()
    local localization = self:GetLocalization()
    self:Send('setTranslations', { locale = localization.locale, translations = localization.translations })
    self:Send('setSettings', { units = localization.units })
end

function SX.UI:Initialize()
    RegisterNUICallback('nuiReady', function(_, cb)
        SX.UI:SendLocalization()
        cb({ ok = true })
    end)

    CreateThread(function()
        Wait(1000)
        SX.UI:SendLocalization()
    end)
end
