local event = require('event')
local ffi = require('ffi')
local packet = require('packet')
local shared = require('shared')
local string = require('string')
local math = require('math')
local table = require('table')
local types = require('types')
local os = require('os')

packets = shared.new('packets')

local registry = {}
local history = {}

local amend_packet
amend_packet = function(packet, cdata, ftype)
    local count = ftype.count
    if count then
        for i = 0, count - 1 do
            local inner_value = cdata[i]
            if type(inner_value) == 'cdata' then
                local inner = packet[i]
                if not inner then
                    inner = {}
                    packet[i] = inner
                end
                amend_packet(inner, inner_value, ftype.base)
            else
                packet[i] = inner_value
            end
        end
        return
    end

    for key, value in pairs(cdata) do
        if type(value) == 'cdata' then
            local inner = packet[key]
            if not inner then
                inner = {}
                packet[key] = inner
            end
            amend_packet(inner, value, ftype.fields[key].type)
        else
            packet[key] = value
        end
    end
end

local parse_single
do
    local math_floor = math.floor
    local ffi_copy = ffi.copy
    local ffi_new = ffi.new

    parse_single = function(packet, ptr, ftype, size)
        if ftype == nil then
            return
        end

        if ftype.multiple == nil then
            local instance
            local size = ftype.size
            local var_size = ftype.var_size
            if var_size then
                instance = ffi_new(ftype.name, math_floor((size - size) / var_size))
            else
                instance = ffi_new(ftype.name)
            end
            ffi_copy(instance, ptr, size)

            amend_packet(packet, instance, ftype)
            return
        end

        local base = ftype.base
        local indices = {parse_single(packet, ptr, base, size)}
        local size_diff = base.size
        ptr = ptr + size_diff
        size = size - size_diff

        do
            local lookups = ftype.lookups
            local base_index = #indices
            for i = 1, #lookups do
                indices[base_index + i] = packet[lookups[i]]
            end
        end

        local new_type = ftype
        for i = 1, #indices do
            local index = indices[i]
            new_type = new_type[index]

            if new_type == nil then
                return unpack(indices)
            end
        end

        do
            local new_indices = {parse_single(packet, ptr, new_type, size)}
            local base_index = #indices
            for i = 1, #new_indices do
                indices[base_index + i] = new_indices[i]
            end
        end

        return unpack(indices)
    end
end

packets.env = {}

packets.env.get_last = function(path)
    return history[path]
end

do
    local event_new = event.new

    packets.env.make_event = function(path)
        local events = registry[path]
        if not events then
            events = {}
            registry[path] = events
        end

        local event = event_new()
        events[#events + 1] = event

        return event
    end
end

local process_packet = function(packet, path)
    local events = registry[path]
    if events then
        for i = 1, #events do
            events[i]:trigger(packet)
        end
    end

    history[path] = packet
end

local make_timestamp
do
    local os_time = os.time

    local last_time = os_time()
    local now_count = 0

    make_timestamp = function()
        local now = os_time()
        if last_time == now then
            now_count = now_count + 1
            return now + now_count / 10000
        end

        now_count = 0
        last_time = now
        return now
    end
end

local handle_packet
do
    local char_ptr = ffi.typeof('char const*')

    handle_packet = function(direction, raw)
        local id = raw.id
        local data = raw.data

        local packet = {
            direction = direction,
            id = id,
            data = data,
            blocked = raw.blocked,
            modified = raw.modified,
            injected = raw.injected,
            timestamp = make_timestamp(),
        }

        local indices = {direction, id, parse_single(packet, char_ptr(data), types[direction][id], #data)}

        local path = ''
        process_packet(packet, path)

        for i = 1, #indices do
            path = path .. '/' .. tostring(indices[i])
            process_packet(packet, path)
        end
    end
end

packet.incoming:register(function(raw)
    handle_packet('incoming', raw)
end)

packet.outgoing:register(function(raw)
    handle_packet('outgoing', raw)
end)

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
