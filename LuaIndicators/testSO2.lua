Settings = {	Name = "FEK_test_2STOCH", 
				line = {{	Name 	= "StochSlow", 
							Type 	= TYPE_LINE, 
							Color 	= RGB(255, 68, 68)	},
                        {	Name 	= "StochFast", 
							Type 	= TYPE_LINE, 
							Color 	= RGB(255, 208, 96)	},
						{	Name 	= "HL Top",
							Type 	= TYPE_LINE, 
							Color 	= RGB(0, 206, 0),
							Value 	= 80	            },
						{	Name 	= "HL Centre",
							Type 	= TYPE_DASHDOT, 
							Color 	= RGB(140, 140, 140),
							Value 	= 50                },
						{	Name 	= "HL Bottom",
							Type 	= TYPE_LINE, 
							Color 	= RGB(221, 44, 44),
							Value 	= 20	            }}}
			
--[[--------------------------------------------------------------------------
--  --------------------------------------------------------------------------]]							
function Init()
	ScriptPath = getScriptPath()

    ChartTag = { Stoch = Settings.Name .. "Stoch", Price = Settings.Name .. "Price", RSI = Settings.Name .. "RSI" }

    LabelParams = { R = 255, G = 255, B = 255,
                    TRANSPARENCY = 0, TRANSPARENT_BACKGROUND = 1,
                    FONT_FACE_NAME = "Arial", FONT_HEIGHT = 8 }

    StochParams = { Levels = { Top = 80, Center = 50, Bottom = 20 },
                    Slow = { PeriodK = 10, Shift = 3, PeriodD = 1 },
                    Fast = { PeriodK = 5, Shift = 2, PeriodD = 1 } }

    
	MAParameters = { Period = 20,  Shift = 2 }

    Directions = { Up = "Up", Down = "Down" }

    StochSignals = { TrendOn = 0, TrendOff = 0, Cross50 = 0, Cross = 0, Spring = 0, LightPullback = 0, NirmalPullback = 0, DeepPullback = 0 }
    PriceSignals = {}
    RSISignals = {}

    FuncBB = BolBands()
	FuncStochSlow = Stoch("SLOW")
	FuncStochFast = Stoch("FAST")
  
	return #Settings.line
end

--[[--------------------------------------------------------------------------
--  --------------------------------------------------------------------------]]
function OnCalculate(index_candle) 
    --message(index_candle)
    return 10, 70, StochParams.Levels.Top, StochParams.Levels.Center, StochParams.Levels.Bottom
end

function BolBands()
end

function Stoch(a)
end

