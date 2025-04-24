--!strict

type VoidMeta = {
	__index: VoidMeta,
	new: (Gui: {[string]: any}, Parent: VoidGui?) -> VoidGui,
	Add: (self: VoidGui, Gui: {[string]: any}) -> VoidGui,
	Remove: (self: VoidGui) -> (),
	SetPropertyValue: (self: VoidGui, Property: string, Value: any) -> (),
	GetPropertyValue: (self: VoidGui, Property: string) -> any,
	Tween: (self: VoidGui, TweenInfo: TweenInfo, Value: {[string]: any}) -> Tween,
	Connect: (self: VoidGui, EventName: string, Function: (self: VoidGui, ...any) -> ()) -> (),
	Disconnect: (self: VoidGui, EventName: string) -> boolean,
	FindFirstChild: (self: VoidGui, Name: string, Recursive: boolean?) -> VoidGui,
	Destroy: (self: VoidGui) -> (),
}



export type VoidGui = typeof(setmetatable({} :: {
	VoidID: string,
	Values: {[string]: any},
	Children: {[string]: {Name: string, Child: VoidGui}},
	Connections: {[string]: RBXScriptConnection},
	Parent: VoidGui?,
	Instance: Instance
}, {} :: VoidMeta))

local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local RobloxInstance = Instance

local module: VoidMeta = {} :: VoidMeta
module.__index = module

local DefaultFolder = script:FindFirstChild("Default")
local DefaultInstances: {[string]: Instance} = {}

local ReservedWords = {
	Children = function(self: VoidGui, Gui: {[string]: any})
		for _, Properties in Gui.Children do
			local Child = module.new(Properties, self)
			self.Children[Child.VoidID] = {
				Name = Properties.Name or Properties.Class,
				Child = Child,
			}
		end
	end,

	Events = function(self: VoidGui, Gui: {[string]: any})
		for EventName: string, Function in Gui.Events :: {[string]: (self: VoidGui, ...any) -> ()} do
			local Signal = (self.Instance :: any)[EventName] :: RBXScriptSignal
			self.Connections[EventName] = Signal:Connect(function(...)
				Function(self, ...)
			end)
		end
	end,
}

local SkipWords = {
	Values = true,
	Class = true,
	Parent = true
}

local function HasProperty(Object: Instance, Property: string): (boolean, any)
	return pcall(function()
		return (Object :: any)[Property]
	end)
end

if DefaultFolder then
	for _, Module: ModuleScript in DefaultFolder:GetDescendants() do
		if not Module:IsA("ModuleScript") then
			continue
		end

		local DefaultInstance = RobloxInstance.new(Module.Name)
		for Property, Value in require(Module) :: {[string]: any} do
			DefaultInstance[Property] = Value
		end
		
		DefaultInstances[Module.Name] = DefaultInstance
	end
end

function module.new(Gui: {[string]: any}, Parent: VoidGui?): VoidGui
	if typeof(Parent) ~= "table" and Parent ~= nil then
		error("Type of Parent ~= table")
	elseif typeof(Parent) == "table" and getmetatable(Parent) ~= module then
		error("Type of Parent ~= VoidGui")
	end

	local self: VoidGui = setmetatable({}, module) :: VoidGui

	if typeof(Gui) ~= "table" then
		return self
	end

	local Class = Gui.Class
	if not Class then
		error("Index Class not found.")
	end
	local Instance = if DefaultInstances[Class] then DefaultInstances[Class]:Clone() else RobloxInstance.new(Class)

	self.VoidID = HttpService:GenerateGUID(false)
	self.Values = if Gui.Values then table.clone(Gui.Values) else {}
	self.Children = {}
	self.Connections = {}
	self.Parent = Parent
	self.Instance = Instance

	for Property: string, Value: any in next, Gui do
		if SkipWords[Property] then
			continue
		end

		local PropertyExist, ReturnedValue = HasProperty(Instance, Property)
		local IsReserved = ReservedWords[Property]

		if not PropertyExist and not IsReserved then
			error(ReturnedValue)
		end

		if IsReserved then
			IsReserved(self, Gui)
			continue
		end

		Instance[Property] = Value
	end
	
	if Parent and not Parent.Children[self.VoidID] then
		Parent.Children[self.VoidID] = {
			Name = Gui.Name or Gui.Class,
			Child = self,
		}
	end
	
	Instance.Parent = 
		if Gui.Parent == nil and Parent then Parent.Instance
		elseif typeof(Gui.Parent) == "Instance" then Gui.Parent
		elseif typeof(Gui.Parent) == "table" and getmetatable(Gui.Parent) == module then Gui.Parent.Instance
		else error(`Type of the index Parent is {typeof(Gui.Parent)}, it needs to be VoidGui or Instance`)

	return self
end

function module:Add(Gui: {[string]: any}): VoidGui
	return module.new(Gui, self)
end

function module:SetPropertyValue(Property: string, Value: any): ()
	local Instance = self.Instance

	local PropertyExist, ReturnedValue = HasProperty(Instance, Property)
	if not PropertyExist then
		error(ReturnedValue)
	end
	
	(Instance :: any)[Property] =
		if Property == "Parent" and typeof(Value) == "table" and getmetatable(Value) == module then Value.Instance
		else Value
end

function module:GetPropertyValue(Property: string): any
	return select(2, HasProperty(self.Instance, Property))
end

function module:Tween(TweenInfo: TweenInfo, Value: {[string]: any}): Tween
	return TweenService:Create(self.Instance, TweenInfo, Value)
end

function module:Connect(EventName: string, Function: (self: VoidGui, ...any) -> ()): ()
	if self.Connections[EventName] then
		return
	end

	local Instance = self.Instance
	local EventExist, Signal: RBXScriptSignal = HasProperty(Instance, EventName)
	if not EventExist then
		error(Signal)
	end

	self.Connections[EventName] = Signal:Connect(function(...)
		Function(self, ...)
	end)
end

function module:Disconnect(EventName: string): boolean
	if not self.Connections[EventName] then
		return false
	end

	self.Connections[EventName]:Disconnect()
	self.Connections[EventName] = nil

	return true
end

function module:FindFirstChild(Name: string, Recursive: boolean?): VoidGui
	local Child: VoidGui = nil
	for _, v in self.Children do
		if v.Name == Name then
			Child = v.Child
			break
		end
	end
	
	if Recursive then
		for _, v in self.Children do
			v.Child:FindFirstChild(Name, true)
		end
	end

	return Child
end

function module:Destroy(): ()
	for _, v in self.Children do
		v.Child:Destroy()
	end
	
	table.clear(self.Children)
	table.clear(self.Connections)

	self.Instance:Destroy()
	
	if self.Parent then
		self.Parent.Children[self.VoidID] = nil
	end
	
	for i, Connection: RBXScriptConnection in self.Connections do
		Connection:Disconnect()
		self.Connections[i] = nil
	end
end

return module
