Settings={ Name = "FEK_minimal" }

function Init()
	sz1 = Size()
	sz2 = getNumCandles ("FEK_LITHIUMPrice")
	return 1
end

function OnCalculate(index)
	PrintDbgStr("quik:" .. index .. "/sz1:".. sz1 .. "/sz2:" .. sz2)
	return 50/sz1
end
