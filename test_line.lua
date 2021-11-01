Settings = {
    Name = "FEK_CentreLine"
}

-----------------------------------------------------------------------------
-- function Init
-----------------------------------------------------------------------------
function Init()
    CentreLines = {Indexes = {}, Values - {}}

    -- chart labels ids and default params
    ChartLabels = { [RSIs.Name] = {}, [RSIs.Name] = {}, Params = { TRANSPARENCY = 0, TRANSPARENT_BACKGROUND = 1, FONT_FACE_NAME = "Arial", FONT_HEIGHT = 8 }}

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

    ChartParams = { [Prices.Name] = { Tag = GetChartTag(Prices.Name), Step = 5 }, -- FEK_LITHIUMPrice
    [RSIs.Name] = { Tag = GetChartTag(RSIs.Name), Step = 5}} -- FEK_LITHIUMRSI

    RSIs = { Name = "RSI", Fasts = {}, Slows = {}, Params = { Dev = 0, Slow = 14, Fast = 9 }}

    Prices = { Name = "Price", Opens = {}, Closes = {}, Highs = {}, Lows = {}, Deltas = {}}

    Signals = { Cross = { Name = "Cross", Count = 0, Candle = 0 }}
    Directions = { Up = "up", Down = "down" }

    PriceTypes = { Median = 1, Typical = 2, Weighted = 3, AvarageCloses = 4 }

    RSIFast = RSI("Fast")
    RSISlow = RSI("Slow")

    return 1
end

-----------------------------------------------------------------------------
-- function OnCalculate
-----------------------------------------------------------------------------
function OnCalculate(index)
    -- debug output
    if (index == 1) then
        local t = T(index)
        PrintDebugMessage(index, t.month, t.day, t.hour, t.min)
    end

    -- set initial values on first candle
    if (index == 1) then
        DataSource = getDataSourceInfo()
        SecInfo = getSecurityInfo(DataSource.class_code, DataSource.sec_code)

        SetInitialCounts()
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

    RSIs.Deltas[index] = (RSIs.Fasts[index] ~= nil) and (RSIs.Slows[index] ~= nil) and RoundScale(GetDelta(RSIs.Fasts[index], RSIs.Slows[index]), SecInfo.scale) or nil

    --todo recalc centre_line beetwen new last corner point
    -- check fast rsi cross slow rsi up
    if (SignalOscCross((index-1), Directions.Up, RSIs)) then
        SetSignal((index-1), Directions.Up, RSIs, Signals.Cross)

        -- set chart label
        ChartLabels[RSIs.Name][index-1] = SetChartLabel((index-1), Directions.Up, RSIs, Signals.Cross, ChartIcons.Romb)

        CentreLines.Indexes[#CentreLines+1] = index - 1
        CentreLine.Values[#CentreLines+1] = GetCentreLine((index-1), Directions.Up, PriceTypes.Median, Prices)
    end
    
    -- check fast rsi cross slow rsi down
    if (SignalOscCross((index-1), Directions.Down, RSIs)) then
        SetSignal((index-1), Directions.Down, RSIs, Signals.Cross)
        
        -- set chart label
        ChartLabels[RSIs.Name][index-1] = SetChartLabel((index-1), Directions.Down, RSIs, Signals.Cross, ChartIcons.Romb)
        
        CentreLines.Indexes[#CentreLines+1] = index - 1
        CentreLines.Values[#CentreLines+1] = GetCentreLine((index-1), Directions.Down, PriceTypes.Median, Prices)
    end

    -- calc last point indicator CentreLine
    local last_centre_line = GetLastCentreLine(index)

    Prices.Deltas[index] = (Prices.Closes[index] ~= nil) and (last_centre_line) and RoundScale(GetDelta(Prices.Closes[index], last_centre_line), SecInfo.scale) or nil

    return last_centre_line
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
-----------------------------------------------------------------------------
function EventCross(index, direction, value1, value2, dev)
    return (ConditionRelate(direction, value2[index-1], value1[index-1], dev) and ConditionRelate(direction, value1[index], value2[index], dev))
end

-----------------------------------------------------------------------------
-- function GetCentreLine
-----------------------------------------------------------------------------
function GetCentreLine(index, direction, price_type, prices)
    if (price_type == PriceTypes.AvarageCloses) then
        return (prices.Closes[index-1] + prices.Closes[index]) / 2
    end

    local result

    if (direction  == Directions.Up) then
        result = (prices.Lows[index-1] + prices.Highs[index]) / 2
    elseif (direction  == Directions.Down) then
        result = (prices.Lows[index] + prices.Highs[index-1]) / 2
    end

    if (price_type == PriceTypes.Median) then
        return result
    end

    result = (result * 2 + prices.Closes[index]) / 3

    if (price_type == PriceTypes.Typical) then
        return result
    end

    result = (result * 3 + prices.Opens[index-1]) / 4

    if (price_type == PriceTypes.Weighted) then
        return result
    end

    return -1
end

-----------------------------------------------------------------------------
-- function 
-----------------------------------------------------------------------------
function GetLastCentreLine(index)
    local cl_last = #CentreLines.Indexes

    local result = CentreLines.Values[cl_last] + (CentreLines.Values[cl_last] - CentreLines.Values[cl_last-1]) / (CentreLines.Indexes[cl_last] - CentreLines.Indexes[cl_last-1]) * (index - CentreLines.Indexes[cl_last])
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
function SetSignal(index, direction, indicator_name, signal_name)
    -- set signal up/down off
    Signals[Reverse(direction)][indicator_name][signal_name].Candle = 0

    -- set signal down/up on
    Signals[direction][indicator_name][signal_name].Count = Signals[direction][indicator_name][signal_name].Count + 1
    Signals[direction][indicator_name][signal_name].Candle = index
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
                table.insert(tmessage, type(args[count]) == "string" and args[count] or tostring(args[count]))
            end
        end

        return (table.concat(tmessage, "|"))
    else
        -- nothing todo
        return nil
    end
end

----------------------------------------------------------------------------
-- function PrintDebugMessage(message1, message2, ...) print messages as one string separated by symbol in message window and debug utility
----------------------------------------------------------------------------
function PrintDebugMessage(...)
    local smessage = GetMessage(...)

    if (smessage ~= nil) then
        -- print messages as one string
        -- message(smessage)
        PrintDbgStr("QUIK|" .. smessage)

        -- return number of messages
        local args = { n = select("#",...), ... }
        return args.n
    else
        -- nothing todo
        return 0
    end
end

----------------------------------------------------------------------------
-- function GetChartLabelText
----------------------------------------------------------------------------
function GetChartLabelText(direction, indicator_name, signal_name, text)

    local dir = (direction == Directions.Up) and "L" or "S"

    return GetMessage(dir .. indicator_name .. signal_name, Signals[direction][indicator_name][signal_name].Count, Signals[direction][indicator_name][signal_name].Candle, text)
end

----------------------------------------------------------------------------
-- function GetChartLabelYPos
--todo make cyclic variable for several levels of y position
----------------------------------------------------------------------------
function GetChartLabelYPos(index, direction, indicator_name)
    local position_y
    local sign = (direction == Directions.Up) and -1 or 1
    local price = (direction == Directions.Up) and "Lows" or "Highs"

    -- y pos for price chart
    if (indicator_name == Prices.Name) then
        position_y = Prices[price][index] + sign * ChartParams[Prices.Name].Step * SecInfo.min_price_step

    -- y pos for stoch chart
    elseif (indicator_name == Stochs.Name) then
        position_y = Stochs.Slows[index] * (100 + sign * ChartParams[Stochs.Name].Step) / 100

    -- y pos for rsi chart
    elseif (indicator_name == RSIs.Name) then
        position_y = RSIs.Slows[index] * (100 + sign * ChartParams[RSIs.Name].Step) / 100
    end

    return position_y
end

----------------------------------------------------------------------------
-- function GetChartIcon
----------------------------------------------------------------------------
function GetChartIcon(direction, icon)
    icon = icon or ChartIcons.Triangle

    return icon .. "_" .. direction .. ".jpg"
end

----------------------------------------------------------------------------
-- function SetChartLabel
----------------------------------------------------------------------------
function SetChartLabel(index, direction, indicator_name, signal_name, icon, text)
    -- delete label duplicates
    local chart_tag = GetChartTag(indicator_name)
    if (ChartLabels[indicator_name][index] ~= nil) then
        DelLabel(chart_tag, ChartLabels[indicator_name][index])
    end

    -- set label icon
    ChartLabels.Params.IMAGE_PATH = ChartLabels.Params.IconPath .. GetChartIcon(direction, icon)

    -- set label position
    local x  = T(index)
    ChartLabels.Params.DATE = tostring(10000 * x.year + 100 * x.month + x.day)
    ChartLabels.Params.TIME = tostring(10000 * x.hour + 100 * x.min + x.sec)

    ChartLabels.Params.YVALUE = GetChartLabelYPos(index, direction, indicator_name)

    -- set chart alingment from direction
    if (direction == Directions.Up) then
        ChartLabels.Params.ALIGNMENT = "BOTTOM"
    elseif (direction == Directions.Down) then
        ChartLabels.Params.ALIGNMENT = "TOP"
    end

    -- set text
    ChartLabels.Params.HINT = direction .. indicator_name .. signal_name
    ChartLabels.Params.TEXT = GetChartLabelText(direction, indicator_name, signal_name, text)

    -- set chart label return id
    local result = AddLabel(chart_tag, ChartLabels.Params)
    return result
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
--  --------------------------------------------------------------------------
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
--
-----------------------------------------------------------------------------
function SetInitialCounts()
    -- down signals
    Signals[Directions.Down][RSIs.Name]["Cross"].Count = 0
    Signals[Directions.Down][RSIs.Name]["Cross"].Candle = 0

    -- up signals
    Signals[Directions.Up][RSIs.Name]["Cross"].Count = 0
    Signals[Directions.Up][RSIs.Name]["Cross"].Candle = 0
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


