exports("IsScannerActive", function()
    return SX.Scanner:IsActive()
end)

exports("SetScannerActive", function(active)
    SX.Scanner:SetActive(active)
end)

exports("ToggleScanner", function()
    SX.Scanner:Toggle()
end)

exports("SetCrosshair", function(active, state, progress)
    SX.Scanner:SetCrosshair(active, state, progress)
end)

exports("ShowWidget", function(vehicle, key)
    SX.Scanner:ShowWidget(vehicle, key)
end)

exports("HideWidget", function()
    SX.Scanner:HideWidget()
end)

exports("IsWidgetVisible", function()
    return SX.Scanner:IsWidgetVisible()
end)

exports("SetWidgetPage", function(page)
    SX.Scanner:SetWidgetPage(page)
end)

exports("GetVehicleStats", function(entity)
    return SX.Scanner:GetVehicleStats(entity)
end)

exports("PushScan", function(vehicle)
    SX.Scanner:PushScan(vehicle)
end)

exports("GetHistory", function()
    return SX.Scanner:GetHistory()
end)

exports("ClearHistory", function()
    SX.Scanner:ClearHistory()
end)

exports("GetUnits", function()
    return SX.UI:GetUnits()
end)
