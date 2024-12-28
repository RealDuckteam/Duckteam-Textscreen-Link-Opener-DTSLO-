if SERVER then
    AddCSLuaFile("dtslo/config.lua")
    AddCSLuaFile("client/dtslo_client.lua")
    include("server/dtslo_server.lua")
else
    include("dtslo/config.lua")
    include("client/dtslo_client.lua")
end
