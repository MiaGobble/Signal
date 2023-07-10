--!strict

local Signal = {}
Signal.__index = Signal

local Connection = {}
Connection.__index = Connection

function Connection.new(Signal, Callback)
	return setmetatable({
		Signal = Signal,
		Callback = Callback
	}, Connection)
end

function Connection.Disconnect(self)
	self.Signal[self] = nil
end


function Signal.new()
	return setmetatable({} :: any, Signal)
end

function Signal.Connect(self, Callback)
	local selfConnection = Connection.new(self, Callback)
	self[selfConnection] = true
	
	return selfConnection
end

function Signal.Once(self, Callback)
	local selfConnection; selfConnection = Connection.new(self, function(...)
		selfConnection:Disconnect()
		Callback(...)
	end)
	
	self[selfConnection] = true
	
	return selfConnection
end

function Signal.Wait(self)
	local waitingCoroutine = coroutine.running()
	
	local selfConnection; selfConnection = self:Connect(function(...)
		selfConnection:Disconnect()
		task.spawn(waitingCoroutine, ...)
	end)
	
	return coroutine.yield()
end

function Signal.DisconnectAll(self)
	table.clear(self)
end

function Signal.Fire(self, ...)
	if next(self) then
		for selfConnection in pairs(self) do
			selfConnection.Callback(...)
		end
	end
end

type Connection = {
	Disconnect: (self: any) -> ()
}

export type Signal<T...> = {
	Fire: (self: any, T...) -> (),
	Connect: (self: any, FN: (T...) -> ()) -> Connection,
	Once: (self: any, FN: (T...) -> ()) -> Connection,
	Wait: (self: any) -> T...,
	DisconnectAll: (self: any) -> ()
}

return Signal :: {new: () -> Signal<...any>}