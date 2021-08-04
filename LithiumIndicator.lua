--==========================================================================
--	Indicator Lithium, 2021 (c) FEK
--==========================================================================
--todo convert RoundScale(..., 4) to RoundScale(..., values_after_point)
--// func AddLabel use Labels array
--todo create func CheckElementarySignal
--todo move long/short checking signals to diferent branch
--todo check price/osc events uturn3/4
--todo make code for elementary price/osc uturin3/4
--todo make code for complex signals

----------------------------------------------------------------------------
--#region	Settings
----------------------------------------------------------------------------
Settings = { Name = "FEK_LITHIUM",
			-- lines on main chart
			line = {{ Name = "PCHigh", Type = TYPE_LINE, Color = RGB(221, 44, 44) },
					{ Name = "PCMiddle", Type = TYPE_LINE,	Color = RGB(0, 206, 0) },
					{ Name = "PCLow", Type = TYPE_LINE, Color = RGB(0, 162, 232) }}}
--#endregion

--==========================================================================
--#region	Init
--==========================================================================
function Init()
	-- indicators data arrays and params
	Stochs = { Name = "Stoch", Fast = {}, Slow = {}, Delta = {}, Params = { HLines = { Top = 80, Center = 50, Bottom = 20 }, Slow = { PeriodK = 10, Shift = 3, PeriodD = 1 }, Fast = { PeriodK = 5, Shift = 2, PeriodD = 1 }}}
	Prices = { Name = "Price", Open = {}, Close = {}, High = {}, Low = {}}
	RSIs = { Name = "RSI", Fast = {}, Slow = {}, Delta = {}, Params = { HLines = { Top = 80, TopTrend = 60, Center = 50, BottomTrend = 40, Bottom = 20 }, PeriodSlow = 14, PeriodFast = 9 }}
	PriceChannels = { Name = "PC", Top = {}, Bottom = {}, Center = {}, Delta = {}, Params = { Period = 20 }}

	-- directions for signals, labels and deals
	Directions = { Up = "L", Down = "S" }

	-- levels to show labels on charts
	Levels = { 1, 2, 4, 8 }

	-- tags for charts to show labels and steps for text labels on charts
	Charts = { [Prices.Name]  = { Tag = GetChartTag(Prices.Name), Step = 15, Level = Levels[1] + Levels[3] },	-- FEK_LITHIUMPrice
				[Stochs.Name] = { Tag = GetChartTag(Stochs.Name), Step = 10, Level = Levels[4] }, -- FEK_LITHIUMStoch
				[RSIs.Name] = { Tag = GetChartTag(RSIs.Name), Step = 5, Level = Levels[2] }}		-- FEK_LITHIUMRSI

	-- chart labels ids
	Labels = { [Prices.Name] = {}, [Stochs.Name] = {}, [RSIs.Name] = {}}

	-- chart label icons
	Icons = { Arrow = "A", Point = "P", Triangle = "T", Cross = "C", Romb = "R", Plus = "L", Flash = "F", Asterix = "X",
				BigArrow = "W", BigPoint = "N", BigTriangle = "E", BigCross = "S", BigRomb = "B", BigPlus = "U" }

	-- chart labels default params
	LabelParams = { TRANSPARENCY = 0, TRANSPARENT_BACKGROUND = 1, FONT_FACE_NAME = "Arial", FONT_HEIGHT = 8 }

	-- get script path
	ScriptPath = getScriptPath()

	-- get icons for current theme
	if (isDarkTheme()) then
		IconPath = ScriptPath .. "\\black_theme\\"
		LabelParams.R = 255
		LabelParams.G = 255
		LabelParams.B = 255
	else
		IconPath = ScriptPath .. "\\white_theme\\"
		LabelParams.R = 0
		LabelParams.G = 0
		LabelParams.B = 0
	end

	-- indicators function
	FuncStochSlow = Stoch("SLOW")
	FuncStochFast = Stoch("FAST")
	FuncRSISlow = RSI("SLOW")
	FuncRSIFast = RSI("FAST")
	FuncPC = PriceChannel()

	-- signals start candles and counts
	Signals = {	[Directions.Up] = { [Prices.Name] = { CrossMA= { Count = 0, Candle = 0 }}, 
			[Stochs.Name] = { Cross = { Count = 0, Candle = 0 }, Cross50 = { Count = 0, Candle = 0 }, HSteamer = { Count = 0, Candle = 0 }, VSteamer = { Count = 0, Candle = 0 }}, 
			[RSIs.Name] = { Cross = { Count = 0, Candle = 0 }, Cross50 = { Count = 0, Candle = 0 }, TrendOn = { Count = 0, Candle = 0 }}}, 
			[Directions.Down] = { [Prices.Name] = { CrossMiddlePC = { Count = 0, Candle = 0 }}, 
			[Stochs.Name] = { Cross = { Count = 0, Candle = 0 }, Cross50 = { Count = 0, Candle = 0 }, HSteamer = { Count = 0, Candle = 0 }, VSteamer = { Count = 0, Candle = 0 }},
			[RSIs.Name] = { Cross = { Count = 0, Candle = 0 }, Cross50 = { Count = 0, Candle = 0 }, TrendOn = { Count = 0, Candle = 0 }}},
			Params = { Durations = { Elementary = 4, Enter = 3 }, Steamer = { Dev = 30, Duration = 2 }}} 

	return #Settings.line
end
--#endregion

--==========================================================================
--	OnCalculate
--==========================================================================
function OnCalculate(index_candle)	
    --	if (index_candle> 3000) then
	-- 	PrintDebugMessage("canle", index_candle, T(index_candle).day, T(index_candle).hour, T(index_candle).min)

	if (index_candle == 1) then
		DataSource = getDataSourceInfo()
		SecInfo = getSecurityInfo(DataSource.class_code, DataSource.sec_code)

		--#region	init Signals Candles and Counts
		-- up signals
		Signals[Directions.Up].Prices.CrossMA.Count = 0
		Signals[Directions.Up].Prices.CrossMA.Candle = 0

		Signals[Directions.Up].Stochs.Cross.Count = 0
		Signals[Directions.Up].Stochs.Cross.Candle = 0
		Signals[Directions.Up].Stochs.Cross50.Count = 0
		Signals[Directions.Up].Stochs.Cross50.Candle = 0
		Signals[Directions.Up].Stochs.HSteamer.Count = 0
		Signals[Directions.Up].Stochs.HSteamer.Candle = 0
		Signals[Directions.Up].Stochs.VSteamer.Count = 0
		Signals[Directions.Up].Stochs.VSteamer.Candle = 0

		Signals[Directions.Up].RSIs.Cross.Count = 0
		Signals[Directions.Up].RSIs.Cross.Candle = 0
		Signals[Directions.Up].RSIs.Cross50.Count = 0
		Signals[Directions.Up].RSIs.Cross50.Candle = 0
		Signals[Directions.Up].RSIs.TrendOn.Count = 0
		Signals[Directions.Up].RSIs.TrendOn.Candle = 0

		-- down signals
		Signals[Directions.Down].Prices.CrossMiddlePC.Count = 0
		Signals[Directions.Down].Prices.CrossMiddlePC.Candle = 0

		Signals[Directions.Down].Stochs.Cross.Count = 0
		Signals[Directions.Down].Stochs.Cross.Candle = 0
		Signals[Directions.Down].Stochs.Cross50.Count = 0
		Signals[Directions.Down].Stochs.Cross50.Candle = 0
		Signals[Directions.Down].Stochs.HSteamer.Count = 0
		Signals[Directions.Down].Stochs.HSteamer.Candle = 0
		Signals[Directions.Down].Stochs.VSteamer.Count = 0
		Signals[Directions.Down].Stochs.VSteamer.Candle = 0

		Signals[Directions.Down].RSIs.Cross.Count = 0
		Signals[Directions.Down].RSIs.Cross.Candle = 0
		Signals[Directions.Down].RSIs.Cross50.Count = 0
		Signals[Directions.Down].RSIs.Cross50.Candle = 0
		Signals[Directions.Down].RSIs.TrendOn.Count = 0
		Signals[Directions.Down].RSIs.TrendOn.Candle = 0 
		--#endregion
	end

	--#region	get prices and indicators for current candle
	-- calculate current prices
	Prices.Open[index_candle] = O(index_candle)
	Prices.Close[index_candle] = C(index_candle)
	Prices.High[index_candle] = H(index_candle)
	Prices.Low[index_candle] = L(index_candle)

	-- calculate current stoch
	Stochs.Slow[index_candle], _ = FuncStochSlow(index_candle)
	Stochs.Fast[index_candle], _ = FuncStochFast(index_candle)
	Stochs.Slow[index_candle] = RoundScale(Stochs.Slow[index_candle], 4)
	Stochs.Fast[index_candle] = RoundScale(Stochs.Fast[index_candle], 4)

	-- calculate current rsi
	RSIs.Fast[index_candle] = FuncRSIFast(index_candle)
	RSIs.Slow[index_candle] = FuncRSISlow(index_candle)
	RSIs.Fast[index_candle] = RoundScale(RSIs.Fast[index_candle], 4)
	RSIs.Slow[index_candle] = RoundScale(RSIs.Slow[index_candle], 4)

	-- calculate current price channel
	PriceChannels.Top[index_candle], PriceChannels.Bottom[index_candle] = FuncPC(index_candle)
	PriceChannels.Top[index_candle] = RoundScale(PriceChannels.Top[index_candle], 4) 
	PriceChannels.Bottom[index_candle] = RoundScale(PriceChannels.Bottom[index_candle], 4)
	PriceChannels.Center[index_candle] = ((PriceChannels.Top[index_candle] ~= nil) and (PriceChannels.Bottom[index_candle] ~= nil)) and RoundScale((PriceChannels.Bottom[index_candle] + (PriceChannels.Top[index_candle] + PriceChannels.Bottom[index_candle]) / 2), 4)
	PriceChannels.Delta[index_candle] = ((Prices.Close[index_candle] ~= nil) and (PriceChannels.Center[index_candle] ~= nil)) and RoundScale(GetDelta(Prices.Close[index_candle], PriceChannels.Center[index_candle]), 4)

	-- calculate current deltas
	Stochs.Delta[index_candle] = ((Stochs.Slow[index_candle] ~= nil) and (Stochs.Fast[index_candle] ~= nil)) and RoundScale(GetDelta(Stochs.Fast[index_candle], Stochs.Slow[index_candle]), 4)
	RSIs.Delta[index_candle] = ((RSIs.Fast[index_candle]~= nil) and (RSIs.Slow[index_candle] ~= nil)) and RoundScale(GetDelta(RSIs.Fast[index_candle], RSIs.Slow[index_candle]), 4)
	--#endregion

	----------------------------------------------------------------------------
	--	I. Elementary Price Signals
	----------------------------------------------------------------------------
	--#region	I.1. Elementary Price Signal: Signals[Directions.Down/Up].Prices.CrossMA
	--				Trend Signal: Signals[Directions.Down/Up].Trend
	--				Depends on signal: -
	--				Terminates by signals: Reverse self-signal
	--				Terminates by duration: -
	-- check start elementary signal price cross ma up 
	if (SignalPriceCrossMA(Prices, PriceChannels.Center, index_candle, Directions.Up)) then
		-- set elementary down signal off
		Signals[Directions.Down][Prices.Name].CrossMA.Candle = 0
		-- set elementary up signal on
		Signals[Directions.Up][Prices.Name].CrossMA.Count = Signals[Directions.Up][Prices.Name].CrossMA.Count + 1
		Signals[Directions.Up][Prices.Name].CrossMA.Candle = index_candle - 1

		-- set chart label
		Labels[Prices.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (Prices.Low[index_candle-1] - Charts[Prices.Name].Step * SecInfo.min_price_step), Charts[Prices.Name].Tag, "LPriceCrossMA|Start|" .. tostring(Signals[Directions.Up][Prices.Name].CrossMA.Count).."|" .. (index_candle-1) .. "|" ..Signals[Directions.Up][Prices.Name].CrossMA.Candle, Icons.Arrow, Levels[1])
	end

	-- check start elementary signal price cross ma down 
	if (SignalPriceCrossMA(Prices, PriceChannels.Center, index_candle, Directions.Down)) then
		-- set elementary up signal off
		Signals[Directions.Up][Prices.Name].CrossMA.Candle = 0
		-- set elementary down signal on
		Signals[Directions.Down][Prices.Name].CrossMA.Count = Signals[Directions.Down][Prices.Name].CrossMA.Count + 1
		Signals[Directions.Down][Prices.Name].CrossMA.Candle = index_candle - 1

		-- set chart label
		Labels[Prices.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (Prices.High[index_candle-1] + Charts[Prices.Name].Step * SecInfo.min_price_step), Charts[Prices.Name].Tag, "SPriceCrossMA|Start|" .. tostring(Signals[Directions.Down][Prices.Name].CrossMA.Count) .. "|" .. (index_candle-1) .. "|" .. Signals[Directions.Down][Prices.Name].CrossMA.Candle, Icons.Arrow, Levels[1])
	end
	--#endregion

	----------------------------------------------------------------------------
	--	II. Elementary Stoch Signals
	----------------------------------------------------------------------------
	--#region	II.1. Elementary Stoch Signal: Signals[Directions.Down/Up].Stochs.Cross
	--				Impulse Signal: Signals[Directions.Down/Up].Impulse
	--				Depends on signal: SignalOscCross
	--				Terminates by signals: Reverse self-signal
	--				Terminates by duration: -
	-- check fast stoch cross slow stoch up
		if (SignalOscCross(Stochs, index_candle, Directions.Up)) then
		-- set elementary down signal off
		Signals[Directions.Down][Stochs.Name].Cross.Candle = 0
		-- set elementary up signal on
		Signals[Directions.Up][Stochs.Name].Cross.Candle = index_candle - 1
		Signals[Directions.Up][Stochs.Name].Cross.Count = Signals[Directions.Up][Stochs.Name].Cross.Count + 1

		-- set chart label
		Labels[Stochs.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (Stochs.Slow[index_candle-1] * (100 - Charts[Stochs.Name].Step) / 100), Charts[Stochs.Name].Tag, "LStochCross|Start|" .. tostring(Signals[Directions.Up][Stochs.Name].Cross.Count) .. "|" .. (index_candle-1), Icons.Triangle, Levels[1])
	end

	-- check fast stoch cross slow stoch down
	if (SignalOscCross(Stochs, index_candle, Directions.Down)) then
		-- set elementary down signal off
		Signals[Directions.Up][Stochs.Name].Cross.Candle = 0
		-- set elementary up signal on
		Signals[Directions.Down][Stochs.Name].Cross.Candle = index_candle - 1
		Signals[Directions.Down][Stochs.Name].Cross.Count = Signals[Directions.Down][Stochs.Name].Cross.Count + 1

		-- set chart label
		Labels[Stochs.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (Stochs.Slow[index_candle-1] * (100 + Charts[Stochs.Name].Step) / 100), Charts[Stochs.Name].Tag, "SStochCross|Start|" .. tostring(Signals[Directions.Down][Stochs.Name].Cross.Count) .. "|" .. (index_candle-1), Icons.Triangle, Levels[1])
	end
	--#endregion

	--#region	II.2. Elementary Stoch Signal: Signals[Directions.Down/Up].Stochs.Cross50
	--				Impulse Signal: Signals[Directions.Down/Up].Impulse
	--				Depends on signal: SignalOscCrossLevel
	--				Terminates by signals: Reverse self-signal
	--				Terminates by duration: -
	-- check slow stoch cross lvl50 up
	if (SignalOscCrossLevel(Stochs.Slow, Stochs.Params.HLines.Center, index_candle, Directions.Up)) then
		-- set elementary down signal off
		Signals[Directions.Down][Stochs.Name].Cross50.Candle = 0
		-- set elementary up signal on
		Signals[Directions.Up][Stochs.Name].Cross50.Candle = index_candle - 1
		Signals[Directions.Up][Stochs.Name].Cross50.Count = Signals[Directions.Up][Stochs.Name].Cross50.Count + 1

		-- set chart label
		Labels[Stochs.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (Stochs.Slow[index_candle-1] * (100 - 2 * Charts[Stochs.Name].Step) / 100), Charts[Stochs.Name].Tag, "LStochCross50|Start|" .. tostring(Signals[Directions.Up][Stochs.Name].Cross50.Count) .. "|" .. (index_candle-1), Icons.Arrow, Levels[1])
	end

	-- check slow stoch cross lvl50 down
	if (SignalOscCrossLevel(Stochs.Slow, Stochs.Params.HLines.Center, index_candle, Directions.Down)) then
		-- set elementary up signal off
		Signals[Directions.Up][Stochs.Name].Cross50.Candle = 0
		-- set elementary down signal on
		Signals[Directions.Down][Stochs.Name].Cross50.Candle = index_candle - 1
		Signals[Directions.Down][Stochs.Name].Cross50.Count = Signals[Directions.Down][Stochs.Name].Cross50.Count + 1

		Labels[Stochs.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (Stochs.Slow[index_candle-1] * (100 + 2 * Charts[Stochs.Name].Step) / 100), Charts[Stochs.Name].Tag,  "SStochCross50|Start|" .. tostring(Signals[Directions.Down][Stochs.Name].Cross50.Count) .. "|" .. (index_candle-1), Icons.Arrow, Levels[1])
	end
	--#endregion

	-- #region	II.3. Elementary Stoch Signal: Signals[Directions.Down/Up].Stochs.Steamer
	--				Enter Signal: Signals[Directions.Down/Up].TrendOn/Uturn
	--				Depends on signal: SignalOscHorSteamer, SignalOscVerSteamer
	--				Terminates by signals:
	--				Terminates by duration:
	-- check stoch steamer up
	if (SignalOscVSteamer(Stochs, index_candle, Directions.Up)) then
		-- set elementary down signal off
		Signals[Directions.Down][Stochs.Name].VSteamer.Candle = 0
		-- set elementary up signal on
		Signals[Directions.Up][Stochs.Name].VSteamer.Candle = index_candle - 1
		Signals[Directions.Up][Stochs.Name].VSteamer.Count = Signals[Directions.Up][Stochs.Name].VSteamer.Count + 1

		-- set chart label
		Labels[Stochs.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (Stochs.Slow[index_candle-1] * (100 - 3 * Charts[Stochs.Name].Step) / 100), Charts[Stochs.Name].Tag, "LStochVSteamer|" .. tostring(Signals[Directions.Up][Stochs.Name].VSteamer.Count), Icons.Triangle, Levels[2])
	end

	-- check stoch steamer down
	if (SignalOscVSteamer(Stochs, index_candle, Directions.Down)) then
		-- set elementary up signal off
		Signals[Directions.Up][Stochs.Name].VSteamer.Candle = 0
		-- set elementary down signal on
		Signals[Directions.Down][Stochs.Name].VSteamer.Candle = index_candle - 1
		Signals[Directions.Down][Stochs.Name].VSteamer.Count = Signals[Directions.Down][Stochs.Name].VSteamer.Count + 1

		-- set chart label
		Labels[Stochs.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (Stochs.Slow[index_candle-1] * (100 + 3 * Charts[Stochs.Name].Step) / 100), Charts[Stochs.Name].Tag, "SStochVSteamer|" .. tostring(Signals[Directions.Down][Stochs.Name].VSteamer.Count), Icons.Triangle, Levels[2])
	end

	-- check stoch steamer up
	if (SignalOscHSteamer(Stochs, index_candle, Directions.Up)) then
		-- set elementary down signal off
		Signals[Directions.Down][Stochs.Name].HSteamer.Candle = 0
		-- set elementary up signal on
		Signals[Directions.Up][Stochs.Name].HSteamer.Candle = index_candle - 1
		Signals[Directions.Up][Stochs.Name].HSteamer.Count = Signals[Directions.Up][Stochs.Name].HSteamer.Count + 1

		-- set chart label
		Labels[Stochs.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (Stochs.Slow[index_candle-1] * (100 - 4 * Charts[Stochs.Name].Step) / 100), Charts[Stochs.Name].Tag, "LStochHSteamer|" .. tostring(Signals[Directions.Up][Stochs.Name].HSteamer.Count) .. "|" .. tostring(index_candle-1), Icons.Romb, Levels[2])
	end
	
	-- check stoch steamer down
	if (SignalOscHSteamer(Stochs, index_candle, Directions.Down)) then
		-- set elementary up signal off
		Signals[Directions.Up][Stochs.Name].HSteamer.Candle = 0
		-- set elementary down signal on
		Signals[Directions.Down][Stochs.Name].HSteamer.Candle = index_candle - 1
		Signals[Directions.Down][Stochs.Name].HSteamer.Count = Signals[Directions.Down][Stochs.Name].HSteamer.Count + 1

		-- set chart label
		Labels[Stochs.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (Stochs.Slow[index_candle-1] * (100 + 4 * Charts[Stochs.Name].Step) / 100), Charts[Stochs.Name].Tag, "SStochHSteamer|" .. tostring(Signals[Directions.Down][Stochs.Name].HSteamer.Count) .. "|" .. tostring(index_candle-1), Icons.Romb, Levels[2])
	end 
	--#endregion 

	----------------------------------------------------------------------------
	--	III. Elementary RSI Signals
	----------------------------------------------------------------------------
	--#region	III.1. Elementary RSI Signal: Signals[Directions.Down/Up].RSIs.Cross
	--				Impulse Signal: Signals[Directions.Down/Up].Impulse
	---				Depends on signal: SignalOscCross
	--				Terminates by signals: Reverse self-signal
	--				Terminates by duration: -
	-- check fast rsi cross slow rsi up
	if (SignalOscCross(RSIs, index_candle, Directions.Up)) then
		-- set elementary down signal off
		Signals[Directions.Down][RSIs.Name].Cross.Candle = 0
		-- set elementary up signal on
		Signals[Directions.Up][RSIs.Name].Cross.Candle = index_candle - 1
		Signals[Directions.Up][RSIs.Name].Cross.Count = Signals[Directions.Up][RSIs.Name].Cross.Count + 1

		-- set chart label
		Labels[RSIs.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (RSIs.Slow[index_candle-1] * (100 - Charts[RSIs.Name].Step) / 100), Charts[RSIs.Name].Tag, "LRSICross|Start|" .. tostring(Signals[Directions.Up][RSIs.Name].Cross.Count) .. "|" .. (index_candle-1), Icons.Triangle, Levels[1])
	end

	-- check fast rsi cross slow rsi down
	if (SignalOscCross(RSIs, index_candle, Directions.Down)) then
		-- set elementary down signal off
		Signals[Directions.Up][RSIs.Name].Cross.Candle = 0
		-- set elementary up signal on
		Signals[Directions.Down][RSIs.Name].Cross.Candle = index_candle - 1
		Signals[Directions.Down][RSIs.Name].Cross.Count = Signals[Directions.Down][RSIs.Name].Cross.Count + 1

		-- set chart label
		Labels[RSIs.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (RSIs.Slow[index_candle-1] * (100 + Charts[RSIs.Name].Step) / 100), Charts[RSIs.Name].Tag,  "SRSICross|Start|" .. tostring(Signals[Directions.Down][RSIs.Name].Cross.Count) .. "|" .. (index_candle-1), Icons.Triangle, Levels[1])
	end
	--#endregion

	--#region	III.2. Elementary RSI Signal: Signals[Directions.Down/Up].RSIs.Cross50
	--				Impulse Signal: Signals[Directions.Down/Up].Impulse
	---				Depends on signal: SignalOscCrossLevel
	--				Terminates by signals: Reverse self-signal
	--				Terminates by duration: -
	-- check slow rsi cross lvl50 up
	if (SignalOscCrossLevel(RSIs.Slow, RSIs.Params.HLines.Center, index_candle, Directions.Up)) then
		-- set elementary down signal off
		Signals[Directions.Down][RSIs.Name].Cross50.Candle = 0
		-- set elementary up signal on
		Signals[Directions.Up][RSIs.Name].Cross50.Candle = index_candle - 1
		Signals[Directions.Up][RSIs.Name].Cross50.Count = Signals[Directions.Up][RSIs.Name].Cross50.Count + 1

		-- set chart label
		Labels[RSIs.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (RSIs.Slow[index_candle-1] * (100 - 2 * Charts[RSIs.Name].Step) / 100), Charts[RSIs.Name].Tag, "LRSICross50|Start|" .. tostring(Signals[Directions.Up][RSIs.Name].Cross50.Count) .. "|" .. (index_candle-1), Icons.Arrow, Levels[1])
	end

	-- check slow rsi cross lvl50 udown
	if (SignalOscCrossLevel(RSIs.Slow, RSIs.Params.HLines.Center, index_candle, Directions.Down)) then
		-- set elementary down signal off
		Signals[Directions.Up][RSIs.Name].Cross50.Candle = 0
		-- set elementary down signal on
		Signals[Directions.Down][RSIs.Name].Cross50.Candle = index_candle - 1
		Signals[Directions.Down][RSIs.Name].Cross50.Count = Signals[Directions.Down][RSIs.Name].Cross50.Count + 1

		-- set chart label
		Labels[RSIs.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (RSIs.Slow[index_candle-1] * (100 + 2 * Charts[RSIs.Name].Step) / 100), Charts[RSIs.Name].Tag, "SRSICross50|Start|" .. tostring(Signals[Directions.Down][RSIs.Name].Cross50.Count) .. "|" .. (index_candle-1), Icons.Arrow, Levels[1])
	end
	--#endregion

	--#region	III.3. Elementary RSI Signal: Signals[Directions.Down/Up].RSIs.TrendOn
	--				Enter Signals: Signals[Directions.Down/Up].TrendOn
	--				Depends on signal: SignalOscTrendOn
	--				Terminates by signals: Reverse self-signal,SignalOscTrendOff, SignalOscCross
	--				Terminates by duration: Signals.Params.Durations.Elementary
	-- check start elementary slow rsi enter on uptrend zone signal
	if (SignalOscTrendOn(RSIs, index_candle, Directions.Up)) then
		-- set elementary down signal off
		Signals[Directions.Down][RSIs.Name].TrendOn.Candle = 0
		-- set elementary up signal on
		Signals[Directions.Up][RSIs.Name].TrendOn.Candle = index_candle - 1
		Signals[Directions.Up][RSIs.Name].TrendOn.Count = Signals[Directions.Up][RSIs.Name].TrendOn.Count + 1

		-- set chart label
		Labels[RSIs.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (RSIs.Slow[index_candle-1] * (100 - 3 * Charts[RSIs.Name].Step) / 100), Charts[RSIs.Name].Tag, "LRSITrendOn|Start|" .. tostring(Signals[Directions.Up][RSIs.Name].TrendOn.Count) .. "|" .. (index_candle-1), Icons.Point, Levels[1])
	end

	-- check presence elementary up signal
	if (Signals[Directions.Up][RSIs.Name].TrendOn.Candle > 0) then
		-- set duration elemenetary up signal
		local duration = index_candle - Signals[Directions.Up][RSIs.Name].TrendOn.Candle
		-- check continuation elementary up signal
		if (duration <= Signals.Params.Durations.Elementary) then
			-- check termination by slow rsi enter off uptrend zone
			if (SignalOscTrendOff(RSIs, index_candle, Directions.Down)) then
				-- set elementary up signal off
				Signals[Directions.Up][RSIs.Name].TrendOn.Candle = 0

				-- set chart label
				Labels[RSIs.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (RSIs.Slow[index_candle-1]*(100 - 3 * Charts[RSIs.Name].Step) /100), Charts[RSIs.Name].Tag, "LRSITrendOff|End|" .. tostring(Signals[Directions.Up][RSIs.Name].TrendOn.Count) .. "|" .. (duration-1) .. "|" .. (index_candle-1), Icons.Cross, Levels[1])
			-- check termination by fast rsi cross slow rsi down
			elseif (SignalOscCross(RSIs, index_candle, Directions.Down)) then
				-- set elementary up signal off
				Signals[Directions.Up][RSIs.Name].TrendOn.Candle = 0

				-- set chart label
				Labels[RSIs.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (RSIs.Slow[index_candle-1] * (100 - 3 * Charts[RSIs.Name].Step) / 100), Charts[RSIs.Name].Tag, "LRSICrossDown|End|" .. tostring(Signals[Directions.Up][RSIs.Name].TrendOn.Count) .. "|" .. (duration-1) .. "|" .. (index_candle-1), Icons.Cross, Levels[1])
			-- process continuation elementary up signal
			else
				-- set chart label
				Labels[RSIs.Name][index_candle] = SetChartLabel(T(index_candle), (RSIs.Slow[index_candle] * (100 - 3 * Charts[RSIs.Name].Step) / 100), Charts[RSIs.Name].Tag, "LRSITrendOn|Continue|" .. tostring(Signals[Directions.Up][RSIs.Name].TrendOn.Count) .. "|" .. duration .. "|" .. index_candle, Icons.Point, Levels[1])
			end
		-- check termination by duration elementary up signal
		elseif (duration > Signals.Params.Durations.Elementary) then
			-- set elementary up signal off
			Signals[Directions.Up][RSIs.Name].TrendOn.Candle = 0

			-- set chart label
			Labels[RSIs.Name][index_candle] = SetChartLabel(T(index_candle), (RSIs.Slow[index_candle] * (100 - 3 * Charts[RSIs.Name].Step) / 100), Charts[RSIs.Name].Tag, "LRSITrendOn|End|" .. tostring(Signals[Directions.Up][RSIs.Name].TrendOn.Count) .. "|" .. duration .. "|" ..index_candle, Icons.Cross, Levels[1])
		end
	end

	-- check start elementary slow rsi enter on down trend zone signal
	if (SignalOscTrendOn(RSIs, index_candle, Directions.Down)) then
		-- set elementary up signal off
		Signals[Directions.Up][RSIs.Name].TrendOn.Candle = 0
		-- set elementary down signal on
		Signals[Directions.Down][RSIs.Name].TrendOn.Candle = index_candle - 1
		Signals[Directions.Down][RSIs.Name].TrendOn.Count = Signals[Directions.Down][RSIs.Name].TrendOn.Count + 1

		-- set chart label
		Labels[RSIs.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (RSIs.Slow[index_candle-1] * (100 + 3 * Charts[RSIs.Name].Step) / 100), Charts[RSIs.Name].Tag,  "SRSITrendOn|Start|" .. tostring(Signals[Directions.Down][RSIs.Name].TrendOn.Count) .. "|" .. (index_candle-1), Icons.Point, Levels[1])
	end

	-- check presence elementary down signal
	if (Signals[Directions.Down][RSIs.Name].TrendOn.Candle > 0) then
		-- set duration elemenetary down signal
		local duration = index_candle - Signals[Directions.Down][RSIs.Name].TrendOn.Candle
		-- check continuation elementary down signal
		if (duration <= Signals.Params.Durations.Elementary) then
			-- check termination by slow rsi enter off downtrend zone
			if (SignalOscTrendOff(RSIs, index_candle, Directions.Up)) then
				-- set elementary down signal off
				Signals[Directions.Down][RSIs.Name].TrendOn.Candle = 0

				-- set chart label
				Labels[RSIs.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (RSIs.Slow[index_candle-1] * (100 + 3 * Charts[RSIs.Name].Step) / 100), Charts[RSIs.Name].Tag, "SRSITrendOff|End|" .. tostring(Signals[Directions.Down][RSIs.Name].TrendOn.Count) .. "|" ..(duration - 1).. "|" .. (index_candle-1), Icons.Cross, Levels[1])
			-- check termination by fast rsi cross slow rsi down
			elseif (SignalOscCross(RSIs, index_candle, Directions.Down)) then
				Signals[Directions.Up][RSIs.Name].TrendOn.Candle = 0

				-- set chart label
				Labels[RSIs.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (RSIs.Slow[index_candle-1] * (100 + 3 * Charts[RSIs.Name].Step) / 100), Charts[RSIs.Name].Tag, "SRSICrossUp|End|" .. tostring(Signals[Directions.Up][RSIs.Name].TrendOn.Count) .. "|" ..(duration-1) .. "|" .. (index_candle-1), Icons.Cross, Levels[1])
			-- process continuation elementary down signal
			else
				-- set chart label
				Labels[RSIs.Name][index_candle] = SetChartLabel(T(index_candle), (RSIs.Slow[index_candle] * (100 + 3 * Charts[RSIs.Name].Step) / 100), Charts[RSIs.Name].Tag, "SRSITrendOn|Continue|" .. tostring(Signals[Directions.Down][RSIs.Name].TrendOn.Count) .. "|" .. duration .. "|" .. index_candle, Icons.Point, Levels[1])
			end
		-- check termination by duration elementary down signal
		elseif (duration > Signals.Params.Durations.Elementary) then
			-- set elementary down signal off
			Signals[Directions.Down][RSIs.Name].TrendOn.Candle = 0

			-- set chart label
			Labels[RSIs.Name][index_candle] = SetChartLabel(T(index_candle), (RSIs.Slow[index_candle] * (100 + 3 * Charts[RSIs.Name].Step) / 100), Charts[RSIs.Name].Tag, "SRSITrendOn|End|" .. tostring(Signals[Directions.Down][RSIs.Name].TrendOn.Count) .. "|" .. duration .. "|" .. index_candle, Icons.Cross, Levels[1])
		end
	end
	--#endregion

	if (index_candle==3075) then
		PrintDebugMessage("===Enter Up", "TrendOn", Signals[Directions.Up].TrendOn.Count, "Uturn", Signals[Directions.Up].Uturn.Count, "Spring1", Signals[Directions.Up].Spring1.Count, "Spring2", Signals[Directions.Up].Spring2.Count)
		PrintDebugMessage("Complex Up", "Trend", Signals[Directions.Up].Trend.Count, "Impulse", Signals[Directions.Up].Impulse.Count, "Enter", Signals[Directions.Up].Enter.Count)
		PrintDebugMessage("Prices Up", "CrossMA", Signals[Directions.Up].Prices.CrossMA.Count, "Uturn3", Signals[Directions.Up].Prices.Uturn3.Count, "Uturn4", Signals[Directions.Up].Prices.Uturn4.Count)
		PrintDebugMessage("Stochs Up", "Cross", Signals[Directions.Up].Stochs.Cross.Count, "Cross50", Signals[Directions.Up].Stochs.Cross50.Count, "Uturn3", Signals[Directions.Up].Stochs.Uturn3.Count, "Uturn4", Signals[Directions.Up].Stochs.Uturn4.Count, "Spring3", Signals[Directions.Up].Stochs.Spring3.Count, "Spring4", Signals[Directions.Up].Stochs.Spring4.Count, "VSteamer", Signals[Directions.Up].Stochs.VSteamer.Count, "HSteamer", Signals[Directions.Up].Stochs.HSteamer.Count)
		PrintDebugMessage("RSIs Up", "Cross", Signals[Directions.Up].RSIs.Cross.Count, "Cross50", Signals[Directions.Up].RSIs.Cross50.Count, "Uturn3", Signals[Directions.Up].RSIs.Uturn3.Count, "Uturn4", Signals[Directions.Up].RSIs.Uturn4.Count, "Spring3", Signals[Directions.Up].RSIs.Spring3.Count, "Spring4", Signals[Directions.Up].RSIs.Spring4.Count, "TrendOn", Signals[Directions.Up].RSIs.TrendOn.Count)

		PrintDebugMessage("===Enter Down", "TrendOn", Signals[Directions.Down].TrendOn.Count, "Uturn", Signals[Directions.Down].Uturn.Count, "Spring1", Signals[Directions.Down].Spring1.Count, "Spring2", Signals[Directions.Down].Spring2.Count)
		PrintDebugMessage("Complex Down", "Trend", Signals[Directions.Down].Trend.Count, "Impulse", Signals[Directions.Down].Impulse.Count, "Enter", Signals[Directions.Down].Enter.Count)
		PrintDebugMessage("Prices Down", "CrossMA", Signals[Directions.Down].Prices.CrossMA.Count, "Uturn3", Signals[Directions.Down].Prices.Uturn3.Count, "Uturn4", Signals[Directions.Down].Prices.Uturn4.Count)
		PrintDebugMessage("Stochs Down", "Cross", Signals[Directions.Down].Stochs.Cross.Count, "Cross50", Signals[Directions.Down].Stochs.Cross50.Count, "Uturn3", Signals[Directions.Down].Stochs.Uturn3.Count, "Uturn4", Signals[Directions.Down].Stochs.Uturn4.Count, "Spring3", Signals[Directions.Down].Stochs.Spring3.Count, "Spring4", Signals[Directions.Down].Stochs.Spring4.Count, "VSteamer", Signals[Directions.Down].Stochs.VSteamer.Count, "HSteamer", Signals[Directions.Down].Stochs.HSteamer.Count)
		PrintDebugMessage("RSIs Down", "Cross", Signals[Directions.Down].RSIs.Cross.Count, "Cross50", Signals[Directions.Down].RSIs.Cross50.Count, "Uturn3", Signals[Directions.Down].RSIs.Uturn3.Count, "Uturn4", Signals[Directions.Down].RSIs.Uturn4.Count, "Spring3", Signals[Directions.Down].RSIs.Spring3.Count, "Spring4", Signals[Directions.Down].RSIs.Spring4.Count, "TrendOn", Signals[Directions.Down].RSIs.TrendOn.Count)
	end 


    return PriceChannels.Top[index_candle], PriceChannels.Center[index_candle], PriceChannels.Bottom[index_candle]
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
        if (PriceChannels.Params.Period > 0) then
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
                Highs[Squeeze(Candles.count, PriceChannels.Params.Period - 1) + 1] = H(Candles.processed)
                Lows[Squeeze(Candles.count, PriceChannels.Params.Period - 1) + 1] = L(Candles.processed)

                -- calc and return max results
                if (Candles.count >= PriceChannels.Params.Period) then
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
	mode = string.upper(string.sub(mode, 1, 1))
	local Settings = {}
	if (mode == "S") then
		Settings = {  	period_k 	= Stochs.Params.Slow.PeriodK,
						shift 		= Stochs.Params.Slow.Shift,
						period_d 	= Stochs.Params.Slow.PeriodD }
	elseif (mode == "F") then
		Settings = {  	period_k 	= Stochs.Params.Fast.PeriodK,
						shift 		= Stochs.Params.Fast.Shift,
						period_d 	= Stochs.Params.Fast.PeriodD }
	end

	local K_ma1 = SMA(Settings)
	local K_ma2 = SMA(Settings)
	local D_ma  = EMA(Settings)

	local Highs = {}
	local Lows = {}
	local Candles = { processed = 0, count = 0 }

	return function (index_candle)
		if (Settings.period_k > 0) and (Settings.period_d > 0) then
			if (index_candle == 1) then
				Highs = {}
				Lows = {}
				Candles = { processed = 0, count = 0 }
			end

			if CandleExist(index_candle) then
				if (index_candle ~= Candles.processed) then
					Candles = { processed = index_candle, count = Candles.count + 1 }
				end

				Highs[Squeeze(Candles.count, Settings.period_k - 1) + 1] = H(Candles.processed)
				Lows[Squeeze(Candles.count, Settings.period_k - 1) + 1] = L(Candles.processed)

				if (Candles.count >= Settings.period_k)  then
					local max_high = math.max(unpack(Highs))
					local max_low = math.min(unpack(Lows))

					local value_k1 = K_ma1(Candles.count - Settings.period_k + 1,
										{[Candles.count - Settings.period_k + 1] = C(Candles.processed) - max_low})

					local value_k2 = K_ma2(Candles.count - Settings.period_k + 1,
										{[Candles.count - Settings.period_k + 1] = max_high - max_low})

					if ((Candles.count >= (Settings.period_k + Settings.shift - 1)) and (value_k2 ~= 0)) then
						local stoch_k = 100 * value_k1 / value_k2
						local stoch_d = D_ma(Candles.count - (Settings.period_k + Settings.shift - 2),
											{[Candles.count - (Settings.period_k + Settings.shift - 2)] = stoch_k})

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
--#region	INDICATOR RSI
--==========================================================================
----------------------------------------------------------------------------
-- function RSI
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

			local value_up = Ma_up(Itterations.count, {[Itterations.count] = move_up})
			local value_down = Ma_down(Itterations.count, {[Itterations.count] = move_down})

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
--	function MMA = (MMAi-1*(n-1) + Pi) / n
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
--	SIGNALS
--==========================================================================
----------------------------------------------------------------------------
--#region	Oscilator Signals
----------------------------------------------------------------------------
--
--	Signal Osc	Vertical Steamer
--
function SignalOscVSteamer(oscs, index, direction, dev)
	if (CheckDataSufficiency(index_candle, 2, oscs.Slow) and CheckDataSufficiency(index_candle, 2, oscs.Fast)) then
		dev = dev or Signals.Params.Steamer.Dev
		-- true or false
		return (-- oscs move in direction last 2 candles 
				(SignalMove(oscs.Fast, index, direction) and SignalMove(oscs.Slow, index, direction)) and
				-- fast osc ralate slow osc in direction last 2 candles 
				(SignalIsRelate(oscs.Fast[index-2], oscs.Slow[index-2], direction) and SignalIsRelate(oscs.Fast[index-1], oscs.Slow[index-1], direction)) and
				-- delta beetwen osc fast and slow osc less then dev last 2 candles 
				(GetDelta(oscs.Fast[index-2], oscs.Slow[index-2]) <= dev) and (GetDelta(oscs.Fast[index-1], oscs.Slow[index-1]) <= dev))
	else
		-- error
		return false
	end
end

--
--	Signal Osc	Horisontal Steamer
--
function SignalOscHSteamer(oscs, index, direction)
	if (CheckDataSufficiency(index_candle, (Signals.Params.Steamer.Duration+2), oscs.Slow) and CheckDataSufficiency(index_candle, (Signals.Params.Steamer.Duration+2), oscs.Fast)) then
		if (SignalOscCrossLevel(oscs.Slow, Stochs.Params.HLines.Center, index, direction)) then
			local count
			for count = 0, Signals.Params.Steamer.Duration do
				if (SignalOscCrossLevel(oscs.Fast, Stochs.Params.HLines.Center, (index-count), direction)) then
					--* use in long/short poses
					Labels[Stochs.Name][index-count-1] = SetChartLabel(T(index-count-1), (Stochs.Slow[index-count-1] * (100 - 4 * Charts[Stochs.Name].Step) / 100), Charts[Stochs.Name].Tags, "HSteamer|" .. count .. " of " .. tostring(index-count-1), Icons.Asterix, Levels[1])
					-- true or false
					return ( -- oscs move in direction last 2 candles 
							(SignalMove(oscs.Fast, (index-count), direction) and SignalMove(oscs.Slow, index, direction)) and
							-- fast osc ralate slow osc in direction last 2 candles 
							(SignalIsRelate(oscs.Fast[index-count-1], oscs.Slow[index-count-1], direction) and SignalIsRelate(oscs.Fast[index-1], oscs.Slow[index-1], direction)))
				end
			end
		end
	else
		-- error
		return false
	end
end

--
--	Signal Osc	Fast Cross Osc Slow
--
function SignalOscCross(oscs, index, direction, dev)
	if (CheckDataSufficiency(index, 2, oscs.Slow) and CheckDataSufficiency(index, 2, oscs.Fast)) then
		dev = dev or 0
		-- true or false
		return SignalCross(oscs.Fast, oscs.Slow, index, direction, dev)
	else
		-- error
		return false
	end
end

--
-- Signal Osc Cross Level
--
function SignalOscCrossLevel(oscs, level, index, direction, dev)
	if (CheckDataSufficiency(index, 2, oscs.Slow)) then
		dev = dev or 0
		-- true or false
		return SignalCross(osc, {[index-2] = level, [index-1] = level}, index, direction, dev)
	else
		-- error
		return false
	end
end

--
-- SignalOscTrendOn
--
function SignalOscTrendOn(oscs, index, direction)
	local level
	if (oscs.Name == RSIs.Name) then
		if (CheckDataSufficiency(index, 2, RSIs.Slow)) then
			if (direction == Directions.Up) then
				level = RSIs.Params.HLines.TopTrend
			elseif (direction == Directions.Down) then
				level = RSIs.Params.HLines.BottomTrend
			else
				return false
			end
			-- true or false
			return  SignalOscCrossLevel(RSIs.Slow, level, index, direction, dev)
		end
	elseif (oscs.Name == Stochs.Name) then
		if (CheckDataSufficiency(index, 2, Stochs.Slow)) then
			if (direction == Directions.Up) then
				level = Stochs.Params.HLines.Top
			elseif (direction == Directions.Down) then
				level = Stochs.Params.HLines.Bottom
			else
				return false
			end
			-- true or false
			return  SignalOscCrossLevel(Stochs.Slow, level, index, direction, dev)
		end
	elseif (oscs.Name == PriceChannels.Name) then
		if (CheckDataSufficiency(index, 2, PriceChannels.Center)) then
			if (direction == Directions.Up) then
				level = PriceChannels.Top[index-2]
			elseif (direction == Directions.Down) then
				level = PriceChannels.Bottom[index-2]
			else
				return false
			end
			-- true or false
			return  SignalOscCrossLevel(PriceChannels.Center, level, index, direction, dev)
		end
	else
		-- error
		return false
	end
end

--
-- Signal Osc	TrendOff
--
function SignalOscTrendOff(oscs, index, direction)
	if (CheckDataSufficiency(index, 2, oscs.Slow)) then
		local level
		if (oscs.Name == RSIs.Name) then
			if (direction == Directions.Up) then
				level = RSIs.Params.HLines.BottomTrend
			elseif (direction == Directions.Down) then
				level = RSIs.Params.HLines.TopTrend
			else
				return false
			end
		elseif (oscs.Name==Stochs.Name) then
			if (direction == Directions.Up) then
				level = Stochs.Params.HLines.Bottom
			elseif (direction == Directions.Down) then
				level = Stochs.Params.HLines.Top
			else
				return false
			end
		else
			return false
		end
		-- true or false
		return  SignalOscCrossLevel(oscs.Slow, level, index, direction, dev)
	else
		-- error
		return false
	end
end

--
-- Signal Osc	Uturn with 3 candles
--
function SignalOscUturn3(oscs, index, direction)
	if (CheckDataSufficiency(index, 3, oscs.Slow) and CheckDataSufficiency(index, 3, oscs.Fast) and 
		CheckDataSufficiency(index, 3, oscs.Delta)) then
		-- true or false
		return ( -- deltas uturn
			SignalUturn(oscs.Delta, index, Directions.Up) and
			-- fastosc/slowosc uturn
			SignalUturn(oscs.Fast, index, direction) and SignalMove(oscs.Slow, index, direction) and
			-- fastosc over slowosc all 3 candles
			(SignalIsRelate(oscs.Fast[index-3], oscs.Slow[index-3], direction) and
			SignalIsRelate(oscs.Fast[index-2], oscs.Slow[index-2], direction) and
			SignalIsRelate(oscs.Fast[index-1], oscs.Slow[index-1], direction)))
	else
		-- error
		return false
	end
end

--
-- Signal Osc	Uturn with 4 candles
--
function SignalOscUturn4(osc, index, direction)	
	if (CheckDataSufficiency(index, 4, oscs.Slow) and CheckDataSufficiency(index, 4, oscs.Fast) and 
		CheckDataSufficiency(index, 4, oscs.Delta)) then
		-- true or false
		return ( -- deltas uturn
			(SignalMove(osc.Delta, index-2, Directions.Down) and SignalMove(osc.Delta, index, Directions.Up)) and
			-- fastosc/slowosc uturn
			(SignalMove(osc.Fast, index-2, Reverse(direction)) and SignalMove(osc.Fast, index, direction) and SignalMove(osc.Slow, index, direction)) and
			-- fastosc over slowosc all 4 candles
			(SignalIsRelate(osc.Fast[index-4], osc.Slow[index-4], direction) and
			SignalIsRelate(osc.Fast[index-3], osc.Slow[index-3], direction) and
			SignalIsRelate(osc.Fast[index-2], osc.Slow[index-2], direction) and
			SignalIsRelate(osc.Fast[index-1], osc.Slow[index-1], direction)))
	else
		-- error
		return false
	end
end
--#endregion

----------------------------------------------------------------------------
--#region	Price Signals
----------------------------------------------------------------------------
--
-- Signal Price	Cross MA
--
function SignalPriceCrossMA(prices, mas, index, direction, dev)
	if (CheckDataSufficiency(index, 1, prices.Open) and CheckDataSufficiency(index, 2, prices.Close) and CheckDataSufficiency(index_candle, 2, mas)) then
		dev = dev or 0	
		-- true or false
		return (-- candle up/down
				SignalIsRelate(prices.Close[index-1], prices.Open[index-1], direction) and
				-- candle cross ma up/down
				SignalCross(prices.Close, mas, index, direction, dev))
	else
		-- error
		return false
	end
end

--
-- Signal Price Uturn3
--
function SignalPriceUturn3(prices, mas, index, direction, dev)
	if (CheckDataSufficiency(index, 3, prices.Open) and CheckDataSufficiency(index, 3, prices.Close) and
		CheckDataSufficiency(index, 3, prices.High) and CheckDataSufficiency(index, 3, prices.Low) and
		CheckDataSufficiency(index, 3, mas.Central) and CheckDataSufficiency(index, 3, mas.Delta)) then
		dev = dev or 0	
		-- true or false
		if (direction == Directions.Up) then
			-- one first candles down, one last candle up
			return (SignalIsRelate(prices.Open[index-3], prices.Close[index-3], direction, dev) and
					SignalIsRelate(prices.Close[index-1], prices.Open[index-1], direction, dev) and
					-- prices.close uturn and delta uturn min at top 
					SignalUturn(prices.Close, index, direction) and SignalUturn(mas.Delta, index, Directions.Up) and
					-- ma move 3 last candles up
					mas.Central[index-1] >= mas.Central[index-2] and mas.Central[index-2] >= mas.Central[index-3] and
					-- strength condition
					(prices.Close[index-1] >= prices.Close[index-2]) and (prices.Close[index-1] >= prices.Close[index-3]))
		elseif (direction == Directions.Down) then
				-- one first candle up, one last candle is down
				return (SignalIsRelate(prices.Open[index-3], prices.Close[index-3], direction, dev) and
						SignalIsRelate(prices.Close[index-1], prices.Open[index-1], direction, dev) and
						-- prices.close uturn and delta uturn min at top uturn
						SignalUturn(prices.Close, index, direction) and SignalUturn(mas.Delta, index, Directions.Up) and
						-- ma move last 3 candles down
						mas.Central[index-3] >= mas.Central[index-2] and mas.Central[index-2] >= mas.Central[index-1] and
						-- strength condition
						(prices.Close[index-2] >= prices.Close[index-1]) and (prices.Close[index-3] >= prices.Close[index-1]))
			end
	else
		-- error
		return false
	end
end

--
-- Signal Price Uturn4
--
function SignalPriceUturn4(prices, mas, index, direction, dev)
	if (CheckDataSufficiency(index, 4, prices.Open) and CheckDataSufficiency(index, 4, prices.Close) and
		CheckDataSufficiency(index, 4, prices.High) and CheckDataSufficiency(index, 4, prices.Low) and
		CheckDataSufficiency(index, 4, mas.Central) and CheckDataSufficiency(index, 4, mas.Delta)) then
		dev = dev or 0	
		-- true or false
		if (direction == Directions.Up) then
			-- one first candles down, one last candle up
			return (SignalIsRelate(prices.Open[index-4], prices.Close[index-4], direction, dev) and
					SignalIsRelate(prices.Close[index-1], prices.Open[index-1], direction, dev) and
					-- price.close uturn
					SignalMove(prices.Close, (index-2), Reverse(direction)) and SignalMove(prices.Close, index, direction) and
					-- delta min at top uturn
					SignalMove(mas.Delta, (index-2), Directions.Down) and SignalMove(mas.Delta, index, Directions.Up) and
					-- ma move 4 last candles up
					(mas.Central[index-1] >= mas.Central[index-2]) and (mas.Central[index-2] >= mas.Central[index-3]) and (mas.Central[index-3] >= mas.Central[index-4]) and
					-- strength condition
					(prices.Close[index-1] >= prices.Close[index-2]) and (prices.Close[index-1] >= prices.Close[index-3]) and (prices.Close[index-1] >= prices.Close[index-4]))
		elseif (direction == Directions.Down) then
			-- one or two of 2 first candles are down, last 1 candle is up
			return (SignalIsRelate(prices.Open[index-4], prices.Close[index-4], direction, dev) and
					SignalIsRelate(prices.Close[index-1], prices.Open[index-1], direction, dev) and
					-- price.close uturn
					SignalMove(prices.Close, (index-2), Reverse(direction)) and SignalMove(prices.Close, index, direction) and
					-- delta min at top uturn
					SignalMove(mas.Delta, (index-2), Directions.Down) and SignalMove(mas.Delta, index, Directions.Up) and
					-- ma move 4 last candles down
					(mas.Central[index-4] >= mas.Central[index-3]) and (mas.Central[index-3] >= mas.Central[index-2]) and (mas.Central[index-2] >= mas.Central[index-1]) and
					-- strength condition
					(prices.Close[index-2] >= prices.Close[index-1]) and (prices.Close[index-3] >= prices.Close[index-1]) and (prices.Close[index-4] >= prices.Close[index-1]))
		end
	else
		-- error
		return false
	end
end
--#endregion

----------------------------------------------------------------------------
--#region	Elementary Signals
--todo	code 5 candles
----------------------------------------------------------------------------
--
--	Signal	Value1 cross Value2 up and down
--
function SignalCross(value1, value2, index, direction, dev)
	if (direction == Directions.Up) then
		return (((value2[index-2] + dev) >= value1[index-2]) and (value1[index-1] >= (value2[index-1] - dev)))
	elseif (direction == Directions.Down) then
		return ((value1[index-2] >= (value2[index-2] - dev)) and ((value2[index-1] + dev) >= value1[index-1]))
	end

	return false
end

--
--	Signal	2 last candles Value move up or down
--
function SignalMove(value, index, direction)
	if (direction == Directions.Up) then
		return (value[index-1] > value[index-2])
	elseif (direction == Directions.Down) then
		return (value[index-2] > value[index-1])
	end

	return false
end

--
--	Signal	3 last candles Value uturn up or down 
--
function SignalUturn(value, index, direction)
	if (direction == Directions.Up) then
		return ((value[index-3] > value[index-2]) and (value[index-1] > value[index-2]))
	elseif (direction == Directions.Down) then
		return ((value[index-2] > value[index-3]) and (value[index-2] > value[index-1]))
	end

	return false
end

--
--	Condition	Is over or under Value2
--
function SignalIsRelate(value1, value2, direction, dev)
	if (direction == Directions.Up) then
		return ((value1 + dev) > value2)
	elseif (direction == Directions.Down) then
		return (value2 > (value1 - dev))
	end

	return false
end
--#endregion

--==========================================================================
--#region	UTILITIES
--==========================================================================
----------------------------------------------------------------------------
--	function Reverse
--	return reverse of direction
----------------------------------------------------------------------------
function Reverse(direction)
	if (direction == Directions.Up) then
		return Directions.Down
	elseif (direction == Directions.Down) then
		return Directions.Up
	else
		return nil
	end
end

----------------------------------------------------------------------------
--	function GetDelta
--	return abs difference between values
----------------------------------------------------------------------------
function GetDelta(value1, value2)
	return math.abs(value1 - value2)
end

----------------------------------------------------------------------------
--	function PrintDebugMessage(message1, message2, ...)
--	print messages as one string separated by symbol in message window and debug utility
----------------------------------------------------------------------------
function PrintDebugMessage(...)
	local args = { n = select("#",...), ... }
	-- check number messages more then zero
	if (args.n > 0) then
		local count
		local tmessage = {}

		-- concate messages with symbol
		for count = 1, args.n do
			table.insert(tmessage, tostring(args[count]))
		end
		local smessage = table.concat(tmessage, "|")

		-- print messages as one string
		message(smessage)
		PrintDbgStr("QUIK|" .. smessage)

		-- return number of messages
		return args.n
	else
		-- nothing todo
		return 0
	end
end

----------------------------------------------------------------------------
--	function Squeeze
--	return number from 0 (if index start from 1) to period and then again from 0 (index == period)
--	pointer in cycylic buffer 
----------------------------------------------------------------------------
function Squeeze(index, period)
	return math.fmod(index - 1, period + 1)
end

----------------------------------------------------------------------------
--	function RoundScale
--	return value with requred numbers after digital point
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
--	function GetChartTag
--	return chart atg from indicator name
----------------------------------------------------------------------------
function GetChartTag(indicator_name)
	return Settings.Name .. indicator_name
end

----------------------------------------------------------------------------
--	function GetLevel
--	return which levels packed in flag (chart levels)
----------------------------------------------------------------------------
function GetLevel(flag)
	local result = {}

	result[4] = flag & 8
	result[3] = flag & 4
	result[2] = flag & 2
	result[1] = flag & 1

	return result
end

----------------------------------------------------------------------------
--	function SetChartLabel
----------------------------------------------------------------------------
function SetChartLabel(x_value, y_value, indicator_name, text, icon, signal_level)
	-- delete label duplicates
	if (Labels[indicator_name][index_candle-1] ~= nil) then
		DelLabel(GetChartTag(indicator_name), Labels[indicator_name][index_candle-1])
	end 
	
	-- check signal level and chart levels
	signal_level = signal_level or Levels.Level1
	local chart_levels = GetLevel(Charts[indicator_name].Level)
	if (((signal_level == Levels[1]) and (chart_levels[1] > 0)) or 
		((signal_level == Levels[2]) and (chart_levels[2] > 0)) or 
		((signal_level == Levels[3]) and (chart_levels[3] > 0))  or 
		((signal_level == Levels[4]) and (chart_levels[4] > 0))) then

		-- get direction from first letter of text - S for short/ L for Long
		local direction = string.upper(string.sub(text, 1, 1))
		if (direction == Directions.Up) then
			LabelParams.ALIGNMENT = "BOTTOM"
		elseif (direction == Directions.Down) then
			LabelParams.ALIGNMENT = "TOP"
		else
			return -1
		end

		-- set icon
		icon = (icon and string.upper(string.sub(icon, 1, 1))) or Icons.Triangle
		if (icon == Icons.Arrow) then
			if (direction == Directions.Up) then
				LabelParams.IMAGE_PATH = IconPath .. "arrow_up.jpg"
			elseif (direction == Directions.Down) then
				LabelParams.IMAGE_PATH = IconPath .. "arrow_down.jpg"
			end
		elseif (icon == Icons.Point) then
			if (direction == Directions.Up) then
				LabelParams.IMAGE_PATH = IconPath .. "point_up.jpg"
			elseif (direction == Directions.Down) then
				LabelParams.IMAGE_PATH = IconPath .. "point_down.jpg"
			end
		elseif (icon == Icons.Triangle) then
			if (direction == Directions.Up) then
				LabelParams.IMAGE_PATH = IconPath .. "triangle_up.jpg"
			elseif (direction == Directions.Down) then
				LabelParams.IMAGE_PATH = IconPath .. "triangle_down.jpg"
			end
		elseif (icon == Icons.Cross) then
			if (direction == Directions.Up) then
				LabelParams.IMAGE_PATH = IconPath .. "cross_up.jpg"
			elseif (direction == Directions.Down) then
				LabelParams.IMAGE_PATH = IconPath .. "cross_down.jpg"
			end
		elseif (icon == Icons.Romb) then
			if (direction == Directions.Up) then
				LabelParams.IMAGE_PATH = IconPath .. "romb_up.jpg"
			elseif (direction == Directions.Down) then
				LabelParams.IMAGE_PATH = IconPath .. "romb_down.jpg"
			end
		elseif (icon == Icons.Plus) then
			if (direction == Directions.Up) then
				LabelParams.IMAGE_PATH = IconPath .. "plus_up.jpg"
			elseif (direction == Directions.Down) then
				LabelParams.IMAGE_PATH = IconPath .. "plus_down.jpg"
			end
		elseif (icon == Icons.Flash) then
			if (direction == Directions.Up) then
				LabelParams.IMAGE_PATH = IconPath .. "flash_up.jpg"
			elseif (direction == Directions.Down) then
				LabelParams.IMAGE_PATH = IconPath .. "flash_down.jpg"
			end
		elseif (icon == Icons.Asterix) then
			if (direction == Directions.Up) then
				LabelParams.IMAGE_PATH = IconPath .. "asterix_up.jpg"
			elseif (direction == Directions.Down) then
				LabelParams.IMAGE_PATH = IconPath .. "asterix_down.jpg"
			end
		elseif (icon == Icons.BigArrow) then
			if (direction == Directions.Up) then
				LabelParams.IMAGE_PATH = IconPath .. "big_arrow_up.jpg"
			elseif (direction == Directions.Down) then
				LabelParams.IMAGE_PATH = IconPath .. "big_arrow_down.jpg"
			end
		elseif (icon == Icons.BigPoint) then
			if (direction == Directions.Up) then
				LabelParams.IMAGE_PATH = IconPath .. "big_point_up.jpg"
			elseif (direction == Directions.Down) then
				LabelParams.IMAGE_PATH = IconPath .. "big_point_down.jpg"
			end
		elseif (icon == Icons.BigTriangle) then
			if (direction == Directions.Up) then
				LabelParams.IMAGE_PATH = IconPath .. "big_triangle_up.jpg"
			elseif (direction == Directions.Down) then
				LabelParams.IMAGE_PATH = IconPath .. "big_triangle_down.jpg"
			end
		elseif (icon == Icons.BigCross) then
			if (direction == Directions.Up) then
				LabelParams.IMAGE_PATH = IconPath .. "big_cross_up.jpg"
			elseif (direction == Directions.Down) then
				LabelParams.IMAGE_PATH = IconPath .. "big_cross_down.jpg"
			end
		elseif (icon == Icons.BigRomb) then
			if (direction == Directions.Up) then
				LabelParams.IMAGE_PATH = IconPath .. "big_romb_up.jpg"
			elseif (direction == Directions.Down) then
				LabelParams.IMAGE_PATH = IconPath .. "big_romb_down.jpg"
			end
		elseif (icon == Icons.BigPlus) then
			if (direction == Directions.Up) then
				LabelParams.IMAGE_PATH = IconPath .. "big_plus_up.jpg"
			elseif (direction == Directions.Down) then
				LabelParams.IMAGE_PATH = IconPath .. "big_plus_down.jpg"
			end
		else
			return -1
		end

		-- set other label vars
		LabelParams.HINT = text
		LabelParams.TEXT = text
		LabelParams.YVALUE = y_value
		LabelParams.DATE = tostring(10000 * x_value.year + 100 * x_value.month + x_value.day)
		LabelParams.TIME = tostring(10000 * x_value.hour + 100 *  x_value.min + x_value.sec)

		-- set chart label return id
		return AddLabel(chart_tag, LabelParams)
	else
		-- nothing todo
		return 0
	end
end

----------------------------------------------------------------------------
--	function CheckDataSufficiency
--	return true if number values from index back exist
----------------------------------------------------------------------------
function CheckDataSufficiency(index, number, value)
	-- if index under required number retirn false
	if (index <= number) then
		return false
	end

	local count
	for count = 1, number, 1 do
		-- if one of number values mot exist return false
		if (value[index-count] == nil) then
			return false
		end
	end

	return true
end
--#endregion 

----------------------------------------------------------------------------
--#region	additional table functions
----------------------------------------------------------------------------
--
-- table.val_to_str
--
function table.val_to_str(v)
	if "string" == type(v) then
		v = string.gsub(v, "\n", "\\n")
		if string.match(string.gsub(v, "[^'\"]", ""), '^"+$') then
			return "'" .. v .. "'"
		end
		return '"' .. string.gsub(v, '"', '\\"') .. '"'
	end
	return "table" == type(v) and table.tostring(v) or tostring(v)
end

--
-- table.key_to_str
--
function table.key_to_str(k)
	if "string" == type(k) and string.match(k, "^[_%a][_%a%d]*$") then
		return k
	end
	return "[" .. table.val_to_str(k) .. "]"
end

--
-- table.tostring
--
function table.tostring(tbl)
	if type(tbl) ~= 'table' then return table.val_to_str(tbl) end
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
end

--
-- table.tostring
--
function table.load(fname)
	local f, err = io.open(fname, "r")
	if f == nil then return {} end
	local fn, err = loadstring("return "..f:read("*a"))
	f:close()
	if type(fn) == "function" then
		local succ, res = pcall(fn)
		if succ and type(res) == "table" then return res end
	end
	return {}
end

--
-- table.save
--
function table.save(fname, tbl)
	local f, err = io.open(fname, "w")
	if f ~= nil then
		f:write(table.tostring(tbl))
		f:close()
	end
end
--#endregion
--[[ EOF ]]--