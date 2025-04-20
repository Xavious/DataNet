datanet = {}
datanet.font_size = 14
datanet.menu = {}
datanet.menu.x = {}
datanet.menu.a = {}
datanet.menu.tabs = {""}
datanet.menu.count = 1
datanet.menu.current = 1
datanet.menu.last = 1
datanet.menu.adjLabelstyle = [[
  border: 1px solid rgb(32,34,37);
  background-color: rgb(54, 57, 63);
]]
datanet.menu.buttonStyle = [[
  QLabel{ background-color: rgba(32,34,37,100%);}
  QLabel::hover{ background-color: rgba(40,43,46,100%);}
]]
datanet.menu.buttonFontSize = 10

datanet.button_style =[[
  QLabel{background-color: rgba(88,101,242,100%)}
  QLabel::hover{ background-color: rgba(71,82,196,100%);}
  color: rgb(216,217,218)
  margin-right: 1px;
  margin-left: 1px;
  border-top-left-radius: 5px;
  border-top-right-radius: 5px;
]]
datanet.button_style_clicked =[[
  QLabel{background-color: rgba(71,82,196,100%)}
  QLabel::hover{ background-color: rgba(71,82,196,100%);}
  color: rgb(216,217,218)
  margin-right: 1px;
  margin-left: 1px;
  border-top-left-radius: 5px;
  border-top-right-radius: 5px;
]]
datanet.button_style_x =[[
  QLabel{background-color: rgba(88,101,242,100%)}
  QLabel::hover{ background-color: rgba(231,70,56,100%);}
  color: rgb(216,217,218)
  margin-right: 1px;
  margin-left: 1px;
  border-top-left-radius: 5px;
  border-top-right-radius: 5px;
]]

datanet.button_style_a = [[
  QLabel{background-color: rgba(88,101,242,100%)}
  QLabel::hover{ background-color: rgba(70,196,110,100%);}
  color: rgb(216,217,218)
  margin-right: 1px;
  margin-left: 1px;
  border-top-left-radius: 5px;
  border-top-right-radius: 5px;
]]
datanet.input_style =[[
  QPlainTextEdit{
    border: 1px solid rgb(32,34,37);
    background-color: rgb(64,68,75);
    font: bold 12pt "Arial";
    color: rgb(255,255,255);
  }
]]
datanet.label_style =[[
  border: 1px solid rgb(32,34,37);
  background-color: rgb(47,49,54);
  font: bold 20pt "Arial";
  color: rgb(0,0,0);
  qproperty-alignment: 'AlignVCenter|AlignRight';
]]

datanet.container = Adjustable.Container:new({
  name = "datanet_container",
  titleText = "DataNet",
  titleTxtColor = "white",
  x = "-45%", y = "0%",
  width = "45%", height = "100%",
  adjLabelstyle = datanet.menu.adjLabelstyle,
  buttonstyle = datanet.menu.buttonStyle,
  buttonFontSize = 10,
  buttonsize = 20,
  padding = 10
})

function datanet.load()

  datanet.menu.header = Geyser.HBox:new({
    name = "datamem.menu.header",
    x = 0, y = "3%",
    width = "100%", height = "5%" 
  }, datanet.container)
  
  datanet.menu.footer = Geyser.Container:new({
    name = "datamem.menu.footer",
    x = 0, y = "8%",
    width = "100%",
    height = "90%"
  },datanet.container)
  
  for k,v in pairs(datanet.menu.tabs) do
    datanet.menu[k.."tab"] = Geyser.Label:new({
      name = "datanet.menu."..k..".tab",
    }, datanet.menu.header)
    datanet.menu[k.."tab"]:setStyleSheet(datanet.button_style)
    datanet.menu[k.."tab"]:echo("<center>"..v)
    datanet.menu[k.."tab"]:setClickCallback("datanet.menu.click",k)
    datanet.menu[k.."tab"]:show()
    
    if k ~= 1 then
      datanet.menu[k.."tabx"] = Geyser.Label:new({
        x = "-25px", y = 0,
        width = "25px",
        height = "100%",
        name = "datanet.menu."..k..".tabx",
        message = "<center>X"
      }, datanet.menu[k.."tab"])
      datanet.menu[k.."tabx"]:setStyleSheet(datanet.button_style_x)
      datanet.menu[k.."tabx"]:setClickCallback("datanet.menu.x.click",k)  
    else
      datanet.menu[k.."taba"] = Geyser.Label:new({
        x = 0, y = 0,
        width = "25px",
        height = "100%",
        name = "datanet.menu."..k..".taba",
        message = "<center>+"
      }, datanet.menu[k.."tab"])
      datanet.menu[k.."taba"]:setStyleSheet(datanet.button_style_a)
      datanet.menu[k.."taba"]:setClickCallback("datanet.menu.a.click",k)
    end
    
    datanet.menu[k] = Geyser.Container:new({
      name = "datanet.menu."..k,
      x = 0, y = 0,
      width = "100%",
      height = "100%",
    }, datanet.menu.footer)
    
    datanet.menu[k.."console"] = Geyser.MiniConsole:new({
      name = "datanet.menu."..k..".console",
      x = 0, y = 0,
      width = "100%", height = "100%",
      autoWrap = true,
      color = "black",
      scrollBar = true,
      fontSize = datanet.font_size,
    }, datanet.menu[k])
    
    datanet.menu[k]:hide()
  end
  datanet.menu.setCurrent(datanet.menu.current)
  datanet.menu[datanet.menu.current]:show()
  
end

function datanet.menu.setCurrent(key)
  datanet.menu[datanet.menu.current]:hide()
  datanet.menu[datanet.menu.current.."tab"]:setStyleSheet(datanet.button_style)
  datanet.menu[key.."tab"]:setStyleSheet(datanet.button_style_clicked)
  datanet.menu.last = datanet.menu.current
  datanet.menu.current = key
  datanet.menu[datanet.menu.current]:show()
end
  
function datanet.menu.click(key)
  datanet.menu.setCurrent(key)
end

function datanet.menu.x.click(key)
  if key == datanet.menu.current then
    if datanet.menu.tabs[datanet.menu.last] ~= nil and datanet.menu.current ~= datanet.menu.last then
      datanet.menu.setCurrent(datanet.menu.last)
    else
      datanet.menu.setCurrent(1)
    end
  end

  datanet.menu.tabs[key] = nil
  datanet.menu[key]:hide()
  datanet.menu[key] = nil
  datanet.menu[key.."tab"]:hide()
  datanet.menu[key.."tab"] = nil
  datanet.menu[key.."taba"] = nil
  datanet.menu[key.."tabx"] = nil
  datanet.menu[key.."console"]:clear()
  datanet.menu[key.."console"]:hide()
  datanet.menu[key.."console"] = nil
  
  datanet.load()
end

function datanet.menu.a.click()
  datanet.addTab()
end

function datanet.addTab(new)
  datanet.menu.count = datanet.menu.count + 1
  table.insert(datanet.menu.tabs, datanet.menu.count, "")
  if new ~= nil then
    datanet.menu.new = datanet.menu.count
  end
  datanet.load()
end

datanet.load()
datanet.container:hide()