local packets = require('packets')
local server = require('shared.server')
local structs = require('structs')

local ls_struct = structs.struct({
    name                = {structs.string(0x14)},
    permissions         = {structs.uint32},
    color               = {structs.struct({
        red                 = {structs.uint8},
        green               = {structs.uint8},
        blue                = {structs.uint8},
    })},
    lsmes               = {structs.struct({
        message             = {structs.string(0x80)},
        player_name         = {structs.string(0x10)},
        timestamp           = {structs.uint32},
    })},
    bag_index           = {structs.uint8},
})

local data, events = server.new(structs.struct({
    [1]                 = {ls_struct},
    [2]                 = {ls_struct},
}))

local handle_0CC = function(p)
    local ls_data = data[p.linkshell_index + 1]

    ls_data.name = p.linkshell_name
    ls_data.permissions = p.permissions
    ls_data.lsmes.message = p.message
    ls_data.lsmes.timestamp = p.timestamp
    ls_data.lsmes.player_name = p.player_name
end

packets.incoming:register_init({
    [{0x0CC, 0}] = handle_0CC,
    [{0x0CC, 1}] = handle_0CC,
    [{0x037}] = function(p)
        local ls_data = data[1]

        ls_data.color.red = p.linkshell1_red
        ls_data.color.green = p.linkshell1_green
        ls_data.color.blue = p.linkshell1_blue
    end,
    [{0x0E0}] = function(p)
        local ls_data = data[p.linkshell_number]

        ls_data.bag_index = p.bag_index
        if ls_data.bag_index ~= 0 then
            return
        end

        ls_data.name = ''
        ls_data.permissions = 0
        ls_data.color.red = 0
        ls_data.color.green = 0
        ls_data.color.blue = 0
        ls_data.lsmes.message = ''
        ls_data.lsmes.player_name = ''
        ls_data.lsmes.timestamp = 0
    end,
})

--[[
Copyright © 2018, Windower Dev Team
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Windower Dev Team nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE WINDOWER DEV TEAM BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]
