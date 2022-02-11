----------------------------------------------------------------------------
-- additional table functions
----------------------------------------------------------------------------
--
-- table.val_to_str
--
function table.val_to_str(v)
   -- if v is string
    if (type(v) == "string")  then
        -- replace \n to \\n
        v = string.gsub(v, "\n", "\\n")
        -- if string have " and not have ' return string wraped in '
        if string.match(string.gsub(v, "[^'\"]", ""), '^"+$') then
            return "'" .. v .. "'"
        end
        -- replace " to \" return result string wraped in "
        return '"' .. string.gsub(v, '"', '\\"') .. '"'
    end
   -- if v is table try it convert to string default return string consist pointer to table
    return (type(v) == "table") and table.tostring(v) or tostring(v)
end

--
-- table.key_to_str
--
function table.key_to_str(k)
   -- if k is string and start with _letter then _letter digit return k
    if ((type(k) =="string") and string.match(k, "^[_%a][_%a%d]*$")) then
        return k
    end
    -- return k converted to string with conversion " and wrapped in ' or " and wraped in []
    return "[" .. table.val_to_str(k) .. "]"
end

--
-- table.tostring
--
function table.tostring(tbl)
    -- if tbl isnt table return tbl with conversion " and wrapped in ' or " and wraped in []
    if (type(tbl) ~= 'table') then
        return table.val_to_str(tbl)
    end

    -- insert value converted to string with integer index to table result
    local result, done = {}, {}
    for k, v in ipairs(tbl) do
        table.insert(result, table.val_to_str(v))
        done[k] = true
    end

    -- insert pairs key=value converted to strings with noninteger index to result table
    for k, v in pairs(tbl) do
        if not done[k] then
            table.insert(result, table.key_to_str(k) .. "=" .. table.val_to_str(v))
        end
    end

    -- return string is concated result table
    return "{" .. table.concat(result, ",") .. "}"
end

--
-- table.load
--
function table.load(fname)
   -- open file to read
    local f, err = io.open(fname, "r")
    if (f == nil) then
        return {}
    end

    -- read table from file and return function returning table
	local _loadfunc
	if (string.match(_VERSION, "(%d.%d)") == "5.1") then
		_loadfunc = loadstring
	else
		_loadfunc = load
	end

    local fn, err = _loadfunc("return " .. f:read("*a"))
    f:close()

    -- call readed function under protected mode
    if (type(fn) == "function") then
       local succ, res = pcall(fn)
       -- return readed table
        if (succ and type(res) == "table") then
            return res
        end
    end
    return {}
end

--
-- table.save
--
function table.save(fname, tbl)
   -- open file to wriet
   local f, err = io.open(fname, "w")
   -- write table converted to string to file
    if (f ~= nil) then
        f:write(table.tostring(tbl))
        f:close()
    end
end

--
-- test
--

tbl = {1,2,3,"aaa", "bb'bb", 4,5,{6,7,'cc"cc'}}
table.save("aaa.out", tbl)
zbl = table.load("aaa.out")
print(table.tostring(zbl))

