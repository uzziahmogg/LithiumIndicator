--==========================================================================
--	Indicator Lithium, 2021 (c) FEK
--==========================================================================
--
--! !!!make stoch steamer signal
--! 	make signal simpler using 
--! recode function SetChartLabel to use array Labels
--! move long/short signals under proper trend
--! convert suficciency data for index_candle more then max params length
--! use lua bit functions instead quik bit.functions
--todo create function for check elementary/complex signals
--todo signals to close - duration/end of elementary signal (trendoff)//end of impulse signal(reverse osc cross/cross50) but i mean stair closing allready worked
--todo make different duration for 3 and 4 candles signals
--todo enter after first trend+impulse - first leg of uturn4/spring4 is first protrend impulse
--* create mech for turning showing on/off every elementary signal ie steamer
--* create permanent logging subsystem
--*		export log to excel for external metrics test
--*	use different flags to create/append file operations
--*	create transaction to open position mechs
--*	create stare closing position mechs
--*	create risk management via pause in trading
--*		create deal financial result mechs
--*	create multiinstrument mechs
--*		create determenation money pie per instrument mechs
--*	create 2 additional signals
--*		signal zigzag at ma
--*		signal diver
--* 		Spring3 work only on ext may be use for diver
--*		trend bias!
--*	create mech to move stoploss to local extremum
--? create termination stoch uturn3/4/Spring3/4 signals after reverse stoch cross
--?	create web api for grafana/chart.js/dart+flutter dashboard
--?	there are 4 trend filters
--?		ma/stoch moves
--?		BBdelta growth
--?		cross price chanell
--?		little filter cross dev
--// signals table with dependences, includes swithing on and off
--// signal sign set on prev candle and not set in current candle
--// RSITrendOn terminated with reverse RSITrendoff and RSICross
----------------------------------------------------------------------------
-- array Settings
----------------------------------------------------------------------------

Settings = {	Name = "FEK_LITHIUM",
				line = {{	Name = "BB",
							Type = TYPE_LINE,
							Color = RGB(221, 44, 44) },
						{	Name = "BBTop",
							Type = TYPE_LINE,
							Color = RGB(0, 206, 0) },
						{	Name = "BBBottom",
							Type = TYPE_LINE,
							Color = RGB(0, 162, 232) }}}

--==========================================================================
--#region function Init
--==========================================================================
function Init()
	-- indicators data arrays and params
	Stochs = { Name = "Stoch", Fast = {}, Slow = {}, Delta = {}, Params = { Levels = { Top = 80, Center = 50, Bottom = 20 }, Slow = { PeriodK = 10, Shift = 3, PeriodD = 1 }, Fast = { PeriodK = 5, Shift = 2, PeriodD = 1}} }
	BBs = { Name = "BB", Top = {}, Bottom = {}, Delta = {}, Params = { Period = 20,  Shift = 2 } }
	MAs = { Name = "MA", Delta = {} }
	Prices = { Name = "Price", Open = {}, Close = {}, High = {}, Low = {}  }
	RSIs = { Name = "RSI", Fast = {}, Slow = {}, Delta = {}, Params = { Levels = { Top = 80, TopTrend = 60, Center = 50, BottomTrend = 40, Bottom = 20 }, PeriodSlow = 14, PeriodFast = 9 } }

	-- log levels
	LogLevels = { Quiet = "Quiet", Normal = "Normal", Verbose = "Verbose" }

	-- levels to show labels on charts
	SignalLevels = { Elementary = 1, Impulse = 2, Trend = 4, Enter = 8 }

	-- directions for signals, labels and deals
	Directions = { Up = "L", Down = "S" }

	-- tags for charts to show labels
	ChartTags = { 	Stoch = Settings.Name .. Stochs.Name ,  	-- FEK_LITHIUMStoch
					Price = Settings.Name .. Prices.Name, 	-- FEK_LITHIUMPrice
					RSI = Settings.Name .. RSIs.Name }		-- FEK_LITHIUMRSI

	-- steps for text labels on charts
	ChartSteps = { Price = 15, Stoch = 10, RSI = 5 }

	-- chart labels ids
	Labels = { [Prices.Name] = {}, [Stochs.Name] = {}, [RSIs.Name] = {} }

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

	-- signals start candles and counts
	Signals = {	[Directions.Up] = { TrendOn = { Count = 0, Candle = 0 }, Uturn = { Count = 0, Candle = 0 }, Spring1 = { Count = 0, Candle = 0 }, Spring2 = { Count = 0, Candle = 0 }, 
	Trend = { Count = 0, Candle = 0}, Impulse = { Count = 0, Candle = 0}, Enter = { Count = 0, Candle = 0 }, 
	Prices = { CrossMA = { Count = 0, Candle = 0 }, Uturn3 = { Count = 0, Candle = 0 }, Uturn4 = { Count = 0, Candle = 0 }}, 
	Stochs = { Cross = { Count = 0, Candle = 0 }, Cross50 = { Count = 0, Candle = 0 }, Uturn3 = { Count = 0, Candle = 0 }, Uturn4 = { Count = 0, Candle = 0 }, Spring3 = { Count = 0, Candle = 0 }, Spring4 = { Count = 0, Candle = 0 }, HSteamer = { Count = 0, Candle = 0 }, VSteamer = { Count = 0, Candle = 0 }}, 
	RSIs = {	Cross = { Count = 0, Candle = 0 }, Cross50 = { Count = 0, Candle = 0 }, Uturn3 = { Count = 0, Candle = 0 }, Uturn4 = { Count = 0, Candle = 0 }, Spring3 = { Count = 0, Candle = 0 }, Spring4 = { Count = 0, Candle = 0 }, TrendOn = { Count = 0, Candle = 0 }}}, 
	[Directions.Down] = { TrendOn = { Count = 0, Candle = 0 }, Uturn = { Count = 0, Candle = 0 }, Spring1 = { Count = 0, Candle = 0 }, Spring2 = { Count = 0, Candle = 0 }, 
	Trend = { Count = 0, Candle = 0}, Impulse = { Count = 0, Candle = 0}, Enter = { Count = 0, Candle = 0 }, 
	Prices = { CrossMA = { Count = 0, Candle = 0 }, Uturn3 = { Count = 0, Candle = 0 }, Uturn4 = { Count = 0, Candle = 0 }}, 
	Stochs = { Cross = { Count = 0, Candle = 0 }, Cross50 = { Count = 0, Candle = 0 }, Uturn3 = { Count = 0, Candle = 0 }, Uturn4 = { Count = 0, Candle = 0 }, Spring3 = { Count = 0, Candle = 0 }, Spring4 = { Count = 0, Candle = 0 }, HSteamer = { Count = 0, Candle = 0 }, VSteamer = { Count = 0, Candle = 0 }},
	RSIs = {	Cross = { Count = 0, Candle = 0 }, Cross50 = { Count = 0, Candle = 0 }, Uturn3 = { Count = 0, Candle = 0 }, Uturn4 = { Count = 0, Candle = 0 }, Spring3 = { Count = 0, Candle = 0 }, Spring4 = { Count = 0, Candle = 0 }, TrendOn = { Count = 0, Candle = 0 }}},
	Params = { Durations = { Elementary = 4, Enter = 3 }, Steamer = { Dev = 30, Duration = 2 }}} 

	return #Settings.line
end
--#endregion

--==========================================================================
--#region	function OnCalculate
--==========================================================================
function OnCalculate(index_candle)
	if (index_candle == 1) then
		LogLevel = LogLevels.Verbose
		ChartsParam = SetParam(0, SignalLevels.Impulse, 0)

		DataSource = getDataSourceInfo()
		SecInfo = getSecurityInfo(DataSource.class_code, DataSource.sec_code)

		--#region init Signals Candles and Counts
		-- Enter Signals
		Signals[Directions.Up].TrendOn.Count = 0
		Signals[Directions.Up].TrendOn.Candle = 0
		Signals[Directions.Up].Uturn.Count = 0
		Signals[Directions.Up].Uturn.Candle = 0
		Signals[Directions.Up].Spring1.Count = 0
		Signals[Directions.Up].Spring1.Candle = 0
		Signals[Directions.Up].Spring2.Count = 0
		Signals[Directions.Up].Spring2.Candle = 0

		-- Complex Trend Impulse and Enter Signals
		Signals[Directions.Up].Trend.Count = 0
		Signals[Directions.Up].Trend.Candle = 0
		Signals[Directions.Up].Impulse.Count = 0
		Signals[Directions.Up].Impulse.Candle = 0
		Signals[Directions.Up].Enter.Count = 0
		Signals[Directions.Up].Enter.Candle = 0

		-- Elementary Signals
		Signals[Directions.Up].Prices.CrossMA.Count = 0
		Signals[Directions.Up].Prices.CrossMA.Candle = 0
		Signals[Directions.Up].Prices.Uturn3.Count = 0
		Signals[Directions.Up].Prices.Uturn3.Candle = 0
		Signals[Directions.Up].Prices.Uturn4.Count = 0
		Signals[Directions.Up].Prices.Uturn4.Candle = 0

		Signals[Directions.Up].Stochs.Cross.Count = 0
		Signals[Directions.Up].Stochs.Cross.Candle = 0
		Signals[Directions.Up].Stochs.Cross50.Count = 0
		Signals[Directions.Up].Stochs.Cross50.Candle = 0
		Signals[Directions.Up].Stochs.Uturn3.Count = 0
		Signals[Directions.Up].Stochs.Uturn3.Candle = 0
		Signals[Directions.Up].Stochs.Uturn4.Count = 0
		Signals[Directions.Up].Stochs.Uturn4.Candle = 0
		Signals[Directions.Up].Stochs.Spring3.Count = 0
		Signals[Directions.Up].Stochs.Spring3.Candle = 0
		Signals[Directions.Up].Stochs.Spring4.Count = 0
		Signals[Directions.Up].Stochs.Spring4.Candle = 0
		Signals[Directions.Up].Stochs.HSteamer.Count = 0
		Signals[Directions.Up].Stochs.HSteamer.Candle = 0
		Signals[Directions.Up].Stochs.VSteamer.Count = 0
		Signals[Directions.Up].Stochs.VSteamer.Candle = 0

		Signals[Directions.Up].RSIs.Cross.Count = 0
		Signals[Directions.Up].RSIs.Cross.Candle = 0
		Signals[Directions.Up].RSIs.Cross50.Count = 0
		Signals[Directions.Up].RSIs.Cross50.Candle = 0
		Signals[Directions.Up].RSIs.Uturn3.Count = 0
		Signals[Directions.Up].RSIs.Uturn3.Candle = 0
		Signals[Directions.Up].RSIs.Uturn4.Count = 0
		Signals[Directions.Up].RSIs.Uturn4.Candle = 0
		Signals[Directions.Up].RSIs.Spring3.Count = 0
		Signals[Directions.Up].RSIs.Spring3.Candle = 0
		Signals[Directions.Up].RSIs.Spring4.Count = 0
		Signals[Directions.Up].RSIs.Spring4.Candle = 0
		Signals[Directions.Up].RSIs.TrendOn.Count = 0
		Signals[Directions.Up].RSIs.TrendOn.Candle = 0

		-- Enter Signals
		Signals[Directions.Down].TrendOn.Count = 0
		Signals[Directions.Down].TrendOn.Candle = 0
		Signals[Directions.Down].Uturn.Count = 0
		Signals[Directions.Down].Uturn.Candle = 0
		Signals[Directions.Down].Spring1.Count = 0
		Signals[Directions.Down].Spring1.Candle = 0
		Signals[Directions.Down].Spring2.Count = 0
		Signals[Directions.Down].Spring2.Candle = 0

		-- Complex Trend Impulse and Enter Signals
		Signals[Directions.Down].Trend.Count = 0
		Signals[Directions.Down].Trend.Candle = 0
		Signals[Directions.Down].Impulse.Count = 0
		Signals[Directions.Down].Impulse.Candle = 0
		Signals[Directions.Down].Enter.Count = 0
		Signals[Directions.Down].Enter.Candle = 0

		-- Elementary Signals
		Signals[Directions.Down].Prices.CrossMA.Count = 0
		Signals[Directions.Down].Prices.CrossMA.Candle = 0
		Signals[Directions.Down].Prices.Uturn3.Count = 0
		Signals[Directions.Down].Prices.Uturn3.Candle = 0
		Signals[Directions.Down].Prices.Uturn4.Count = 0
		Signals[Directions.Down].Prices.Uturn4.Candle = 0

		Signals[Directions.Down].Stochs.Cross.Count = 0
		Signals[Directions.Down].Stochs.Cross.Candle = 0
		Signals[Directions.Down].Stochs.Cross50.Count = 0
		Signals[Directions.Down].Stochs.Cross50.Candle = 0
		Signals[Directions.Down].Stochs.Uturn3.Count = 0
		Signals[Directions.Down].Stochs.Uturn3.Candle = 0
		Signals[Directions.Down].Stochs.Uturn4.Count = 0
		Signals[Directions.Down].Stochs.Uturn4.Candle = 0
		Signals[Directions.Down].Stochs.Spring3.Count = 0
		Signals[Directions.Down].Stochs.Spring3.Candle = 0
		Signals[Directions.Down].Stochs.Spring4.Count = 0
		Signals[Directions.Down].Stochs.Spring4.Candle = 0
		Signals[Directions.Down].Stochs.HSteamer.Count = 0
		Signals[Directions.Down].Stochs.HSteamer.Candle = 0
		Signals[Directions.Down].Stochs.VSteamer.Count = 0
		Signals[Directions.Down].Stochs.VSteamer.Candle = 0

		Signals[Directions.Down].RSIs.Cross.Count = 0
		Signals[Directions.Down].RSIs.Cross.Candle = 0
		Signals[Directions.Down].RSIs.Cross50.Count = 0
		Signals[Directions.Down].RSIs.Cross50.Candle = 0
		Signals[Directions.Down].RSIs.Uturn3.Count = 0
		Signals[Directions.Down].RSIs.Uturn3.Candle = 0
		Signals[Directions.Down].RSIs.Uturn4.Count = 0
		Signals[Directions.Down].RSIs.Uturn4.Candle = 0
		Signals[Directions.Down].RSIs.Spring3.Count = 0
		Signals[Directions.Down].RSIs.Spring3.Candle = 0
		Signals[Directions.Down].RSIs.Spring4.Count = 0
		Signals[Directions.Down].RSIs.Spring4.Candle = 0
		Signals[Directions.Down].RSIs.TrendOn.Count = 0
		Signals[Directions.Down].RSIs.TrendOn.Candle = 0 
	--#endregion
	end

	Prices.Open[index_candle] = O(index_candle)
	Prices.Close[index_candle] = C(index_candle)
	Prices.High[index_candle] = H(index_candle)
	Prices.Low[index_candle] = L(index_candle)

	MAs[index_candle], BBs.Top[index_candle], BBs.Bottom[index_candle] = FuncBB(index_candle)
	MAs[index_candle] = RoundScale(MAs[index_candle], 4)
	BBs.Top[index_candle] = RoundScale(BBs.Top[index_candle], 4)
	BBs.Bottom[index_candle] = RoundScale(BBs.Bottom[index_candle], 4)

	Stochs.Slow[index_candle], _ = FuncStochSlow(index_candle)
	Stochs.Fast[index_candle], _ = FuncStochFast(index_candle)
	Stochs.Slow[index_candle] = RoundScale(Stochs.Slow[index_candle], 4)
	Stochs.Fast[index_candle] = RoundScale(Stochs.Fast[index_candle], 4)

	RSIs.Fast[index_candle] = FuncRSIFast(index_candle)
	RSIs.Slow[index_candle] = FuncRSISlow(index_candle)
	RSIs.Fast[index_candle] = RoundScale(RSIs.Fast[index_candle], 4)
	RSIs.Slow[index_candle] = RoundScale(RSIs.Slow[index_candle], 4)

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

	--
	--#region	I.2. Elementary Price Signals: Signals[Directions.Down/Up].Prices.Uturn3
	--				Enter Signal: Signals[Directions.Down/Up].Uturn, Signals[Directions.Down/Up].Spring1/2
	--				Depends on signal: SignalPriceUturn3
	--				Terminates by signals: Reverse self-signal
	--				Terminates by duration: Signals.Params.Durations.Elementary
	--
	if (CheckDataSufficiency(index_candle, 3, Prices.Close) and CheckDataSufficiency(index_candle, 3, Prices.Open) and
	CheckDataSufficiency(index_candle, 3, Prices.High) and CheckDataSufficiency(index_candle, 3, Prices.Low) and
	CheckDataSufficiency(index_candle, 3, MAs) and CheckDataSufficiency(index_candle, 3, MAs.Delta)) then
		--
		-- check start elementary price uturn3 up signal
		--
		if (SignalPriceUturn3(Prices, MAs, index_candle, Directions.Up)) then
			-- set elementary down signal off
			Signals[Directions.Down].Prices.Uturn3.Candle = 0
			-- set elementary up signal on
			Signals[Directions.Up].Prices.Uturn3.Candle = index_candle - 1
			Signals[Directions.Up].Prices.Uturn3.Count = Signals[Directions.Up].Prices.Uturn3.Count + 1

			-- set chart label
			if (Labels[Prices.Name][index_candle-1] ~= nil) then
				DelLabel(ChartTags.Price, Labels[Prices.Name][index_candle-1])
			end
			Labels[Prices.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (Prices.Low[index_candle-1]-2*ChartSteps.Price*SecInfo.min_price_step), ChartTags.Price, "LPriceUturn3|Start|"..tostring(Signals[Directions.Up].Prices.Uturn3.Count).."|"..(index_candle-1), ChartLabelIcons.Point, SignalLevels.Elementary)
		end

		-- check presence elementary up signal
		if (Signals[Directions.Up].Prices.Uturn3.Candle > 0) then
			--set duration elemenetary up signal
			local duration = index_candle - Signals[Directions.Up].Prices.Uturn3.Candle
			-- check continuation elementary up signal
			if (duration <= Signals.Params.Durations.Elementary) then

				-- set chart label
				-- if (Labels[Prices.Name][index_candle] ~= nil) then
				-- 	DelLabel(ChartTags.Price, Labels[Prices.Name][index_candle])
				-- end
				--Labels[Prices.Name][index_candle] = SetChartLabel(T(index_candle), (Prices.Low[index_candle]-2*ChartSteps.Price*SecInfo.min_price_step), ChartTags.Price, "LPriceUturn3|Continue|"..tostring(Signals[Directions.Up].Prices.Uturn3.Count).."|"..duration.."|".. index_candle, ChartLabelIcons.Point, SignalLevels.Elementary)
			-- check termination by duration elementary up signal
			elseif (duration > Signals.Params.Durations.Elementary) then
				-- set elementary up signal off
				Signals[Directions.Up].Prices.Uturn3.Candle = 0

				-- set chart label
				if (Labels[Prices.Name][index_candle] ~= nil) then
					DelLabel(ChartTags.Price, Labels[Prices.Name][index_candle])
				end
				Labels[Prices.Name][index_candle] = SetChartLabel(T(index_candle), (Prices.Low[index_candle]-2*ChartSteps.Price*SecInfo.min_price_step), ChartTags.Price, "LPriceUturn3|End|"..tostring(Signals[Directions.Up].Prices.Uturn3.Count).."|"..duration.."|"..index_candle, ChartLabelIcons.Cross, SignalLevels.Elementary)
			end
		end

		--
		-- check start elementary price uturn3 down signal
		--
		if (SignalPriceUturn3(Prices, MAs, index_candle, Directions.Down)) then
			-- set elementary up signal off
			Signals[Directions.Up].Prices.Uturn3.Candle = 0
			-- set elementary down signal on
			Signals[Directions.Down].Prices.Uturn3.Candle = index_candle - 1
			Signals[Directions.Down].Prices.Uturn3.Count = Signals[Directions.Down].Prices.Uturn3.Count + 1

			-- set chart label
			if (Labels[Prices.Name][index_candle-1] ~= nil) then
				DelLabel(ChartTags.Price, Labels[Prices.Name][index_candle-1])
			end
			Labels[Prices.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (Prices.High[index_candle-1]+2*ChartSteps.Price*SecInfo.min_price_step), ChartTags.Price, "SPriceUturn3|Start|"..tostring(Signals[Directions.Down].Prices.Uturn3.Count).."|"..(index_candle-1), ChartLabelIcons.Point, SignalLevels.Elementary)
		end

		-- check presence elementary down signal
		if (Signals[Directions.Down].Prices.Uturn3.Candle > 0) then
			--set duration elemenetary down signal
			local duration = index_candle - Signals[Directions.Down].Prices.Uturn3.Candle
			-- check continuation elementary down signal
			if (duration <= Signals.Params.Durations.Elementary) then

				-- set chart label
				-- if (Labels[Prices.Name][index_candle] ~= nil) then
				-- 	DelLabel(ChartTags.Price, Labels[Prices.Name][index_candle])
				-- end
				--Labels[Prices.Name][index_candle] = SetChartLabel(T(index_candle), (Prices.High[index_candle]+2*ChartSteps.Price*SecInfo.min_price_step), ChartTags.Price, "SPriceUturn3|Continue|"..tostring(Signals[Directions.Down].Prices.Uturn3.Count).."|"..duration.."|"..index_candle, ChartLabelIcons.Point, SignalLevels.Elementary)
			-- check termination by duration elementary down signal
			elseif (duration > Signals.Params.Durations.Elementary) then
				-- set elementary down signal off
				Signals[Directions.Down].Prices.Uturn3.Candle = 0

				-- set chart label
				if (Labels[Prices.Name][index_candle] ~= nil) then
					DelLabel(ChartTags.Price, Labels[Prices.Name][index_candle])
				end
				Labels[Prices.Name][index_candle] = SetChartLabel(T(index_candle), (Prices.High[index_candle]+2*ChartSteps.Price*SecInfo.min_price_step), ChartTags.Price, "SPriceUturn3|End|"..tostring(Signals[Directions.Down].Prices.Uturn3.Count).."|"..duration.."|"..index_candle,  ChartLabelIcons.Cross, SignalLevels.Elementary)
			end
		end
	end
	--#endregion

	--
	--#region	I.3. Elementary Price Signals: Signals[Directions.Down/Up].Prices.Uturn4
	--				Enter Signal: Signals[Directions.Down/Up].Uturn, Signals[Directions.Down/Up].Spring1/2
	--				Depends on signal: SignalPriceUturn4
	--				Terminates by signals: Reverse self-signal
	--				Terminates by duration: Signals.Params.Durations.Elementary
	--
	if (CheckDataSufficiency(index_candle, 4, Prices.Close) and	CheckDataSufficiency(index_candle, 4, Prices.Open) and
	CheckDataSufficiency(index_candle, 4, Prices.High) and CheckDataSufficiency(index_candle, 4, Prices.Low) and
	CheckDataSufficiency(index_candle, 4, MAs) and CheckDataSufficiency(index_candle, 4, MAs.Delta)) then
		--
		-- check start elementary price uturn4 up signal
		--
		if (SignalPriceUturn4(Prices, MAs, index_candle, Directions.Up)) then
			-- set elementary down signal off
			Signals[Directions.Down].Prices.Uturn4.Candle = 0
			-- set elementary up signal on
			Signals[Directions.Up].Prices.Uturn4.Candle = index_candle - 1
			Signals[Directions.Up].Prices.Uturn4.Count = Signals[Directions.Up].Prices.Uturn4.Count + 1

			-- set chart label
			if (Labels[Prices.Name][index_candle-1] ~= nil) then
				DelLabel(ChartTags.Price, Labels[Prices.Name][index_candle-1])
			end
			Labels[Prices.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (Prices.Low[index_candle-1]-3*ChartSteps.Price*SecInfo.min_price_step), ChartTags.Price, "LPriceUturn4|Start|"..tostring(Signals[Directions.Up].Prices.Uturn4.Count).."|"..(index_candle-1), ChartLabelIcons.Romb, SignalLevels.Elementary)
		end

		-- check presence elementary up signal
		if (Signals[Directions.Up].Prices.Uturn4.Candle > 0) then
			-- set duration elemenetary up signal
			local duration = index_candle - Signals[Directions.Up].Prices.Uturn4.Candle
			-- check continuation elementary up signal
			if (duration <= Signals.Params.Durations.Elementary) then
				-- set chart label
				-- if (Labels[Prices.Name][index_candle] ~= nil) then
				-- 	DelLabel(ChartTags.Price, Labels[Prices.Name][index_candle])
				-- end
				--Labels[Prices.Name][index_candle] = SetChartLabel(T(index_candle), (Prices.Low[index_candle]-3*ChartSteps.Price*SecInfo.min_price_step), ChartTags.Price, "LPriceUturn4|Continue|"..tostring(Signals[Directions.Up].Prices.Uturn4.Count).."|"..duration.."|"..index_candle, ChartLabelIcons.Romb, SignalLevels.Elementary)
			-- check termination by duration elementary up signal
			elseif (duration > Signals.Params.Durations.Elementary) then
				-- set elementary up signal off
				Signals[Directions.Up].Prices.Uturn4.Candle = 0

				-- set chart label
				if (Labels[Prices.Name][index_candle] ~= nil) then
					DelLabel(ChartTags.Price, Labels[Prices.Name][index_candle])
				end
				Labels[Prices.Name][index_candle] = SetChartLabel(T(index_candle), (Prices.Low[index_candle]-3*ChartSteps.Price*SecInfo.min_price_step), ChartTags.Price, "LPriceUturn4|End|"..tostring(Signals[Directions.Up].Prices.Uturn4.Count).."|"..duration.."|"..index_candle, ChartLabelIcons.Cross, SignalLevels.Elementary)
			end
		end

		--
		-- check start elementary price uturn4 down signal
		--
		if (SignalPriceUturn4(Prices, MAs, index_candle, Directions.Down)) then
			-- set elementary up signal off
			Signals[Directions.Up].Prices.Uturn4.Candle = 0
			-- set elementary down signal on
			Signals[Directions.Down].Prices.Uturn4.Candle = index_candle - 1
			Signals[Directions.Down].Prices.Uturn4.Count = Signals[Directions.Down].Prices.Uturn4.Count + 1

			-- set chart label
			if (Labels[Prices.Name][index_candle-1] ~= nil) then
				DelLabel(ChartTags.Price, Labels[Prices.Name][index_candle-1])
			end
			Labels[Prices.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (Prices.High[index_candle-1]+3*ChartSteps.Price*SecInfo.min_price_step), ChartTags.Price, "SPriceUturn4|Start|"..tostring(Signals[Directions.Down].Prices.Uturn4.Count).."|"..(index_candle-1), ChartLabelIcons.Romb, SignalLevels.Elementary)
		end

		-- check presence elementary down signal
		if (Signals[Directions.Down].Prices.Uturn4.Candle > 0) then
			--set duration elemenetary down signal
			local duration = index_candle - Signals[Directions.Down].Prices.Uturn4.Candle
			-- check continuation elementary down signal
			if (duration <= Signals.Params.Durations.Elementary) then
				-- set chart label
				-- if (Labels[Prices.Name][index_candle] ~= nil) then
				-- 	DelLabel(ChartTags.Price, Labels[Prices.Name][index_candle])
				-- end
				--Labels[Prices.Name][index_candle] = SetChartLabel(T(index_candle), (Prices.High[index_candle]+3*ChartSteps.Price*SecInfo.min_price_step), ChartTags.Price, "SPriceUturn4|Continue|"..tostring(Signals[Directions.Down].Prices.Uturn4.Count).."|"..duration.."|"..index_candle, ChartLabelIcons.Romb, SignalLevels.Elementary)
			-- check termination by duration elementary down signal
			elseif (duration > Signals.Params.Durations.Elementary) then
				-- set elementary down signal off
				Signals[Directions.Down].Prices.Uturn4.Candle = 0

				-- set chart label
				if (Labels[Prices.Name][index_candle] ~= nil) then
					DelLabel(ChartTags.Price, Labels[Prices.Name][index_candle])
				end
				Labels[Prices.Name][index_candle] = SetChartLabel(T(index_candle), (Prices.High[index_candle]+3*ChartSteps.Price*SecInfo.min_price_step), ChartTags.Price, "SPriceUturn4|End|"..tostring(Signals[Directions.Down].Prices.Uturn4.Count).."|"..duration.."|"..index_candle, ChartLabelIcons.Cross, SignalLevels.Elementary)
			end
		end
	end
	--#endregion

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
	--#region	II.3. Elementary Stoch Signal: Signals[Directions.Down/Up].Stochs.Uturn3
	--				Enter Signal: Signals[Directions.Down/Up].Uturn
	--				Depends on signal: SignalOscUturn3
	--				Terminates by signals: Reverse self-signal
	--				Terminates by duration: Signals.Params.Durations.Elementary
	--
	if (CheckDataSufficiency(index_candle, 3, Stochs.Slow) and CheckDataSufficiency(index_candle, 3, Stochs.Fast)) then
		--
		-- check start elementary stoch uturn3 up signal
		--
		if (SignalOscUturn3(Stochs, index_candle, Directions.Up)) then
			-- set elementary down signal off
			Signals[Directions.Down].Stochs.Uturn3.Candle = 0
			-- set elementary up signal on
			Signals[Directions.Up].Stochs.Uturn3.Candle = index_candle - 1
			Signals[Directions.Up].Stochs.Uturn3.Count = Signals[Directions.Up].Stochs.Uturn3.Count + 1

			-- set chart label
			if (Labels[Stochs.Name][index_candle-1] ~= nil) then
				DelLabel(ChartTags.Stoch, Labels[Stochs.Name][index_candle-1])
			end
			Labels[Stochs.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (Stochs.Slow[index_candle-1]*(100-3*ChartSteps.Stoch)/100), ChartTags.Stoch, "LStochUturn3|Start|"..tostring(Signals[Directions.Up].Stochs.Uturn3.Count).."|"..(index_candle-1), ChartLabelIcons.Point, SignalLevels.Elementary)
		end

		-- check presence elementary up signal
		if (Signals[Directions.Up].Stochs.Uturn3.Candle > 0) then
			-- set duration elemenetary up signal
			local duration = index_candle - Signals[Directions.Up].Stochs.Uturn3.Candle
			-- check continuation elementary up signal
			if (duration <= Signals.Params.Durations.Elementary) then

				-- set chart label
				-- if (Labels[Stochs.Name][index_candle] ~= nil) then
				-- 	DelLabel(ChartTags.Stoch, Labels[Stochs.Name][index_candle])
				-- end
				--Labels[Stochs.Name][index_candle] = SetChartLabel(T(index_candle), (Stochs.Slow[index_candle]*(100-3*ChartSteps.Stoch)/100), ChartTags.Stoch, "LStochUturn3|Continue|"..tostring(Signals[Directions.Up].Stochs.Uturn3.Count).."|"..duration.."|"..index_candle, ChartLabelIcons.Point, SignalLevels.Elementary)
			-- check termination by duration elementary up signal
			elseif (duration > Signals.Params.Durations.Elementary) then
				-- set elementary up signal off
				Signals[Directions.Up].Stochs.Uturn3.Candle = 0

				-- set chart label
				if (Labels[Stochs.Name][index_candle] ~= nil) then
					DelLabel(ChartTags.Stoch, Labels[Stochs.Name][index_candle])
				end
				Labels[Stochs.Name][index_candle] = SetChartLabel(T(index_candle), (Stochs.Slow[index_candle]*(100-3*ChartSteps.Stoch)/100), ChartTags.Stoch, "LStochUturn3|End|"..tostring(Signals[Directions.Up].Stochs.Uturn3.Count).."|"..duration.."|"..index_candle, ChartLabelIcons.Cross, SignalLevels.Elementary)
			end
		end

		--
		-- check start elementary stoch uturn3 down signal
		--
		if (SignalOscUturn3(Stochs, index_candle, Directions.Down)) then
			-- set elementary up signal off
			Signals[Directions.Up].Stochs.Uturn3.Candle = 0
			-- set elementary down signal on
			Signals[Directions.Down].Stochs.Uturn3.Candle = index_candle - 1
			Signals[Directions.Down].Stochs.Uturn3.Count = Signals[Directions.Down].Stochs.Uturn3.Count + 1

			-- set chart label
			if (Labels[Stochs.Name][index_candle-1] ~= nil) then
				DelLabel(ChartTags.Stoch, Labels[Stochs.Name][index_candle-1])
			end
			Labels[Stochs.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (Stochs.Slow[index_candle-1]*(100+3*ChartSteps.Stoch)/100), ChartTags.Stoch, "SStochUturn3|Start|"..tostring(Signals[Directions.Down].Stochs.Uturn3.Count).."|"..(index_candle-1), ChartLabelIcons.Point, SignalLevels.Elementary)
		end

		-- check presence elementary down signal
		if (Signals[Directions.Down].Stochs.Uturn3.Candle > 0) then
			-- set duration elemenetary up signal
			local duration = index_candle - Signals[Directions.Down].Stochs.Uturn3.Candle
			-- check continuation elementary down signal
			if (duration <= Signals.Params.Durations.Elementary) then

				-- set chart label
				-- if (Labels[Stochs.Name][index_candle] ~= nil) then
				-- 	DelLabel(ChartTags.Stoch, Labels[Stochs.Name][index_candle])
				-- end
				--Labels[Stochs.Name][index_candle] = SetChartLabel(T(index_candle), (Stochs.Slow[index_candle]*(100+3*ChartSteps.Stoch)/100), ChartTags.Stoch, "SStochUturn3|Continue|"..tostring(Signals[Directions.Down].Stochs.Uturn3.Count).."|"..duration.."|"..index_candle, ChartLabelIcons.Point, SignalLevels.Elementary)
			-- check termination by duration elementary up signal
			elseif (duration > Signals.Params.Durations.Elementary) then
				-- set elementary down signal off
				Signals[Directions.Down].Stochs.Uturn3.Candle = 0

				-- set chart label
				if (Labels[Stochs.Name][index_candle] ~= nil) then
					DelLabel(ChartTags.Stoch, Labels[Stochs.Name][index_candle])
				end
				Labels[Stochs.Name][index_candle] = SetChartLabel(T(index_candle), (Stochs.Slow[index_candle]*(100+3*ChartSteps.Stoch)/100), ChartTags.Stoch, "SStochUturn3|End|"..tostring(Signals[Directions.Down].Stochs.Uturn3.Count).."|"..duration.."|"..index_candle, ChartLabelIcons.Cross, SignalLevels.Elementary)
			end
		end
	end
	--#endregion

	--
	--#region	II.4. Elementary Stoch Signal: Signals[Directions.Down/Up].Stochs.Uturn4
	--				Enter Signal: Signals[Directions.Down/Up].Uturn
	--				Depends on signal: SignalOscUturn4
	--				Terminates by signals: Reverse self-signal
	--				Terminates by duration: Signals.Params.Durations.Elementary
	--
	if (CheckDataSufficiency(index_candle, 4, Stochs.Slow) and CheckDataSufficiency(index_candle, 4, Stochs.Fast)) then
		--
		-- check start elementary stoch uturn4 up signal
		--
		if (SignalOscUturn4(Stochs, index_candle, Directions.Up)) then
			-- set elementary down signal off
			Signals[Directions.Down].Stochs.Uturn4.Candle = 0
			-- set elementary up signal on
			Signals[Directions.Up].Stochs.Uturn4.Candle = index_candle - 1
			Signals[Directions.Up].Stochs.Uturn4.Count = Signals[Directions.Up].Stochs.Uturn4.Count + 1

			-- set chart label
			if (Labels[Stochs.Name][index_candle-1] ~= nil) then
				DelLabel(ChartTags.Stoch, Labels[Stochs.Name][index_candle-1])
			end
			Labels[Stochs.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (Stochs.Slow[index_candle-1]*(100-4*ChartSteps.Stoch)/100), ChartTags.Stoch, "LStochUturn4|Start|"..tostring(Signals[Directions.Up].Stochs.Uturn4.Count).."|"..(index_candle-1), ChartLabelIcons.Romb, SignalLevels.Elementary)
		end

		-- check presence elementary up signal
		if (Signals[Directions.Up].Stochs.Uturn4.Candle > 0) then
			-- set duration elemenetary up signal
			local duration = index_candle - Signals[Directions.Up].Stochs.Uturn4.Candle
			-- check continuation elementary up signal
			if (duration <= Signals.Params.Durations.Elementary) then

				-- set chart label
				-- if (Labels[Stochs.Name][index_candle] ~= nil) then
				-- 	DelLabel(ChartTags.Stoch, Labels[Stochs.Name][index_candle])
				-- end
				--Labels[Stochs.Name][index_candle] = SetChartLabel(T(index_candle), (Stochs.Slow[index_candle]*(100-4*ChartSteps.Stoch)/100), ChartTags.Stoch, "LStochUturn4|Continue|"..tostring(Signals[Directions.Up].Stochs.Uturn4.Count).."|"..duration.."|"..index_candle, ChartLabelIcons.Romb, SignalLevels.Elementary)
			-- check termination by duration elementary up signal
			elseif (duration > Signals.Params.Durations.Elementary) then
				-- set elementary up signal off
				Signals[Directions.Up].Stochs.Uturn4.Candle = 0

				-- set chart label
				if (Labels[Stochs.Name][index_candle] ~= nil) then
					DelLabel(ChartTags.Stoch, Labels[Stochs.Name][index_candle])
				end
				Labels[Stochs.Name][index_candle] = SetChartLabel(T(index_candle), (Stochs.Slow[index_candle]*(100-4*ChartSteps.Stoch)/100), ChartTags.Stoch, "LStochUturn4|End|"..tostring(Signals[Directions.Up].Stochs.Uturn4.Count).."|"..duration.."|"..index_candle, ChartLabelIcons.Cross, SignalLevels.Elementary)
			end
		end

		--
		-- check start elementary stoch uturn4 down signal
		--
		if (SignalOscUturn4(Stochs, index_candle, Directions.Down)) then
			-- set elementary up signal off
			Signals[Directions.Up].Stochs.Uturn4.Candle = 0
			-- set elementary down signal on
			Signals[Directions.Down].Stochs.Uturn4.Candle = index_candle - 1
			Signals[Directions.Down].Stochs.Uturn4.Count = Signals[Directions.Down].Stochs.Uturn4.Count + 1

			-- set  chart label
			if (Labels[Stochs.Name][index_candle-1] ~= nil) then
				DelLabel(ChartTags.Stoch, Labels[Stochs.Name][index_candle-1])
			end
			Labels[Stochs.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (Stochs.Slow[index_candle-1]*(100+4*ChartSteps.Stoch)/100), ChartTags.Stoch, "SStochUturn4|Start|"..tostring(Signals[Directions.Down].Stochs.Uturn4.Count).."|"..(index_candle-1), ChartLabelIcons.Romb, SignalLevels.Elementary)
		end

		-- check presence elementary down signal
		if (Signals[Directions.Down].Stochs.Uturn4.Candle > 0) then
			-- set duration elemenetary up signal
			local duration = index_candle - Signals[Directions.Down].Stochs.Uturn4.Candle
			-- check continuation elementary down signal
			if (duration <= Signals.Params.Durations.Elementary) then

				-- set chart label
				-- if (Labels[Stochs.Name][index_candle] ~= nil) then
				-- 	DelLabel(ChartTags.Stoch, Labels[Stochs.Name][index_candle])
				-- end
				--Labels[Stochs.Name][index_candle] = SetChartLabel(T(index_candle), (Stochs.Slow[index_candle]*(100+4*ChartSteps.Stoch)/100), ChartTags.Stoch, "SStochUturn4|Continue|"..tostring(Signals[Directions.Down].Stochs.Uturn4.Count).."|"..duration.."|"..index_candle, ChartLabelIcons.Romb, SignalLevels.Elementary)
			-- check termination by duration elementary up signal
			elseif (duration > Signals.Params.Durations.Elementary) then
				-- set elementary down signal off
				Signals[Directions.Down].Stochs.Uturn4.Candle = 0

				-- set chart label
				if (Labels[Stochs.Name][index_candle] ~= nil) then
					DelLabel(ChartTags.Stoch, Labels[Stochs.Name][index_candle])
				end
				Labels[Stochs.Name][index_candle] = SetChartLabel(T(index_candle), (Stochs.Slow[index_candle]*(100+4*ChartSteps.Stoch)/100), ChartTags.Stoch, "SStochUturn4|End|"..tostring(Signals[Directions.Down].Stochs.Uturn4.Count).."|"..duration.."|"..index_candle, ChartLabelIcons.Cross, SignalLevels.Elementary)
			end
		end
	end
	--#endregion

	--
	--#region	II.5. Elementary Stoch Signal: Signals[Directions.Down/Up].Stochs.Spring3
	--				Enter Signal: Signals[Directions.Down/Up].Spring1/Spring2
	--				Depends on signal: SignalOscSpring3
	--				Terminates by signals: Reverse self-signal
	--				Terminates by duration: Signals.Params.Durations.Elementary
	--
	if (CheckDataSufficiency(index_candle, 3, Stochs.Slow) and CheckDataSufficiency(index_candle, 3, Stochs.Fast)) then
		-- check start elementary stoch spring3 up signal
		if (SignalOscSpring3(Stochs, index_candle, Directions.Up)) then
			-- set elementary down signal off
			Signals[Directions.Down].Stochs.Spring3.Candle = 0
			-- set elementary up signal on
			Signals[Directions.Up].Stochs.Spring3.Candle = index_candle - 1
			Signals[Directions.Up].Stochs.Spring3.Count = Signals[Directions.Up].Stochs.Spring3.Count + 1

			-- set chart label
			if (Labels[Stochs.Name][index_candle-1] ~= nil) then
				DelLabel(ChartTags.Stoch, Labels[Stochs.Name][index_candle-1])
			end
			Labels[Stochs.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (Stochs.Slow[index_candle-1]*(100-5*ChartSteps.Stoch)/100), ChartTags.Stoch, "LStochSpring3|Start|"..tostring(Signals[Directions.Up].Stochs.Spring3.Count).."|"..(index_candle-1), ChartLabelIcons.Plus, SignalLevels.Elementary)
		end

		-- check presence elementary up signal
		if (Signals[Directions.Up].Stochs.Spring3.Candle > 0) then
			-- set duration elemenetary up signal
			local duration = index_candle - Signals[Directions.Up].Stochs.Spring3.Candle
			-- check continuation elementary up signal
			if (duration <= Signals.Params.Durations.Elementary) then

				-- set chart label
				-- if (Labels[Stochs.Name][index_candle] ~= nil) then
				-- 	DelLabel(ChartTags.Stoch, Labels[Stochs.Name][index_candle])
				-- end
				--Labels[Stochs.Name][index_candle] = SetChartLabel(T(index_candle), (Stochs.Slow[index_candle]*(100-5*ChartSteps.Stoch)/100), ChartTags.Stoch, "LStochSpring3|Continue|"..tostring(Signals[Directions.Up].Stochs.Spring3.Count).."|".. duration.."|"..index_candle, ChartLabelIcons.Plus, SignalLevels.Elementary)
			-- check termination by duration elementary up signal
			elseif (duration > Signals.Params.Durations.Elementary) then
				-- set elementary up signal off
				Signals[Directions.Up].Stochs.Spring3.Candle = 0

				-- set chart label
				if (Labels[Stochs.Name][index_candle] ~= nil) then
					DelLabel(ChartTags.Stoch, Labels[Stochs.Name][index_candle])
				end
				Labels[Stochs.Name][index_candle] = SetChartLabel(T(index_candle), (Stochs.Slow[index_candle]*(100-5*ChartSteps.Stoch)/100), ChartTags.Stoch, "LStochSpring3|End|"..tostring(Signals[Directions.Up].Stochs.Spring3.Count).."|"..duration.."|"..index_candle, ChartLabelIcons.Cross, SignalLevels.Elementary)
			end
		end

		--
		-- check start elementary stoch spring3 down signal
		--
		if (SignalOscSpring3(Stochs, index_candle, Directions.Down)) then
			-- set elementary up signal off
			Signals[Directions.Up].Stochs.Spring3.Candle = 0
			-- set elementary down signal on
			Signals[Directions.Down].Stochs.Spring3.Candle = index_candle - 1
			Signals[Directions.Down].Stochs.Spring3.Count = Signals[Directions.Down].Stochs.Spring3.Count + 1

			-- set chart label
			if (Labels[Stochs.Name][index_candle-1] ~= nil) then
				DelLabel(ChartTags.Stoch, Labels[Stochs.Name][index_candle-1])
			end
			Labels[Stochs.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (Stochs.Slow[index_candle-1]*(100+5*ChartSteps.Stoch)/100), ChartTags.Stoch, "SStochSpring3|Start|"..tostring(Signals[Directions.Down].Stochs.Spring3.Count).."|"..(index_candle-1), ChartLabelIcons.Plus, SignalLevels.Elementary)
		end

		-- check presence elementary down signal
		if (Signals[Directions.Down].Stochs.Spring3.Candle > 0) then
			-- set duration elemenetary down signal
			local duration = index_candle - Signals[Directions.Down].Stochs.Spring3.Candle
			-- check continuation elementary down signal
			if (duration <= Signals.Params.Durations.Elementary) then

				-- set chart label
				-- if (Labels[Stochs.Name][index_candle] ~= nil) then
				-- 	DelLabel(ChartTags.Stoch, Labels[Stochs.Name][index_candle])
				-- end
				--Labels[Stochs.Name][index_candle] = SetChartLabel(T(index_candle), (Stochs.Slow[index_candle]*(100+5*ChartSteps.Stoch)/100), ChartTags.Stoch, "SStochSpring3|Continue|"..tostring(Signals[Directions.Down].Stochs.Spring3.Count).."|"..duration.."|"..index_candle, ChartLabelIcons.Plus, SignalLevels.Elementary)
			-- check termination by duration elementary down signal
			elseif (duration > Signals.Params.Durations.Elementary) then
				-- set elementary down signal off
				Signals[Directions.Down].Stochs.Spring3.Candle = 0

				-- set chart label
				if (Labels[Stochs.Name][index_candle] ~= nil) then
					DelLabel(ChartTags.Stoch, Labels[Stochs.Name][index_candle])
				end
				Labels[Stochs.Name][index_candle] = SetChartLabel(T(index_candle), (Stochs.Slow[index_candle]*(100+5*ChartSteps.Stoch)/100), ChartTags.Stoch, "SStochSpring3|End|"..tostring(Signals[Directions.Down].Stochs.Spring3.Count).."|"..duration.."|"..index_candle, ChartLabelIcons.Cross, SignalLevels.Elementary)
			end
		end
	end
	--#endregion

	--
	--#region		II.6. Elementary Stoch Signal: Signals[Directions.Down/Up].Stochs.Spring4
	--				Enter Signal: Signals[Directions.Down/Up].Spring1/Spring2
	--				Depends on signal: SignalOscSpring4
	--				Terminates by signals: Reverse self-signal
	--				Terminates by duration: Signals.Params.Durations.Elementary
	--
	if (CheckDataSufficiency(index_candle, 4, Stochs.Slow) and CheckDataSufficiency(index_candle, 4, Stochs.Fast)) then
		--
		-- check start elementary stoch spring4 up signal
		--
		if (SignalOscSpring4(Stochs, index_candle, Directions.Up)) then
			-- set elementary down signal off
			Signals[Directions.Down].Stochs.Spring4.Candle = 0
			-- set elementary up signal on
			Signals[Directions.Up].Stochs.Spring4.Candle = index_candle - 1
			Signals[Directions.Up].Stochs.Spring4.Count = Signals[Directions.Up].Stochs.Spring4.Count + 1

			-- set chart label
			if (Labels[Stochs.Name][index_candle-1] ~= nil) then
				DelLabel(ChartTags.Stoch, Labels[Stochs.Name][index_candle-1])
			end
			Labels[Stochs.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (Stochs.Slow[index_candle-1]*(100-6*ChartSteps.Stoch)/100), ChartTags.Stoch, "LStochSpring4|Start|"..tostring(Signals[Directions.Up].Stochs.Spring4.Count).."|"..(index_candle-1), ChartLabelIcons.Flash, SignalLevels.Elementary)
		end

		-- check presence elementary up signal
		if (Signals[Directions.Up].Stochs.Spring4.Candle > 0) then
			-- set duration elemenetary down signal
			local duration = index_candle - Signals[Directions.Up].Stochs.Spring4.Candle
			-- check continuation elementary up signal
			if (duration <= Signals.Params.Durations.Elementary) then

				-- set chart label
				-- if (Labels[Stochs.Name][index_candle] ~= nil) then
				-- 	DelLabel(ChartTags.Stoch, Labels[Stochs.Name][index_candle])
				-- end
				--Labels[Stochs.Name][index_candle] = SetChartLabel(T(index_candle), (Stochs.Slow[index_candle]*(100-6*ChartSteps.Stoch)/100), ChartTags.Stoch, "LStochSpring4|Continue|"..tostring(Signals[Directions.Up].Stochs.Spring4.Count).."|".. duration.."|"..index_candle, ChartLabelIcons.Flash, SignalLevels.Elementary)
			-- check termination by duration elementary up signal
			elseif (duration > Signals.Params.Durations.Elementary) then
				-- set elementary up signal off
				Signals[Directions.Up].Stochs.Spring4.Candle = 0

				-- set chart label
				if (Labels[Stochs.Name][index_candle] ~= nil) then
					DelLabel(ChartTags.Stoch, Labels[Stochs.Name][index_candle])
				end
				Labels[Stochs.Name][index_candle] = SetChartLabel(T(index_candle), (Stochs.Slow[index_candle]*(100-6*ChartSteps.Stoch)/100), ChartTags.Stoch, "LStochSpring4|End|"..tostring(Signals[Directions.Up].Stochs.Spring4.Count).."|".. duration.."|"..index_candle, ChartLabelIcons.Cross, SignalLevels.Elementary)
			end
		end

		--
		-- check start elementary stoch spring4 down signal
		--
		if (SignalOscSpring4(Stochs, index_candle, Directions.Down)) then
			-- set elementary up signal off
			Signals[Directions.Up].Stochs.Spring4.Candle = 0
			-- set elementary down signal on
			Signals[Directions.Down].Stochs.Spring4.Candle = index_candle - 1
			Signals[Directions.Down].Stochs.Spring4.Count = Signals[Directions.Down].Stochs.Spring4.Count + 1

			-- set chart label
			if (Labels[Stochs.Name][index_candle-1] ~= nil) then
				DelLabel(ChartTags.Stoch, Labels[Stochs.Name][index_candle-1])
			end
			Labels[Stochs.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (Stochs.Slow[index_candle-1]*(100+6*ChartSteps.Stoch)/100), ChartTags.Stoch, "SStochSpring4|Start|"..tostring(Signals[Directions.Down].Stochs.Spring4.Count).."|"..(index_candle-1), ChartLabelIcons.Flash, SignalLevels.Elementary)
		end

		-- check pesence elementary down signal
		if (Signals[Directions.Down].Stochs.Spring4.Candle > 0) then
			-- set duration elemenetary down signal
			local duration = index_candle - Signals[Directions.Down].Stochs.Spring4.Candle
			-- check continuation elementary down signal
			if (duration <= Signals.Params.Durations.Elementary) then

				-- set chart label
				-- if (Labels[Stochs.Name][index_candle] ~= nil) then
				-- 	DelLabel(ChartTags.Stoch, Labels[Stochs.Name][index_candle])
				-- end
				--Labels[Stochs.Name][index_candle] = SetChartLabel(T(index_candle), (Stochs.Slow[index_candle]*(100+6*ChartSteps.Stoch)/100), ChartTags.Stoch, "SStochSpring4|Continue|"..tostring(Signals[Directions.Down].Stochs.Spring4.Count).."|"..duration.."|"..index_candle, ChartLabelIcons.Flash, SignalLevels.Elementary)
			-- check termination by duration elementary down signal
			elseif (duration > Signals.Params.Durations.Elementary) then
				-- set elementary down signal off
				Signals[Directions.Down].Stochs.Spring4.Candle = 0

				-- set chart label
				if (Labels[Stochs.Name][index_candle] ~= nil) then
					DelLabel(ChartTags.Stoch, Labels[Stochs.Name][index_candle])
				end
				Labels[Stochs.Name][index_candle] = SetChartLabel(T(index_candle), (Stochs.Slow[index_candle]*(100+6*ChartSteps.Stoch)/100), ChartTags.Stoch, "SStochSpring4|End|"..tostring(Signals[Directions.Down].Stochs.Spring4.Count).."|"..duration.."|"..index_candle, ChartLabelIcons.Cross, SignalLevels.Elementary)
			end
		end
	end
	--#endregion

	--
	-- #region	II.7. Elementary Stoch Signal: Signals[Directions.Down/Up].Stochs.Steamer
	--				Enter Signal: Signals[Directions.Down/Up].TrendOn/Uturn
	--				Depends on signal: SignalOscHorSteamer, SignalOscVerSteamer
	--				Terminates by signals:
	--				Terminates by duration:
	--
--	if (index_candle> 3000) then
	-- 	PrintDebugMessage("canle", index_candle, T(index_candle).day, T(index_candle).hour, T(index_candle).min)

	if (CheckDataSufficiency(index_candle,  (Signals.Params.Steamer.Duration+2), Stochs.Slow) and CheckDataSufficiency(index_candle,  (Signals.Params.Steamer.Duration+2), Stochs.Fast)) then
--[[ 		-- check stoch steamer up
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
		end ]]

		-- check stoch steamer up
--[[ 		if (SignalOscHSteamer(Stochs, index_candle, Directions.Up)) then
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
		end ]]
	end
--end
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

	--
	--#region	III.4. Elementary RSI Signal: Signals[Directions.Down/Up].RSIs.Uturn3
	--				Enter Signals: Signals[Directions.Down/Up].Uturn/Spring1
	--				Depends on signal: SignalOscUturn3
	--				Terminates by signals: Reverse self-signal, SignalOscCross
	--				Terminates by duration: Signals.Params.Durations.Elementary
	--
	if (CheckDataSufficiency(index_candle, 3, RSIs.Slow) and CheckDataSufficiency(index_candle, 3, RSIs.Fast)) then
		--
		-- check start elementary uturn3 up signal
		--
		if (SignalOscUturn3(RSIs, index_candle, Directions.Up)) then
			-- set elementary down signal off
			Signals[Directions.Down].RSIs.Uturn3.Candle = 0
			-- set elementary up  signal on
			Signals[Directions.Up].RSIs.Uturn3.Candle = index_candle - 1
			Signals[Directions.Up].RSIs.Uturn3.Count = Signals[Directions.Up].RSIs.Uturn3.Count + 1

			-- set chart label
			if (Labels[RSIs.Name][index_candle-1] ~= nil) then
				DelLabel(ChartTags.RSI, Labels[RSIs.Name][index_candle-1])
			end
			Labels[RSIs.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (RSIs.Slow[index_candle-1]*(100-4*ChartSteps.RSI)/100), ChartTags.RSI, "LRSIUturn3|Start|"..tostring(Signals[Directions.Up].RSIs.Uturn3.Count).."|"..(index_candle-1), ChartLabelIcons.Romb, SignalLevels.Elementary)
		end

		-- check presence elementary up signal
		if (Signals[Directions.Up].RSIs.Uturn3.Candle > 0) then
			-- set duration elemenetary up signal
			local duration = index_candle - Signals[Directions.Up].RSIs.Uturn3.Candle
			-- check continuation elementary up signal
			if (duration <= Signals.Params.Durations.Elementary) then
				-- check termination by fast rsi cross slow rsi down
				if (SignalOscCross(RSIs, index_candle, Directions.Down)) then
					-- set elementary up signal off
					Signals[Directions.Up].RSIs.Uturn3.Candle = 0

					-- set chart label
					if (Labels[RSIs.Name][index_candle-1] ~= nil) then
						DelLabel(ChartTags.RSI, Labels[RSIs.Name][index_candle-1])
					end
					Labels[RSIs.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (RSIs.Slow[index_candle-1]*(100-4*ChartSteps.RSI)/100), ChartTags.RSI, "LRSICrossDown|End|"..tostring(Signals[Directions.Up].RSIs.Uturn3.Count).."|"..(duration-1).."|"..(index_candle-1), ChartLabelIcons.Cross, SignalLevels.Elementary)
				-- process continuation  elementary up signal
				else
					-- set chart label
					-- if (Labels[RSIs.Name][index_candle] ~= nil) then
					-- 	DelLabel(ChartTags.RSI, Labels[RSIs.Name][index_candle])
					-- end
					--Labels[RSIs.Name][index_candle] = SetChartLabel(T(index_candle), (RSIs.Slow[index_candle]*(100-4*ChartSteps.RSI)/100), ChartTags.RSI, "LRSIUturn3|Continue|"..tostring(Signals[Directions.Up].RSIs.Uturn3.Count).."|"..duration.."|"..index_candle, ChartLabelIcons.Romb, SignalLevels.Elementary)
				end
			-- check termination by duration elementary up signal
			elseif (duration > Signals.Params.Durations.Elementary) then
				-- set elementary up signal off
				Signals[Directions.Up].RSIs.Uturn3.Candle = 0

				-- set chart label
				if (Labels[RSIs.Name][index_candle] ~= nil) then
					DelLabel(ChartTags.Stoch, Labels[RSIs.Name][index_candle])
				end
				Labels[RSIs.Name][index_candle] = SetChartLabel(T(index_candle), (RSIs.Slow[index_candle]*(100-4*ChartSteps.RSI)/100), ChartTags.RSI, "LRSIUturn3|End|"..tostring(Signals[Directions.Up].RSIs.Uturn3.Count).."|"..duration.."|"..index_candle, ChartLabelIcons.Cross, SignalLevels.Elementary)
			end
		end

		--
		-- check start elementary uturn3 down signal
		--
		if (SignalOscUturn3(RSIs, index_candle, Directions.Down)) then
			-- set elementary up signal off
			Signals[Directions.Up].RSIs.Uturn3.Candle = 0
			-- set elementary down signal on
			Signals[Directions.Down].RSIs.Uturn3.Candle = index_candle - 1
			Signals[Directions.Down].RSIs.Uturn3.Count = Signals[Directions.Down].RSIs.Uturn3.Count + 1

			-- set chart label
			if (Labels[RSIs.Name][index_candle-1] ~= nil) then
				DelLabel(ChartTags.RSI, Labels[RSIs.Name][index_candle-1])
			end
			Labels[RSIs.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (RSIs.Slow[index_candle-1]*(100+4*ChartSteps.RSI)/100), ChartTags.RSI, "SRSIUturn3|Start|"..tostring(Signals[Directions.Down].RSIs.Uturn3.Count).."|"..(index_candle-1), ChartLabelIcons.Romb, SignalLevels.Elementary)
		end

		-- check presence elementary down signal 
		if (Signals[Directions.Down].RSIs.Uturn3.Candle > 0) then
			-- set duration elemenetary down signal
			local duration = index_candle - Signals[Directions.Down].RSIs.Uturn3.Candle
			-- check continuation elementary down signal
			if (duration <= Signals.Params.Durations.Elementary) then
				-- check termination by fast rsi cross slow rsi up
				if (SignalOscCross(RSIs, index_candle, Directions.Up)) then
					-- set elementary down signal off
					Signals[Directions.Down].RSIs.Uturn3.Candle = 0

					-- set chart label
					if (Labels[RSIs.Name][index_candle-1] ~= nil) then
						DelLabel(ChartTags.RSI, Labels[RSIs.Name][index_candle-1])
					end
					Labels[RSIs.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (RSIs.Slow[index_candle-1]*(100+4*ChartSteps.RSI)/100), ChartTags.RSI, "SRSICrossUp|End|"..tostring(Signals[Directions.Down].RSIs.Uturn3.Count).."|"..(duration-1).."|"..(index_candle-1), ChartLabelIcons.Cross, SignalLevels.Elementary)
				-- process continuation  elementary up signal
				else
					-- set chart label
					-- if (Labels[RSIs.Name][index_candle] ~= nil) then
					-- 	DelLabel(ChartTags.RSI, Labels[RSIs.Name][index_candle])
					-- end
					--Labels[RSIs.Name][index_candle] = SetChartLabel(T(index_candle), (RSIs.Slow[index_candle]*(100+4*ChartSteps.RSI)/100), ChartTags.RSI, "SRSIUturn3|Continue|"..tostring(Signals[Directions.Down].RSIs.Uturn3.Count).."|"..duration.."|"..index_candle, ChartLabelIcons.Romb, SignalLevels.Elementary)
				end
			-- check termination by duration elementary down signal
			elseif (duration > Signals.Params.Durations.Elementary) then
				-- set elementary down signal off
				Signals[Directions.Down].RSIs.Uturn3.Candle = 0

				-- set chart label
				if (Labels[RSIs.Name][index_candle] ~= nil) then
					DelLabel(ChartTags.RSI, Labels[RSIs.Name][index_candle])
				end
				Labels[RSIs.Name][index_candle] = SetChartLabel(T(index_candle), (RSIs.Slow[index_candle]*(100+4*ChartSteps.RSI)/100), ChartTags.RSI, "SRSIUturn3|End|"..tostring(Signals[Directions.Down].RSIs.Uturn3.Count).."|"..duration.."|"..index_candle, ChartLabelIcons.Cross, SignalLevels.Elementary)
			end
		end
	end
	--#endregion

	--
	--#region	III.5. Elementary RSI Signal: Signals[Directions.Down/Up].RSIs.Uturn4
	--				Enter Signals: Signals[Directions.Down/Up].Uturn/Spring1
	--				Depends on signal: SignalOscUturn4
	--				Terminates by signals: Reverse self-signal, SignalOscCross
	--				Terminates by duration: Signals.Params.Durations.Elementary
	--
	if (CheckDataSufficiency(index_candle, 4, RSIs.Slow) and CheckDataSufficiency(index_candle, 4, RSIs.Fast)) then
		--
		-- check start elementary uturn3 up signal
		--
		if (SignalOscUturn4(RSIs, index_candle, Directions.Up)) then
			-- set elementary down signal off
			Signals[Directions.Down].RSIs.Uturn4.Candle = 0
			-- set elementary up signal on
			Signals[Directions.Up].RSIs.Uturn4.Candle = index_candle - 1
			Signals[Directions.Up].RSIs.Uturn4.Count = Signals[Directions.Up].RSIs.Uturn4.Count + 1

			-- set chart label
			if (Labels[RSIs.Name][index_candle-1] ~= nil) then
				DelLabel(ChartTags.RSI, Labels[RSIs.Name][index_candle-1])
			end
			Labels[RSIs.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (RSIs.Slow[index_candle-1]*(100-5*ChartSteps.RSI)/100), ChartTags.RSI, "LRSIUturn4|Start|"..tostring(Signals[Directions.Up].RSIs.Uturn4.Count).."|"..(index_candle-1), ChartLabelIcons.Plus, SignalLevels.Elementary)
		end

		-- check presence elementary up signal
		if (Signals[Directions.Up].RSIs.Uturn4.Candle > 0) then
			-- set duration elemenetary up signal
			local duration = index_candle - Signals[Directions.Up].RSIs.Uturn4.Candle
			-- check continuation elementary up signal
			if (duration <= Signals.Params.Durations.Elementary) then
				-- check termination by fast rsi cross slow rsi down
				if (SignalOscCross(RSIs, index_candle, Directions.Down)) then
					-- set elementary up signal off
					Signals[Directions.Up].RSIs.Uturn4.Candle = 0

					-- set chart label
					if (Labels[RSIs.Name][index_candle-1] ~= nil) then
						DelLabel(ChartTags.RSI, Labels[RSIs.Name][index_candle-1])
					end
					Labels[RSIs.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (RSIs.Slow[index_candle-1]*(100-5*ChartSteps.RSI)/100), ChartTags.RSI, "LRSICrossDown|End|"..tostring(Signals[Directions.Up].RSIs.Uturn4.Count).."|"..(duration-1).."|"..(index_candle-1), ChartLabelIcons.Cross, SignalLevels.Elementary)
				-- process continuation elementary up signal
				else
					-- set chart label
					-- if (Labels[RSIs.Name][index_candle] ~= nil) then
					-- 	DelLabel(ChartTags.RSI, Labels[RSIs.Name][index_candle])
					-- end
					--Labels[RSIs.Name][index_candle] = SetChartLabel(T(index_candle), (RSIs.Slow[index_candle]*(100-5*ChartSteps.RSI)/100), ChartTags.RSI, "LRSIUturn4|Continue|"..tostring(Signals[Directions.Up].RSIs.Uturn4.Count).."|".. duration.."|"..index_candle, ChartLabelIcons.Plus, SignalLevels.Elementary)
				end
			-- check termination by duration elementary up signal
			elseif (duration > Signals.Params.Durations.Elementary) then
				-- set elementary up signal off
				Signals[Directions.Up].RSIs.Uturn4.Candle = 0

				-- set chart label
				if (Labels[RSIs.Name][index_candle] ~= nil) then
					DelLabel(ChartTags.Stoch, Labels[RSIs.Name][index_candle])
				end
				Labels[RSIs.Name][index_candle] = SetChartLabel(T(index_candle), (RSIs.Slow[index_candle]*(100-5*ChartSteps.RSI)/100), ChartTags.RSI, "LRSIUturn4|End|"..tostring(Signals[Directions.Up].RSIs.Uturn4.Count).."|"..duration.."|"..index_candle, ChartLabelIcons.Cross, SignalLevels.Elementary)
			end
		end

		--
		-- check start elementary uturn3 down signal
		--
		if (SignalOscUturn4(RSIs, index_candle, Directions.Down)) then
			-- set elementary up signal off
			Signals[Directions.Up].RSIs.Uturn4.Candle = 0
			-- set elementary down signal on
			Signals[Directions.Down].RSIs.Uturn4.Candle = index_candle - 1
			Signals[Directions.Down].RSIs.Uturn4.Count = Signals[Directions.Down].RSIs.Uturn4.Count + 1

			-- set chart label
			if (Labels[RSIs.Name][index_candle-1] ~= nil) then
				DelLabel(ChartTags.RSI, Labels[RSIs.Name][index_candle-1])
			end
			Labels[RSIs.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (RSIs.Slow[index_candle-1]*(100+5*ChartSteps.RSI)/100), ChartTags.RSI, "SRSIUturn4|Start|"..tostring(Signals[Directions.Down].RSIs.Uturn4.Count).."|"..(index_candle-1), ChartLabelIcons.Plus, SignalLevels.Elementary)
		end

		-- check presence elementary down signal
		if (Signals[Directions.Down].RSIs.Uturn4.Candle > 0) then
			-- set duration elemenetary down signal
			local duration = index_candle - Signals[Directions.Down].RSIs.Uturn4.Candle
			-- check continuation elementary down signal
			if (duration <= Signals.Params.Durations.Elementary) then
				-- check termination by fast rsi cross slow rsi up
				if (SignalOscCross(RSIs, index_candle, Directions.Up)) then
					-- set elementary down signal off
					Signals[Directions.Down].RSIs.Uturn4.Candle = 0

					-- set chart label
					if (Labels[RSIs.Name][index_candle-1] ~= nil) then
						DelLabel(ChartTags.RSI, Labels[RSIs.Name][index_candle-1])
					end
					Labels[RSIs.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (RSIs.Slow[index_candle-1]*(100+5*ChartSteps.RSI)/100), ChartTags.RSI, "SRSICrossUp|End|"..tostring(Signals[Directions.Down].RSIs.Uturn4.Count).."|"..(duration-1).."|"..(index_candle-1), ChartLabelIcons.Cross, SignalLevels.Elementary)
				-- process continuation elementary down signal
				else
					-- set chart label
					-- if (Labels[RSIs.Name][index_candle] ~= nil) then
					-- 	DelLabel(ChartTags.RSI, Labels[RSIs.Name][index_candle])
					-- end
					--Labels[RSIs.Name][index_candle] = SetChartLabel(T(index_candle), (RSIs.Slow[index_candle]*(100+5*ChartSteps.RSI)/100), ChartTags.RSI, "SRSIUturn4|Continue|"..tostring(Signals[Directions.Down].RSIs.Uturn4.Count).."|"..duration.."|"..index_candle, ChartLabelIcons.Plus, SignalLevels.Elementary)
					
				end
			-- check termination by duration elementary down signal
			elseif (duration > Signals.Params.Durations.Elementary) then
				-- set elementary down signal off
				Signals[Directions.Down].RSIs.Uturn4.Candle = 0

				-- set chart label
				if (Labels[RSIs.Name][index_candle] ~= nil) then
					DelLabel(ChartTags.Stoch, Labels[RSIs.Name][index_candle])
				end
				Labels[RSIs.Name][index_candle] = SetChartLabel(T(index_candle), (RSIs.Slow[index_candle]*(100+5*ChartSteps.RSI)/100), ChartTags.RSI, "SRSIUturn4|End|"..tostring(Signals[Directions.Down].RSIs.Uturn4.Count).."|"..duration.."|"..index_candle, ChartLabelIcons.Cross, SignalLevels.Elementary)
			end
		end
	end
	--#endregion

	--
	--#region	III.6. Elementary RSI Signal: Signals[Directions.Down].RSIs.Spring3
	--				Enter Signals: Signals[Directions.Down/Up].Spring1/2
	--				Depends on signal: SignalOscSpring3
	--				Terminates by signals: Reverse self-signal, SignalOscCross
	--				Terminates by duration: Signals.Params.Durations.Elementary
	--
	if (CheckDataSufficiency(index_candle, 3, RSIs.Slow) and CheckDataSufficiency(index_candle, 3, RSIs.Fast)) then
		--
		-- check start elementary spring3 up signal
		--
		if (SignalOscSpring3(RSIs, index_candle, Directions.Up)) then
			-- set elementary down signal off
			Signals[Directions.Down].RSIs.Spring3.Candle = 0
			-- set elementary up signal on
			Signals[Directions.Up].RSIs.Spring3.Candle = index_candle - 1
			Signals[Directions.Up].RSIs.Spring3.Count = Signals[Directions.Up].RSIs.Spring3.Count + 1

			-- set chart label
			if (Labels[RSIs.Name][index_candle-1] ~= nil) then
				DelLabel(ChartTags.RSI, Labels[RSIs.Name][index_candle-1])
			end
			Labels[RSIs.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (RSIs.Slow[index_candle-1]*(100-6*ChartSteps.RSI)/100), ChartTags.RSI, "LRSISpring3|Start|"..tostring(Signals[Directions.Up].RSIs.Spring3.Count).."|"..(index_candle-1), ChartLabelIcons.Flash, SignalLevels.Elementary)
		end

		-- check presence elementary up signal
		if (Signals[Directions.Up].RSIs.Spring3.Candle > 0) then
			-- set duration elemenetary up signal
			local duration = index_candle - Signals[Directions.Up].RSIs.Spring3.Candle
			-- check continuation elementary up signal
			if (duration <= Signals.Params.Durations.Elementary) then
				-- check termination by fast rsi cross slow rsi down
				if (SignalOscCross(RSIs, index_candle, Directions.Down)) then
					-- set elementary up signal off
					Signals[Directions.Up].RSIs.Spring3.Candle = 0

					-- set chart label
					if (Labels[RSIs.Name][index_candle-1] ~= nil) then
						DelLabel(ChartTags.RSI, Labels[RSIs.Name][index_candle-1])
					end
					Labels[RSIs.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (RSIs.Slow[index_candle-1]*(100-6*ChartSteps.RSI)/100), ChartTags.RSI, "LRSICrossDown|End|"..tostring(Signals[Directions.Up].RSIs.Spring3.Count).."|"..(duration-1).."|"..(index_candle-1), ChartLabelIcons.Cross, SignalLevels.Elementary)
				-- process continuation elementary up signal
				else
					-- set chart label
					-- if (Labels[RSIs.Name][index_candle] ~= nil) then
					-- 	DelLabel(ChartTags.RSI, Labels[RSIs.Name][index_candle])
					-- end
					--Labels[RSIs.Name][index_candle] = SetChartLabel(T(index_candle), (RSIs.Slow[index_candle]*(100-6*ChartSteps.RSI)/100), ChartTags.RSI, "LRSISpring3|Continue|"..tostring(Signals[Directions.Up].RSIs.Spring3.Count).."|"..duration.."|"..index_candle, ChartLabelIcons.Flash, SignalLevels.Elementary)

				end
			-- check termination by duration elementary up signal
			elseif (duration > Signals.Params.Durations.Elementary) then
				-- set elementary up signal off
				Signals[Directions.Up].RSIs.Spring3.Candle = 0

				-- set chart label
				if (Labels[RSIs.Name][index_candle] ~= nil) then
					DelLabel(ChartTags.Stoch, Labels[RSIs.Name][index_candle])
				end
				Labels[RSIs.Name][index_candle] = SetChartLabel(T(index_candle), (RSIs.Slow[index_candle]*(100-6*ChartSteps.RSI)/100), ChartTags.RSI, "LRSISpring3|End|"..tostring(Signals[Directions.Up].RSIs.Spring3.Count).."|"..duration.."|"..index_candle, ChartLabelIcons.Cross, SignalLevels.Elementary)
			end
		end

		--
		-- check start elementary spring3 down signal
		--
		if (SignalOscSpring3(RSIs, index_candle, Directions.Down)) then
			-- set elementary up signal off
			Signals[Directions.Up].RSIs.Spring3.Candle = 0
			-- set elementary down signal on
			Signals[Directions.Down].RSIs.Spring3.Candle = index_candle - 1
			Signals[Directions.Down].RSIs.Spring3.Count = Signals[Directions.Down].RSIs.Spring3.Count + 1

			-- set chart label
			if (Labels[RSIs.Name][index_candle-1] ~= nil) then
				DelLabel(ChartTags.RSI, Labels[RSIs.Name][index_candle-1])
			end
			Labels[RSIs.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (RSIs.Slow[index_candle-1]*(100+6*ChartSteps.RSI)/100), ChartTags.RSI, "SRSISpring3|Start|"..tostring(Signals[Directions.Down].RSIs.Spring3.Count).."|"..(index_candle-1), ChartLabelIcons.Flash, SignalLevels.Elementary)
		end

		-- check presence elementary down signal
		if (Signals[Directions.Down].RSIs.Spring3.Candle > 0) then
			-- set duration elemenetary down signal
			local duration = index_candle - Signals[Directions.Down].RSIs.Spring3.Candle
			-- check continuation elementary down signal
			if (duration <= Signals.Params.Durations.Elementary) then
				-- check termination by fast rsi cross slow rsi up
				if (SignalOscCross(RSIs, index_candle, Directions.Up)) then
					-- set elementary down signal off
					Signals[Directions.Down].RSIs.Spring3.Candle = 0

					-- set chart label
					if (Labels[RSIs.Name][index_candle-1] ~= nil) then
						DelLabel(ChartTags.RSI, Labels[RSIs.Name][index_candle-1])
					end
					Labels[RSIs.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (RSIs.Slow[index_candle-1]*(100+6*ChartSteps.RSI)/100), ChartTags.RSI, "SRSICrossUp|End|"..tostring(Signals[Directions.Down].RSIs.Spring3.Count).."|"..(duration-1).."|"..(index_candle-1), ChartLabelIcons.Cross, SignalLevels.Elementary)
				-- process continuation elementary down signal
				else
					-- set chart label
					-- if (Labels[RSIs.Name][index_candle] ~= nil) then
					-- 	DelLabel(ChartTags.RSI, Labels[RSIs.Name][index_candle])
					-- end
					--Labels[RSIs.Name][index_candle] = SetChartLabel(T(index_candle), (RSIs.Slow[index_candle]*(100+6*ChartSteps.RSI)/100), ChartTags.RSI, "SRSISpring3|Continue|"..tostring(Signals[Directions.Down].RSIs.Spring3.Count).."|"..duration.."|"..index_candle, ChartLabelIcons.Flash, SignalLevels.Elementary)
				end
			-- check termination by duration elementary down signal
			elseif (duration > Signals.Params.Durations.Elementary) then
				-- set elementary down signal off
				Signals[Directions.Down].RSIs.Spring3.Candle = 0

				-- set chart label
				if (Labels[RSIs.Name][index_candle] ~= nil) then
					DelLabel(ChartTags.Stoch, Labels[RSIs.Name][index_candle])
				end
				Labels[RSIs.Name][index_candle] = SetChartLabel(T(index_candle), (RSIs.Slow[index_candle]*(100+6*ChartSteps.RSI)/100), ChartTags.RSI, "SRSISpring3|End|"..tostring(Signals[Directions.Down].RSIs.Spring3.Count).."|"..duration.."|"..index_candle, ChartLabelIcons.Cross, SignalLevels.Elementary)
			end
		end
	end
	--#endregion

	--
	--#region	III.7. Elementary RSI Signal: Signals[Directions.Down].RSIs.Spring4
	--				Enter Signals: Signals[Directions.Down/Up].Spring1/2
	--				Depends on signal: SignalOscSpring4
	--				Terminates by signals: Reverse self-signal, SignalOscCross
	--				Terminates by duration: Signals.Params.Durations.Elementary
	--
	if (CheckDataSufficiency(index_candle, 4, RSIs.Slow) and CheckDataSufficiency(index_candle, 4, RSIs.Fast)) then
		--
		-- check start elementary spring4 up signal
		--
		if ((SignalOscSpring4(RSIs, index_candle, Directions.Up))) then
			-- set elementary down signal off
			Signals[Directions.Down].RSIs.Spring4.Candle = 0
			-- set elementary up signal on
			Signals[Directions.Up].RSIs.Spring4.Candle = index_candle - 1
			Signals[Directions.Up].RSIs.Spring4.Count = Signals[Directions.Up].RSIs.Spring4.Count + 1

			-- set chart label
			if (Labels[RSIs.Name][index_candle-1] ~= nil) then
				DelLabel(ChartTags.RSI, Labels[RSIs.Name][index_candle-1])
			end
			Labels[RSIs.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (RSIs.Slow[index_candle-1]*(100-7*ChartSteps.RSI)/100), ChartTags.RSI, "LRSISpring4|Start|"..tostring(Signals[Directions.Up].RSIs.Spring4.Count).."|"..(index_candle-1), ChartLabelIcons.Asterix, SignalLevels.Elementary)
		end

		-- check presence elementary up signal
		if (Signals[Directions.Up].RSIs.Spring4.Candle > 0) then
			-- set duration elemenetary up signal
			local duration = index_candle - Signals[Directions.Up].RSIs.Spring4.Candle
			-- check continuation elementary up signal
			if (duration <= Signals.Params.Durations.Elementary) then
				-- check termination by fast rsi cross slow rsi down
				if (SignalOscCross(RSIs, index_candle, Directions.Down)) then
					-- set elementary up signal off
					Signals[Directions.Up].RSIs.Spring4.Candle = 0

					-- set chart label
					if (Labels[RSIs.Name][index_candle-1] ~= nil) then
						DelLabel(ChartTags.RSI, Labels[RSIs.Name][index_candle-1])
					end
					Labels[RSIs.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (RSIs.Slow[index_candle-1]*(100-7*ChartSteps.RSI)/100), ChartTags.RSI, "LRSICrossDown|End|"..tostring(Signals[Directions.Up].RSIs.Spring4.Count).."|"..(duration-1).."|"..(index_candle-1), ChartLabelIcons.Cross, SignalLevels.Elementary)
				-- process continuation elementary up signal
				else
					-- set chart label
					-- if (Labels[RSIs.Name][index_candle] ~= nil) then
					-- 	DelLabel(ChartTags.RSI, Labels[RSIs.Name][index_candle])
					-- end
					--Labels[RSIs.Name][index_candle] = SetChartLabel(T(index_candle), (RSIs.Slow[index_candle]*(100-7*ChartSteps.RSI)/100), ChartTags.RSI, "LRSISpring4|Continue|"..tostring(Signals[Directions.Up].RSIs.Spring4.Count).."|"..duration.."|"..index_candle, ChartLabelIcons.Asterix, SignalLevels.Elementary)
				end
			-- check termination by duration elementary up signal
			elseif (duration > Signals.Params.Durations.Elementary) then
				-- set elementary up signal off
				Signals[Directions.Up].RSIs.Spring4.Candle = 0

				-- set chart label
				if (Labels[RSIs.Name][index_candle] ~= nil) then
					DelLabel(ChartTags.Stoch, Labels[RSIs.Name][index_candle])
				end
				Labels[RSIs.Name][index_candle] = SetChartLabel(T(index_candle), (RSIs.Slow[index_candle]*(100-7*ChartSteps.RSI)/100), ChartTags.RSI, "LRSISpring4|End|"..tostring(Signals[Directions.Up].RSIs.Spring4.Count).."|"..duration.."|"..index_candle, ChartLabelIcons.Cross, SignalLevels.Elementary)
			end
		end

		--
		-- check start elementary spring4 down signal
		--
		if (SignalOscSpring4(RSIs, index_candle, Directions.Down)) then
			-- set elementary up signal off
			Signals[Directions.Up].RSIs.Spring4.Candle = 0
			-- set elementary down signal on
			Signals[Directions.Down].RSIs.Spring4.Candle = index_candle - 1
			Signals[Directions.Down].RSIs.Spring4.Count = Signals[Directions.Down].RSIs.Spring4.Count + 1

			-- set chart label
			if (Labels[RSIs.Name][index_candle-1] ~= nil) then
				DelLabel(ChartTags.RSI, Labels[RSIs.Name][index_candle-1])
			end
			Labels[RSIs.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (RSIs.Slow[index_candle-1]*(100+7*ChartSteps.RSI)/100), ChartTags.RSI, "SRSISpring4|Start|"..tostring(Signals[Directions.Down].RSIs.Spring4.Count).."|"..(index_candle-1), ChartLabelIcons.Asterix, SignalLevels.Elementary)
		end

		-- check presence elementary down signal
		if (Signals[Directions.Down].RSIs.Spring4.Candle > 0) then
			-- set duration elemenetary down signal
			local duration = index_candle - Signals[Directions.Down].RSIs.Spring4.Candle
			-- check continuation elementary down signal
			if (duration <= Signals.Params.Durations.Elementary) then
				-- check termination by fast rsi cross slow rsi up
				if (SignalOscCross(RSIs, index_candle, Directions.Up)) then
					-- set elementary down signal off
					Signals[Directions.Down].RSIs.Spring4.Candle = 0

					-- set chart label
					if (Labels[RSIs.Name][index_candle-1] ~= nil) then
						DelLabel(ChartTags.RSI, Labels[RSIs.Name][index_candle-1])
					end
					Labels[RSIs.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (RSIs.Slow[index_candle-1]*(100+7*ChartSteps.RSI)/100), ChartTags.RSI, "SRSICrossUp|End|"..tostring(Signals[Directions.Down].RSIs.Spring4.Count).."|"..(duration-1).."|"..(index_candle-1), ChartLabelIcons.Cross, SignalLevels.Elementary)
				-- process continuation elementary down signal
				else
					-- set chart label
					-- if (Labels[RSIs.Name][index_candle] ~= nil) then
					-- 	DelLabel(ChartTags.RSI, Labels[RSIs.Name][index_candle])
					-- end
					--Labels[RSIs.Name][index_candle] = SetChartLabel(T(index_candle), (RSIs.Slow[index_candle]*(100+7*ChartSteps.RSI)/100), ChartTags.RSI, "SRSISpring4|Continue|"..tostring(Signals[Directions.Down].RSIs.Spring4.Count).."|"..duration.."|"..index_candle, ChartLabelIcons.Asterix, SignalLevels.Elementary)

				end
			-- check termination by duration elementary down signal
			elseif (duration > Signals.Params.Durations.Elementary) then
				-- set elementary down signal off
				Signals[Directions.Down].RSIs.Spring4.Candle = 0

				-- set chart label
				if (Labels[RSIs.Name][index_candle] ~= nil) then
					DelLabel(ChartTags.Stoch, Labels[RSIs.Name][index_candle])
				end
				Labels[RSIs.Name][index_candle] = SetChartLabel(T(index_candle), (RSIs.Slow[index_candle]*(100+7*ChartSteps.RSI)/100), ChartTags.RSI, "SRSISpring4|End|"..tostring(Signals[Directions.Down].RSIs.Spring4.Count).."|"..duration.."|"..index_candle, ChartLabelIcons.Cross, SignalLevels.Elementary)
			end
		end
	end
	--#endregion

	----------------------------------------------------------------------------
	--	IV. Trend and Impulse Complex Signals
	----------------------------------------------------------------------------
	--
	--#region	IV.1. Trend Signal: Signals[Directions.Down/Up].Trend
	---				Depends on signal: Prices.CrossMA
	--				Terminates by signals: Reverse self-signal
	--				Terminates by duration: -
	--
	-- check start trend up signal and check elementary up signal
	--
	if ((Signals[Directions.Up].Trend.Candle == 0) and (Signals[Directions.Up].Prices.CrossMA.Candle > 0) and
	-- check close prices move up - analog steamer
	(CheckDataSufficiency(index_candle, 2, MAs) and SignalMove(MAs, index_candle, Directions.Up))) then
		-- set trend down signal off
		Signals[Directions.Down].Trend.Candle = 0
		-- set trend up signal on
		Signals[Directions.Up].Trend.Count = Signals[Directions.Up].Trend.Count + 1
		Signals[Directions.Up].Trend.Candle = index_candle - 1

		-- set chart label
		if (Labels[Prices.Name][index_candle-1] ~= nil) then
			DelLabel(ChartTags.Price, Labels[Prices.Name][index_candle-1])
		end 
		Labels[Prices.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (Prices.Low[index_candle-1]-4*ChartSteps.Price*SecInfo.min_price_step), ChartTags.Price, "LTrend|Start|"..tostring(Signals[Directions.Up].Trend.Count).."|"..(index_candle-1), ChartLabelIcons.BigArrow, SignalLevels.Trend)
	end

	--
	-- check start trend down signal and check elementary down signal
	--
	if ((Signals[Directions.Down].Trend.Candle == 0) and (Signals[Directions.Down].Prices.CrossMA.Candle > 0) and
	-- check close prices move down
	(CheckDataSufficiency(index_candle, 2, MAs) and SignalMove(MAs, index_candle, Directions.Down))) then
		-- set trend up signal off
		Signals[Directions.Up].Trend.Candle = 0
		-- set trend down signal on
		Signals[Directions.Down].Trend.Count = Signals[Directions.Down].Trend.Count + 1
		Signals[Directions.Down].Trend.Candle = index_candle - 1

		-- set chart label
		if (Labels[Prices.Name][index_candle-1] ~= nil) then
			DelLabel(ChartTags.Price, Labels[Prices.Name][index_candle-1])
		end
		Labels[Prices.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (Prices.High[index_candle-1]+4*ChartSteps.Price*SecInfo.min_price_step), ChartTags.Price, "STrend|Start|"..tostring(Signals[Directions.Down].Trend.Count).."|"..(index_candle-1), ChartLabelIcons.BigArrow, SignalLevels.Trend)
	end
	--#endregion

	--
	--#region	IV.2. Impulse Signal: Signals[Directions.Down/Up].Impulse
	--				Depends on signal: Stochs.Cross50, Stochs.Cross, RSIs.Cross50, RSIs.Cross
	--				Terminates by signals: breaking one elementary signals Stochs.Cross50, Stochs.Cross, RSIs.Cross50, RSIs.Cross
	--				Terminates by duration: -
	--
	-- check start impulse up signal
	--
	if (Signals[Directions.Up].Impulse.Candle == 0) then
		-- check elementary up signals
		if (((Signals[Directions.Up].Stochs.Cross50.Candle > 0) and (Signals[Directions.Up].Stochs.Cross.Candle > 0) and
		(Signals[Directions.Up].RSIs.Cross50.Candle > 0) and (Signals[Directions.Up].RSIs.Cross.Candle > 0)) and
		-- slow stoch move up
		(CheckDataSufficiency(index_candle, 2, Stochs.Slow) and SignalMove(Stochs.Slow, index_candle, Directions.Up))) then
		--check slow stoch steamer up
		--?	SignalOscSteamer(Stochs.Slow, index_candle, Directions.Up)
			-- set impulse down signal off
			Signals[Directions.Down].Impulse.Candle = 0
			-- set impulse up signal on
			Signals[Directions.Up].Impulse.Count = Signals[Directions.Up].Impulse.Count + 1
			Signals[Directions.Up].Impulse.Candle = index_candle - 1

			-- set chart label
			if (Labels[Prices.Name][index_candle-1] ~= nil) then
				DelLabel(ChartTags.Price, Labels[Prices.Name][index_candle-1])
			end
			Labels[Prices.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (Prices.Low[index_candle-1]-5*ChartSteps.Price*SecInfo.min_price_step), ChartTags.Price, "LImpulse|Start|"..tostring(Signals[Directions.Up].Impulse.Count).."|"..(index_candle-1), ChartLabelIcons.BigTriangle, SignalLevels.Impulse)
		end
	end

	-- check presence impulse up signal
	if (Signals[Directions.Up].Impulse.Candle > 0) then
		-- check termination by breaking one elementary up signals
		if ((Signals[Directions.Up].Stochs.Cross50.Candle == 0) or (Signals[Directions.Up].Stochs.Cross.Candle == 0) or
		(Signals[Directions.Up].RSIs.Cross50.Candle == 0) or (Signals[Directions.Up].RSIs.Cross.Candle == 0)) then
			-- set impulse up signal off
			Signals[Directions.Up].Impulse.Candle = 0

			-- set chart label
			if (Labels[Prices.Name][index_candle-1] ~= nil) then
				DelLabel(ChartTags.Price, Labels[Prices.Name][index_candle-1])
			end
			Labels[Prices.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (Prices.Low[index_candle-1]-5*ChartSteps.Price*SecInfo.min_price_step), ChartTags.Price, "LImpulse|End|"..tostring(Signals[Directions.Up].Impulse.Count).."|"..(index_candle-1), ChartLabelIcons.BigCross, SignalLevels.Impulse)
		end
	end

	--
	-- check start impulse down signal
	--
	if ((Signals[Directions.Down].Impulse.Candle == 0)) then
		-- check elementary down signals
		if (((Signals[Directions.Down].Stochs.Cross50.Candle > 0) and (Signals[Directions.Down].Stochs.Cross.Candle > 0) and
		(Signals[Directions.Down].RSIs.Cross50.Candle > 0) and (Signals[Directions.Down].RSIs.Cross.Candle > 0)) and
		-- slow stoch move down
		(CheckDataSufficiency(index_candle, 2, Stochs.Slow) and SignalMove(Stochs.Slow, index_candle, Directions.Down))) then
		-- check slow stoch steamer down
		--?	SignalOscSteamer(osc.Slow, index_candle, Directions.Down)
			-- set impulse up signal off
			Signals[Directions.Up].Impulse.Candle = 0
			-- set impulse down signal on
			Signals[Directions.Down].Impulse.Count = Signals[Directions.Down].Impulse.Count + 1
			Signals[Directions.Down].Impulse.Candle = index_candle - 1

			-- set chart label
			if (Labels[Prices.Name][index_candle-1] ~= nil) then
				DelLabel(ChartTags.Price, Labels[Prices.Name][index_candle-1])
			end
			Labels[Prices.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (Prices.High[index_candle-1]+5*ChartSteps.Price*SecInfo.min_price_step), ChartTags.Price, "SImpulse|Start|"..tostring(Signals[Directions.Down].Impulse.Count).."|"..(index_candle-1), ChartLabelIcons.BigTriangle, SignalLevels.Impulse)
		end
	end

	-- check presence impulse up signal
	if (Signals[Directions.Down].Impulse.Candle > 0) then
		-- check termination by breaking one elementary down signals
		if ((Signals[Directions.Down].Stochs.Cross50.Candle == 0) or (Signals[Directions.Down].Stochs.Cross.Candle == 0) or
		(Signals[Directions.Down].RSIs.Cross50.Candle == 0) or (Signals[Directions.Down].RSIs.Cross.Candle == 0)) then
			-- set impulse down signal off
			Signals[Directions.Down].Impulse.Candle = 0

			-- set chart label
			if (Labels[Prices.Name][index_candle-1] ~= nil) then
				DelLabel(ChartTags.Price, Labels[Prices.Name][index_candle-1])
			end
			Labels[Prices.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (Prices.High[index_candle-1]+5*ChartSteps.Price*SecInfo.min_price_step), ChartTags.Price, "SImpulse|End|"..tostring(Signals[Directions.Down].Impulse.Count).."|"..(index_candle-1), ChartLabelIcons.BigCross, SignalLevels.Impulse)
		end
	end
	--#endregion

	----------------------------------------------------------------------------
	--	V. Enter Complex Signals
	----------------------------------------------------------------------------
	--
	--#region	V.1. Enter Signal: Signals[Directions.Down/Up].TrendOn
	--				Depends on signal: Signals[Directions.Up].Trend, Signals[Directions.Up].Impulse, Signals[Directions.Up].RSIs.TrendOn
	--				Terminates by signals: breaking one signals: Signals[Directions.Up].Trend, Signals[Directions.Up].Impulse, Signals[Directions.Up].RSIs.TrendOn
	--				Terminates by duration: Signals.Params.Durations.Enter
	--
	-- check start enter up signal
	--
	if (Signals[Directions.Up].TrendOn.Candle == 0) then
		-- check trend up and impulse up signals and check elementary up signals
		if ((Signals[Directions.Up].Trend.Candle > 0) and (Signals[Directions.Up].Impulse.Candle > 0) and (Signals[Directions.Up].RSIs.TrendOn.Candle > 0)) then
			-- set enter down signal off
			Signals[Directions.Down].TrendOn.Candle = 0
			-- set enter up signals on
			Signals[Directions.Up].TrendOn.Candle = index_candle - 1
			Signals[Directions.Up].TrendOn.Count = Signals[Directions.Up].TrendOn.Count + 1
			-- set enter down signal off
			Signals[Directions.Down].Enter.Candle = 0
			-- set enter down signal on
			Signals[Directions.Up].Enter.Count = Signals[Directions.Up].Enter.Count + 1
			Signals[Directions.Up].Enter.Candle = index_candle - 1

			-- set chart label
			if (Labels[Prices.Name][index_candle-1] ~= nil) then
				DelLabel(ChartTags.Price, Labels[Prices.Name][index_candle-1])
			end
			Labels[Prices.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (Prices.Low[index_candle-1]-6*ChartSteps.Price*SecInfo.min_price_step), ChartTags.Price, "LTrendOn|Start|"..tostring(Signals[Directions.Up].TrendOn.Count).."|"..(index_candle-1), ChartLabelIcons.BigPoint, SignalLevels.Enter)
		end
	end

	-- check presence enter up signal
	if (Signals[Directions.Up].TrendOn.Candle > 0) then
		-- set duration enter up signal
		local duration = index_candle - Signals[Directions.Up].TrendOn.Candle
		-- check continuation enter up signal
		if (duration <= Signals.Params.Durations.Enter) then
			-- check termination by breaking one elementary and complex signals
			if ((Signals[Directions.Up].Trend.Candle == 0) or (Signals[Directions.Up].Impulse.Candle == 0) or (Signals[Directions.Up].RSIs.TrendOn.Candle == 0)) then
				-- set enter up signals off
				Signals[Directions.Up].TrendOn.Candle = 0
				Signals[Directions.Up].Enter.Candle = 0

				-- set chart label
				if (Labels[Prices.Name][index_candle-1] ~= nil) then
					DelLabel(ChartTags.Price, Labels[Prices.Name][index_candle-1])
				end
				Labels[Prices.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (Prices.Low[index_candle-1]-6*ChartSteps.Price*SecInfo.min_price_step), ChartTags.Price, "LTrendOff|End|"..tostring(Signals[Directions.Up].TrendOn.Count).."|"..(duration-1).."|"..(index_candle-1), ChartLabelIcons.BigCross, SignalLevels.Enter)
			-- process continuation elementary up signal
			else
				-- set chart label
				-- if (Labels[Prices.Name][index_candle] ~= nil) then
				-- 	DelLabel(ChartTags.Price, Labels[Prices.Name][index_candle1])
				-- end
				--Labels[Prices.Name][index_candle] = SetChartLabel(T(index_candle), (Prices.Low[index_candle]-6*ChartSteps.Price*SecInfo.min_price_step), ChartTags.Price, "LTrendOn|Continue|"..tostring(Signals[Directions.Up].TrendOn.Count).."|"..duration.."|"..index_candle, ChartLabelIcons.BigPoint, SignalLevels.Enter)

			end
		-- check termination by duration enter up signal
		elseif (duration > Signals.Params.Durations.Enter) then
			-- set enter up signals off
			Signals[Directions.Up].TrendOn.Candle = 0
			Signals[Directions.Up].Enter.Candle = 0

			-- set chart label
			if (Labels[Prices.Name][index_candle] ~= nil) then
				DelLabel(ChartTags.Price, Labels[Prices.Name][index_candle])
			end
			Labels[Prices.Name][index_candle] = SetChartLabel(T(index_candle), (Prices.Low[index_candle]-6*ChartSteps.Price*SecInfo.min_price_step), ChartTags.Price, "LTrendOn|End|"..tostring(Signals[Directions.Up].TrendOn.Count).."|"..duration.."|"..index_candle, ChartLabelIcons.BigCross, SignalLevels.Enter)
		end
	end

	--
	-- check start enter down signal 
	--
	if (Signals[Directions.Down].TrendOn.Candle == 0) then
		-- check trend and impulse down signals and check elementary down signals
		if ((Signals[Directions.Down].Trend.Candle > 0) and (Signals[Directions.Down].Impulse.Candle > 0) and (Signals[Directions.Down].RSIs.TrendOn.Candle > 0)) then
			-- set enter up signal off
			Signals[Directions.Up].TrendOn.Candle = 0
			-- set enter down signals on
			Signals[Directions.Down].TrendOn.Candle = index_candle - 1
			Signals[Directions.Down].TrendOn.Count = Signals[Directions.Down].TrendOn.Count + 1
			-- set enter up signal off
			Signals[Directions.Up].Enter.Candle = 0
			-- set enter down signal on
			Signals[Directions.Down].Enter.Count = Signals[Directions.Down].Enter.Count + 1
			Signals[Directions.Down].Enter.Candle = index_candle - 1

			-- set chart label
			if (Labels[Prices.Name][index_candle-1] ~= nil) then
				DelLabel(ChartTags.Price, Labels[Prices.Name][index_candle-1])
			end
			Labels[Prices.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (Prices.High[index_candle-1]+6*ChartSteps.Price*SecInfo.min_price_step), ChartTags.Price, "STrendOn|Start|"..tostring(Signals[Directions.Down].TrendOn.Count).."|"..(index_candle-1), ChartLabelIcons.BigPoint, SignalLevels.Enter)
		end
	end

	-- check presence enter up signal
	if (Signals[Directions.Down].TrendOn.Candle > 0) then
		-- set enter down signal duration
		local duration = index_candle - Signals[Directions.Down].TrendOn.Candle
		-- check continuation enter down signal
		if (duration <= Signals.Params.Durations.Enter) then
			-- check termination breaking one elementary and complex signals
			if ((Signals[Directions.Down].Trend.Candle == 0) or (Signals[Directions.Down].Impulse.Candle == 0) or (Signals[Directions.Down].RSIs.TrendOn.Candle == 0)) then
				-- set enter down signals off
				Signals[Directions.Down].TrendOn.Candle = 0
				Signals[Directions.Down].Enter.Candle = 0

				-- set chart label
				if (Labels[Prices.Name][index_candle-1] ~= nil) then
					DelLabel(ChartTags.Price, Labels[Prices.Name][index_candle-1])
				end
				Labels[Prices.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (Prices.High[index_candle-1]+6*ChartSteps.Price*SecInfo.min_price_step), ChartTags.Price, "STrendOff|End|"..tostring(Signals[Directions.Down].TrendOn.Count).."|"..(duration-1).."|"..(index_candle-1), ChartLabelIcons.BigCross, SignalLevels.Enter)
			-- process continuation elementary down signal
			else
				-- set chart label
				-- if (Labels[Prices.Name][index_candle] ~= nil) then
				-- 	DelLabel(ChartTags.Price, Labels[Prices.Name][index_candle])
				-- end
				--Labels[Prices.Name][index_candle] = SetChartLabel(T(index_candle), (Prices.High[index_candle]+6*ChartSteps.Price*SecInfo.min_price_step), ChartTags.Price, "STrendOn|Continue|"..tostring(Signals[Directions.Down].TrendOn.Count).."|"..duration.."|" ..index_candle, ChartLabelIcons.BigPoint, SignalLevels.Enter)

			end
		-- check termination by duration enter down signal
		elseif (duration > Signals.Params.Durations.Enter) then
			-- set enter down signals off
			Signals[Directions.Down].TrendOn.Candle = 0
			Signals[Directions.Down].Enter.Candle = 0

			-- set chart label
			if (Labels[Prices.Name][index_candle] ~= nil) then
				DelLabel(ChartTags.Price, Labels[Prices.Name][index_candle])
			end
			Labels[Prices.Name][index_candle] = SetChartLabel(T(index_candle), (Prices.High[index_candle]+6*ChartSteps.Price*SecInfo.min_price_step), ChartTags.Price, "STrendOn|End|"..tostring(Signals[Directions.Down].TrendOn.Count).."|"..duration.."|"..index_candle, ChartLabelIcons.BigCross, SignalLevels.Enter)
		end
	end
	--#endregion

	--
	--#region	V.2. Enter Signal: Signals[Directions.Down/Up].Uturn
	--				Depends on signal: Signals[Directions.Up].Trend, Signals[Directions.Up].Impulse, Prices.Uturn3, Prices.Uturn4, RSIs.Uturn3, RSIs.Uturn4, Stochs.Uturn3, Stochs.Uturn4
	--				Terminates by signals: breaking one signals: Signals[Directions.Up].Trend, Signals[Directions.Up].Impulse, Prices.Uturn3, Prices.Uturn4, RSIs.Uturn3, RSIs.Uturn4, Stochs.Uturn3, Stochs.Uturn4
	--				Terminates by duration: Signals.Params.Durations.Enter
	--
	---- check start enter up signal
	--
	if (Signals[Directions.Up].Uturn.Candle == 0) then
		-- check trend up and impulse up signals 
		if (((Signals[Directions.Up].Trend.Candle > 0) and (Signals[Directions.Up].Impulse.Candle > 0)) and
		-- check elementary up signals
		(((Signals[Directions.Up].Prices.Uturn3.Candle > 0) or (Signals[Directions.Up].Prices.Uturn4.Candle > 0)) and
		((Signals[Directions.Up].RSIs.Uturn3.Candle > 0) or (Signals[Directions.Up].RSIs.Uturn4.Candle > 0)) and
		((Signals[Directions.Up].Stochs.Uturn3.Candle > 0) or (Signals[Directions.Up].Stochs.Uturn4.Candle > 0))) and
		-- check rsi uturn up in trend zone
		IsRelate(RSIs.Slow[index_candle-1], RSIs.Params.Levels.TopTrend, Directions.Up)) then
			-- set enter down signal off
			Signals[Directions.Down].Uturn.Candle = 0
			-- set enter up signals on
			Signals[Directions.Up].Uturn.Candle = index_candle - 1
			Signals[Directions.Up].Uturn.Count = Signals[Directions.Up].Uturn.Count + 1
			-- set enter up signal off
			Signals[Directions.Down].Enter.Candle = 0
			-- set enter down signal on
			Signals[Directions.Up].Enter.Count = Signals[Directions.Up].Enter.Count + 1
			Signals[Directions.Up].Enter.Candle = index_candle - 1

			-- set chart label
			if (Labels[Prices.Name][index_candle-1] ~= nil) then
				DelLabel(ChartTags.Price, Labels[Prices.Name][index_candle-1])
			end
			Labels[Prices.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (Prices.Low[index_candle-1]-7*ChartSteps.Price*SecInfo.min_price_step), ChartTags.Price, "LUturn|Start|"..tostring(Signals[Directions.Up].Uturn.Count).."|"..(index_candle-1), ChartLabelIcons.BigRomb, SignalLevels.Enter)
		end
	end

	-- check presence enter up signal
	if (Signals[Directions.Up].Uturn.Candle > 0) then
		-- set duration enter up signal
		local duration = index_candle - Signals[Directions.Up].Uturn.Candle
		-- check continuation enter up signal
		if (duration <= Signals.Params.Durations.Enter) then
			-- check temination by breaking one elementary and complex signals
			if (((Signals[Directions.Up].Prices.Uturn3.Candle == 0) and (Signals[Directions.Up].Prices.Uturn4.Candle == 0)) or
			((Signals[Directions.Up].RSIs.Uturn3.Candle == 0) and (Signals[Directions.Up].RSIs.Uturn4.Candle == 0)) or
			((Signals[Directions.Up].Stochs.Uturn3.Candle == 0) and (Signals[Directions.Up].Stochs.Uturn4.Candle == 0)) or
			-- check rsi uturn up off trend zone
			IsRelate(RSIs.Slow[index_candle-1], RSIs.Params.Levels.TopTrend, Directions.Down) or
			--check off trend and impluse signals
			(Signals[Directions.Up].Trend.Candle == 0) or (Signals[Directions.Up].Impulse.Candle == 0)) then
				-- set enter up signals off
				Signals[Directions.Up].Uturn.Candle = 0
				Signals[Directions.Up].Enter.Candle = 0

				-- set chart label
				if (Labels[Prices.Name][index_candle-1] ~= nil) then
					DelLabel(ChartTags.Price, Labels[Prices.Name][index_candle-1])
				end
				Labels[Prices.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (Prices.Low[index_candle-1]-7*ChartSteps.Price*SecInfo.min_price_step), ChartTags.Price, "LUturnOff|End|"..tostring(Signals[Directions.Up].Uturn.Count).."|"..(duration-1).."|"..(index_candle-1), ChartLabelIcons.BigCross, SignalLevels.Enter)
			-- process continuation elementary up signal
			else
				-- set chart label
				-- if (Labels[Prices.Name][index_candle] ~= nil) then
				-- 	DelLabel(ChartTags.Price, Labels[Prices.Name][index_candle])
				-- end
				--Labels[Prices.Name][index_candle] = SetChartLabel(T(index_candle), (Prices.Low[index_candle]-7*ChartSteps.Price*SecInfo.min_price_step), ChartTags.Price, "LUturn|Continue|"..tostring(Signals[Directions.Up].Uturn.Count).."|"..duration.."|"..index_candle, ChartLabelIcons.BigRomb, SignalLevels.Enter)

			end
		-- check termination by duration enter up signal
		elseif (duration > Signals.Params.Durations.Enter) then
			-- set enter up signals off
			Signals[Directions.Up].Uturn.Candle = 0
			Signals[Directions.Up].Enter.Candle = 0

			-- set chart label
			if (Labels[Prices.Name][index_candle] ~= nil) then
				DelLabel(ChartTags.Price, Labels[Prices.Name][index_candle])
			end
			Labels[Prices.Name][index_candle] = SetChartLabel(T(index_candle), (Prices.Low[index_candle]-7*ChartSteps.Price*SecInfo.min_price_step), ChartTags.Price, "LUturn|End|"..tostring(Signals[Directions.Up].Uturn.Count).."|"..duration.."|"..(index_candle), ChartLabelIcons.BigCross, SignalLevels.Enter)
		end
	end

	--
	-- check start enter down signal
	--
	if (Signals[Directions.Down].Uturn.Candle == 0) then
		-- check trend and impulse down signals
		if (((Signals[Directions.Down].Trend.Candle > 0) and (Signals[Directions.Down].Impulse.Candle > 0)) and
		-- check elementary down signals
		(((Signals[Directions.Down].Prices.Uturn3.Candle > 0) or (Signals[Directions.Down].Prices.Uturn4.Candle > 0)) and
		((Signals[Directions.Down].RSIs.Uturn3.Candle > 0) or (Signals[Directions.Down].RSIs.Uturn4.Candle > 0)) and
		((Signals[Directions.Down].Stochs.Uturn3.Candle > 0) or (Signals[Directions.Down].Stochs.Uturn4.Candle > 0))) and
		-- check rsi uturn down in trend zone
		IsRelate(RSIs.Slow[index_candle-1], RSIs.Params.Levels.BottomTrend, Directions.Down)) then
			-- set enter up signal off
			Signals[Directions.Up].Uturn.Candle = 0
			-- set enter up signals on
			Signals[Directions.Down].Uturn.Candle = index_candle - 1
			Signals[Directions.Down].Uturn.Count = Signals[Directions.Down].Uturn.Count + 1
			-- set enter up signal off
			Signals[Directions.Up].Enter.Candle = 0
			-- set enter down signal on
			Signals[Directions.Down].Enter.Count = Signals[Directions.Down].Enter.Count + 1
			Signals[Directions.Down].Enter.Candle = index_candle - 1

			-- set chart label
			if (Labels[Prices.Name][index_candle-1] ~= nil) then
				DelLabel(ChartTags.Price, Labels[Prices.Name][index_candle-1])
			end
			Labels[Prices.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (Prices.High[index_candle-1]+7*ChartSteps.Price*SecInfo.min_price_step), ChartTags.Price, "SUturn|Start|"..tostring(Signals[Directions.Down].Uturn.Count).."|"..(index_candle-1), ChartLabelIcons.BigRomb, SignalLevels.Enter)
		end
	end

	-- check presence enter down signal
	if (Signals[Directions.Down].Uturn.Candle > 0) then
		-- set duration enter up signal
		local duration = index_candle - Signals[Directions.Down].Uturn.Candle
		-- check continuation enter up signal
		if (duration <= Signals.Params.Durations.Enter) then
			-- check termination by breaking one elementary and complex signals
			if (((Signals[Directions.Down].Prices.Uturn3.Candle == 0) and (Signals[Directions.Down].Prices.Uturn4.Candle == 0)) or
			((Signals[Directions.Down].RSIs.Uturn3.Candle == 0) and (Signals[Directions.Down].RSIs.Uturn4.Candle == 0)) or
			((Signals[Directions.Down].Stochs.Uturn3.Candle == 0) and (Signals[Directions.Down].Stochs.Uturn4.Candle == 0)) or
			-- check rsi uturn down off trend zone
			IsRelate(RSIs.Slow[index_candle-1], RSIs.Params.Levels.BottomTrend, Directions.Up) or
			--check off trend and impulse signals
			(Signals[Directions.Down].Trend.Candle == 0) or (Signals[Directions.Down].Impulse.Candle == 0)) then
				-- set enter down signals off
				Signals[Directions.Down].Uturn.Candle = 0
				Signals[Directions.Down].Enter.Candle = 0

				-- set chart label
				if (Labels[Prices.Name][index_candle-1] ~= nil) then
					DelLabel(ChartTags.Price, Labels[Prices.Name][index_candle-1])
				end
				Labels[Prices.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (Prices.High[index_candle-1]+7*ChartSteps.Price*SecInfo.min_price_step), ChartTags.Price, "SUturnOff|End|"..tostring(Signals[Directions.Down].Uturn.Count).."|"..(duration-1).."|"..(index_candle-1), ChartLabelIcons.BigCross, SignalLevels.Enter)
			-- process continuation elementary up signal
			else
				-- set chart label
				-- if (Labels[Prices.Name][index_candle] ~= nil) then
				-- 	DelLabel(ChartTags.Price, Labels[Prices.Name][index_candle])
				-- end
				--Labels[Prices.Name][index_candle] = SetChartLabel(T(index_candle), (Prices.High[index_candle]+7*ChartSteps.Price*SecInfo.min_price_step), ChartTags.Price, "SUturn|Continue|"..tostring(Signals[Directions.Down].Uturn.Count).."|"..duration.."|"..index_candle, ChartLabelIcons.BigRomb, SignalLevels.Enter)
			end
		-- check termination by duration enter up signal
		elseif (duration > Signals.Params.Durations.Enter) then
			-- set enter down signals off
			Signals[Directions.Down].Uturn.Candle = 0
			Signals[Directions.Down].Enter.Candle = 0

			-- set chart label
			if (Labels[Prices.Name][index_candle] ~= nil) then
				DelLabel(ChartTags.Price, Labels[Prices.Name][index_candle])
			end
			Labels[Prices.Name][index_candle] = SetChartLabel(T(index_candle), (Prices.High[index_candle]+7*ChartSteps.Price*SecInfo.min_price_step), ChartTags.Price, "SUturn|End|"..tostring(Signals[Directions.Down].Uturn.Count).."|"..duration.."|"..index_candle, ChartLabelIcons.BigCross, SignalLevels.Enter)
		end
	end
	--#endregion

	--
	--#region	V.3. Enter Signal: Signals[Directions.Down/Up].Spring1
	--				Depends on signal: Signals[Directions.Up].Trend, Signals[Directions.Up].Impulse, Prices.Uturn3, Prices.Uturn4, RSIs.Uturn3, RSIs.Uturn4, Stochs.Spring3, Stochs.Spring4
	--				Terminates by signals: breaking one signals: Signals[Directions.Up].Trend, Signals[Directions.Up].Impulse, Prices.Uturn3, Prices.Uturn4, RSIs.Uturn3, RSIs.Uturn4, Stochs.Spring3, Stochs.Spring4
	--				Terminates by duration: Signals.Params.Durations.Enter
	--
	-- check enter up signal start
	--
	if (Signals[Directions.Up].Spring1.Candle == 0) then
		-- check trend and impulse up signals
		if (((Signals[Directions.Up].Trend.Candle > 0) and (Signals[Directions.Up].Impulse.Candle > 0)) and
		-- check elementary up signals
		(((Signals[Directions.Up].Prices.Uturn3.Candle > 0) or (Signals[Directions.Up].Prices.Uturn4.Candle > 0)) and
		((Signals[Directions.Up].RSIs.Uturn3.Candle > 0) or (Signals[Directions.Up].RSIs.Uturn4.Candle > 0)) and
		((Signals[Directions.Up].Stochs.Spring3.Candle > 0) or (Signals[Directions.Up].Stochs.Spring4.Candle > 0))) and
		-- check rsi uturn up in trend zone
		IsRelate(RSIs.Slow[index_candle-1], RSIs.Params.Levels.TopTrend, Directions.Up)) then
			-- set enter down signal off
			Signals[Directions.Down].Spring1.Candle = 0
			-- set enter up signals on
			Signals[Directions.Up].Spring1.Candle = index_candle - 1
			Signals[Directions.Up].Spring1.Count = Signals[Directions.Up].Spring1.Count + 1
			-- set enter up signal off
			Signals[Directions.Down].Enter.Candle = 0
			-- set enter down signal on
			Signals[Directions.Up].Enter.Count = Signals[Directions.Up].Enter.Count + 1
			Signals[Directions.Up].Enter.Candle = index_candle - 1

			-- set chart label
			if (Labels[Prices.Name][index_candle-1] ~= nil) then
				DelLabel(ChartTags.Price, Labels[Prices.Name][index_candle-1])
			end
			Labels[Prices.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (Prices.Low[index_candle-1]-8*ChartSteps.Price*SecInfo.min_price_step), ChartTags.Price, "LSpring1|Start|"..tostring(Signals[Directions.Up].Spring1.Count).."|"..(index_candle-1), ChartLabelIcons.BigPlus, SignalLevels.Enter)
		end
	end

	-- check presence enter up signals
	if (Signals[Directions.Up].Spring1.Candle > 0) then
		-- set duration enter up signal
		local duration = index_candle - Signals[Directions.Up].Spring1.Candle
		-- check continuation enter up signal
		if (duration <= Signals.Params.Durations.Enter) then
			-- check termination by breaking one elementary and complex signals
			if (((Signals[Directions.Up].Prices.Uturn3.Candle == 0) and (Signals[Directions.Up].Prices.Uturn4.Candle == 0)) or
			((Signals[Directions.Up].RSIs.Uturn3.Candle == 0) and (Signals[Directions.Up].RSIs.Uturn4.Candle == 0)) or
			((Signals[Directions.Up].Stochs.Spring3.Candle == 0) and (Signals[Directions.Up].Stochs.Spring4.Candle == 0)) or
			-- check rsi uturn up off trend zone
			IsRelate(RSIs.Slow[index_candle-1], RSIs.Params.Levels.TopTrend, Directions.Down) or
			--check off trend and impulse signals
			(Signals[Directions.Up].Trend.Candle == 0) or (Signals[Directions.Up].Impulse.Candle == 0)) then
				-- set enter up signals off
				Signals[Directions.Up].Spring1.Candle = 0
				Signals[Directions.Up].Enter.Candle = 0

				-- set chart label
				if (Labels[Prices.Name][index_candle-1] ~= nil) then
					DelLabel(ChartTags.Price, Labels[Prices.Name][index_candle-1])
				end
				Labels[Prices.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (Prices.Low[index_candle-1]-8*ChartSteps.Price*SecInfo.min_price_step), ChartTags.Price, "LSpring1Off|End|" .. tostring(Signals[Directions.Up].Spring1.Count).."|"..(duration-1).."|"..(index_candle-1), ChartLabelIcons.BigCross, SignalLevels.Enter)
			-- process continuation elementary up signal
			else
				-- set chart label
				-- if (Labels[Prices.Name][index_candle] ~= nil) then
				-- 	DelLabel(ChartTags.Price, Labels[Prices.Name][index_candle])
				-- end
				--Labels[Prices.Name][index_candle] = SetChartLabel(T(index_candle), (Prices.Low[index_candle]-8*ChartSteps.Price*SecInfo.min_price_step), ChartTags.Price, "LSpring1|Continue|"..tostring(Signals[Directions.Up].Spring1.Count).."|"..duration.."|"..index_candle, ChartLabelIcons.BigPlus, SignalLevels.Enter)
			end
		-- check termination by duration enter up signal
		elseif (duration > Signals.Params.Durations.Enter) then
			-- set enter up signals off
			Signals[Directions.Up].Spring1.Candle = 0
			Signals[Directions.Up].Enter.Candle = 0

			if (Labels[Prices.Name][index_candle] ~= nil) then
				DelLabel(ChartTags.Price, Labels[Prices.Name][index_candle])
			end
			Labels[Prices.Name][index_candle] = SetChartLabel(T(index_candle), (Prices.Low[index_candle]-8*ChartSteps.Price*SecInfo.min_price_step), ChartTags.Price, "LSpring1|End|"..tostring(Signals[Directions.Up].Spring1.Count).."|"..duration.."|"..index_candle, ChartLabelIcons.BigCross, SignalLevels.Enter)
		end
	end

	--
	-- check start enter down signal
	--
	if (Signals[Directions.Down].Spring1.Candle == 0) then
		-- check trend and impulse down signals
		if (((Signals[Directions.Down].Trend.Candle > 0) and (Signals[Directions.Down].Impulse.Candle > 0)) and
		-- check elementary down signals
		(((Signals[Directions.Down].Prices.Uturn3.Candle > 0) or (Signals[Directions.Down].Prices.Uturn4.Candle > 0)) and
		((Signals[Directions.Down].RSIs.Uturn3.Candle > 0) or (Signals[Directions.Down].RSIs.Uturn4.Candle > 0)) and
		((Signals[Directions.Down].Stochs.Spring3.Candle > 0) or (Signals[Directions.Down].Stochs.Spring4.Candle > 0))) and
		-- check rsi uturn down in trend zone
		IsRelate(RSIs.Slow[index_candle-1], RSIs.Params.Levels.BottomTrend, Directions.Down)) then
			-- set enter up signal off
			Signals[Directions.Up].Spring1.Candle = 0
			-- set enter up signal on
			Signals[Directions.Down].Spring1.Candle = index_candle - 1
			Signals[Directions.Down].Spring1.Count = Signals[Directions.Down].Spring1.Count + 1
			-- set enter up signal off
			Signals[Directions.Up].Enter.Candle = 0
			-- set enter down signal on
			Signals[Directions.Down].Enter.Count = Signals[Directions.Down].Enter.Count + 1
			Signals[Directions.Down].Enter.Candle = index_candle - 1

			-- set chart label
			if (Labels[Prices.Name][index_candle-1] ~= nil) then
				DelLabel(ChartTags.Price, Labels[Prices.Name][index_candle-1])
			end
			Labels[Prices.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (Prices.High[index_candle-1]+8*ChartSteps.Price*SecInfo.min_price_step), ChartTags.Price, "SSpring1|Start|"..tostring(Signals[Directions.Down].Spring1.Count).."|"..(index_candle-1), ChartLabelIcons.BigPlus, SignalLevels.Enter)
		end
	end

	-- check presence enter down signals
	if (Signals[Directions.Down].Spring1.Candle > 0) then
		-- set duration enter up signal
		local duration = index_candle - Signals[Directions.Down].Spring1.Candle
		-- check continuation enter down signal
		if (duration <= Signals.Params.Durations.Enter) then
			-- check termination bt breaking one elementary and complex signals
			if (((Signals[Directions.Down].Prices.Uturn3.Candle == 0) and (Signals[Directions.Down].Prices.Uturn4.Candle == 0)) or
			((Signals[Directions.Down].RSIs.Uturn3.Candle == 0) and (Signals[Directions.Down].RSIs.Uturn4.Candle == 0)) or
			((Signals[Directions.Down].Stochs.Spring3.Candle == 0) and (Signals[Directions.Down].Stochs.Spring4.Candle == 0)) or
			-- check rsi uturn down off trend zone
			IsRelate(RSIs.Slow[index_candle-1], RSIs.Params.Levels.BottomTrend, Directions.Up) or
			--check off trend and impulse signals
			(Signals[Directions.Down].Trend.Candle == 0) or (Signals[Directions.Down].Impulse.Candle == 0)) then
				-- set enter up signals off
				Signals[Directions.Down].Spring1.Candle = 0
				Signals[Directions.Down].Enter.Candle = 0

				-- set chart label
				if (Labels[Prices.Name][index_candle-1] ~= nil) then
					DelLabel(ChartTags.Price, Labels[Prices.Name][index_candle-1])
				end
				Labels[Prices.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (Prices.High[index_candle-1]+8*ChartSteps.Price*SecInfo.min_price_step), ChartTags.Price, "SSpring1Off|End|"..tostring(Signals[Directions.Down].Spring1.Count).."|"..(duration-1).."|"..(index_candle-1), ChartLabelIcons.BigCross, SignalLevels.Enter)
			-- process continuation elementary up signal
			else
				-- set chart label
				-- if (Labels[Prices.Name][index_candle] ~= nil) then
				-- 	DelLabel(ChartTags.Price, Labels[Prices.Name][index_candle])
				-- end
				--Labels[Prices.Name][index_candle] = SetChartLabel(T(index_candle), (Prices.High[index_candle]+8*ChartSteps.Price*SecInfo.min_price_step), ChartTags.Price, "SSpring1|Continue|"..tostring(Signals[Directions.Down].Spring1.Count).."|"..duration.."|"..index_candle, ChartLabelIcons.BigPlus, SignalLevels.Enter)
			end
		-- check termination by duration enter down signal
		elseif (duration > Signals.Params.Durations.Enter) then
			-- set enter down signals off
			Signals[Directions.Down].Spring1.Candle = 0
			Signals[Directions.Down].Enter.Candle = 0

			-- set chart label
			if (Labels[Prices.Name][index_candle] ~= nil) then
				DelLabel(ChartTags.Price, Labels[Prices.Name][index_candle])
			end
			Labels[Prices.Name][index_candle] = SetChartLabel(T(index_candle), (Prices.High[index_candle]+8*ChartSteps.Price*SecInfo.min_price_step), ChartTags.Price, "SSpring1|End|" .. tostring(Signals[Directions.Down].Spring1.Count).."|"..duration.."|"..index_candle, ChartLabelIcons.BigCross, SignalLevels.Enter)
		end
	end
	--#endregion

	--
	--#region	V.4. Enter Signal: Signals[Directions.Down/Up].Spring2
		--				Depends on signal: Signals[Directions.Up].Trend, Signals[Directions.Up].Impulse, Prices.Uturn3, Prices.Uturn4, RSIs.Spring3, RSIs.Spring4, Stochs.Spring3, Stochs.Spring4
	--				Terminates by signals: breaking one signals: Signals[Directions.Up].Trend, Signals[Directions.Up].Impulse, Prices.Uturn3, Prices.Uturn4, RSIs.Spring3, RSIs.Spring4, Stochs.Spring3, Stochs.Spring4
	--				Terminates by duration: Signals.Params.Durations.Enter
	--
	-- check start enter up signal
	--
	if (Signals[Directions.Up].Spring2.Candle == 0) then
		-- check trend and impulse up signals
		if (((Signals[Directions.Up].Trend.Candle > 0) and (Signals[Directions.Up].Impulse.Candle > 0)) and
		-- check elementary up signals
		(((Signals[Directions.Up].Prices.Uturn3.Candle > 0) or (Signals[Directions.Up].Prices.Uturn4.Candle > 0)) and
		((Signals[Directions.Up].RSIs.Spring3.Candle > 0) or (Signals[Directions.Up].RSIs.Spring4.Candle > 0)) and
		((Signals[Directions.Up].Stochs.Spring3.Candle > 0) or (Signals[Directions.Up].Stochs.Spring4.Candle > 0))) and
		-- check rsi uturn up in trend zone
		IsRelate(RSIs.Slow[index_candle-1], RSIs.Params.Levels.TopTrend, Directions.Up)) then
			-- set enter down signal off
			Signals[Directions.Down].Spring2.Candle = 0
			-- set enter up signals on
			Signals[Directions.Up].Spring2.Candle = index_candle - 1
			Signals[Directions.Up].Spring2.Count = Signals[Directions.Up].Spring2.Count + 1
			-- set enter up signal off
			Signals[Directions.Down].Enter.Candle = 0
			-- set enter down signal on
			Signals[Directions.Up].Enter.Count = Signals[Directions.Up].Enter.Count + 1
			Signals[Directions.Up].Enter.Candle = index_candle - 1

			-- set chart label
			if (Labels[Prices.Name][index_candle-1] ~= nil) then
				DelLabel(ChartTags.Price, Labels[Prices.Name][index_candle-1])
			end
			Labels[Prices.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (Prices.Low[index_candle-1]-9*ChartSteps.Price*SecInfo.min_price_step), ChartTags.Price, "LSpring2|Start|"..tostring(Signals[Directions.Up].Spring2.Count).."|"..(index_candle-1), ChartLabelIcons.BigFlash, SignalLevels.Enter)
		end
	end

	-- check presence enter up signals
	if (Signals[Directions.Down].Spring2.Candle > 0) then
		-- set enter up signal duration
		local duration = index_candle - Signals[Directions.Down].Spring2.Candle
		-- check continuation enter up signal
		if (duration <= Signals.Params.Durations.Enter) then
			-- check termination by breaking one elementary and complex signals
			if (((Signals[Directions.Up].Prices.Uturn3.Candle == 0) and (Signals[Directions.Up].Prices.Uturn4.Candle == 0)) or
			((Signals[Directions.Up].RSIs.Spring3.Candle == 0) and (Signals[Directions.Up].RSIs.Spring4.Candle == 0)) or
			((Signals[Directions.Up].Stochs.Spring3.Candle == 0) and (Signals[Directions.Up].Stochs.Spring4.Candle == 0)) or
			-- check rsi uturn up off trend zone
			IsRelate(RSIs.Slow[index_candle-1], RSIs.Params.Levels.TopTrend, Directions.Down)
			--check off trend and impulse signals
			(Signals[Directions.Up].Trend.Candle == 0) or (Signals[Directions.Up].Impulse.Candle == 0)) then
				-- set enter up signals off
				Signals[Directions.Up].Spring1.Candle = 0
				Signals[Directions.Up].Enter.Candle = 0

				-- set chart label
				if (Labels[Prices.Name][index_candle-1] ~= nil) then
					DelLabel(ChartTags.Price, Labels[Prices.Name][index_candle-1])
				end
				Labels[Prices.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (Prices.Low[index_candle-1]-9*ChartSteps.Price*SecInfo.min_price_step), ChartTags.Price, "LSpring2Off|End|"..tostring(Signals[Directions.Up].Spring2.Count).."|"..(duration-1).."|"..(index_candle-1), ChartLabelIcons.BigCross, SignalLevels.Enter)
			-- process continuation elementary up signal
			else
				-- set chart label
				-- if (Labels[Prices.Name][index_candle] ~= nil) then
				-- 	DelLabel(ChartTags.Price, Labels[Prices.Name][index_candle])
				-- end
				--Labels[Prices.Name][index_candle] = SetChartLabel(T(index_candle), (Prices.Low[index_candle]-9*ChartSteps.Price*SecInfo.min_price_step), ChartTags.Price, "LSpring2|Continue|"..tostring(Signals[Directions.Up].Spring2.Count).."|"..duration.."|"..index_candle, ChartLabelIcons.BigFlash, SignalLevels.Enter)
			end
		-- check termination by duration enter up signal
		elseif (duration > Signals.Params.Durations.Enter) then
			-- set enter up signals off
			Signals[Directions.Up].Spring2.Candle = 0
			Signals[Directions.Up].Enter.Candle = 0
		
			if (Labels[Prices.Name][index_candle] ~= nil) then
				DelLabel(ChartTags.Price, Labels[Prices.Name][index_candle])
			end
			Labels[Prices.Name][index_candle] = SetChartLabel(T(index_candle), (Prices.Low[index_candle]-9*ChartSteps.Price*SecInfo.min_price_step), ChartTags.Price, "LSpring2|End|"..tostring(Signals[Directions.Up].Spring2.Count).."|"..duration.."|"..index_candle, ChartLabelIcons.BigCross, SignalLevels.Enter)
		end
	end

	--
	-- check enter down signal start
	--
	if (Signals[Directions.Down].Spring2.Candle == 0) then
		-- check trend and impulse down signal
		if (((Signals[Directions.Down].Trend.Candle > 0) and (Signals[Directions.Down].Impulse.Candle > 0)) and
		-- check elementary down signals
		(((Signals[Directions.Down].Prices.Uturn3.Candle > 0) or (Signals[Directions.Down].Prices.Uturn4.Candle > 0)) and
		((Signals[Directions.Down].RSIs.Spring3.Candle > 0) or (Signals[Directions.Down].RSIs.Spring4.Candle > 0)) and
		((Signals[Directions.Down].Stochs.Spring3.Candle > 0) or (Signals[Directions.Down].Stochs.Spring4.Candle > 0))) and
		-- check rsi uturn down in trend zone
		IsRelate(RSIs.Slow[index_candle-1], RSIs.Params.Levels.BottomTrend, Directions.Down)) then
			-- set enter up signal off
			Signals[Directions.Up].Spring2.Candle = 0
			-- set enter down signals on
			Signals[Directions.Down].Spring2.Candle = index_candle - 1
			Signals[Directions.Down].Spring2.Count = Signals[Directions.Down].Spring2.Count + 1
			-- set enter up signal off
			Signals[Directions.Up].Enter.Candle = 0
			-- set enter down signal on
			Signals[Directions.Down].Enter.Count = Signals[Directions.Down].Enter.Count + 1
			Signals[Directions.Down].Enter.Candle = index_candle - 1

			-- set chart label
			if (Labels[Prices.Name][index_candle-1] ~= nil) then
				DelLabel(ChartTags.Price, Labels[Prices.Name][index_candle-1])
			end
			Labels[Prices.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (Prices.High[index_candle-1]+9*ChartSteps.Price*SecInfo.min_price_step), ChartTags.Price, "SSpring2|Start|"..tostring(Signals[Directions.Down].Spring2.Count).."|"..(index_candle-1), ChartLabelIcons.BigFlash, SignalLevels.Enter)
		end
	end

	-- check presence elementary up signals
	if (Signals[Directions.Down].Spring2.Candle > 0) then
		-- set duration enter up signal
		local duration = index_candle - Signals[Directions.Down].Spring2.Candle
		-- check continuation enter up signal
		if (duration <= Signals.Params.Durations.Enter) then
			-- check breaking one elementary and complex signals
			if (((Signals[Directions.Down].Prices.Uturn3.Candle == 0) and (Signals[Directions.Down].Prices.Uturn4.Candle == 0)) or
			((Signals[Directions.Down].RSIs.Spring3.Candle == 0) and (Signals[Directions.Down].RSIs.Spring4.Candle == 0)) or
			((Signals[Directions.Down].Stochs.Spring3.Candle == 0) and (Signals[Directions.Down].Stochs.Spring4.Candle == 0)) or
			-- check rsi uturn down off trend zone
			IsRelate(RSIs.Slow[index_candle-1], RSIs.Params.Levels.BottomTrend, Directions.Up) or
			--check off trend and impulse signals
			(Signals[Directions.Down].Trend.Candle == 0) or (Signals[Directions.Down].Impulse.Candle == 0)) then
				-- set enter up signals off
				Signals[Directions.Down].Spring1.Candle = 0
				Signals[Directions.Down].Enter.Candle = 0

				-- set chart label
				if (Labels[Prices.Name][index_candle-1] ~= nil) then
					DelLabel(ChartTags.Price, Labels[Prices.Name][index_candle-1])
				end
				Labels[Prices.Name][index_candle-1] = SetChartLabel(T(index_candle-1), (Prices.High[index_candle-1]+9*ChartSteps.Price*SecInfo.min_price_step), ChartTags.Price, "SSpring2Off|End|"..tostring(Signals[Directions.Down].Spring2.Count).."|"..(duration-1).."|"..(index_candle-1), ChartLabelIcons.BigCross, SignalLevels.Enter)
			-- process continuation elementary up signal
			else
				-- set chart label
				-- if (Labels[Prices.Name][index_candle] ~= nil) then
				-- 	DelLabel(ChartTags.Price, Labels[Prices.Name][index_candle])
				-- end
				--Labels[Prices.Name][index_candle] = SetChartLabel(T(index_candle-1), (Prices.High[index_candle-1]+9*ChartSteps.Price*SecInfo.min_price_step), ChartTags.Price, "SSpring2|Continue|"..tostring(Signals[Directions.Down].Spring2.Count).."|"..duration.."|"..index_candle, ChartLabelIcons.BigFlash, SignalLevels.Enter)
				
			end
		-- check termination by duration enter up signal
		elseif (duration > Signals.Params.Durations.Enter) then
			-- set enter down signals off
			Signals[Directions.Down].Spring2.Candle = 0
			Signals[Directions.Down].Enter.Candle = 0

			-- set chart label
			if (Labels[Prices.Name][index_candle] ~= nil) then
				DelLabel(ChartTags.Price, Labels[Prices.Name][index_candle])
			end
			Labels[Prices.Name][index_candle] = SetChartLabel(T(index_candle), (Prices.High[index_candle]+9*ChartSteps.Price*SecInfo.min_price_step), ChartTags.Price, "SSpring2|End|"..tostring(Signals[Directions.Down].Spring2.Count).."|"..index_candle, ChartLabelIcons.BigCross, SignalLevels.Enter)
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
--#region	INDICATOR MA
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
--
-- Signal Osc Uturn with 3 candles
--
function SignalOscUturn3(osc, index, direction)
	-- deltas uturn
	return (SignalUturn(osc.Delta, index, Directions.Up) and
		-- fastosc slowosc uturn
		SignalUturn(osc.Fast, index, direction) and SignalMove(osc.Slow, index, direction) and
		-- fastosc over slowosc on all
		(IsRelate(osc.Fast[index-3], osc.Slow[index-3], direction) and
		IsRelate(osc.Fast[index-2], osc.Slow[index-2], direction) and
		IsRelate(osc.Fast[index-1], osc.Slow[index-1], direction)))
end

--
-- Signal Osc Uturn with 4 candles
--
function SignalOscUturn4(osc, index, direction)
	-- deltas uturn
	return ((SignalMove(osc.Delta, index-2, Directions.Down) and SignalMove(osc.Delta, index, Directions.Up)) and
		-- fastosc slowosc uturn
		(SignalMove(osc.Fast, index-2, Reverse(direction)) and SignalMove(osc.Fast, index, direction) and SignalMove(osc.Slow, index, direction)) and
		-- fasrosc over slowosc on border
		(IsRelate(osc.Fast[index-4], osc.Slow[index-4], direction) and
		IsRelate(osc.Fast[index-3], osc.Slow[index-3], direction) and
		IsRelate(osc.Fast[index-2], osc.Slow[index-2], direction) and
		IsRelate(osc.Fast[index-1], osc.Slow[index-1], direction)))
end

--
-- Signal Osc Spring with 3 candles
--
function SignalOscSpring3(osc, index, direction)
	-- deltas move
	return (SignalMove(osc.Delta, index, Directions.Up) and
		-- fastosc and slowosc uturn
		(SignalUturn(osc.Fast, index, direction) and SignalMove(osc.Slow, index, direction)) and
		-- fasrosc over slowosc on border
		(IsRelate(osc.Fast[index-3], osc.Slow[index-3], direction) and
		IsRelate(osc.Slow[index-2], osc.Fast[index-2], direction) and
		IsRelate(osc.Fast[index-1], osc.Slow[index-1], direction)))
end

--
-- Signal Osc Spring with 4 candles
--
function SignalOscSpring4(osc, index, direction)
	-- fastosc and slowosc uturn
	return ((SignalMove(osc.Fast, index-2, Reverse(direction)) and SignalMove(osc.Fast, index, direction) and SignalMove(osc.Slow, index, direction)) and
		-- fastosc over slowosc on all
		(IsRelate(osc.Fast[index-4], osc.Slow[index-4], direction) and
		IsRelate(osc.Slow[index-3], osc.Fast[index-3], direction) and
		IsRelate(osc.Slow[index-2], osc.Fast[index-2], direction) and
		IsRelate(osc.Fast[index-1], osc.Slow[index-1], direction)) or

		(IsRelate(osc.Fast[index-4], osc.Slow[index-4], direction) and
		IsRelate(osc.Fast[index-3], osc.Slow[index-3], direction) and
		IsRelate(osc.Slow[index-2], osc.Fast[index-2], direction) and
		IsRelate(osc.Fast[index-1], osc.Slow[index-1], direction)) or

		IsRelate(osc.Fast[index-4], osc.Slow[index-4], direction) and
		IsRelate(osc.Slow[index-3], osc.Fast[index-3], direction) and
		IsRelate(osc.Fast[index-2], osc.Slow[index-2], direction) and
		IsRelate(osc.Fast[index-1], osc.Slow[index-1], direction))
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

--
-- Signal Price Uturn3
--
function SignalPriceUturn3(price, ma, index, direction)
	direction = string.upper(string.sub(direction, 1, 1))

	if (direction == Directions.Up) then
		-- one or two of 2 first candles are down, last 1 candle is up
		return ((((price.Open[index-3] > price.Close[index-3]) or (price.Open[index-2] >= price.Close[index-2])) and
			(price.Close[index-1] > price.Open[index-1])) and
			-- price.close uturn and delta min at top uturn			
			SignalUturn(price.Close, index, direction) and SignalUturn(ma.Delta, index, Directions.Up) and
			-- ma move up
			(SignalMove(ma, (index-1), direction) and SignalMove(ma, index, direction)) and
			-- strength condition
			((price.Close[index-1] > (price.Low[index-3] + 2.0 / 3.0 * (price.High[index-3] - price.Low[index-3]))) or
			(price.Close[index-1] > (price.Low[index-2] + 2.0 / 3.0 * (price.High[index-2] - price.Low[index-2])))))

	elseif (direction == Directions.Down) then
		-- one or two of 2 first candles are down, last 1 candle is up
		return ((((price.Close[index-3] > price.Open[index-3]) or (price.Close[index-2] >= price.Open[index-2])) and
			(price.Open[index-1] > price.Close[index-1])) and
			-- price.close uturn and delta min at top uturn
			SignalUturn(price.Close, index, direction) and SignalUturn(ma.Delta, index, Directions.Up) and
			-- ma move down
			(SignalMove(ma, (index-1), direction) and SignalMove(ma, index, direction)) and
			-- strength condition
			(((price.High[index-3] - 2.0 / 3.0 * (price.High[index-3] - price.Low[index-3])) > price.Close[index-1]) or
			((price.High[index-2] - 2.0 / 3.0 * (price.High[index-2] - price.Low[index-2])) > price.Close[index-1])))
	end
end

--
-- Signal Price Uturn4
--
function SignalPriceUturn4(price, ma, index, direction)
	direction = string.upper(string.sub(direction, 1, 1))

	if (direction == Directions.Up) then
		-- first 2 candles down, last candle up
		return ((((price.Open[index-4] > price.Close[index-4]) or (price.Open[index-3] > price.Close[index-3])) and
			(price.Close[index-1] > price.Open[index-1])) and
			-- price.close uturn
			(SignalMove(price.Close, index-2, Reverse(direction)) and SignalMove(price.Close, index, direction)) and
			-- delta min at top uturn
			(SignalMove(ma.Delta, index-2, Directions.Down) and SignalMove(ma.Delta, index, Directions.Up)) and
			-- ma move up
			(SignalMove(ma, (index-2), direction) and SignalMove(ma, index, direction))  and
			-- strength condition
			((price.Close[index-1] > (price.Low[index-3] + 2.0 / 3.0 * (price.High[index-3] - price.Low[index-3]))) or
			(price.Close[index-1] > (price.Low[index-2] + 2.0 / 3.0 * (price.High[index-2] - price.Low[index-2])))))

	elseif (direction == Directions.Down) then
		-- one or two of 2 first candles are down, last 1 candle is up
		return ((((price.Close[index-4] > price.Open[index-4]) or (price.Close[index-3] > price.Open[index-3])) and
			(price.Open[index-1] > price.Close[index-1])) and
			-- price.close uturn
			(SignalMove(price.Close, index-2, Reverse(direction)) and SignalMove(price.Close, index, direction)) and
			-- delta min at top uturn
			(SignalMove(ma.Delta, index-2, Directions.Down) and SignalMove(ma.Delta, index, Directions.Up)) and
			-- ma move down
			(SignalMove(ma, (index-2), direction) and SignalMove(ma, index, direction)) and
			-- strength condition
			(((price.High[index-3] - 2.0 / 3.0 * (price.High[index-3] - price.Low[index-3])) > price.Close[index-1]) or
			((price.High[index-2] - 2.0 / 3.0 * (price.High[index-2] - price.Low[index-2])) > price.Close[index-1])))
	end
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