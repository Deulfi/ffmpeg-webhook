-- MPV Script to send stream URLs to webhook server for download
-- Place this file in: 
--   Linux: ~/.config/mpv/scripts/ffmpeg_webhook.lua
--   Windows: %APPDATA%/mpv/scripts/ffmpeg_webhook.lua

-- put 'ctrl+d script-message-to ffmpeg_webhook download-ffmpeg'  in input.conf if no uosc available
-- put controls=button:ffmpeg_webhook (name of this script) in uosc.conf for the uosc button

-- Configuration
local WEBHOOK_URL = "http://YourIP:YourPort/hooks/download-stream"

local mp = require 'mp'
local utils = require 'mp.utils'
local msg = require 'mp.msg'
local script_name = mp.get_script_name()
local uosc_present = false


-- Detect operating system
local function get_os()
    local os_name = ""
    -- Check if we're on Windows
    if package.config:sub(1,1) == '\\' then
        os_name = "windows"
    else
        os_name = "linux"
    end
    return os_name
end

-- Get the current stream URL from mpv
local function get_stream_url()
    local path = mp.get_property("path")
    if not path then
        msg.error("No stream URL found")
        return nil
    end
    return path
end

-- Get filename from user input or use default
local function get_filename()
    -- Get the media title if available
    local title = mp.get_property("media-title")
    
    -- Clean up the title to make it filename-safe
    if title then
        -- Remove file extension if present
        title = title:match("(.+)%..+$") or title
        -- Remove special characters
        title = title:gsub("[^%w%s%-_]", "_")
    else
        -- Use timestamp as fallback
        title = os.date("stream_%Y%m%d_%H%M%S")
    end
    

    return title
end

-- Send download request to webhook server
local function download_stream()
    local url = get_stream_url()
    
    if not url then
        mp.osd_message("Error: No stream URL found", 3)
        return
    end
    
    local filename = get_filename()
    
    msg.info("Sending download request for: " .. url)
    msg.info("Filename: " .. filename)

    local function execute_command(filename)

       -- Check if filename has any extension
        if not filename:match("%.%w+$") then
            filename = filename .. ".mp4"
        end

        -- Prepare JSON payload
        local json_payload = string.format('{"url":"%s","name":"%s"}', url, filename)
        
        -- Prepare curl command based on OS
        local os_type = get_os()
        local curl_command
        
        if os_type == "windows" then
            -- Windows curl command
            curl_command = {
                "curl.exe",
                "-X", "POST",
                WEBHOOK_URL,
                "-H", "Content-Type: application/json",
                "-d", json_payload
            }
        else
            -- Linux curl command
            curl_command = {
                "curl",
                "-X", "POST",
                WEBHOOK_URL,
                "-H", "Content-Type: application/json",
                "-d", json_payload
            }
        end
        
        -- Execute curl command
        local result = utils.subprocess({
            args = curl_command,
            cancellable = false
        })
        
        -- Check result
        if result.status == 0 then
            mp.osd_message("Download started: " .. filename, 3)
            msg.info("Download request sent successfully")
        else
            mp.osd_message("Error: Download request failed", 3)
            msg.error("Failed to send download request")
            msg.error("Error: " .. (result.error or "Unknown error"))
        end
    end

    --get userinput for filename
    local input = require 'mp.input'
    input.get({
        default_text = filename,
        prompt = "Enter filename:",
        submit = function (name)
            execute_command(name)
        end,
    })
    
end


-- Script message interface for other scripts
mp.register_script_message("download-ffmpeg", download_stream)


mp.register_script_message('uosc-version', function(version)
    uosc_present = true
    mp.commandv('script-message-to', 'uosc', 'set-button', script_name, utils.format_json({
        icon = "download",
        tooltip = "Send current stream to FFmpeg webhook",
        command = "script-message download-ffmpeg",
        hide = false,
    }))
end)

if not uosc_present then
    mp.commandv('script-message-to', 'uosc', 'set-button', script_name, utils.format_json({icon = "", hide = true}))
end
