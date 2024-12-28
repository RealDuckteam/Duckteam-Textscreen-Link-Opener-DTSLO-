if SERVER then
    AddCSLuaFile("lua/dtslo/config.lua")
    AddCSLuaFile("lua/client/dtslo_client.lua")
    include("lua/server/dtslo_server.lua")
else
    include("lua/dtslo/config.lua")
    include("lua/client/dtslo_client.lua")
end
