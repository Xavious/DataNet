-- DataNet: Tabbed MUD Data Browser
datanet = {}

-- Configuration
datanet.config = {
  font_size = 14,
  container = {
    x = "-45%", y = "0%",
    width = "45%", height = "100%"
  },
  layout = {
    tabs_height = "5%",
    tabs_y = "3%",
    nav_height = "4%",
    nav_y = "8%",
    content_y = "8%",
    content_height = "92%",
    tab_spacing = "1px"
  }
}

-- Centralized Styling System
datanet.styles = {
  -- Container styles
  container = {
    adjLabelstyle = [[
      border: 1px solid rgb(32,34,37);
      background-color: rgb(54, 57, 63);
    ]],
    buttonStyle = [[
      QLabel{ background-color: rgba(32,34,37,100%);}
      QLabel::hover{ background-color: rgba(40,43,46,100%);}
    ]]
  },

  -- Tab button styles
  tab = {
    normal = [[
      QLabel{background-color: rgba(88,101,242,100%)}
      QLabel::hover{ background-color: rgba(71,82,196,100%);}
      color: rgb(216,217,218);
      margin-right: 1px;
      margin-left: 1px;
      border-top-left-radius: 5px;
      border-top-right-radius: 5px;
    ]],
    active = [[
      QLabel{background-color: rgba(71,82,196,100%)}
      QLabel::hover{ background-color: rgba(71,82,196,100%);}
      color: rgb(216,217,218);
      margin-right: 1px;
      margin-left: 1px;
      border-top-left-radius: 5px;
      border-top-right-radius: 5px;
    ]],
    close_button = [[
      QLabel{background-color: rgba(88,101,242,100%)}
      QLabel::hover{ background-color: rgba(231,70,56,100%);}
      color: rgb(216,217,218);
      margin-right: 1px;
      margin-left: 1px;
      border-top-left-radius: 5px;
      border-top-right-radius: 5px;
    ]],
    add_button = [[
      QLabel{background-color: rgba(88,101,242,100%)}
      QLabel::hover{ background-color: rgba(70,196,110,100%);}
      color: rgb(216,217,218);
      margin-right: 1px;
      margin-left: 1px;
      border-top-left-radius: 5px;
      border-top-right-radius: 5px;
    ]]
  },

  -- Content styles
  content = {
    input = [[
      QPlainTextEdit{
        border: 1px solid rgb(32,34,37);
        background-color: rgb(64,68,75);
        font: bold 12pt "Arial";
        color: rgb(255,255,255);
      }
    ]],
    label = [[
      border: 1px solid rgb(32,34,37);
      background-color: rgb(47,49,54);
      font: bold 20pt "Arial";
      color: rgb(0,0,0);
      qproperty-alignment: 'AlignVCenter|AlignRight';
    ]]
  }
}

-- State Management
datanet.state = {
  tabs = {""},
  count = 1,
  current = 1,
  last = 1,
  new_tab = nil,

  -- History tracking for each tab
  history = {
    -- Structure: [tab_id] = { entries = {...}, current_index = 1, max_size = 50 }
    -- Each entry: { title = "page title", content = "cached content", timestamp = os.time(), command = "datanet xyz" }
  }
}

-- UI Element References
datanet.ui = {}

-- Helper Functions
datanet.helpers = {
  -- Generate consistent element names
  getTabName = function(id) return "datanet.tab." .. id end,
  getTabButtonName = function(id) return "datanet.tab." .. id .. ".button" end,
  getTabCloseName = function(id) return "datanet.tab." .. id .. ".close" end,
  getTabContainerName = function(id) return "datanet.tab." .. id .. ".container" end,
  getTabConsoleName = function(id) return "datanet.tab." .. id .. ".console" end,

  -- Element access shortcuts
  getTab = function(id) return datanet.ui["tab_" .. id] end,
  getTabButton = function(id) return datanet.ui["tab_button_" .. id] end,
  getTabClose = function(id) return datanet.ui["tab_close_" .. id] end,
  getTabContainer = function(id) return datanet.ui["tab_container_" .. id] end,
  getTabConsole = function(id) return datanet.ui["tab_console_" .. id] end,

  -- State helpers
  isValidTab = function(id) return datanet.state.tabs[id] ~= nil end,
  getCurrentTab = function() return datanet.state.current end,
  getTabCount = function() return datanet.state.count end,

  -- History helpers
  initTabHistory = function(id)
    if not datanet.state.history[id] then
      datanet.state.history[id] = {
        entries = {},
        current_index = 0,
        max_size = 50
      }
      debugc("Initialized new history for tab " .. tostring(id))
    else
      debugc("History already exists for tab " .. tostring(id) .. ", preserving it")
    end
  end,

  addHistoryEntry = function(id, title, content, command)
    debugc("addHistoryEntry called for tab " .. tostring(id))
    local history = datanet.state.history[id]
    if not history then
      debugc("No history found, initializing for tab " .. tostring(id))
      datanet.helpers.initTabHistory(id)
      history = datanet.state.history[id]
    end

    -- Create new entry
    local entry = {
      title = title or "Untitled",
      content = content or "",
      timestamp = os.time(),
      command = command or ""
    }

    -- Remove any forward history (like browsers do)
    for i = history.current_index + 1, #history.entries do
      history.entries[i] = nil
    end

    -- Add new entry
    table.insert(history.entries, entry)
    history.current_index = #history.entries
    debugc("Added history entry. Total entries: " .. tostring(#history.entries))
    debugc("Current index: " .. tostring(history.current_index))

    -- Limit history size
    if #history.entries > history.max_size then
      table.remove(history.entries, 1)
      history.current_index = history.current_index - 1
    end
  end,

  canGoBack = function(id)
    local history = datanet.state.history[id]
    debugc("canGoBack check for tab " .. tostring(id))
    if not history then
      debugc("No history found")
      return false
    end
    debugc("History found. Current index: " .. tostring(history.current_index) .. ", Total entries: " .. tostring(#history.entries))
    return history.current_index > 1
  end,

  canGoForward = function(id)
    local history = datanet.state.history[id]
    return history and history.current_index < #history.entries
  end,

  getCurrentHistoryEntry = function(id)
    local history = datanet.state.history[id]
    if history and history.current_index > 0 then
      return history.entries[history.current_index]
    end
    return nil
  end
}

-- Create main container
datanet.container = Adjustable.Container:new({
  name = "datanet_container",
  titleText = "DataNet",
  titleTxtColor = "white",
  x = datanet.config.container.x,
  y = datanet.config.container.y,
  width = datanet.config.container.width,
  height = datanet.config.container.height,
  adjLabelstyle = datanet.styles.container.adjLabelstyle,
  buttonstyle = datanet.styles.container.buttonStyle,
  buttonFontSize = 10,
  buttonsize = 20,
  padding = 10
})

-- Navigation Functions
function datanet.goBack()
  debugc("datanet.goBack() called")
  local current_id = datanet.state.current
  if not datanet.helpers.canGoBack(current_id) then
    debugc("Cannot go back - no history available")
    return
  end

  local history = datanet.state.history[current_id]
  history.current_index = history.current_index - 1

  local entry = history.entries[history.current_index]
  if entry then
    -- Restore content from history
    local console = datanet.helpers.getTabConsole(current_id)
    local console_name = datanet.helpers.getTabConsoleName(current_id)
    if console then
      console:clear()
      if type(entry.content) == "table" then
        for _, line in ipairs(entry.content) do
          -- Echo line normally for testing
          decho(console_name, line .. "\n")
        end
      else
        -- Echo single content normally for testing
        decho(console_name, entry.content .. "\n")
      end
    end

    -- Update tab title
    datanet.state.tabs[current_id] = entry.title

    -- Reload to update display
    datanet.load()
  end

  datanet.updateNavigationState(current_id)
end

-- Echo a line to console, replacing datanet links with clickable links
function datanet.echoLineWithLinks(console_name, line)
  if not line or type(line) ~= "string" then return end

  debugc("echoLineWithLinks called with line: " .. line)

  -- Simple pattern to find datanet links
  local link_pattern = "([A-Za-z][A-Za-z]*:[/][%w/_%.-]+)"

  -- Check if line contains any links
  local has_links = string.match(line, link_pattern)

  if has_links then
    debugc("Line contains links, processing...")
    local processed_line = line

    -- Remove all links from the line
    for link in string.gmatch(line, link_pattern) do
      debugc("Found link: '" .. link .. "'")
      processed_line = string.gsub(processed_line, link, "", 1)
    end

    -- Echo the line without links
    decho(console_name, processed_line)

    -- Add clickable underlined links
    for link in string.gmatch(line, link_pattern) do
      local clickable_text = "<u>" .. link .. "</u>"
      local command = [[send("datanet ]] .. link .. [[")]]
      debugc("Creating clickable link - Text: '" .. clickable_text .. "', Command: '" .. command .. "'")
      dechoLink(console_name, clickable_text, command, link, true)
    end

    echo(console_name, "\n")
  else
    debugc("No links found in line, echoing normally")
    -- No links, just echo the line normally
    decho(console_name, line .. "\n")
  end
end

function datanet.refresh()
  debugc("datanet.refresh() called")
  local current_id = datanet.state.current
  local history = datanet.state.history[current_id]

  if history and history.current_index > 0 then
    local current_entry = history.entries[history.current_index]
    if current_entry and current_entry.command then
      debugc("Executing refresh command: " .. current_entry.command)
      send(current_entry.command)
    else
      debugc("No command found for current page")
    end
  else
    debugc("No history available for refresh")
  end
end

function datanet.goForward()
  debugc("datanet.goForward() called")
  local current_id = datanet.state.current
  if not datanet.helpers.canGoForward(current_id) then
    debugc("Cannot go forward - no history available")
    return
  end

  local history = datanet.state.history[current_id]
  history.current_index = history.current_index + 1

  local entry = history.entries[history.current_index]
  if entry then
    -- Restore content from history
    local console = datanet.helpers.getTabConsole(current_id)
    local console_name = datanet.helpers.getTabConsoleName(current_id)
    if console then
      console:clear()
      if type(entry.content) == "table" then
        for _, line in ipairs(entry.content) do
          -- Echo line normally for testing
          decho(console_name, line .. "\n")
        end
      else
        -- Echo single content normally for testing
        decho(console_name, entry.content .. "\n")
      end
    end

    -- Update tab title
    datanet.state.tabs[current_id] = entry.title

    -- Reload to update display
    datanet.load()
  end

  datanet.updateNavigationState(current_id)
end

function datanet.load()
  -- Create navigation buttons on the left side of tabs area
  datanet.ui.back_button = Geyser.Label:new({
    name = "datanet.back_button",
    x = 0,
    y = datanet.config.layout.tabs_y,
    width = "3%",
    height = datanet.config.layout.tabs_height
  }, datanet.container)
  datanet.ui.back_button:setStyleSheet(datanet.styles.tab.normal)
  datanet.ui.back_button:echo("<center>◀")
  datanet.ui.back_button:setClickCallback("datanet.goBack")
  datanet.ui.back_button:show()

  datanet.ui.forward_button = Geyser.Label:new({
    name = "datanet.forward_button",
    x = "3%",
    y = datanet.config.layout.tabs_y,
    width = "3%",
    height = datanet.config.layout.tabs_height
  }, datanet.container)
  datanet.ui.forward_button:setStyleSheet(datanet.styles.tab.normal)
  datanet.ui.forward_button:echo("<center>▶")
  datanet.ui.forward_button:setClickCallback("datanet.goForward")
  datanet.ui.forward_button:show()

  datanet.ui.refresh_button = Geyser.Label:new({
    name = "datanet.refresh_button",
    x = "6%",
    y = datanet.config.layout.tabs_y,
    width = "3%",
    height = datanet.config.layout.tabs_height
  }, datanet.container)
  datanet.ui.refresh_button:setStyleSheet(datanet.styles.tab.normal)
  datanet.ui.refresh_button:echo("<center>↻")
  datanet.ui.refresh_button:setClickCallback("datanet.refresh")
  datanet.ui.refresh_button:show()

  -- Create tabs container for tab buttons (adjusted for navigation buttons)
  datanet.ui.tabs = Geyser.HBox:new({
    name = "datanet.tabs",
    x = "9%", -- Start after navigation buttons (3% + 3% + 3%)
    y = datanet.config.layout.tabs_y,
    width = "87%", -- 96% - 9% nav buttons = 87% for tabs
    height = datanet.config.layout.tabs_height
  }, datanet.container)

  -- Create content container for tab content
  datanet.ui.content = Geyser.Container:new({
    name = "datanet.content",
    x = 0,
    y = datanet.config.layout.content_y,
    width = "100%",
    height = datanet.config.layout.content_height
  }, datanet.container)

  -- Create tabs using tab system
  for k, v in pairs(datanet.state.tabs) do
    datanet.createTab(k, v)
  end

  -- Create add button
  datanet.ui.add_button = Geyser.Label:new({
    name = "datanet.add_button",
    x = "96%",
    y = datanet.config.layout.tabs_y,
    width = "4%",
    height = datanet.config.layout.tabs_height
  }, datanet.container)
  datanet.ui.add_button:setStyleSheet(datanet.styles.tab.add_button)
  datanet.ui.add_button:echo("<center>✚")
  datanet.ui.add_button:setClickCallback("datanet.addTab")
  datanet.ui.add_button:show()

  -- Set current tab
  datanet.setCurrent(datanet.state.current)
end

-- Create a single tab with all its components
function datanet.createTab(id, content)
  content = content or ""

  -- Initialize history for this tab
  datanet.helpers.initTabHistory(id)

  -- Create tab button
  local tab_button = Geyser.Label:new({
    name = datanet.helpers.getTabButtonName(id)
  }, datanet.ui.tabs)
  tab_button:setStyleSheet(datanet.styles.tab.normal)
  tab_button:echo("<center>" .. content)
  tab_button:setClickCallback("datanet.selectTab", id)
  tab_button:show()
  datanet.ui["tab_button_" .. id] = tab_button

  -- Create close button for tabs other than first
  if id ~= 1 then
    local close_button = Geyser.Label:new({
      x = "-25px", y = 0,
      width = "25px", height = "100%",
      name = datanet.helpers.getTabCloseName(id),
      message = "<center>✕"
    }, tab_button)
    close_button:setStyleSheet(datanet.styles.tab.close_button)
    close_button:setClickCallback("datanet.closeTab", id)
    datanet.ui["tab_close_" .. id] = close_button
  end

  -- Create tab container
  local tab_container = Geyser.Container:new({
    name = datanet.helpers.getTabContainerName(id),
    x = 0, y = 0,
    width = "100%", height = "100%"
  }, datanet.ui.content)
  tab_container:hide()
  datanet.ui["tab_container_" .. id] = tab_container

  -- Create console
  local console = Geyser.MiniConsole:new({
    name = datanet.helpers.getTabConsoleName(id),
    x = 0, y = 0,
    width = "100%", height = "100%",
    autoWrap = true,
    color = "black",
    scrollBar = true,
    fontSize = datanet.config.font_size
  }, tab_container)
  datanet.ui["tab_console_" .. id] = console
end

-- Set current tab with proper styling
function datanet.setCurrent(id)
  if not datanet.helpers.isValidTab(id) then
    id = 1 -- fallback
  end

  -- Hide current tab
  local current_container = datanet.helpers.getTabContainer(datanet.state.current)
  if current_container then
    current_container:hide()
  end

  -- Update button styling
  local current_button = datanet.helpers.getTabButton(datanet.state.current)
  if current_button then
    current_button:setStyleSheet(datanet.styles.tab.normal)
  end

  local new_button = datanet.helpers.getTabButton(id)
  if new_button then
    new_button:setStyleSheet(datanet.styles.tab.active)
  end

  -- Update state
  datanet.state.last = datanet.state.current
  datanet.state.current = id

  -- Show new tab
  local new_container = datanet.helpers.getTabContainer(id)
  if new_container then
    new_container:show()
  end

  -- Update navigation buttons and address bar
  datanet.updateNavigationState(id)
end

-- Tab selection callback
function datanet.selectTab(id)
  datanet.setCurrent(id)
end

-- Add new tab without full rebuild
function datanet.addTab(open_in_new)
  datanet.state.count = datanet.state.count + 1
  local new_id = datanet.state.count

  -- Add to state
  datanet.state.tabs[new_id] = ""
  if open_in_new then
    datanet.state.new_tab = new_id
  end

  -- Create only the new tab (incremental update)
  datanet.createTab(new_id, "")

  -- Switch to new tab if requested
  if open_in_new then
    datanet.setCurrent(new_id)
  end
end

-- Close tab with proper cleanup
function datanet.closeTab(id)
  if not datanet.helpers.isValidTab(id) then
    return
  end

  -- Switch away from tab being closed
  if id == datanet.state.current then
    if datanet.helpers.isValidTab(datanet.state.last) and datanet.state.current ~= datanet.state.last then
      datanet.setCurrent(datanet.state.last)
    else
      datanet.setCurrent(1)
    end
  end

  -- Clean up UI elements
  datanet.cleanupTab(id)

  -- Clean up history for this tab
  if datanet.state.history[id] then
    datanet.state.history[id] = nil
    debugc("Cleaned up history for tab " .. tostring(id))
  end

  -- Update state
  datanet.state.tabs[id] = nil

  -- Rebuild only if necessary
  datanet.load()
end

-- Cleanup function for proper memory management
function datanet.cleanupTab(id)
  local elements = {
    datanet.ui["tab_button_" .. id],
    datanet.ui["tab_close_" .. id],
    datanet.ui["tab_container_" .. id],
    datanet.ui["tab_console_" .. id]
  }

  for _, element in ipairs(elements) do
    if element then
      element:hide()
      -- Note: Geyser elements are automatically cleaned up by Mudlet
    end
  end

  -- Clear references
  datanet.ui["tab_button_" .. id] = nil
  datanet.ui["tab_close_" .. id] = nil
  datanet.ui["tab_container_" .. id] = nil
  datanet.ui["tab_console_" .. id] = nil
end


-- Update navigation button states and address bar
function datanet.updateNavigationState(tab_id)
  tab_id = tab_id or datanet.state.current

  -- Update back button
  if datanet.helpers.canGoBack(tab_id) then
    datanet.ui.back_button:setStyleSheet(datanet.styles.tab.normal)
  else
    datanet.ui.back_button:setStyleSheet(datanet.styles.tab.active)
  end

  -- Update forward button
  if datanet.helpers.canGoForward(tab_id) then
    datanet.ui.forward_button:setStyleSheet(datanet.styles.tab.normal)
  else
    datanet.ui.forward_button:setStyleSheet(datanet.styles.tab.active)
  end

end

-- Record a new page visit (called by triggers)
function datanet.recordPageVisit(tab_id, title, content, command)
  debugc("datanet.recordPageVisit called with tab_id: " .. tostring(tab_id))
  debugc("Title: " .. tostring(title))
  debugc("Command: " .. tostring(command))
  tab_id = tab_id or datanet.state.current

  -- Add to history
  datanet.helpers.addHistoryEntry(tab_id, title, content, command)

  -- Update navigation state
  datanet.updateNavigationState(tab_id)
end

-- Initialize DataNet
datanet.load()
datanet.container:hide()

