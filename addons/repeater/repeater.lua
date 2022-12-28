--[[
* Ashita - Copyright (c) 2014 - 2016 atom0s [atom0s@live.com]
*
* This work is licensed under the Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License.
* To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-nd/4.0/ or send a letter to
* Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
*
* By using Ashita, you agree to the above license and its terms.
*
*      Attribution - You must give appropriate credit, provide a link to the license and indicate if changes were
*                    made. You must do so in any reasonable manner, but not in any way that suggests the licensor
*                    endorses you or your use.
*
*   Non-Commercial - You may not use the material (Ashita) for commercial purposes.
*
*   No-Derivatives - If you remix, transform, or build upon the material (Ashita), you may not distribute the
*                    modified material. You are, however, allowed to submit the modified works back to the original
*                    Ashita project in attempt to have it added to the original project.
*
* You may not apply legal terms or technological measures that legally restrict others
* from doing anything the license permits.
*
* No warranties are given.
]]--

addon.author   = 'bluekirby || v4 Port by ItallicNinja';
addon.name     = 'repeater';
addon.version  = '4.0.0';
addon.desc      = 'Allows a player to set a command to be repeated automatically';
addon.link      = 'https://ashitaxi.com/';

require('common');

local chat = require('chat');
local fonts = require('fonts');
local settings = require('settings');

local __go;
local __command;
local __timer;
local __cycle;

-- Default Settings
local default_settings = T{
    cycle = 1,
    jitter = 0,
};

--[[
* Prints the addon help information.
*
* @param {boolean} isError - Flag if this function was invoked due to an error.
--]]

local function print_help(isError)
    -- Print the help header..
    if (isError) then
        print(chat.header(addon.name):append(chat.error('Invalid command syntax for command: ')):append(chat.success('/' .. addon.name)));
    else
        print(chat.header(addon.name):append(chat.message('Available commands:')));
    end

    local cmds = T{
        { '/repeat set <cmd>', 'Toggles the fps font visibility.' },
        { '/repeat start', 'Displays the addons help information.' },
        { '/repeat stop', 'Sets the fps font visibility.' },
        { '/repeat cycle <seconds>', 'Reloads the addons settings from disk.' },
        { '/repeat help', 'Resets the addons settings to default.' },
    };

    -- Print the command list..
    cmds:ieach(function (v)
        print(chat.header(addon.name):append(chat.error('Usage: ')):append(chat.message(v[1]):append(' - ')):append(chat.color1(6, v[2])));
    end);
end


local function read_divisor() -- borrowed from fps addon
    local fpsaddr = ashita.memory.find('FFXiMain.dll', 0, '81EC000100003BC174218B0D', 0, 0);
    if (fpsaddr == 0) then
        print(chat.header(addon.name):append(chat.error('Could not locate required signature!')));
        return true;
    end

    -- Read the address..
    local addr = ashita.memory.read_uint32(fpsaddr + 0x0C);
    addr = ashita.memory.read_uint32(addr);
    return ashita.memory.read_uint32(addr + 0x30);
end;

local function quoted_concat(t, s, o)
    if (o == nil) then return ''; end
    if (o > #t) then return ''; end

    local ret = '';
    for x = o, #t do
        local spaces = string.find(t[x], " ");
        if (spaces) then
            ret = ret .. string.format('"%s"%s', t[x], s);
        else
            ret = ret .. string.format('%s%s', t[x], s);
        end
    end
    return ret;
end

--[[
* event: load
* desc : Event called when the addon is being loaded.
--]]
ashita.events.register('load', function()
    __go = false;
    __command = "";
    __timer = 0;
    __cycle = 5;
end );

--[[
* event: command
* desc : Event called when the addon is processing a command.
--]]
ashita.events.register('command', 'command_cb', function (e)
    -- Parse the command arguments..
    local args = cmd:args();
    if (args[1] ~= '/repeat') then
        return false;
    elseif (#args < 2) then
        return true;
    -- Handle: /repeat set - Set the command to repeat
    elseif ((args[2] == 'set') and (#args >= 3)) then
        __command = quoted_concat(args," ",3);
        __command = string.trim(__command);
        print(chat.header(addon.name):append(chat.message("Command to be repeated: " .. __command)));
        return true;
    -- Handle: /repeat start - Start repeater
    elseif (args[2] == 'start') then
        if(#__command > 1) then
            print(chat.header(addon.name):append(chat.message("Starting cycle!")));
            __go = true;
        else
            print(chat.header(addon.name):append(chat.message("Set a command first!")));
        end
        return true;
    -- Handle: /repeat stop - Stop repeater
    elseif (args[2] == 'stop') then
        __go = false;
        print(chat.header(addon.name):append(chat.message("Cycle Terminated!")));
        return true;
    -- Handle: /repeat cycle - Sets the cycle delay between commands (in seconds).
    elseif ((args[2] == 'cycle') and (#args == 3)) then
        __cycle = tonumber(args[3]);
        if(__cycle < 1) then __cycle = 1 end
        __timer = 0;
        print(chat.header(addon.name):append(chat.message("Commands will be executed every " .. __cycle .. " seconds!")));
        return;
    elseif (args[2] == 'help') then
        print_help(false);
        return;
    end
    -- Unhandled: Print help information..
    print_help(true);
    return false;
end );

--[[
* event: render
* desc : Event called when the addon is active.
--]]
ashita.events.register('render', function()
    if(__go) then
        if(__timer == (60 / read_divisor() * __cycle)) then
            AshitaCore:GetChatManager():QueueCommand(__command, 1);
            __timer = 0;
        else
            __timer = __timer + 1;
        end
    end
end );