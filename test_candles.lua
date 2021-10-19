Settings= 
{ 
    Name = "FEK_test_candles" 
} 

function Init() 
    return 1 
end 

function OnCalculate(index) 
    if (index > 7580) then
        local t = T(index)
        PrintDebugMessage("test_candle:", index, t.month, t.day, t.hour, t.min, t.sec)
        PrintDebugMessage("   ", O(index), H(index), L(index), C(index))
    end
    return nil 
end 

function PrintDebugMessage(...)
    local smessage = GetMessage(...)

    if (smessage ~= nil) then
        --message(smessage)
        PrintDbgStr("QUIK|" .. smessage)

        -- return number of messages
        local args = { n = select("#",...), ... }
        return args.n
    else
        -- nothing todo
        return 0
    end
end

function GetMessage(...)
    local args = { n = select("#",...), ... }
    
    if (args.n > 0) then
        local count
        local tmessage = {}

        -- concate messages with symbol
        for count = 1, args.n do
            table.insert(tmessage, type(args[count]) == "string" and args[count] or tostring(args[count]))
        end

        return (table.concat(tmessage, "|"))
    else
        -- nothing todo
        return nil
    end
end
