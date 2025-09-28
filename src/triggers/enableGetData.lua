-- Clear console for the target tab (new tab or current tab)
local target_tab_id = datanet.state.new_tab or datanet.state.current
local console = datanet.helpers.getTabConsole(target_tab_id)
if console then
  console:clear()
end

-- Parse and reconstruct the datanet command
local protocol = matches.protocol
local path = matches.path
datanet.current_command = "datanet " .. protocol .. ":" .. path
debugc("Reconstructed command: " .. tostring(datanet.current_command))

enableTrigger('getData')
enableTrigger('enableDisableGetData')
disableTrigger('enableGetData')