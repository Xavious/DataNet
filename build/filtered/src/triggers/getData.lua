selectCurrentLine()
copy()
--deleteLine()
if datanet.menu.new ~= nil then
  datanet.menu[datanet.menu.new.."console"]:appendBuffer()
else
  datanet.menu[datanet.menu.current.."console"]:appendBuffer()
end