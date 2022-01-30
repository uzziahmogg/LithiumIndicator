signals = "Cross50" .. ",,," .. "Cross" .. ",,," .. "Uturn31" .. ",,," .. "Uturn32" .. ",,," .. "TrendOff" .. ",,," .. "Steamer" .. ",,," .. "StrengthOsc" .. ",,," .. "StrengthPrice" .. ",,," .. "Enter"  .. ",,,"
oscs = "Prices" .. "," .. "Stochs" .. "," .. "RSIs"
msg1 = ",,,,,," .. "L" .. ",,,,,,,,,,,,,,,,,,,,,,,,,,," .. "S"
msg2 = ",,,,,," .. signals .. signals
msg3 = "Index,Year,Month,Day,Hour,Min," .. oscs .. "," .. oscs .. "," .. oscs .. "," .. oscs .. "," .. oscs .. "," .. oscs .. "," .. oscs .. "," .. oscs .. "," .. oscs .. "," .. oscs .. "," .. oscs .. "," .. oscs .. "," .. oscs .. "," .. oscs .. "," .. oscs .. "," .. oscs .. "," .. oscs .. "," .. oscs
print(msg1.."\n" .. msg2 .. "\n" .. msg3)
