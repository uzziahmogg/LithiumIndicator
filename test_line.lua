Settings= 
{ 
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
        Add = 1
    else
        if (math.fmod(index, 2) == 1) then
            Lines[index] = Lines[index-2] + Add
        end

        if (math.fmod(index, Period) == 0) then
            Add = Add * -1
        end
    end

    local t = T(index)
    PrintDbgStr("QUIK" .. "|" .. t.month .. "|" .. t.day .. "|" .. t.hour .. "|" .. t.min .. "|" .. index .. "|" .. math.fmod(index, Period)  .. "|" .. math.fmod(index, 2)  .. "|" .. Add .. "|" .. tostring(Lines[index]))

    return Lines[index]
end 


