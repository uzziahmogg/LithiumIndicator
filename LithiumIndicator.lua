--===========================================================================
--	Indicator Lithium, 2021 (c) FEK
--===========================================================================
--// convert RoundScale(..., SecInfo.scale) to RoundScale(..., values_after_point)
--// func AddLabel use Labels array
--// check price/osc events uturn3/4
--// make code for signal price/osc uturin3/4
--// make same func for text concate in PrintDebugMessage and GetChartLabelText
--// remove Params levels
--// merge IndArrays and ChartParams - chart is collection of indicators
--// recode all SignalCross to more soft strenth condition - first leg may be equal second leg only different so moveing statrted
--// recode SignalSteamer to osc slow move on index osc flat move on index and can be flat or contr moveing on index-1
--// remove rsicross50
--// move TrendOff to Stoch
--// recode priceuturn3
--// check DataExist for functions

--todo create func CheckElementarySignal
--todo make code for CheckComplexSignals
--todo remake all error handling to exceptions in functional programming
--todo remove all chart labels keep only last 30
--todo remove all prices and inds array, kepp only last three
--todo recode SetInitValues and PrintDebugSummary to cycles over all pairs
--todo make shift uturn slow and fast lines

--? move long/short checking signals to diferent branch
--? make candle+count itterator in separate States structure
--? make 3-candle cross event fucntion
--? move error checking data checking args checking from signal functions to lowest event functions

--* if function make something - return number maked things, or 0 if nothing todo, or nil if error
--* if function return something - if success return string or number or boolean or if error/todo nothing return nil
--* rememebr about strength critery in prciecross/osccross signals - now there have most strength criter where different sides of cross have different not equal values

--* events -> signals -> states -> enters
--* events/conditions is elementary signals like fast oscilator cross up slow oscilator, price cross up ma  and all there are in period 2-3 candles
--* several events and conditions consist signal like uturn, spring, cross, cross50 etc
--* functions responsible for cantching signals counting requested events and conditions
--* several signals consist states like trend, impulse etc
--* several states and signals consist enters like Leg1ZigZagSpring, Uturn50 etc
--* signals is clear signals , all strengh conditions must be in states/enters
--===========================================================================
-----------------------------------------------------------------------------
--#region Settings
-----------------------------------------------------------------------------
Settings = { Name = "FEK_LITHIUM", line = {{ Name = "Top", Type = TYPE_LINE, Color = RGB(221, 44, 44) }, { Name = "Centre", Type = TYPE_LINE,	Color = RGB(0, 206, 0) },  { Name = "Bottom", Type = TYPE_LINE, Color = RGB(0, 162, 232) }}}
--#endregion

-----------------------------------------------------------------------------
--#region Init
-----------------------------------------------------------------------------
function Init()

    -- permissions to show labels on charts
    ChartPermissions = { Event = 1, Signal = 2, State = 4, Enter = 8 }

    -- chart params and indicators it consist
    -- price data arrays and params
    Prices = { Name = "Price", Opens = {}, Closes = {}, Highs = {}, Lows = {}, Dev = 0, Step = 5, Permission = ChartPermissions.Signal } -- FEK_LITHIUMPrice
    -- stochastic data arrays and params
    Stochs = { Name = "Stoch", Fasts = {}, Slows = {}, Deltas = {}, HLines = { TopExtreme = 80, Centre = 50, BottomExtreme = 20 }, Slow = { PeriodK = 10, Shift = 3, PeriodD = 1 }, Fast = { PeriodK = 5, Shift = 2, PeriodD = 1 }, Dev = 0, Step = 20, Permission = ChartPermissions.Event } -- FEK_LITHIUMStoch
    -- RSI data arrays and params
    RSIs = { Name = "RSI", Fasts = {}, Slows = {}, Deltas = {}, HLines = { TopExtreme = 80, TopTrend = 60, Centre = 50, BottomTrend = 40, BottomExtreme = 20 }, Slow = 14, Fast = 9, Dev = 0, Step = 5, Permission = ChartPermissions.Signal } -- FEK_LITHIUMRSI
    -- price channel data arrays and params
    PCs = { Name = "PC", Tops = {}, Bottoms = {}, Centres = {}, Deltas = {}, Period = 20 }

    -- directions for signals labels and deals
    Directions = { Long = "L", Short = "S" }

    -- chart labels arrays and default params
    ChartLabels = { [Prices.Name] = {}, [Stochs.Name] = {}, [RSIs.Name] = {},
        Params = { TRANSPARENCY = 0, TRANSPARENT_BACKGROUND = 1, FONT_FACE_NAME = "Arial", FONT_HEIGHT = 8 }}

    -- script path
    ScriptPath = getScriptPath()

    -- icons for current theme
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
    ChartIcons = { Arrow = "arrow", Point = "point", Triangle = "triangle", Cross = "cross", Romb = "romb", Plus = "plus", Flash = "flash", Asterix = "asterix", BigArrow = "big_arrow", BigPoint = "big_point", BigTriangle = "big_triangle", BigCross = "big_cross", BigRomb = "big_romb", BigPlus = "big_plus", Minus = "minus" }

    -- stages of deals for chart labels text only
    DealStages = { Start = "Start", Continue = "Continue", End = "End" }

    -- indicator functions
    StochSlow = Stoch("Slow")
    StochFast = Stoch("Fast")
    RSISlow = RSI("Slow")
    RSIFast = RSI("Fast")
    PC = PriceChannel()

    -- signals names, counts, start cansles
    Signals = { CrossMA = { Name = "CrossMA", [Directions.Long] = { [Prices.Name] = { Count = 0, Candle = 0 }}, [Directions.Short] = { [Prices.Name] = { Count = 0, Candle = 0 }}},
    Cross = { Name = "Cross", [Directions.Long] = { [Stochs.Name] = { Count = 0, Candle = 0 }, [RSIs.Name] = { Count = 0, Candle = 0 }}, [Directions.Short] = { [Stochs.Name] = { Count = 0, Candle = 0 }, [RSIs.Name] = { Count = 0, Candle = 0 }}},
    Cross50 = { Name = "Cross50", [Directions.Long] = { [Stochs.Name] = { Count = 0, Candle = 0 }},[Directions.Short] = { [Stochs.Name] = { Count = 0, Candle = 0 }}},
    Steamer = { Name = "Steamer", [Directions.Long] = { [Stochs.Name] = { Count = 0, Candle = 0 }}, [Directions.Short] = { [Stochs.Name] = { Count = 0, Candle = 0 }}},
    TrendOff = { Name = "TrendOff", [Directions.Long] = { [Stochs.Name] = { Count = 0, Candle = 0 }}, [Directions.Short] = { [Stochs.Name] = { Count = 0, Candle = 0 }}},
    Uturn3 = { Name = "Uturn3", [Directions.Long] = { [Prices.Name] = { Count = 0, Candle = 0 }, [Stochs.Name] = { Count = 0, Candle = 0 }, [RSIs.Name] = { Count = 0, Candle = 0 }}, [Directions.Short] = { [Prices.Name] = { Count = 0, Candle = 0 }, [Stochs.Name] = { Count = 0, Candle = 0 }, [RSIs.Name] = { Count = 0, Candle = 0 }}}, 
    Enter = { Name = "Enter", Count = 0, Candle = 0}, 
    MaxDuration = 2, MaxDifference = 30, MinDeviation = 0 }

    return #Settings.line
end
--#endregion

-----------------------------------------------------------------------------
-- function OnCalculate
-----------------------------------------------------------------------------
function OnCalculate(index)
    -- set initial values on first candle
    if (index == 1) then
        DataSource = getDataSourceInfo()
        SecInfo = getSecurityInfo(DataSource.class_code, DataSource.sec_code)

        SetInitialValues(Signals)
    end

    --#region set prices and indicators for current candle
    -- calculate current prices
    Prices.Opens[index] = O(index)
    Prices.Closes[index] = C(index)
    Prices.Highs[index] = H(index)
    Prices.Lows[index] = L(index)

    -- calculate current stoch
    Stochs.Slows[index], _ = StochSlow(index)
    Stochs.Fasts[index], _ = StochFast(index)
    Stochs.Slows[index] = RoundScale(Stochs.Slows[index], SecInfo.scale)
    Stochs.Fasts[index] = RoundScale(Stochs.Fasts[index], SecInfo.scale)
    Stochs.Deltas[index] = (Stochs.Slows[index] ~= nil) and (Stochs.Fasts[index] ~= nil) and RoundScale(GetDelta(Stochs.Fasts[index], Stochs.Slows[index]), SecInfo.scale) or nil

    -- calculate current rsi
    RSIs.Fasts[index] = RSIFast(index)
    RSIs.Slows[index] = RSISlow(index)
    RSIs.Fasts[index] = RoundScale(RSIs.Fasts[index], SecInfo.scale)
    RSIs.Slows[index] = RoundScale(RSIs.Slows[index], SecInfo.scale)
    RSIs.Deltas[index] = (RSIs.Fasts[index] ~= nil) and (RSIs.Slows[index] ~= nil) and RoundScale(GetDelta(RSIs.Fasts[index], RSIs.Slows[index]), SecInfo.scale) or nil

    -- calculate current price channel
    PCs.Tops[index], PCs.Bottoms[index] = PC(index)
    PCs.Tops[index] = RoundScale(PCs.Tops[index], SecInfo.scale)
    PCs.Bottoms[index] = RoundScale(PCs.Bottoms[index], SecInfo.scale)
    PCs.Centres[index] = (PCs.Tops[index] ~= nil) and (PCs.Bottoms[index] ~= nil) and RoundScale((PCs.Bottoms[index] + (PCs.Tops[index] - PCs.Bottoms[index]) / 2), SecInfo.scale) or nil
    PCs.Deltas[index] = (Prices.Closes[index] ~= nil) and (PCs.Centres[index] ~= nil) and RoundScale(GetDelta(Prices.Closes[index], PCs.Centres[index]), SecInfo.scale) or nil
    --#endregion

    --=======================================================================
    -- I. Price Signals
    --=======================================================================
    -------------------------------------------------------------------------
    --#region I.1. Signals.CrossMA[Down/Up].Price
    -------------------------------------------------------------------------

    -- check start signal price cross ma up
    if (SignalPriceCrossMA((index-1), Directions.Long, Prices.Closes, PCs.Centres)) then

        -- set signal
        SetSignal((index-1), Directions.Long, Prices, Signals.CrossMA)

        -- set chart label
        ChartLabels[Prices.Name][index-1] = SetChartLabel((index-1), Directions.Long, Prices, Signals.CrossMA, ChartIcons.Arrow, ChartPermissions.Event)
    end -- long

    -- check start signal price cross ma down
    if (SignalPriceCrossMA(index-1, Directions.Short, Prices.Closes, PCs.Centres)) then

        -- set signal
        SetSignal((index-1), Directions.Short, Prices, Signals.CrossMA)

        -- set chart label
        ChartLabels[Prices.Name][index-1] = SetChartLabel((index-1), Directions.Short, Prices, Signals.CrossMA, ChartIcons.Arrow, ChartPermissions.Event)
    end -- short
    --#endregion

    -------------------------------------------------------------------------
    --#region I.2. Signals.Uturn3[Down/Up].Price
    -------------------------------------------------------------------------

    -- check start signal uturn3 up
    if (SignalPriceUturn3(index, Directions.Long, Prices, PCs)) then

        -- set signal on
        SetSignal((index-1), Directions.Long, Prices, Signals.Uturn3)

        -- set chart label
        ChartLabels[Prices.Name][index-1] = SetChartLabel((index-1), Directions.Long, Prices, Signals.Uturn3, ChartIcons.Arrow, ChartPermissions.Event)
    end -- long

    -- check start signal price cross ma down
    if (SignalPriceUturn3(index, Directions.Short, Prices, PCs)) then

        -- set signal on
        SetSignal((index-1), Directions.Short, Prices, Signals.Uturn3)

        -- set chart label
        ChartLabels[Prices.Name][index-1] = SetChartLabel((index-1), Directions.Short, Prices, Signals.Uturn3, ChartIcons.Arrow, ChartPermissions.Event)
    end -- short
    --#endregion

    --=======================================================================
    -- II. Stoch Signals
    --=======================================================================
    -------------------------------------------------------------------------
    --#region II.1. Signals.Cross[Down/Up].Stochs
    -------------------------------------------------------------------------

    -- check fast stoch cross slow stoch up
    if (SignalOscCross((index-1), Directions.Long, Stochs)) then

        -- set signal
        SetSignal((index-1), Directions.Long, Stochs, Signals.Cross)

        -- set chart label
        ChartLabels[Stochs.Name][index-1] = SetChartLabel((index-1), Directions.Long, Stochs, Signals.Cross, ChartIcons.Romb, ChartPermissions.Signal)
    end -- long

    -- check fast stoch cross slow stoch down
    if (SignalOscCross((index-1), Directions.Short, Stochs)) then

        -- set signal
        SetSignal((index-1), Directions.Short, Stochs, Signals.Cross)

        -- set chart label
        ChartLabels[Stochs.Name][index-1] = SetChartLabel((index-1), Directions.Short, Stochs, Signals.Cross, ChartIcons.Romb, ChartPermissions.Signal)
    end -- short
    --#endregion

    -------------------------------------------------------------------------
    --#region II.2. Signals.Cross50[Down/Up].Stochs
    -------------------------------------------------------------------------

    -- check slow stoch cross lvl50 up
    if (SignalOscCrossLevel((index-1), Directions.Long, Stochs.Slows, Stochs.HLines.Centre)) then

        -- set signal
        SetSignal((index-1), Directions.Long, Stochs, Signals.Cross50)

        -- set chart label
        ChartLabels[Stochs.Name][index-1] = SetChartLabel((index-1), Directions.Long, Stochs, Signals.Cross50, ChartIcons.Arrow, ChartPermissions.Signal)
    end -- long

    -- check slow stoch cross lvl50 down
    if (SignalOscCrossLevel((index-1), Directions.Short, Stochs.Slows, Stochs.HLines.Centre)) then

        -- set signal
        SetSignal((index-1), Directions.Short, Stochs, Signals.Cross50)

        -- set chart label
        ChartLabels[Stochs.Name][index-1] = SetChartLabel((index-1), Directions.Short, Stochs, Signals.Cross50, ChartIcons.Arrow, ChartPermissions.Signal)
    end -- short
    --#endregion

    -------------------------------------------------------------------------
    --#region II.3. Signals.Steamer[Down/Up].Stochs
    -------------------------------------------------------------------------

    -- check stoch steamer up
    if (SignalOscSteamer((index-1), Directions.Long, Stochs)) then

        -- set signal on
        SetSignal((index-1), Directions.Long, Stochs, Signals.Steamer)

        -- set chart label
        ChartLabels[Stochs.Name][index-1] = SetChartLabel((index-1), Directions.Long, Stochs, Signals.Steamer, ChartIcons.Plus, ChartPermissions.Signal)
    end -- long

    -- check stoch steamer down
    if (SignalOscSteamer((index-1), Directions.Short, Stochs)) then

        -- set signal on
        SetSignal((index-1), Directions.Short, Stochs, Signals.Steamer)

        -- set chart label
        ChartLabels[Stochs.Name][index-1] = SetChartLabel((index-1), Directions.Short, Stochs, Signals.Steamer, ChartIcons.Plus, ChartPermissions.Signal)
    end -- short
    --#endregion
        
    -- debuglog
    --[[ if (index > 11600) and (index < 11700) then
        local t = T(index)
        PrintDebugMessage(index, t.month, t.day, t.hour, t.min)

        PrintDebugMessage("-s", Stochs.Slows[index-2], Stochs.Slows[index-1], Stochs.Slows[index])
        PrintDebugMessage("-f", Stochs.Fasts[index-2], Stochs.Fasts[index-1], Stochs.Fasts[index])
        PrintDebugMessage("-d", math.abs(GetDelta(Stochs.Slows[index-2], Stochs.Fasts[index-2])), math.abs(GetDelta(Stochs.Slows[index-1], Stochs.Fasts[index-1])), math.abs(GetDelta(Stochs.Slows[index], Stochs.Fasts[index])))
    end  ]]

    -------------------------------------------------------------------------
    --#region II.4. Signals.Uturn3[Down/Up].Stochs
    -------------------------------------------------------------------------

    -- check slow stoch uturn 3 candles up
    if (SignalOscUturn3((index-1), Directions.Long, Stochs)) then

        -- set signal on
        SetSignal((index-1), Directions.Long, Stochs, Signals.Uturn3)

        -- set chart label
        ChartLabels[Stochs.Name][index-1] = SetChartLabel((index-1), Directions.Long, Stochs, Signals.Uturn3, ChartIcons.Triangle, ChartPermissions.Event)
    end -- long

    -- check slow stoch uturn 3 candles down
    if (SignalOscUturn3((index-1), Directions.Short, Stochs)) then

        -- set signal on
        SetSignal((index-1), Directions.Short, Stochs, Signals.Uturn3)

        -- set chart label
        ChartLabels[Stochs.Name][index-1] = SetChartLabel((index-1), Directions.Short, Stochs, Signals.Uturn3, ChartIcons.Triangle, ChartPermissions.Event)
    end -- short
    --#endregion

    -------------------------------------------------------------------------
    --#region III.5. Signals.TrendOff[Down/Up].Stochs
    -------------------------------------------------------------------------

    -- check start signal up trendon - slow rsi enter on uptrend zone
    if SignalOscTrendOff((index-1), Directions.Short, Stochs) then

        -- set signal on
        SetSignal((index-1), Directions.Short, Stochs, Signals.TrendOff)

        -- set chart label
        ChartLabels[Stochs.Name][index-1] = SetChartLabel((index-1), Directions.Short, Stochs, Signals.TrendOff, ChartIcons.Point, ChartPermissions.Signal)
    end -- long

    -- check start signal down trendon - slow rsi enter on down trend zone
    if SignalOscTrendOff((index-1), Directions.Long, Stochs) then

        SetSignal((index-1), Directions.Long, Stochs, Signals.TrendOff)

        -- set chart label
        ChartLabels[Stochs.Name][index-1] = SetChartLabel((index-1), Directions.Long, Stochs, Signals.TrendOff, ChartIcons.Point, ChartPermissions.Signal)
    end -- short
    --#endregion

    --=======================================================================
    -- III. RSI Signals
    --=======================================================================
    -------------------------------------------------------------------------
    --#region III.1. Signals.Cross[Down/Up].RSIs
    -------------------------------------------------------------------------

    -- check fast rsi cross slow rsi up
    if (SignalOscCross((index-1), Directions.Long, RSIs)) then

        --set signal on
        SetSignal((index-1), Directions.Long, RSIs, Signals.Cross)

        -- set chart label
        ChartLabels[RSIs.Name][index-1] = SetChartLabel((index-1), Directions.Long, RSIs, Signals.Cross, ChartIcons.Romb, ChartPermissions.Event)
    end -- long

    -- check fast rsi cross slow rsi down
    if (SignalOscCross((index-1), Directions.Short, RSIs)) then

        -- set signals on
        SetSignal((index-1), Directions.Short, RSIs, Signals.Cross)

        -- set chart label
        ChartLabels[RSIs.Name][index-1] = SetChartLabel((index-1), Directions.Short, RSIs, Signals.Cross, ChartIcons.Romb, ChartPermissions.Event)
    end -- short
    --#endregion

    -------------------------------------------------------------------------
    --#region III.2. Signals.Uturn3[Down/Up].RSIs
    -------------------------------------------------------------------------

        -- check slow RSI uturn 3 candles up
        if (SignalOscUturn3((index-1), Directions.Long, RSIs)) then

            -- set signal on
            SetSignal((index-1), Directions.Long, RSIs, Signals.Uturn3)
    
            -- set chart label
            ChartLabels[RSIs.Name][index-1] = SetChartLabel((index-1), Directions.Long, RSIs, Signals.Uturn3, ChartIcons.Triangle, ChartPermissions.Event)
        end -- long
    
        -- check slow RSI uturn 3 candles down
        if (SignalOscUturn3((index-1), Directions.Short, RSIs)) then
    
            -- set signal on
            SetSignal((index-1), Directions.Short, RSIs, Signals.Uturn3)
    
            -- set chart label
            ChartLabels[RSIs.Name][index-1] = SetChartLabel((index-1), Directions.Short, RSIs, Signals.Uturn3, ChartIcons.Triangle, ChartPermissions.Event)
        end -- short
    --#endregion

    --=======================================================================
    -- IV. Enters
    --=======================================================================

    -------------------------------------------------------------------------
    --#region IV.1. States.Enter[Down/Up]
    -------------------------------------------------------------------------

    -- check signals long
    if ((Signals[Signals.Enter.Name][Directions.Long].Candle == 0) and --?
    (Signals[Signals.CrossMA.Name][Directions.Long][Prices.Name].Candle > 0) and (Signals[Signals.Cross50.Name][Directions.Long][Stochs.Name].Candle > 0) and (Signals[Signals.Cross.Name][Directions.Long][Stochs.Name].Candle > 0) and (Signals[Signals.Cross.Name][Directions.Long][RSIs.Name].Candle > 0) and (Signals[Signals.Steamer.Name][Directions.Long][RSIs.Name].Candle > 0)) then

        -- set enter long signal on
        SetState((index-1), Directions.Long, Signals.Enter)

        -- set chart label
        ChartLabels[Prices.Name][index-1] = SetChartLabel((index-1), Directions.Long, Prices, Signals.Enter, ChartIcons.BigArrow, ChartPermissions.Enter, DealStages.Start)
    end -- long

    -- check signals short
    if ((Signals[Signals.Enter.Name][Directions.Short].Candle == 0) and --? 
    (Signals[Signals.CrossMA.Name][Directions.Short][Prices.Name].Candle > 0) and (Signals[Signals.Cross50.Name][Directions.Short][Stochs.Name].Candle > 0) and (Signals[Signals.Cross.Name][Directions.Short][Stochs.Name].Candle > 0) and (Signals[Signals.Cross.Name][Directions.Short][RSIs.Name].Candle > 0)and (Signals[Signals.Steamer.Name][Directions.Short][RSIs.Name].Candle > 0)) then

        -- set enter short signal on
        SetState((index-1), Directions.Short, Signals.Enter)

        -- set chart label
        ChartLabels[Prices.Name][index-1] = SetChartLabel((index-1), Directions.Short, Prices, Signals.Enter, ChartIcons.BigArrow, ChartPermissions.Enter, DealStages.Start)
    end -- short

    -- check enter long 
    if (Signals[Signals.Enter.Name][Directions.Long][Prices.Name].Candle > 0) then

        -- set enter duration
        local duration = index - Signals[Signals.Enter.Name][Directions.Long][Prices.Name].Candle

        -- check continuation enter long
        if (duration <= Signals.Duration) then

            -- enter long terminates by end one of long signals
            if ((Signals[Signals.CrossMA.Name][Directions.Long][Prices.Name].Candle == 0) or (Signals[Signals.Cross50.Name][Directions.Long][Stochs.Name].Candle == 0) or (Signals[Signals.Cross.Name][Directions.Long][Stochs.Name].Candle == 0) and (Signals[Signals.Cross.Name][Directions.Long][RSIs.Name].Candle == 0)) then

                -- set chart label
                ChartLabels[Prices.Name][index-1] = SetChartLabel((index-1), Directions.Long, Prices, Signals.Enter, ChartIcons.BigCross, ChartPermissions.Enter, tostring(index-1) .. "|" .. tostring(duration) .. "|" .. DealStages.End .. " by offsignal")

                -- set enter long off
                Signals[Signals.Enter.Name][Directions.Long][Prices.Name].Candle = 0

            -- process continuation enter long
            else
                -- set chart label
                ChartLabels[Prices.Name][index] = SetChartLabel(index, Directions.Long, Prices, Signals.Enter, ChartIcons.Minus, ChartPermissions.Enter, GetMessage(DealStages.Continue, duration))
            end

        -- enter long terminates by end of duration
        elseif (duration > Signals.Duration) then
            -- set chart label
            ChartLabels[Prices.Name][index-1] = SetChartLabel((index-1), Directions.Long, Prices.Name, Signals.Enter, ChartIcons.BigCross, ChartPermissions.Enter, tostring(index-1) .. "|" .. tostring(duration) .. "|" .. DealStages.End .. " by duration")

            -- set enter short signal off
            Signals[Signals.Enter.Name][Directions.Long][Prices.Name].Candle = 0
        end
    end -- long

    -- check enter short
    if (Signals[Signals.Enter.Name][Directions.Short][Prices.Name].Candle > 0) then

        -- set duration
        local duration = index - Signals[Signals.Enter.Name][Directions.Short][Prices.Name].Candle

        -- check continuation enter long
        if (duration <= Signals.Duration) then

            -- enter long terminates by end one of long signals
            if ((Signals[Signals.CrossMA.Name][Directions.Short][Prices.Name].Candle == 0) or (Signals[Signals.Cross50.Name][Directions.Short][Stochs.Name].Candle == 0) or (Signals[Signals.Cross.Name][Directions.Short][Stochs.Name].Candle == 0) and (Signals[Signals.Cross.Name][Directions.Short][RSIs.Name].Candle == 0)) then

                -- set chart label
                ChartLabels[Prices.Name][index-1] = SetChartLabel((index-1), Directions.Short, Prices, Signals.Enter, ChartIcons.BigCross, ChartPermissions.Enter, tostring(index-1) .. "|" .. tostring(duration) .. "|" .. DealStages.End .. " by offsignal")

                -- set enter long off
                Signals[Signals.Enter.Name][Directions.Short][Prices.Name].Candle = 0

            -- process continuation enter long
            else
                -- set chart label
                ChartLabels[Prices.Name][index] = SetChartLabel(index, Directions.Short, Prices, Signals.Enter, ChartIcons.Minus, ChartPermissions.Enter, GetMessage(DealStages.Continue, duration))
            end

        -- enter long terminates by end of duration
        elseif (duration > Signals.Duration) then
            -- set chart label
            ChartLabels[Prices.Name][index-1] = SetChartLabel((index-1), Directions.Short, Prices.Name, Signals.Enter, ChartIcons.BigCross, ChartPermissions.Enter, tostring(index-1) .. "|" .. tostring(duration) .. "|" .. DealStages.End .. " by duration")

            -- set enter short signal off
            Signals[Signals.Enter.Name][Directions.Short][Prices.Name].Candle = 0
        end -- short
    end 
    --#endregion

--[[     if (index == 20000) then
        PrintDebugSummary(Signals)
    end ]]

    -- return PCs.Tops[index], PCs.Centres[index], PCs.Bottoms[index]
    return Stochs.Slows[index], Stochs.Fasts[index]
    -- return RSIs.Slows[index], RSIs.Fasts[index]
end

--==========================================================================
--#region INDICATOR Price Channel
--==========================================================================
----------------------------------------------------------------------------
-- Price Channel
----------------------------------------------------------------------------
function PriceChannel()
    local Highs = {}
    local Lows = {}
    local Idx_chart = 0
    local Idx_buffer = 0

    return function (index)
        if (PCs.Period > 0) then
            -- first candle - reinit for start
            if (index == 1) then
                Highs = {}
                Lows = {}
                Idx_chart = 0
                Idx_buffer = 0
            end

            if CandleExist(index) then
                -- new candle new processed candle and increased count processed candles
                if (Idx_chart ~= index) then
                    Idx_chart = index
                    Idx_buffer = Idx_buffer + 1
                end

                -- insert high and low to circle buffers Highs and Lows
                Highs[CyclicPointer(Idx_buffer, PCs.Period - 1) + 1] = H(Idx_chart)
                Lows[CyclicPointer(Idx_buffer, PCs.Period - 1) + 1] = L(Idx_chart)

                -- calc and return max results
                if (Idx_buffer >= PCs.Period) then
                    local max_high = math.max(table.unpack(Highs))
                    local max_low = math.min(table.unpack(Lows))

                    return max_high, max_low
                end
            end
        end
        return nil, nil
    end
end
--#endregion

--==========================================================================
--#region INDICATOR STOCH
--==========================================================================
----------------------------------------------------------------------------
-- function Stochastic Oscillator ("SO")
----------------------------------------------------------------------------
function Stoch(mode)
    local Settings = { period_k = Stochs[mode].PeriodK, shift = Stochs[mode].Shift, period_d = Stochs[mode].PeriodD }

    local K_ma1 = SMA(Settings)
    local K_ma2 = SMA(Settings)
    local D_ma  = EMA(Settings)

    -- cyclic buffer to highs
    local Highs = {}
    -- cyclic buffer to lows
    local Lows = {}
    -- idx_chart point to index of real candles on chart/ds, idx_buffer point to candles in cyclic buffer count number processed candles
    local Idx_chart = 0
    local Idx_buffer = 0

    return function (index)
        if (Settings.period_k > 0) and (Settings.period_d > 0) then

            -- reinit arrays
            if (index == 1) then
                Highs = {}
                Lows = {}
                Idx_chart = 0
                Idx_buffer = 0
            end

            if CandleExist(index) then
                if (Idx_chart ~= index) then
                    Idx_chart = index
                    Idx_buffer = Idx_buffer + 1
                end

                -- pointer into cyclic buffer from 1 to period_k
                local idx = CyclicPointer(Idx_buffer, Settings.period_k - 1) + 1
                Highs[idx] = H(Idx_chart)
                Lows[idx] = L(Idx_chart)

                local idx_k = Idx_buffer - Settings.period_k
                if (idx_k >= 0)  then
                    local max_high = math.max(table.unpack(Highs))
                    local max_low = math.min(table.unpack(Lows))

                    local value_k1 = K_ma1(idx_k + 1, { [idx_k + 1] = C(Idx_chart) - max_low })

                    local value_k2 = K_ma2(idx_k + 1, { [idx_k + 1] = max_high - max_low })

                    local idx_d = Idx_buffer - (Settings.period_k + Settings.shift) + 1 --?+1
                    if ((idx_d >= 0) and (value_k2 ~= 0)) then
                        local stoch_k = 100 * value_k1 / value_k2
                        local stoch_d = D_ma(idx_d + 1, { [idx_d + 1] = stoch_k })

                        return stoch_k, stoch_d
                    end
                end
            end
        end

        return nil, nil
    end
end

----------------------------------------------------------------------------
-- function EMAi = (EMAi-1*(n-1)+2*Pi) / (n+1)
----------------------------------------------------------------------------
function EMA(Settings)
    local Ema_prev = 0
    local Ema_cur = 0
    local Idx_chart = 0
    local Idx_buffer = 0

    return function(index, prices)
        if (index == 1) then
            Ema_prev = 0
            Ema_cur = 0
            Idx_chart = 0
            Idx_buffer = 0
        end

        if CandleExist(index) then
            if (Idx_chart ~= index) then
                Idx_chart = index
                Idx_buffer = Idx_buffer + 1
                Ema_prev = Ema_cur
            end

            if (Idx_buffer == 1) then
                Ema_cur = prices[Idx_chart]
            else
                Ema_cur = (Ema_prev * (Settings.period_d - 1) + 2 * prices[Idx_chart]) / (Settings.period_d + 1)
            end

            if (Idx_buffer >= Settings.period_d) then
                return Ema_cur
            end
        end

        return nil
    end
end

----------------------------------------------------------------------------
-- function SMA = sums(Pi) / n
----------------------------------------------------------------------------
function SMA(Settings)
    local Sums = {}
    local Idx_chart = 0
    local Idx_buffer = 0

    return function (index, prices)
        if (index == 1) then
            Sums = {}
            Idx_chart = 0
            Idx_buffer = 0
        end

        if CandleExist(index) then
            if (Idx_chart ~= index) then
                Idx_chart = index
                Idx_buffer = Idx_buffer + 1
            end

            local idx_cur = CyclicPointer(Idx_buffer, Settings.shift)
            local idx_prev = CyclicPointer(Idx_buffer - 1, Settings.shift)
            local idx_oldest = CyclicPointer(Idx_buffer - Settings.shift, Settings.shift)

            Sums[idx_cur] = (Sums[idx_prev] or 0) + prices[Idx_chart] / Settings.shift

            if (Idx_buffer >= Settings.shift) then
                return (Sums[idx_cur] - (Sums[idx_oldest] or 0))
            end
        end

        return nil
    end
end
--#endregion

--==========================================================================
--#region INDICATOR RSI
--==========================================================================
----------------------------------------------------------------------------
-- function RSI calculate indicator RSI for durrent candle
----------------------------------------------------------------------------
function RSI(mode)
    local Settings = { period = RSIs[mode] }

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
                    return (100 - (100 / (1 + (value_up / value_down))))
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
--#endregion

--==========================================================================
--#region OSCILATOR SIGNALS
--==========================================================================
----------------------------------------------------------------------------
-- Signal Osc Steamer
----------------------------------------------------------------------------
function SignalOscSteamer(index, direction, oscs, diff, dev)
    if (CheckDataExist(index, 2, oscs.Slows) and CheckDataExist(index, 2, oscs.Fasts)) then

        local dev = dev or Signals.MinDeviation
        local diff = diff or Signals.MaxDifference

        return (-- osc fast and slow move in direction last 2 candles
            (EventMove(index, direction, oscs.Fasts, dev) and EventMove(index, direction, oscs.Slows, dev)) and 

            -- osc fast ralate osc slow in direction last 1 candle
            ConditionRelate(direction, oscs.Fasts[index], oscs.Slows[index], dev) and 

            -- delta beetwen osc fast and slow osc less then diff last 1 candle
            ConditionFlat(oscs.Fasts[index], oscs.Slows[index], diff))

    -- not enough data
    else
        return false
    end
end

----------------------------------------------------------------------------
-- Signal Osc Fast Cross Osc Slow
----------------------------------------------------------------------------
function SignalOscCross(index, direction, oscs, diff, dev)
    if (CheckDataExist(index, 2, oscs.Slows) and CheckDataExist(index, 2, oscs.Fasts)) then

        local dev = dev or Signals.MinDeviation
        local diff = diff or 0

        -- cross fast osc over/under slow osc
        -- return EventCross(index, direction, oscs.Fasts, oscs.Slows, dev)

        return ( -- first candle of two is equal or different like in cross
            (ConditionFlat(oscs.Fasts[index-1], oscs.Slows[index-1], diff) or ConditionRelate(Reverse(direction), oscs.Fasts[index-1], oscs.Slows[index-1], dev)) and 

            -- osc fast over/under osc slow in second candle of two
            ConditionRelate(direction, oscs.Fasts[index], oscs.Slows[index], dev))

    -- not enough data
    else
        return false
    end
end

----------------------------------------------------------------------------
-- Signal Osc Cross Level
----------------------------------------------------------------------------
function SignalOscCrossLevel(index, direction, osc, level, diff, dev)
    if (CheckDataExist(index, 2, osc)) then

        local dev = dev or Signals.MinDeviation
        local diff = diff or 0

        -- osc cross level up/down
        --[[ local levels = {[index-1] = level, [index] = level}
        return EventCross(index, direction, osc, levels, dev) ]]

        return ( -- first candle of two is equal or different like in cross
            (ConditionFlat(osc[index-1], level, diff) or ConditionRelate(Reverse(direction), osc[index-1], level, dev)) and

            -- osc fast over/under osc slow in second candle of two
            ConditionRelate(direction, osc[index], level, dev))

    -- not enough data
    else
        return false
    end
end

----------------------------------------------------------------------------
-- Signal Osc TrendOff
----------------------------------------------------------------------------
function SignalOscTrendOff(index, direction, oscs, dev)
    local level, osc

    -- check for rsi
    if (oscs.Name == RSIs.Name) then
        osc = RSIs.Slows

        if (direction == Directions.Long) then
            level = RSIs.HLines.BottomTrend
        elseif (direction == Directions.Short) then
            level = RSIs.HLines.TopTrend
        end

    -- chek for stochastic
    elseif (oscs.Name == Stochs.Name) then
        osc = Stochs.Slows

        if (direction == Directions.Long) then
            level = Stochs.HLines.BottomExtreme
        elseif (direction == Directions.Short) then
            level = Stochs.HLines.TopExtreme
        end

    -- chek for pc
    elseif (oscs.Name == PCs.Name) then
        if CheckDataExist(index, 2, PCs.Centres) then
            osc = Prices.Closes

            if (direction == Directions.Long) then
                level = PCs.Botttom[index-1]
            elseif (direction == Directions.Short) then
                level = PCs.Tops[index-1]
            end

        -- not enough data
        else
            return false
        end
    end

    return SignalOscCrossLevel(index, direction, osc, level, dev)
end

----------------------------------------------------------------------------
-- Signal Osc Uturn with 3 candles
----------------------------------------------------------------------------
function SignalOscUturn3(index, direction, oscs, diff, dev)
    if (CheckDataExist(index, 3, oscs.Slows) and CheckDataExist(index, 3, oscs.Fasts) and CheckDataExist(index, 3, oscs.Deltas)) then

        local dev = dev or Signals.MinDeviation
        local diff = diff or 0

        return -- fastosc uturn3: normal fast osc uturn3
            (EventUturn3(index, direction, oscs.Fasts, dev) and

            -- slowosc uturn3: normal uturn3 or equal oscslows at first and second candles and move at third candle from second to third candles of uturn3 or move all three candles of uturn3
            (EventUturn3(index, direction, oscs.Slows, dev) or ((EventFlat((index-1), oscs.Slows, diff) and EventMove(index, direction, oscs.Slows, dev)) or (EventMove((index-1), direction, oscs.Slows, dev) and EventMove(index, direction, oscs.Slows, dev)))) and

            -- deltas uturn3: uturn3 or equal oscdeltas at first and second candles and move at third candle from second to third candles of uturn3 or move all three candles of uturn3
            (EventUturn3(index, direction, oscs.Deltas, dev) or ((EventFlat((index-1), oscs.Deltas, diff) and EventMove(index, direction, oscs.Deltas, dev)) or (EventMove((index-1), direction, oscs.Deltas, dev) and EventMove(index, direction, oscs.Deltas, dev)))) and

            -- relation: fastosc over slowosc at first and third candles of uturn3 only
            (ConditionRelate(direction, oscs.Fasts[index-2], oscs.Slows[index-2], dev) and ConditionRelate(direction, oscs.Fasts[index], oscs.Slows[index], dev)) and

            -- strength: fastosc and slowosc at third candle greater or equal then ones at first candle of uturn3
            ((ConditionRelate(direction, oscs.Slows[index], oscs.Slows[index-2], dev) or ConditionFlat(oscs.Slows[index], oscs.Slows[index-2], diff)) and (ConditionRelate(direction, oscs.Fasts[index], oscs.Fasts[index-2], dev) or ConditionFlat(oscs.Fasts[index], oscs.Fasts[index-2], diff))))

    -- not enough data
    else
        return false
    end
end
--#endregion

--==========================================================================
--#region Price Signals
--==========================================================================
----------------------------------------------------------------------------
-- Signal Price	CrossMA
----------------------------------------------------------------------------
function SignalPriceCrossMA(index, direction, price, ma, diff, dev)
    if (CheckDataExist(index, 2, price) and CheckDataExist(index, 2, ma)) then

        local dev = dev or Signals.MinDeviation
        local diff = diff or 0

        -- close cross ma up/down
        -- return EventCross(index, direction, price, ma, dev)

        return (-- first candle of two is equal or different like in cross
            (ConditionFlat(ma[index-1], price[index-1], diff) or ConditionRelate(direction, ma[index-1], price[index-1], dev)) and 

            -- osc fast over/under osc slow in second candle of two
            ConditionRelate(direction, price[index], ma[index], dev))

    -- not enough data
    else
        return false
    end
end

----------------------------------------------------------------------------
-- Signal Price Uturn with 3 candles
----------------------------------------------------------------------------
function SignalPriceUturn3(index, direction, prices, mas, diff, dev)
    if (CheckDataExist(index, 3, prices.Opens) and CheckDataExist(index, 3, prices.Closes) and CheckDataExist(index, 3, prices.Highs) and CheckDataExist(index, 3, prices.Lows) and CheckDataExist(index, 3, mas.Centres) and CheckDataExist(index, 3, mas.Deltas)) then

        local dev = dev or Signals.MinDeviation
        local diff = diff or 0

        local condition = -- prices.Closes uturn3:
            (EventUturn3(index, direction, prices.Closes, dev) and

            -- mas uturn3: uturn3 or equal oscslows at first and second candles and move at third candle from second to third candles of uturn3 or move all three candles of uturn3
            -- (EventMove(index, direction, mas.Centres, dev) or EventFlat(index, mas.Centres, diff)) and (EventMove((index-1), direction, mas.Centres, dev) or EventFlat((index-1), mas.Centres, diff))
            (EventUturn3(index, direction, mas.Centres, dev) or ((EventFlat((index-1), mas.Centres, diff) and EventFlat(index, mas.Centres, diff)) or (EventFlat((index-1), mas.Centres, diff) and EventMove(index, direction, mas.Centres, dev)) or (EventMove((index-1), direction, mas.Centres, dev) and EventMove(index, direction, mas.Centres, dev)))) and

            -- delta uturn3: uturn3 or equal oscdeltas at first and second candles and move at third candle from second to third candles of uturn3 or move all three candles of uturn3
            (EventUturn3(index, direction, mas.Deltas, dev) or ((EventFlat((index-1), mas.Deltas, diff) and EventMove(index, direction, mas.Deltas, dev)) or (EventMove((index-1), direction, mas.Deltas, dev) and EventMove(index, direction, mas.Deltas, dev)))) and

            -- relation: first two candle contr-trend, one last candle pro-trend
            (((ConditionRelate(Reverse(direction), prices.Closes[index-2], prices.Opens[index-2], dev) or ConditionRelate(Reverse(direction), prices.Closes[index-1], prices.Opens[index-1], dev)) and ConditionRelate(direction, prices.Closes[index], prices.Opens[index], dev)) and (ConditionRelate(direction, prices.Open[index-2], mas.Centres[index-2], dev) and (ConditionRelate(direction, prices.Opens[index-1], mas.Centres[index-1], dev) or ConditionRelate(direction, prices.Closes[index-1], mas.Centres[index-1], dev)) and ConditionRelate(direction, prices.Closes[index], mas.Centres[index], dev))))
            
            -- strength condition
            -- and (ConditionRelate(direction, prices.Closes[index], prices.Opens[index-2], dev) or ConditionRelate(direction, prices.Closes[index], prices.Opens[index-1], dev)) and ConditionRelate(direction, prices.Closes[index], prices.Closes[index-2], dev)

        if (direction == Directions.Long) then
            return (condition and
                -- strength condition
                ((prices.Closes[index-1] > (prices.Lows[index-3] + 2.0 / 3.0 * (prices.Highs[index-3] - prices.Lows[index-3]))) or  (prices.Closes[index-1] > (prices.Lows[index-2] + 2.0 / 3.0 * (prices.Highs[index-2] - prices.Lows[index-2])))))

        elseif (direction == Directions.Short) then
            return (condition and
                -- strength condition
                (((prices.Highs[index-3] - 2.0 / 3.0 * (prices.Highs[index-3] - prices.Lows[index-3])) > prices.Closes[index-1]) or ((prices.Highs[index-2] - 2.0 / 3.0 * (prices.Highs[index-2] - prices.Lows[index-2])) > prices.Closes[index-1])))
        end

    -- not enough data
    else
        return false
    end
end
--#endregion

--==========================================================================
--#region Events
--==========================================================================
----------------------------------------------------------------------------
-- Event Value1 cross Value2 up and down
----------------------------------------------------------------------------
function EventCross(index, direction, value1, value2, dev)
    return (ConditionRelate(direction, value2[index-1], value1[index-1], dev) and ConditionRelate(direction, value1[index], value2[index], dev))
end

----------------------------------------------------------------------------
-- Event 2 last candles Value move up or down
----------------------------------------------------------------------------
function EventMove(index, direction, value, dev)
    return ConditionRelate(direction, value[index], value[index-1], dev)
end

----------------------------------------------------------------------------
-- Event 3 last candles Value uturn up or down
----------------------------------------------------------------------------
function EventUturn3(index, direction, value, dev)
    return (ConditionRelate(direction, value[index-2], value[index-1], dev) and ConditionRelate(direction, value[index], value[index-1], dev))
end

----------------------------------------------------------------------------
-- Event is 2 last candles Value is equal
----------------------------------------------------------------------------
function EventFlat(index, value, dev)
    return (math.abs(GetDelta(value[index], value[index-1])) <= dev)
end

----------------------------------------------------------------------------
-- Condition Is Value1 over or under Value2
----------------------------------------------------------------------------
function ConditionRelate(direction, value1, value2, dev)
    if (direction == Directions.Long) then
        return (value1 > (value2 + dev))
    elseif (direction == Directions.Short) then
        return (value2 > (value1 + dev))
    end
end

----------------------------------------------------------------------------
-- Condition Is Value1 equal Value2
----------------------------------------------------------------------------
function ConditionFlat(value1, value2, diff)
    return (math.abs(GetDelta(value1, value2)) <= diff)
end
--#endregion

--==========================================================================
--#region UTILITIES
--==========================================================================
----------------------------------------------------------------------------
-- function Reverse() return reverse of direction
----------------------------------------------------------------------------
function Reverse(direction)
    if (direction == Directions.Long) then
        return Directions.Short
    elseif (direction == Directions.Short) then
        return Directions.Long
    end
end

----------------------------------------------------------------------------
-- function GetDelta() return abs difference between values
----------------------------------------------------------------------------
function GetDelta(value1, value2)
    if ((value1 == nil) or (value2 == nil)) then
        return nil
    end

    -- return math.abs(value1 - value2)
    return (value1 - value2)

end

----------------------------------------------------------------------------
-- function Squeeze() return number from 0 (if index start from 1) to period and then again from 0 (index == period) pointer in cycylic buffer
----------------------------------------------------------------------------
function CyclicPointer(index, period)
    return math.fmod(index - 1, period + 1)
end

----------------------------------------------------------------------------
-- function RoundScale() return value with requred numbers after digital point
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
-- function GetChartTag() return chart tag from Robot name and Indicator name
----------------------------------------------------------------------------
function GetChartTag(indicator_name)
    return (Settings.Name .. indicator_name)
end

----------------------------------------------------------------------------
-- function SetSignal() set signal variables and state
----------------------------------------------------------------------------
function SetSignal(index, direction, indicator, signal)
    -- set signal up/down off
    Signals[signal.Name][Reverse(direction)][indicator.Name].Candle = 0

    -- set signal down/up on
    Signals[signal.Name][direction][indicator.Name].Count = Signals[signal.Name][direction][indicator.Name].Count + 1
    Signals[signal.Name][direction][indicator.Name].Candle = index
end

--------------------------------------------------------------------------
-- function CheckDataExist() return true if number values from index back exist
----------------------------------------------------------------------------
function CheckDataExist(index, number, value)
    -- if index under required number return false
    if (index <= number) then
        return false
    end

    local count
    for count = 0, (number-1), 1 do

        -- if one of number values not exist return false
        if (value[index-count] == nil) then
            return false
        end
    end

    return true
end

----------------------------------------------------------------------------
-- function CheckChartPermission() Returns the truth if signal permission is alowed by permissions of chart
----------------------------------------------------------------------------
function CheckChartPermission(indicator, signal_permission)
    return (((signal_permission == ChartPermissions.Event) and ((indicator.Permission & ChartPermissions.Event) > 0)) or ((signal_permission == ChartPermissions.Signal) and ((indicator.Permission & ChartPermissions.Signal) > 0)) or ((signal_permission == ChartPermissions.State) and ((indicator.Permission & ChartPermissions.State) > 0))  or ((signal_permission == ChartPermissions.Enter) and ((indicator.Permission & ChartPermissions.Enter) > 0)))
end
----------------------------------------------------------------------------
-- function GetMessage(...) Returns messages separated by the symbol as one string 
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
-- function PrintDebugMessage(message1, message2, ...) print messages as one string separated by symbol in message window and debug console
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

-----------------------------------------------------------------------------
-- function GetChartLabelXPos() returns x position for chart label
-----------------------------------------------------------------------------
function GetChartLabelXPos(t)
    return tostring(10000 * t.year + 100 * t.month + t.day), tostring(10000 * t.hour + 100 * t.min + t.sec)
end

----------------------------------------------------------------------------
-- function GetChartLabelYPos() returns y position for chart label
--todo make cyclic variable for several levels of y position
----------------------------------------------------------------------------
function GetChartLabelYPos(index, direction, indicator)
    local y
    local sign = (direction == Directions.Long) and -1 or 1
    local price = (direction == Directions.Long) and "Lows" or "Highs"

    -- y pos for price chart
    if (indicator.Name == Prices.Name) then
        y = Prices[price][index] + sign * Prices.Step * SecInfo.min_price_step

    -- y pos for stoch/rsi chart
    else
        y = indicator.Slows[index] * (100 + sign * indicator.Step) / 100
    end

    return y
end

----------------------------------------------------------------------------
-- function GetChartIcon() returns icon path for chart label
----------------------------------------------------------------------------
function GetChartIcon(direction, icon)
    icon = icon or ChartIcons.Triangle

    return ( ChartLabels.Params.IconPath  .. icon .. "_" .. direction .. ".jpg")
end

----------------------------------------------------------------------------
-- function SetChartLabel() set chart label
----------------------------------------------------------------------------
function SetChartLabel(index, direction, indicator, signal, icon, signal_permission, text)

    -- check signal level and chart levels
    if CheckChartPermission(indicator, signal_permission) then

        -- delete label duplicates
        local chart_tag = GetChartTag(indicator.Name)

        if (ChartLabels[indicator.Name][index] ~= nil) then
            DelLabel(chart_tag, ChartLabels[indicator.Name][index])
        end

        -- set label icon
        ChartLabels.Params.IMAGE_PATH = GetChartIcon(direction, icon)

        -- set label position
        ChartLabels.Params.DATE, ChartLabels.Params.TIME = GetChartLabelXPos(T(index))

        ChartLabels.Params.YVALUE = GetChartLabelYPos(index, direction, indicator)

        -- set chart alingment from direction
        if (direction == Directions.Long) then
            ChartLabels.Params.ALIGNMENT = "BOTTOM"
        elseif (direction == Directions.Short) then
            ChartLabels.Params.ALIGNMENT = "TOP"
        end

        -- set text
        ChartLabels.Params.TEXT = GetMessage(direction, signal.Name, Signals[signal.Name][direction][indicator.Name].Count)

        ChartLabels.Params.HINT = GetMessage(ChartLabels.Params.TEXT, Signals[signal.Name][direction][indicator.Name].Candle, text)

        -- set chart label return id
        return AddLabel(chart_tag, ChartLabels.Params)

    -- nothing todo
    else
        return nil
    end
end

----------------------------------------------------------------------------
-- function SetInitialCounts() init Signals Candles and Counts
----------------------------------------------------------------------------
function SetInitialValues(t)
    local k, v
    for k, v in pairs(t) do
        if (type(v) == "table") then
            foo(v)
        else 
            t[k] = 0
        end
    end
end

----------------------------------------------------------------------------
--
----------------------------------------------------------------------------
function PrintDebugSummary(t)
    local k, v
    for k, v in pairs(t) do		
        if (type(v) == "table") then
            foo(v)
        else 
            PrintDebugMessage(tostring(k), tostring(t[k]))
        end
    end
end

--#endregion

----------------------------------------------------------------------------
--#region additional table functions
----------------------------------------------------------------------------
--
-- table.val_to_str
--
--[[ function table.val_to_str(v)
    if (type(v) == "string")  then
        v = string.gsub(v, "\n", "\\n")
        if string.match(string.gsub(v, "[^'\"]", ""), '^"+$') then
            return "'" .. v .. "'"
        end
        return '"' .. string.gsub(v, '"', '\\"') .. '"'
    end
    return (type(v) == "table") and table.tostring(v) or tostring(v)
end --]]

--
-- table.key_to_str
--
--[[ function table.key_to_str(k)
    if ((type(k) =="string") and string.match(k, "^[_%a][_%a%d]*$")) then
        return k
    end
    return "[" .. table.val_to_str(k) .. "]"
end ]]

--
-- table.tostring
--
--[[ function table.tostring(tbl)
    if (type(tbl) ~= 'table') then
        return table.val_to_str(tbl)
    end

    local result, done = {}, {}
    for k, v in ipairs(tbl) do
        table.insert(result, table.val_to_str(v))
        done[k] = true
    end

    for k, v in pairs(tbl) do
        if not done[k] then
            table.insert(result, table.key_to_str(k) .. "=" .. table.val_to_str(v))
        end
    end
    return "{" .. table.concat(result, ",") .. "}"
end ]]

--
-- table.tostring
--
--[[ function table.load(fname)
    local f, err = io.open(fname, "r")
    if (f == nil) then
        return {}
    end

    local fn, err = loadstring("return " .. f:read("*a"))
    f:close()

    if (type(fn) == "function") then
        local succ, res = pcall(fn)
        if (succ and type(res) == "table") then
            return res
        end
    end
    return {}
end ]]

--
-- table.save
--
--[[ function table.save(fname, tbl)
    local f, err = io.open(fname, "w")
    if (f ~= nil) then
        f:write(table.tostring(tbl))
        f:close()
    end
end ]]
--#endregion
--[[ EOF ]]--
