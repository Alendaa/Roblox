--!strict

local Event = require("./Event")

export type new = <T>(Value: T) -> Value

type Meta = {
    __call: (self: Value, ...any) -> any,
    new: new
}

export type Value = typeof(setmetatable({} :: {
    __call: (...any) -> any,
    Value: any,
    Event: Event.Event,
}, {} :: Meta))

local module: Meta = {} :: Meta
module.__call = function(self, ...): any
    local Value = table.pack(..., nil)[1] -- the nil exclude every value after index 1

    local OldValue = self.Value
    self.Value = if Value ~= nil then Value else self.Value

    self.Event:Fire(Value)

    return OldValue
end

function module.new<T>(Value: T): Value
    if typeof(Value) == "nil" then
        return (nil :: any) :: Value
    end

    local self: Value = setmetatable({}, module) :: Value
    self.Value = Value
    self.Event = Event.new()

    return self
end

return module
