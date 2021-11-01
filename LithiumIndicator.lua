--==========================================================================
--	Indicator Lithium, 2021 (c) FEK
--==========================================================================
--// convert RoundScale(..., SecInfo.scale) to RoundScale(..., values_after_point)
--// func AddLabel use Labels array
--// check price/osc events uturn3/4
--// make code for signal price/osc uturin3/4
--// make same func for text concate in PrintDebugMessage and GetChartLabelText
--todo create func CheckElementarySignal
--todo make code for CheckComplexSignals
--todo move long/short checking signals to diferent branch
--todo remake all error handling to exceptions in functional programming
--todo make 3-candle cross event fucntion
--todo make candle+count itterator in separate States structure

-- if function make something - return number maked things, or 0 if nothing todo, or -1 if error
-- if function return string or number or boolean - return string or number or boolean if success or return nil if error. todo nothing return nil

----------------------------------------------------------------------------
--#region Settings
----------------------------------------------------------------------------
Settings = { Name = "FEK_LITHIUM",
    -- lines on main chart
    line = {{ Name = "PCTop", Type = TYPE_LINE, Color = RGB(221, 44, 44) }, { Name = "PCentre", Type = TYPE_LINE,	Color = RGB(0, 206, 0) },  { Name = "PCBottom", Type = TYPE_LINE, Color = RGB(0, 162, 232) }}}
--#endregion

--==========================================================================
--#region Init
--==========================================================================
function Init()
    -- indicators data arrays and params
    Prices = { Name = "Price", Opens = {}, Closes = {}, Highs = {}, Lows = {}}
    Stochs = { Name = "Stoch", Fasts = {}, Slows = {}, Deltas = {}, Params = { HLines = { TopExtreme = 80, Centre = 50, BottomExtreme = 20 }, Slow = { PeriodK = 10, Shift = 3, PeriodD = 1 }, Fast = { PeriodK = 5, Shift = 2, PeriodD = 1 }}}
    RSIs = { Name = "RSI", Fasts = {}, Slows = {}, Deltas = {}, Params = { HLines = { TopExtreme = 80, TopTrend = 60, Centre = 50, BottomTrend = 40, BottomExtreme = 20 }, Slow = 14, Fast = 9 }}
    PCs = { Name = "PC", Tops = {}, Bottoms = {}, Centres = {}, Deltas = {}, Params = { Period = 20 }}

    -- directions for signals, labels and deals
    Directions = { Up = "up", Down = "down" }

    -- grades to show labels on charts
    ChartPermissions = { 1, 2, 4, 8 }

    -- tags for charts to show labels and steps for text labels on charts, permission for what label show on chart
    ChartParams = { [Prices.Name] = { Tag = GetChartTag(Prices.Name), Step = 5, Permission = ChartPermissions[1] + ChartPermissions[2] }, -- FEK_LITHIUMPrice
        [Stochs.Name] = { Tag = GetChartTag(Stochs.Name), Step = 10, Permission = ChartPermissions[1] + ChartPermissions[4]}, -- FEK_LITHIUMStoch
        [RSIs.Name] = { Tag = GetChartTag(RSIs.Name), Step = 5, Permission = ChartPermissions[1] + ChartPermissions[4]}} -- FEK_LITHIUMRSI

    -- chart labels ids and default params
    ChartLabels = { [Prices.Name] = {}, [Stochs.Name] = {}, [RSIs.Name] = {},
        Params = { TRANSPARENCY = 0, TRANSPARENT_BACKGROUND = 1, FONT_FACE_NAME = "Arial", FONT_HEIGHT = 8 }}

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

    DealStages = { Start = "Start", Continue = "Continue", End = "End" }

    -- indicator functions
    StochSlow = Stoch("Slow")
    StochFast = Stoch("Fast")
    RSISlow = RSI("Slow")
    RSIFast = RSI("Fast")
    PC = PriceChannel()

    -- events - signals - states - enters
    -- functions responsible for events events/conditions
    -- several events and conditions consist signal like uturn, spring, cross, cross50 etc
    -- several signals consist states like trend, impulse etc
    -- several states consist enters like Leg1ZigZagSpring, Uturn50 etc
    --[[ SignalNames = { CrossMA = "CrossMA", Cross50 = "Cross50", Cross = "Cross" } ]]

    Signals = {	[Directions.Up] = { 
        [Prices.Name] = { CrossMA = { Count = 0, Candle = 0 }, Uturn3 = { Count = 0, Candle = 0 }, Uturn4 = { Count = 0, Candle = 0 }, StateTrend = { Count = 0, Candle = 0 }, EnterUturn3 = { Count = 0, Candle = 0 }},
        [Stochs.Name] = { Cross = { Count = 0, Candle = 0 }, Cross50 = { Count = 0, Candle = 0 }, HSteamer = { Count = 0, Candle = 0 }, VSteamer = { Count = 0, Candle = 0 }, TrendOn = { Count = 0, Candle = 0 }, TrendOff = { Count = 0, Candle = 0 }, Uturn3 = { Count = 0, Candle = 0 }, Uturn4 = { Count = 0, Candle = 0 }, Spring3 = { Count = 0, Candle = 0 }, Spring4 = { Count = 0, Candle = 0 }, StateImpulse = { Count = 0, Candle = 0 }},
        [RSIs.Name] = { Cross = { Count = 0, Candle = 0 }, Cross50 = { Count = 0, Candle = 0 }, TrendOn = { Count = 0, Candle = 0 }, TrendOff = { Count = 0, Candle = 0 }, Uturn3 = { Count = 0, Candle = 0 }, Uturn4 = { Count = 0, Candle = 0 }, Spring3 = { Count = 0, Candle = 0 }, Spring4 = { Count = 0, Candle = 0 }}},
        [Directions.Down] = { 
        [Prices.Name] = { CrossMA = { Count = 0, Candle = 0 }, Uturn3 = { Count = 0, Candle = 0 }, Uturn4 = { Count = 0, Candle = 0 }, StateTrend = { Count = 0, Candle = 0 },EnterUturn3 = { Count = 0, Candle = 0 }},
        [Stochs.Name] = { Cross = { Count = 0, Candle = 0 }, Cross50 = { Count = 0, Candle = 0 }, HSteamer = { Count = 0, Candle = 0 }, VSteamer = { Count = 0, Candle = 0 }, TrendOn = { Count = 0, Candle = 0 }, TrendOff = { Count = 0, Candle = 0 }, Uturn3 = { Count = 0, Candle = 0 }, Uturn4 = { Count = 0, Candle = 0 }, Spring3 = { Count = 0, Candle = 0 }, Spring4 = { Count = 0, Candle = 0 }, StateImpulse = { Count = 0, Candle = 0 }},
        [RSIs.Name] = { Cross = { Count = 0, Candle = 0 }, Cross50 = { Count = 0, Candle = 0 }, TrendOn = { Count = 0, Candle = 0 }, TrendOff = { Count = 0, Candle = 0 }, Uturn3 = { Count = 0, Candle = 0 }, Uturn4 = { Count = 0, Candle = 0 }, Spring3 = { Count = 0, Candle = 0 }, Spring4 = { Count = 0, Candle = 0 }}}, 
        Params = { Duration = 2, Steamers = { VerticalDifference = 30, HorizontalDuration = 2 }, Devs = { Stoch = 0, RSI = 0 }}}

        CentreLines = {}

        PriceTypes = { Median = 1, Typical = 2, Weighted = 3, AvarageCloses = 4 }

    return #Settings.line
end
--#endregion

--==========================================================================
-- OnCalculate
--==========================================================================
function OnCalculate(index_candle)
    -- debuglog
    --[[ if (index_candle > 7200) then
        local t = T(index_candle)
        PrintDebugMessage("OnCalc", index_candle, t.month, t.day, t.hour, t.min)
    end ]]

    -- set initial values on first candle
    if (index_candle == 1) then
        DataSource = getDataSourceInfo()
        SecInfo = getSecurityInfo(DataSource.class_code, DataSource.sec_code)

        SetInitialCounts()
    end

    --#region set prices and indicators for current candle
    -- calculate current prices
    Prices.Opens[index_candle] = O(index_candle)
    Prices.Closes[index_candle] = C(index_candle)
    Prices.Highs[index_candle] = H(index_candle)
    Prices.Lows[index_candle] = L(index_candle)

    -- calculate current stoch
    Stochs.Slows[index_candle], _ = StochSlow(index_candle)
    Stochs.Fasts[index_candle], _ = StochFast(index_candle)

    Stochs.Slows[index_candle] = RoundScale(Stochs.Slows[index_candle], SecInfo.scale)
    Stochs.Fasts[index_candle] = RoundScale(Stochs.Fasts[index_candle], SecInfo.scale)

    Stochs.Deltas[index_candle] = (Stochs.Slows[index_candle] ~= nil) and (Stochs.Fasts[index_candle] ~= nil) and RoundScale(GetDelta(Stochs.Fasts[index_candle], Stochs.Slows[index_candle]), SecInfo.scale) or nil

    -- calculate current rsi
    RSIs.Fasts[index_candle] = RSIFast(index_candle)
    RSIs.Slows[index_candle] = RSISlow(index_candle)

    RSIs.Fasts[index_candle] = RoundScale(RSIs.Fasts[index_candle], SecInfo.scale)
    RSIs.Slows[index_candle] = RoundScale(RSIs.Slows[index_candle], SecInfo.scale)

    RSIs.Deltas[index_candle] = (RSIs.Fasts[index_candle] ~= nil) and (RSIs.Slows[index_candle] ~= nil) and RoundScale(GetDelta(RSIs.Fasts[index_candle], RSIs.Slows[index_candle]), SecInfo.scale) or nil

    -- calculate current price channel
    PCs.Tops[index_candle], PCs.Bottoms[index_candle] = PC(index_candle)

    PCs.Tops[index_candle] = RoundScale(PCs.Tops[index_candle], SecInfo.scale)
    PCs.Bottoms[index_candle] = RoundScale(PCs.Bottoms[index_candle], SecInfo.scale)

    --[[ PCs.Centres[index_candle] = (PCs.Tops[index_candle] ~= nil) and (PCs.Bottoms[index_candle] ~= nil) and RoundScale((PCs.Bottoms[index_candle] + (PCs.Tops[index_candle] - PCs.Bottoms[index_candle]) / 2), SecInfo.scale) or nil

    PCs.Deltas[index_candle] = (Prices.Closes[index_candle] ~= nil) and (PCs.Centres[index_candle] ~= nil) and RoundScale(GetDelta(Prices.Closes[index_candle], PCs.Centres[index_candle]), SecInfo.scale) or nil ]]
    --#endregion
    
    ----------------------------------------------------------------------------
    -- I. Price Signals
    ----------------------------------------------------------------------------
    --#region   I.1. Signal: Signals[Down/Up].Price.CrossMA
    --          Functions: SignalPriceCrossMA
    --          Signal terminates by signals: Reverse self-signal
    --          Signal terminates by duration: -
    --          State: States[Down/Up].Price.StateTrend

    -- check start signal price cross ma up
    --[[ if (SignalPriceCrossMA(index_candle, Directions.Up, Prices, PCs.Centres)) then
        SetSignal((index_candle-1), Directions.Up, Prices.Name, "CrossMA")

        -- set chart label
        ChartLabels[Prices.Name][index_candle-1] = SetChartLabel((index_candle-1), Directions.Up, Prices.Name, "CrossMA", ChartIcons.Triangle, ChartPermissions[1])
    end

    -- check start signal price cross ma down
    if (SignalPriceCrossMA(index_candle, Directions.Down, Prices, PCs.Centres)) then
        SetSignal((index_candle-1), Directions.Down, Prices.Name, "CrossMA")

        -- set chart label
        ChartLabels[Prices.Name][index_candle-1] = SetChartLabel((index_candle-1), Directions.Down, Prices.Name, "CrossMA", ChartIcons.Triangle, ChartPermissions[1])
    end ]] 
    --#endregion

    --#region   I.2. Signal: Signals[Down/Up].Price.Uturn3
    --          Functions: SignalPriceUturn3
    --          Signal terminates by signals: -
    --          Signal terminates by duration: Signals.Params.Duration
    --          Enter: Signals[Down/Up].Price.EnterUturn3

    -- check start signal uturn3 up
    --[[ if (SignalPriceUturn3(index_candle, Directions.Up, Prices, PCs)) then
        SetSignal((index_candle-1), Directions.Up, Prices.Name, "Uturn3")

        -- set chart label
        ChartLabels[Prices.Name][index_candle-1] = SetChartLabel((index_candle-1), Directions.Up, Prices.Name, "Uturn3", ChartIcons.Arrow, ChartPermissions[1])
    end

    -- check start signal price cross ma down
    if (SignalPriceUturn3(index_candle, Directions.Down, Prices, PCs)) then
        SetSignal((index_candle-1), Directions.Down, Prices.Name, "Uturn3")

        -- set chart label
        ChartLabels[Prices.Name][index_candle-1] = SetChartLabel((index_candle-1), Directions.Down, Prices.Name, "Uturn3", ChartIcons.Arrow, ChartPermissions[1])
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
    --[[ if (SignalOscCross(index_candle, Directions.Up, Stochs, Signals.Params.Devs.Stoch)) then
        SetSignal((index_candle-1), Directions.Up, Stochs.Name, "Cross")

        -- set chart label
        ChartLabels[Stochs.Name][index_candle-1] = SetChartLabel((index_candle-1), Directions.Up, Stochs.Name, "Cross", ChartIcons.Romb, ChartPermissions[3])
    end

    -- check fast stoch cross slow stoch down
    if (SignalOscCross(index_candle, Directions.Down, Stochs, Signals.Params.Devs.Stoch)) then
        SetSignal((index_candle-1), Directions.Down, Stochs.Name, "Cross")

        -- set chart label
        ChartLabels[Stochs.Name][index_candle-1] = SetChartLabel((index_candle-1), Directions.Down, Stochs.Name, "Cross", ChartIcons.Romb, ChartPermissions[3])
    end ]]
    --#endregion

    --#region II.2. Signal: Signals[Down/Up].Stochs.Cross50
    --              Functions: SignalOscCrossLevel
    --              Terminates by signals: Reverse self-signal
    --              Terminates by duration: -
    --              State: Signals[Down/Up].Prices.StateTrend

    -- check slow stoch cross lvl50 up
    --[[ if (SignalOscCrossLevel(index_candle, Directions.Up, Stochs, Stochs.Params.HLines.Centre)) then
        SetSignal((index_candle-1), Directions.Up, Stochs.Name, "Cross50")

        -- set chart label
        ChartLabels[Stochs.Name][index_candle-1] = SetChartLabel((index_candle-1), Directions.Up, Stochs.Name, "Cross50", ChartIcons.Triangle, ChartPermissions[1])
    end

    -- check slow stoch cross lvl50 down
    if (SignalOscCrossLevel(index_candle, Directions.Down, Stochs, Stochs.Params.HLines.Centre)) then
        SetSignal((index_candle-1), Directions.Down, Stochs.Name, "Cross50")

        -- set chart label
        ChartLabels[Stochs.Name][index_candle-1] = SetChartLabel((index_candle-1), Directions.Down, Stochs.Name, "Cross50", ChartIcons.Triangle, ChartPermissions[1])
    end ]]
    --#endregion

    --#region II.3. Elementary Stoch Signal: Signals[Down/Up].Stochs.VSteamer
    --              Enter Signal: Signals[Down/Up]["TrendOn"]/Uturn
    --              Depends on signal: SignalOscVSteamer
    --              Terminates by signals: Reverse self-signal
    --              Terminates by duration: -
--[[
    -- check stoch vsteamer up
    if (SignalOscVSteamer(index_candle, Directions.Up, Stochs)) then
        SetSignal((index_candle-1), Directions.Up, Stochs.Name, "VSteamer")

        -- set chart label
        ChartLabels[Stochs.Name][index_candle-1] = SetChartLabel((index_candle-1), Directions.Up, Stochs.Name, "VSteamer", ChartIcons.Point, ChartPermissions[1], DealStages.Start)
    end

    -- check stoch vsteamer down
    if (SignalOscVSteamer(index_candle, Directions.Down, Stochs)) then
        SetSignal((index_candle-1), Directions.Down, Stochs.Name, "VSteamer")

        -- set chart label
        ChartLabels[Stochs.Name][index_candle-1] = SetChartLabel((index_candle-1), Directions.Down, Stochs.Name, "VSteamer", ChartIcons.Point, ChartPermissions[1], DealStages.Start)
    end

    --#region II.4. Elementary Stoch Signal: Signals[Down/Up].Stochs.HSteamer
    --              Enter Signal: Signals[Down/Up]["TrendOn"]/Uturn
    --              Depends on signal: SignalOscHSteamer
    --              Terminates by signals: Reverse self-signal
    --              Terminates by duration: -

    -- check stoch hsteamer up
    if (SignalOscHSteamer(index_candle, Directions.Up, Stochs)) then
        SetSignal((index_candle-1), Directions.Up, Stochs.Name, "HSteamer")

        -- set chart label
        ChartLabels[Stochs.Name][index_candle-1] = SetChartLabel((index_candle-1), Directions.Up, Stochs.Name, "HSteamer", ChartIcons.Plus, ChartPermissions[1], DealStages.Start)
    end

    -- check stoch hsteamer down
    if (SignalOscHSteamer(index_candle, Directions.Down, Stochs)) then
        SetSignal((index_candle-1), Directions.Down, Stochs.Name, "HSteamer")

        -- set chart label
        ChartLabels[Stochs.Name][index_candle-1] = SetChartLabel((index_candle-1), Directions.Down, Stochs.Name, "HSteamer", ChartIcons.Plus, ChartPermissions[1], DealStages.Start)
    end
    --#endregion
]]
    ----------------------------------------------------------------------------
    -- III. RSI Signals
    ----------------------------------------------------------------------------
    --#region III.1. Signal: Signals[Down/Up].RSIs.Cross
    --               Functions: SignalOscCross
    --               Terminates by signals: Reverse self-signal
    --               Terminates by duration: -
    --               State: Signals[Down/Up].Stochs.StateImpulse

    -- check fast rsi cross slow rsi up
    if (SignalOscCross(index_candle, Directions.Up, RSIs, Signals.Params.Devs.
    RSI)) then
        SetSignal((index_candle-1), Directions.Up, RSIs.Name, "Cross")

        -- set chart label
        ChartLabels[RSIs.Name][index_candle-1] = SetChartLabel((index_candle-1), Directions.Up, RSIs.Name, "Cross", ChartIcons.Romb, ChartPermissions[3])

        CentreLines[index_candle-1] = GetCentreLine(index_candle, Directions.Up, PriceTypes.Median, Prices)
    end

    -- check fast rsi cross slow rsi down
    if (SignalOscCross(index_candle, Directions.Down, RSIs, Signals.Params.Devs.
    RSI)) then
        SetSignal((index_candle-1), Directions.Down, RSIs.Name, "Cross")

        -- set chart label
        ChartLabels[RSIs.Name][index_candle-1] = SetChartLabel((index_candle-1), Directions.Down, RSIs.Name, "Cross", ChartIcons.Romb, ChartPermissions[3])

        CentreLines[index_candle-1] = GetCentreLine(index_candle, Directions.Down, PriceTypes.Median, Prices)
    end
    --#endregion

    --#region III.2. Signal: Signals[Down/Up].RSIs.Cross50
    --               Functions: SignalOscCrossLevel
    --               Terminates by signals: Reverse self-signal
    --               Terminates by duration: -
    --               State: States[Down/Up].Prices.StateTrend

    -- check slow rsi cross lvl50 up
    --[[ if (SignalOscCrossLevel(index_candle, Directions.Up, RSIs, RSIs.Params.HLines.Centre)) then
        SetSignal((index_candle-1), Directions.Up, RSIs.Name, "Cross50")

        -- set chart label
        ChartLabels[RSIs.Name][index_candle-1] = SetChartLabel((index_candle-1), Directions.Up, RSIs.Name, "Cross50", ChartIcons.Triangle, ChartPermissions[1])
    end

    -- check slow rsi cross lvl50 down
    if (SignalOscCrossLevel(index_candle, Directions.Down, RSIs, RSIs.Params.HLines.Centre)) then
        SetSignal((index_candle-1), Directions.Down, RSIs.Name, "Cross50")

        -- set chart label
        ChartLabels[RSIs.Name][index_candle-1] = SetChartLabel((index_candle-1), Directions.Down, RSIs.Name, "Cross50", ChartIcons.Triangle, ChartPermissions[1])
    end ]]
    --#endregion

    --#region III.3. Elementary RSI Signal: Signals[Down/Up].RSIs["TrendOn"]
    --               Enter Signals: Signals[Down/Up]["TrendOn"]
    --               Depends on signal: SignalOscTrendOn
    --               Terminates by signals: Reverse self-signal, SignalOscTrendOff, SignalOscCross
    --               Terminates by duration: Signals.Params.Durations.Elementary
    -- check start signal up trendon - slow rsi enter on uptrend zone
    --[[
    if (SignalOscTrendOn(index_candle, Directions.Up, RSIs)) then
        SetSignal((index_candle-1), Directions.Up, RSIs.Name, "TrendOn")

        -- set chart label
        ChartLabels[RSIs.Name][index_candle-1] = SetChartLabel((index_candle-1), Directions.Up, RSIs.Name, "TrendOn", ChartIcons.Asterix, ChartPermissions[1], DealStages.Start)
    end -- up start

    -- check presence signal up
    if (Signals[Directions.Up][RSIs.Name]["TrendOn"].Candle > 0) then

        -- set duration signal up
        local duration = index_candle - Signals[Directions.Up][RSIs.Name]["TrendOn"].Candle

        -- check continuation signal up
        if (duration <= Signals.Params.Durations.Elementary) then

            -- check termination by slow rsi left off uptrend zone
            if (SignalOscTrendOff(index_candle, Directions.Down, RSIs)) then
                -- set signal up off
                Signals[Directions.Up][RSIs.Name]["TrendOn"].Candle = 0

                -- set chart label
                ChartLabels[RSIs.Name][index_candle-1] = SetChartLabel((index_candle-1), Directions.Up, RSIs.Name, "TrendOn", ChartIcons.Cross, ChartPermissions[1], GetMessage(DealStages.End,  "TrendOffDown", duration))

            -- check termination by fast rsi cross slow rsi down
            elseif (SignalOscCross(index_candle, Directions.Down, RSIs)) then
                -- set signal up off
                Signals[Directions.Up][RSIs.Name]["TrendOn"].Candle = 0

                -- set chart label
                ChartLabels[RSIs.Name][index_candle-1] = SetChartLabel((index_candle-1), Directions.Up, RSIs.Name, "TrendOn", ChartIcons.Cross, ChartPermissions[1], GetMessage(DealStages.End, "CrossDown", duration))

            -- process continuation signal up
            else
                -- set chart label
                ChartLabels[RSIs.Name][index_candle] = SetChartLabel(index_candle, Directions.Up, RSIs.Name, "TrendOn", ChartIcons.Asterix, ChartPermissions[1], GetMessage(DealStages.Continue, duration))
            end

        -- check termination by duration signal up
        elseif (duration > Signals.Params.Duration) then
            -- set signal up off
            Signals[Directions.Up][RSIs.Name]["TrendOn"].Candle = 0

            -- set chart label
            ChartLabels[RSIs.Name][index_candle] = SetChartLabel(index_candle, Directions.Up, RSIs.Name, "TrendOn", ChartIcons.Cross, ChartPermissions[1], GetMessage(DealStages.End, "Duration", duration))
        end
    end -- up presence

    -- check start signal down trendon - slow rsi enter on down trend zone
    if (SignalOscTrendOn(index_candle, Directions.Down, RSIs)) then
        SetSignal((index_candle-1), Directions.Down, RSIs.Name, "TrendOn")

        -- set chart label
        ChartLabels[RSIs.Name][index_candle-1] = SetChartLabel((index_candle-1), Directions.Down, RSIs.Name, "TrendOn", ChartIcons.Asterix, ChartPermissions[1], DealStages.Start)
    end -- down start

    -- check presence signal down
    if (Signals[Directions.Down][RSIs.Name]["TrendOn"].Candle > 0) then
        -- set duration signal down
        local duration = index_candle - Signals[Directions.Down][RSIs.Name]["TrendOn"].Candle

        -- check continuation signal down
        if (duration <= Signals.Params.Durations.Elementary) then

            -- check termination by slow rsi left off downtrend zone
            if (SignalOscTrendOff(index_candle, Directions.Up, RSIs)) then
                -- set signal down off
                Signals[Directions.Down][RSIs.Name]["TrendOn"].Candle = 0

                -- set chart label
                ChartLabels[RSIs.Name][index_candle-1] = SetChartLabel((index_candle-1), Directions.Down, RSIs.Name, "TrendOn", ChartIcons.Cross, ChartPermissions[1], GetMessage(DealStages.End,  "TrendOffUp", duration))

                -- check termination by fast rsi cross slow rsi up
            elseif (SignalOscCross(index_candle, Directions.Up, RSIs)) then
                -- set signal down off
                Signals[Directions.Down][RSIs.Name]["TrendOn"].Candle = 0

                -- set chart label
                ChartLabels[RSIs.Name][index_candle-1] = SetChartLabel((index_candle-1), Directions.Down, RSIs.Name, "TrendOn", ChartIcons.Cross, ChartPermissions[1], GetMessage(DealStages.End, "CrossUp", duration))

            -- process continuation signal down
            else
                -- set chart label
                ChartLabels[RSIs.Name][index_candle] =  SetChartLabel(index_candle, Directions.Down, RSIs.Name, "TrendOn", ChartIcons.Asterix, ChartPermissions[1], GetMessage(DealStages.Continue, duration))
            end

        -- check termination by duration signal down
        elseif (duration > Signals.Params.Duration) then
            -- set signal down off
            Signals[Directions.Down][RSIs.Name]["TrendOn"].Candle = 0

            -- set chart label
            ChartLabels[RSIs.Name][index_candle] =  SetChartLabel(index_candle, Directions.Down, RSIs.Name, "TrendOn", ChartIcons.Cross, ChartPermissions[1], GetMessage(DealStages.End, "Duration", duration))
        end
    end -- down presence
    --#endregion
]]

    ----------------------------------------------------------------------------
    -- IV. States
    ----------------------------------------------------------------------------
    --#region IV.1. State: States[Down/Up].Trend
    ---             Depends: Price.CrossMA, Stoch.Cross50, RSI.Cross50
    --              Terminates by signals: One of reverse self-signal
    --              Terminates by duration: -

    -- check start trend up state and check signals up
    --[[ if ((Signals[Directions.Up][Prices.Name]["StateTrend"].Candle == 0) and (Signals[Directions.Up][Prices.Name]["CrossMA"].Candle > 0) and (Signals[Directions.Up][Stochs.Name]["Cross50"].Candle > 0) and (Signals[Directions.Up][RSIs.Name]["Cross50"].Candle > 0)) then

		-- set trend down signal off
        SetState((index_candle-1), Directions.Up, "Trend")

        -- set chart label
        ChartLabels[Prices.Name][index_candle-1] = SetChartLabel((index_candle-1), Directions.Up, Prices.Name, "Trend", ChartIcons.BigArrow, ChartPermissions[2], DealStages.Start)
    end

    -- check start trend down state and check signals down
    if ((Signals[Directions.Down][Prices.Name]["StateTrend"].Candle == 0) and (Signals[Directions.Down][Prices.Name]["CrossMA"].Candle > 0) and (Signals[Directions.Down][Stochs.Name]["Cross50"].Candle > 0) and (Signals[Directions.Down][RSIs.Name]["Cross50"].Candle > 0)) then

        -- set trend down signal off
        SetState((index_candle-1), Directions.Down, "Trend")

        -- set chart label
        ChartLabels[Prices.Name][index_candle-1] = SetChartLabel((index_candle-1), Directions.Down, Prices.Name, "Trend", ChartIcons.BigArrow, ChartPermissions[2], DealStages.Start)
    end

    -- check state trend up end
    if (Signals[Directions.Up][Prices.Name]["StateTrend"].Candle > 0) then

        local duration = index_candle - Signals[Directions.Up][Prices.Name]["StateTrend"].Candle

        -- state trend up end by end one of up signals
        if ((Signals[Directions.Up][Prices.Name]["CrossMA"].Candle == 0) or (Signals[Directions.Up][Stochs.Name]["Cross50"].Candle == 0) or (Signals[Directions.Up][RSIs.Name]["Cross50"].Candle == 0)) then

            -- set chart label
            ChartLabels[Prices.Name][index_candle-1] = SetChartLabel((index_candle-1), Directions.Up, Prices.Name, "Trend", ChartIcons.BigCross, ChartPermissions[2], tostring(index_candle-1) .. "|" .. tostring(duration) .. "|" .. DealStages.End .. " by offsignal")

            -- turn off state
            Signals[Directions.Up][Prices.Name]["StateTrend"].Candle = 0

        -- state trend up end by end of duration
        elseif (duration >= Signals.Params.Duration) then
            -- set chart label
            ChartLabels[Prices.Name][index_candle-1] = SetChartLabel((index_candle-1), Directions.Up, Prices.Name, "Trend", ChartIcons.BigCross, ChartPermissions[2], tostring(index_candle-1) .. "|" .. tostring(duration) .. "|" .. DealStages.End .. " by duration")

            -- turn off state
            Signals[Directions.Up][Prices.Name]["StateTrend"].Candle = 0
        end
    end

    -- check state trend down end
    if (Signals[Directions.Down][Prices.Name]["StateTrend"].Candle > 0) then

        local duration = index_candle - Signals[Directions.Down][Prices.Name]["StateTrend"].Candle

        -- state trend down end by end one of down signals
        if ((Signals[Directions.Down][Prices.Name]["CrossMA"].Candle == 0) or (Signals[Directions.Down][Stochs.Name]["Cross50"].Candle == 0) or (Signals[Directions.Down][RSIs.Name]["Cross50"].Candle == 0)) then

            -- set chart label
            ChartLabels[Prices.Name][index_candle-1] = SetChartLabel((index_candle-1), Directions.Down, Prices.Name, "Trend", ChartIcons.BigCross, ChartPermissions[2], tostring(duration) .. "|" .. DealStages.End)

            -- turn off state
            Signals[Directions.Down][Prices.Name]["StateTrend"].Candle = 0

        -- state trend down end by end of duration
        elseif (duration >= Signals.Params.Duration) then
            -- set chart label
            ChartLabels[Prices.Name][index_candle-1] = SetChartLabel((index_candle-1), Directions.Down, Prices.Name, "Trend", ChartIcons.BigCross, ChartPermissions[2], tostring(index_candle-1) .. "|" .. tostring(duration) .. "|" .. DealStages.End .. "by duration")

            -- turn off state
            Signals[Directions.Down][Prices.Name]["StateTrend"].Candle = 0
        end
    end ]] 
	--#endregion

    --#region IV.2. State: State[Down/Up].Impulse
    ---             Depends: Stoch.Cross, RSI.Cross
    --              Terminates by signals: One of reverse self-signal
    --              Terminates by duration: -
	--#endregion

    -- check start trend up state and check signals up
    --[[ if ((Signals[Directions.Up][Stochs.Name]["StateImpulse"].Candle == 0) and (Signals[Directions.Up][Stochs.Name]["Cross"].Candle > 0) and (Signals[Directions.Up][RSIs.Name]["Cross"].Candle > 0)) then

        -- set trend down signal off
        SetState((index_candle-1), Directions.Up, "Impulse")

        -- set chart label
        ChartLabels[Stochs.Name][index_candle-1] = SetChartLabel((index_candle-1), Directions.Up, Stochs.Name, "Impulse", ChartIcons.BigArrow, ChartPermissions[3], DealStages.Start)
    end

    -- check start trend down state and check signals down
    if ((Signals[Directions.Down][Stochs.Name]["StateImpulse"].Candle == 0) and (Signals[Directions.Down][Stochs.Name]["Cross"].Candle > 0) and (Signals[Directions.Down][RSIs.Name]["Cross"].Candle > 0)) then

        -- set trend down signal off
        SetState((index_candle-1), Directions.Down, "Impulse")

        -- set chart label
        ChartLabels[Stochs.Name][index_candle-1] = SetChartLabel((index_candle-1), Directions.Down, Stochs.Name, "Impulse", ChartIcons.BigArrow, ChartPermissions[3], DealStages.Start)
    end

    -- check state trend up end
    if (Signals[Directions.Up][Stochs.Name]["StateImpulse"].Candle > 0) then

        local duration = index_candle - Signals[Directions.Up][Stochs.Name]["StateImpulse"].Candle

        -- state trend up end by end one of up signals
        if ((Signals[Directions.Up][Stochs.Name]["Cross"].Candle == 0) or (Signals[Directions.Up][RSIs.Name]["Cross"].Candle == 0)) then

            -- set chart label
            ChartLabels[Stochs.Name][index_candle-1] = SetChartLabel((index_candle-1), Directions.Up, Stochs.Name, "Impulse", ChartIcons.BigCross, ChartPermissions[3], tostring(index_candle-1) .. "|" .. tostring(duration) .. "|" .. DealStages.End .. " by offsignal")

            -- turn off state
            Signals[Directions.Up][Stochs.Name]["StateImpulse"].Candle = 0

        -- state trend up end by end of duration
        elseif (duration >= Signals.Params.Duration) then
            -- set chart label
            ChartLabels[Stochs.Name][index_candle-1] = SetChartLabel((index_candle-1), Directions.Up, Stochs.Name, "Impulse", ChartIcons.BigCross, ChartPermissions[3], tostring(index_candle-1) .. "|" .. tostring(duration) .. "|" .. DealStages.End .. " by duration")

            -- turn off state
            Signals[Directions.Up][Stochs.Name]["StateImpulse"].Candle = 0

        end
    end

    -- check state trend down end
    if (Signals[Directions.Down][Stochs.Name]["StateImpulse"].Candle > 0) then

        local duration = index_candle - Signals[Directions.Down][Stochs.Name]["StateImpulse"].Candle

        -- state trend down end by end one of down signals
        if ((Signals[Directions.Down][Stochs.Name]["Cross"].Candle == 0) or (Signals[Directions.Down][RSIs.Name]["Cross"].Candle == 0)) then
            -- set chart label
            ChartLabels[Stochs.Name][index_candle-1] = SetChartLabel((index_candle-1), Directions.Down, Stochs.Name, "Impulse", ChartIcons.BigCross, ChartPermissions[3], tostring(duration) .. "|" .. DealStages.End .. " by offsignal")

            -- turn off state
            Signals[Directions.Down][Stochs.Name]["StateImpulse"].Candle = 0

        -- state trend down end by end of duration
        elseif (duration >= Signals.Params.Duration) then            
            -- set chart label
            ChartLabels[Stochs.Name][index_candle-1] = SetChartLabel((index_candle-1), Directions.Down, Stochs.Name, "Impulse", ChartIcons.BigCross, ChartPermissions[3], tostring(index_candle-1) .. "|" .. tostring(duration) .. "|" .. DealStages.End .. " by duration")

            -- turn off state
            Signals[Directions.Down][Stochs.Name]["StateImpulse"].Candle = 0
        end
    end ]] 

    --PrintDebugSummary(index_candle, 7314)

    return PCs.Tops[index_candle], CentreLines[index_candle], PCs.Bottoms[index_candle]
    -- return Stochs.Slows[index_candle], Stochs.Fasts[index_candle]
    -- return RSIs.Slows[index_candle], RSIs.Fasts[index_candle]
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
        if (PCs.Params.Period > 0) then
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
                Highs[CyclicPointer(Idx_buffer, PCs.Params.Period - 1) + 1] = H(Idx_chart)
                Lows[CyclicPointer(Idx_buffer, PCs.Params.Period - 1) + 1] = L(Idx_chart)

                -- calc and return max results
                if (Idx_buffer >= PCs.Params.Period) then
                    local max_high = math.max(table.unpack(Highs))
                    local max_low = math.min(table.unpack(Lows))

                    return max_high, max_low
                end
            end
        end
        return nil, nil
    end
end

----------------------------------------------------------------------------
-- function CentreLine
----------------------------------------------------------------------------
function GetCentreLine(index, direction, price_type, prices)
    if (price_type == PriceTypes.AvarageCloses) then
        return (prices.Closes[index-2] + prices.Closes[index-1]) / 2
    end
    
    local result

    if (direction  == Directions.Up) then
        result = (prices.Lows[index-2] + prices.Highs[index-1]) / 2
    elseif (direction  == Directions.Down) then
        result = (prices.Lows[index-1] + prices.Highs[index-2]) / 2
    end
    
    if (price_type == PriceTypes.Median) then
        return result
    end
    
    result = (result * 2 + prices.Closes[index-1]) / 3
    
    if (price_type == PriceTypes.Typical) then
        return result
    end

    result = (result * 3 + prices.Opens[index-2]) / 4

    if (price_type == PriceTypes.Weighted) then
        return result
    end

    return -1
end
--#endregion

--==========================================================================
--#region INDICATOR STOCH
--==========================================================================
----------------------------------------------------------------------------
-- function Stochastic Oscillator ("SO")
----------------------------------------------------------------------------
function Stoch(mode)
    local Settings = { period_k = Stochs.Params[mode].PeriodK, shift = Stochs.Params[mode].Shift, period_d = Stochs.Params[mode].PeriodD }

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
--#endregion

--==========================================================================
-- SIGNALS
--==========================================================================
----------------------------------------------------------------------------
--#region Oscilator Signals
----------------------------------------------------------------------------
--
-- Signal Osc Vertical Steamer
--
function SignalOscVSteamer(index, direction, oscs, vertical_difference, dev)
    if (CheckDataExist(index, 3, oscs.Slows) and CheckDataExist(index, 3, oscs.Fasts)) then

        --PrintDebugMessage("VSteamer", index)

        dev = dev or 0
        local v_diff = vertical_difference or Signals.Params.Steamer.VerticalDifference

        -- true or false
        if (-- oscs move in direction last 3 candles
        (EventMove(index, direction, oscs.Fasts, dev) and EventMove(index, direction, oscs.Slows, dev) and EventMove(index-1, direction, oscs.Fasts, dev) and EventMove(index-1, direction, oscs.Slows, dev)) and
        -- fast osc ralate slow osc in direction last 3 candles
        (ConditionRelate(direction, oscs.Fasts[index-1], oscs.Slows[index-1], dev) and ConditionRelate(direction, oscs.Fasts[index-2], oscs.Slows[index-2], dev) and ConditionRelate(direction, oscs.Fasts[index-3], oscs.Slows[index-3], dev)) and
        -- delta beetwen osc fast and slow osc less then dev last 3 candles
        ((GetDelta(oscs.Fasts[index-1], oscs.Slows[index-1]) <= v_diff) and (GetDelta(oscs.Fasts[index-2], oscs.Slows[index-2]) <= v_diff) and (GetDelta(oscs.Fasts[index-3], oscs.Slows[index-3]) <= v_diff))) then

            -- set chart label
            -- ChartLabels[oscs.Name][index-1] = SetChartLabel(T(index-1), GetChartLabelYPos(index-1, direction, oscs.Name), ChartParams[oscs.Name].Tag, GetChartLabelText(index-1, direction, oscs.Name, "VSteamer", DealStages.Start), ChartIcons.Flash, ChartPermissions[1])

            return true
        else
            return false
        end
    end
end

--
-- Signal Osc Horisontal Steamer
--
function SignalOscHSteamer(index, direction, oscs, horizontal_duration, dev)
    local h_dur = horizontal_duration or Signals.Params.Steamer.HorizontalDuration
    
    if (CheckDataExist(index, (h_dur+2), oscs.Slows) and CheckDataExist(index, (h_dur+2), oscs.Fasts)) then
        
        dev = dev or 0

        if (SignalOscCrossLevel(index, direction, oscs.Slows, Stochs.Params.HLines.Centre, dev)) then

            -- true or false
            local count
            for count = 0, h_dur do

                if (SignalOscCrossLevel((index-count), direction, oscs.Fasts, Stochs.Params.HLines.Centre, dev) and
                -- oscs move in direction 2 candles
                (EventMove(oscs.Fasts, (index-count), direction, dev) and EventMove(oscs.Slows, index, direction, dev)) and
                -- fast osc ralate slow osc in direction 2 candles
                (ConditionRelate(oscs.Fasts[(index-count)-1], oscs.Slows[(index-count)-1], direction, dev) and ConditionRelate(oscs.Fasts[index-1], oscs.Slows[index-1], direction, dev))) then

                    -- set chart label
                    -- ChartLabels[oscs.Name][(index-count)-1] = SetChartLabel(T((index-count)-1), GetChartLabelYPos((index-count)-1, direction, oscs.Name), ChartParams[oscs.Name].Tag, GetChartLabelText((index-count)-1, direction, oscs.Name, "HSteamer", DealStages.Start), ChartIcons.Flash, ChartPermissions[1])

                    return true
                end
            end
            return false
        end
    else
        return false
    end
end

--
-- Signal Osc Fast Cross Osc Slow
--
function SignalOscCross(index, direction, oscs, dev)
    if (CheckDataExist(index, 2, oscs.Slows) and CheckDataExist(index, 2, oscs.Fasts)) then
        dev = dev or 0

        -- true or false
        return EventCross(index, direction, oscs.Fasts, oscs.Slows, dev)
    else
        return false
    end
end

--
-- Signal Osc Cross Level
--
function SignalOscCrossLevel(index, direction, oscs, level, dev)    
    if (CheckDataExist(index, 2, oscs.Slows)) then
        dev = dev or 0

        -- osc cross level up/down
        return EventCross(index, direction, oscs.Slows, {[index-2] = level, [index-1] = level}, dev)

    -- not enough data
    else
        return false
    end
end

--
-- Signal Osc TrendOn
--
function SignalOscTrendOn(index, direction, oscs, dev)
    dev = dev or 0
    local level

    -- check for rsi
    if (oscs.Name == RSIs.Name) then
        if (CheckDataExist(index, 2, RSIs.Slows)) then

            if (direction == Directions.Up) then
                level = RSIs.Params.HLines.TopTrend
            elseif (direction == Directions.Down) then
                level = RSIs.Params.HLines.BottomTrend
            else
                return false
            end

            return SignalOscCrossLevel(index, direction, level, RSIs.Slows, dev)
        -- not enough data
        else
            return false
        end

    -- check for stochastic
    elseif (oscs.Name == Stochs.Name) then
        if (CheckDataExist(index, 2, Stochs.Slows)) then

            if (direction == Directions.Up) then
                level = Stochs.Params.HLines.TopExtreme
            elseif (direction == Directions.Down) then
                level = Stochs.Params.HLines.BottomExtreme
            else
                return false
            end

            return SignalOscCrossLevel(index, direction, level, Stochs.Slows, dev)
        -- not enough data
        else
            return false
        end

    -- check for pc
    elseif (oscs.Name == PCs.Name) then
        if (CheckDataExist(index, 2, PCs.Centres) and CheckDataExist(index, 2, Prices.Closes)) then

            if (direction == Directions.Up) then
                level = PCs.Tops[index-2]
            elseif (direction == Directions.Down) then
                level = PCs.Bottoms[index-2]
            else
                return false
            end

            return SignalOscCrossLevel(index, direction, level, Prices.Closes, dev)
        -- not enough data
        else
            return false
        end

    -- error - there are not such oscs
    else
        return false
    end
end

--
-- Signal Osc TrendOff
--
function SignalOscTrendOff(index, direction, oscs, dev)
    dev = dev or 0
    local level

    -- check for rsi
    if (oscs.Name == RSIs.Name) then
        if (CheckDataExist(index, 2, RSIs.Slows)) then

            if (direction == Directions.Up) then
                level = RSIs.Params.HLines.BottomTrend
            elseif (direction == Directions.Down) then
                level = RSIs.Params.HLines.TopTrend
            end

            return SignalOscCrossLevel(index, direction, level, RSIs.Slows, dev)
        -- not enough data
        else
            return false
        end

    -- chek for stochastic
    elseif (oscs.Name == Stochs.Name) then
        if (CheckDataExist(index, 2, Stochs.Slows)) then

            if (direction == Directions.Up) then
                level = Stochs.Params.HLines.BottomExtreme
            elseif (direction == Directions.Down) then
                level = Stochs.Params.HLines.TopExtreme
            end
            
            return SignalOscCrossLevel(index, direction, level, Stochs.Slows, dev)
        -- not enough data
        else
            return false
        end

    -- chek for pc
    elseif (oscs.Name == PCs.Name) then
        if (CheckDataExist(index, 2, PCs.Centres) and CheckDataExist(index, 2, Prices.Closes)) then

            if (direction == Directions.Up) then
                level = PCs.Botttom[index-2]
            elseif (direction == Directions.Down) then
                level = PCs.Tops[index-2]
            end
            
            return SignalOscCrossLevel(index, direction, level, Prices.Closes, dev)
        -- not enough data
        else
            return false
        end

    -- error - there are not such oscs
    else
        return false
    end
end

--
-- Signal Osc Uturn with 3 candles
--
function SignalOscUturn3(index, direction, oscs, dev)
    if (CheckDataExist(index, 3, oscs.Slows) and CheckDataExist(index, 3, oscs.Fasts) and CheckDataExist(index, 3, oscs.Deltas)) then

        dev = dev or 0

        -- true or false
        return ( -- deltas uturn
            EventUturn(index, Directions.Up, oscs.Deltas, dev) and
            -- fastosc/slowosc uturn
            EventUturn(index, direction, oscs.Fasts, dev) and EventMove(index, direction, oscs.Slows, dev) and
            -- fastosc over slowosc all 3 candles
            (ConditionRelate(direction, oscs.Fasts[index-3], oscs.Slows[index-3], dev) and ConditionRelate(direction, oscs.Fasts[index-2], oscs.Slows[index-2], dev) and ConditionRelate(direction, oscs.Fasts[index-1], oscs.Slows[index-1], dev)))

    -- not enough data
    else
        return false
    end
end

--
-- Signal Osc Uturn with 4 candles
--
function SignalOscUturn4(index, direction, oscs, dev)
    if (CheckDataExist(index, 4, oscs.Slows) and CheckDataExist(index, 4, oscs.Fasts) and CheckDataExist(index, 4, oscs.Deltas)) then

        dev = dev or 0

        -- true or false
        return ( -- deltas uturn
            (EventMove((index-2), Directions.Down, oscs.Deltas, dev) and EventMove(index, Directions.Up, oscs.Deltas, dev)) and
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

----------------------------------------------------------------------------
--#region Price Signals
----------------------------------------------------------------------------
--
-- Signal Price	CrossMA
--
function SignalPriceCrossMA(index, direction, prices, mas, dev)
    if (CheckDataExist(index, 2, prices.Closes) and CheckDataExist(index, 2, mas)) then
        dev = dev or 0

        -- candle close cross ma up/down
        return (EventCross(index, direction, prices.Closes, mas, dev))

    -- not enough data
    else
        return false
    end
end

--
-- Signal Price Uturn with 3 candles
--
function SignalPriceUturn3(index, direction, prices, mas, dev)
    if (CheckDataExist(index, 3, prices.Opens) and CheckDataExist(index, 3, prices.Closes) and CheckDataExist(index, 3, prices.Highs) and CheckDataExist(index, 3, prices.Lows) and CheckDataExist(index, 3, mas.Centres) and CheckDataExist(index, 3, mas.Deltas)) then

        dev = dev or 0

        if (index == 7744 or index == 7743 or index == 7742 or index == 7741) then
            PrintDebugMessage("===", "Uturn3", index, T(index).month, T(index).day, T(index).hour, T(index).min, direction, "===")
            PrintDebugMessage("   candle-3 or -2 contr-trend", (ConditionRelate(Reverse(direction), prices.Closes[index-3], prices.Opens[index-3], dev) or ConditionRelate(Reverse(direction), prices.Closes[index-2], prices.Opens[index-2], dev)), "   candle pro-trend-1", ConditionRelate(direction, prices.Closes[index-1], prices.Opens[index-1], dev))
            PrintDebugMessage("   closes0 uturn", EventUturn(index, direction, prices.Closes, dev), "   delta0 uturn", EventUturn(index, direction, mas.Deltas, dev))
            PrintDebugMessage("    ma deltas", mas.Deltas[index-3], mas.Deltas[index-2], mas.Deltas[index-1])
            PrintDebugMessage("   ma move pro-trend-0", EventMove(index, direction, mas.Centres, dev), EventFlat(index, mas.Centres, dev))
            PrintDebugMessage("   ma move pro-trend-1", EventMove((index-1), direction, mas.Centres, dev), EventFlat((index-1), mas.Centres, dev))
            PrintDebugMessage("   strength up3", (prices.Closes[index-1] > (prices.Lows[index-3] + 2.0 / 3.0 * (prices.Highs[index-3] - prices.Lows[index-3]))),
            "   strength up2", (prices.Closes[index-1] > (prices.Lows[index-2] + 2.0 / 3.0 * (prices.Highs[index-2] - prices.Lows[index-2]))), 
            "   strength down3", ((prices.Highs[index-3] - 2.0 / 3.0 * (prices.Highs[index-3] - prices.Lows[index-3])) > prices.Closes[index-1]),
            "   strength down2", ((prices.Highs[index-2] - 2.0 / 3.0 * (prices.Highs[index-2] - prices.Lows[index-2])) > prices.Closes[index-1]))
        end

        local condition = 
            -- one first candle contr-trend, one last candle pro-trend
            (ConditionRelate(Reverse(direction), prices.Closes[index-3], prices.Opens[index-3], dev) or ConditionRelate(Reverse(direction), prices.Closes[index-2], prices.Opens[index-2], dev)) and ConditionRelate(direction, prices.Closes[index-1], prices.Opens[index-1], dev) and
            -- prices.Closes uturn
            EventUturn(index, direction, prices.Closes, dev) and
            -- delta uturn with delta min at uturn top
            EventUturn(index, direction, mas.Deltas, dev) and
            -- ma move pro-trend 3 last candles
            (EventMove(index, direction, mas.Centres, dev) or EventFlat(index, mas.Centres, dev)) and (EventMove((index-1), direction, mas.Centres, dev) or EventFlat((index-1), mas.Centres, dev))

        if (direction == Directions.Up) then
            return (condition and
                -- strength condition
                -- (prices.Closes[index-1] >= prices.Closes[index-2]) and (prices.Closes[index-1] >= prices.Closes[index-3]))
                ((prices.Closes[index-1] > (prices.Lows[index-3] + 2.0 / 3.0 * (prices.Highs[index-3] - prices.Lows[index-3]))) or
			    (prices.Closes[index-1] > (prices.Lows[index-2] + 2.0 / 3.0 * (prices.Highs[index-2] - prices.Lows[index-2])))))

        elseif (direction == Directions.Down) then
            return (condition and
                -- strength condition
                -- (prices.Closes[index-2] >= prices.Closes[index-1]) and (prices.Closes[index-3] >= prices.Closes[index-1]))

                (((prices.Highs[index-3] - 2.0 / 3.0 * (prices.Highs[index-3] - prices.Lows[index-3])) > prices.Closes[index-1]) or
			    ((prices.Highs[index-2] - 2.0 / 3.0 * (prices.Highs[index-2] - prices.Lows[index-2])) > prices.Closes[index-1])))
        end

    -- not enough data
    else
        return false
    end
end

--
-- Signal Price Uturn with 4 candles
--
function SignalPriceUturn4(index, direction, prices, mas, dev)
    if (CheckDataExist(index, 4, prices.Opens) and CheckDataExist(index, 4, prices.Closes) and CheckDataExist(index, 4, prices.Highs) and CheckDataExist(index, 4, prices.Lows) and CheckDataExist(index, 4, mas.Centres) and CheckDataExist(index, 4, mas.Deltas)) then

        dev = dev or 0

        local pre_result = 
        -- one first candle contr-trend, one last candle pro-trend
        ConditionRelate(direction, prices.Opens[index-4], prices.Closes[index-4], dev) and ConditionRelate(direction, prices.Closes[index-1], prices.Opens[index-1], dev) and
        -- price.Closes uturn
        EventMove((index-2), Reverse(direction), prices.Closes, dev) and EventMove(index, direction, prices.Closes, dev) and
        -- delta min at top uturn
        EventMove((index-2), Directions.Down, mas.Deltas, dev) and EventMove(index, Directions.Up, mas.Deltas, dev) and
        -- ma move 4 last candles up
        (EventMove(index, direction, mas.Centres, dev) or EventFlat(index, mas.Centres, dev)) and
        (EventMove((index-1), direction, mas.Centres, dev) or EventFlat((index-1), mas.Centres, dev)) and
        (EventMove((index-2), direction, mas.Centres, dev) or EventFlat((index-2), mas.Centres, dev))

    if (direction == Directions.Up) then
        return (pre_result and
            -- strength condition
            (prices.Closes[index-1] >= prices.Closes[index-2]) and (prices.Closes[index-1] >= prices.Closes[index-3]) and (prices.Closes[index-1] >= prices.Closes[index-4]))

        elseif (direction == Directions.Down) then
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

----------------------------------------------------------------------------
--#region Events
----------------------------------------------------------------------------
--
-- Event Value1 cross Value2 up and down
--
function EventCross(index, direction, value1, value2, dev)
    return (ConditionRelate(direction, value2[index-2], value1[index-2], dev) and ConditionRelate(direction, value1[index-1], value2[index-1], dev))
end

--
-- Event 2 last candles Value move up or down
--
function EventMove(index, direction, value, dev)
    return ConditionRelate(direction, value[index-1], value[index-2], dev)
end

--
-- Event 3 last candles Value uturn up or down
--
function EventUturn(index, direction, value, dev)
    return (ConditionRelate(direction, value[index-3], value[index-2], dev) and ConditionRelate(direction, value[index-1], value[index-2], dev))
end

--
-- Event is 2 last candles Value is equal
--
function EventFlat(index, value, dev)
    return (GetDelta(value[index-1], value[index-2]) <= dev)
end

--
-- Condition Is Value1 over or under Value2
--
function ConditionRelate(direction, value1, value2, dev)
    if (direction == Directions.Up) then
        return (value1 > (value2 + dev))
    elseif (direction == Directions.Down) then
        return (value2 > (value1 + dev))
    end
end
--#endregion

--==========================================================================
--#region UTILITIES
--==========================================================================
----------------------------------------------------------------------------
-- function Reverse return reverse of direction
----------------------------------------------------------------------------
function Reverse(direction)
    if (direction == Directions.Up) then
        return Directions.Down
    elseif (direction == Directions.Down) then
        return Directions.Up
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
function SetSignal(index, direction, indicator_name, signal_name)
    -- set signal up/down off
    Signals[Reverse(direction)][indicator_name][signal_name].Candle = 0

    -- set signal down/up on
    Signals[direction][indicator_name][signal_name].Count = Signals[direction][indicator_name][signal_name].Count + 1
    Signals[direction][indicator_name][signal_name].Candle = index
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
-- function CheckDataExist return true if number values from index_candle back exist
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
-- function CheckChartPermission
----------------------------------------------------------------------------
function CheckChartPermission(indicator_name, signal_permission)
    return (((signal_permission == ChartPermissions[1]) and ((ChartParams[indicator_name].Permission & 1) > 0)) or ((signal_permission == ChartPermissions[2]) and ((ChartParams[indicator_name].Permission & 2) > 0)) or ((signal_permission == ChartPermissions[3]) and ((ChartParams[indicator_name].Permission & 4) > 0))  or ((signal_permission == ChartPermissions[4]) and ((ChartParams[indicator_name].Permission & 8) > 0)))
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
function SetChartLabel(index, direction, indicator_name, signal_name, icon, signal_permission, text)
    -- check signal level and chart levels
    if CheckChartPermission(indicator_name, signal_permission) then

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

    -- nothing todo
    else
        return -1
    end
end

----------------------------------------------------------------------------
-- function SetInitialCounts()    init Signals Candles and Counts
----------------------------------------------------------------------------
function SetInitialCounts()
    -- down signals
    Signals[Directions.Down][Prices.Name]["CrossMA"].Count = 0
    Signals[Directions.Down][Prices.Name]["CrossMA"].Candle = 0
    Signals[Directions.Down][Prices.Name]["Uturn3"].Count = 0
    Signals[Directions.Down][Prices.Name]["Uturn3"].Candle = 0
    Signals[Directions.Down][Prices.Name]["Uturn4"].Count = 0
    Signals[Directions.Down][Prices.Name]["Uturn4"].Candle = 0
    Signals[Directions.Down][Prices.Name]["StateTrend"].Count = 0
    Signals[Directions.Down][Prices.Name]["StateTrend"].Candle = 0
    Signals[Directions.Down][Prices.Name]["EnterUturn3"].Count = 0
    Signals[Directions.Down][Prices.Name]["EnterUturn3"].Candle = 0

    Signals[Directions.Down][Stochs.Name]["Cross"].Count = 0
    Signals[Directions.Down][Stochs.Name]["Cross"].Candle = 0
    Signals[Directions.Down][Stochs.Name]["Cross50"].Count = 0
    Signals[Directions.Down][Stochs.Name]["Cross50"].Candle = 0
    Signals[Directions.Down][Stochs.Name]["HSteamer"].Count = 0
    Signals[Directions.Down][Stochs.Name]["HSteamer"].Candle = 0
    Signals[Directions.Down][Stochs.Name]["VSteamer"].Count = 0
    Signals[Directions.Down][Stochs.Name]["VSteamer"].Candle = 0
    Signals[Directions.Down][Stochs.Name]["TrendOn"].Count = 0
    Signals[Directions.Down][Stochs.Name]["TrendOn"].Candle = 0
    Signals[Directions.Down][Stochs.Name]["TrendOff"].Count = 0
    Signals[Directions.Down][Stochs.Name]["TrendOff"].Candle = 0
    Signals[Directions.Down][Stochs.Name]["Uturn3"].Candle = 0
    Signals[Directions.Down][Stochs.Name]["Uturn3"].Count = 0
    Signals[Directions.Down][Stochs.Name]["Uturn4"].Candle = 0
    Signals[Directions.Down][Stochs.Name]["Uturn4"].Count = 0
    Signals[Directions.Down][Stochs.Name]["Spring3"].Candle = 0
    Signals[Directions.Down][Stochs.Name]["Spring3"].Count = 0
    Signals[Directions.Down][Stochs.Name]["Spring4"].Candle = 0
    Signals[Directions.Down][Stochs.Name]["Spring4"].Count = 0    
    Signals[Directions.Down][Stochs.Name]["StateImpulse"].Candle = 0
    Signals[Directions.Down][Stochs.Name]["StateImpulse"].Count = 0

    Signals[Directions.Down][RSIs.Name]["Cross"].Count = 0
    Signals[Directions.Down][RSIs.Name]["Cross"].Candle = 0
    Signals[Directions.Down][RSIs.Name]["Cross50"].Count = 0
    Signals[Directions.Down][RSIs.Name]["Cross50"].Candle = 0
    Signals[Directions.Down][RSIs.Name]["TrendOn"].Count = 0
    Signals[Directions.Down][RSIs.Name]["TrendOn"].Candle = 0
    Signals[Directions.Down][RSIs.Name]["TrendOff"].Count = 0
    Signals[Directions.Down][RSIs.Name]["TrendOff"].Candle = 0
    Signals[Directions.Down][RSIs.Name]["Uturn3"].Candle = 0
    Signals[Directions.Down][RSIs.Name]["Uturn3"].Count = 0
    Signals[Directions.Down][RSIs.Name]["Uturn4"].Candle = 0
    Signals[Directions.Down][RSIs.Name]["Uturn4"].Count = 0
    Signals[Directions.Down][RSIs.Name]["Spring3"].Candle = 0
    Signals[Directions.Down][RSIs.Name]["Spring3"].Count = 0
    Signals[Directions.Down][RSIs.Name]["Spring4"].Candle = 0
    Signals[Directions.Down][RSIs.Name]["Spring4"].Count = 0

    -- up signals
    Signals[Directions.Up][Prices.Name]["CrossMA"].Count = 0
    Signals[Directions.Up][Prices.Name]["CrossMA"].Candle = 0
    Signals[Directions.Up][Prices.Name]["Uturn3"].Count = 0
    Signals[Directions.Up][Prices.Name]["Uturn3"].Candle = 0
    Signals[Directions.Up][Prices.Name]["Uturn4"].Count = 0
    Signals[Directions.Up][Prices.Name]["Uturn4"].Candle = 0    
    Signals[Directions.Up][Prices.Name]["StateTrend"].Count = 0
    Signals[Directions.Up][Prices.Name]["StateTrend"].Candle = 0
    Signals[Directions.Up][Prices.Name]["EnterUturn3"].Count = 0
    Signals[Directions.Up][Prices.Name]["EnterUturn3"].Candle = 0

    Signals[Directions.Up][Stochs.Name]["Cross"].Count = 0
    Signals[Directions.Up][Stochs.Name]["Cross"].Candle = 0
    Signals[Directions.Up][Stochs.Name]["Cross50"].Count = 0
    Signals[Directions.Up][Stochs.Name]["Cross50"].Candle = 0
    Signals[Directions.Up][Stochs.Name]["HSteamer"].Count = 0
    Signals[Directions.Up][Stochs.Name]["HSteamer"].Candle = 0
    Signals[Directions.Up][Stochs.Name]["VSteamer"].Count = 0
    Signals[Directions.Up][Stochs.Name]["VSteamer"].Candle = 0
    Signals[Directions.Up][Stochs.Name]["TrendOn"].Count = 0
    Signals[Directions.Up][Stochs.Name]["TrendOn"].Candle = 0
    Signals[Directions.Up][Stochs.Name]["TrendOff"].Count = 0
    Signals[Directions.Up][Stochs.Name]["TrendOff"].Candle = 0
    Signals[Directions.Up][Stochs.Name]["Uturn3"].Candle = 0
    Signals[Directions.Up][Stochs.Name]["Uturn3"].Count = 0
    Signals[Directions.Up][Stochs.Name]["Uturn4"].Candle = 0
    Signals[Directions.Up][Stochs.Name]["Uturn4"].Count = 0
    Signals[Directions.Up][Stochs.Name]["Spring3"].Candle = 0
    Signals[Directions.Up][Stochs.Name]["Spring3"].Count = 0
    Signals[Directions.Up][Stochs.Name]["Spring4"].Candle = 0
    Signals[Directions.Up][Stochs.Name]["Spring4"].Count = 0
    Signals[Directions.Up][Stochs.Name]["StateImpulse"].Candle = 0
    Signals[Directions.Up][Stochs.Name]["StateImpulse"].Count = 0

    Signals[Directions.Up][RSIs.Name]["Cross"].Count = 0
    Signals[Directions.Up][RSIs.Name]["Cross"].Candle = 0
    Signals[Directions.Up][RSIs.Name]["Cross50"].Count = 0
    Signals[Directions.Up][RSIs.Name]["Cross50"].Candle = 0
    Signals[Directions.Up][RSIs.Name]["TrendOn"].Count = 0
    Signals[Directions.Up][RSIs.Name]["TrendOn"].Candle = 0
    Signals[Directions.Up][RSIs.Name]["TrendOff"].Count = 0
    Signals[Directions.Up][RSIs.Name]["TrendOff"].Candle = 0
    Signals[Directions.Up][RSIs.Name]["Uturn3"].Candle = 0
    Signals[Directions.Up][RSIs.Name]["Uturn3"].Count = 0
    Signals[Directions.Up][RSIs.Name]["Uturn4"].Candle = 0
    Signals[Directions.Up][RSIs.Name]["Uturn4"].Count = 0
    Signals[Directions.Up][RSIs.Name]["Spring3"].Candle = 0
    Signals[Directions.Up][RSIs.Name]["Spring3"].Count = 0
    Signals[Directions.Up][RSIs.Name]["Spring4"].Candle = 0
    Signals[Directions.Up][RSIs.Name]["Spring4"].Count = 0
end

----------------------------------------------------------------------------
--
----------------------------------------------------------------------------
function PrintDebugSummary(index, number)
    if (index == number) then
        local t = T(index)
        PrintDebugMessage("Summary", index, t.month, t.day, t.hour, t.min)

        PrintDebugMessage("StatesUp", "Trend", Signals[Directions.Up][Prices.Name]["StateTrend"].Count, "Impulse", Signals[Directions.Up][Stochs.Name]["StateImpulse"].Count)
        PrintDebugMessage("PricesUp", "CrossMA", Signals[Directions.Up][Prices.Name]["CrossMA"].Count)
        PrintDebugMessage("StochsUp", "Cross", Signals[Directions.Up][Stochs.Name]["Cross"].Count, "Cross50", Signals[Directions.Up][Stochs.Name]["Cross50"].Count)
        PrintDebugMessage("RSIsUp", "Cross", Signals[Directions.Up][RSIs.Name]["Cross"].Count, "Cross50", Signals[Directions.Up][RSIs.Name]["Cross50"].Count)

        PrintDebugMessage("StatesDown", "Trend", Signals[Directions.Down][Prices.Name]["StateTrend"].Count, "Impulse", Signals[Directions.Up][Stochs.Name]["StateImpulse"].Count)
        PrintDebugMessage("PricesDown", "CrossMA", Signals[Directions.Down][Prices.Name]["CrossMA"].Count)
        PrintDebugMessage("StochsDown", "Cross", Signals[Directions.Down][Stochs.Name]["Cross"].Count, "Cross50", Signals[Directions.Down][Stochs.Name]["Cross50"].Count)
        PrintDebugMessage("RSIsDown", "Cross", Signals[Directions.Down][RSIs.Name]["Cross"].Count, "Cross50", Signals[Directions.Down][RSIs.Name]["Cross50"].Count)
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
