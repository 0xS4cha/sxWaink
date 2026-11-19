exports("IsScannerActive", function()
    return SX.App:IsScannerActive()
end)

exports("SetScannerActive", function(active)
    SX.App:SetScannerActive(active)
end)

exports("SetCrosshair", function(active, state, progress)
    SX.App:SetCrosshair(active, state, progress)
end)

exports("ShowWidget", function(vehicle, key)
    SX.App:ShowWidget(vehicle, key)
end)

exports("HideWidget", function()
    SX.App:HideWidget()
end)

exports("IsWidgetVisible", function()
    return SX.App:IsWidgetVisible()
end)

exports("SetWidgetPage", function(page)
    SX.App:SetWidgetPage(page)
end)

exports("GetVehicleStats", function(entity)
    return SX.App:GetVehicleStats(entity)
end)

exports("PushScan", function(vehicle)
    SX.App:PushScan(vehicle)
end)

exports("GetHistory", function()
    return SX.App:GetHistory()
end)

exports("ClearHistory", function()
    SX.App:ClearHistory()
end)

exports("GetUnits", function()
    return SX.UI:GetUnits()
end)
