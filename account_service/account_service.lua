local event = require('event')
local memory = require('memory')
local packets = require('packets')
local resources = require('resources')
local server = require('shared.server')
local structs = require('structs')

local data = server.new(structs.struct({
    logged_in           = {structs.bool},
    name                = {structs.string(0x10)},
    id                  = {structs.int32},
    server              = {structs.int32, lookup=resources.servers},
    login               = {data=event.new()},
    logout              = {data=event.new()},
}))

local login_event = data.login
local logout_event = data.logout

packets.incoming:register_init({
    [{0x00A}] = function(p)
        local login = not data.logged_in
        if not login then
            return
        end

        coroutine.schedule(function()
            local info = memory.account_info
            while info.server_id == -1 do
                coroutine.sleep_frame()
            end

            data.name = info.name
            data.id = info.id
            data.server = info.server_id % 0x20
            data.logged_in = true

            login_event:trigger()
        end)
    end,
    [{0x00B, 0x01}] = function(p)
        local logout = p.type == 1
        if not logout then
            return
        end

        data.logged_in = false
        data.server = 0
        data.name = ''
        data.id = 0

        logout_event:trigger()
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
