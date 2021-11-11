--============================================================================
--todo remove all chart labels keep only last 30
--todo remove all prices and inds array, kepp only last three
--? why calculated centre line don't paint point at candle 1
--============================================================================
Settings = {
    Name = "FEK_CentreLine", 
    line ={{ Name = "Calculated", Type = TYPE_LINE, Color = RGB(255, 0, 0) }, { Name = "Approximated", Type = TYPE_DASH, Color = RGB(0, 255, 0) }}}

-----------------------------------------------------------------------------
-- function Init
-----------------------------------------------------------------------------
function Init()
    RSIs = { Name = "RSI", Fasts = {}, Slows = {}, Params = { Dev = 0, Slow = 14, Fast = 9 }}

    Prices = { Name = "Price", Opens = {}, Closes = {}, Highs = {}, Lows = {}, Deltas = {}}

    Directions = { Long = "L", Short = "S" }

    -- chart labels ids and default params
    ChartLabels = { [Prices.Name] = {}, [RSIs.Name] = {}, Params = { TRANSPARENCY = 0, TRANSPARENT_BACKGROUND = 1, FONT_FACE_NAME = "Arial", FONT_HEIGHT = 8 }}

    -- get script path
    ScriptPath = getScriptPath()

    -- get icons for current theme
    if (isDarkTheme()) then
        ChartLabels.Params.IconPath = ScriptPath .. "\\black_theme\\"
        ChartLabels.Params.R = 255
        ChartLabels.Params.G = 255
        ChartLabels.Params.B = 255
    else
        ChartLabels.Params.IconPath = ScriptPath .. "\\black_theme\\"
        ChartLabels.Params.R = 255
        ChartLabels.Params.G = 255
        ChartLabels.Params.B = 255
    end

    -- chart label icons
    ChartIcons = { Arrow = "arrow", Point = "point", Triangle = "triangle", Cross = "cross", Romb = "romb", Plus = "plus", Flash = "flash", Asterix = "asterix", BigArrow = "big_arrow", BigPoint = "big_point", BigTriangle = "big_triangle", BigCross = "big_cross", BigRomb = "big_romb", BigPlus = "big_plus" }

    ChartParams = { [Prices.Name] = { Tag = GetChartTag(Prices.Name), Step = 5 }, -- FEK_CentreLinePrice
    [RSIs.Name] = { Tag = GetChartTag(RSIs.Name), Step = 5}} -- FEK_CentreLineRSI

    -- Signals = { [Directions.Long] = { [Prices.Name] = { Cross = { Name = "Cross", Count = 0, Candle = 0 }}, [RSIs.Name] = { Cross = { Name = "Cross", Count = 0, Candle = 0 }}, Enter = { Cross = { Name = "Cross", Count = 0, Candle = 0 }}}, [Directions.Short] = { [Prices.Name] = { Cross = { Name = "Cross", Count = 0, Candle = 0 }}, [RSIs.Name] = { Cross = { Name = "Cross", Count = 0, Candle = 0 }}, Enter = { Cross = { Name = "Cross", Count = 0, Candle = 0 }}}}

    Signals = { [Directions.Long] = { [Prices.Name] = { Cross = { Name = "Cross", Count, Candle }}, [RSIs.Name] = { Cross = { Name = "Cross", Count, Candle }}, Enter = { Cross = { Name = "Cross", Count, Candle }}}, [Directions.Short] = { [Prices.Name] = { Cross = { Name = "Cross", Count, Candle }}, [RSIs.Name] = { Cross = { Name = "Cross", Count, Candle }}, Enter = { Cross = { Name = "Cross", Count, Candle }}}}

    PriceTypes = { Median = 1, Typical = 2, Weighted = 3, AvarageCloses = 4, Close = 5 }

    RSIFast = RSI("Fast")
    RSISlow = RSI("Slow")

    return #Settings.line
end

-----------------------------------------------------------------------------
-- function OnCalculate
-----------------------------------------------------------------------------
function OnCalculate(index)
    local calc_centre_line

    -- set initial values on first candle
    if (index == 1) then
        DataSource = getDataSourceInfo()
        SecInfo = getSecurityInfo(DataSource.class_code, DataSource.sec_code)

        CentreLines = { Indexes = {}, Values = {} }
        CentreLines.Indexes[1] = 1
        CentreLines.Values[1] = C(1)

        SetInitialCounts()
        calc_centre_line = CentreLines.Values[1]
    else
        calc_centre_line = nil
    end

    -- calculate current prices
    Prices.Opens[index] = O(index)
    Prices.Closes[index] = C(index)
    Prices.Highs[index] = H(index)
    Prices.Lows[index] = L(index)

    -- calculate current rsi
    RSIs.Fasts[index] = RSIFast(index)
    RSIs.Slows[index] = RSISlow(index)

    RSIs.Fasts[index] = RoundScale(RSIs.Fasts[index], SecInfo.scale)
    RSIs.Slows[index] = RoundScale(RSIs.Slows[index], SecInfo.scale)

    --RSIs.Deltas[index] = (RSIs.Fasts[index] ~= nil) and (RSIs.Slows[index] ~= nil) and RoundScale(GetDelta(RSIs.Fasts[index], RSIs.Slows[index]), SecInfo.scale) or nil

    -- check fast rsi cross slow rsi up
    if (SignalOscCross((index-1), Directions.Long, RSIs)) then

        SetSignal((index-1), Directions.Long, RSIs, Signals[Directions.Long][RSIs.Name].Cross)

        -- set chart label
        ChartLabels[RSIs.Name][index-1] = SetChartLabel((index-1), Directions.Long, RSIs, Signals[Directions.Long][RSIs.Name].Cross, ChartIcons.Romb)

        SetCalculatedCentreLine((index-1), Directions.Long, PriceTypes.Close)
    end
    
    -- check fast rsi cross slow rsi down
    if (SignalOscCross((index-1), Directions.Short, RSIs)) then

        SetSignal((index-1), Directions.Short, RSIs, Signals[Directions.Short][RSIs.Name].Cross)

        -- set chart label
        ChartLabels[RSIs.Name][index-1] = SetChartLabel((index-1), Directions.Short, RSIs, Signals[Directions.Short][RSIs.Name].Cross, ChartIcons.Romb)

        SetCalculatedCentreLine((index-1), Directions.Short, PriceTypes.Close)
    end

    -- calc last point indicator CentreLine
    local appr_centre_line = GetApproximatedCentreLine(index)

    --Prices.Deltas[index] = (Prices.Closes[index] ~= nil) and (last_centre_line) and RoundScale(GetDelta(Prices.Closes[index], last_centre_line), SecInfo.scale) or nil

    -- debuglog
--[[     if (index > 10500) then
        local t = T(index)
        PrintDebugMessage("OnCalc1", index, t.month .. "-" .. t.day .. "--" .. t.hour .. ":" .. t.min)
    end   ]]

    -- return RSIs.Slows[index], RSIs.Fasts[index]
    return calc_centre_line, appr_centre_line
end

-----------------------------------------------------------------------------
-- function SignalOscCross
-----------------------------------------------------------------------------
function SignalOscCross(index, direction, oscs, dev)
    if (CheckDataExist(index, 2, oscs.Slows) and CheckDataExist(index, 2, oscs.Fasts)) then

        dev = dev or 0

        -- true or false
        return EventCross(index, direction, oscs.Fasts, oscs.Slows, dev)
    else
        return false
    end
end

-----------------------------------------------------------------------------
-- function EventCross
--todo check condition flat for PriceCrossMA
-----------------------------------------------------------------------------
function EventCross(index, direction, value1, value2, dev)
    -- return (ConditionRelate(direction, value2[index-1], value1[index-1], dev) or ConditionFlat(value2[index-1], value1[index-1], dev)) and ConditionRelate(direction, value1[index], value2[index], dev)

    return ConditionRelate(direction, value2[index-1], value1[index-1], dev)  and ConditionRelate(direction, value1[index], value2[index], dev)
end

-----------------------------------------------------------------------------
-- function ConditionFlat
-----------------------------------------------------------------------------
function ConditionFlat(value1, value2, dev)
    return math.abs(GetDelta(value1, value2)) <= dev
end

-----------------------------------------------------------------------------
-- function Condition Is Value1 over or under Value2
-----------------------------------------------------------------------------
function ConditionRelate(direction, value1, value2, dev)
    if (direction == Directions.Long) then
        return (value1 > (value2 + dev))
    elseif (direction == Directions.Short) then
        return (value2 > (value1 + dev))
    end
end

-----------------------------------------------------------------------------
-- function SetCentreLine
-----------------------------------------------------------------------------
function SetCalculatedCentreLine(index, direction, price_type)
    function GetCentreLine()
        if (price_type == PriceTypes.Close) then
            return Prices.Closes[index]
        end

        if (price_type == PriceTypes.AvarageCloses) then
            return (Prices.Closes[index-1] + Prices.Closes[index]) / 2
        end

        local result

        if (direction  == Directions.Long) then
            result = (Prices.Lows[index-1] + Prices.Highs[index]) / 2
        elseif (direction  == Directions.Short) then
            result = (Prices.Lows[index] + Prices.Highs[index-1]) / 2
        end

        if (price_type == PriceTypes.Median) then
            return result
        end

        result = (result * 2 + Prices.Closes[index]) / 3

        if (price_type == PriceTypes.Typical) then
            return result
        end

        result = (result * 3 + Prices.Opens[index-1]) / 4

        if (price_type == PriceTypes.Weighted) then
            return result
        end

        return -1
    end

    if (index ~= CentreLines.Indexes[#CentreLines.Indexes]) then
        CentreLines.Indexes[#CentreLines.Indexes+1] = index
        CentreLines.Values[#CentreLines.Values+1] = GetCentreLine()

        SetValue(index, 1, CentreLines.Values[#CentreLines.Values])
        
        return CentreLines.Values[#CentreLines.Values]
    end

    return -1
end

-----------------------------------------------------------------------------
-- function GetApproximatedCentreLine
-----------------------------------------------------------------------------
function GetApproximatedCentreLine(index)
    local cl_size = #CentreLines.Indexes

    if (cl_size >= 2) then
        return CentreLines.Values[cl_size] + (CentreLines.Values[cl_size] - CentreLines.Values[cl_size-1]) / (CentreLines.Indexes[cl_size] - CentreLines.Indexes[cl_size-1]) * (index - CentreLines.Indexes[cl_size])
    end

    return nil
end

----------------------------------------------------------------------------
-- function Reverse return reverse of direction
----------------------------------------------------------------------------
function Reverse(direction)
    if (direction == Directions.Long) then
        return Directions.Short
    elseif (direction == Directions.Short) then
        return Directions.Long
    end
end

----------------------------------------------------------------------------
-- function GetChartTag     return chart tag from Robot name and Indicator name
----------------------------------------------------------------------------
function GetChartTag(indicator_name)
    return (Settings.Name .. indicator_name)
end

----------------------------------------------------------------------------
-- function SetSignal
----------------------------------------------------------------------------
function SetSignal(index, direction, indicator, signal)
    -- set signal up/down off
    Signals[Reverse(direction)][indicator.Name][signal.Name].Candle = 0

    -- set signal down/up on
    Signals[direction][indicator.Name][signal.Name].Count = Signals[direction][indicator.Name][signal.Name].Count + 1
    Signals[direction][indicator.Name][signal.Name].Candle = index
end

--------------------------------------------------------------------------
-- function CheckDataExist return true if number values from index back exist
----------------------------------------------------------------------------
function CheckDataExist(index, number, value)
    -- if index under required number return false
    if (index <= number) then
        return false
    end

    local count
    for count = 1, number, 1 do

        -- if one of number values not exist return false
        if (value[index-count] == nil) then
            return false
        end
    end

    return true
end

----------------------------------------------------------------------------
-- function GetMessage(...) return messages as one string separated by symbol
----------------------------------------------------------------------------
function GetMessage(...)
    local args = { n = select("#",...), ... }
    -- check number messages more then zero
    if (args.n > 0) then
        local count
        local tmessage = {}

        -- concate messages with symbol
        for count = 1, args.n do
            if (args[count] ~= nil) then
                table.insert(tmessage, ((type(args[count]) == "string") and args[count]) or tostring(args[count]))
            end
        end

        return table.concat(tmessage, "|"), args.n
    else
        -- nothing todo
        return nil
    end
end

----------------------------------------------------------------------------
-- function PrintDebugMessage(message1, message2, ...) print messages as one string separated by symbol in message window and debug utility
----------------------------------------------------------------------------
function PrintDebugMessage(...)
    local smessage, n = GetMessage(...)

    if (smessage ~= nil) then
        -- print messages as one string
        -- message(smessage)
        PrintDbgStr("QUIK|" .. smessage)

        -- return number of messages
        return n
    else
        -- nothing todo
        return 0
    end
end

-----------------------------------------------------------------------------
-- function GetChartLabelXPos
-----------------------------------------------------------------------------
function GetChartLabelXPos(t)
    return tostring(10000 * t.year + 100 * t.month + t.day), tostring(10000 * t.hour + 100 * t.min + t.sec)
end

----------------------------------------------------------------------------
-- function GetChartLabelYPos
----------------------------------------------------------------------------
function GetChartLabelYPos(index, direction, indicator_name)
    local y
    local sign = (direction == Directions.Long) and -1 or 1
    local price = (direction == Directions.Long) and "Lows" or "Highs"

    -- y pos for price chart
    if (indicator_name == Prices.Name) then
        y = Prices[price][index] + sign * ChartParams[Prices.Name].Step * SecInfo.min_price_step

    -- y pos for rsi chart
    elseif (indicator_name == RSIs.Name) then
        y = RSIs.Slows[index] * (100 + sign * ChartParams[RSIs.Name].Step) / 100
    end

    return y
end

----------------------------------------------------------------------------
-- function GetChartIcon
----------------------------------------------------------------------------
function GetChartIcon(direction, icon)
    icon = icon or ChartIcons.Triangle

    return ChartLabels.Params.IconPath .. icon .. "_" .. direction .. ".jpg"
end

----------------------------------------------------------------------------
-- function SetChartLabel
----------------------------------------------------------------------------
function SetChartLabel(index, direction, indicator, signal, icon, text)
    -- delete label duplicates
    local chart_tag = GetChartTag(indicator.Name)

    if (ChartLabels[indicator.Name][index] ~= nil) then
        DelLabel(chart_tag, ChartLabels[indicator.Name][index])
    end

    -- set label icon
    ChartLabels.Params.IMAGE_PATH = GetChartIcon(direction, icon)

    -- set label position
    ChartLabels.Params.DATE, ChartLabels.Params.TIME = GetChartLabelXPos(T(index))

    ChartLabels.Params.YVALUE = GetChartLabelYPos(index, direction, indicator.Name)

    -- set chart alingment from direction
    if (direction == Directions.Long) then
        ChartLabels.Params.ALIGNMENT = "BOTTOM"
    elseif (direction == Directions.Short) then
        ChartLabels.Params.ALIGNMENT = "TOP"
    end

    -- set text
    ChartLabels.Params.TEXT = GetMessage(direction, signal.Name, Signals[direction][indicator.Name][signal.Name].Count)

    ChartLabels.Params.HINT = GetMessage(ChartLabels.Params.TEXT, Signals[direction][indicator.Name][signal.Name].Candle, text)

    -- set chart label return id
    return AddLabel(chart_tag, ChartLabels.Params)
end

----------------------------------------------------------------------------
-- function Squeeze return number from 0 (if index start from 1) to period and then again from 0 (index == period) pointer in cycylic buffer
----------------------------------------------------------------------------
function CyclicPointer(index, period)
    return math.fmod(index - 1, period + 1)
end

----------------------------------------------------------------------------
-- function RoundScale return value with requred numbers after digital point
----------------------------------------------------------------------------
function RoundScale(value, scale)
    if ((value == nil) or (scale == nil)) then
        return nil
    end

    -- calc and return result
    local mult = 10^(scale or 0)

    if (value >= 0) then
        return (math.floor(value * mult + 0.5) / mult)
    else
        return (math.ceil(value * mult - 0.5) / mult)
    end
end

----------------------------------------------------------------------------
-- function RSI calculate indicator RSI for durrent candle
----------------------------------------------------------------------------
function RSI(mode)
    local Settings = { period = RSIs.Params[mode] }

    local Ma_up = MMA(Settings)
    local Ma_down = MMA(Settings)

    local Price_prev = 0
    local Price_cur = 0
    local Idx_chart = 0
    local Idx_buffer = 0

    return function (index)
        if (index == 1) then
            Idx_chart = 0
            Idx_buffer = 0
            Price_cur = 0
            Price_prev = 0
        end

        if CandleExist(index) then
            if (Idx_chart ~= index) then
                Idx_chart = index
                Idx_buffer = Idx_buffer + 1
                Price_prev = Price_cur
            end

            Price_cur = C(Idx_chart)

            local move_up = 0
            local move_down = 0

            if (Idx_buffer > 1) then
                if (Price_prev < Price_cur) then
                    move_up = Price_cur - Price_prev
                end

                if (Price_prev > Price_cur) then
                    move_down = Price_prev - Price_cur
                end
            end

            local value_up = Ma_up(Idx_buffer, { [Idx_buffer] = move_up })
            local value_down = Ma_down(Idx_buffer, { [Idx_buffer] = move_down })

            if (Idx_buffer >= Settings.period) then
                if (value_down == 0) then
                    return 100
                else
                    return 100 - (100 / (1 + (value_up / value_down)))
                end
            end
        end

        return nil
    end
end

----------------------------------------------------------------------------
--	function MMA = (MMAi-1 * (n - 1) + Pi) / n
----------------------------------------------------------------------------
function MMA(Settings)
    local Smas = {}
    local Mma_prev = 0
    local Mma_cur = 0
    local Idx_chart = 0
    local Idx_buffer = 0

    return function(index, prices)
        if (index == 1) then
            Smas = {}
            Mma_prev = 0
            Mma_cur = 0
            Idx_chart = 0
            Idx_buffer = 0
        end

        if CandleExist(index) then
            if (Idx_chart ~= index) then
                Idx_chart = index
                Idx_buffer = Idx_buffer + 1
                Mma_prev = Mma_cur
            end

            local idx_cur = CyclicPointer(Idx_buffer, Settings.period)
            local idx_prev = CyclicPointer(Idx_buffer - 1, Settings.period)
            local idx_oldest = CyclicPointer(Idx_buffer - Settings.period, Settings.period)

            if (Idx_buffer <= (Settings.period + 1)) then --?+1
                Smas[idx_cur] = (Smas[idx_prev] or 0) + prices[Idx_chart] / Settings.period

                if ((Idx_buffer == Settings.period) or (Idx_buffer == Settings.period + 1)) then --?+1
                    Mma_cur = Smas[idx_cur] - (Smas[idx_oldest] or 0)
                end
            else
                Mma_cur = (Mma_prev * (Settings.period - 1) + prices[Idx_chart]) / Settings.period
            end

            if (Idx_buffer >= Settings.period) then
                return Mma_cur
            end
        end

        return nil
    end
end

-----------------------------------------------------------------------------
-- SetInitialCounts
-----------------------------------------------------------------------------
function SetInitialCounts()
    -- down signals
    Signals[Directions.Short][Prices.Name]["Cross"].Count = 0
    Signals[Directions.Short][Prices.Name]["Cross"].Candle = 0
    Signals[Directions.Short][RSIs.Name]["Cross"].Count = 0
    Signals[Directions.Short][RSIs.Name]["Cross"].Candle = 0    
    Signals[Directions.Short]["Enter"]["Cross"].Count = 0
    Signals[Directions.Short]["Enter"]["Cross"].Candle = 0

    -- up signals
    Signals[Directions.Long][Prices.Name]["Cross"].Count = 0
    Signals[Directions.Long][Prices.Name]["Cross"].Candle = 0
    Signals[Directions.Long][RSIs.Name]["Cross"].Count = 0
    Signals[Directions.Long][RSIs.Name]["Cross"].Candle = 0
    Signals[Directions.Long]["Enter"]["Cross"].Count = 0
    Signals[Directions.Long]["Enter"]["Cross"].Candle = 0
end

-----------------------------------------------------------------------------
-- function GetDelta
-----------------------------------------------------------------------------
function GetDelta(value1, value2)
    if ((value1 == nil) or (value2 == nil)) then
        return nil
    end

    -- return math.abs(value1 - value2)
    return (value1 - value2)

end


--[[ End of File ]]--