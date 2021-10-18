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

-- if function make something - return number maked things, or 0 if nothing todo, or -1 if error
-- if function return string or number or boolean - return string or number or boolean if success or return nil if error. todo nothing return nil

----------------------------------------------------------------------------
--#region Settings
----------------------------------------------------------------------------
Settings = { Name = "FEK_LITHIUM",
    -- lines on main chart
    line = {{ Name = "PCTop", Type = TYPE_LINE, Color = RGB(221, 44, 44) }, { Name = "PCenter", Type = TYPE_LINE,	Color = RGB(0, 206, 0) },  { Name = "PCBottom", Type = TYPE_LINE, Color = RGB(0, 162, 232) }}}
--#endregion

--==========================================================================
--#region Init
--==========================================================================
function Init()
    -- indicators data arrays and params
    Stochs = { Name = "Stoch", Fast = {}, Slow = {}, Delta = {},
        Params = { HLines = { TopExtreme = 80, Center = 50, BottomExtreme = 20 }, Slow = { PeriodK = 10, Shift = 3, PeriodD = 1 }, Fast = { PeriodK = 5, Shift = 2, PeriodD = 1 }}}
    Prices = { Name = "Price", Open = {}, Close = {}, High = {}, Low = {}}
    RSIs = { Name = "RSI", Fast = {}, Slow = {}, Delta = {},
        Params = { HLines = { TopExtreme = 80, TopTrend = 60, Center = 50, BottomTrend = 40, BottomExtreme = 20 }, PeriodSlow = 14, PeriodFast = 9 }}
    PCs = { Name = "PC", Top = {}, Bottom = {}, Center = {}, Delta = {}, Params = { Period = 20 }}

    -- directions for signals, labels and deals
    Directions = { Up = "up", Down = "down" }

    -- grades to show labels on charts
    ChartPermissions = { 1, 2, 4, 8 }

    -- tags for charts to show labels and steps for text labels on charts, permission for what label show on chart
    ChartParams = { [Prices.Name] = { Tag = GetChartTag(Prices.Name), Step = 15, Permission = ChartPermissions[1] + ChartPermissions[3] },	-- FEK_LITHIUMPrice
        [Stochs.Name] = { Tag = GetChartTag(Stochs.Name), Step = 10, Level = ChartPermissions[4] }, -- FEK_LITHIUMStoch
        [RSIs.Name] = { Tag = GetChartTag(RSIs.Name), Step = 5, Level = ChartPermissions[2] }}		-- FEK_LITHIUMRSI

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
        ChartLabels.Params.IconPath = ScriptPath .. "\\white_theme\\"
        ChartLabels.Params.R = 0
        ChartLabels.Params.G = 0
        ChartLabesl.Params.B = 0
    end

    -- chart label icons
    ChartIcons = { Arrow = "arrow", Point = "point", Triangle = "triangle", Cross = "cross", Romb = "romb", Plus = "plus", Flash = "flash", Asterix = "asterix", BigArrow = "big_arrow", BigPoint = "big_point", BigTriangle = "big_triangle", BigCross = "big_cross", BigRomb = "big_romb", BigPlus = "big_plus" }

    DealStages = { "Start", "Continue", "End" }

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
    -- several states cinsist enters like Leg1ZigZagSpring, Uturn50 etc
    Signals = {	[Directions.Up] = { 
        [Prices.Name] = { CrossMA = { Count = 0, Candle = 0 }, Uturn3 = { Count = 0, Candle = 0 }, Uturn4 = { Count = 0, Candle = 0 }},
        [Stochs.Name] = { Cross = { Count = 0, Candle = 0 }, Cross50 = { Count = 0, Candle = 0 }, HSteamer = { Count = 0, Candle = 0 }, VSteamer = { Count = 0, Candle = 0 }, TrendOn = { Count = 0, Candle = 0 }, TrendOff = { Count = 0, Candle = 0 }, Uturn3 = { Count = 0, Candle = 0 }, Uturn4 = { Count = 0, Candle = 0 }, Spring3 = { Count = 0, Candle = 0 }, Spring4 = { Count = 0, Candle = 0 }},
        [RSIs.Name] = { Cross = { Count = 0, Candle = 0 }, Cross50 = { Count = 0, Candle = 0 }, TrendOn = { Count = 0, Candle = 0 }, TrendOff = { Count = 0, Candle = 0 }, Uturn3 = { Count = 0, Candle = 0 }, Uturn4 = { Count = 0, Candle = 0 }, Spring3 = { Count = 0, Candle = 0 }, Spring4 = { Count = 0, Candle = 0 }}},
        [Directions.Down] = { 
        [Prices.Name] = { CrossMA = { Count = 0, Candle = 0 }, Uturn3 = { Count = 0, Candle = 0 }, Uturn4 = { Count = 0, Candle = 0 }},
        [Stochs.Name] = { Cross = { Count = 0, Candle = 0 }, Cross50 = { Count = 0, Candle = 0 }, HSteamer = { Count = 0, Candle = 0 }, VSteamer = { Count = 0, Candle = 0 }, TrendOn = { Count = 0, Candle = 0 }, TrendOff = { Count = 0, Candle = 0 }, Uturn3 = { Count = 0, Candle = 0 }, Uturn4 = { Count = 0, Candle = 0 }, Spring3 = { Count = 0, Candle = 0 }, Spring4 = { Count = 0, Candle = 0 }},
        [RSIs.Name] = { Cross = { Count = 0, Candle = 0 }, Cross50 = { Count = 0, Candle = 0 }, TrendOn = { Count = 0, Candle = 0 }, TrendOff = { Count = 0, Candle = 0 }, Uturn3 = { Count = 0, Candle = 0 }, Uturn4 = { Count = 0, Candle = 0 }, Spring3 = { Count = 0, Candle = 0 }, Spring4 = { Count = 0, Candle = 0 }}},
        Params = { Duration = 2, Steamer = { VerticalDifference = 30, HorizontalDuration = 2 }}}
    --States = { [Directions.Up] = { Trend = { Count = 0, Candle = 0 }},         [Directions.Down] = { Trend = { Count = 0, Candle = 0 }}}

    Index_Candle = 0

    return #Settings.line
end
--#endregion

--==========================================================================
--	OnCalculate
--==========================================================================
function OnCalculate(index_candle)
    -- debug logging
    if (index_candle == 240) or (index_candle == 245) then
        local t = T(index_candle)
        PrintDebugMessage("OnCalculate:", index_candle, t.month, t.day, t.hour, t.min)
    end
    Index_Candle = index_candle
    
    -- set initial values on first candle
    if (index_candle == 1) then
        DataSource = getDataSourceInfo()
        SecInfo = getSecurityInfo(DataSource.class_code, DataSource.sec_code)
        
        SetInitialCounts()
    end

    --#region set prices and indicators for current candle
    -- calculate current prices
    Prices.Open[index_candle] = O(index_candle)
    Prices.Close[index_candle] = C(index_candle)
    Prices.High[index_candle] = H(index_candle)
    Prices.Low[index_candle] = L(index_candle)

    -- calculate current stoch
    if (index_candle == 240) or (index_candle == 245) then
        PrintDebugMessage("Stoch1:", index_candle)
    end
    Stochs.Slow[index_candle], _ = StochSlow(index_candle)
    Stochs.Fast[index_candle], _ = StochFast(index_candle)

    Stochs.Slow[index_candle] = RoundScale(Stochs.Slow[index_candle], SecInfo.scale)
    Stochs.Fast[index_candle] = RoundScale(Stochs.Fast[index_candle], SecInfo.scale)

    Stochs.Delta[index_candle] = (Stochs.Slow[index_candle] ~= nil) and (Stochs.Fast[index_candle] ~= nil) and RoundScale(GetDelta(Stochs.Fast[index_candle], Stochs.Slow[index_candle]), SecInfo.scale) or nil

    if (index_candle == 240) or (index_candle == 245) then
        PrintDebugMessage("Stoch2:", index_candle, Stochs.Slow[index_candle], Stochs.Fast[index_candle], Stochs.Delta[index_candle])
    end

    -- calculate current rsi
    RSIs.Fast[index_candle] = RSIFast(index_candle)
    RSIs.Slow[index_candle] = RSISlow(index_candle)
    RSIs.Fast[index_candle] = RoundScale(RSIs.Fast[index_candle], SecInfo.scale)
    RSIs.Slow[index_candle] = RoundScale(RSIs.Slow[index_candle], SecInfo.scale)

    RSIs.Delta[index_candle] = (RSIs.Fast[index_candle] ~= nil) and (RSIs.Slow[index_candle] ~= nil) and RoundScale(GetDelta(RSIs.Fast[index_candle], RSIs.Slow[index_candle]), SecInfo.scale) or nil

    if (index_candle == 240) or (index_candle == 245) 
    then
        PrintDebugMessage("RSI:", index_candle, RSIs.Slow[index_candle], RSIs.Fast[index_candle], RSIs.Delta[index_candle])
    end

    -- calculate current price channel
    PCs.Top[index_candle], PCs.Bottom[index_candle] = PC(index_candle)

    PCs.Top[index_candle] = RoundScale(PCs.Top[index_candle], SecInfo.scale)
    PCs.Bottom[index_candle] = RoundScale(PCs.Bottom[index_candle], SecInfo.scale)

    PCs.Center[index_candle] = (PCs.Top[index_candle] ~= nil) and (PCs.Bottom[index_candle] ~= nil) and RoundScale((PCs.Bottom[index_candle] + (PCs.Top[index_candle] - PCs.Bottom[index_candle]) / 2), SecInfo.scale) or nil

    PCs.Delta[index_candle] = (Prices.Close[index_candle] ~= nil) and (PCs.Center[index_candle] ~= nil) and RoundScale(GetDelta(Prices.Close[index_candle], PCs.Center[index_candle]), SecInfo.scale) or nil

    if (index_candle == 240) or (index_candle == 245) 
    then
        PrintDebugMessage("PC:", index_candle, PCs.Top[index_candle], PCs.Bottom[index_candle], PCs.Center[index_candle], PCs.Delta[index_candle])
    end
    --#endregion

    ----------------------------------------------------------------------------
    -- I. States
    ----------------------------------------------------------------------------
    --#region   I.1. Signal: Signals[Directions.Down/Up].Price.CrossMA
    --          State: Signals[Down/Up].Price.Trend
    --          Depends on signal: -
    --          State terminates by signals: Reverse self-signal
    --          Terminates by duration: -
    -- check start signal price cross ma up
    if (SignalPriceCrossMA(index_candle, Directions.Up, Prices, PCs.Center)) then
        SetSignal((index_candle-1), Directions.Up, Prices.Name, "CrossMA")
        -- SetState((index_candle-1), Directions.Up, "Trend")

        -- set chart label
        ChartLabels[Prices.Name][index_candle-1] = SetChartLabel((index_candle-1), Directions.Up, Prices.Name, "CrossMA", ChartIcons.Triangle, ChartPermissions[1], DealStages.Start)
    end

    -- check start signal price cross ma down
    if (SignalPriceCrossMA(index_candle, Directions.Down, Prices, PCs.Center)) then
        SetSignal((index_candle-1), Directions.Down, Prices.Name, "CrossMA")
        -- SetState((index_candle-1), Directions.Down, "Trend")

        -- set chart label
        ChartLabels[Prices.Name][index_candle-1] = SetChartLabel((index_candle-1), Directions.Down, Prices.Name, "CrossMA", ChartIcons.Triangle, ChartPermissions[1], DealStages.Start)
    end
    --#endregion
--[[
    ----------------------------------------------------------------------------
    -- II. Elementary Stoch Signals
    ----------------------------------------------------------------------------
    --#region   II.1. Elementary Stoch Signal: Signals[Down/Up].Stochs.Cross
    --          Impulse Signal: Signals[Down/Up].Impulse
    --          Depends on signal: SignalOscCross
    --          Terminates by signals: Reverse self-signal
    --          Terminates by duration: -
    -- check fast stoch cross slow stoch up
    if (SignalOscCross(index_candle, Directions.Up, Stochs)) then
        SetSignal((index_candle-1), Directions.Up, Stochs.Name, "Cross")
        -- SetState((index_candle-1), Directions.Up, "Impulse")
        
        -- set chart label
        ChartLabels[Stochs.Name][index_candle-1] = SetChartLabel((index_candle-1), Directions.Up, Stochs.Name, "Cross", ChartIcons.Romb, ChartPermissions[1], DealStages.Start)
    end
    
    -- check fast stoch cross slow stoch down
    if (SignalOscCross(index_candle, Directions.Down)) then
        SetSignal((index_candle-1), Directions.Down, Stochs.Name, "Cross")
        -- SetState((index_candle-1), Directions.Down, "Impulse")

        -- set chart label
        ChartLabels[Stochs.Name][index_candle-1] = SetChartLabel((index_candle-1), Directions.Down, Stochs.Name, "Cross", ChartIcons.Romb, ChartPermissions[1], DealStages.Start)
    end
    --#endregion

    --#region II.2. Elementary Stoch Signal: Signals[Down/Up].Stochs.Cross50
    --              Impulse Signal: Signals[Down/Up].Impulse
    --              Depends on signal: SignalOscCrossLevel
    --              Terminates by signals: Reverse self-signal
    --              Terminates by duration: -
    -- check slow stoch cross lvl50 up
    if (SignalOscCrossLevel(index_candle, Directions.Up, Stochs.Slow, Stochs.Params.HLines.Center)) then
        SetSignal((index_candle-1), Directions.Up, Stochs.Name, "Cross50")

        -- set chart label
        ChartLabels[Stochs.Name][index_candle-1] = SetChartLabel((index_candle-1), Directions.Up, Stochs.Name, "Cross50", ChartIcons.Triangle, ChartPermissions[1], DealStages.Start)
    end

    -- check slow stoch cross lvl50 down
    if (SignalOscCrossLevel(index_candle, Directions.Down, Stochs.Slow, Stochs.Params.HLines.Center)) then
        SetSignal((index_candle-1), Directions.Down, Stochs.Name, "Cross50")

        -- set chart label
        ChartLabels[Stochs.Name][index_candle-1] = SetChartLabel((index_candle-1), Directions.Down, Stochs.Name, "Cross50", ChartIcons.Triangle, ChartPermissions[1], DealStages.Start)
    end
    --#endregion

    --#region II.3. Elementary Stoch Signal: Signals[Down/Up].Stochs.VSteamer
    --              Enter Signal: Signals[Down/Up]["TrendOn"]/Uturn
    --              Depends on signal: SignalOscVSteamer
    --              Terminates by signals: Reverse self-signal
    --              Terminates by duration: -
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

    ----------------------------------------------------------------------------
    -- III. Elementary RSI Signals
    ----------------------------------------------------------------------------
    --#region III.1. Elementary RSI Signal: Signals[Down/Up].RSIs.Cross
    --               Impulse Signal: Signals[Down/Up].Impulse
    ---              Depends on signal: SignalOscCross
    --               Terminates by signals: Reverse self-signal
    --               Terminates by duration: -
    -- check fast rsi cross slow rsi up
    if (SignalOscCross(index_candle, Directions.Up, RSIs)) then
        SetSignal((index_candle-1), Directions.Up, RSIs.Name, "Cross")

        -- set chart label
        ChartLabels[Stochs.Name][index_candle-1] = SetChartLabel((index_candle-1), Directions.Up, RSIs.Name, "Cross", ChartIcons.Romb, ChartPermissions[1], DealStages.Start)
    end

    -- check fast rsi cross slow rsi down
    if (SignalOscCross(index_candle, Directions.DownRSIs)) then
        SetSignal((index_candle-1), Directions.Down, RSIs.Name, "Cross")

        -- set chart label
        ChartLabels[Stochs.Name][index_candle-1] = SetChartLabel((index_candle-1), Directions.Down, RSIs.Name, "Cross", ChartIcons.Romb, ChartPermissions[1], DealStages.Start)
    end
    --#endregion

    --#region III.2. Elementary RSI Signal: Signals[Down/Up].RSIs.Cross50
    --               Impulse Signal: Signals[Down/Up].Impulse
    ---              Depends on signal: SignalOscCrossLevel
    --               Terminates by signals: Reverse self-signal
    --               Terminates by duration: -
    -- check slow rsi cross lvl50 up
    if (SignalOscCrossLevel(index_candle, Directions.Up, RSIs.Slow, RSIs.Params.HLines.Center)) then
        SetSignal((index_candle-1), Directions.Up, RSIs.Name, "Cross50")

        -- set chart label
        ChartLabels[Stochs.Name][index_candle-1] = SetChartLabel((index_candle-1), Directions.Up, RSIs.Name, "Cross50", ChartIcons.Triangle, ChartPermissions[1], DealStages.Start)
    end

    -- check slow rsi cross lvl50 down
    if (SignalOscCrossLevel(index_candle, Directions.Down, RSIs.Slow, RSIs.Params.HLines.Center)) then
        SetSignal((index_candle-1), Directions.Down, RSIs.Name, "Cross50")

        -- set chart label
        ChartLabels[Stochs.Name][index_candle-1] = SetChartLabel((index_candle-1), Directions.Down, RSIs.Name, "Cross50", ChartIcons.Triangle, ChartPermissions[1], DealStages.Start)

    end
    --#endregion

    --#region III.3. Elementary RSI Signal: Signals[Down/Up].RSIs["TrendOn"]
    --               Enter Signals: Signals[Down/Up]["TrendOn"]
    --               Depends on signal: SignalOscTrendOn
    --               Terminates by signals: Reverse self-signal, SignalOscTrendOff, SignalOscCross
    --               Terminates by duration: Signals.Params.Durations.Elementary
    -- check start signal up trendon - slow rsi enter on uptrend zone
    if (SignalOscTrendOn(index_candle, Directions.Up, RSIs)) then
        SetSignal((index_candle-1), Directions.Up, RSIs.Name, "TrendOn")

        -- set chart label
        ChartLabels[Stochs.Name][index_candle-1] = SetChartLabel((index_candle-1), Directions.Up, RSIs.Name, "TrendOn", ChartIcons.Asterix, ChartPermissions[1], DealStages.Start)
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
                ChartLabels[Stochs.Name][index_candle-1] = SetChartLabel((index_candle-1), Directions.Up, RSIs.Name, "TrendOn", ChartIcons.Cross, ChartPermissions[1], GetMessage(DealStages.End,  "TrendOffDown", duration))

            -- check termination by fast rsi cross slow rsi down
            elseif (SignalOscCross(index_candle, Directions.Down, RSIs)) then
                -- set signal up off
                Signals[Directions.Up][RSIs.Name]["TrendOn"].Candle = 0

                -- set chart label
                ChartLabels[Stochs.Name][index_candle-1] = SetChartLabel((index_candle-1), Directions.Up, RSIs.Name, "TrendOn", ChartIcons.Cross, ChartPermissions[1], GetMessage(DealStages.End, "CrossDown", duration))

            -- process continuation signal up
            else
                -- set chart label
                ChartLabels[Stochs.Name][index_candle] = SetChartLabel(index_candle, Directions.Up, RSIs.Name, "TrendOn", ChartIcons.Asterix, ChartPermissions[1], GetMessage(DealStages.Continue, duration))
            end

        -- check termination by duration signal up
        elseif (duration > Signals.Params.Duration) then
            -- set signal up off
            Signals[Directions.Up][RSIs.Name]["TrendOn"].Candle = 0

            -- set chart label
            ChartLabels[Stochs.Name][index_candle] = SetChartLabel(index_candle, Directions.Up, RSIs.Name, "TrendOn", ChartIcons.Cross, ChartPermissions[1], GetMessage(DealStages.End, "Duration", duration))
        end
    end -- up presence

    -- check start signal down trendon - slow rsi enter on down trend zone
    if (SignalOscTrendOn(index_candle, Directions.Down, RSIs)) then
        SetSignal((index_candle-1), Directions.Down, RSIs.Name, "TrendOn")

        -- set chart label
        ChartLabels[Stochs.Name][index_candle-1] = SetChartLabel((index_candle-1), Directions.Down, RSIs.Name, "TrendOn", ChartIcons.Asterix, ChartPermissions[1], DealStages.Start)
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
                ChartLabels[Stochs.Name][index_candle-1] = SetChartLabel((index_candle-1), Directions.Down, RSIs.Name, "TrendOn", ChartIcons.Cross, ChartPermissions[1], GetMessage(DealStages.End,  "TrendOffUp", duration))

                -- check termination by fast rsi cross slow rsi up
            elseif (SignalOscCross(index_candle, Directions.Up, RSIs)) then
                -- set signal down off
                Signals[Directions.Down][RSIs.Name]["TrendOn"].Candle = 0

                -- set chart label
                ChartLabels[Stochs.Name][index_candle-1] = SetChartLabel((index_candle-1), Directions.Down, RSIs.Name, "TrendOn", ChartIcons.Cross, ChartPermissions[1], GetMessage(DealStages.End, "CrossUp", duration))

            -- process continuation signal down
            else
                -- set chart label
                ChartLabels[Stochs.Name][index_candle] =  SetChartLabel(index_candle, Directions.Down, RSIs.Name, "TrendOn", ChartIcons.Asterix, ChartPermissions[1], GetMessage(DealStages.Continue, duration))
            end

        -- check termination by duration signal down
        elseif (duration > Signals.Params.Duration) then
            -- set signal down off
            Signals[Directions.Down][RSIs.Name]["TrendOn"].Candle = 0

            -- set chart label
            ChartLabels[Stochs.Name][index_candle] =  SetChartLabel(index_candle, Directions.Down, RSIs.Name, "TrendOn", ChartIcons.Cross, ChartPermissions[1], GetMessage(DealStages.End, "Duration", duration))
        end
    end -- down presence
    --#endregion
]]
    --PrintDebugSummary()

    return PCs.Top[index_candle], PCs.Center[index_candle], PCs.Bottom[index_candle]
    -- return Stochs.Slow[index_candle], Stochs.Fast[index_candle]
    -- return RSIs.Slow[index_candle], RSIs.Fast[index_candle]
end

--==========================================================================
--#region	INDICATOR  Price Channel
--==========================================================================
----------------------------------------------------------------------------
-- Price Channel
----------------------------------------------------------------------------
function PriceChannel()
    local Highs = {}
    local Lows = {}
    local Candles = { processed = 0, count = 0 }

    return function (index_candle)
        if (PCs.Params.Period > 0) then
            -- first candle - reinit for start
            if (index_candle == 1) then
                Highs = {}
                Lows = {}
                Candles = { processed = 0, count = 0 }
            end

            if CandleExist(index_candle) then
                -- new candle new processed candle and increased count processed candles
                if (Candles.processed ~= index_candle) then
                    Candles = { processed = index_candle, count = Candles.count + 1 }
                end

                -- insert high and low to circle buffers Highs and Lows
                Highs[Squeeze(Candles.count, PCs.Params.Period - 1) + 1] = H(Candles.processed)
                Lows[Squeeze(Candles.count, PCs.Params.Period - 1) + 1] = L(Candles.processed)

                -- calc and return max results
                if (Candles.count >= PCs.Params.Period) then
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
--#region	INDICATOR STOCH
--==========================================================================
----------------------------------------------------------------------------
--	function Stochastic Oscillator ("SO")
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
    -- idx_chart point to index of real candles on chart/ds, idx_buffer point to candles in cyclic buffer
    local Candles = { idx_chart = 0, idx_buffer = 0 }

    return function (index)
        if (Settings.period_k > 0) and (Settings.period_d > 0) then
            
            -- reinit arrays
            if (index == 1) then
                Highs = {}
                Lows = {}
                Candles.idx_chart = 0
                Candles.idx_buffer = 0 
            end

            if CandleExist(index) then
                if (Candles.idx_chart ~= index) then
                    Candles.idx_chart = index
                    Candles.idx_buffer = Candles.idx_buffer + 1
                end

                -- pointer into cyclic buffer from 1 to period_k
                local idx = Squeeze(Candles.count, Settings.period_k - 1) + 1
                Highs[idx] = H(Candles.idx_chart)
                Lows[idx] = L(Candles.idx_chart)

                local idx_k = Candles.idx_buffer - Settings.period_k
                if (idx_k >= 0)  then
                    local max_high = math.max(unpack(Highs))
                    local max_low = math.min(unpack(Lows))

                    local value_k1 = K_ma1(idx_k + 1, { [idx_k + 1] = C(Candles.idx_chart) - max_low })

                    local value_k2 = K_ma2(idx_k + 1, { [idx_k + 1] = max_high - max_low })

                    local idx_d = Candles.idx_buffer - (Settings.period_k + Settings.shift) + 1
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
--	function EMAi = (EMAi-1*(n-1)+2*Pi) / (n+1)
----------------------------------------------------------------------------
function EMA(Settings)
    local Emas = { previous = nil, current = nil }
    local Candles = { processed = 0, count = 0 }

    return function(index_candle, prices)
        if (index_candle == 1) then
            Emas = { previous = nil, current = nil }
            Candles = { processed = 0, count = 0 }
        end

        if CandleExist(index_candle) then
            if (index_candle ~= Candles.processed) then
                Candles = { processed = index_candle, count = Candles.count + 1 }
                Emas.previous = Emas.current
            end

            if (Candles.count == 1) then
                Emas.current = prices[Candles.processed]
            else
                Emas.current = (Emas.previous * (Settings.period_d - 1) + 2 * prices[Candles.processed]) / (Settings.period_d + 1)
            end

            if (Candles.count >= Settings.period_d) then
                return Emas.current
            end
        end

        return nil
    end
end

----------------------------------------------------------------------------
--	function SMA = sums(Pi) / n
----------------------------------------------------------------------------
function SMA(Settings)
    local Sums = {}
    local Candles = { processed = 0, count = 0 }

    return function (index_candle, prices)
        if (index_candle == 1) then
            Sums = {}
            Candles = { processed = 0, count = 0 }
        end

        if CandleExist(index_candle) then
            if (index_candle ~= Candles.processed) then
                Candles = { processed = index_candle, count = Candles.count + 1 }
            end

            local index1 = Squeeze(Candles.count, Settings.shift)
            local index2 = Squeeze(Candles.count - 1, Settings.shift)
            local index3 = Squeeze(Candles.count - Settings.shift, Settings.shift)

            Sums[index1] = (Sums[index2] or 0) + prices[Candles.processed]

            if (Candles.count >= Settings.shift) then
                return (Sums[index1] - (Sums[index3] or 0)) / Settings.shift
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
    mode = string.sub(string.upper(mode), 1, 1)
    local Settings = {}

    if (mode == "S") then
        Settings.period = RSIs.Params.PeriodSlow
    elseif (mode == "F") then
        Settings.period = RSIs.Params.PeriodFast
    end

    local Ma_up = MMA(Settings)
    local Ma_down = MMA(Settings)

    local Prices = { previous = nil, current = nil}
    local Itterations = { processed = 0, count = 0 }

    return function (index_candle)
        if (index_candle == 1) then
            Itterations = { processed = 0, count = 0 }
        end

        if CandleExist(index_candle) then
            if (index_candle ~= Itterations.processed) then
                Itterations = { processed = index_candle, count = Itterations.count + 1 }
                Prices.previous = Prices.current
            end

            Prices.current = C(Itterations.processed)

            local move_up = 0
            local move_down = 0

            if (Itterations.count > 1) then
                if (Prices.previous < Prices.current) then
                    move_up = Prices.current - Prices.previous
                end

                if (Prices.previous > Prices.current) then
                    move_down = Prices.previous - Prices.current
                end
            end

            local value_up = Ma_up(Itterations.count, { [Itterations.count] = move_up })
            local value_down = Ma_down(Itterations.count, { [Itterations.count] = move_down })

            if (Itterations.count >= Settings.period) then
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
    local Sums = {}
    local Values = { previous = nil, current = nil }
    local Itterations = { processed = 0, count = 0 }

    return function(index_candle, prices)
        if (index_candle == 1) then
            Sums = {}
            Values = { previous = nil, current = nil }
            Itterations = { processed = 0, count = 0 }
        end

        if CandleExist(index_candle) then
            if (index_candle ~= Itterations.processed) then
                Itterations = { processed = index_candle, count = Itterations.count + 1 }
                Values.previous = Values.current
            end

            local index1 = Squeeze(Itterations.count, Settings.period)
            local index2 = Squeeze(Itterations.count - 1, Settings.period)
            local index3 = Squeeze(Itterations.count - Settings.period, Settings.period)

            if (Itterations.count <= (Settings.period + 1)) then
                Sums[index1] = (Sums[index2] or 0) + prices[Itterations.processed]

                if ((Itterations.count == Settings.period) or (Itterations.count == Settings.period + 1)) then
                    Values.current = (Sums[index1] - (Sums[index3] or 0)) / Settings.period
                end
            else
                Values.current = (Values.previous * (Settings.period - 1) + prices[Itterations.processed]) / Settings.period
            end

            if (Itterations.count >= Settings.period) then
                return Values.current
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
    if (CheckDataExist(index, 3, oscs.Slow) and CheckDataExist(index, 3, oscs.Fast)) then

        --PrintDebugMessage("VSteamer", index)

        dev = dev or 0
        local v_diff = vertical_difference or Signals.Params.Steamer.VerticalDifference

        -- true or false
        if (-- oscs move in direction last 3 candles
        (EventMove(index, direction, oscs.Fast, dev) and EventMove(index, direction, oscs.Slow, dev) and EventMove(index-1, direction, oscs.Fast, dev) and EventMove(index-1, direction, oscs.Slow, dev)) and
        -- fast osc ralate slow osc in direction last 3 candles
        (ConditionRelate(direction, oscs.Fast[index-1], oscs.Slow[index-1], dev) and ConditionRelate(direction, oscs.Fast[index-2], oscs.Slow[index-2], dev) and ConditionRelate(direction, oscs.Fast[index-3], oscs.Slow[index-3], dev)) and
        -- delta beetwen osc fast and slow osc less then dev last 3 candles
        ((GetDelta(oscs.Fast[index-1], oscs.Slow[index-1]) <= v_diff) and (GetDelta(oscs.Fast[index-2], oscs.Slow[index-2]) <= v_diff) and (GetDelta(oscs.Fast[index-3], oscs.Slow[index-3]) <= v_diff))) then

            -- set chart label
            ChartLabels[oscs.Name][index-1] = SetChartLabel(T(index-1), GetChartLabelYPos(index-1, direction, oscs.Name), Charts[oscs.Name].Tag, GetChartLabelText(index-1, direction, oscs.Name, "VSteamer", DealStages.Start), ChartIcons.Flash, ChartPermissions[1])

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
    
    if (CheckDataExist(index, (h_dur+2), oscs.Slow) and CheckDataExist(index, (h_dur+2), oscs.Fast)) then
        
        dev = dev or 0

        if (SignalOscCrossLevel(index, direction, oscs.Slow, Stochs.Params.HLines.Center, dev)) then

            -- true or false
            local count
            for count = 0, h_dur do

                if (SignalOscCrossLevel((index-count), direction, oscs.Fast, Stochs.Params.HLines.Center, dev) and
                -- oscs move in direction 2 candles
                (EventMove(oscs.Fast, (index-count), direction, dev) and EventMove(oscs.Slow, index, direction, dev)) and
                -- fast osc ralate slow osc in direction 2 candles
                (ConditionRelate(oscs.Fast[(index-count)-1], oscs.Slow[(index-count)-1], direction, dev) and ConditionRelate(oscs.Fast[index-1], oscs.Slow[index-1], direction, dev))) then

                    -- set chart label
                    ChartLabels[oscs.Name][(index-count)-1] = SetChartLabel(T((index-count)-1), GetChartLabelYPos((index-count)-1, direction, oscs.Name), Charts[oscs.Name].Tag, GetChartLabelText((index-count)-1, direction, oscs.Name, "HSteamer", DealStages.Start), ChartIcons.Flash, ChartPermissions[1])

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
    dev = dev or 0

    if (CheckDataExist(index, 2, oscs.Slow) and CheckDataExist(index, 2, oscs.Fast)) then
        -- true or false
        return EventCross(index, direction, oscs.Fast, oscs.Slow, dev)
    else
        return false
    end
end

--
-- Signal Osc Cross Level
--
function SignalOscCrossLevel(index, direction, oscs, level, dev)
    dev = dev or 0

    if (CheckDataExist(index, 2, oscs.Slow)) then
        -- true or false
        return EventCross(index, direction, {[index-2] = level, [index-1] = level}, oscs.Slow, dev)
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
        if (CheckDataExist(index, 2, RSIs.Slow)) then

            if (direction == Directions.Up) then
                level = RSIs.Params.HLines.TopTrend
            elseif (direction == Directions.Down) then
                level = RSIs.Params.HLines.BottomTrend
            else
                return false
            end

            return SignalOscCrossLevel(index, direction, level, RSIs.Slow, dev)
        -- not enough data
        else
            return false
        end

    -- check for stochastic
    elseif (oscs.Name == Stochs.Name) then
        if (CheckDataExist(index, 2, Stochs.Slow)) then

            if (direction == Directions.Up) then
                level = Stochs.Params.HLines.TopExtreme
            elseif (direction == Directions.Down) then
                level = Stochs.Params.HLines.BottomExtreme
            else
                return false
            end

            return SignalOscCrossLevel(index, direction, level, Stochs.Slow, dev)
        -- not enough data
        else
            return false
        end

    -- check for pc
    elseif (oscs.Name == PCs.Name) then
        if (CheckDataExist(index, 2, PCs.Center) and CheckDataExist(index, 2, Prices.Close)) then

            if (direction == Directions.Up) then
                level = PCs.Top[index-2]
            elseif (direction == Directions.Down) then
                level = PCs.Bottom[index-2]
            else
                return false
            end

            return SignalOscCrossLevel(index, direction, level, Prices.Close, dev)
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
        if (CheckDataExist(index, 2, RSIs.Slow)) then

            if (direction == Directions.Up) then
                level = RSIs.Params.HLines.BottomTrend
            elseif (direction == Directions.Down) then
                level = RSIs.Params.HLines.TopTrend
            end

            return SignalOscCrossLevel(index, direction, level, RSIs.Slow, dev)
        -- not enough data
        else
            return false
        end

    -- chek for stochastic
    elseif (oscs.Name == Stochs.Name) then
        if (CheckDataExist(index, 2, Stochs.Slow)) then

            if (direction == Directions.Up) then
                level = Stochs.Params.HLines.BottomExtreme
            elseif (direction == Directions.Down) then
                level = Stochs.Params.HLines.TopExtreme
            end
            
            return SignalOscCrossLevel(index, direction, level, Stochs.Slow, dev)
        -- not enough data
        else
            return false
        end

    -- chek for pc
    elseif (oscs.Name == PCs.Name) then
        if (CheckDataExist(index, 2, PCs.Center) and CheckDataExist(index, 2, Prices.Close)) then

            if (direction == Directions.Up) then
                level = PCs.Botttom[index-2]
            elseif (direction == Directions.Down) then
                level = PCs.Top[index-2]
            end
            
            return SignalOscCrossLevel(index, direction, level, Prices.Close, dev)
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
    if (CheckDataExist(index, 3, oscs.Slow) and CheckDataExist(index, 3, oscs.Fast) and CheckDataExist(index, 3, oscs.Delta)) then

        dev = dev or 0

        -- true or false
        return ( -- deltas uturn
            EventUturn(index, Directions.Up, oscs.Delta, dev) and
            -- fastosc/slowosc uturn
            EventUturn(index, direction, oscs.Fast, dev) and EventMove(index, direction, oscs.Slow, dev) and
            -- fastosc over slowosc all 3 candles
            (ConditionRelate(direction, oscs.Fast[index-3], oscs.Slow[index-3], dev) and ConditionRelate(direction, oscs.Fast[index-2], oscs.Slow[index-2], dev) and ConditionRelate(direction, oscs.Fast[index-1], oscs.Slow[index-1], dev)))

    -- not enough data
    else
        return false
    end
end

--
-- Signal Osc Uturn with 4 candles
--
function SignalOscUturn4(index, direction, oscs, dev)
    if (CheckDataExist(index, 4, oscs.Slow) and CheckDataExist(index, 4, oscs.Fast) and CheckDataExist(index, 4, oscs.Delta)) then

        dev = dev or 0

        -- true or false
        return ( -- deltas uturn
            (EventMove((index-2), Directions.Down, osc.Delta, dev) and EventMove(index, Directions.Up, osc.Delta, dev)) and
            -- fastosc/slowosc uturn
            (EventMove((index-2), Reverse(direction), osc.Fast, dev) and EventMove(index, direction, osc.Fast, dev) and EventMove(index, direction, osc.Slow, dev)) and
            -- fastosc over slowosc all 4 candles
            (ConditionRelate(direction, osc.Fast[index-4], osc.Slow[index-4], dev) and ConditionRelate(direction, osc.Fast[index-3], osc.Slow[index-3], dev) and ConditionRelate(direction, osc.Fast[index-2], osc.Slow[index-2], dev) and ConditionRelate(direction, osc.Fast[index-1], osc.Slow[index-1], dev)))

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
    if (CheckDataExist(index, 1, prices.Open) and CheckDataExist(index, 2, prices.Close) and CheckDataExist(index, 2, mas)) then

        dev = dev or 0

        return (-- candle up/down
                ConditionRelate(direction, prices.Close[index-1], prices.Open[index-1], dev) and
                -- candle cross ma up/down
                EventCross(index, direction, prices.Close, mas, dev))

    -- not enough data
    else
        return false
    end
end

--
-- Signal Price Uturn with 3 candles
--
function SignalPriceUturn3(index, direction, prices, mas, dev)
    if (CheckDataExist(index, 3, prices.Open) and CheckDataExist(index, 3, prices.Close) and CheckDataExist(index, 3, prices.High) and CheckDataExist(index, 3, prices.Low) and CheckDataExist(index, 3, mas.Central) and CheckDataExist(index, 3, mas.Delta)) then

        dev = dev or 0

        local pre_result = 
            -- one first candle contr-trend, one last candle pro-trend
            ConditionRelate(direction, prices.Open[index-3], prices.Close[index-3], dev) and ConditionRelate(direction, prices.Close[index-1], prices.Open[index-1], dev) and
            -- prices.close uturn
            EventUturn(index, direction, prices.Close, dev) and
            -- delta uturn with delta min at uturn top
            EventUturn(index, Directions.Up, mas.Delta, dev) and
            -- ma move pro-trend 3 last candles
            (SignalIsMove(index, direction, mas.Central, dev) or EventFlat(index, mas.Central, dev)) and  (SignalIsMove((index-1), direction, mas.Central, dev) or EventFlat((index-1), mas.Central, dev))

        if (direction == Directions.Up) then
            return (pre_result and
                -- strength condition
                (prices.Close[index-1] >= prices.Close[index-2]) and (prices.Close[index-1] >= prices.Close[index-3]))

        elseif (direction == Directions.Down) then
            return (pre_result and
                -- strength condition
                (prices.Close[index-2] >= prices.Close[index-1]) and (prices.Close[index-3] >= prices.Close[index-1]))
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
    if (CheckDataExist(index, 4, prices.Open) and CheckDataExist(index, 4, prices.Close) and CheckDataExist(index, 4, prices.High) and CheckDataExist(index, 4, prices.Low) and CheckDataExist(index, 4, mas.Central) and CheckDataExist(index, 4, mas.Delta)) then

        dev = dev or 0

        local pre_result = 
        -- one first candle contr-trend, one last candle pro-trend
        ConditionRelate(direction, prices.Open[index-4], prices.Close[index-4], dev) and ConditionRelate(direction, prices.Close[index-1], prices.Open[index-1], dev) and
        -- price.close uturn
        EventMove((index-2), Reverse(direction), prices.Close, dev) and EventMove(index, direction, prices.Close, dev) and
        -- delta min at top uturn
        EventMove((index-2), Directions.Down, mas.Delta, dev) and EventMove(index, Directions.Up, mas.Delta, dev) and
        -- ma move 4 last candles up
        (SignalIsMove(index, direction, mas.Central, dev) or EventFlat(index, mas.Central, dev)) and
        (SignalIsMove((index-1), direction, mas.Central, dev) or EventFlat((index-1), mas.Central, dev)) and
        (SignalIsMove((index-2), direction, mas.Central, dev) or EventFlat((index-2), mas.Central, dev))

    if (direction == Directions.Up) then
        return (pre_result and
            -- strength condition
            (prices.Close[index-1] >= prices.Close[index-2]) and (prices.Close[index-1] >= prices.Close[index-3]) and (prices.Close[index-1] >= prices.Close[index-4]))

        elseif (direction == Directions.Down) then
            return (pre_result and
            -- strength condition
            (prices.Close[index-2] >= prices.Close[index-1]) and (prices.Close[index-3] >= prices.Close[index-1]) and (prices.Close[index-4] >= prices.Close[index-1]))
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
    --PrintDebugMessage("EventFlat", index)
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
-- function GetDelta    return abs difference between values
----------------------------------------------------------------------------
function GetDelta(value1, value2)
    if ((value1 == nil) or (value2 == nil)) then
        return nil
    end
    if (type(value1) ~= "number" or type(value2) ~= "number") then
        PrintDebugMessage("fromGetDelta", Index_Candle, value1, value2)
    end
    return math.abs(value1 - value2)
end

----------------------------------------------------------------------------
-- function Squeeze return number from 0 (if index start from 1) to period and then again from 0 (index == period) pointer in cycylic buffer
----------------------------------------------------------------------------
function Squeeze(index, period)
    return math.fmod(index - 1, period + 1)
end

----------------------------------------------------------------------------
-- function RoundScale  return value with requred numbers after digital point
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
--[[ function SetState(index, direction, signal_name)
    -- set state up/down off
    States[Reverse(direction)][signal_name].Candle = 0

    -- set state down/up on
    States[direction][signal_name].Count = States[direction][signal_name].Count + 1
    States[direction][signal_name].Candle = index
end]]

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
            table.insert(tmessage, type(args[count]) == "string" and args[count] or tostring(args[count]))
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
        message(smessage)
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
function GetChartLabelText(index, direction, indicator_name, signal_name, text)
    
    local dir = (direction == Directions.Up) and "L" or "S"

    return GetMessage(dir .. indicator_name .. signal_name, Signals[direction][indicator_name][signal_name].Count, index, Signals[direction][indicator_name][signal_name].Candle, text)
end

----------------------------------------------------------------------------
-- function GetChartLabelYPos
--todo make cyclic variable for several levels of y position
----------------------------------------------------------------------------
function GetChartLabelYPos(index, direction, indicator_name)
    local position_y
    local sign = (direction == Directions.Up) and -1 or 1 
    
    -- y pos for price chart
    if (indicator_name == Prices.Name) then
        position_y = Prices.Low[index] + sign * ChartParams[Prices.Name].Step * SecInfo.min_price_step

    -- y pos for stoch chart
    elseif (indicator_name == Stochs.Name) then
        position_y = Stochs.Slow[index] * (100 + sign * ChartParams[Stochs.Name].Step) / 100

    -- y pos for rsi chart
    elseif (indicator_name == RSIs.Name) then
        position_y = RSIs.Slow[index] * (100 + sign * ChartParams[RSIs.Name].Step) / 100
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
function SetChartLabel(index, direction, indicator_name, signal_name, icon, signal_grade, text)
    -- check signal level and chart levels
    if CheckChartPermission(indicator_name, signal_grade) then

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
        ChartLabels.Params.TEXT = GetChartLabelText(index, direction, indicator_name, signal_name, text)

        -- set chart label return id
        return AddLabel(chart_tag, ChartLabels.Params)

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
-- function PrintDebugSummary(number)
--     if (index_candle == number) then
--         PrintDebugMessage("===Enter Up===", "TrendOn", Signals[Directions.Up]["TrendOn"].Count, "Uturn", Signals[Directions.Up].Uturn.Count, "Spring1", Signals[Directions.Up].Spring1.Count, "Spring2", Signals[Directions.Up].Spring2.Count)
--         PrintDebugMessage("Complex Up", "Trend", Signals[Directions.Up].Trend.Count, "Impulse", Signals[Directions.Up].Impulse.Count, "Enter", Signals[Directions.Up].Enter.Count)
--         PrintDebugMessage("Prices Up", "CrossMA", Signals[Directions.Up].Prices.CrossMA.Count, "Uturn3", Signals[Directions.Up].Prices.Uturn3.Count, "Uturn4", Signals[Directions.Up].Prices.Uturn4.Count)
--         PrintDebugMessage("Stochs Up", "Cross", Signals[Directions.Up].Stochs.Cross.Count, "Cross50", Signals[Directions.Up].Stochs.Cross50.Count, "Uturn3", Signals[Directions.Up].Stochs.Uturn3.Count, "Uturn4", Signals[Directions.Up].Stochs.Uturn4.Count, "Spring3", Signals[Directions.Up].Stochs.Spring3.Count, "Spring4", Signals[Directions.Up].Stochs.Spring4.Count, "VSteamer", Signals[Directions.Up].Stochs.VSteamer.Count, "HSteamer", Signals[Directions.Up].Stochs.HSteamer.Count)
--         PrintDebugMessage("RSIs Up", "Cross", Signals[Directions.Up].RSIs.Cross.Count, "Cross50", Signals[Directions.Up].RSIs.Cross50.Count, "Uturn3", Signals[Directions.Up].RSIs.Uturn3.Count, "Uturn4", Signals[Directions.Up].RSIs.Uturn4.Count, "Spring3", Signals[Directions.Up].RSIs.Spring3.Count, "Spring4", Signals[Directions.Up].RSIs.Spring4.Count, "TrendOn", Signals[Directions.Up].RSIs["TrendOn"].Count)
--
--         PrintDebugMessage("===Enter Down", "TrendOn", Signals[Directions.Down]["TrendOn"].Count, "Uturn", Signals[Directions.Down].Uturn.Count, "Spring1", Signals[Directions.Down].Spring1.Count, "Spring2", Signals[Directions.Down].Spring2.Count)
--         PrintDebugMessage("Complex Down", "Trend", Signals[Directions.Down].Trend.Count, "Impulse", Signals[Directions.Down].Impulse.Count, "Enter", Signals[Directions.Down].Enter.Count)
--         PrintDebugMessage("Prices Down", "CrossMA", Signals[Directions.Down].Prices.CrossMA.Count, "Uturn3", Signals[Directions.Down].Prices.Uturn3.Count, "Uturn4", Signals[Directions.Down].Prices.Uturn4.Count)
--         PrintDebugMessage("Stochs Down", "Cross", Signals[Directions.Down].Stochs.Cross.Count, "Cross50", Signals[Directions.Down].Stochs.Cross50.Count, "Uturn3", Signals[Directions.Down].Stochs.Uturn3.Count, "Uturn4", Signals[Directions.Down].Stochs.Uturn4.Count, "Spring3", Signals[Directions.Down].Stochs.Spring3.Count, "Spring4", Signals[Directions.Down].Stochs.Spring4.Count, "VSteamer", Signals[Directions.Down].Stochs.VSteamer.Count, "HSteamer", Signals[Directions.Down].Stochs.HSteamer.Count)
--         PrintDebugMessage("RSIs Down", "Cross", Signals[Directions.Down].RSIs.Cross.Count, "Cross50", Signals[Directions.Down].RSIs.Cross50.Count, "Uturn3", Signals[Directions.Down].RSIs.Uturn3.Count, "Uturn4", Signals[Directions.Down].RSIs.Uturn4.Count, "Spring3", Signals[Directions.Down].RSIs.Spring3.Count, "Spring4", Signals[Directions.Down].RSIs.Spring4.Count, "TrendOn", Signals[Directions.Down].RSIs["TrendOn"].Count)
--     end
-- end
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
