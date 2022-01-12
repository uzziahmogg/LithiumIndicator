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
--// recode SetInitValues and PrintDebugSummary to cycles over all pairs

--todo create func CheckElementarySignal
--todo remake all error handling to exceptions in functional programming
--todo remove all chart labels keep only last 30
--todo remove all prices and inds array, kepp only last three
--// shift uturn slow and fast lines
--// remove SochCross from Signals -> remove relation in uturn3
--// remove delta in uturn3
--todo enter for Trendoff
--todo check signals in realtime
--todo enter for Uturn3
--// all variants for StochSlow in Uturn3
--todo 2 signals with 2nd leg zigzag near lvl50
--todo 1st leg zigzag with divergence
--todo combinations of enter
--todo functions Uturn, Spring for RSI Uturn3
--todo functions Place for Stoch Uturn3

--todo loging to CSV
--todo transaction
--todo make stoploss to nearest ext
--todo position menegement
--todo risk menegement
--todo check new signal functions and add strength signals

--? make code for CheckComplexSignals
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

--* relate in 1) StochCross 2) Uturn3 3) StochSteamer
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
    Stochs = { Name = "Stoch", Fasts = {}, Slows = {}, HLines = { TopExtreme = 80, Centre = 50, BottomExtreme = 20 }, Slow = { PeriodK = 10, Shift = 3, PeriodD = 1 }, Fast = { PeriodK = 5, Shift = 2, PeriodD = 1 }, Dev = 0, Step = 20, Permission = ChartPermissions.Event } -- FEK_LITHIUMStoch
    -- RSI data arrays and params
    RSIs = { Name = "RSI", Fasts = {}, Slows = {}, HLines = { TopExtreme = 80, TopTrend = 60, Centre = 50, BottomTrend = 40, BottomExtreme = 20 }, Slow = 14, Fast = 9, Dev = 0, Step = 5, Permission = ChartPermissions.Signal } -- FEK_LITHIUMRSI
    -- price channel data arrays and params
    PCs = { Name = "PC", Tops = {}, Bottoms = {}, Centres = {}, Period = 20 }

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
    Signals = { Cross = { Name = "Cross", [Directions.Long] = { [Stochs.Name] = { Count = 0, Candle = 0 }, [RSIs.Name] = { Count = 0, Candle = 0 }}, [Directions.Short] = { [Stochs.Name] = { Count = 0, Candle = 0 }, [RSIs.Name] = { Count = 0, Candle = 0 }}},
    Cross50 = { Name = "Cross50", [Directions.Long] = { [Prices.Name] = { Count = 0, Candle = 0 }, [Stochs.Name] = { Count = 0, Candle = 0 }}, [Directions.Short] = { [Prices.Name] = { Count = 0, Candle = 0 }, [Stochs.Name] = { Count = 0, Candle = 0 }}},
    Steamer = { Name = "Steamer", [Directions.Long] = { [Stochs.Name] = { Count = 0, Candle = 0 }}, [Directions.Short] = { [Stochs.Name] = { Count = 0, Candle = 0 }}},
    TrendOff = { Name = "TrendOff", [Directions.Long] = { [Stochs.Name] = { Count = 0, Candle = 0 }}, [Directions.Short] = { [Stochs.Name] = { Count = 0, Candle = 0 }}},
    Uturn31 = { Name = "Uturn31", [Directions.Long] = { [Prices.Name] = { Count = 0, Candle = 0 }, [Stochs.Name] = { Count = 0, Candle = 0 }, [RSIs.Name] = { Count = 0, Candle = 0 }}, [Directions.Short] = { [Prices.Name] = { Count = 0, Candle = 0 }, [Stochs.Name] = { Count = 0, Candle = 0 }, [RSIs.Name] = { Count = 0, Candle = 0 }}},
    Uturn32 = { Name = "Uturn32", [Directions.Long] = { [Prices.Name] = { Count = 0, Candle = 0 }, [Stochs.Name] = { Count = 0, Candle = 0 }, [RSIs.Name] = { Count = 0, Candle = 0 }}, [Directions.Short] = { [Prices.Name] = { Count = 0, Candle = 0 }, [Stochs.Name] = { Count = 0, Candle = 0 }, [RSIs.Name] = { Count = 0, Candle = 0 }}},
    Enter = { Name = "Enter", Count = 0, Candle = 0},
    MaxDuration = 2, MaxDifference = 30, MinDifference = 0, MinDeviation = 0 }

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

        Nesting = 1
        SetInitialValues(Signals)
        
        ProcessedIndex = 0
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

    -- calculate current rsi
    RSIs.Fasts[index] = RSIFast(index)
    RSIs.Slows[index] = RSISlow(index)
    RSIs.Fasts[index] = RoundScale(RSIs.Fasts[index], SecInfo.scale)
    RSIs.Slows[index] = RoundScale(RSIs.Slows[index], SecInfo.scale)

    -- calculate current price channel
    PCs.Tops[index], PCs.Bottoms[index] = PC(index)
    PCs.Tops[index] = RoundScale(PCs.Tops[index], SecInfo.scale)
    PCs.Bottoms[index] = RoundScale(PCs.Bottoms[index], SecInfo.scale)
    PCs.Centres[index] = (PCs.Tops[index] ~= nil) and (PCs.Bottoms[index] ~= nil) and RoundScale((PCs.Bottoms[index] + (PCs.Tops[index] - PCs.Bottoms[index]) / 2), SecInfo.scale) or nil
    --#endregion

    local t = T(index)
    PrintDebugMessage(index, t.month, t.day, t.hour, t.min)

    if (ProcessedIndex ~= index) then
        --=======================================================================
        -- I. Price Signals
        --=======================================================================
        -------------------------------------------------------------------------
        --#region I.1. Signals.CrossMA[Down/Up].Price
        -------------------------------------------------------------------------
        PrintDebugMessage("I1-Price-Cross50", index, t.month, t.day, t.hour, t.min)

        -- check start signal price cross ma up
        if (Signal2Cross((index-1), Directions.Long, Prices.Closes, PCs.Centres)) then
            PrintDebugMessage("I1-Price-Cross50-Long", (index-1), t.month, t.day, t.hour, t.min)
        
            -- set signal
            SetSignal((index-1), Directions.Long, Prices, Signals.Cross50)

            -- set chart label
            ChartLabels[Prices.Name][index-1] = SetChartLabel((index-1), Directions.Long, Prices, Signals.Cross50, ChartIcons.Arrow, ChartPermissions.Event)
        end -- long

        -- check start signal price cross ma down
        if (Signal2Cross(index-1, Directions.Short, Prices.Closes, PCs.Centres)) then
            PrintDebugMessage("I1-Price-Cross50-Short", (index-1), t.month, t.day, t.hour, t.min)
            
            -- set signal
            SetSignal((index-1), Directions.Short, Prices, Signals.Cross50)

            -- set chart label
            ChartLabels[Prices.Name][index-1] = SetChartLabel((index-1), Directions.Short, Prices, Signals.Cross50, ChartIcons.Arrow, ChartPermissions.Event)
        end -- short
        --#endregion

        -------------------------------------------------------------------------
        --#region I.2. Signals.Uturn31[Down/Up].Price
        -------------------------------------------------------------------------
        PrintDebugMessage("I2-Price-Uturn31", index, t.month, t.day, t.hour, t.min)

        -- check start signal uturn31 up
        if (Signal2Uturn31((index-1), Directions.Long, Prices.Closes, PCs.Centres)) then
            PrintDebugMessage("I2-Price-Uturn31-Long", (index-1), t.month, t.day, t.hour, t.min)
            
            -- set signal on
            SetSignal((index-1), Directions.Long, Prices, Signals.Uturn31)

            -- set chart label
            ChartLabels[Prices.Name][index-1] = SetChartLabel((index-1), Directions.Long, Prices, Signals.Uturn31, ChartIcons.Arrow, ChartPermissions.Event)
        end -- long

        -- check start signal uturn31 down
        if (Signal2Uturn31((index-1), Directions.Short, Prices.Closes, PCs.Centres)) then
            PrintDebugMessage("I2-Price-Uturn31-Short", (index-1), t.month, t.day, t.hour, t.min)

            -- set signal on
            SetSignal((index-1), Directions.Short, Prices, Signals.Uturn31)

            -- set chart label
            ChartLabels[Prices.Name][index-1] = SetChartLabel((index-1), Directions.Short, Prices, Signals.Uturn31, ChartIcons.Arrow, ChartPermissions.Event)
        end -- short

        -------------------------------------------------------------------------
        --#region I.3. Signals.Uturn32[Down/Up].Price
        -------------------------------------------------------------------------
        PrintDebugMessage("I3-Price-Uturn32", index, t.month, t.day, t.hour, t.min)

        -- check start signal uturn32 up
        if (Signal2Uturn32((index-1), Directions.Long, Prices.Closes, PCs.Centres)) then
            PrintDebugMessage("I3-Price-Uturn32-Long", (index-1), t.month, t.day, t.hour, t.min)

            -- set signal on
            SetSignal((index-1), Directions.Long, Prices, Signals.Uturn32)

            -- set chart label
            ChartLabels[Prices.Name][index-1] = SetChartLabel((index-1), Directions.Long, Prices, Signals.Uturn32, ChartIcons.Arrow, ChartPermissions.Event)
        end -- long

        -- check start signal uturn32 down
        if (Signal2Uturn32((index-1), Directions.Short, Prices.Closes, PCs.Centres)) then
            PrintDebugMessage("I3-Price-Uturn32-Short", (index-1), t.month, t.day, t.hour, t.min)

            -- set signal on
            SetSignal((index-1), Directions.Short, Prices, Signals.Uturn32)

            -- set chart label
            ChartLabels[Prices.Name][index-1] = SetChartLabel((index-1), Directions.Short, Prices, Signals.Uturn32, ChartIcons.Arrow, ChartPermissions.Event)
        end -- short
        --#endregion

        --=======================================================================
        -- II. Stoch Signals
        --=======================================================================
        -------------------------------------------------------------------------
        --#region II.1. Signals.Cross[Down/Up].Stochs
        -------------------------------------------------------------------------
        PrintDebugMessage("II1-Stoch-Cross", index, t.month, t.day, t.hour, t.min)

        -- check fast stoch cross slow stoch up
        if (SignalCross((index-1), Directions.Long, Stochs)) then
            PrintDebugMessage("II1-Stoch-Cross-Long", (index-1), t.month, t.day, t.hour, t.min)

            -- set signal
            SetSignal((index-1), Directions.Long, Stochs, Signals.Cross)

            -- set chart label
            ChartLabels[Stochs.Name][index-1] = SetChartLabel((index-1), Directions.Long, Stochs, Signals.Cross, ChartIcons.Romb, ChartPermissions.Signal)
        end -- long

        -- check fast stoch cross slow stoch down
        if (SignalCross((index-1), Directions.Short, Stochs)) then
            PrintDebugMessage("II1-Stoch-Cross-Short", (index-1), t.month, t.day, t.hour, t.min)

            -- set signal
            SetSignal((index-1), Directions.Short, Stochs, Signals.Cross)

            -- set chart label
            ChartLabels[Stochs.Name][index-1] = SetChartLabel((index-1), Directions.Short, Stochs, Signals.Cross, ChartIcons.Romb, ChartPermissions.Signal)
        end -- short
        --#endregion

        -------------------------------------------------------------------------
        --#region II.2. Signals.Cross50[Down/Up].Stochs
        -------------------------------------------------------------------------
        PrintDebugMessage("II2-Stoch-Cross50", index, t.month, t.day, t.hour, t.min)

        -- check slow stoch cross lvl50 up
        if (SignalCrossLevel((index-1), Directions.Long, Stochs.Slows, Stochs.HLines.Centre)) then
            PrintDebugMessage("II2-Stoch-Cross50-Long", (index-1), t.month, t.day, t.hour, t.min)

            -- set signal
            SetSignal((index-1), Directions.Long, Stochs, Signals.Cross50)

            -- set chart label
            ChartLabels[Stochs.Name][index-1] = SetChartLabel((index-1), Directions.Long, Stochs, Signals.Cross50, ChartIcons.Arrow, ChartPermissions.Signal)
        end -- long

        -- check slow stoch cross lvl50 down
        if (SignalCrossLevel((index-1), Directions.Short, Stochs.Slows, Stochs.HLines.Centre)) then
            PrintDebugMessage("II2-Stoch-Cross50-Short", (index-1), t.month, t.day, t.hour, t.min)

            -- set signal
            SetSignal((index-1), Directions.Short, Stochs, Signals.Cross50)

            -- set chart label
            ChartLabels[Stochs.Name][index-1] = SetChartLabel((index-1), Directions.Short, Stochs, Signals.Cross50, ChartIcons.Arrow, ChartPermissions.Signal)
        end -- short
        --#endregion

        -------------------------------------------------------------------------
        --#region II.3. Signals.Steamer[Down/Up].Stochs
        -------------------------------------------------------------------------
        PrintDebugMessage("II3-Stoch-Steamer", index, t.month, t.day, t.hour, t.min)

        -- check stoch steamer up
        if (SignalSteamer((index-1), Directions.Long, Stochs)) then
            PrintDebugMessage("II3-Stoch-Steamer-Long", (index-1), t.month, t.day, t.hour, t.min)

            -- set signal on
            SetSignal((index-1), Directions.Long, Stochs, Signals.Steamer)

            -- set chart label
            ChartLabels[Stochs.Name][index-1] = SetChartLabel((index-1), Directions.Long, Stochs, Signals.Steamer, ChartIcons.Plus, ChartPermissions.Signal)
        end -- long

        -- check stoch steamer down
        if (SignalSteamer((index-1), Directions.Short, Stochs)) then
            PrintDebugMessage("II3-Stoch-Steamer-Short", (index-1), t.month, t.day, t.hour, t.min)

            -- set signal on
            SetSignal((index-1), Directions.Short, Stochs, Signals.Steamer)

            -- set chart label
            ChartLabels[Stochs.Name][index-1] = SetChartLabel((index-1), Directions.Short, Stochs, Signals.Steamer, ChartIcons.Plus, ChartPermissions.Signal)
        end -- short
        --#endregion

        -------------------------------------------------------------------------
        --#region II.4. Signals.Uturn31[Down/Up].Stochs
        -------------------------------------------------------------------------
        PrintDebugMessage("II4-Stoch-Uturn31", index, t.month, t.day, t.hour, t.min)

        -- check slow stoch uturn 3 candles up
        if (SignalUturn31((index-1), Directions.Long, Stochs)) then
            PrintDebugMessage("II4-Stoch-Uturn31-Long", index, t.month, t.day, t.hour, t.min)

            -- set signal on
            SetSignal((index-1), Directions.Long, Stochs, Signals.Uturn31)

            -- set chart label
            ChartLabels[Stochs.Name][index-1] = SetChartLabel((index-1), Directions.Long, Stochs, Signals.Uturn31, ChartIcons.Triangle, ChartPermissions.Signal)
        end -- long

        -- check slow stoch uturn 3 candles down
        if (SignalUturn31((index-1), Directions.Short, Stochs)) then
            PrintDebugMessage("II4-Stoch-Uturn31-Short", index, t.month, t.day, t.hour, t.min)

            -- set signal on
            SetSignal((index-1), Directions.Short, Stochs, Signals.Uturn31)

            -- set chart label
            ChartLabels[Stochs.Name][index-1] = SetChartLabel((index-1), Directions.Short, Stochs, Signals.Uturn31, ChartIcons.Triangle, ChartPermissions.Signal)
        end -- short
        --#endregion

        -------------------------------------------------------------------------
        --#region II.5. Signals.Uturn32[Down/Up].Stochs
        -------------------------------------------------------------------------
        PrintDebugMessage("II5-Stoch-Uturn32", index, t.month, t.day, t.hour, t.min)

        -- check slow stoch uturn 3 candles up
        if (SignalUturn32((index-1), Directions.Long, Stochs)) then
            PrintDebugMessage("II5-Stoch-Uturn32-Long", index, t.month, t.day, t.hour, t.min)

            -- set signal on
            SetSignal((index-1), Directions.Long, Stochs, Signals.Uturn32)

            -- set chart label
            ChartLabels[Stochs.Name][index-1] = SetChartLabel((index-1), Directions.Long, Stochs, Signals.Uturn32, ChartIcons.Triangle, ChartPermissions.Event)
        end -- long

        -- check slow stoch uturn 3 candles down
        if (SignalUturn32((index-1), Directions.Short, Stochs)) then
            PrintDebugMessage("II5-Stoch-Uturn32-Short", index, t.month, t.day, t.hour, t.min)

            -- set signal on
            SetSignal((index-1), Directions.Short, Stochs, Signals.Uturn32)

            -- set chart label
            ChartLabels[Stochs.Name][index-1] = SetChartLabel((index-1), Directions.Short, Stochs, Signals.Uturn32, ChartIcons.Triangle, ChartPermissions.Event)
        end -- short
        --#endregion

        -------------------------------------------------------------------------
        --#region III.6. Signals.TrendOff[Down/Up].Stochs
        -------------------------------------------------------------------------
        PrintDebugMessage("II6-Stoch-TrendOff", index, t.month, t.day, t.hour, t.min)

        -- check start signal up trendoff - slow osc enter off uptrend zone
        if SignalTrendOff((index-1), Directions.Short, Stochs) then
            PrintDebugMessage("II6-Stoch-TrendOff-Long", index, t.month, t.day, t.hour, t.min)

            -- set signal on
            SetSignal((index-1), Directions.Short, Stochs, Signals.TrendOff)

            -- set chart label
            ChartLabels[Stochs.Name][index-1] = SetChartLabel((index-1), Directions.Short, Stochs, Signals.TrendOff, ChartIcons.Point, ChartPermissions.Event)
        end -- long

        -- check start signal down trendoff - slow osc enter off down trend zone
        if SignalTrendOff((index-1), Directions.Long, Stochs) then
            PrintDebugMessage("II6-Stoch-TrendOff-Short", index, t.month, t.day, t.hour, t.min)

            SetSignal((index-1), Directions.Long, Stochs, Signals.TrendOff)

            -- set chart label
            ChartLabels[Stochs.Name][index-1] = SetChartLabel((index-1), Directions.Long, Stochs, Signals.TrendOff, ChartIcons.Point, ChartPermissions.Event)
        end -- short
        --#endregion

        --=======================================================================
        -- III. RSI Signals
        --=======================================================================
        -------------------------------------------------------------------------
        --#region III.1. Signals.Cross[Down/Up].RSIs
        -------------------------------------------------------------------------
        -- check fast rsi cross slow rsi up
        --[[if (SignalCross((index-1), Directions.Long, RSIs)) then
            --set signal on
            SetSignal((index-1), Directions.Long, RSIs, Signals.Cross)

            -- set chart label
            ChartLabels[RSIs.Name][index-1] = SetChartLabel((index-1), Directions.Long, RSIs, Signals.Cross, ChartIcons.Romb, ChartPermissions.Event)
        end -- long

        -- check fast rsi cross slow rsi down
        if (SignalCross((index-1), Directions.Short, RSIs)) then
            -- set signals on
            SetSignal((index-1), Directions.Short, RSIs, Signals.Cross)

            -- set chart label
            ChartLabels[RSIs.Name][index-1] = SetChartLabel((index-1), Directions.Short, RSIs, Signals.Cross, ChartIcons.Romb, ChartPermissions.Event)
        end -- short
        --#endregion

        -------------------------------------------------------------------------
        --#region III.2. Signals.Uturn31[Down/Up].RSIs
        -------------------------------------------------------------------------
            -- check slow RSI uturn 3 candles up
            if (SignalUturn31((index-1), Directions.Long, RSIs)) then
                -- set signal on
                SetSignal((index-1), Directions.Long, RSIs, Signals.Uturn31)

                -- set chart label
                ChartLabels[RSIs.Name][index-1] = SetChartLabel((index-1), Directions.Long, RSIs, Signals.Uturn31, ChartIcons.Triangle, ChartPermissions.Signal)
            end -- long

            -- check slow RSI uturn 3 candles down
            if (SignalUturn31((index-1), Directions.Short, RSIs)) then
                -- set signal on
                SetSignal((index-1), Directions.Short, RSIs, Signals.Uturn31)

                -- set chart label
                ChartLabels[RSIs.Name][index-1] = SetChartLabel((index-1), Directions.Short, RSIs, Signals.Uturn31, ChartIcons.Triangle, ChartPermissions.Signal)
            end -- short

            
        -------------------------------------------------------------------------
        --#region III.3. Signals.Uturn32[Down/Up].RSIs
        -------------------------------------------------------------------------
            -- check slow RSI uturn 3 candles up
            if (SignalUturn32((index-1), Directions.Long, RSIs)) then
                -- set signal on
                SetSignal((index-1), Directions.Long, RSIs, Signals.Uturn32)

                -- set chart label
                ChartLabels[RSIs.Name][index-1] = SetChartLabel((index-1), Directions.Long, RSIs, Signals.Uturn32, ChartIcons.Triangle, ChartPermissions.Signal)
            end -- long

            -- check slow RSI uturn 3 candles down
            if (SignalUturn32((index-1), Directions.Short, RSIs)) then
                -- set signal on
                SetSignal((index-1), Directions.Short, RSIs, Signals.Uturn32)

                -- set chart label
                ChartLabels[RSIs.Name][index-1] = SetChartLabel((index-1), Directions.Short, RSIs, Signals.Uturn32, ChartIcons.Triangle, ChartPermissions.Signal)
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
        end ]]
        --#endregion

        ProcessedIndex = index
    end

    -- debuglog    
    if (index == 5816) then
        PrintDebugSummary()
    end

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
--#region SIGNALS
--==========================================================================
----------------------------------------------------------------------------
-- Signal Steamer - fast and slow move synchro in one direction
----------------------------------------------------------------------------
function SignalSteamer(index, direction, oscs, diff, dev)
    if (CheckDataExist(index, 2, oscs.Fasts) and CheckDataExist(index, 2, oscs.Slows)) then

        local dev = dev or Signals.MinDeviation
        local diff = diff or Signals.MaxDifference

        return (-- osc fast and slow move in direction last 2 candles
            (EventMove(index, direction, oscs.Fasts, dev) and EventMove(index, direction, oscs.Slows, dev)) and

            -- osc fast ralate osc slow in direction last 1 candle
            CheckRelate(direction, oscs.Fasts[index], oscs.Slows[index], dev) and

            -- delta beetwen osc fast and slow osc less then diff last 1 candle
            CheckFlat(oscs.Fasts[index], oscs.Slows[index], diff))

    -- not enough data
    else
        return false
    end
end

----------------------------------------------------------------------------
-- Signal Fast Cross Slow Up/Down
----------------------------------------------------------------------------
function SignalCross(index, direction, oscs, diff, dev)
    return Signal2Cross(index, direction, oscs.Fasts, oscs.Slows, diff, dev)
end

function Signal2Cross(index, direction, values1, values2, diff, dev)
    if (CheckDataExist(index, 2, values1) and CheckDataExist(index, 2, values2)) then
        local dev = dev or Signals.MinDeviation
        local diff = diff or Signals.MinDifference

        return ( -- two first candle is equal, two last candles is different
        (CheckFlat(values1[index-1], values2[index-1], diff) and CheckRelate(direction, values1[index], values2[index], dev)) or
        -- cross fast osc over/under slow osc
        EventCross(index, direction, values1, values2, dev))
            
    -- not enough data
    else
        return false
    end
end

----------------------------------------------------------------------------
-- Signal TrendOff
----------------------------------------------------------------------------
function SignalTrendOff(index, direction, oscs, dev)
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

    return SignalCrossLevel(index, direction, osc, level, dev)
end

----------------------------------------------------------------------------
-- Signal values Cross Level
----------------------------------------------------------------------------
function SignalCrossLevel(index, direction, values, level, diff, dev)
    if (CheckDataExist(index, 2, values)) then

        local dev = dev or Signals.MinDeviation
        local diff = diff or Signals.MinDifference

        return ( -- two first candle is equal, two last candles is different
            (CheckFlat(values[index-1], level, diff) and CheckRelate(direction, values[index], level, dev)) or
            -- cross fast values over/under level
            EventCross(index, direction, values, {[index-1] = level, [index] = level}, dev))

    -- not enough data
    else
        return false
    end
end

----------------------------------------------------------------------------
-- Signal Uturn with 3 candles model 1 - fast uturn3 with shifts and slow uturn3
----------------------------------------------------------------------------
function SignalUturn31(index, direction, oscs, dev)
    return Signal2Uturn31(index, direction, oscs.Fasts, oscs.Slows, dev)
end

----------------------------------------------------------------------------
function Signal2Uturn31(index, direction, values1, values2, dev)
    if (CheckDataExist(index, 5, values1) and CheckDataExist(index, 3, values2)) then
        local dev = dev or Signals.MinDeviation
        
        return ((EventUturn3(index, direction, values1, dev) or EventUturn3((index-1), direction, values1, dev) or EventUturn3((index-2), direction, values1, dev)) and EventUturn3(index, direction, values2, dev))

    -- not enough data
    else
        return false
    end
end

----------------------------------------------------------------------------
-- Signal Uturn with 3 candles model 2 - fast  uturn3 and slow flat or move 
----------------------------------------------------------------------------
function SignalUturn32(index, direction, oscs, dev)
    return Signal2Uturn32(index, direction, oscs.Fasts, oscs.Slows, dev)
end

----------------------------------------------------------------------------
function Signal2Uturn32(index, direction, values1, values2, dev)
    if (CheckDataExist(index, 3, values1) and CheckDataExist(index, 3, values2)) then
        local dev = dev or Signals.MinDeviation

        return (EventUturn3(index, direction, values1, dev) and EventMove(index, direction, values2, dev) and not EventMove((index-1), Reverse(direction), values2, dev))

    -- not enough data
    else
        return false
    end
end

----------------------------------------------------------------------------
-- Signal Strength model 1 - value1 and value2 at index greater or equal then ones at index-2
----------------------------------------------------------------------------
function SignalStrength1(index, direction, values1, values2, diff, dev)
    if (CheckDataExist(index, 3, values1) and CheckDataExist(index, 3, values2))then
        local dev = dev or Signals.MinDeviation
        local diff = diff or Signals.MinDifference

        return ((CheckRelate(direction, values1[index], values1[index-2], dev) or CheckFlat(values1[index], values1[index-2], diff)) and (CheckRelate(direction, values2[index], values2[index-2], dev) or CheckFlat(values2[index], values2[index-2], diff)))
    end
end

----------------------------------------------------------------------------
-- Signal Stregth model 2 - priceclose at index greater then 2/3 range of candles at index-1 or index-2
----------------------------------------------------------------------------
function SignalStrength2(index, direction, prices, dev)
    if (CheckDataExist(index, 3, prices.Closes) and CheckDataExist(index, 3,  prices.Highs) and CheckDataExist(index, 3,  prices.Lows)) then
        local dev = dev or Signals.MinDeviation

        if (direction == Directions.Long) then
            return ((prices.Closes[index] > (prices.Lows[index-2] + 2.0 / 3.0 * (prices.Highs[index-2] - prices.Lows[index-2]) + dev)) or (prices.Closes[index] > (prices.Lows[index-1] + 2.0 / 3.0 * (prices.Highs[index-1] - prices.Lows[index-1]) + dev)))

        elseif (direction == Directions.Short) then
            return (((prices.Highs[index-2] - 2.0 / 3.0 * (prices.Highs[index-2] - prices.Lows[index-2])) > prices.Closes[index] + dev) or ((prices.Highs[index-1] - 2.0 / 3.0 * (prices.Highs[index-1] - prices.Lows[index-1])) > prices.Closes[index] + dev))
        end
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
    return (CheckRelate(direction, value2[index-1], value1[index-1], dev) and CheckRelate(direction, value1[index], value2[index], dev))
end

----------------------------------------------------------------------------
-- Event 2 last candles Value move up or down
----------------------------------------------------------------------------
function EventMove(index, direction, value, dev)
    return CheckRelate(direction, value[index], value[index-1], dev)
end

----------------------------------------------------------------------------
-- Event 3 last candles Value uturn up or down
----------------------------------------------------------------------------
function EventUturn3(index, direction, value, dev)
    return (CheckRelate(direction, value[index-2], value[index-1], dev) and CheckRelate(direction, value[index], value[index-1], dev))
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
function CheckRelate(direction, value1, value2, dev)
    if (direction == Directions.Long) then
        return (value1 > (value2 + dev))
    elseif (direction == Directions.Short) then
        return (value2 > (value1 + dev))
    end
end

----------------------------------------------------------------------------
-- Condition Is Value1 equal Value2
----------------------------------------------------------------------------
function CheckFlat(value1, value2, diff)
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
        ChartLabels.Params.TEXT = GetMessage(direction, signal.Name, Signals[signal.Name][direction][indicator.Name].Count, index)

        ChartLabels.Params.HINT = GetMessage(ChartLabels.Params.TEXT, Signals[signal.Name][direction][indicator.Name].Candle, text)

        -- set chart label return id
        return AddLabel(chart_tag, ChartLabels.Params)

    -- nothing todo
    else
        return ChartLabels[indicator.Name][index]
    end
end

----------------------------------------------------------------------------
-- function SetInitialCounts() init Signals Candles and Counts
----------------------------------------------------------------------------
function SetInitialValues(t)
    local key, value
    for key, value in pairs(t) do
        if (type(value) == "table") then
            Nesting = Nesting + 1
            SetInitialValues(value)
        else
            if (Nesting == 4) then 
                t[key] = 0
            end
        end
    end
    if (Nesting ~= 1) then 
        Nesting = Nesting - 1
    end
end

----------------------------------------------------------------------------
--
----------------------------------------------------------------------------
function PrintDebugSummary()
    local rule = "------------------------------------------------"
    local fmt = "%-9s%-4s%-6s%-6s%-4s%-4s%-6s%-6s%-4s"
    
    PrintDebugMessage(string.format("%-s", rule))
    PrintDebugMessage(string.format(fmt, "Signal", "Dir", "Price",  "Stoch", "RSI", "Dir", "Price",  "Stoch", "RSI"))
    PrintDebugMessage(string.format("%-s", rule))
    PrintDebugMessage(string.format(fmt, Signals.Cross.Name, Directions.Long, 0, Signals.Cross[Directions.Long][Stochs.Name].Count, Signals.Cross[Directions.Long][RSIs.Name].Count, Directions.Short, 0, Signals.Cross[Directions.Short][Stochs.Name].Count, Signals.Cross[Directions.Short][RSIs.Name].Count))
    PrintDebugMessage(string.format(fmt, Signals.Cross50.Name, Directions.Long, Signals.Cross50[Directions.Long][Prices.Name].Count, Signals.Cross50[Directions.Long][Stochs.Name].Count, 0, Directions.Short, Signals.Cross50[Directions.Short][Prices.Name].Count, Signals.Cross50[Directions.Short][Stochs.Name].Count, 0))
    PrintDebugMessage(string.format(fmt, Signals.Steamer.Name, Directions.Long, 0, Signals.Steamer[Directions.Long][Stochs.Name].Count, 0, Directions.Short, 0, Signals.Steamer[Directions.Short][Stochs.Name].Count, 0))
    PrintDebugMessage(string.format(fmt, Signals.TrendOff.Name, Directions.Long, 0, Signals.TrendOff[Directions.Long][Stochs.Name].Count, 0, Directions.Short, 0, Signals.TrendOff[Directions.Short][Stochs.Name].Count, 0))
    PrintDebugMessage(string.format(fmt, Signals.Uturn31.Name, Directions.Long, Signals.Uturn31[Directions.Long][Prices.Name].Count, Signals.Uturn31[Directions.Long][Stochs.Name].Count,Signals.Uturn31[Directions.Long][RSIs.Name].Count, Directions.Short, Signals.Uturn31[Directions.Short][Prices.Name].Count, Signals.Uturn31[Directions.Short][Stochs.Name].Count,Signals.Uturn31[Directions.Short][RSIs.Name].Count))
    PrintDebugMessage(string.format(fmt, Signals.Uturn32.Name, Directions.Long, Signals.Uturn32[Directions.Long][Prices.Name].Count, Signals.Uturn32[Directions.Long][Stochs.Name].Count,Signals.Uturn32[Directions.Long][RSIs.Name].Count, Directions.Short, Signals.Uturn32[Directions.Short][Prices.Name].Count, Signals.Uturn32[Directions.Short][Stochs.Name].Count,Signals.Uturn32[Directions.Short][RSIs.Name].Count))
    PrintDebugMessage(string.format("%-s", rule))
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
