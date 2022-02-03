-------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------
function IndexWindowConstructor(_from, _size)
	local Windows = { From = _from, Size = _size, Indexes = {}, Values = {} }

	return function()
		return Windows
	end
end

-------------------------------------------------------------------------------
-- Add item - index and value to IndexWindow with checking hit inside IndexWindow
-- _index is global candle index
-------------------------------------------------------------------------------
function IndexWindowAddItem(_windows, _index, _value)
	if (_index == 1) then
		_windows.Indexes = {}
		_windows.Values = {}
	end

	-- append close price to end of IndexWindow
	if (--[[CandleExist(index) and]] (_index >= _windows.From) and (_index <= (_windows.From + _windows.Size))) then
		table.insert(_windows.Indexes, _index - _windows.From + 1, _index)
		table.insert(_windows.Values, _index - _windows.From + 1, _value)

		-- remove first items of IndexWindow if IndexWindow growth up max Size
		--[[if ((#_windows.Indexes > _windows.Size) and (#_windows.Values > _windows.Size)) then
			table.remove(_windows.Indexes, 1)
			table.remove(_windows.Values, 1)
		end]]

		return true
	end

	return false
end

-------------------------------------------------------------------------------
-- Get item - value by index in window not in array
-- _index is global candle index
-------------------------------------------------------------------------------
function IndexWindowGetItem(_windows, _index)
	if ((_index >= _windows.From) and (_index <= (_windows.From + _windows.Size))) then
		return _windows.Values[_index - _windows.From + 1]
	end
	return nil
end

-- constructor
x = IndexWindowConstructor(11, 33)()
z = IndexWindowConstructor(27, 44)()

print("---------------")
print("x: " .. tostring(x) .. "\tz: " .. tostring(z))
print("x.From: " .. tostring(x.From) .. "\tz.From " .. tostring(z.From))
print("x.Size: " .. tostring(x.Size) .. "\tz.Size " .. tostring(z.Size))
print("x.Indexes: " .. tostring(x.Indexes) .. "\tz.Indexes: " .. tostring(z.Indexes))
print("x.Values: " .. tostring(x.Values) .. "\tz.Values: " .. tostring(z.Values))
print("---------------")

for i = 1, 50 do
    IndexWindowAddItem(x, i, i/2)
	IndexWindowAddItem(z, i, i*2)
end

for i = 1, 50 do
    print('[' .. i .. ']: ' .. '\tx[' .. tostring(x.Indexes[i]).. "]=" .. tostring(x.Values[i]) .. '\tz[' .. tostring(z.Indexes[i]).. "]=" .. tostring(z.Values[i]))
end

