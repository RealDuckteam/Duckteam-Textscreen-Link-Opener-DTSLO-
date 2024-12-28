if not SERVER then return end

util.AddNetworkString("DTSLO_OpenURL")
include("dtslo/config.lua")

local DTSLO_Translations = {}

local function LoadTranslations()
    local languageFile = "language/" .. DTSLO_Config.Language .. ".json"
    if file.Exists(languageFile, "LUA") then
        local data = file.Read(languageFile, "LUA")
        DTSLO_Translations = util.JSONToTable(data) or {}
    else
        DTSLO_Translations = {
            ["urls_loaded"] = "URLs loaded.",
            ["no_urls_found"] = "No saved URLs found. New file created.",
            ["urls_saved"] = "URLs saved.",
            ["please_provide_url"] = "Please provide a valid URL!",
            ["invalid_url"] = "Invalid URL! The URL must start with 'http://' or 'https://'.",
            ["not_looking_at_textscreen"] = "You are not looking at a valid textscreen!",
            ["url_already_exists"] = "This textscreen already has a link. Delete the old link before adding a new one.",
            ["url_added"] = "URL added to the textscreen.",
            ["url_removed_from_textscreen"] = "URL removed from the textscreen.",
            ["admin_required"] = "You must be an admin to use this command.",
            ["not_looking_at_textscreen"] = "You are not looking at a valid textscreen!",
            ["no_url_to_remove"] = "This textscreen has no link to remove.",
            ["url_removed"] = "The link for this textscreen has been removed."
        }
        print("DTSLO: Language file not found. Default texts will be used.")
    end
end

local function Translate(text)
    return DTSLO_Translations[text] or text
end

local filePath = "dtslo/dtslo_urls.txt"
local screenURLs = {}
local isShuttingDown = false

local function LoadURLs()
    if not file.Exists("dtslo", "DATA") then
        file.CreateDir("dtslo")
    end

    if file.Exists(filePath, "DATA") then
        local data = file.Read(filePath, "DATA")
        screenURLs = util.JSONToTable(data) or {}
        print(Translate("urls_loaded"))
    else
        screenURLs = {}
        SaveURLs()
        print(Translate("no_urls_found"))
    end
end

local function SaveURLs()
    local data = util.TableToJSON(screenURLs)
    if not file.Exists("dtslo", "DATA") then
        file.CreateDir("dtslo")
    end
    file.Write(filePath, data)
    print(Translate("urls_saved"))
end

local function IsValidURL(url)
    return url:match("^https?://")
end

local function AddURLToTextScreen(ply, cmd, args)
    if not ply:IsAdmin() then
        ply:ChatPrint(Translate("admin_required"))
        return
    end

    if not args[1] then
        ply:ChatPrint(Translate("please_provide_url"))
        return
    end

    local url = args[1]

    if not IsValidURL(url) then
        ply:ChatPrint(Translate("invalid_url"))
        return
    end

    local trace = ply:GetEyeTrace()
    local ent = trace.Entity

    if not IsValid(ent) or ent:GetClass() ~= "sammyservers_textscreen" then
        ply:ChatPrint(Translate("not_looking_at_textscreen"))
        return
    end

    if screenURLs[ent:EntIndex()] then
        ply:ChatPrint(Translate("url_already_exists"))
        return
    end

    screenURLs[ent:EntIndex()] = url
    SaveURLs()
    ply:ChatPrint(Translate("url_added") .. ": " .. url)

    if DTSLO_Config.UseBillyLogs and pcall(require, "billy_logs") then
        local billy_logs = require("billy_logs")
        billy_logs.log(ply, "DTSLO_URL_ADD", "URL " .. url .. " zu Textscreen " .. ent:EntIndex() .. " hinzugefügt.")
    end
end

concommand.Add("dtslo_add", AddURLToTextScreen)

hook.Add("EntityRemoved", "DTSLO_RemoveURLOnDelete", function(ent)
    if isShuttingDown then return end

    if ent:GetClass() == "sammyservers_textscreen" then
        if screenURLs[ent:EntIndex()] then
            screenURLs[ent:EntIndex()] = nil
            SaveURLs()
            print(Translate("url_removed_from_textscreen"))

            if DTSLO_Config.UseBillyLogs and pcall(require, "billy_logs") then
                local billy_logs = require("billy_logs")
                billy_logs.log(nil, "DTSLO_URL_REMOVE", "URL für Textscreen " .. ent:EntIndex() .. " entfernt.")
            end
        end
    end
end)

hook.Add("PlayerUse", "DTSLO_OpenURLOnUse", function(ply, ent)
    if IsValid(ent) and ent:GetClass() == "sammyservers_textscreen" then
        local url = screenURLs[ent:EntIndex()]
        if url then
            net.Start("DTSLO_OpenURL")
            net.WriteString(url)
            net.Send(ply)

            if DTSLO_Config.UseBillyLogs and pcall(require, "billy_logs") then
                local billy_logs = require("billy_logs")
                billy_logs.log(ply, "DTSLO_URL_OPEN", "URL " .. url .. " wurde auf Textscreen " .. ent:EntIndex() .. " geöffnet.")
            end
        end
    end
end)

hook.Add("Initialize", "DTSLO_Initialize", function()
    LoadURLs()
    LoadTranslations()  
end)

local function RemoveURLFromTextScreen(ply, cmd, args)
    if not ply:IsAdmin() then
        ply:ChatPrint(Translate("admin_required"))
        return
    end

    local trace = ply:GetEyeTrace()
    local ent = trace.Entity

    if not IsValid(ent) or ent:GetClass() ~= "sammyservers_textscreen" then
        ply:ChatPrint(Translate("not_looking_at_textscreen"))
        return
    end

    if not screenURLs[ent:EntIndex()] then
        ply:ChatPrint(Translate("no_url_to_remove"))
        return
    end

    screenURLs[ent:EntIndex()] = nil
    SaveURLs()
    ply:ChatPrint(Translate("url_removed"))

    if DTSLO_Config.UseBillyLogs and pcall(require, "billy_logs") then
        local billy_logs = require("billy_logs")
        billy_logs.log(ply, "DTSLO_URL_REMOVE", "URL für Textscreen " .. ent:EntIndex() .. " gelöscht.")
    end
end

concommand.Add("dtslo_remove", RemoveURLFromTextScreen)

hook.Add("ShutDown", "DTSLO_Shutdown", function()
    isShuttingDown = true
end)
