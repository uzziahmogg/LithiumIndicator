--==========================================================================
--	Indicator Lithium, 2021 (c) FEK
--==========================================================================
--// convert RoundScale(..., SecInfo.scale) to RoundScale(..., values_after_point)
--// func AddLabel use Labels array
--// check price/osc events uturn3/4
--// make code for signal price/osc uturin3/4
--// make same func for text concate in PrintDebugMessage and GetChartLabelText
--// remove Params levels
--// merge IndArrays and ChartParams - chart is collection of indicators
--todo create func CheckElementarySignal
--todo make code for CheckComplexSignals
--todo move long/short checking signals to diferent branch
--todo remake all error handling to exceptions in functional programming
--todo make 3-candle cross event fucntion
--todo make candle+count itterator in separate States structure
--todo remove all chart labels keep only last 30
--todo remove all prices and inds array, kepp only last three
--todo recode SetInitValues and PrintDebugSummary to cycles over all pairs
--todo recode all SignalCross to more soft strenth condition - first leg may be equal second leg only different so moveing statrted
--todo recode SignalSteamer to osc slow move on index osc flat move on index and can be flat or contr moveing on index-1
--
--? move error checking data checking args checking from signal functions to lowest event functions
--
--! if function make something - return number maked things, or 0 if nothing todo, or nil if error
--! if function return something - if success return string or number or boolean or if error/todo nothing return nil
--! rememebr about strength critery in prciecross/osccross signals - now there have most strength criter where different sides of cross have different not equal values
--
--! events -> signals -> states -> enters
--! events/conditions is elementary signals like fast oscilator cross up slow oscilator, price cross up ma  and all there are in period 2-3 candles
--! several events and conditions consist signal like uturn, spring, cross, cross50 etc
--! functions responsible for cantching signals counting requested events and conditions
--! several signals consist states like trend, impulse etc
--! several states and signals consist enters like Leg1ZigZagSpring, Uturn50 etc
--! signals is cleat signals , all streng conditions must be in states/enters
--==========================================================================
----------------------------------------------------------------------------
--#region Settings
----------------------------------------------------------------------------
Settings = { Name = "FEK_LITHIUM", line = {{ Name = "Top", Type = TYPE_LINE, Color = RGB(221, 44, 44) }, { Name = "Centre", Type = TYPE_LINE,	Color = RGB(0, 206, 0) },  { Name = "Bottom", Type = TYPE_LINE, Color = RGB(0, 162, 232) }}}
--#endregion

----------------------------------------------------------------------------
--#region Init
----------------------------------------------------------------------------
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

    --price channel data arrays and params
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

    --[[ SignalNames = { CrossMA = "CrossMA", Cross50 = "Cross50", Cross = "Cross" } ]]

    --* convert to signals.names.directions.indicators.count/candle
    Signals = {	CrossMA = { Name = "CrossMA",
                    [Directions.Long] = { [Prices.Name] = { Count, Candle }}, [Directions.Short] = { [Prices.Name] = { Count, Candle }}},
                Cross = { Name = "Cross",
                    [Directions.Long] = { [Stochs.Name] = { Count, Candle },
                                        [RSIs.Name] = { Count, Candle }},
                    [Directions.Short] = { [Stochs.Name] = { Count, Candle },
                                        [RSIs.Name] = { Count, Candle }}},
                Cross50 = { Name = "Cross50",
                    [Directions.Long] = { [Stochs.Name] = { Count, Candle },
                                        [RSIs.Name] = { Count, Candle }}, --!
                    [Directions.Short] = { [Stochs.Name] = { Count, Candle },
                                        [RSIs.Name] = { Count, Candle }}}, --!
                Steamer = { Name = "Steamer",
                    [Directions.Long] = { [Stochs.Name] = { Count, Candle }},
                    [Directions.Short] = { [Stochs.Name] = { Count, Candle }}},
                TrendOff = { Name = "TrendOff",
                    [Directions.Long] = { [Stochs.Name] = { Count, Candle },
                                        [RSIs.Name] = { Count, Candle }},
                    [Directions.Short] = { [Stochs.Name] = { Count, Candle },
                                        [RSIs.Name] = { Count, Candle }}}, 
                MaxDuration = 2, MaxDifference = 30, MinDeviation = 0 }

    return #Settings.line
end
--#endregion

----------------------------------------------------------------------------
-- function OnCalculate
----------------------------------------------------------------------------
function OnCalculate(index)
    -- set initial values on first candle
    if (index == 1) then
        DataSource = getDataSourceInfo()
        SecInfo = getSecurityInfo(DataSource.class_code, DataSource.sec_code)

        SetInitialCounts()
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

    ----------------------------------------------------------------------------
    -- I. Price Signals
    ----------------------------------------------------------------------------
    --#region   I.1. Signal: Signals[Down/Up].CrossMA.Price
    --          Functions: SignalPriceCrossMA
    --          Signal terminates by signals: Reverse self-signal
    --          Signal terminates by duration: -
    --          State: States[Down/Up].Price.StateTrend

    -- check start signal price cross ma up
    if (SignalPriceCrossMA((index-1), Directions.Long, Prices.Closes, PCs.Centres)) then

        -- set signal
        SetSignal((index-1), Directions.Long, Prices, Signals.CrossMA)

        -- set chart label
        ChartLabels[Prices.Name][index-1] = SetChartLabel((index-1), Directions.Long, Prices, Signals.CrossMA, ChartIcons.Arrow, ChartPermissions.Event)
    end

    -- check start signal price cross ma down
    if (SignalPriceCrossMA(index-1, Directions.Short, Prices.Closes, PCs.Centres)) then

        -- set signal
        SetSignal((index-1), Directions.Short, Prices, Signals.CrossMA)

        -- set chart label
        ChartLabels[Prices.Name][index-1] = SetChartLabel((index-1), Directions.Short, Prices, Signals.CrossMA, ChartIcons.Arrow, ChartPermissions.Event)
    end 
    --#endregion

    --#region   I.2. Signal: Signals[Down/Up].Price.Uturn3
    --          Functions: SignalPriceUturn3
    --          Signal terminates by signals: -
    --          Signal terminates by duration: Signals.Params.Duration
    --          Enter: Signals[Down/Up].Price.EnterUturn3

    -- check start signal uturn3 up
    --[[ if (SignalPriceUturn3(index, Directions.Long, Prices, PCs)) then
        SetSignal((index-1), Directions.Long, Prices.Name, "Uturn3")

        -- set chart label
        ChartLabels[Prices.Name][index-1] = SetChartLabel((index-1), Directions.Long, Prices.Name, "Uturn3", ChartIcons.Arrow, ChartPermissions[1])
    end

    -- check start signal price cross ma down
    if (SignalPriceUturn3(index, Directions.Short, Prices, PCs)) then
        SetSignal((index-1), Directions.Short, Prices.Name, "Uturn3")

        -- set chart label
        ChartLabels[Prices.Name][index-1] = SetChartLabel((index-1), Directions.Short, Prices.Name, "Uturn3", ChartIcons.Arrow, ChartPermissions[1])
    end ]]
    --#endregion

    ----------------------------------------------------------------------------
    -- II. Stoch Signals
    ----------------------------------------------------------------------------
    --#region   II.1. Signal: Signals[Down/Up].Stochs.Cross
    --          Functions: SignalOscCross
    --          Terminates by signals: Reverse self-signal
    --          Terminates by duration: -
    --          State: Signals[Down/Up].Stochs.StateImpulse

    -- check fast stoch cross slow stoch up
    if (SignalOscCross((index-1), Directions.Long, Stochs)) then

        -- set signal
        SetSignal((index-1), Directions.Long, Stochs, Signals.Cross)

        -- set chart label
        ChartLabels[Stochs.Name][index-1] = SetChartLabel((index-1), Directions.Long, Stochs, Signals.Cross, ChartIcons.Romb, ChartPermissions.Signal)
    end

    -- check fast stoch cross slow stoch down
    if (SignalOscCross((index-1), Directions.Short, Stochs)) then

        -- set signal
        SetSignal((index-1), Directions.Short, Stochs, Signals.Cross)

        -- set chart label
        ChartLabels[Stochs.Name][index-1] = SetChartLabel((index-1), Directions.Short, Stochs, Signals.Cross, ChartIcons.Romb, ChartPermissions.Signal)
    end
    --#endregion

    --#region II.2. Signal: Signals[Down/Up].Stochs.Cross50
    --              Functions: SignalOscCrossLevel
    --              Terminates by signals: Reverse self-signal
    --              Terminates by duration: -
    --              State: Signals[Down/Up].Prices.StateTrend

    -- check slow stoch cross lvl50 up
    if (SignalOscCrossLevel((index-1), Directions.Long, Stochs.Slows, Stochs.HLines.Centre)) then

        -- set signal
        SetSignal((index-1), Directions.Long, Stochs, Signals.Cross50)

        -- set chart label
        ChartLabels[Stochs.Name][index-1] = SetChartLabel((index-1), Directions.Long, Stochs, Signals.Cross50, ChartIcons.Triangle, ChartPermissions.Signal)
    end

    -- check slow stoch cross lvl50 down
    if (SignalOscCrossLevel((index-1), Directions.Short, Stochs.Slows, Stochs.HLines.Centre)) then

        -- set signal
        SetSignal((index-1), Directions.Short, Stochs, Signals.Cross50)

        -- set chart label
        ChartLabels[Stochs.Name][index-1] = SetChartLabel((index-1), Directions.Short, Stochs, Signals.Cross50, ChartIcons.Triangle, ChartPermissions.Signal)
    end
    --#endregion

    
    -- debuglog
    if (index > 11600) and (index < 11700) then
        local t = T(index)
        PrintDebugMessage(index, t.month, t.day, t.hour, t.min)

        PrintDebugMessage("-s", Stochs.Slows[index-2], Stochs.Slows[index-1], Stochs.Slows[index])
        PrintDebugMessage("-f", Stochs.Fasts[index-2], Stochs.Fasts[index-1], Stochs.Fasts[index])
        PrintDebugMessage("-d", math.abs(GetDelta(Stochs.Slows[index-2], Stochs.Fasts[index-2])), math.abs(GetDelta(Stochs.Slows[index-1], Stochs.Fasts[index-1])), math.abs(GetDelta(Stochs.Slows[index], Stochs.Fasts[index])))
    end 

    --#region II.3. Elementary Stoch Signal: Signals[Down/Up].Stochs.Steamer
    --              Enter Signal: Signals[Down/Up]["TrendOn"]/Uturn
    --              Depends on signal: SignalOscVSteamer
    --              Terminates by signals: Reverse self-signal
    --              Terminates by duration: -

    -- check stoch steamer up
    if (SignalOscSteamer((index-1), Directions.Long, Stochs)) then

        -- set signal on
        SetSignal((index-1), Directions.Long, Stochs, Signals.Steamer)

        -- set chart label
        ChartLabels[Stochs.Name][index-1] = SetChartLabel((index-1), Directions.Long, Stochs, Signals.Steamer, ChartIcons.Point, ChartPermissions.Event, DealStages.Start)
    end

    -- check stoch steamer down
    if (SignalOscSteamer((index-1), Directions.Short, Stochs)) then

        -- set signal on
        SetSignal((index-1), Directions.Short, Stochs, Signals.Steamer)

        -- set chart label
        ChartLabels[Stochs.Name][index-1] = SetChartLabel((index-1), Directions.Short, Stochs, Signals.Steamer, ChartIcons.Point, ChartPermissions.Event, DealStages.Start)
    end
    --#endregion

    --#region II.3. Signal: Signals[Down/Up].Stochs.Uturn3
    --              Functions: SignalOscUturn3
    --              Terminates by signals: -
    --              Terminates by duration: Signals.Params.Duration
    --              Enter: Signals[Down/Up].Price.EnterUturn3

    -- check slow stoch uturn 3 candles up
    --[[ if (SignalOscUturn3(index, Directions.Long, Stochs, Signals.Params.Devs.Stoch)) then
        SetSignal((index-1), Directions.Long, Stochs.Name, "Uturn3")

        -- set chart label
        ChartLabels[Stochs.Name][index-1] = SetChartLabel((index-1), Directions.Long, Stochs.Name, "Uturn3", ChartIcons.Triangle, ChartPermissions[1])
    end

    -- check slow stoch uturn 3 candles down
    if (SignalOscUturn3(index, Directions.Short, Stochs, Signals.Params.Devs.Stoch)) then
        SetSignal((index-1), Directions.Short, Stochs.Name, "Uturn3")

        -- set chart label
        ChartLabels[Stochs.Name][index-1] = SetChartLabel((index-1), Directions.Short, Stochs.Name, "Uturn3", ChartIcons.Triangle, ChartPermissions[1])
    end

    -- check presence signal up
    if (Signals[Directions.Long][Stochs.Name]["Uturn3"].Candle > 0) then

        -- set duration signal up
        local duration = index - Signals[Directions.Long][Stochs.Name]["Uturn3"].Candle

        -- check continuation signal up
        if (duration <= Signals.Params.Duration) then
            -- set chart label
            ChartLabels[Stochs.Name][index] = SetChartLabel(index, Directions.Long, Stochs.Name, "Uturn3", ChartIcons.Asterix, ChartPermissions[1], GetMessage(DealStages.Continue, duration))

        -- check termination by duration signal up
        elseif (duration > Signals.Params.Duration) then
            -- set signal up off
            Signals[Directions.Long][Stochs.Name]["Uturn3"].Candle = 0

            -- set chart label
            ChartLabels[Stochs.Name][index] = SetChartLabel(index, Directions.Long, Stochs.Name, "Uturn3", ChartIcons.Cross, ChartPermissions[1], GetMessage(DealStages.End, duration))
        end
    end -- up presence

    -- check presence signal down
    if (Signals[Directions.Short][Stochs.Name]["Uturn3"].Candle > 0) then

        -- set duration signal down
        local duration = index - Signals[Directions.Short][Stochs.Name]["Uturn3"].Candle

        -- check continuation signal down
        if (duration <= Signals.Params.Duration) then
            -- set chart label
            ChartLabels[Stochs.Name][index] =  SetChartLabel(index, Directions.Short, Stochs.Name, "Uturn3", ChartIcons.Asterix, ChartPermissions[1], GetMessage(DealStages.Continue, duration))

        -- check termination by duration signal down
        elseif (duration > Signals.Params.Duration) then
            -- set signal down off
            Signals[Directions.Short][Stochs.Name]["Uturn3"].Candle = 0

            -- set chart label
            ChartLabels[Stochs.Name][index] =  SetChartLabel(index, Directions.Short, Stochs.Name, "Uturn3", ChartIcons.Cross, ChartPermissions[1], GetMessage(DealStages.End, duration))
        end
    end -- down presence ]]
    --#endregion

    ----------------------------------------------------------------------------
    -- III. RSI Signals
    ----------------------------------------------------------------------------
    --#region III.1. Signal: Signals[Down/Up].RSIs.Cross
    --               Functions: SignalOscCross
    --               Terminates by signals: Reverse self-signal
    --               Terminates by duration: -
    --               State: Signals[Down/Up].Stochs.StateImpulse

    -- check fast rsi cross slow rsi up
    if (SignalOscCross((index-1), Directions.Long, RSIs)) then

        --set signal
        SetSignal((index-1), Directions.Long, RSIs, Signals.Cross)

        -- set chart label
        ChartLabels[RSIs.Name][index-1] = SetChartLabel((index-1), Directions.Long, RSIs, Signals.Cross, ChartIcons.Romb, ChartPermissions.Event)
    end

    -- check fast rsi cross slow rsi down
    if (SignalOscCross((index-1), Directions.Short, RSIs)) then

        -- set signals
        SetSignal((index-1), Directions.Short, RSIs, Signals.Cross)

        -- set chart label
        ChartLabels[RSIs.Name][index-1] = SetChartLabel((index-1), Directions.Short, RSIs, Signals.Cross, ChartIcons.Romb, ChartPermissions.Event)
    end

    --#endregion

    --#region III.2. Signal: Signals[Down/Up].RSIs.Cross50
    --               Functions: SignalOscCrossLevel
    --               Terminates by signals: Reverse self-signal
    --               Terminates by duration: -
    --               State: States[Down/Up].Prices.StateTrend

    -- check slow rsi cross lvl50 up
    if (SignalOscCrossLevel((index-1), Directions.Long, RSIs.Slows, RSIs.HLines.Centre)) then

        --set signal
        SetSignal((index-1), Directions.Long, RSIs, Signals.Cross50)

        -- set chart label
        ChartLabels[RSIs.Name][index-1] = SetChartLabel((index-1), Directions.Long, RSIs, Signals.Cross50, ChartIcons.Triangle, ChartPermissions.Event)
    end

    -- check slow rsi cross lvl50 down
    if (SignalOscCrossLevel((index-1), Directions.Short, RSIs.Slows, RSIs.HLines.Centre)) then
        SetSignal((index-1), Directions.Short, RSIs, Signals.Cross50)

        -- set chart label
        ChartLabels[RSIs.Name][index-1] = SetChartLabel((index-1), Directions.Short, RSIs, Signals.Cross50, ChartIcons.Triangle, ChartPermissions.Event)
    end
    --#endregion

    --#region III.3. Elementary RSI Signal: Signals[Down/Up].RSIs["TrendOff"]
    --               Enter Signals: Signals[Down/Up]["TrendOff"]
    --               Depends on signal: SignalOscTrendOff
    --               Terminates by signals: Reverse self-signal, SignalOscTrendOff, SignalOscCross
    --               Terminates by duration: Signals.Params.Duration

    -- check start signal up trendon - slow rsi enter on uptrend zone
    if SignalOscTrendOff((index-1), Directions.Short, RSIs) then

        -- set signal on
        SetSignal((index-1), Directions.Short, RSIs, Signals.TrendOff)

        -- set chart label
        ChartLabels[RSIs.Name][index-1] = SetChartLabel((index-1), Directions.Short, RSIs, Signals.TrendOff, ChartIcons.Triangle, ChartPermissions.Event)
    end -- up 

    -- check start signal down trendon - slow rsi enter on down trend zone
    if SignalOscTrendOff((index-1), Directions.Long, RSIs) then

        SetSignal((index-1), Directions.Long, RSIs, Signals.TrendOff)

        -- set chart label
        ChartLabels[RSIs.Name][index-1] = SetChartLabel((index-1), Directions.Long, RSIs, Signals.TrendOff, ChartIcons.Arrow, ChartPermissions.Event)
    end -- down 
    --#endregion

    ----------------------------------------------------------------------------
    -- IV. States
    ----------------------------------------------------------------------------
    --#region IV.1. State: States[Down/Up].Trend
    ---             Depends: Price.CrossMA, Stoch.Cross50, RSI.Cross50
    --              Terminates by signals: One of reverse self-signal
    --              Terminates by duration: -

    -- check start trend up state and check signals up
    --[[ if ((Signals[Directions.Long][Prices.Name]["StateTrend"].Candle == 0) and (Signals[Directions.Long][Prices.Name]["CrossMA"].Candle > 0) and (Signals[Directions.Long][Stochs.Name]["Cross50"].Candle > 0) and (Signals[Directions.Long][RSIs.Name]["Cross50"].Candle > 0)) then

		-- set trend down signal off
        SetState((index-1), Directions.Long, "Trend")

        -- set chart label
        ChartLabels[Prices.Name][index-1] = SetChartLabel((index-1), Directions.Long, Prices.Name, "Trend", ChartIcons.BigArrow, ChartPermissions[2], DealStages.Start)
    end

    -- check start trend down state and check signals down
    if ((Signals[Directions.Short][Prices.Name]["StateTrend"].Candle == 0) and (Signals[Directions.Short][Prices.Name]["CrossMA"].Candle > 0) and (Signals[Directions.Short][Stochs.Name]["Cross50"].Candle > 0) and (Signals[Directions.Short][RSIs.Name]["Cross50"].Candle > 0)) then

        -- set trend down signal off
        SetState((index-1), Directions.Short, "Trend")

        -- set chart label
        ChartLabels[Prices.Name][index-1] = SetChartLabel((index-1), Directions.Short, Prices.Name, "Trend", ChartIcons.BigArrow, ChartPermissions[2], DealStages.Start)
    end

    -- check state trend up end
    if (Signals[Directions.Long][Prices.Name]["StateTrend"].Candle > 0) then

        local duration = index - Signals[Directions.Long][Prices.Name]["StateTrend"].Candle

        -- state trend up end by end one of up signals
        if ((Signals[Directions.Long][Prices.Name]["CrossMA"].Candle == 0) or (Signals[Directions.Long][Stochs.Name]["Cross50"].Candle == 0) or (Signals[Directions.Long][RSIs.Name]["Cross50"].Candle == 0)) then

            -- set chart label
            ChartLabels[Prices.Name][index-1] = SetChartLabel((index-1), Directions.Long, Prices.Name, "Trend", ChartIcons.BigCross, ChartPermissions[2], tostring(index-1) .. "|" .. tostring(duration) .. "|" .. DealStages.End .. " by offsignal")

            -- turn off state
            Signals[Directions.Long][Prices.Name]["StateTrend"].Candle = 0

        -- state trend up end by end of duration
        elseif (duration >= Signals.Params.Duration) then
            -- set chart label
            ChartLabels[Prices.Name][index-1] = SetChartLabel((index-1), Directions.Long, Prices.Name, "Trend", ChartIcons.BigCross, ChartPermissions[2], tostring(index-1) .. "|" .. tostring(duration) .. "|" .. DealStages.End .. " by duration")

            -- turn off state
            Signals[Directions.Long][Prices.Name]["StateTrend"].Candle = 0
        end
    end

    -- check state trend down end
    if (Signals[Directions.Short][Prices.Name]["StateTrend"].Candle > 0) then

        local duration = index - Signals[Directions.Short][Prices.Name]["StateTrend"].Candle

        -- state trend down end by end one of down signals
        if ((Signals[Directions.Short][Prices.Name]["CrossMA"].Candle == 0) or (Signals[Directions.Short][Stochs.Name]["Cross50"].Candle == 0) or (Signals[Directions.Short][RSIs.Name]["Cross50"].Candle == 0)) then

            -- set chart label
            ChartLabels[Prices.Name][index-1] = SetChartLabel((index-1), Directions.Short, Prices.Name, "Trend", ChartIcons.BigCross, ChartPermissions[2], tostring(duration) .. "|" .. DealStages.End)

            -- turn off state
            Signals[Directions.Short][Prices.Name]["StateTrend"].Candle = 0

        -- state trend down end by end of duration
        elseif (duration >= Signals.Params.Duration) then
            -- set chart label
            ChartLabels[Prices.Name][index-1] = SetChartLabel((index-1), Directions.Short, Prices.Name, "Trend", ChartIcons.BigCross, ChartPermissions[2], tostring(index-1) .. "|" .. tostring(duration) .. "|" .. DealStages.End .. "by duration")

            -- turn off state
            Signals[Directions.Short][Prices.Name]["StateTrend"].Candle = 0
        end
    end ]]
	--#endregion

    --#region IV.2. State: State[Down/Up].Impulse
    ---             Depends: Stoch.Cross, RSI.Cross
    --              Terminates by signals: One of reverse self-signal
    --              Terminates by duration: -
	--#endregion

    -- check start trend up state and check signals up
    --[[ if ((Signals[Directions.Long][Stochs.Name]["StateImpulse"].Candle == 0) and (Signals[Directions.Long][Stochs.Name]["Cross"].Candle > 0) and (Signals[Directions.Long][RSIs.Name]["Cross"].Candle > 0)) then

        -- set trend down signal off
        SetState((index-1), Directions.Long, "Impulse")

        -- set chart label
        ChartLabels[Stochs.Name][index-1] = SetChartLabel((index-1), Directions.Long, Stochs.Name, "Impulse", ChartIcons.BigArrow, ChartPermissions[3], DealStages.Start)
    end

    -- check start trend down state and check signals down
    if ((Signals[Directions.Short][Stochs.Name]["StateImpulse"].Candle == 0) and (Signals[Directions.Short][Stochs.Name]["Cross"].Candle > 0) and (Signals[Directions.Short][RSIs.Name]["Cross"].Candle > 0)) then

        -- set trend down signal off
        SetState((index-1), Directions.Short, "Impulse")

        -- set chart label
        ChartLabels[Stochs.Name][index-1] = SetChartLabel((index-1), Directions.Short, Stochs.Name, "Impulse", ChartIcons.BigArrow, ChartPermissions[3], DealStages.Start)
    end

    -- check state trend up end
    if (Signals[Directions.Long][Stochs.Name]["StateImpulse"].Candle > 0) then

        local duration = index - Signals[Directions.Long][Stochs.Name]["StateImpulse"].Candle

        -- state trend up end by end one of up signals
        if ((Signals[Directions.Long][Stochs.Name]["Cross"].Candle == 0) or (Signals[Directions.Long][RSIs.Name]["Cross"].Candle == 0)) then

            -- set chart label
            ChartLabels[Stochs.Name][index-1] = SetChartLabel((index-1), Directions.Long, Stochs.Name, "Impulse", ChartIcons.BigCross, ChartPermissions[3], tostring(index-1) .. "|" .. tostring(duration) .. "|" .. DealStages.End .. " by offsignal")

            -- turn off state
            Signals[Directions.Long][Stochs.Name]["StateImpulse"].Candle = 0

        -- state trend up end by end of duration
        elseif (duration >= Signals.Params.Duration) then
            -- set chart label
            ChartLabels[Stochs.Name][index-1] = SetChartLabel((index-1), Directions.Long, Stochs.Name, "Impulse", ChartIcons.BigCross, ChartPermissions[3], tostring(index-1) .. "|" .. tostring(duration) .. "|" .. DealStages.End .. " by duration")

            -- turn off state
            Signals[Directions.Long][Stochs.Name]["StateImpulse"].Candle = 0

        end
    end

    -- check state trend down end
    if (Signals[Directions.Short][Stochs.Name]["StateImpulse"].Candle > 0) then

        local duration = index - Signals[Directions.Short][Stochs.Name]["StateImpulse"].Candle

        -- state trend down end by end one of down signals
        if ((Signals[Directions.Short][Stochs.Name]["Cross"].Candle == 0) or (Signals[Directions.Short][RSIs.Name]["Cross"].Candle == 0)) then
            -- set chart label
            ChartLabels[Stochs.Name][index-1] = SetChartLabel((index-1), Directions.Short, Stochs.Name, "Impulse", ChartIcons.BigCross, ChartPermissions[3], tostring(duration) .. "|" .. DealStages.End .. " by offsignal")

            -- turn off state
            Signals[Directions.Short][Stochs.Name]["StateImpulse"].Candle = 0

        -- state trend down end by end of duration
        elseif (duration >= Signals.Params.Duration) then
            -- set chart label
            ChartLabels[Stochs.Name][index-1] = SetChartLabel((index-1), Directions.Short, Stochs.Name, "Impulse", ChartIcons.BigCross, ChartPermissions[3], tostring(index-1) .. "|" .. tostring(duration) .. "|" .. DealStages.End .. " by duration")

            -- turn off state
            Signals[Directions.Short][Stochs.Name]["StateImpulse"].Candle = 0
        end
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
-- Signal Osc Vertical Steamer
----------------------------------------------------------------------------
function SignalOscSteamer(index, direction, oscs, diff, dev)
    if (CheckDataExist(index, 3, oscs.Slows) and CheckDataExist(index, 3, oscs.Fasts)) then

        local dev = dev or Signals.MinDeviation
        local diff = diff or Signals.MaxDifference

        if (index > 11600) and (index < 11700) then
            PrintDebugMessage("--ms", index, direction, EventMove(index, direction, oscs.Slows, dev))
            PrintDebugMessage("--mf", EventMove(index-1, direction, oscs.Fasts, dev), EventMove(index, direction, oscs.Fasts, dev))
            PrintDebugMessage("--c",  ConditionRelate(direction, oscs.Fasts[index-1], oscs.Slows[index-1], dev), ConditionRelate(direction, oscs.Fasts[index], oscs.Slows[index], dev))
            PrintDebugMessage("--d",  ConditionEqual(oscs.Fasts[index-2], oscs.Slows[index-2], diff), ConditionEqual(oscs.Fasts[index-1], oscs.Slows[index-1], diff), ConditionEqual(oscs.Fasts[index], oscs.Slows[index], diff))
        end

        -- true or false
        return (-- oscs move in direction last 3 candles
        (EventMove(index, direction, oscs.Fasts, dev) and EventMove(index, direction, oscs.Slows, dev) and 
        EventMove(index-1, direction, oscs.Fasts, dev)) and 
        --[[ EventMove(index-1, direction, oscs.Slows, dev)) and ]]

        -- fast osc ralate slow osc in direction last 3 candles
        (ConditionRelate(direction, oscs.Fasts[index], oscs.Slows[index], dev) and 
        ConditionRelate(direction, oscs.Fasts[index-1], oscs.Slows[index-1], dev)) and 
        --[[ ConditionRelate(direction, oscs.Fasts[index-2], oscs.Slows[index-2], dev)) and ]]

        -- delta beetwen osc fast and slow osc less then dev last 3 candles
        (ConditionEqual(oscs.Fasts[index], oscs.Slows[index], diff) and ConditionEqual(oscs.Fasts[index-1], oscs.Slows[index-1], diff) and ConditionEqual(oscs.Fasts[index-2], oscs.Slows[index-2], diff))) 
    else
        return false
    end
end

----------------------------------------------------------------------------
-- Signal Osc Fast Cross Osc Slow
----------------------------------------------------------------------------
function SignalOscCross(index, direction, oscs, dev)
    if (CheckDataExist(index, 2, oscs.Slows) and CheckDataExist(index, 2, oscs.Fasts)) then

        local dev = dev or Signals.MinDeviation

        -- cross fast osc over/under slow osc
        return EventCross(index, direction, oscs.Fasts, oscs.Slows, dev)

    -- not enough data
    else
        return false
    end
end

----------------------------------------------------------------------------
-- Signal Osc Cross Level
----------------------------------------------------------------------------
function SignalOscCrossLevel(index, direction, osc, level, dev)
    if (CheckDataExist(index, 2, osc)) then

        local dev = dev or Signals.MinDeviation
        local levels = {[index-1] = level, [index] = level}

        -- osc cross level up/down
        return EventCross(index, direction, osc, levels, dev)

    -- not enough data
    else
        return false
    end
end

----------------------------------------------------------------------------
--! Signal Osc TrendOn
----------------------------------------------------------------------------
function SignalOscTrendOn(index, direction, oscs, dev)
    local level, osc

    -- check for rsi
    if (oscs.Name == RSIs.Name) then
        osc = RSIs.Slows

        if (direction == Directions.Long) then
            level = RSIs.HLines.TopTrend
        elseif (direction == Directions.Short) then
            level = RSIs.HLines.BottomTrend
        end

    -- check for stochastic
    elseif (oscs.Name == Stochs.Name) then
        osc = Stochs.Slows

        if (direction == Directions.Long) then
            level = Stochs.HLines.TopExtreme
        elseif (direction == Directions.Short) then
            level = Stochs.HLines.BottomExtreme
        end

    -- check for pc
    elseif (oscs.Name == PCs.Name) then
        if CheckDataExist(index, 2, PCs.Centres) then
            osc = Prices.Closes

            if (direction == Directions.Long) then
                level = PCs.Tops[index-1]
            elseif (direction == Directions.Short) then
                level = PCs.Bottoms[index-1]
            end

        -- not enough data
        else
            return false
        end
    end

    return SignalOscCrossLevel(index, direction, osc, level, dev)
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
function SignalOscUturn3(index, direction, oscs, dev)
    if (CheckDataExist(index, 3, oscs.Slows) and CheckDataExist(index, 3, oscs.Fasts) and CheckDataExist(index, 3, oscs.Deltas)) then

        local dev = dev or Signals.MinDeviation

        local condition =
            -- fastosc uturn
            (EventUturn(index, direction, oscs.Fasts, dev) or
            (EventFlat(index-1, oscs.Fasts, dev) and EventMove(index, direction, oscs.Fasts, dev))) and
            -- deltas uturn
            EventUturn(index, direction, oscs.Deltas, dev) and
            -- slowosc move pro-trend 3 last candles
            (EventMove(index, direction, oscs.Slows, dev) and EventMove(index-1, direction, oscs.Slows, dev)) and
            -- fastosc over slowosc all 3 candles
            (ConditionRelate(direction, oscs.Fasts[index-3], oscs.Slows[index-3], dev) and ConditionRelate(direction, oscs.Fasts[index-2], oscs.Slows[index-2], dev) and ConditionRelate(direction, oscs.Fasts[index-1], oscs.Slows[index-1], dev))

        -- strength condition
        local result = ConditionRelate(direction, oscs.Slows[index-1], oscs.Slows[index-3], dev)

        return (condition and result)

    -- not enough data
    else
        return false
    end
end

----------------------------------------------------------------------------
-- Signal Osc Uturn with 4 candles
----------------------------------------------------------------------------
function SignalOscUturn4(index, direction, oscs, dev)
    if (CheckDataExist(index, 4, oscs.Slows) and CheckDataExist(index, 4, oscs.Fasts) and CheckDataExist(index, 4, oscs.Deltas)) then

        local dev = dev or Signals.MinDeviation

        -- true or false
        return ( -- deltas uturn
            (EventMove((index-2), Directions.Short, oscs.Deltas, dev) and EventMove(index, Directions.Long, oscs.Deltas, dev)) and
            -- fastosc/slowosc uturn
            (EventMove((index-2), Reverse(direction), oscs.Fasts, dev) and EventMove(index, direction, oscs.Fasts, dev) and EventMove(index, direction, oscs.Slows, dev)) and
            -- fastosc over slowosc all 4 candles
            (ConditionRelate(direction, oscs.Fasts[index-4], oscs.Slows[index-4], dev) and ConditionRelate(direction, oscs.Fasts[index-3], oscs.Slows[index-3], dev) and ConditionRelate(direction, oscs.Fasts[index-2], oscs.Slows[index-2], dev) and ConditionRelate(direction, oscs.Fasts[index-1], oscs.Slows[index-1], dev)))

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
function SignalPriceCrossMA(index, direction, price, ma, dev)
    if (CheckDataExist(index, 2, price) and CheckDataExist(index, 2, ma)) then

        local dev = dev or Signals.MinDeviation

        -- close cross ma up/down
        return EventCross(index, direction, price, ma, dev)

    -- not enough data
    else
        return false
    end
end

----------------------------------------------------------------------------
-- Signal Price Uturn with 3 candles
----------------------------------------------------------------------------
function SignalPriceUturn3(index, direction, prices, mas, dev)
    if (CheckDataExist(index, 3, prices.Opens) and CheckDataExist(index, 3, prices.Closes) and CheckDataExist(index, 3, prices.Highs) and CheckDataExist(index, 3, prices.Lows) and CheckDataExist(index, 3, mas.Centres) and CheckDataExist(index, 3, mas.Deltas)) then

        local dev = dev or Signals.MinDeviation

        local condition =
            -- one first candle contr-trend, one last candle pro-trend
            (ConditionRelate(Reverse(direction), prices.Closes[index-3], prices.Opens[index-3], dev) or ConditionRelate(Reverse(direction), prices.Closes[index-2], prices.Opens[index-2], dev)) and ConditionRelate(direction, prices.Closes[index-1], prices.Opens[index-1], dev) and
            -- prices.Closes uturn
            EventUturn(index, direction, prices.Closes, dev) and
            -- delta uturn
            EventUturn(index, direction, mas.Deltas, dev) and
            -- ma move pro-trend 3 last candles
            (EventMove(index, direction, mas.Centres, dev) or EventFlat(index, mas.Centres, dev)) and (EventMove((index-1), direction, mas.Centres, dev) or EventFlat((index-1), mas.Centres, dev))
            -- strength condition
            -- and ConditionRelate(direction, prices.Closes[index-1], prices.Closes[index-3], dev)

        if (direction == Directions.Long) then
            return (condition and
                -- strength condition
                ((prices.Closes[index-1] > (prices.Lows[index-3] + 2.0 / 3.0 * (prices.Highs[index-3] - prices.Lows[index-3]))) or
			    (prices.Closes[index-1] > (prices.Lows[index-2] + 2.0 / 3.0 * (prices.Highs[index-2] - prices.Lows[index-2])))))

        elseif (direction == Directions.Short) then
            return (condition and
                -- strength condition
                (((prices.Highs[index-3] - 2.0 / 3.0 * (prices.Highs[index-3] - prices.Lows[index-3])) > prices.Closes[index-1]) or
			    ((prices.Highs[index-2] - 2.0 / 3.0 * (prices.Highs[index-2] - prices.Lows[index-2])) > prices.Closes[index-1])))
        end

    -- not enough data
    else
        return false
    end
end

----------------------------------------------------------------------------
-- Signal Price Uturn with 4 candles
----------------------------------------------------------------------------
function SignalPriceUturn4(index, direction, prices, mas, dev)
    if (CheckDataExist(index, 4, prices.Opens) and CheckDataExist(index, 4, prices.Closes) and CheckDataExist(index, 4, prices.Highs) and CheckDataExist(index, 4, prices.Lows) and CheckDataExist(index, 4, mas.Centres) and CheckDataExist(index, 4, mas.Deltas)) then

        local dev = dev or Signals.MinDeviation

        local pre_result =
        -- one first candle contr-trend, one last candle pro-trend
        ConditionRelate(direction, prices.Opens[index-4], prices.Closes[index-4], dev) and ConditionRelate(direction, prices.Closes[index-1], prices.Opens[index-1], dev) and
        -- price.Closes uturn
        EventMove((index-2), Reverse(direction), prices.Closes, dev) and EventMove(index, direction, prices.Closes, dev) and
        -- delta min at top uturn
        EventMove((index-2), Directions.Short, mas.Deltas, dev) and EventMove(index, Directions.Long, mas.Deltas, dev) and
        -- ma move 4 last candles up
        (EventMove(index, direction, mas.Centres, dev) or EventFlat(index, mas.Centres, dev)) and
        (EventMove((index-1), direction, mas.Centres, dev) or EventFlat((index-1), mas.Centres, dev)) and
        (EventMove((index-2), direction, mas.Centres, dev) or EventFlat((index-2), mas.Centres, dev))

    if (direction == Directions.Long) then
        return (pre_result and
            -- strength condition
            (prices.Closes[index-1] >= prices.Closes[index-2]) and (prices.Closes[index-1] >= prices.Closes[index-3]) and (prices.Closes[index-1] >= prices.Closes[index-4]))

        elseif (direction == Directions.Short) then
            return (pre_result and
            -- strength condition
            (prices.Closes[index-2] >= prices.Closes[index-1]) and (prices.Closes[index-3] >= prices.Closes[index-1]) and (prices.Closes[index-4] >= prices.Closes[index-1]))
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
function ConditionEqual(value1, value2, dev)
    return (math.abs(GetDelta(value1, value2)) <= dev)
end
--#endregion

--==========================================================================
--#region UTILITIES
--==========================================================================
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
-- function GetDelta return abs difference between values
----------------------------------------------------------------------------
function GetDelta(value1, value2)
    if ((value1 == nil) or (value2 == nil)) then
        return nil
    end

    -- return math.abs(value1 - value2)
    return (value1 - value2)

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
    Signals[signal.Name][Reverse(direction)][indicator.Name].Candle = 0

    -- set signal down/up on
    Signals[signal.Name][direction][indicator.Name].Count = Signals[signal.Name][direction][indicator.Name].Count + 1
    Signals[signal.Name][direction][indicator.Name].Candle = index
end

----------------------------------------------------------------------------
-- function SetStates
----------------------------------------------------------------------------
function SetState(index, direction, signal_name)
    local indicator_name
    if (signal_name == "StateTrend") then
        indicator_name = Prices.Name
    elseif (signal_name == "StateImpulse") then
        indicator_name = Stochs.Name
    end

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
    for count = 0, (number-1), 1 do

        -- if one of number values not exist return false
        if (value[index-count] == nil) then
            return false
        end
    end

    return true
end

----------------------------------------------------------------------------
-- function CheckChartPermission
----------------------------------------------------------------------------
function CheckChartPermission(indicator, signal_permission)

    return (((signal_permission == ChartPermissions.Event) and ((indicator.Permission & ChartPermissions.Event) > 0)) or ((signal_permission == ChartPermissions.Signal) and ((indicator.Permission & ChartPermissions.Signal) > 0)) or ((signal_permission == ChartPermissions.State) and ((indicator.Permission & ChartPermissions.State) > 0))  or ((signal_permission == ChartPermissions.Enter) and ((indicator.Permission & ChartPermissions.Enter) > 0)))
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
-- function GetChartLabelXPos
-----------------------------------------------------------------------------
function GetChartLabelXPos(t)
    return tostring(10000 * t.year + 100 * t.month + t.day), tostring(10000 * t.hour + 100 * t.min + t.sec)
end

----------------------------------------------------------------------------
-- function GetChartLabelYPos
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
-- function GetChartIcon
----------------------------------------------------------------------------
function GetChartIcon(direction, icon)
    icon = icon or ChartIcons.Triangle

    return ( ChartLabels.Params.IconPath  .. icon .. "_" .. direction .. ".jpg")
end

----------------------------------------------------------------------------
-- function SetChartLabel
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
-- function SetInitialCounts()    init Signals Candles and Counts
----------------------------------------------------------------------------
function SetInitialCounts()
    -- down signals
    Signals.CrossMA[Directions.Short][Prices.Name].Count = 0
    Signals.CrossMA[Directions.Short][Prices.Name].Candle = 0

    Signals.Cross[Directions.Short][Stochs.Name].Count = 0
    Signals.Cross[Directions.Short][Stochs.Name].Candle = 0
    Signals.Cross50[Directions.Short][Stochs.Name].Count = 0
    Signals.Cross50[Directions.Short][Stochs.Name].Candle = 0
    Signals.Steamer[Directions.Short][Stochs.Name].Count = 0
    Signals.Steamer[Directions.Short][Stochs.Name].Candle = 0
    Signals.TrendOff[Directions.Short][Stochs.Name].Count = 0
    Signals.TrendOff[Directions.Short][Stochs.Name].Candle = 0

    Signals.Cross[Directions.Short][RSIs.Name].Count = 0
    Signals.Cross[Directions.Short][RSIs.Name].Candle = 0
    Signals.Cross50[Directions.Short][RSIs.Name].Count = 0
    Signals.Cross50[Directions.Short][RSIs.Name].Candle = 0
    Signals.TrendOff[Directions.Short][RSIs.Name].Count = 0
    Signals.TrendOff[Directions.Short][RSIs.Name].Candle = 0

    -- up signals
    Signals.CrossMA[Directions.Long][Prices.Name].Count = 0
    Signals.CrossMA[Directions.Long][Prices.Name].Candle = 0

    Signals.Cross[Directions.Long][Stochs.Name].Count = 0
    Signals.Cross[Directions.Long][Stochs.Name].Candle = 0
    Signals.Cross50[Directions.Long][Stochs.Name].Count = 0
    Signals.Cross50[Directions.Long][Stochs.Name].Candle = 0
    Signals.Steamer[Directions.Long][Stochs.Name].Count = 0
    Signals.Steamer[Directions.Long][Stochs.Name].Candle = 0
    Signals.TrendOff[Directions.Long][Stochs.Name].Count = 0
    Signals.TrendOff[Directions.Long][Stochs.Name].Candle = 0

    Signals.Cross[Directions.Long][RSIs.Name].Count = 0
    Signals.Cross[Directions.Long][RSIs.Name].Candle = 0
    Signals.Cross50[Directions.Long][RSIs.Name].Count = 0
    Signals.Cross50[Directions.Long][RSIs.Name].Candle = 0
    Signals.TrendOff[Directions.Long][RSIs.Name].Count = 0
    Signals.TrendOff[Directions.Long][RSIs.Name].Candle = 0
end

----------------------------------------------------------------------------
--
----------------------------------------------------------------------------
function PrintDebugSummary(index, number)
--[[     if (index == number) then
        local t = T(index)
        PrintDebugMessage("Summary", index, t.month, t.day, t.hour, t.min)

        PrintDebugMessage("StatesUp", "Trend", Signals[Directions.Long][Prices.Name]["StateTrend"].Count, "Impulse", Signals[Directions.Long][Stochs.Name]["StateImpulse"].Count)
        PrintDebugMessage("PricesUp", "CrossMA", Signals[Directions.Long][Prices.Name]["CrossMA"].Count)
        PrintDebugMessage("StochsUp", "Cross", Signals[Directions.Long][Stochs.Name]["Cross"].Count, "Cross50", Signals[Directions.Long][Stochs.Name]["Cross50"].Count)
        PrintDebugMessage("RSIsUp", "Cross", Signals[Directions.Long][RSIs.Name]["Cross"].Count, "Cross50", Signals[Directions.Long][RSIs.Name]["Cross50"].Count)

        PrintDebugMessage("StatesDown", "Trend", Signals[Directions.Short][Prices.Name]["StateTrend"].Count, "Impulse", Signals[Directions.Long][Stochs.Name]["StateImpulse"].Count)
        PrintDebugMessage("PricesDown", "CrossMA", Signals[Directions.Short][Prices.Name]["CrossMA"].Count)
        PrintDebugMessage("StochsDown", "Cross", Signals[Directions.Short][Stochs.Name]["Cross"].Count, "Cross50", Signals[Directions.Short][Stochs.Name]["Cross50"].Count)
        PrintDebugMessage("RSIsDown", "Cross", Signals[Directions.Short][RSIs.Name]["Cross"].Count, "Cross50", Signals[Directions.Short][RSIs.Name]["Cross50"].Count)
    end ]]
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
