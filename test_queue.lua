-------------------------------------------------------------------------------
-- class IndexWindows - saves part of global array _from index with _size
-------------------------------------------------------------------------------
function IndexWindows(_size)
    -- local class methods used inside class
    -----------------------------------------
    -- check index hit inside window border
    -- _index is global candle index
    local function _CheckIndex(_self, _index)
        return ((_index >= _self.From) and (_index <= (_self.From + _self.Size - 1)))
    end

    -- get size of global array
    -- must be replaced with qlua Size()!
    local function _Size()
    return 100
end

    -- class values
    -----------------------------------
    -- Indexes - inner array of indexes
    -- Values - inner array of values
    -- From - starting global index
    -- Size - size of IndexWindow
    local Windows = { From = (_Size() - _size + 1 > 0) and (_Size() - _size + 1) or 1,
                      Size = _size,
                      Indexes = {},
                      Values = {},
                      _metatable = {} }

    -- class methods
    ----------------------------------
    -- get item value with array index
    -- _index is global candle index
    function _GetItem(_self, _index)
        if (_CheckIndex(_self, _index)) then
           -- _idx index in IndexWindows
           -- Indexes[_idx] == _index!
            local _idx = _index - _self.From + 1
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

    -- class constructor
    --------------------
    -- return clojure
    return function()
       -- set metamethods for function overloading and using class object sintax sugar
       Windows._metatable = { __index = { GetItem = _GetItem, AddItem = _AddItem } }
       setmetatable(Windows, Windows._metatable)

        return Windows
    end
end

-- test class
-------------------------------------------------------------------------------
-- create objects
x = IndexWindows(10)()
z = IndexWindows(44)()

-- set index and values to objects IndexWindow using two syntax class object and fucntions
for i = 1, 100 do
    _AddItem(x, i, i/2)
    z:AddItem(i, i*2)
end

-- get index and  values using old syntax via direct accesss to array items
for i = 1, 100 do
    print('[' .. i .. ']: ' .. '\tx[' .. tostring(x.Indexes[i]).. "]=" .. tostring(x.Values[i]) .. '\tz[' .. tostring(z.Indexes[i]).. "]=" .. tostring(z.Values[i]))
end

-- get index and values from objects IndexWindow using two syntax class object and fucntions
for i = 1, 100 do
    local xi, xv = x:GetItem(i + x.From - 1)
    local zi, zv = _GetItem(z, i + z.From - 1)
    print('[' .. i .. ']:\tx[' .. tostring(xi) .. "]=" .. tostring(xv) .. '\tz[' .. tostring(zi) .. "]=" .. tostring(zv))
end

-- EOF
