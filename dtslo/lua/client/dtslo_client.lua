net.Receive("DTSLO_OpenURL", function()
    local url = net.ReadString()
    gui.OpenURL(url)

    if DTSLO_Config.SoundFile then
        surface.PlaySound(DTSLO_Config.SoundFile)
    end
end)
