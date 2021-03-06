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
--// recode SetInitValues and PrintSummaryResults to cycles over all pairs
--// shift uturn slow and fast lines
--// remove SochCross from Signals -> remove relation in uturn3
--// remove delta in uturn3
--// all variants for StochSlow in Uturn3
--// check new signal functions and add strength signals
--// enter for Uturn3
--// create func CheckElementarySignal
--// separate enter forn uturn31 and uturn32
--// turn off signal for duration
--// made signal turn off by opposite signal on
--// separate signal start and stop by opposite signal/duration
--//states: CheckStateStrengthOn...
--// make continue icon for previous candle to avoid double chart icon

--todo check signals in realtime
--todo remake all error handling to exceptions in functional programming
--todo remove all chart labels keep only last 30
--todo remove all prices and inds array, kepp only last three
--todo enter for Trendoff+Diver
--todo 1st leg zigzag with divergence
--todo 2 signals with 2nd leg zigzag near lvl50
--todo separate enters for combination price uturn31/32 and stoch uturn31/32 and rsi uturn31/32
--todo rsi uturn with spring/relate
--todo indicators with queue
--todo set initial values with set arrays with fixed structure with counts only low level of nesting and init to zero via cycles and recursions and then add names at curtain levels OR via inheritence
--todo make single metatable for all instances of IndexWindows
--todo CheckEnter via complex description of enter. dependent signals and sequentaly checking elementary signals via cycles and recursions
--todo remove turn off from strength

--todo loging to CSV
--todo transaction
--todo make stoploss to nearest ext
--todo position menegement
--todo risk menegement

--? functions Place for Stoch Uturn3 AND convert states to conditions value relate level
--? may be remove stoch uturns because we need impulse onlu from price and rsi
--? make structure for enter and dependent signals and strenghts
--? icon property signal/state
--? make full support for states, strenghths, enters, including Signals etc arrays
--? make functions Uturn, Spring for RSI Uturn3
--? make code for CheckComplexSignals
--? move long/short checking signals to diferent branch
--? make candle+count itterator in separate States structure
--? make 3-candle cross event fucntion
--? move error checking data checking args checking from signal functions to lowest event functions
--? fast relate slow in 1) StochCross 2) Uturn3 3) StochSteamer

--* if func make smthg - return true if ok or return false if nook
--* if func return number boolen string including number maked things include zero if maked nothing - return thng or nil if return error

--* rememebr about strength critery in prciecross/osccross signals - now there have most strength criter where different sides of cross have different not equal values
--* events -> signals and strength -> states -> enters
--* events/conditions is elementary signals like fast oscilator cross up slow oscilator, price cross up ma  and all there are in period 2-3 candles
--* several events and conditions consist signal like uturn, spring, cross, cross50 etc
--* signal turn off by opposite signal or by duration
--* strength is conditions for signals like request for close last candle over all previous closes of candles in Reverse Candle Model, so strength cannot be turn off
--* signals is clear signals , all strengh conditions must be in states/enters
--* states consist trend, impulse etc and havn't duration to off, states turn off ny opposite states
--* several states and signals consist enters like Leg1ZigZagSpring, Uturn50 etc

--===========================================================================
-----------------------------------------------------------------------------
--#region SETTINGS
-----------------------------------------------------------------------------
Settings = { Name = "FEK_LITHIUM", line = {{ Name = "Top", Type = TYPE_LINE, Color = RGB(242, 249, 198), Width = 1  }, { Name = "Centre", Type = TYPE_POINT,	Color = RGB(237, 246, 225), Width = 1 },  { Name = "Bottom", Type = TYPE_LINE, Color = RGB(224, 138, 149), Width = 3 }}}
--#endregion SETTINGS

-----------------------------------------------------------------------------
--#region INIT
-----------------------------------------------------------------------------
function Init()
   -- permissions to show labels on charts
   ChartPermissions = { Signal = 1, Strength = 2, State = 4, Enter = 8 }

   -- chart params and indicators
   -- price data arrays and params
   Prices = { Name = "Price", Opens = {}, Closes = {}, Highs = {}, Lows = {}, Step = 5, Permission = ChartPermissions.Enter + ChartPermissions.Signal } -- FEK_LITHIUMPrice

   -- stochastic data arrays and params
   Stochs = { Name = "Stoch", Fasts = {}, Slows = {}, HLines = { TopExtreme = 80, Centre = 50, BottomExtreme = 20 }, Slow = { PeriodK = 10, Shift = 3, PeriodD = 1 }, Fast = { PeriodK = 5, Shift = 2, PeriodD = 1 }, Step = 20, Permission = ChartPermissions.State } -- FEK_LITHIUMStoch

   -- RSI data arrays and params
   RSIs = { Name = "RSI", Fasts = {}, Slows = {}, HLines = { TopExtreme = 80, TopTrend = 60, Centre = 50, BottomTrend = 40, BottomExtreme = 20 }, Slow = 14, Fast = 9, Step = 5, Permission = ChartPermissions.Signal } -- FEK_LITHIUMRSI

   -- price channel data arrays and params
   PCs = { Name = "PC", Tops = {}, Bottoms = {}, Centres = {}, Period = 20 }

   -- directions for signals labels and deals
   Directions = { Long = "L", Short = "S" }

   -- chart labels arrays and default params
   IndexWindowsSize = 100
   ChartLabels = { [Prices.Name] = IndexWindows(IndexWindowsSize)(), [Stochs.Name] =  IndexWindows(IndexWindowsSize)(), [RSIs.Name] = IndexWindows(IndexWindowsSize)(), Params = { TRANSPARENCY = 0, TRANSPARENT_BACKGROUND = 1, FONT_FACE_NAME = "Arial", FONT_HEIGHT = 8 }}

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

   -- logging level as in lualogging module
   DebugLevel = { Debug = 1 --[[ fine-grained informational events that are most useful to debug an application ]], Info = 2 --[[ informational messages that highlight the progress of the application at coarse-grained level ]],  Warn = 4 --[[ potentially harmful situations ]], Error = 8 --[[ error events that might still allow the application to continue running ]], Fatal = 16 --[[ very severe error events that would presumably lead the application to abort ]], Off = 32 --[[ will stop all log messages ]] }

   -- signals names, counts, start cansles
   Signals = { Cross = { Name = "Cross", [Directions.Long] = { [Stochs.Name] = { Count = 0, Candle = 0 }, [RSIs.Name] = { Count = 0, Candle = 0 }}, [Directions.Short] = { [Stochs.Name] = { Count = 0, Candle = 0 }, [RSIs.Name] = { Count = 0, Candle = 0 }}},

               Cross50 = { Name = "Cross50", [Directions.Long] = { [Prices.Name] = { Count = 0, Candle = 0 }, [Stochs.Name] = { Count = 0, Candle = 0 }}, [Directions.Short] = { [Prices.Name] = { Count = 0, Candle = 0 }, [Stochs.Name] = { Count = 0, Candle = 0 }}},

               Steamer = { Name = "Steamer", [Directions.Long] = { [Stochs.Name] = { Count = 0, Candle = 0 }}, [Directions.Short] = { [Stochs.Name] = { Count = 0, Candle = 0 }}},

               TrendOff = { Name = "TrendOff", [Directions.Long] = { [Stochs.Name] = { Count = 0, Candle = 0 }}, [Directions.Short] = { [Stochs.Name] = { Count = 0, Candle = 0 }}},

               Uturn31 = { Name = "Uturn31", [Directions.Long] = { [Prices.Name] = { Count = 0, Candle = 0 }, [Stochs.Name] = { Count = 0, Candle = 0 }, [RSIs.Name] = { Count = 0, Candle = 0 }}, [Directions.Short] = { [Prices.Name] = { Count = 0, Candle = 0 }, [Stochs.Name] = { Count = 0, Candle = 0 }, [RSIs.Name] = { Count = 0, Candle = 0 }}},

               Uturn32 = { Name = "Uturn32", [Directions.Long] = { [Prices.Name] = { Count = 0, Candle = 0 }, [Stochs.Name] = { Count = 0, Candle = 0 }, [RSIs.Name] = { Count = 0, Candle = 0 }}, [Directions.Short] = { [Prices.Name] = { Count = 0, Candle = 0 }, [Stochs.Name] = { Count = 0, Candle = 0 }, [RSIs.Name] = { Count = 0, Candle = 0 }}},

               StrengthOsc = { Name = "StrengthOsc", [Directions.Long] = { [Stochs.Name] = { Count = 0, Candle = 0 }, [RSIs.Name] = { Count = 0, Candle = 0 }}, [Directions.Short] = { [Stochs.Name] = { Count = 0, Candle = 0 }, [RSIs.Name] = { Count = 0, Candle = 0 }}},

               StrengthPrice = { Name = "StrengthPrice", [Directions.Long] = { [Prices.Name] = { Count = 0, Candle = 0 }}, [Directions.Short] = { [Prices.Name] = { Count = 0, Candle = 0 }}},

               Enter = { Name = "Enter", [Directions.Long] = { [Prices.Name] = { Count = 0, Candle = 0 }}, [Directions.Short] = { [Prices.Name] = { Count = 0, Candle = 0 }}},

               MaxDuration = 2, MaxDifference = 10, MinDifference = 0, MinDeviation = 0 }

   -- indicator functions
   StochSlow = Stoch("Slow")
   StochFast = Stoch("Fast")
   RSISlow = RSI("Slow")
   RSIFast = RSI("Fast")
   PC = PriceChannel()

   Pass = 0

   return #Settings.line
end
--#endregion INIT

-----------------------------------------------------------------------------
-- function OnCalculate
-----------------------------------------------------------------------------
function OnCalculate(index)
   -- set initial values on first candle
   if (index == 1) then
      DataSource = getDataSourceInfo()
      SecInfo = getSecurityInfo(DataSource.class_code, DataSource.sec_code)

      Nesting = 1
      ProcessedIndex = 0
      Pass = Pass + 1

      SetInitialValues(Signals)

      PrintDebugMessage("Prices I,V", ChartLabels[Prices.Name], ChartLabels[Prices.Name].Indexes, ChartLabels[Prices.Name].Values)
      PrintDebugMessage("=======")
      PrintDebugMessage("Stochs I,V", ChartLabels[Stochs.Name], ChartLabels[Stochs.Name].Indexes, ChartLabels[Stochs.Name].Values)
      PrintDebugMessage("----------")
      PrintDebugMessage("RSIs I,V", ChartLabels[RSIs.Name], ChartLabels[RSIs.Name].Indexes, ChartLabels[RSIs.Name].Values)
   end

   --#region SET PRICES AND INDICATORS FOR CURRENT CANDLE
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
   --#endregion SET PRICES AND INDICATORS FOR CURRENT CANDLE

   -- debuglog
   --if ((index == 5172) or (index == 5171) or (index == 5170) or (index == 5169)) then
   local t = T(index)
   PrintDebugMessage("I:".. tostring(index), "P:" .. tostring(Pass), "Y:" .. t.year, "M:" .. t.month, "D:" .. t.day, "H:" .. t.hour, "m:" .. t.min)
   message(GetMessage("I:".. tostring(index), "P:" .. tostring(Pass), "Y:" .. t.year, "M:" .. t.month, "D:" .. t.day, "H:" .. t.hour, "m:" .. t.min))
   --end

   -------------------------------------------------------------------------
   -- CHECK SIGNALS STATES ENTERS
   -------------------------------------------------------------------------
   if (ProcessedIndex ~= index) then
      --
      --#region CHECK STATES
      --
      -- check signal price cross ma
      CheckStateStrengthOn(index, Directions.Long, Prices, Signals.Cross50)
      CheckStateStrengthOn(index, Directions.Short, Prices, Signals.Cross50)

      -- check signal stoch fast cross slow
      CheckStateStrengthOn(index, Directions.Long, Stochs, Signals.Cross)
      CheckStateStrengthOn(index, Directions.Short, Stochs, Signals.Cross)

      -- check signal stoch slow cross lvl50
      CheckStateStrengthOn(index, Directions.Long, Stochs, Signals.Cross50)
      CheckStateStrengthOn(index, Directions.Short, Stochs, Signals.Cross50)

      -- check signal rsi fast cross slow
      CheckStateStrengthOn(index, Directions.Long, RSIs, Signals.Cross)
      CheckStateStrengthOn(index, Directions.Short, RSIs, Signals.Cross)

      --
      --#region CHECK SIGNALS
      --
      -- check price signal uturn31
      CheckSignal(index, Directions.Long, Prices, Signals.Uturn31)
      CheckSignal(index, Directions.Short, Prices, Signals.Uturn31)

      -- check ptice signal uturn32
      CheckSignal(index, Directions.Long, Prices, Signals.Uturn32)
      CheckSignal(index, Directions.Short, Prices, Signals.Uturn32)

      -- check signal stoch trendoff
      CheckSignal(index, Directions.Long, Stochs, Signals.TrendOff)
      CheckSignal(index, Directions.Short, Stochs, Signals.TrendOff)

      -- check signal stoch uturn31
      CheckSignal(index, Directions.Long, Stochs, Signals.Uturn31)
      CheckSignal(index, Directions.Short, Stochs, Signals.Uturn31)

      -- check signal stoch uturn32
      CheckSignal(index, Directions.Long, Stochs, Signals.Uturn32)
      CheckSignal(index, Directions.Short, Stochs, Signals.Uturn32)

      -- check signal rsi uturn31
      CheckSignal(index, Directions.Long, RSIs, Signals.Uturn31)
      CheckSignal(index, Directions.Short, RSIs, Signals.Uturn31)

      -- check signal rsi uturn32
      CheckSignal(index, Directions.Long, RSIs, Signals.Uturn32)
      CheckSignal(index, Directions.Short, RSIs, Signals.Uturn32)
      --#endregion CHECK SIGNALS

      --
      --#region CHECK STRENGTH
      --
      -- check signal price strengthprice
      CheckStateStrengthOn(index, Directions.Long, Prices, Signals.StrengthPrice)
      CheckStateStrengthOn(index, Directions.Short, Prices, Signals.StrengthPrice)

      -- check signal stoch steamer
      CheckStateStrengthOn(index, Directions.Long, Stochs, Signals.Steamer)
      CheckStateStrengthOn(index, Directions.Short, Stochs, Signals.Steamer)

      -- check signal stoch strengthosc
      CheckStateStrengthOn(index, Directions.Long, Stochs, Signals.StrengthOsc)
      CheckStateStrengthOn(index, Directions.Short, Stochs, Signals.StrengthOsc)

      -- check signal rsi strengthosc
      CheckStateStrengthOn(index, Directions.Long, RSIs, Signals.StrengthOsc)
      CheckStateStrengthOn(index, Directions.Short, RSIs, Signals.StrengthOsc)
      --#endregion CHECK STRENGTH

      --
      --#region CHECK ENTERS
      --
      CheckEnter(index, Directions.Long)
      CheckEnter(index, Directions.Short)
      --#endregion CHECK ENTERS

      --PrintIntermediateResults(index)

      ProcessedIndex = index
   end -- ProcessedIndex ~= index

   if (index == Size()) then
      PrintSummaryResults(index)
   end

   -- return PCs.Tops[index], PCs.Centres[index], PCs.Bottoms[index]
   return Stochs.Fasts[index], Stochs.HLines.Centre, Stochs.Slows[index]
   -- return RSIs.Fasts[index], RSIs.HLines.Centre, RSIs.Slows[index]
end

--==========================================================================
--#region INDICATOR PRICE CHANNEL
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
--#endregion PRICE CHANNEL

--==========================================================================
--#region INDICATOR STOCHASTIC
--==========================================================================
----------------------------------------------------------------------------
-- Stochastic Oscillator ("SO")
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
-- EMAi = (EMAi-1*(n-1)+2*Pi) / (n+1)
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
-- SMA = sums(Pi) / n
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
--#endregion STOCHASTIC

--==========================================================================
--#region INDICATOR RSI
--==========================================================================
----------------------------------------------------------------------------
-- RSI calculate indicator RSI for durrent candle
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
-- MMA = (MMAi-1 * (n - 1) + Pi) / n
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
--#endregion RSI

--==========================================================================
--#region SIGNALS
--==========================================================================
----------------------------------------------------------------------------
-- CheckStateStrengthOn - check on states Cross, Cross50 and not check states off
----------------------------------------------------------------------------
function CheckStateStrengthOn(index, direction, indicator, signal)
   local values1, values2, signal_function, chart_icon
   local chart_permission

   -- set indicators
   if (indicator.Name == Prices.Name) then
      values1 = Prices.Closes
      values2 = PCs.Centres
   elseif (indicator.Name == Stochs.Name) then
      values1 = Stochs.Fasts
      values2 = Stochs.Slows
   elseif (indicator.Name == RSIs.Name) then
      values1 = RSIs.Fasts
      values2 = RSIs.Slows
   end

   -- set signal function
   if (signal.Name == Signals.Cross50.Name) then
      chart_permission = ChartPermissions.State
      chart_icon = ChartIcons.Arrow
      signal_function = SignalCross
      if (indicator.Name == Stochs.Name) then
         values1 = Stochs.Slows
         values2 = {[index-2] = Stochs.HLines.Centre, [index-1] = Stochs.HLines.Centre}
      end

   elseif (signal.Name == Signals.Cross.Name) then
      chart_permission = ChartPermissions.State
      chart_icon = ChartIcons.Triangle
      signal_function = SignalCross

   -- set strength functions
   elseif (signal.Name == Signals.StrengthOsc.Name) then
      chart_permission = ChartPermissions.Strength
      chart_icon = ChartIcons.Asterix
      signal_function = SignalStrengthOsc

   elseif (signal.Name == Signals.StrengthPrice.Name) then
      chart_permission = ChartPermissions.Strength
      chart_icon = ChartIcons.Flash
      signal_function = SignalStrengthPrice
      values1 = Prices

   elseif (signal.Name == Signals.Steamer.Name) then
      chart_permission = ChartPermissions.Strength
      chart_icon = ChartIcons.Plus
      signal_function = SignalSteamer
   end

   -- check signal start
   if (signal_function((index-1), direction, values1, values2)) then
      PrintDebugMessage("CheckStateStrengthOn", index-1, direction, indicator.Name, signal.Name)
      -- set signal
      SetSignal((index-1), direction, indicator, signal)

      -- set chart label
      ChartLabels[indicator.Name][index-1] = SetChartLabel((index-1), direction, indicator, signal, chart_icon, chart_permission)
   end
end

----------------------------------------------------------------------------
-- CheckSignal - check on signals: Uturn31, Uturn32, TrendOff, strength: StrengthOsc, StrengthPrice, Steamer and check off they
----------------------------------------------------------------------------
function CheckSignal(index, direction, indicator, signal)
   local values1, values2, signal_function, chart_icon, chart_permission

   -- set indicators
   if (indicator.Name == Prices.Name) then
      values1 = Prices.Closes
      values2 = PCs.Centres
   elseif (indicator.Name == Stochs.Name) then
      values1 = Stochs.Fasts
      values2 = Stochs.Slows
   elseif (indicator.Name == RSIs.Name) then
      values1 = RSIs.Fasts
      values2 = RSIs.Slows
   end

   -- set signals function
   if (signal.Name == Signals.Uturn31.Name ) then
      chart_permission = ChartPermissions.Signal
      chart_icon = ChartIcons.Romb
      signal_function = SignalUturn31

   elseif (signal.Name == Signals.Uturn32.Name ) then
      chart_permission = ChartPermissions.Signal
      chart_icon = ChartIcons.Point
      signal_function = SignalUturn32

   elseif (signal.Name == Signals.TrendOff.Name ) then
      chart_permission = ChartPermissions.Signal
      chart_icon = ChartIcons.Minus
      signal_function = SignalCross
      if (indicator.Name == Stochs.Name) then
         values1 = Stochs.Slows
         if (direction == Directions.Long) then
            values2 = {[index-2] = Stochs.HLines.TopExtreme, [index-1] = Stochs.HLines.TopExtreme}
         elseif (direction == Directions.Short) then
            values2 = {[index-2] = Stochs.HLines.BottomExtreme, [index-1] = Stochs.HLines.BottomExtreme}
         end
      elseif (indicator.Name == RSIs.Name) then
         values1 = RSIs.Slows
         if (direction == Directions.Long) then
            values2 = {[index-2] = RSIs.HLines.TopTrend, [index-1] = RSIs.HLines.TopTrend}
         elseif (direction == Directions.LShortong) then
            values2 = {[index-2] = RSIs.HLines.BottomTrend, [index-1] = RSIs.HLines.BottomTrend}
         end
      end
      direction = Reverse(direction)
   end

   -- check signal on
   if (signal_function((index-1), direction, values1, values2)) then
      PrintDebugMessage("CheckSignal", index-1, direction, indicator.Name, signal.Name)

      -- set signal
      SetSignal((index-1), direction, indicator, signal)

      -- set chart label
      ChartLabels[indicator.Name][index-1] = SetChartLabel((index-1), direction, indicator, signal, chart_icon, chart_permission)
   end -- signal on

   -- check signal off
   if (Signals[signal.Name][direction][indicator.Name].Candle > 0) then
      -- set signal duration
      local duration = index - Signals[signal.Name][direction][indicator.Name].Candle

      -- signal terminates by end of duration
      if (duration > Signals.MaxDuration) then
         -- set signal off
         Signals[signal.Name][direction][indicator.Name].Candle = 0
      end
   end -- signal off
end

----------------------------------------------------------------------------
-- CheckEnter 
----------------------------------------------------------------------------
function CheckEnter(index, direction)
   -- check enter on
   if ((Signals[Signals.Enter.Name][direction][Prices.Name].Candle == 0) and
   -- states
   ((Signals[Signals.Cross50.Name][direction][Prices.Name].Candle > 0) and
   (Signals[Signals.Cross50.Name][direction][Stochs.Name].Candle > 0) and (Signals[Signals.Cross.Name][direction][Stochs.Name].Candle > 0) and
   (Signals[Signals.Cross.Name][direction][RSIs.Name].Candle > 0)) and
   -- signals
   (((Signals[Signals.Uturn31.Name][direction][Prices.Name].Candle > 0) or (Signals[Signals.Uturn32.Name][direction][Prices.Name].Candle > 0)) and
   --((Signals[Signals.Uturn31.Name][direction][Stochs.Name].Candle > 0) or (Signals[Signals.Uturn32.Name][direction][Stochs.Name].Candle > 0)) and
   ((Signals[Signals.Uturn31.Name][direction][RSIs.Name].Candle > 0) or (Signals[Signals.Uturn32.Name][direction][RSIs.Name].Candle > 0)))
   -- strength
   --[[ and (Signals[Signals.StrengthPrice.Name][direction][Prices.Name].Candle > 0) and
   (Signals[Signals.Steamer.Name][direction][Stochs.Name].Candle > 0) and
   (Signals[Signals.StrengthOsc.Name][direction][Stochs.Name].Candle > 0) and
   (Signals[Signals.StrengthOsc.Name][direction][RSIs.Name].Candle > 0) ]]
   ) then
      PrintDebugMessage("CheckEnter", index-1, direction)

      -- set enter signal on
      SetSignal((index-1), direction, Prices, Signals.Enter)

      -- set chart label
      ChartLabels[Prices.Name][index-1] = SetChartLabel((index-1), direction, Prices, Signals.Enter, ChartIcons.BigArrow, ChartPermissions.Enter)
   end -- enter signals on

   -- check enter off
   if (Signals[Signals.Enter.Name][direction][Prices.Name].Candle > 0) then
      -- set enter duration
      local duration = index - Signals[Signals.Enter.Name][direction][Prices.Name].Candle

      -- check continuation enter and check enter terminates by end one of state signals or check enter terminates by end of duration
      if (((duration <= Signals.MaxDuration) and ((Signals[Signals.Cross50.Name][direction][Prices.Name].Candle == 0) or (Signals[Signals.Cross50.Name][direction][Stochs.Name].Candle == 0) or (Signals[Signals.Cross.Name][direction][Stochs.Name].Candle == 0) or (Signals[Signals.Cross.Name][direction][RSIs.Name].Candle == 0))) or (duration > Signals.MaxDuration)) then
         -- set enter long off
         Signals[Signals.Enter.Name][direction][Prices.Name].Candle = 0
      end
   end -- enter long off
end
----------------------------------------------------------------------------
-- Signal Steamer - fast and slow move synchro in one direction
----------------------------------------------------------------------------
function SignalSteamer(index, direction, value1, value2, dev, diff)
   if (CheckDataExist(index, 2, value1) and CheckDataExist(index, 2, value2)) then

      local dev = dev or Signals.MinDeviation
      local diff = diff or Signals.MaxDifference

      return (-- osc fast and slow move in direction last 2 candles
         (EventMove(index, direction, value1, dev) and EventMove(index, direction, value2, dev)) and

         -- osc fast ralate osc slow in direction last 1 candle
         CheckRelate(direction, value1[index], value2[index], dev) and

         -- delta beetwen osc fast and slow osc less then diff last 1 candle
         CheckFlat(value1[index], value2[index], diff))

   -- not enough data
   else
      return nil
   end
end

----------------------------------------------------------------------------
-- Signal Fast Cross Slow Up/Down
----------------------------------------------------------------------------
function SignalCross(index, direction, values1, values2, dev, diff)
   if (CheckDataExist(index, 2, values1) and CheckDataExist(index, 2, values2)) then
      local dev = dev or Signals.MinDeviation
      local diff = diff or Signals.MinDifference

      return ( -- two first candle is equal, two last candles is different
         (CheckFlat(values1[index-1], values2[index-1], diff) and CheckRelate(direction, values1[index], values2[index], dev)) or
         -- cross fast osc over/under slow osc
         EventCross(index, direction, values1, values2, dev))

   -- not enough data
   else
      return nil
   end
end

----------------------------------------------------------------------------
-- Signal Uturn with 3 candles model 1 - fast uturn3 with shifts and slow uturn3
--todo fasts relate slows
----------------------------------------------------------------------------
function SignalUturn31(index, direction, values1, values2, dev, diff)
   if (CheckDataExist(index, 5, values1) and CheckDataExist(index, 3, values2)) then
      local dev = dev or Signals.MinDeviation
      local diff = diff or Signals.MinDifference

--[[       PrintDebugMessage("SignalUturn31-1", index, direction, values1, values2, dev, diff)
      PrintDebugMessage("SignalUturn31-2", EventUturn3(index, direction, values1, dev), EventUturn3((index-1), direction, values1, dev), EventUturn3((index-2), direction, values1, dev), EventUturn3(index, direction, values2, dev)) ]]

      return ((EventUturn3(index, direction, values1, dev) or EventUturn3((index-1), direction, values1, dev) or EventUturn3((index-2), direction, values1, dev)) and EventUturn3(index, direction, values2, dev))

   -- not enough data
   else
      return nil
   end
end

----------------------------------------------------------------------------
-- Signal Uturn with 3 candles model 2 - fast  uturn3 and slow flat or move
--todo fasts relate slows
----------------------------------------------------------------------------
function SignalUturn32(index, direction, values1, values2, dev, diff)
   if (CheckDataExist(index, 3, values1) and CheckDataExist(index, 3, values2)) then
      local dev = dev or Signals.MinDeviation
      local diff = diff or Signals.MinDifference

--[[       PrintDebugMessage("SignalUturn32-1", index, direction, values1, values2, dev, diff)
      PrintDebugMessage("SignalUturn32-2", EventUturn3(index, direction, values1, dev), EventMove(index, Reverse(direction), values2, dev), EventMove((index-1), Reverse(direction), values2, dev)) ]]

      return (EventUturn3(index, direction, values1, dev) and not EventMove(index, Reverse(direction), values2, dev) and not EventMove((index-1), Reverse(direction), values2, dev))

   -- not enough data
   else
      return nil
   end
end

----------------------------------------------------------------------------
-- Signal Strength model 1 - value1 and value2 at index greater or equal then ones at index-2
----------------------------------------------------------------------------
function SignalStrengthOsc(index, direction, values1, values2, dev, diff)
   if (CheckDataExist(index, 3, values1) and CheckDataExist(index, 3, values2)) then
      local dev = dev or Signals.MinDeviation
      local diff = diff or Signals.MinDifference

      return ((CheckRelate(direction, values1[index], values1[index-2], dev) or CheckFlat(values1[index], values1[index-2], diff)) and (CheckRelate(direction, values2[index], values2[index-2], dev) or CheckFlat(values2[index], values2[index-2], diff)))

   -- not enough data
   else
      return nil
   end
end

----------------------------------------------------------------------------
-- Signal Strength model 2 - priceclose at index greater then 2/3 range of candles at index-1 or index-2
----------------------------------------------------------------------------
function SignalStrengthPrice(index, direction, prices, value, dev)
   if (CheckDataExist(index, 3, prices.Closes) and CheckDataExist(index, 3,  prices.Highs) and CheckDataExist(index, 3,  prices.Lows)) then
      local dev = dev or Signals.MinDeviation

      if (direction == Directions.Long) then
         return ((prices.Closes[index] > (prices.Lows[index-2] + 2.0 / 3.0 * (prices.Highs[index-2] - prices.Lows[index-2]) + dev)) or (prices.Closes[index] > (prices.Lows[index-1] + 2.0 / 3.0 * (prices.Highs[index-1] - prices.Lows[index-1]) + dev)))

      elseif (direction == Directions.Short) then
         return (((prices.Highs[index-2] - 2.0 / 3.0 * (prices.Highs[index-2] - prices.Lows[index-2])) > prices.Closes[index] + dev) or ((prices.Highs[index-1] - 2.0 / 3.0 * (prices.Highs[index-1] - prices.Lows[index-1])) > prices.Closes[index] + dev))
      end

   -- not enough data
   else
      return nil
   end
end
--#endregion SIGNALS

--==========================================================================
--#region EVENTS
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
--#endregion EVENTS

--==========================================================================
--#region UTILITIES
--==========================================================================
----------------------------------------------------------------------------
-- Reverse() return reverse of direction
----------------------------------------------------------------------------
function Reverse(direction)
   if (direction == Directions.Long) then
      return Directions.Short
   elseif (direction == Directions.Short) then
      return Directions.Long
   end
end

----------------------------------------------------------------------------
-- GetDelta() return abs difference between values
----------------------------------------------------------------------------
function GetDelta(value1, value2)
   if ((value1 == nil) or (value2 == nil)) then
      return nil
   end

   -- return math.abs(value1 - value2)
   return (value1 - value2)
end

----------------------------------------------------------------------------
-- Squeeze() return number from 0 (if index start from 1) to period and then again from 0 (index == period) pointer in cycylic buffer
----------------------------------------------------------------------------
function CyclicPointer(index, period)
   return math.fmod(index - 1, period + 1)
end

----------------------------------------------------------------------------
-- RoundScale() return value with requred numbers after digital point
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
-- GetChartTag() return chart tag from Robot name and Indicator name
----------------------------------------------------------------------------
function GetChartTag(indicator_name)
   return (Settings.Name .. indicator_name)
end

----------------------------------------------------------------------------
-- SetSignal() set signal variables and state
----------------------------------------------------------------------------
function SetSignal(index, direction, indicator, signal)
   -- set signal up/down off
   Signals[signal.Name][Reverse(direction)][indicator.Name].Candle = 0

   -- set signal down/up on
   Signals[signal.Name][direction][indicator.Name].Count = Signals[signal.Name][direction][indicator.Name].Count + 1
   Signals[signal.Name][direction][indicator.Name].Candle = index
end

--------------------------------------------------------------------------
-- CheckDataExist() return true if number values from index back exist
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
-- CheckChartPermission() Returns the truth if signal permission is alowed by permissions of chart
----------------------------------------------------------------------------
function CheckChartPermission(indicator, signal_permission)
   return (((signal_permission == ChartPermissions.Signal) and ((indicator.Permission & ChartPermissions.Signal) > 0)) or ((signal_permission == ChartPermissions.Strength) and ((indicator.Permission & ChartPermissions.Strength) > 0)) or ((signal_permission == ChartPermissions.State) and ((indicator.Permission & ChartPermissions.State) > 0)) or ((signal_permission == ChartPermissions.Enter) and ((indicator.Permission & ChartPermissions.Enter) > 0)))
end

----------------------------------------------------------------------------
-- GetMessage(...) Returns messages separated by the symbol as one string
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

   -- nothing todo
   else
      return nil
   end
end

----------------------------------------------------------------------------
-- PrintDebugMessage(message1, message2, ...) print messages as one string separated by symbol in message window and debug console
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

   -- nothing todo
   else
      return nil
   end
end

-----------------------------------------------------------------------------
-- GetChartLabelXPos() returns x position for chart label
-----------------------------------------------------------------------------
function GetChartLabelXPos(t)
   return tostring(10000 * t.year + 100 * t.month + t.day), tostring(10000 * t.hour + 100 * t.min + t.sec)
end

----------------------------------------------------------------------------
-- GetChartLabelYPos() returns y position for chart label
--todo make cyclic variable for several levels of y position
----------------------------------------------------------------------------
function GetChartLabelYPos(index, direction, indicator)
   local y
   local sign = (direction == Directions.Long) and -1 or 1

   -- y pos for price chart
   if (indicator.Name == Prices.Name) then
      local price = (direction == Directions.Long) and "Lows" or "Highs"
      y = Prices[price][index] + sign * Prices.Step * SecInfo.min_price_step

      -- y pos for stoch/rsi chart
   else
      y = indicator.Slows[index] * (100 + sign * indicator.Step) / 100
   end

   return y
end

----------------------------------------------------------------------------
-- GetChartIcon() returns icon path for chart label
----------------------------------------------------------------------------
function GetChartIcon(direction, icon)
   icon = icon or ChartIcons.Triangle
   return (ChartLabels.Params.IconPath  .. icon .. "_" .. direction .. ".jpg")
end

----------------------------------------------------------------------------
-- SetChartLabel() set chart label
----------------------------------------------------------------------------
function SetChartLabel(index, direction, indicator, signal, icon, signal_permission, text)
   -- check signal level and chart levels
   if ChartLabels[indicator.Name]:CheckIndexFrom(index) then
      if CheckChartPermission(indicator, signal_permission) then
         PrintDebugMessage("SetChartLabel1", index, direction, indicator.Name, signal.Name, icon, signal_permission, text)
         local chart_tag = GetChartTag(indicator.Name)
         local idx, chart_label_id = ChartLabels[indicator.Name]:GetItem(index)
         PrintDebugMessage("SetChartLabel2", idx, chart_label_id)

         -- record with index and check_label_id in IndexWindows exist -  delete label duplicate
         if ((idx ~= nil) and (chart_label_id ~= nil)) then
            local res = DelLabel(chart_tag, chart_label_id)
            PrintDebugMessage("SetChartLabel3", res, chart_label_id)
         -- record not exist - add new item to IndexWindows
         else
            _, chart_label_id = ChartLabels[indicator.Name]:AddItem(index, true)
            PrintDebugMessage("SetChartLabel4",chart_label_id)
            -- del chart label that removed from overflowed IndexWindow
            if  ((chart_label_id ~= nil) and (chart_label_id ~= 0)) then
               local res = DelLabel(chart_tag, chart_label_id)
               PrintDebugMessage("SetChartLabel5", res, chart_label_id)
            end
         end

         -- set label icon
         ChartLabels.Params.IMAGE_PATH = GetChartIcon(direction, icon)
         -- set label position
         ChartLabels.Params.DATE, ChartLabels.Params.TIME = GetChartLabelXPos(T(index))
         ChartLabels.Params.YVALUE = GetChartLabelYPos(index, direction, indicator)
         -- set chart alingment from direction
         ChartLabels.Params.ALIGNMENT = (direction == Directions.Long) and "BOTTOM" or "TOP"
         -- set text
         ChartLabels.Params.TEXT = ""
         ChartLabels.Params.HINT = GetMessage(direction, indicator.Name, signal.Name, Signals[signal.Name][direction][indicator.Name].Count, "\n", Signals[signal.Name][direction][indicator.Name].Candle, text)

         -- set chart label and return id
         chart_label_id = AddLabel(chart_tag, ChartLabels.Params)
         ChartLabels[indicator.Name]:SetItem(index, chart_label_id)
         PrintDebugMessage("SetChartLabel6", chart_label_id, ChartLabels[indicator.Name]:GetItem(index))
         return chart_label_id
      end
   -- nothing todo
   else
      return nil
   end
end

----------------------------------------------------------------------------
-- SetInitialCounts() init Signals Candles and Counts
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
--#endregion UTILITIES

--==========================================================================
--#region PRINTS
--==========================================================================
----------------------------------------------------------------------------
-- PrintSummaryResult
----------------------------------------------------------------------------
function PrintSummaryResults(index)
   local rule = "-------------------------------------------------------"
   local fmt = "%-14s%-4s%-6s%-6s%-5s%-4s%-6s%-6s%-5s"
   local t1 = T(1)
   local t2 = T(index)

   PrintDebugMessage("Number of candles", index, "First", t1.year, t1.month, t1.day, t1.hour, t1.min, "Last", t2.year, t2.month, t2.day, t2.hour, t2.min)

   -- print header
   PrintDebugMessage(string.format("%-s", rule))
   PrintDebugMessage(string.format(fmt, "Signal", "Dir", Prices.Name,  Stochs.Name, RSIs.Name, "Dir", Prices.Name,  Stochs.Name, RSIs.Name))
   PrintDebugMessage(string.format("%-s", rule))

   -- print Cross50
   PrintDebugMessage(string.format(fmt, Signals.Cross50.Name, Directions.Long, Signals.Cross50[Directions.Long][Prices.Name].Count, Signals.Cross50[Directions.Long][Stochs.Name].Count, "-", Directions.Short, Signals.Cross50[Directions.Short][Prices.Name].Count, Signals.Cross50[Directions.Short][Stochs.Name].Count, "-"))

   -- print Cross
   PrintDebugMessage(string.format(fmt, Signals.Cross.Name, Directions.Long, "-", Signals.Cross[Directions.Long][Stochs.Name].Count, Signals.Cross[Directions.Long][RSIs.Name].Count, Directions.Short, "-", Signals.Cross[Directions.Short][Stochs.Name].Count, Signals.Cross[Directions.Short][RSIs.Name].Count))

   -- print Uturn31
   PrintDebugMessage(string.format(fmt, Signals.Uturn31.Name, Directions.Long, Signals.Uturn31[Directions.Long][Prices.Name].Count, Signals.Uturn31[Directions.Long][Stochs.Name].Count, Signals.Uturn31[Directions.Long][RSIs.Name].Count, Directions.Short, Signals.Uturn31[Directions.Short][Prices.Name].Count, Signals.Uturn31[Directions.Short][Stochs.Name].Count, Signals.Uturn31[Directions.Short][RSIs.Name].Count))

   -- print Utrun32
   PrintDebugMessage(string.format(fmt, Signals.Uturn32.Name, Directions.Long, Signals.Uturn32[Directions.Long][Prices.Name].Count, Signals.Uturn32[Directions.Long][Stochs.Name].Count, Signals.Uturn32[Directions.Long][RSIs.Name].Count, Directions.Short, Signals.Uturn32[Directions.Short][Prices.Name].Count, Signals.Uturn32[Directions.Short][Stochs.Name].Count, Signals.Uturn32[Directions.Short][RSIs.Name].Count))

   -- print TrendOff
   PrintDebugMessage(string.format(fmt, Signals.TrendOff.Name, Directions.Long, "-", Signals.TrendOff[Directions.Long][Stochs.Name].Count, "-", Directions.Short, "-", Signals.TrendOff[Directions.Short][Stochs.Name].Count, "-"))

   -- print Steamer
   PrintDebugMessage(string.format(fmt, Signals.Steamer.Name, Directions.Long, "-", Signals.Steamer[Directions.Long][Stochs.Name].Count, "-", Directions.Short, "-", Signals.Steamer[Directions.Short][Stochs.Name].Count, "-"))

   -- priint StrengthOsc
   PrintDebugMessage(string.format(fmt, Signals.StrengthOsc.Name, Directions.Long, "-", Signals.StrengthOsc[Directions.Long][Stochs.Name].Count, Signals.StrengthOsc[Directions.Long][RSIs.Name].Count, Directions.Short, "-", Signals.StrengthOsc[Directions.Short][Stochs.Name].Count, Signals.StrengthOsc[Directions.Short][RSIs.Name].Count))

   -- print StrengthPrice
   PrintDebugMessage(string.format(fmt, Signals.StrengthPrice.Name, Directions.Long, Signals.StrengthPrice[Directions.Long][Prices.Name].Count, "-", "-", Directions.Short, Signals.StrengthPrice[Directions.Short][Prices.Name].Count, "-", "-"))

   -- print enter
   PrintDebugMessage(string.format(fmt, Signals.Enter.Name, Directions.Long, Signals.Enter[Directions.Long][Prices.Name].Count, "-", "-", Directions.Short, Signals.Enter[Directions.Short][Prices.Name].Count, "-", "-"))

   -- print footer
   PrintDebugMessage(string.format("%-s", rule))
end

----------------------------------------------------------------------------
-- GetSignalFlag & PrintIntermediateResults
----------------------------------------------------------------------------
function PrintIntermediateResults(index)
   local function GetSignalFlag(signal)
      return tostring((signal > 0) and 1 or 0)
   end

   local msg
   local t = T(index)
   local oscs = Prices.Name .. "," .. Stochs.Name .. "," .. RSIs.Name
   local signals = Signals.Cross50.Name .. ",,," .. Signals.Cross.Name .. ",,," .. Signals.Uturn31.Name .. ",,," .. Signals.Uturn32.Name .. ",,," .. Signals.TrendOff.Name .. ",,," .. Signals.Steamer.Name .. ",,," .. Signals.StrengthOsc.Name .. ",,," .. Signals.StrengthPrice.Name .. ",,," .. Signals.Enter.Name  .. ",,,"

   -- print header
   if (index == 1) then
      PrintDebugMessage(",,,,,," .. Directions.Long .. ",,,,,,,,,,,,,,,,,,,,,,,,,,," .. Directions.Short)

      PrintDebugMessage(",,,,,," .. signals .. signals)

      PrintDebugMessage("Index,Year,Month,Day,Hour,Min," .. oscs .. "," .. oscs .. "," .. oscs .. "," .. oscs .. "," .. oscs .. "," .. oscs .. "," .. oscs .. "," .. oscs .. "," .. oscs .. "," .. oscs .. "," .. oscs .. "," .. oscs .. "," .. oscs .. "," .. oscs .. "," .. oscs .. "," .. oscs .. "," .. oscs .. "," .. oscs)
   end

   -- construct message text
   msg = tostring(index) .. "," .. tostring(t.year) .. "," .. tostring(t.month) .. "," .. tostring(t.day) .. "," .. tostring(t.hour) .. "," .. tostring(t.min)

   -- Directions.Long
   -- print Cross50
   msg = msg .. "," .. GetSignalFlag(Signals.Cross50[Directions.Long][Prices.Name].Candle) .. "," .. GetSignalFlag(Signals.Cross50[Directions.Long][Stochs.Name].Candle) .. ",0"
   -- print Cross
   msg = msg .. ",0," .. GetSignalFlag(Signals.Cross[Directions.Long][Stochs.Name].Candle) .. "," .. GetSignalFlag(Signals.Cross[Directions.Long][RSIs.Name].Candle)

   -- print Uturn31
   msg = msg .. "," .. GetSignalFlag(Signals.Uturn31[Directions.Long][Prices.Name].Candle) .. "," .. GetSignalFlag(Signals.Uturn31[Directions.Long][Stochs.Name].Candle) .. "," .. GetSignalFlag(Signals.Uturn31[Directions.Long][RSIs.Name].Candle)

   -- print Utrun32
   msg = msg .. "," .. GetSignalFlag(Signals.Uturn32[Directions.Long][Prices.Name].Candle) .. "," .. GetSignalFlag(Signals.Uturn32[Directions.Long][Stochs.Name].Candle) .. "," .. GetSignalFlag(Signals.Uturn32[Directions.Long][RSIs.Name].Candle)

   -- print TrendOff
   msg = msg .. ",0," .. GetSignalFlag(Signals.TrendOff[Directions.Long][Stochs.Name].Candle) .. ",0"

   -- print Steamer
   msg = msg .. ",0," .. GetSignalFlag(Signals.Steamer[Directions.Long][Stochs.Name].Candle) .. ",0"

   -- priint StrengthOsc
   msg = msg .. ",0," .. GetSignalFlag(Signals.StrengthOsc[Directions.Long][Stochs.Name].Candle) .. "," .. GetSignalFlag(Signals.StrengthOsc[Directions.Long][RSIs.Name].Candle)

   -- print StrengthPrice
   msg = msg .. "," .. GetSignalFlag(Signals.StrengthPrice[Directions.Long][Prices.Name].Candle) .. ",0,0"

   -- print Enter
   msg = msg .. "," .. GetSignalFlag(Signals.Enter[Directions.Long][Prices.Name].Candle) .. ",0,0"

   -- Directions.Short
   -- print Cross50
   msg = msg .. "," .. GetSignalFlag(Signals.Cross50[Directions.Short][Prices.Name].Candle) .. "," .. GetSignalFlag(Signals.Cross50[Directions.Short][Stochs.Name].Candle) .. ",0"

   -- print Cross
   msg = msg .. ",0," .. GetSignalFlag(Signals.Cross[Directions.Short][Stochs.Name].Candle) .. "," .. GetSignalFlag(Signals.Cross[Directions.Short][RSIs.Name].Candle)

   -- print Uturn31
   msg = msg .. "," .. GetSignalFlag(Signals.Uturn31[Directions.Short][Prices.Name].Candle) .. "," .. GetSignalFlag(Signals.Uturn31[Directions.Short][Stochs.Name].Candle) .. "," .. GetSignalFlag(Signals.Uturn31[Directions.Short][RSIs.Name].Candle)

   -- print Utrun32
   msg = msg .. "," .. GetSignalFlag(Signals.Uturn32[Directions.Short][Prices.Name].Candle) .. "," .. GetSignalFlag(Signals.Uturn32[Directions.Short][Stochs.Name].Candle) .. "," .. GetSignalFlag(Signals.Uturn32[Directions.Short][RSIs.Name].Candle)

   -- print TrendOff
   msg = msg .. ",0," .. GetSignalFlag(Signals.TrendOff[Directions.Short][Stochs.Name].Candle) .. ",0"

   -- print Steamer
   msg = msg .. ",0," .. GetSignalFlag(Signals.Steamer[Directions.Short][Stochs.Name].Candle) .. ",0"

   -- priint StrengthOsc
   msg = msg .. ",0," .. GetSignalFlag(Signals.StrengthOsc[Directions.Short][Stochs.Name].Candle) .. "," .. GetSignalFlag(Signals.StrengthOsc[Directions.Short][RSIs.Name].Candle)

   -- print StrengthPrice
   msg = msg .. "," .. GetSignalFlag(Signals.StrengthPrice[Directions.Short][Prices.Name].Candle) .. ",0,0"

   -- print Enter
   msg = msg .. "," .. GetSignalFlag(Signals.Enter[Directions.Short][Prices.Name].Candle) .. ",0,0"

   PrintDebugMessage(msg)
end
--#endregion PRINTS

--==========================================================================
--#region CLASSES
--==========================================================================
----------------------------------------------------------------------------
-- class IndexWindows - saves part of global array _from index with _size
--todo check for duplicates CheckIndex
----------------------------------------------------------------------------
function IndexWindows(_size)
   -- class values
   ------------------------------
   -- Indexes - inner array of indexes, Values - inner array of values, From - starting global index, Size - size of IndexWindow
   local _Windows = { Size = _size, Indexes = {}, Values = {} }

   -- class methods
   -- _index is global candle index on chart,
   -- _idx is local index in IndexWindows: Indexes[_idx] == _index
   ---------------------------------------------------------------
   local function _GetFrom(_self)
      if (_self.Indexes[1] == nil) then
         local from = Size() - 3 * _self.Size
         return ((from > 0) and from or 1)
      else
         return _self.Indexes[1]
      end
   end

   local function _CheckIndexFrom(_self, _index)
      PrintDebugMessage("_CheckIndexFrom", tostring(_self), tostring(_index), tostring(_GetFrom(_self)), tostring(_index >= _GetFrom(_self)))
      return (_index >= _GetFrom(_self))
   end

   -- check index hit inside IndexWindows
   local function _CheckIndex(_self, _index)
      PrintDebugMessage("_CheckIndex", tostring(_self), tostring(_index), tostring(_CheckIndexFrom(_self, _index)), tostring(_index <= _self.Indexes[#_self.Indexes]))
      return (_CheckIndexFrom(_self, _index) and (_index <= _self.Indexes[#_self.Indexes]))
   end

   -- check idx hit inside IndexWindows
   local function _CheckIdx(_self, _idx)
      return ((_idx >= 1) and (_idx <= #_self.Indexes))
   end

   -- get idx by index
   local function _GetIdx(_self, _index)
      if (_CheckIndex(_self, _index) == nil) then
         return  nil
      end
      local idx
      for idx = 1, #_self.Indexes do
         if (_self.Indexes[idx] == _index) then
            return idx
         end
      end
      return nil
      -- return 0
   end

   -- get index by idx
   local function _GetIndex(_self, _idx)
      if (_CheckIdx(_self, _idx) == nil) then
         return nil
      end
      return _self.Indexes[_idx]
   end

   -- get item value with index
   local function _GetItem(_self, _index)
      PrintDebugMessage("GetItem1", tostring(_self), tostring(_index), tostring(_GetIdx(_self, _index)))
      local idx = _GetIdx(_self, _index)
      if (idx == nil) then
         return nil
      end
      PrintDebugMessage("GetItem2", tostring(idx), tostring(_self.Values[idx]))
      return idx, _self.Values[idx]
   end

   -- set item value with index
   local function _SetItem(_self, _index, _value)
      PrintDebugMessage("SetItem1", tostring(_self), tostring(_index), tostring( _value))
      local idx = _GetIdx(_self, _index)
      if (idx == nil) then
         return nil
      end
      _self.Values[idx] = _value
      PrintDebugMessage("SetItem2", tostring(idx), tostring(_self.Values[idx]))
      return idx, _self.Values[idx]
   end

   -- remove item from IndexWindows
   local function _DelItem(_self, _idx)
      local _idx = _idx or 1
      if _CheckIdx(_self, _idx) then
         return nil
      end
      local chart_label_id = _self.Values[_idx]
      local index = _self.Indexes[_idx]
      PrintDebugMessage("DelItem1", tostring(_self), tostring(_GetFrom(_self)), tostring(_GetSize(_self)), tostring(#_self.Indexes), tostring(#_self.Values), tostring(_idx), tostring(index), tostring(chart_label_id))
      -- remove item with curtain idx
      table.remove(_self.Indexes, _idx)
      table.remove(_self.Values, _idx)
      PrintDebugMessage("DelItem2", tostring(_GetFrom(_self)), tostring(_self.Indexes[_idx]), tostring(_self.Values[_idx]), tostring(#_self.Indexes), tostring(#_self.Values))
      return index, chart_label_id
   end


   local function _GetSize(_self)
      return ((#_self.Indexes == #_self.Values) and #_self.Indexes or nil)
   end

   -- add item - store index and value to IndexWindows with checking borders
   local function _AddItem(_self, _index, _value)
      PrintDebugMessage("AddItem1", tostring(_self), tostring(_GetFrom(_self)), tostring(_GetSize(_self)), tostring(#_self.Indexes), tostring(#_self.Values), tostring(_index), tostring(_value))
      if (not _CheckIndexFrom(_self, _index) or not CandleExist(_index)) then
         return nil
      end
      -- append value to end of IndexWindows array
      table.insert(_self.Indexes, _index)
      table.insert(_self.Values, _value)
      if (_GetSize(_self) == 1) then
         _self.From = _self.Indexes[1]
      end
      -- remove first items of IndexWindow array if IndexWindow growth up max Size
      if (_GetSize(_self) > _self.Size) then
         local chart_label_id1, chart_label_id2
         local index = _GetIndex(_self, 1)
         _, chart_label_id1 = _GetItem(_self, index)
         PrintDebugMessage("AddItem2", tostring(chart_label_id), tostring(index), tostring(#_self.Indexes), tostring(#_self.Values), _self.Indexes[#_self.Indexes], _self.Values[#_self.Values])
         _DelItem(_self, 1)
         index = _GetIndex(_self, 1)
         _, chart_label_id2 = _GetItem(_self, index)
         PrintDebugMessage("AddItem3", tostring(chart_label_id), tostring(index), tostring(#_self.Indexes), tostring(#_self.Values), _self.Indexes[#_self.Indexes], _self.Values[#_self.Values])
         return index, chart_label_id1
      end
      -- return _self.Indexes[#_self.Indexes], _self.Values[#_self.Values]
      return 0
   end

   -- class constructor
   --------------------
   -- return clojure
   return function()
      --todo make single metatable for all instances
      -- set metamethods for function overloading and using class object sintax sugar
      setmetatable(_Windows, { __index = { AddItem = _AddItem, SetItem = _SetItem, GetItem = _GetItem, CheckIndexFrom = _CheckIndexFrom }})
      return _Windows
   end
end
--#region CLASSES

--==========================================================================
--#region ADDITIONAL TABLE FUNCTIONS
--==========================================================================
----------------------------------------------------------------------------
-- table.val_to_str
----------------------------------------------------------------------------
function table.val_to_str(v)
   -- if v is string
   if (type(v) == "string")  then
      -- replace \n to \\n
      v = string.gsub(v, "\n", "\\n")
      -- if string have " and not have ' return string wraped in '
      if string.match(string.gsub(v, "[^'\"]", ""), '^"+$') then
         return "'" .. v .. "'"
      end
      -- replace " to \" return result string wraped in "
      return '"' .. string.gsub(v, '"', '\\"') .. '"'
   end
   -- if v is table try it convert to string default return string consist pointer to table
   return (type(v) == "table") and table.tostring(v) or tostring(v)
end

----------------------------------------------------------------------------
-- table.key_to_str
----------------------------------------------------------------------------
function table.key_to_str(k)
   -- if k is string and start with _letter then _letter digit return k
   if ((type(k) =="string") and string.match(k, "^[_%a][_%a%d]*$")) then
      return k
   end
   -- return k converted to string with conversion " and wrapped in ' or " and wraped in []
   return "[" .. table.val_to_str(k) .. "]"
end

----------------------------------------------------------------------------
-- table.tostring
----------------------------------------------------------------------------
function table.tostring(tbl)
   -- if tbl isnt table return tbl with conversion " and wrapped in ' or " and wraped in []
   if (type(tbl) ~= 'table') then
      return table.val_to_str(tbl)
   end

   -- insert value converted to string with integer index to table result
   local result, done = {}, {}
   for k, v in ipairs(tbl) do
      table.insert(result, table.val_to_str(v))
      done[k] = true
   end

   -- insert pairs key=value converted to strings with noninteger index to result table
   for k, v in pairs(tbl) do
      if not done[k] then
         table.insert(result, table.key_to_str(k) .. "=" .. table.val_to_str(v))
      end
   end

   -- return string is concated result table
   return "{" .. table.concat(result, ",") .. "}"
end

----------------------------------------------------------------------------
-- table.load
----------------------------------------------------------------------------
function table.load(fname)
   -- open file to read
   local f, err = io.open(fname, "r")
   if (f == nil) then
      return {}
   end

   -- read table from file and return function returning table
   local _loadfunc
   if (string.match(_VERSION, "(%d.%d)") == "5.1") then
      _loadfunc = loadstring
   else
      _loadfunc = load
   end

   local fn, err = _loadfunc("return " .. f:read("*a"))
   f:close()

   -- call readed function under protected mode
   if (type(fn) == "function") then
      local succ, res = pcall(fn)
      -- return readed table
      if (succ and type(res) == "table") then
         return res
      end
   end
   return {}
end

----------------------------------------------------------------------------
-- table.save
----------------------------------------------------------------------------
function table.save(fname, tbl)
   -- open file to wriet
   local f, err = io.open(fname, "w")
   -- write table converted to string to file
   if (f ~= nil) then
      f:write(table.tostring(tbl))
      f:close()
   end
end
--#endregion TABLE FUNCTIONS
--[[ EOF ]]--
