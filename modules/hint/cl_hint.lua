SX.Hint = {}
SX.Modules:Register("Hint", 9)

local HINT_ID = 'sxwaink_hint'
local CLOSE_COMMAND = 'wainkclose'

local visible = false

local function keyLabel(hash, fallback)
    local button = GetControlInstructionalButton(0, hash, true)
    if type(button) == 'string' and button:sub(1, 2) == 't_' then
        return button:sub(3)
    end
    return fallback
end

function SX.Hint:CloseKey()
    return keyLabel(joaat(CLOSE_COMMAND) | 0x80000000, Config.Keys.close)
end

function SX.Hint:Show()
    if not Config.Hint.enabled or visible or GetResourceState('sxHelpMenu') ~= 'started' then return end
    visible = exports.sxHelpMenu:Show({
        id = HINT_ID,
        position = Config.Widget.position,
        offset = Config.Widget.offset,
        key = false,
        header = {
            subtitle = GetPhrase('hint_subtitle'),
            title = GetPhrase('hint_title'),
            image = ('nui://%s/web/dist/logo.svg'):format(GetCurrentResourceName()),
        },
        rows = {
            {
                type = 'keys',
                keys = {
                    { key = keyLabel(24, GetPhrase('key_attack')), label = GetPhrase('hint_scan') },
                    { key = self:CloseKey(), label = GetPhrase('hint_close') },
                },
            },
        },
    }) ~= nil
end

function SX.Hint:Hide()
    if not visible then return end
    visible = false
    if GetResourceState('sxHelpMenu') == 'started' then
        exports.sxHelpMenu:Hide(HINT_ID)
    end
end

function SX.Hint:Initialize()
    RegisterCommand(CLOSE_COMMAND, function()
        if SX.Scanner:IsActive() then
            SX.Scanner:SetActive(false)
            Bridge.Notify(GetPhrase('notify_scanner_off'), 'info')
        end
    end, false)
    RegisterKeyMapping(CLOSE_COMMAND, GetPhrase('keymap_close'), 'keyboard', Config.Keys.close)

    AddEventHandler('onResourceStop', function(resource)
        if resource == GetCurrentResourceName() then SX.Hint:Hide() end
    end)
end
