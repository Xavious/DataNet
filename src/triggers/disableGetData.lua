if datanet.menu.new ~= nil then
  moveCursor("datanet.menu."..datanet.menu.new..".console", 0, 0)
  datanet.menu.tabs[datanet.menu.new] = getCurrentLine("datanet.menu."..datanet.menu.new..".console")
  datanet.load()
  moveCursorEnd("datanet.menu."..datanet.menu.new..".console")
  datanet.menu.new = nil
else
  moveCursor("datanet.menu."..datanet.menu.current..".console", 0, 0)
  datanet.menu.tabs[datanet.menu.current] = getCurrentLine("datanet.menu."..datanet.menu.current..".console")
  datanet.load()
  moveCursorEnd("datanet.menu."..datanet.menu.current..".console")
end
cecho("\n[<cyan>DataNet<reset>] Page loaded. Toggle window display with <yellow>showdata<reset> and <yellow>hidedata<reset>")
cecho("\n[<cyan>DataNet<reset>] Use <red>resetdata<reset> to reset capture triggers if the buffer breaks")

disableTrigger('getData')
disableTrigger('disableGetData')
disableTrigger('multiDisableGetData')
enableTrigger('enableGetData')
datanet.container:show()
datanet.container:raiseAll()