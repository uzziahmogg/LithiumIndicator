-------------------------------------------------------------------------------
-- class IndexWindows - saves part of array _from index with _size
-------------------------------------------------------------------------------
function IndexWindows(_size)
    -- class values
    -------------------------------------------------------------------
    -- Indexes - inner array of indexes, Values - inner array of values
   local Windows = { From = (Size() - _size + 1 > 0) and (Size() - _size + 1) or 1, Size = _size, Indexes = {}, Values = {} }

    -- class methods
    ---------------------------------------
    -- check index hit inside window border
    function _CheckIndex(_self, _index)
        return ((_index >= _self.From) and (_index <= (_self.From + _self.Size - 1)))
    end

    ----------------------------------
    -- get item value with array index
    -- _index is global candle index
    function _GetItem(_self, _index)
        if (_CheckIndex(_self, _index)) then
            local _idx = _index - _self.From + 1
            -- _index must be equal Indexes[_idx]
            return _self.Indexes[_idx], _self.Values[_idx]
        end
        return nil
    end

    -------------------------------------------------------------------------
    -- add item - store index and value to IndexWindows with checking borders
    -- _index is global candle index
    function _AddItem(_self, _index, _value)
       -- check index hit inside index window
        if (not _CheckIndex(_self, _index)) then
            return nil
        end

        -- if start of index then reinit Indexes and Values arrays
        if (_index == 1) then
            _self.Indexes = {}
            _self.Values = {}
        end

        -- append value to end of IndexWindows array
        if (--[[CandleExist(index) and]] (_index >= _self.From)) then
            table.insert(_self.Indexes, _index - _self.From + 1, _index)
            table.insert(_self.Values, _index - _self.From + 1, _value)
        end

        -- remove first items of IndexWindow array if IndexWindow growth up max Size
        if ((#_self.Indexes > _self.Size) and (#_self.Values > _self.Size)) then
            table.remove(_self.Indexes, 1)
            table.remove(_self.Values, 1)
            _self.From = _self.From - 1
        end

        return _self.Indexes[#_self.Indexes], _self.Values[#_self.Values]
    end

    -- class values
    -------------------------------------------
    -- set metamethods for function overloading
    _metatable = { __index = { GetItem = _GetItem, AddItem = _AddItem } }
    setmetatable(Windows, _metatable)

    -- class methods
    ----------------------------
    -- class constructor clojure
    return function()
        return Windows

-- test class
-------------------------------------------------------------------------------
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
    _AddItem(x, i, i/2)
    _AddItem(z, i, i*2)
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
