if datanet.menu.new ~= nil then
  datanet.menu[datanet.menu.new.."console"]:clear()
else
  datanet.menu[datanet.menu.current.."console"]:clear()
end

enableTrigger('getData')
enableTrigger('enableDisableGetData')
enableTrigger('multiDisableGetData')
disableTrigger('enableGetData')