Settings = { 
    Name = "FEK_SawLine1" 
} 

function Init() 
    Period = 10
    Lines = {}

    return 1 
end 

function OnCalculate(index) 
    if (index > 9750) then
        local t = T(index)
        PrintDbgStr("QUIK"  .. "|" .. index .. "|" .. t.month .. "|" .. t.day .. "|" .. t.hour .. "|" .. t.min)
    end

    if (index == 9800) then
        local i
        for i = 1, 15 do
            SetValue(9780+i, 1, 3)
        end 
    end

    if (index == 1) then
        Lines[1] = 1
        Add = -1
    elseif (index == 10) then
        Lines[10] = Add * Lines[1]
    else
        if (math.fmod(index, Period) == 0) then
            Lines[index] = Lines[index-Period] * Add
        end
    end
    
    return Lines[index] 

    --[[local ret_value = 0
	if (index == 1) then
        -- PrintDbgStr("Part1:" .. "|" .. index)

		ret_value = 1
	else
        -- PrintDbgStr("Part2:" ..  "|" .. tostring(index) .. "|" .. tostring(GetValue(index-1, 1))  .. "|" ..  tostring(GetValue(index-1, 1)) + 2)

		ret_value = GetValue(index-1, 1) + 2
	end

	if (index % 10 == 0) then
        -- PrintDbgStr("Part3:" .. "|" .. tostring(index) .. "|" .. tostring(SetValue(index-1, 1, 2)) .. "|" .. tostring(index-1) .. ":" .. tostring(GetValue(index-1, 1)))
        SetValue(index-1, 1, 2)
	end  

	return ret_value ]]
end