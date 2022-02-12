--[[
*******************************************************************
Функция для сохранения произвольной таблицы (инструменты, сделки,
заявки и т.п.) в файл. В качестве параметра принимает тэг, хендл
файла (после открытия с помощью io.open) и таблицу.
Пример вызова функции:
   table_save("orders", file, trans_result)
*******************************************************************
]]

--
-- export string in readable format
--
function exportstring(s)
   return string.format("%q", s)
end

function table_save(tag, file, tbl)
   local charS, charE = "   ", "\n"
   local tables, lookup = { tbl }, { [tbl] = 1 }

   file:write(charE .. tag .. "{" .. charE)

   -- cycle over integer indexes in tbl
   for idx, t in ipairs(tables) do
      file:write(charS .. "Table: {" .. idx .. "}" .. charE .. "{" .. charE)
      -- processed integer indexed items
      local thandled = {}

      -- cycle over integer indexes in inner table
      for i, v in ipairs(t) do
         thandled[i] = true

         local stype = type(v)
         if (stype == "table") then
            if (not lookup[v]) then
               table.insert(tables, v)
               lookup[v] = #tables
            end
            file:write(charS .. "{" .. lookup[v] .. "}," .. charE)

         elseif (stype == "string") then
            file:write(charS .. exportstring(v) .."," .. charE)

         elseif (stype == "number") then
            file:write(charS .. tostring(v) .. "," .. charE)
         end
      end

      -- cycle over noninteger indexes in inner table
      for k, v in pairs(t) do
         if (not thandled[k]) then
            local str = ""

            local stype = type(k)
            if (stype == "table") then
               if (not lookup[k]) then
                  table.insert(tables, k)
                  lookup[k] = #tables
               end
               str = charS .. "[{" .. lookup[k] .. "}]="

            elseif (stype == "string") then
               str = charS .. "[" .. exportstring(k) .. "]="

            elseif (stype == "number") then
               str = charS .. "[" .. tostring(k) .. "]="
            end

            if (str ~= "") then

               stype = type(v)
               if (stype == "table") then
                  if (not lookup[v]) then
                     table.insert(tables, v)
                     lookup[v] = #tables
                  end
                  file:write(str .. "{" .. lookup[v] .. "}," .. charE)

               elseif (stype == "string") then
                  file:write(str .. exportstring(v) .. "," .. charE)

               elseif (stype == "number") then
                  file:write(str .. tostring(v) .. "," .. charE)
               end
            end
         end
      end
      file:write("}," .. charE)
   end
   file:write("}" .. charE)
end
