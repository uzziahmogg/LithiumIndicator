-------------------------------------------------------------------------------
-- class IndexWindows - saves part of array _from index with _size
-------------------------------------------------------------------------------
function IndexWindows(_from, _size)
	-- class values
	-- Indexes - inner array of indexes, Values - inner array of values
	local Windows = { From = _from, Size = _size, Indexes = {}, Values = {} }

	-- class methods
	-- get item value with array index
	function _GetItem(_self, _index)
		if ((_index >= _self.From) and (_index <= (_self.From + _self.Size - 1))) then
			local idx = _index - _self.From + 1
			return _self.Indexes[idx], _self.Values[idx]
		end
		return nil
	end

	-- class values
	-- metamethods for function overloading
	setmetatable(Windows, { __index = { GetItem = _GetItem } })

	-- class methods
	-- class constructor clojure
	return function()
		return Windows
	end
end

-------------------------------------------------------------------------------
-- Add item - index and value to IndexWindows with checking hit inside IndexWindows
-- _index is global candle index
-------------------------------------------------------------------------------
function IndexWindowsAddItem(_windows, _index, _value)
	if (_index == 1) then
		_windows.Indexes = {}
		_windows.Values = {}
	end

	-- append close price to end of IndexWindows
	if (--[[CandleExist(index) and]] (_index >= _windows.From) and (_index <= (_windows.From + _windows.Size - 1))) then
		table.insert(_windows.Indexes, _index - _windows.From + 1, _index)
		table.insert(_windows.Values, _index - _windows.From + 1, _value)
		return true
	end

			-- remove first items of IndexWindow if IndexWindow growth up max Size
		--[[if ((#_windows.Indexes > _windows.Size) and (#_windows.Values > _windows.Size)) then
			table.remove(_windows.Indexes, 1)
			table.remove(_windows.Values, 1)
		end]]

	return false
end

-- create objects
x = IndexWindows(11, 33)()
z = IndexWindows(27, 44)()

print("---------------")
print("x: " .. tostring(x) .. "\tz: " .. tostring(z))
print("x.From: " .. tostring(x.From) .. "\tz.From " .. tostring(z.From))
print("x.Size: " .. tostring(x.Size) .. "\tz.Size " .. tostring(z.Size))
print("x.Indexes: " .. tostring(x.Indexes) .. "\tz.Indexes: " .. tostring(z.Indexes))
print("x.Values: " .. tostring(x.Values) .. "\tz.Values: " .. tostring(z.Values))
print("---------------")

for i = 1, 50 do
    IndexWindowsAddItem(x, i, i/2)
	IndexWindowsAddItem(z, i, i*2)
end

--~ for i = 1, 50 do
--~     print('[' .. i .. ']: ' .. '\tx[' .. tostring(x.Indexes[i]).. "]=" .. tostring(x.Values[i]) .. '\tz[' .. tostring(z.Indexes[i]).. "]=" .. tostring(z.Values[i]))
--~ end

for i = 1, 50 do
	local xi, xv = x:GetItem(i + x.From - 1)
	local zi, zv = z:GetItem(i + z.From - 1)
    print('[' .. i .. ']:\tx[' .. tostring(xi) .. "]=" .. tostring(xv) .. '\tz[' .. tostring(zi) .. "]=" .. tostring(zv))
end

for i = 1, 50 do
	local xi, xv = _GetItem(x, i + x.From - 1)
	local zi, zv = _GetItem(z, i + z.From - 1)
    print('[' .. i .. ']:\tx[' .. tostring(xi) .. "]=" .. tostring(xv) .. '\tz[' .. tostring(zi) .. "]=" .. tostring(zv))
end

