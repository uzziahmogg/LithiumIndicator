Settings={ Name = "FEK_minimal" }

function Init()
	sz1 = Size()
	sz2 = getNumCandles ("FEK_LITHIUMPrice")
	Pass = 0
	return 1
end

function OnCalculate(index)
	if (index == 1) then
		Pass = Pass + 1
	end
	PrintDbgStr("quik:" .. index .. "/Pass:" .. Pass .. "/sz1:".. sz1 .. "/sz2:" .. sz2)
	return 50/sz1
end
