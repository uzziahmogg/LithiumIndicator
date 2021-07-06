--==========================================================================
--	Indicator Lithium, 2021 (c) FEK
--==========================================================================
--todo convert RoundScale(..., 4) to RoundScale(..., values_after_point)
--todo func AddLabel use Labels array
--todo create func CheckElementarySignal
--todo move long/short checking signals to diferent branch

----------------------------------------------------------------------------
--#region	Settings
----------------------------------------------------------------------------
Settings = { Name = "FEK_LITHIUM",
			line = {{ Name = "BB", Type = TYPE_LINE, Color = RGB(221, 44, 44) },
					{ Name = "BBTop", Type = TYPE_LINE,	Color = RGB(0, 206, 0) },
					{ Name = "BBBottom", Type = TYPE_LINE, Color = RGB(0, 162, 232) }}}
--#endregion

--==========================================================================
--#region	Init
--==========================================================================
function Init()
	-- indicators data arrays and params
	Stochs = { Name = "Stoch", Fast = {}, Slow = {}, Delta = {}, Params = { Levels = { Top = 80, Center = 50, Bottom = 20 }, Slow = { PeriodK = 10, Shift = 3, PeriodD = 1 }, Fast = { PeriodK = 5, Shift = 2, PeriodD = 1 }}}
	BBs = { Name = "BB", Top = {}, Bottom = {}, Delta = {}, Params = { Period = 20,  Shift = 2 }}
	MAs = { Name = "MA", Delta = {}}
	Prices = { Name = "Price", Open = {}, Close = {}, High = {}, Low = {}}
	RSIs = { Name = "RSI", Fast = {}, Slow = {}, Delta = {}, Params = { Levels = { Top = 80, TopTrend = 60, Center = 50, BottomTrend = 40, Bottom = 20 }, PeriodSlow = 14, PeriodFast = 9 }}
	PCs = { Name = "PC", High = {}, Low = {}, Params = { Period =  BBs.Params.Period / 2 }}

	-- directions for signals, labels and deals
	Directions = { Up = "L", Down = "S" }

	-- tags for charts to show labels
	ChartTags = { 	Stoch = Settings.Name .. Stochs.Name ,  -- FEK_LITHIUMStoch
					Price = Settings.Name .. Prices.Name, 	-- FEK_LITHIUMPrice
					RSI = Settings.Name .. RSIs.Name }		-- FEK_LITHIUMRSI

	-- steps for text labels on charts
	ChartSteps = { Price = 15, Stoch = 10, RSI = 5 }

	-- chart labels ids
	Labels = { [Prices.Name] = {}, [Stochs.Name] = {}, [RSIs.Name] = {}}

	-- chart label icons
	ChartLabelIcons = { Arrow = "A", Point = "P", Triangle = "T", Cross = "C", Romb = "R", Plus = "L", Flash = "F", Asterix = "X",
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
	FuncBB = BolBands()
	FuncStochSlow = Stoch("SLOW")
	FuncStochFast = Stoch("FAST")
	FuncRSISlow = RSI("SLOW")
	FuncRSIFast = RSI("FAST")
	FuncPC = PriceChannel()

	-- signals start candles and counts
	Signals = {	[Directions.Up] = { Prices = { CrossMA = { Count = 0, Candle = 0 }}, 
	Stochs = { Cross = { Count = 0, Candle = 0 }, Cross50 = { Count = 0, Candle = 0 }, HSteamer = { Count = 0, Candle = 0 }, VSteamer = { Count = 0, Candle = 0 }}, 
	RSIs = { Cross = { Count = 0, Candle = 0 }, Cross50 = { Count = 0, Candle = 0 }, TrendOn = { Count = 0, Candle = 0 }}}, 
	[Directions.Down] = { Prices = { CrossMA = { Count = 0, Candle = 0 }}, 
	Stochs = { Cross = { Count = 0, Candle = 0 }, Cross50 = { Count = 0, Candle = 0 }, HSteamer = { Count = 0, Candle = 0 }, VSteamer = { Count = 0, Candle = 0 }},
	RSIs = { Cross = { Count = 0, Candle = 0 }, Cross50 = { Count = 0, Candle = 0 }, TrendOn = { Count = 0, Candle = 0 }}},
	Params = { Durations = { Elementary = 4, Enter = 3 }, Steamer = { Dev = 30, Duration = 2 }}} 

	-- levels to show labels on charts
	SignalLevels = { Elementary = 1, Impulse = 2, Trend = 4, Enter = 8 }

	return #Settings.line
end
--#endregion

--==========================================================================
--	OnCalculate
--==========================================================================
function OnCalculate(index_candle)
	if (index_candle == 1) then
		ChartsParam = SetParam(0, SignalLevels.Impulse, 0)
		
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
		Signals[Directions.Down].Prices.CrossMA.Count = 0
		Signals[Directions.Down].Prices.CrossMA.Candle = 0

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

	-- calculate current bb
	MAs[index_candle], BBs.Top[index_candle], BBs.Bottom[index_candle] = FuncBB(index_candle)
	MAs[index_candle] = RoundScale(MAs[index_candle], 4)
	BBs.Top[index_candle] = RoundScale(BBs.Top[index_candle], 4)
	BBs.Bottom[index_candle] = RoundScale(BBs.Bottom[index_candle], 4)

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
	PCs.High[index_candle], PCs.Low[index_candle] = FuncPC(index_candle)
	PCs.High[index_candle] = RoundScale(PCs.High[index_candle], 4) 
	PCs.Low[index_candle] = RoundScale(PCs.Low[index_candle], 4)

	-- calculate current deltas
	Stochs.Delta[index_candle] = ((Stochs.Slow[index_candle] ~= nil) and (Stochs.Fast[index_candle] ~= nil)) and RoundScale(GetDelta(Stochs.Fast[index_candle], Stochs.Slow[index_candle]), 4)
	BBs.Delta[index_candle] =  ((BBs.Top[index_candle] ~= nil) and (BBs.Bottom[index_candle] ~= nil)) and RoundScale(GetDelta(BBs.Top[index_candle], BBs.Bottom[index_candle]), 4)
	MAs.Delta[index_candle] = ((Prices.Close[index_candle]~= nil) and (MAs[index_candle] ~= nil)) and RoundScale(GetDelta(Prices.Close[index_candle], MAs[index_candle]), 4)
	RSIs.Delta[index_candle] = ((RSIs.Fast[index_candle]~= nil) and (RSIs.Slow[index_candle] ~= nil)) and RoundScale(GetDelta(RSIs.Fast[index_candle], RSIs.Slow[index_candle]), 4)
	--#endregion

	----------------------------------------------------------------------------
	--	I. Elementary Price Signals
	----------------------------------------------------------------------------
	--
	--#region	I.1. Elementary Price Signal: Signals[Directions.Down/Up].Prices.CrossMA
	--				Trend Signal: Signals[Directions.Down/Up].Trend
	--				Depends on signal: -
	--				Terminates by signals: Reverse self-signal
	--				Terminates by duration: -
	--
	if (CheckDataSufficiency(index_candle, 2, Prices.Open) and CheckDataSufficiency(index_candle, 2, Prices.Close) and CheckDataSufficiency(index_candle, 2, MAs)) then
		--
		-- check start elementary price cross ma up signal
		--
		if (SignalPriceCrossMA(Prices, MAs, index_candle, Directions.Up)) then
			-- set elementary down signal off
			Signals[Directions.Down].Prices.CrossMA.Candle = 0
			-- set elementary up signal on
			Signals[Directions.Up].Prices.CrossMA.Count = Signals[Directions.Up].Prices.CrossMA.Count + 1
			Signals[Directions.Up].Prices.CrossMA.Candle = index_candle - 1

			-- set chart label
			if (Labels[Prices.Name][index_candle-1] ~= nil) then
				DelLabel(ChartTags.Price, Labels[Prices.Name][index_candle-1])
			end 
			Labels[Prices.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (Prices.Low[index_candle-1]-ChartSteps.Price*SecInfo.min_price_step), ChartTags.Price, "LPriceCrossMA|Start|"..tostring(Signals[Directions.Up].Prices.CrossMA.Count).."|"..(index_candle-1).."|"..Signals[Directions.Up].Trend.Candle, ChartLabelIcons.Arrow, SignalLevels.Elementary)
		end

		--
		-- check start elementary price cross ma down signal
		--
		if (SignalPriceCrossMA(Prices, MAs, index_candle, Directions.Down)) then
			-- set elementary up signal off
			Signals[Directions.Up].Prices.CrossMA.Candle = 0
			-- set elementary down signal on
			Signals[Directions.Down].Prices.CrossMA.Count = Signals[Directions.Down].Prices.CrossMA.Count + 1
			Signals[Directions.Down].Prices.CrossMA.Candle = index_candle - 1

			-- set debug chart label
			if (Labels[Prices.Name][index_candle-1] ~= nil) then
				DelLabel(ChartTags.Price, Labels[Prices.Name][index_candle-1])
			end
			Labels[Prices.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (Prices.High[index_candle-1]+ChartSteps.Price*SecInfo.min_price_step), ChartTags.Price, "SPriceCrossMA|Start|"..tostring(Signals[Directions.Down].Prices.CrossMA.Count).."|"..(index_candle-1).."|"..Signals[Directions.Down].Trend.Candle, ChartLabelIcons.Arrow, SignalLevels.Elementary)
		end
	end
	--#endregion

    --	if (index_candle> 3000) then
	-- 	PrintDebugMessage("canle", index_candle, T(index_candle).day, T(index_candle).hour, T(index_candle).min)

	----------------------------------------------------------------------------
	--	II. Elementary Stoch Signals
	----------------------------------------------------------------------------
	--
	--#region	II.1. Elementary Stoch Signal: Signals[Directions.Down/Up].Stochs.Cross
	--				Impulse Signal: Signals[Directions.Down/Up].Impulse
	--				Depends on signal: SignalOscCross
	--				Terminates by signals: Reverse self-signal
	--				Terminates by duration: -
	--
	if (CheckDataSufficiency(index_candle, 2, Stochs.Slow) and CheckDataSufficiency(index_candle, 2, Stochs.Fast)) then
		--
		-- check fast stoch cross slow stoch up
		--
		if (SignalOscCross(Stochs, index_candle, Directions.Up)) then
			-- set elementary down signal off
			Signals[Directions.Down].Stochs.Cross.Candle = 0
			-- set elementary up signal on
			Signals[Directions.Up].Stochs.Cross.Candle = index_candle - 1
			Signals[Directions.Up].Stochs.Cross.Count = Signals[Directions.Up].Stochs.Cross.Count + 1

			-- set chart label
			if (Labels[Stochs.Name][index_candle-1] ~= nil) then
				DelLabel(ChartTags.Stoch, Labels[Stochs.Name][index_candle-1])
			end
			Labels[Stochs.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (Stochs.Slow[index_candle-1]*(100-ChartSteps.Stoch)/100), ChartTags.Stoch, "LStochCross|Start|"..tostring(Signals[Directions.Up].Stochs.Cross.Count).."|"..(index_candle-1), ChartLabelIcons.Triangle, SignalLevels.Elementary)
		end

		--
		-- check fast stoch cross slow stoch down
		--
		if (SignalOscCross(Stochs, index_candle, Directions.Down)) then
			-- set elementary down signal off
			Signals[Directions.Up].Stochs.Cross.Candle = 0
			-- set elementary up signal on
			Signals[Directions.Down].Stochs.Cross.Candle = index_candle - 1
			Signals[Directions.Down].Stochs.Cross.Count = Signals[Directions.Down].Stochs.Cross.Count + 1

			-- set chart label
			if (Labels[Stochs.Name][index_candle-1] ~= nil) then
				DelLabel(ChartTags.Stoch, Labels[Stochs.Name][index_candle-1])
			end
			Labels[Stochs.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (Stochs.Slow[index_candle-1]*(100+ChartSteps.Stoch)/100), ChartTags.Stoch, "SStochCross|Start|"..tostring(Signals[Directions.Down].Stochs.Cross.Count).."|"..(index_candle-1), ChartLabelIcons.Triangle, SignalLevels.Elementary)
		end
	end
	--#endregion

	--
	--#region	II.2. Elementary Stoch Signal: Signals[Directions.Down/Up].Stochs.Cross50
	--				Impulse Signal: Signals[Directions.Down/Up].Impulse
	--				Depends on signal: SignalOscCrossLevel
	--				Terminates by signals: Reverse self-signal
	--				Terminates by duration: -
	--
	if (CheckDataSufficiency(index_candle, 2, Stochs.Slow)) then
		--
		-- check slow stoch cross lvl50 up
		--
		if (SignalOscCrossLevel(Stochs.Slow, Stochs.Params.Levels.Center, index_candle, Directions.Up)) then
			-- set elementary down signal off
			Signals[Directions.Down].Stochs.Cross50.Candle = 0
			-- set elementary up signal on
			Signals[Directions.Up].Stochs.Cross50.Candle = index_candle - 1
			Signals[Directions.Up].Stochs.Cross50.Count = Signals[Directions.Up].Stochs.Cross50.Count + 1

			-- set chart label
			-- if (Labels[Stochs.Name][index_candle-1] ~= nil) then
			-- 	DelLabel(ChartTags.Stoch, Labels[Stochs.Name][index_candle-1])
			-- end
			Labels[Stochs.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (Stochs.Slow[index_candle-1]*(100-2*ChartSteps.Stoch)/100), ChartTags.Stoch, "LStochCross50|Start|"..tostring(Signals[Directions.Up].Stochs.Cross50.Count).."|"..(index_candle-1), ChartLabelIcons.Arrow, SignalLevels.Impulse)
		end

		--
		-- check slow stoch cross lvl50 down
		--
		if (SignalOscCrossLevel(Stochs.Slow, Stochs.Params.Levels.Center, index_candle, Directions.Down)) then
			-- set elementary up signal off
			Signals[Directions.Up].Stochs.Cross50.Candle = 0
			-- set elementary down signal on
			Signals[Directions.Down].Stochs.Cross50.Candle = index_candle - 1
			Signals[Directions.Down].Stochs.Cross50.Count = Signals[Directions.Down].Stochs.Cross50.Count + 1

			-- set chart label
			-- if (Labels[Stochs.Name][index_candle-1] ~= nil) then
			-- 	DelLabel(ChartTags.Stoch, Labels[Stochs.Name][index_candle-1])
			-- end
			Labels[Stochs.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (Stochs.Slow[index_candle-1]*(100+2*ChartSteps.Stoch)/100), ChartTags.Stoch,  "SStochCross50|Start|"..tostring(Signals[Directions.Down].Stochs.Cross50.Count).."|"..(index_candle-1), ChartLabelIcons.Arrow, SignalLevels.Impulse)
		end
	end
	--#endregion

	--
	-- #region	II.3. Elementary Stoch Signal: Signals[Directions.Down/Up].Stochs.Steamer
	--				Enter Signal: Signals[Directions.Down/Up].TrendOn/Uturn
	--				Depends on signal: SignalOscHorSteamer, SignalOscVerSteamer
	--				Terminates by signals:
	--				Terminates by duration:
	--
	if (CheckDataSufficiency(index_candle,  (Signals.Params.Steamer.Duration+2), Stochs.Slow) and CheckDataSufficiency(index_candle,  (Signals.Params.Steamer.Duration+2), Stochs.Fast)) then
		-- check stoch steamer up
		if (SignalOscVSteamer(Stochs, index_candle, Directions.Up)) then
			-- set elementary down signal off
			Signals[Directions.Down].Stochs.VSteamer.Candle = 0
			-- set elementary up signal on
			Signals[Directions.Up].Stochs.VSteamer.Candle = index_candle - 1
			Signals[Directions.Up].Stochs.VSteamer.Count = Signals[Directions.Up].Stochs.VSteamer.Count + 1
			-- set chart label
			if (Labels[Stochs.Name][index_candle-1] ~= nil) then
				DelLabel(ChartTags.Stoch, Labels[Stochs.Name][index_candle-1])
			end
			Labels[Stochs.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (Stochs.Slow[index_candle-1]*(100-2*ChartSteps.Stoch)/100), ChartTags.Stoch, "LStochVSteamer|"..tostring(Signals[Directions.Up].Stochs.VSteamer.Count), ChartLabelIcons.Triangle, SignalLevels.Impulse)
		end

		-- check stoch steamer down
		if (SignalOscVSteamer(Stochs, index_candle, Directions.Down)) then
			-- set elementary up signal off
			Signals[Directions.Up].Stochs.VSteamer.Candle = 0
			-- set elementary down signal on
			Signals[Directions.Down].Stochs.VSteamer.Candle = index_candle - 1
			Signals[Directions.Down].Stochs.VSteamer.Count = Signals[Directions.Down].Stochs.VSteamer.Count + 1
			-- set chart label
			if (Labels[Stochs.Name][index_candle-1] ~= nil) then
				DelLabel(ChartTags.Stoch, Labels[Stochs.Name][index_candle-1])
			end
			Labels[Stochs.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (Stochs.Slow[index_candle-1]*(100+2*ChartSteps.Stoch)/100), ChartTags.Stoch, "SStochVSteamer|"..tostring(Signals[Directions.Down].Stochs.VSteamer.Count), ChartLabelIcons.Triangle, SignalLevels.Impulse)
		end

		-- check stoch steamer up
		if (SignalOscHSteamer(Stochs, index_candle, Directions.Up)) then
			-- set elementary down signal off
			Signals[Directions.Down].Stochs.HSteamer.Candle = 0
			-- set elementary up signal on
			Signals[Directions.Up].Stochs.HSteamer.Candle = index_candle - 1
			Signals[Directions.Up].Stochs.HSteamer.Count = Signals[Directions.Up].Stochs.HSteamer.Count + 1
			-- set chart label
			if (Labels[Stochs.Name][index_candle-1] ~= nil) then
				DelLabel(ChartTags.Stoch, Labels[Stochs.Name][index_candle-1])
			end
			Labels[Stochs.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (Stochs.Slow[index_candle-1]*(100-6*ChartSteps.Stoch)/100), ChartTags.Stoch, "LStochHSteamer|"..tostring(Signals[Directions.Up].Stochs.HSteamer.Count).."|"..tostring(index_candle-1), ChartLabelIcons.Romb, SignalLevels.Impulse)
		end
		
		-- check stoch steamer down
		if (SignalOscHSteamer(Stochs, index_candle, Directions.Down)) then
			-- set elementary up signal off
			Signals[Directions.Up].Stochs.HSteamer.Candle = 0
			-- set elementary down signal on
			Signals[Directions.Down].Stochs.HSteamer.Candle = index_candle - 1
			Signals[Directions.Down].Stochs.HSteamer.Count = Signals[Directions.Down].Stochs.HSteamer.Count + 1
			-- set chart label
			if (Labels[Stochs.Name][index_candle-1] ~= nil) then
				DelLabel(ChartTags.Stoch, Labels[Stochs.Name][index_candle-1])
			end
			Labels[Stochs.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (Stochs.Slow[index_candle-1]*(100+6*ChartSteps.Stoch)/100), ChartTags.Stoch, "SStochHSteamer|"..tostring(Signals[Directions.Down].Stochs.HSteamer.Count).."|"..tostring(index_candle-1), ChartLabelIcons.Romb, SignalLevels.Impulse)
		end 
	end
	--#endregion 

	----------------------------------------------------------------------------
	--	III. Elementary RSI Signals
	----------------------------------------------------------------------------
	--
	--#region	III.1. Elementary RSI Signal: Signals[Directions.Down/Up].RSIs.Cross
	--				Impulse Signal: Signals[Directions.Down/Up].Impulse
	---				Depends on signal: SignalOscCross
	--				Terminates by signals: Reverse self-signal
	--				Terminates by duration: -
	--
	if (CheckDataSufficiency(index_candle, 2, RSIs.Slow) and CheckDataSufficiency(index_candle, 2, RSIs.Fast)) then
		--
		-- check fast rsi cross slow rsi up
		--
		if (SignalOscCross(RSIs, index_candle, Directions.Up)) then
			-- set elementary down signal off
			Signals[Directions.Down].RSIs.Cross.Candle = 0
			-- set elementary up signal on
			Signals[Directions.Up].RSIs.Cross.Candle = index_candle - 1
			Signals[Directions.Up].RSIs.Cross.Count = Signals[Directions.Up].RSIs.Cross.Count + 1

			-- set chart label
			if (Labels[RSIs.Name][index_candle-1] ~= nil) then
				DelLabel(ChartTags.RSI, Labels[RSIs.Name][index_candle-1])
			end
			Labels[RSIs.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (RSIs.Slow[index_candle-1]*(100-ChartSteps.RSI)/100), ChartTags.RSI, "LRSICross|Start|"..tostring(Signals[Directions.Up].RSIs.Cross.Count).."|"..(index_candle-1), ChartLabelIcons.Triangle, SignalLevels.Elementary)
		end

		--
		-- check fast rsi cross slow rsi down
		--
		if (SignalOscCross(RSIs, index_candle, Directions.Down)) then
			-- set elementary down signal off
			Signals[Directions.Up].RSIs.Cross.Candle = 0
			-- set elementary up signal on
			Signals[Directions.Down].RSIs.Cross.Candle = index_candle - 1
			Signals[Directions.Down].RSIs.Cross.Count = Signals[Directions.Down].RSIs.Cross.Count + 1

			-- set chart label
			if (Labels[RSIs.Name][index_candle-1] ~= nil) then
				DelLabel(ChartTags.RSI, Labels[RSIs.Name][index_candle-1])
			end
			Labels[RSIs.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (RSIs.Slow[index_candle-1]*(100+ChartSteps.RSI)/100), ChartTags.RSI,  "SRSICross|Start|"..tostring(Signals[Directions.Down].RSIs.Cross.Count).."|"..(index_candle-1), ChartLabelIcons.Triangle, SignalLevels.Elementary)
		end
	end
	--#endregion

	--
	--#region	III.2. Elementary RSI Signal: Signals[Directions.Down/Up].RSIs.Cross50
	--				Impulse Signal: Signals[Directions.Down/Up].Impulse
	---				Depends on signal: SignalOscCrossLevel
	--				Terminates by signals: Reverse self-signal
	--				Terminates by duration: -
	--
	if (CheckDataSufficiency(index_candle, 2, RSIs.Slow)) then
		--
		-- check slow rsi cross lvl50 up
		--
		if (SignalOscCrossLevel(RSIs.Slow, RSIs.Params.Levels.Center, index_candle, Directions.Up)) then
			-- set elementary down signal off
			Signals[Directions.Down].RSIs.Cross50.Candle = 0
			-- set elementary up signal on
			Signals[Directions.Up].RSIs.Cross50.Candle = index_candle - 1
			Signals[Directions.Up].RSIs.Cross50.Count = Signals[Directions.Up].RSIs.Cross50.Count + 1

			-- set chart label
			if (Labels[RSIs.Name][index_candle-1] ~= nil) then
				DelLabel(ChartTags.RSI, Labels[RSIs.Name][index_candle-1])
			end
			Labels[RSIs.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (RSIs.Slow[index_candle-1]*(100-2*ChartSteps.RSI)/100), ChartTags.RSI, "LRSICross50|Start|"..tostring(Signals[Directions.Up].RSIs.Cross50.Count).."|"..(index_candle-1), ChartLabelIcons.Arrow, SignalLevels.Elementary)
		end

		--
		-- check slow rsi cross lvl50 udown
		--
		if (SignalOscCrossLevel(RSIs.Slow, RSIs.Params.Levels.Center, index_candle, Directions.Down)) then
			-- set elementary down signal off
			Signals[Directions.Up].RSIs.Cross50.Candle = 0
			-- set elementary down signal on
			Signals[Directions.Down].RSIs.Cross50.Candle = index_candle - 1
			Signals[Directions.Down].RSIs.Cross50.Count = Signals[Directions.Down].RSIs.Cross50.Count + 1

			-- set chart label
			if (Labels[RSIs.Name][index_candle-1] ~= nil) then
				DelLabel(ChartTags.RSI, Labels[RSIs.Name][index_candle-1])
			end
			Labels[RSIs.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (RSIs.Slow[index_candle-1]*(100+2*ChartSteps.RSI)/100), ChartTags.RSI, "SRSICross50|Start|"..tostring(Signals[Directions.Down].RSIs.Cross50.Count).."|"..(index_candle-1), ChartLabelIcons.Arrow, SignalLevels.Elementary)
		end
	end
	--#endregion

	--
	--#region	III.3. Elementary RSI Signal: Signals[Directions.Down/Up].RSIs.TrendOn
	--				Enter Signals: Signals[Directions.Down/Up].TrendOn
	--				Depends on signal: SignalOscTrendOn
	--				Terminates by signals: Reverse self-signal,SignalOscTrendOff, SignalOscCross
	--				Terminates by duration: Signals.Params.Durations.Elementary
	--
	if (CheckDataSufficiency(index_candle, 2, RSIs.Slow)) then
		--
		-- check start elementary slow rsi enter on uptrend zone signal
		--
		if (SignalOscTrendOn(RSIs, index_candle, Directions.Up)) then
			-- set elementary down signal off
			Signals[Directions.Down].RSIs.TrendOn.Candle = 0
			-- set elementary up signal on
			Signals[Directions.Up].RSIs.TrendOn.Candle = index_candle - 1
			Signals[Directions.Up].RSIs.TrendOn.Count = Signals[Directions.Up].RSIs.TrendOn.Count + 1

			-- set chart label
			if (Labels[RSIs.Name][index_candle-1] ~= nil) then
				DelLabel(ChartTags.RSI, Labels[RSIs.Name][index_candle-1])
			end
			Labels[RSIs.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (RSIs.Slow[index_candle-1]*(100-3*ChartSteps.RSI)/100), ChartTags.RSI, "LRSITrendOn|Start|"..tostring(Signals[Directions.Up].RSIs.TrendOn.Count).."|"..(index_candle-1), ChartLabelIcons.Point, SignalLevels.Elementary)
		end

		-- check presence elementary up signal
		if (Signals[Directions.Up].RSIs.TrendOn.Candle > 0) then
			-- set duration elemenetary up signal
			local duration = index_candle - Signals[Directions.Up].RSIs.TrendOn.Candle
			-- check continuation elementary up signal
			if (duration <= Signals.Params.Durations.Elementary) then
				-- check termination by slow rsi enter off uptrend zone
				if (SignalOscTrendOff(RSIs, index_candle, Directions.Down)) then
					-- set elementary up signal off
					Signals[Directions.Up].RSIs.TrendOn.Candle = 0

					-- set chart label
					if (Labels[RSIs.Name][index_candle-1] ~= nil) then
						DelLabel(ChartTags.RSI, Labels[RSIs.Name][index_candle-1])
					end
					Labels[RSIs.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (RSIs.Slow[index_candle-1]*(100-3*ChartSteps.RSI)/100), ChartTags.RSI, "LRSITrendOff|End|"..tostring(Signals[Directions.Up].RSIs.TrendOn.Count).."|"..(duration-1).."|"..(index_candle-1), ChartLabelIcons.Cross, SignalLevels.Elementary)
				-- check termination by fast rsi cross slow rsi down
				elseif (SignalOscCross(RSIs, index_candle, Directions.Down)) then
						-- set elementary up signal off
						Signals[Directions.Up].RSIs.TrendOn.Candle = 0

						-- set chart label
						if (Labels[RSIs.Name][index_candle-1] ~= nil) then
							DelLabel(ChartTags.RSI, Labels[RSIs.Name][index_candle-1])
						end
						Labels[RSIs.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (RSIs.Slow[index_candle-1]*(100-3*ChartSteps.RSI)/100), ChartTags.RSI, "LRSICrossDown|End|"..tostring(Signals[Directions.Up].RSIs.TrendOn.Count).."|"..(duration-1).."|"..(index_candle-1), ChartLabelIcons.Cross, SignalLevels.Elementary)
				-- process continuation elementary up signal
				else
					-- set chart label
						-- if (Labels[RSIs.Name][index_candle] ~= nil) then
						-- 	DelLabel(ChartTags.RSI, Labels[RSIs.Name][index_candle])
						-- end
						--Labels[RSIs.Name][index_candle] = SetChartLabel(T(index_candle), (RSIs.Slow[index_candle]*(100-3*ChartSteps.RSI)/100), ChartTags.RSI, "LRSITrendOn|Continue|"..tostring(Signals[Directions.Up].RSIs.TrendOn.Count).."|"..duration.."|"..index_candle, ChartLabelIcons.Point, SignalLevels.Elementary)
				end
			-- check termination by duration elementary up signal
			elseif (duration > Signals.Params.Durations.Elementary) then
				-- set elementary up signal off
				Signals[Directions.Up].RSIs.TrendOn.Candle = 0

				-- set chart label
				if (Labels[RSIs.Name][index_candle] ~= nil) then
					DelLabel(ChartTags.Stoch, Labels[RSIs.Name][index_candle])
				end
				Labels[RSIs.Name][index_candle] = SetChartLabel(T(index_candle), (RSIs.Slow[index_candle]*(100-3*ChartSteps.RSI)/100), ChartTags.RSI, "LRSITrendOn|End|"..tostring(Signals[Directions.Up].RSIs.TrendOn.Count).."|"..duration.."|"..index_candle, ChartLabelIcons.Cross, SignalLevels.Elementary)
			end
		end

		--
		-- check start elementary slow rsi enter on down trend zone signal
		--
		if (SignalOscTrendOn(RSIs, index_candle, Directions.Down)) then
			-- set elementary up signal off
			Signals[Directions.Up].RSIs.TrendOn.Candle = 0
			-- set elementary down signal on
			Signals[Directions.Down].RSIs.TrendOn.Candle = index_candle - 1
			Signals[Directions.Down].RSIs.TrendOn.Count = Signals[Directions.Down].RSIs.TrendOn.Count + 1

			-- set chart label
			if (Labels[RSIs.Name][index_candle-1] ~= nil) then
				DelLabel(ChartTags.RSI, Labels[RSIs.Name][index_candle-1])
			end
			Labels[RSIs.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (RSIs.Slow[index_candle-1]*(100+3*ChartSteps.RSI)/100), ChartTags.RSI,  "SRSITrendOn|Start|"..tostring(Signals[Directions.Down].RSIs.TrendOn.Count).."|"..(index_candle-1), ChartLabelIcons.Point, SignalLevels.Elementary)
		end

		-- check presence elementary down signal
		if (Signals[Directions.Down].RSIs.TrendOn.Candle > 0) then
			-- set duration elemenetary down signal
			local duration = index_candle - Signals[Directions.Down].RSIs.TrendOn.Candle
			-- check continuation elementary down signal
			if (duration <= Signals.Params.Durations.Elementary) then
				-- check termination by slow rsi enter off downtrend zone
				if (SignalOscTrendOff(RSIs, index_candle, Directions.Up)) then
					-- set elementary down signal off
					Signals[Directions.Down].RSIs.TrendOn.Candle = 0

					-- set chart label
					if (Labels[RSIs.Name][index_candle-1] ~= nil) then
						DelLabel(ChartTags.RSI, Labels[RSIs.Name][index_candle-1])
					end
					Labels[RSIs.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (RSIs.Slow[index_candle-1]*(100+3*ChartSteps.RSI)/100), ChartTags.RSI, "SRSITrendOff|End|"..tostring(Signals[Directions.Down].RSIs.TrendOn.Count).."|"..(duration-1).."|"..(index_candle-1), ChartLabelIcons.Cross, SignalLevels.Elementary)
				-- check termination by fast rsi cross slow rsi down
				elseif (SignalOscCross(RSIs, index_candle, Directions.Down)) then
					Signals[Directions.Up].RSIs.TrendOn.Candle = 0

					-- set chart label
					if (Labels[RSIs.Name][index_candle-1] ~= nil) then
						DelLabel(ChartTags.RSI, Labels[RSIs.Name][index_candle-1])
					end
					Labels[RSIs.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (RSIs.Slow[index_candle-1]*(100+3*ChartSteps.RSI)/100), ChartTags.RSI, "SRSICrossUp|End|"..tostring(Signals[Directions.Up].RSIs.TrendOn.Count).."|"..(duration-1).."|"..(index_candle-1), ChartLabelIcons.Cross, SignalLevels.Elementary)
				-- process continuation elementary down signal
				else
					-- set chart label
					-- if (Labels[RSIs.Name][index_candle] ~= nil) then
					-- 	DelLabel(ChartTags.RSI, Labels[RSIs.Name][index_candle])
					-- end
					--Labels[RSIs.Name][index_candle] = SetChartLabel(T(index_candle), (RSIs.Slow[index_candle]*(100+3*ChartSteps.RSI)/100), ChartTags.RSI, "SRSITrendOn|Continue|"..tostring(Signals[Directions.Down].RSIs.TrendOn.Count).."|"..duration.."|"..index_candle, ChartLabelIcons.Point, SignalLevels.Elementary)
				end
			-- check termination by duration elementary down signal
			elseif (duration > Signals.Params.Durations.Elementary) then
				-- set elementary down signal off
				Signals[Directions.Down].RSIs.TrendOn.Candle = 0

				-- set chart label
				if (Labels[RSIs.Name][index_candle] ~= nil) then
					DelLabel(ChartTags.RSI, Labels[RSIs.Name][index_candle])
				end
				Labels[RSIs.Name][index_candle] = SetChartLabel(T(index_candle), (RSIs.Slow[index_candle]*(100+3*ChartSteps.RSI)/100), ChartTags.RSI, "SRSITrendOn|End|"..tostring(Signals[Directions.Down].RSIs.TrendOn.Count).."|"..duration.."|"..index_candle, ChartLabelIcons.Cross, SignalLevels.Elementary)
			end
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

    return BBs.Top[index_candle], MAs[index_candle], BBs.Bottom[index_candle]
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
    local highs = {}
    local lows = {}
    local candles = { processed = 0, count = 0 }

    return function (index_candle)
        if (PCs.Params.Period > 0) then
            -- first candle - reinit vars
            if (index_candle == 1) then
                highs = {}
                lows = {}
                candles = { processed = 0, count = 0 }
            end

            if CandleExist(index_candle) then
                -- new candle - new processed candle and increased count processed candle
                if (index_candle ~= candles.processed) then
                    candles = { processed = index_candle, count = candles.count + 1 }
                end

                -- insert high and low to circle buffer
                highs[Squeeze(candles.count, PCs.Params.Period - 1) + 1] = H(candles.processed)
                lows[Squeeze(candles.count, PCs.Params.Period - 1) + 1] = L(candles.processed)

                -- calc and return max results
                if (candles.count >= PCs.Params.Period) then
                    local max_high = math.max(table.unpack(highs))
                    local max_low = math.min(table.unpack(lows))

                    return max_high, max_low
                end
            end
        end
        return nil, nil
    end
end
--#endregion

--==========================================================================
--#region	INDICATOR BB
--==========================================================================
----------------------------------------------------------------------------
--	function BolBands
----------------------------------------------------------------------------
function BolBands()
	local BB_ma = VMA()
	local BB_sd = SD()

	local Itterations = { processed = 0, count = 0 }

	return function (index_candle)
		if (BBs.Params.Period > 0) then
			if (index_candle == 1) then
				Itterations = { processed = 0, count = 0 }
			end

			local b_ma = BB_ma(index_candle)
			local b_sd = BB_sd(index_candle)

			if (CandleExist(index_candle)) then
				if (index_candle ~= Itterations.processed) then
					Itterations = { processed = index_candle, count = Itterations.count + 1 }
				end

				if ((Itterations.count >= BBs.Params.Period) and (b_ma and b_sd)) then
					return b_ma, (b_ma + BBs.Params.Shift * b_sd), (b_ma - BBs.Params.Shift * b_sd)
				end
			end
		end
		return nil, nil, nil
	end
end

----------------------------------------------------------------------------
-- function SD
----------------------------------------------------------------------------
function SD()
	local SD_ma = SMAQueued()

	local Sums = {}
	local Sums2 = {}
	local Itterations = { processed = 0, count = 0 }

	return function (index_candle)
		if (BBs.Params.Period > 0) then
			if (index_candle == 1) then
				Sums = {}
				Sums2 = {}
				Itterations = { processed = 0, count = 0 }
			end

			local t_ma = SD_ma(index_candle)

			if CandleExist(index_candle) then
				if (index_candle ~= Itterations.processed) then
					Itterations = { processed = index_candle, count = Itterations.count + 1 }
				end

				local index1 = Squeeze(Itterations.count, BBs.Params.Period)
				local index2 = Squeeze(Itterations.count - 1, BBs.Params.Period)
				local index3 = Squeeze(Itterations.count - BBs.Params.Period, BBs.Params.Period)

				Sums[index1] = (Sums[index2] or 0) + C(Itterations.processed)
				Sums2[index1] = (Sums2[index2] or 0) + C(Itterations.processed) ^ 2

				if ((Itterations.count >= BBs.Params.Period) and t_ma) then

					return math.sqrt((Sums2[index1] - (Sums2[index3] or 0) - 2 * t_ma * (Sums[index1] - (Sums[index3] or 0)) + BBs.Params.Period * (t_ma ^ 2)) / BBs.Params.Period)
				end
			end
		end
		return nil
	end
end

----------------------------------------------------------------------------
--	functin VMA = sums(Pi*Vi) / sums(Vi)
----------------------------------------------------------------------------
function VMA()
	local Sums_price_volume = {}
	local Sums_volume = {}
	local Itterations = { processed = 0, count = 0 }

	return function(index_candle)
		if (index_candle == 1) then
			Sums_price_volume = {}
			Sums_volume = {}
			Itterations = { processed = 0, count = 0 }
		end

		if CandleExist(index_candle) then
			if (index_candle ~= Itterations.processed) then
				Itterations = { processed = index_candle, count = Itterations.count + 1 }
			end

			local index1 = Squeeze(Itterations.count, BBs.Params.Period)
			local index2 = Squeeze(Itterations.count - 1, BBs.Params.Period)
			local index3 = Squeeze(Itterations.count - BBs.Params.Period, BBs.Params.Period)

			Sums_price_volume[index1] = (Sums_price_volume[index2] or 0) + C(Itterations.processed) * V(Itterations.processed)
			Sums_volume[index1] = (Sums_volume[index2] or 0) + V(Itterations.processed)

			if (Itterations.count >= BBs.Params.Period) then
				return (Sums_price_volume[index1] - (Sums_price_volume[index3] or 0)) / (Sums_volume[index1] - (Sums_volume[index3] or 0))
			end
		end
		return nil
	end
end

----------------------------------------------------------------------------
--	function SMA = sums(Pi) / n !QUEUED!
----------------------------------------------------------------------------
function SMAQueued()
	local Sum = 0
	local Queue = {}

	return function (index_candle)
		if (index_candle == 1) then
			Queue = {}
			Sum = 0
		end

		if CandleExist(index_candle) then
			table.insert(Queue, C(index_candle))
			Sum = Sum + Queue[#Queue]

			if (#Queue == BBs.Params.Period) then
				local sma = Sum / BBs.Params.Period
				Sum = Sum - Queue[1]
				table.remove(Queue, 1)
				return sma
			end
		end
		return nil
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
-- Signal Osc Vertical Steamer
--
function SignalOscVSteamer(osc, index, direction, dev)
	local dev = dev or Signals.Params.Steamer.Dev

	return ((SignalMove(osc.Fast, index, direction) and SignalMove(osc.Slow, index, direction)) and
			(IsRelate(osc.Fast[index-2], osc.Slow[index-2], direction) and IsRelate(osc.Fast[index-1], osc.Slow[index-1], direction)) and
			(GetDelta(osc.Fast[index-2], osc.Slow[index-2]) <= dev) and (GetDelta(osc.Fast[index-1], osc.Slow[index-1]) <= dev))
end

--
-- Signal Osc Horisontal Steamer
--
function SignalOscHSteamer(osc, index, direction)
	if (SignalOscCrossLevel(osc.Slow, Stochs.Params.Levels.Center, index, direction)) then
		-- for count = 1, Signals.Params.Steamer.Duration do
			-- if (SignalOscCrossLevel(osc.Fast, Stochs.Params.Levels.Center, (index-count), direction)) then
				
			-- 	if (Labels[Stochs.Name][index-count] ~= nil) then
			-- 		DelLabel(ChartTags.Stoch, Labels[Stochs.Name][index-count])
			-- 	end
			-- 	Labels[Stochs.Name][index-count] = SetChartLabel(T(index-count), Stochs.Slow[index-count], ChartTags.Stoch, direction.."|"..tostring(index-count), ChartLabelIcons.Asterix, SignalLevels.Impulse)

				return ((SignalMove(osc.Fast, index, direction) and SignalMove(osc.Slow, index, direction)) and
						(IsRelate(osc.Fast[index-2], osc.Slow[index-2], direction) and IsRelate(osc.Fast[index-1], osc.Slow[index-1], direction)))
			-- end
		-- end
	end
	return false
end

--
-- Signal Oscs Fast Cross Slow
--
function SignalOscCross(osc, index, direction, dev)
	local dev = dev or 0

	return SignalCross(osc.Fast, osc.Slow, index, direction, dev)
end

--
-- Signal Osc Cross Level
--
function SignalOscCrossLevel(osc, level, index, direction, dev)
	local dev = dev or 0

	return SignalCross(osc, {[index-2] = level, [index-1] = level}, index, direction, dev)
end

--
-- SignalOscTrendOn
--
function SignalOscTrendOn(osc, index, direction)
	direction = string.upper(string.sub(direction, 1, 1))
	local level

	if (osc.Name == RSIs.Name) then
		if (direction == Directions.Up) then
			level = RSIs.Params.Levels.TopTrend
		elseif (direction == Directions.Down) then
			level = RSIs.Params.Levels.BottomTrend
		else
			return false
		end
	elseif (osc.Name == Stochs.Name) then
		if (direction == Directions.Up) then
			level = Stochs.Params.Levels.Top
		elseif (direction == Directions.Down) then
			level = Stochs.Params.Levels.Bottom
		else
			return false
		end
	else
		return false
	end

	return  SignalOscCrossLevel(osc.Slow, level, index, direction, dev)
end

--
-- SignalOscTrendOff
--
function SignalOscTrendOff(osc, index, direction)
	direction = string.upper(string.sub(direction, 1, 1))
	local level

	if (osc.Name == RSIs.Name) then
		if (direction == Directions.Up) then
			level = RSIs.Params.Levels.BottomTrend
		elseif (direction == Directions.Down) then
			level = RSIs.Params.Levels.TopTrend
		else
			return false
		end
	elseif (osc.Name==Stochs.Name) then
		if (direction == Directions.Up) then
			level = Stochs.Params.Levels.Bottom
		elseif (direction == Directions.Down) then
			level = Stochs.Params.Levels.Top
		else
			return false
		end
	else
		return false
	end

	return  SignalOscCrossLevel(osc.Slow, level, index, direction, dev)
end
--#endregion

----------------------------------------------------------------------------
--#region	Price Signals
----------------------------------------------------------------------------
--
-- Signal Price Cross MA
--
function SignalPriceCrossMA(price, ma, index, direction, dev)
	local dev = dev or 0

			-- candle up
	return (-- IsRelate(price.Close[index-1], price.Open[index-1], direction) and
			-- candle cross ma up
			SignalCross(price.Close, ma, index, direction, dev))
end
--#endregion

----------------------------------------------------------------------------
--#region	Elementary Signals
----------------------------------------------------------------------------
--
-- Signal Value1 cross Value2 up and down
--
function SignalCross(value1, value2, index, direction, dev)
	local dev = dev or 0
	direction = string.upper(string.sub(direction, 1, 1))

	if (direction == Directions.Up) then
		return (((value2[index-2] + dev) >= value1[index-2]) and (value1[index-1] >= (value2[index-1] - dev)))

	elseif (direction == Directions.Down) then
		return ((value1[index-2] >= (value2[index-2] - dev)) and ((value2[index-1] + dev) >= value1[index-1]))
	end

	return false
end

--
-- Signal 2 last candles Value move up or down
--
function SignalMove(value, index, direction)
	direction = string.upper(string.sub(direction, 1, 1))

	if (direction == Directions.Up) then
		return (value[index-1] > value[index-2])

	elseif (direction == Directions.Down) then
		return (value[index-2] > value[index-1])
	end

	return false
end

--
-- Signal 3 last candles Value uturn up or down FIXME: code 5 candles
--
function SignalUturn(value, index, direction)
	direction = string.upper(string.sub(direction, 1, 1))

	if (direction == Directions.Up) then
		return ((value[index-3] > value[index-2]) and (value[index-1] > value[index-2]))

	elseif (direction == Directions.Down) then
		return ((value[index-2] > value[index-3]) and (value[index-2] > value[index-1]))
	end

	return false
end

--
-- Condition is over or under Value2
--
function IsRelate(value1, value2, direction, dev)
	local dev = dev or 0
	direction = string.upper(string.sub(direction, 1, 1))

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
-- function Reverse
----------------------------------------------------------------------------
function Reverse(direction)
	direction = string.upper(string.sub(direction, 1, 1))
	if (direction == Directions.Up) then
		return Directions.Down
	elseif (direction == Directions.Down) then
		return Directions.Up
	else
		return nil
	end
end

----------------------------------------------------------------------------
-- function GetDelta
----------------------------------------------------------------------------
function GetDelta(value1, value2)
	return math.abs(value1 - value2)
end

----------------------------------------------------------------------------
--	function PrintDebugMessage(message1, message2, ...)
----------------------------------------------------------------------------
function PrintDebugMessage(...)
	local args = { n = select("#",...), ... }
	if (args.n > 0) then
		local count
		local tmessage = {}

		for count = 1, args.n do
			table.insert(tmessage, tostring(args[count]))
		end

		local smessage = table.concat(tmessage, "|")

		message(smessage)
		PrintDbgStr("QUIK|" .. smessage)
		return args.n
	else
		return 0
	end
end

----------------------------------------------------------------------------
-- function Squeeze
----------------------------------------------------------------------------
function Squeeze(index, period)
	return math.fmod(index - 1, period + 1)
end

----------------------------------------------------------------------------
--	function RoundScale
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
--	function SetChartLabel
----------------------------------------------------------------------------
function SetChartLabel(x_value, y_value, chart_tag, text, icon, signal_level)
	local chart_level

	if (chart_tag == ChartTags.Price) then
		chart_level, _, _ = GetParams(ChartsParam)
	elseif (chart_tag == ChartTags.Stoch) then
		_, chart_level, _ = GetParams(ChartsParam)
	elseif (chart_tag == ChartTags.RSI) then
		_, _, chart_level = GetParams(ChartsParam)
	end

	if (((GetLevelParams(signal_level).Elementary > 0) and (GetLevelParams(chart_level).Elementary > 0)) or
	((GetLevelParams(signal_level).Impulse > 0) and (GetLevelParams(chart_level).Impulse > 0)) or
	((GetLevelParams(signal_level).Trend > 0) and (GetLevelParams(chart_level).Trend > 0)) or
	((GetLevelParams(signal_level).Enter > 0) and (GetLevelParams(chart_level).Enter > 0))) then

		local direction = string.upper(string.sub(text, 1, 1))
		if (direction == Directions.Up) then
			LabelParams.ALIGNMENT = "BOTTOM"
		elseif (direction == Directions.Down) then
			LabelParams.ALIGNMENT = "TOP"
		else
			return -1
		end

		icon = (icon and string.upper(string.sub(icon, 1, 1))) or ChartLabelIcons.Arrow

		if (icon == ChartLabelIcons.Arrow) then
			if (direction == Directions.Up) then
				LabelParams.IMAGE_PATH = IconPath .. "arrow_up.jpg"
			elseif (direction == Directions.Down) then
				LabelParams.IMAGE_PATH = IconPath .. "arrow_down.jpg"
			end
		elseif (icon == ChartLabelIcons.Point) then
			if (direction == Directions.Up) then
				LabelParams.IMAGE_PATH = IconPath .. "point_up.jpg"
			elseif (direction == Directions.Down) then
				LabelParams.IMAGE_PATH = IconPath .. "point_down.jpg"
			end
		elseif (icon == ChartLabelIcons.Triangle) then
			if (direction == Directions.Up) then
				LabelParams.IMAGE_PATH = IconPath .. "triangle_up.jpg"
			elseif (direction == Directions.Down) then
				LabelParams.IMAGE_PATH = IconPath .. "triangle_down.jpg"
			end
		elseif (icon == ChartLabelIcons.Cross) then
			if (direction == Directions.Up) then
				LabelParams.IMAGE_PATH = IconPath .. "cross_up.jpg"
			elseif (direction == Directions.Down) then
				LabelParams.IMAGE_PATH = IconPath .. "cross_down.jpg"
			end
		elseif (icon == ChartLabelIcons.Romb) then
			if (direction == Directions.Up) then
				LabelParams.IMAGE_PATH = IconPath .. "romb_up.jpg"
			elseif (direction == Directions.Down) then
				LabelParams.IMAGE_PATH = IconPath .. "romb_down.jpg"
			end
		elseif (icon == ChartLabelIcons.Plus) then
			if (direction == Directions.Up) then
				LabelParams.IMAGE_PATH = IconPath .. "plus_up.jpg"
			elseif (direction == Directions.Down) then
				LabelParams.IMAGE_PATH = IconPath .. "plus_down.jpg"
			end
		elseif (icon == ChartLabelIcons.Flash) then
			if (direction == Directions.Up) then
				LabelParams.IMAGE_PATH = IconPath .. "flash_up.jpg"
			elseif (direction == Directions.Down) then
				LabelParams.IMAGE_PATH = IconPath .. "flash_down.jpg"
			end
		elseif (icon == ChartLabelIcons.Asterix) then
			if (direction == Directions.Up) then
				LabelParams.IMAGE_PATH = IconPath .. "asterix_up.jpg"
			elseif (direction == Directions.Down) then
				LabelParams.IMAGE_PATH = IconPath .. "asterix_down.jpg"
			end
		elseif (icon == ChartLabelIcons.BigArrow) then
			if (direction == Directions.Up) then
				LabelParams.IMAGE_PATH = IconPath .. "big_arrow_up.jpg"
			elseif (direction == Directions.Down) then
				LabelParams.IMAGE_PATH = IconPath .. "big_arrow_down.jpg"
			end
		elseif (icon == ChartLabelIcons.BigPoint) then
			if (direction == Directions.Up) then
				LabelParams.IMAGE_PATH = IconPath .. "big_point_up.jpg"
			elseif (direction == Directions.Down) then
				LabelParams.IMAGE_PATH = IconPath .. "big_point_down.jpg"
			end
		elseif (icon == ChartLabelIcons.BigTriangle) then
			if (direction == Directions.Up) then
				LabelParams.IMAGE_PATH = IconPath .. "big_triangle_up.jpg"
			elseif (direction == Directions.Down) then
				LabelParams.IMAGE_PATH = IconPath .. "big_triangle_down.jpg"
			end
		elseif (icon == ChartLabelIcons.BigCross) then
			if (direction == Directions.Up) then
				LabelParams.IMAGE_PATH = IconPath .. "big_cross_up.jpg"
			elseif (direction == Directions.Down) then
				LabelParams.IMAGE_PATH = IconPath .. "big_cross_down.jpg"
			end
		elseif (icon == ChartLabelIcons.BigRomb) then
			if (direction == Directions.Up) then
				LabelParams.IMAGE_PATH = IconPath .. "big_romb_up.jpg"
			elseif (direction == Directions.Down) then
				LabelParams.IMAGE_PATH = IconPath .. "big_romb_down.jpg"
			end
		elseif (icon == ChartLabelIcons.BigPlus) then
			if (direction == Directions.Up) then
				LabelParams.IMAGE_PATH = IconPath .. "big_plus_up.jpg"
			elseif (direction == Directions.Down) then
				LabelParams.IMAGE_PATH = IconPath .. "big_plus_down.jpg"
			end
		else
			return -1
		end

		LabelParams.HINT = text
		--LabelParams.TEXT = text
		LabelParams.YVALUE = y_value

		LabelParams.DATE = tostring(10000 * x_value.year + 100 * x_value.month + x_value.day)
		LabelParams.TIME = tostring(10000 * x_value.hour + 100 *  x_value.min + x_value.sec)

		return AddLabel(chart_tag, LabelParams)
	else
		return 0
	end
end

----------------------------------------------------------------------------
--	function Set and Get flags
----------------------------------------------------------------------------
function SetParam(price, stoch, rsi)
	return (256 * price + 16 * stoch + rsi)
end

function GetParams(flag)
	local price = math.floor(flag / 256)
	local stoch = math.floor((flag - price * 256) / 16)
	local rsi = flag - price * 256 - stoch * 16

	return price, stoch, rsi
end

function GetLevelParams(flag)
	local result = {}

	result.Enter = flag & 8
	result.Trend = flag & 4
	result.Impulse = flag & 2
	result.Elementary = flag & 1

	return result
end

----------------------------------------------------------------------------
--	function CheckDataSufficiency
----------------------------------------------------------------------------
function CheckDataSufficiency(index, number, value)
	if (index <= number) then
		return false
	end

	local count
	for count = 1, number, 1 do
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