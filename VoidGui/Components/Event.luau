--!strict

type Meta = {
    __index: Meta,
    new: () -> Event,
    Fire: (...any) -> ...any,
    Connect: (self: Event, func: (...any) -> ...any) -> Connection,
}

export type Connection = () -> ()

export type Event = typeof(setmetatable({} :: {
    Connections: {[number]: (...any) -> ()?},
}, {} :: Meta))

local module = {}
module.__index = module

function module.new(): Event
    local Event: Event = setmetatable({}, module) :: Event
    Event.Connections = {}

    return Event
end

function module:Fire(...): ()
    for _, func in self.Connections do
        func(...)
    end
end

function module:Connect(func: (...any) -> ()): Connection
    table.insert(self.Connections, func)
    local Position = #self.Connections

    return coroutine.wrap(function()
        local Diff = Position - #self.Connections
        table.remove(self.Connections, if Diff <= 0 then Position else Position - Diff)
    end)
end

return module
