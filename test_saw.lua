Settings = { 
    Name = "FEK_SawLine1" 
} 

function Init() 
    Period = 10
    Lines = {}

    return 1 
end 

function OnCalculate(index) 
--[[     if (index == 1) then
        Lines[1] = 1
        Add = -1
    elseif (index == 10) then
        Lines[10] = Add * Lines[1]
    else
        if (math.fmod(index, Period) == 0) then
            Lines[index] = Lines[index-Period] * Add
        end
    end
    

    if (index > 7780) then
        local i
        for i = 7750, 7760 do
            Lines[i] = nil    
        end
        -- local t = T(index)
        -- PrintDbgStr("QUIK" .. "|" .. t.month .. "|" .. t.day .. "|" .. t.hour .. "|" .. t.min .. "|" .. index .. "|" .. math.fmod(index, Period)  .. "|" .. Add .. "|" .. tostring(Lines[index]))
    end

    return Lines[index] ]]

    local ret_value = 0
	if (index == 1) then
        PrintDbgStr("Part1:" .. "|" .. index)

		ret_value = 1
	else
        PrintDbgStr("Part2:" ..  "|" .. tostring(index) .. "|" .. tostring(GetValue(index-1, 1))  .. "|" ..  tostring(GetValue(index-1, 1)) + 2)

		ret_value = GetValue(index-1, 1) + 2
	end

	if (index % 10 == 0) then
        PrintDbgStr("Part3:" .. "|" .. tostring(index) .. "|" .. tostring(SetValue(index-1, 1, 2)) .. "|" .. tostring(index-1) .. ":" .. tostring(GetValue(index-1, 1)))
	end  

	return ret_value
end