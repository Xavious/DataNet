-- Process captured data and update tab title
local target_tab_id = datanet.state.new_tab or datanet.state.current
local console = datanet.helpers.getTabConsole(target_tab_id)

if console then
  local console_name = datanet.helpers.getTabConsoleName(target_tab_id)
  moveCursor(console_name, 0, 0)
  datanet.state.tabs[target_tab_id] = getCurrentLine(console_name)

  -- Record this page visit in history
  local page_title = getCurrentLine(console_name)

  -- Use the colored content captured during getData trigger
  local content = nil
  if datanet.temp_capture and datanet.temp_capture[target_tab_id] then
    content = datanet.temp_capture[target_tab_id]
    -- Clear the temporary capture for this tab
    datanet.temp_capture[target_tab_id] = nil
    debugc("Using colored content from temp_capture, " .. tostring(#content) .. " lines")
  else
    -- Fallback to plain text if no colored content available
    local line_count = console:getLineCount()
    content = console:getLines(1, line_count)
    debugc("Fallback to plain text content, " .. tostring(#content) .. " lines")
  end
  debugc("Recording page visit - Title: " .. tostring(page_title))
  debugc("Line count: " .. tostring(line_count))
  debugc("Content type: " .. type(content))
  if type(content) == "table" then
    debugc("Content table size: " .. #content)
    for k, v in pairs(content) do
      debugc("Content[" .. tostring(k) .. "] = " .. tostring(v))
    end
  end
  datanet.recordPageVisit(target_tab_id, page_title, content, datanet.current_command or "datanet")

  -- Update tab title (requires reload for now)
  datanet.load()

  moveCursorEnd(console_name)
end

-- Clear new tab flag
datanet.state.new_tab = nil
cecho("\n[<cyan>DataNet<reset>] Page loaded. Toggle window display with <yellow>showdata<reset> and <yellow>hidedata<reset>")
cecho("\n[<cyan>DataNet<reset>] Use <red>resetdata<reset> to reset capture triggers if the buffer breaks")

disableTrigger('getData')
disableTrigger('disableGetData')
disableTrigger('enableDisableGetData')
enableTrigger('enableGetData')
datanet.container:show()
datanet.container:raiseAll()