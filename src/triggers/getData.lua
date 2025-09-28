selectCurrentLine()
copy()


-- Append data to the target tab first (normal process)
local target_tab_id = datanet.state.new_tab or datanet.state.current
local console = datanet.helpers.getTabConsole(target_tab_id)
if console then
  console:appendBuffer()
end

-- Now capture formatted version for history (after normal processing)
selectCurrentLine()
local colored_line = copy2decho()
--deleteLine()

-- Store the colored line for history (accumulate during capture)
if not datanet.temp_capture then
  datanet.temp_capture = {}
end
if not datanet.temp_capture[target_tab_id] then
  datanet.temp_capture[target_tab_id] = {}
end
table.insert(datanet.temp_capture[target_tab_id], colored_line)