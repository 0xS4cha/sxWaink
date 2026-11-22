Config = {}

Config.Framework = 'auto'

Config.Units = 'auto'

Config.Keys = {
    toggle = 'F9',
}

Config.Widget = {
    position = 'bottom-right',
    offset = { x = 2.5, y = 6.0 },
}

Config.Phone = {
    enabled = true,
    identifier = 'Waink',
    name = 'Waink',
    developer = '0xS4cha',
    defaultApp = true,
    price = 0,
    sdPhone = {
        identifier = 'waink',
        closeExport = 'closePhone',
    },
}

Config.Animation = {
    enabled = true,
    prop = 'prop_npc_phone_02',
    bone = 28422,
    offset = vector3(0.0, 0.0, 0.0),
    rotation = vector3(0.0, 0.0, 0.0),
    onFoot = { dict = 'amb@world_human_mobile_film_shocking@female@base', name = 'base' },
    inVehicle = { dict = 'cellphone@in_car@ds', name = 'cellphone_text_read_base' },
}

Config.Light = {
    enabled = true,
    color = { r = 62, g = 230, b = 255 },
    range = 2.5,
    intensity = 4.0,
    pulse = 2.0,
    distance = 60.0,
}

Config.Feedback = {
    enabled = true,
    sounds = true,
    vibration = true,
    audible = true,
    events = {
        start = {
            sound = { name = 'Menu_Accept', set = 'Phone_SoundSet_Default' },
        },
        shutter = {
            sound = { name = 'Camera_Shoot', set = 'Phone_Soundset_Franklin', audible = true },
            vibration = { duration = 80, strength = 120, pulses = 1 },
        },
        success = {
            sound = { name = 'Hack_Success', set = 'DLC_HEIST_BIOLAB_PREP_HACKING_SOUNDS' },
            vibration = { duration = 150, strength = 180, pulses = 1 },
        },
        fail = {
            sound = { name = 'Hack_Failed', set = 'DLC_HEIST_BIOLAB_PREP_HACKING_SOUNDS' },
            vibration = { duration = 300, strength = 220, pulses = 2 },
        },
        blocked = {
            sound = { name = 'Menu_Back', set = 'Phone_SoundSet_Default' },
            vibration = { duration = 100, strength = 150, pulses = 1 },
        },
    },
}

Config.Access = {
    jobs = {},
    ace = 'sxwaink.use',
}

Config.Scan = {
    distance = 40.0,
    duration = 1500,
    decay = 0.5,
    maxSpeed = 15.0,
    distanceFactor = 1.0,
    speedFactor = 1.0,
    plateAngle = 55.0,
    cooldown = 3000,
    widgetDuration = 15000,
}

Config.Owner = {
    enabled = true,
    cacheSeconds = 60,
}

Config.HistoryLimit = 30
