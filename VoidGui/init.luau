--!strict

local ComponentValue = require("./VoidGui/Components/Value")

type Structure<T> = {[string]: any,}

type Meta = {
	__index: Meta,
	__newindex: (t: Gui<any>, k: any, v: any) -> (),

	New: <T>(Structure: {[string]: any}) -> Gui<T>,
	Value: ComponentValue.new
}

export type Gui<T> = {
	_Children: {[Gui<T>]: {Value: Gui<T>, Name: string}?},
	_Connections: {[number]: () -> ()?},
	_Instance: T?,
} & T

type Keys = {
	Reserved: {[string]: (Structure: Structure<any>, self: Gui<any>, Object: Instance) -> ()},
	Ignore: {[string]: boolean}
}

local module: Meta = {} :: Meta
module.__index = module
module.__newindex = function(t, k, v)
	local Object = t._Instance
	if not Object then
		return
	end

	(Object :: any)[k] = v
end

local Keys: Keys = {} :: Keys
Keys.Reserved = {
	Children = function(Structure: Structure<any>, self: Gui<any>)
		for _, Properties in Structure.Children do
			if Properties.Parent == nil then
				Properties.Parent = self
			end

			task.defer(function()
				local Child = module.New(Properties);
				(self._Children :: any)[Child] = {
					Value = Child,
					Name = Structure.Name or Structure.Class
				}
			end)
		end
	end,

	Events = function(_Structure: Structure<any>, _self: Gui<any>)
		
	end,

	Parent = function(Structure: Structure<any>, _, Object: Instance)
		local Parent = Structure.Parent
		local ParentType = typeof(Parent)

		if ParentType ~= "table" and ParentType ~= "nil" and ParentType ~= "Instance" then
			error("Unsuported type of Parent.", 2)
		end

		Object.Parent = if ParentType == "Instance" then Parent
			elseif ParentType == "table" and getmetatable(Parent) == module then Parent._Instance
			else nil
	end
}

Keys.Ignore = {
	Class = true,
}

local function HasProperty(Object: any, Property: any): (boolean, any)
	return pcall(function()
		return Object[Property]
	end)
end


local function StructureToInstance<T>(Structure: {[string]: any}, self: Gui<T>): T
	local Class = Structure.Class
	if typeof(Class) ~= "string" then
		error(`Type of index Class is {typeof(Class)} ~= string.`, 2)
	end
	
	local Object = (Instance.new(Class) :: any) :: T

	for Property: string, Value: any in Structure do
		if Keys.Ignore[Property] then
			continue
		elseif Keys.Reserved[Property] then
			Keys.Reserved[Property](Structure, self, Object :: any)
			continue
		end

		local PropertyExist, ReturnedValue = HasProperty(Object, Property)
		if not PropertyExist then
			error(ReturnedValue, 2)
		end 	
		
		if typeof(Value) and typeof(ReturnedValue) == "function" then
			error("Use events index.")
		end
		
		if typeof(Value) == "table" and getmetatable(Value) == ComponentValue then
			(Object :: any)[Property] = Value();

			table.insert(self._Connections, (Value :: ComponentValue.Value).Event:Connect(function(NewValue: any)
				(Object :: any)[Property] = NewValue
			end))

			continue
		end

		(Object :: any)[Property] = Value
	end

	return Object
end

function module.New<T>(Structure: Structure<T>): Gui<T>
	local self = {}	
	self._Children = {}
	self._Connections = {}
	self._Instance = StructureToInstance(Structure, self :: Gui<T>)

	return setmetatable(self, module) :: Gui<T>
end

module.Value = ComponentValue.new

return module
