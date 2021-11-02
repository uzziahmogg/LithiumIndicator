Settings = { 
    Name = "FEK_SawLine" 
} 

function Init() 
    Period = 10
    Lines = {}

    return 1 
end 

function OnCalculate(index) 
    if (index == 1) then
        Lines[1] = 1
        Add = -1
    elseif (index == 10) then
        Lines[10] = Add * Lines[1]

    elseif ((index > 7750) and (index < 7770)) then
        Lines[index] = nil

    else
        if (math.fmod(index, Period) == 0) then
            if Lines[index-Period] == nil then 

                PrintDbgStr("QUIK" .. "|" .. (index-Period) .. "|" .. tostring(Lines[index-Period]) .. "|" .. (index-Period+1) .. "|" .. tostring(Lines[index-Period+1]) .. "|" .. (index-Period+2) .. "|" .. tostring(Lines[index-Period+2]))

                Lines[index-Period] = -3
                Lines[index-Period+1] = 4
 
                PrintDbgStr("QUIK" .. "|" .. (index-Period) .. "|" .. tostring(Lines[index-Period]) .. "|" .. (index-Period+1) .. "|" .. tostring(Lines[index-Period+1]) .. "|" .. (index-Period+2) .. "|" .. tostring(Lines[index-Period+2]))
            end
            Lines[index] = Lines[index-Period] * Add
        end
    end

    if (index >= 7750) then
        local t = T(index)
        PrintDbgStr("QUIK" .. "|" .. t.month .. "|" .. t.day .. "|" .. t.hour .. "|" .. t.min .. "|" .. index .. "|" .. math.fmod(index, Period)  .. "|" .. Add .. "|" .. tostring(Lines[index]))
    end

    return Lines[index]
end