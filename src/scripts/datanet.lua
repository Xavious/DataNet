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
  },
  cache = {
    max_entries = 200
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
    -- Each entry: { url = "news:/foo", title = "page title", timestamp = os.time(), command = "datanet news:/foo" }
    -- Entries hold no content; it lives in state.cache keyed by url. Pre-phase-3
    -- entries kept content inline, which datanet.helpers.getEntryContent still reads.
  },

  -- Page cache, keyed by url. The index UI lists this, and it is what makes
  -- offline browsing possible. Separate from history because history is a
  -- navigation stack: it truncates forward entries and caps at max_size, so it
  -- loses pages through normal browsing.
  -- Revisiting a url overwrites its content, so going back to an older visit of
  -- the same url shows the newer body. Browsers behave the same way.
  cache = {
    -- Structure: [url] = { title = "page title", content = {...}, timestamp = os.time() }
  }
}

-- Per-character session archive, keyed by character name. Populated from disk by
-- datanet.loadSessions() during init, so it outlives both character swaps and
-- client restarts.
datanet.sessions = {}
datanet.current_character = nil

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

  -- Cache helpers

  urlFromCommand = function(command)
    if type(command) ~= "string" then return nil end
    return command:match("^datanet%s+(.+)$")
  end,

  cachePut = function(url, title, content)
    if not url then return end
    datanet.state.cache[url] = {
      title = title or "",
      content = content,
      timestamp = os.time()
    }
    datanet.helpers.pruneCache()
  end,

  cacheGet = function(url)
    if not url then return nil end
    return datanet.state.cache[url]
  end,

  -- mode is "url" for alphabetical, anything else for newest-first. pairs() order
  -- is not preserved across table.save/table.load, so sorting here is
  -- load-bearing, not cosmetic.
  cacheList = function(mode)
    local list = {}
    for url, page in pairs(datanet.state.cache) do
      table.insert(list, {
        url = url,
        title = page.title,
        timestamp = page.timestamp or 0
      })
    end

    if mode == "url" then
      table.sort(list, function(a, b) return a.url < b.url end)
    else
      table.sort(list, function(a, b) return a.timestamp > b.timestamp end)
    end

    return list
  end,

  -- Trim to config.cache.max_entries, oldest first. A url a live history entry
  -- still points at is never evicted, or going back would render it blank.
  pruneCache = function()
    local max = datanet.config.cache.max_entries
    -- Explicitly date-ordered: eviction drops the oldest, so it must not inherit
    -- whatever ordering the index happens to be displaying.
    local list = datanet.helpers.cacheList("date")
    if #list <= max then return end

    local referenced = {}
    for _, history in pairs(datanet.state.history) do
      for _, entry in ipairs(history.entries or {}) do
        if entry.url then referenced[entry.url] = true end
      end
    end

    for i = #list, max + 1, -1 do
      local url = list[i].url
      if not referenced[url] then
        datanet.state.cache[url] = nil
      end
    end
  end,

  -- Resolves an entry's page body from the cache, falling back to the inline
  -- content that pre-phase-3 entries carried.
  getEntryContent = function(entry)
    if not entry then return "" end
    if entry.content then return entry.content end
    local page = datanet.state.cache[entry.url]
    return (page and page.content) or ""
  end,

  addHistoryEntry = function(id, title, content, command)
    debugc("addHistoryEntry called for tab " .. tostring(id))
    local history = datanet.state.history[id]
    if not history then
      debugc("No history found, initializing for tab " .. tostring(id))
      datanet.helpers.initTabHistory(id)
      history = datanet.state.history[id]
    end

    -- Content goes to the url-keyed cache instead of into the entry, so a url
    -- open in several tabs is stored once. A command with no recoverable url
    -- (the bare "datanet" fallback) has nowhere to key off, so it keeps content
    -- inline and getEntryContent reads it back from there.
    local url = datanet.helpers.urlFromCommand(command)
    local has_content = (type(content) == "table" and next(content) ~= nil)
      or (type(content) == "string" and content ~= "")

    local entry = {
      url = url,
      title = title or "Untitled",
      timestamp = os.time(),
      command = command or ""
    }

    if url and has_content then
      datanet.helpers.cachePut(url, entry.title, content)
    elseif not url then
      entry.content = content or ""
    end

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

-- Paint a history entry's page body into a console. Does not clear it — callers
-- decide that, since some are repainting a console they just cleared themselves.
function datanet.renderEntry(console_name, entry)
  local content = datanet.helpers.getEntryContent(entry)
  if type(content) == "table" then
    for _, line in ipairs(content) do
      datanet.echoLineWithLinks(console_name, line)
    end
  else
    datanet.echoLineWithLinks(console_name, content)
  end
end

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
      datanet.renderEntry(console_name, entry)
    end

    -- Update tab title
    datanet.state.tabs[current_id] = entry.title

    -- Reload to update display
    datanet.load()
  end

  datanet.updateNavigationState(current_id)
end

-- Mirrors the datanetLink trigger's pattern (triggers.json): a protocol of word
-- characters, then a slash-led path. The previous replay pattern rejected digits
-- in the protocol, so links like holo2:/foo stayed plain text even when replay
-- did try to linkify them.
datanet.link_pattern = "%a[%w_]*:/[%w_/]+"

-- Echo one captured line, splicing clickable links in place.
--
-- Mudlet triggers only fire on live game output, so a page replayed from cache or
-- history never passes through the datanetLink trigger and would otherwise render
-- its links as dead text. The popup actions here are deliberately identical to
-- that trigger's, so a replayed page behaves exactly like a freshly loaded one.
function datanet.echoLineWithLinks(console_name, line)
  if type(line) ~= "string" then
    decho(console_name, "\n")
    return
  end

  local pos = 1
  -- Formatting does not carry across separate decho calls, and the colour tag
  -- governing a link is the last one in the text *before* it. Splitting the line
  -- therefore strands that tag in the previous call, so track it and re-state it
  -- inside the link's own text and in the remainder after it.
  local format = ""

  while true do
    local link_start, link_end = string.find(line, datanet.link_pattern, pos)
    if not link_start then break end

    if link_start > pos then
      local prefix = string.sub(line, pos, link_start - 1)
      decho(console_name, prefix)
      format = string.match(prefix, "^.*(<[^<>]+>)") or format
    end

    local link = string.sub(line, link_start, link_end)
    dechoPopup(
      console_name,
      format .. "<u>" .. link .. "</u>",
      {
        [[send("datanet ]] .. link .. [[")]],
        [[datanet.addTab(true, false) send("datanet ]] .. link .. [[")]]
      },
      { link, "Open link in new tab" },
      true
    )

    pos = link_end + 1
  end

  decho(console_name, format .. string.sub(line, pos) .. "\n")
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
      datanet.renderEntry(console_name, entry)
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

  datanet.ui.index_button = Geyser.Label:new({
    name = "datanet.index_button",
    x = "9%",
    y = datanet.config.layout.tabs_y,
    width = "3%",
    height = datanet.config.layout.tabs_height
  }, datanet.container)
  datanet.ui.index_button:setStyleSheet(datanet.styles.tab.normal)
  datanet.ui.index_button:echo("<center>☰")
  datanet.ui.index_button:setClickCallback("datanet.toggleCacheIndex")
  datanet.ui.index_button:show()

  -- Create tabs container for tab buttons (adjusted for navigation buttons)
  datanet.ui.tabs = Geyser.HBox:new({
    name = "datanet.tabs",
    x = "12%", -- Start after navigation buttons (3% + 3% + 3% + 3%)
    y = datanet.config.layout.tabs_y,
    width = "84%", -- 96% - 12% nav buttons = 84% for tabs
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

  -- Cache index overlay. Layered over the tab consoles rather than being a tab,
  -- so it stays out of state.tabs, out of history, and out of the save file.
  datanet.ui.cache_console = Geyser.MiniConsole:new({
    name = "datanet.cache_index",
    x = 0, y = 0,
    width = "100%", height = "100%",
    autoWrap = true,
    color = "black",
    scrollBar = true,
    fontSize = datanet.config.font_size
  }, datanet.ui.content)

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
  -- Passed explicitly: Mudlet hands click callbacks an event table when no
  -- argument is given, which would read as a truthy open_in_new and arm capture
  -- routing into a tab that is not about to request a page
  -- false, true: no capture follows a manually opened blank tab, but asking for
  -- one is an explicit request to go there. Both passed explicitly because Mudlet
  -- hands click callbacks an event table when arguments are omitted.
  datanet.ui.add_button:setClickCallback("datanet.addTab", false, true)
  datanet.ui.add_button:show()

  -- Set current tab
  datanet.setCurrent(datanet.state.current)

  -- Everything above was just (re)created, and Geyser does not draw new widgets
  -- until the container raises. disableGetData does this itself after a capture,
  -- which is why only the non-capture callers of load() showed blank panels.
  datanet.container:raiseAll()

  -- load() runs after every page visit and Geyser reuses widgets by name, so the
  -- overlay's visibility has to be re-derived here rather than assumed. A nil
  -- flag after a script re-parse means closed.
  if datanet.cache_visible then
    datanet.showCacheIndex()
  else
    datanet.hideCacheIndex()
  end
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

-- Style the tab buttons and the index button as one group, so the index reads as
-- a peer of the tabs: whatever is currently on screen is active, everything else
-- is normal.
function datanet.updateTabStyles()
  for id, _ in pairs(datanet.state.tabs) do
    local button = datanet.helpers.getTabButton(id)
    if button then
      local selected = not datanet.cache_visible and id == datanet.state.current
      button:setStyleSheet(selected and datanet.styles.tab.active or datanet.styles.tab.normal)
    end
  end

  if datanet.ui.index_button then
    datanet.ui.index_button:setStyleSheet(
      datanet.cache_visible and datanet.styles.tab.active or datanet.styles.tab.normal)
  end
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

  -- Update state
  datanet.state.last = datanet.state.current
  datanet.state.current = id

  -- Show new tab, unless the cache index is overlaying it. addTab() creates tab
  -- containers after the overlay already exists, so a newly created container
  -- would otherwise be stacked on top of it and hide it.
  local new_container = datanet.helpers.getTabContainer(id)
  if new_container and not datanet.cache_visible then
    new_container:show()
  end

  datanet.updateTabStyles()

  -- Update navigation buttons and address bar
  datanet.updateNavigationState(id)
end

-- Tab selection callback
function datanet.selectTab(id)
  -- Picking a tab means wanting to see it, not the index sitting on top of it
  datanet.hideCacheIndex()
  datanet.setCurrent(id)
end

-- Add new tab without full rebuild
-- route_capture: point the capture chain at this tab, for callers that send a
--   command immediately afterwards.
-- focus: switch to the tab. Links open in the background, so only an explicit
--   "give me a new tab" focuses.
-- Returns the new tab id, which background callers need since state.current
-- deliberately does not move.
function datanet.addTab(route_capture, focus)
  datanet.state.count = datanet.state.count + 1
  local new_id = datanet.state.count

  datanet.state.tabs[new_id] = ""
  if route_capture then
    datanet.state.new_tab = new_id
  end

  -- Create only the new tab (incremental update)
  datanet.createTab(new_id, "")

  -- A recycled tab id reattaches to an existing console, so wipe any leftover text
  local new_console = datanet.helpers.getTabConsole(new_id)
  if new_console then
    new_console:clear()
  end

  if focus then
    -- Taking focus means leaving the index, not opening a tab behind it
    datanet.hideCacheIndex()
    datanet.setCurrent(new_id)
  end

  -- Freshly created Geyser widgets are not drawn until the container raises, so
  -- an incrementally added tab shows as empty window background. The capture path
  -- never hit this because disableGetData ends with its own raiseAll().
  datanet.container:raiseAll()

  return new_id
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
      -- Only hidden, not destroyed: Mudlet keys widgets by name, so recreating a
      -- tab with the same id reattaches to this same console with its text buffer
      -- intact. Callers that must not show stale content have to clear it.
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

-- Cache Index UI

function datanet.renderCacheIndex()
  local console = datanet.ui.cache_console
  if not console then return end
  local console_name = "datanet.cache_index"

  console:clear()

  local mode = datanet.cache_sort or "date"
  local pages = datanet.helpers.cacheList(mode)
  if #pages == 0 then
    decho(console_name, "<200,200,200>No cached pages yet.\n")
    return
  end

  decho(console_name, "<255,255,255>Cached pages (" .. #pages .. ")\n")

  -- The active mode renders as plain text rather than a link, so it reads as
  -- selected and clicking it is a no-op
  local function sortLink(label, value)
    if mode == value then
      decho(console_name, "<255,255,255>[" .. label .. "]")
    else
      dechoLink(
        console_name,
        "<120,200,255>[" .. label .. "]",
        [[datanet.setCacheSort("]] .. value .. [[")]],
        "Sort by " .. label:lower(),
        true
      )
    end
    decho(console_name, " ")
  end

  decho(console_name, "<140,140,140>Sort: ")
  sortLink("Date", "date")
  sortLink("URL", "url")

  if datanet.cache_confirm then
    decho(console_name, "\n<255,180,180>Clear " .. #pages .. " cached page(s), all history and all tabs? ")
    dechoLink(
      console_name,
      "<255,120,120>[Yes]",
      "datanet.clearCache()",
      "Permanently clear this character's cache, history and tabs",
      true
    )
    decho(console_name, " ")
    dechoLink(
      console_name,
      "<120,200,255>[Cancel]",
      "datanet.cancelClearCache()",
      "Keep everything",
      true
    )
  else
    decho(console_name, " ")
    dechoLink(
      console_name,
      "<200,160,160>[Clear]",
      "datanet.confirmClearCache()",
      "Clear this character's cache, history and tabs",
      true
    )
  end

  decho(console_name, "\n\n")

  for _, page in ipairs(pages) do
    -- An empty-string title is truthy in Lua, so a plain `or` guard misses it
    local label = (page.title and page.title:match("%S")) and page.title or page.url
    decho(console_name, "<200,200,200>" .. label .. "\n")

    dechoLink(
      console_name,
      "<120,200,255><u>" .. page.url .. "</u>",
      [[datanet.openFromCache("]] .. page.url .. [[")]],
      "Open cached copy: " .. page.url,
      true
    )
    decho(console_name, "  ")
    dechoLink(
      console_name,
      "<160,160,160>[↻]",
      [[datanet.fetchInNewTab("]] .. page.url .. [[")]],
      "Fetch a live copy in a new tab: " .. page.url,
      true
    )
    decho(console_name, "<100,100,100>  " .. os.date("%Y-%m-%d %H:%M", page.timestamp) .. "\n\n")
  end
end

-- A view preference only, so it is deliberately not persisted and resets to date
-- ordering on a script re-parse.
function datanet.setCacheSort(mode)
  datanet.cache_sort = mode
  datanet.renderCacheIndex()
end

function datanet.confirmClearCache()
  datanet.cache_confirm = true
  datanet.renderCacheIndex()
end

function datanet.cancelClearCache()
  datanet.cache_confirm = nil
  datanet.renderCacheIndex()
end

-- Wipe this character's page cache, history and tabs, back to one blank tab.
-- Other characters' archived sessions are untouched. Irreversible:
-- saveSessions() writes straight through with no debounce, so the on-disk copy
-- goes with it. That is why the index header confirms first.
function datanet.clearCache()
  datanet.teardownAllTabs()
  datanet.resetState()

  datanet.cache_confirm = nil
  datanet.load()
  -- Geyser reuses consoles by name, so the surviving tab still holds the text of
  -- whatever page was last shown in it
  datanet.repaintTabsFromHistory()
  datanet.saveSessions()

  cecho("\n[<cyan>DataNet<reset>] Cache and history cleared for <yellow>"
    .. tostring(datanet.current_character or "this character") .. "<reset>")
end

function datanet.showCacheIndex()
  datanet.cache_visible = true
  datanet.renderCacheIndex()

  local container = datanet.helpers.getTabContainer(datanet.state.current)
  if container then
    container:hide()
  end

  if datanet.ui.cache_console then
    datanet.ui.cache_console:show()
  end

  datanet.updateTabStyles()
end

function datanet.hideCacheIndex()
  datanet.cache_visible = false
  -- Never leave a pending confirm armed for the next time the index opens
  datanet.cache_confirm = nil

  if datanet.ui.cache_console then
    datanet.ui.cache_console:hide()
  end

  local container = datanet.helpers.getTabContainer(datanet.state.current)
  if container then
    container:show()
  end

  datanet.updateTabStyles()
end

function datanet.toggleCacheIndex()
  if datanet.cache_visible then
    datanet.hideCacheIndex()
  else
    datanet.showCacheIndex()
  end
end

-- Open a cached page in the current tab without sending anything to the game,
-- so it costs no charge and works while offline. Falls back to a live fetch on
-- a cache miss.
-- Fetch a live copy into a new tab. Unlike openFromCache this leaves new_tab
-- armed, because a capture does follow and needs it to find the tab.
function datanet.fetchInNewTab(url)
  datanet.addTab(true, false)
  send("datanet " .. url)
end

function datanet.openFromCache(url)
  local page = datanet.helpers.cacheGet(url)
  if not page then
    debugc("datanet.openFromCache: miss for " .. tostring(url) .. ", fetching live")
    datanet.fetchInNewTab(url)
    return
  end

  -- Nothing is captured here, so the capture chain must not be pointed at this
  -- tab, and the page opens behind whatever the player is looking at
  local tab_id = datanet.addTab(false, false)
  local console = datanet.helpers.getTabConsole(tab_id)
  local console_name = datanet.helpers.getTabConsoleName(tab_id)

  if console then
    console:clear()
    datanet.renderEntry(console_name, { url = url })
  end

  local title = (page.title and page.title:match("%S")) and page.title or url
  datanet.helpers.addHistoryEntry(tab_id, title, nil, "datanet " .. url)
  datanet.state.tabs[tab_id] = title

  -- No updateNavigationState for tab_id: the nav buttons belong to whatever tab
  -- still has focus, and load() refreshes them for state.current
  datanet.load()
  datanet.saveSessions()
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

  datanet.saveSessions()
end

-- Character Session Management

datanet.save_dir = getMudletHomeDir() .. "/DataNet"
datanet.save_path = datanet.save_dir .. "/sessions.lua"

-- Fold the live tabs/history back into the archive under the active character.
-- Must run before any disk write, otherwise the character currently being played
-- is the one character missing from the saved file.
function datanet.archiveCurrentCharacter()
  if not datanet.current_character then
    -- Live state has nowhere to go, so a save here would persist whatever was
    -- last loaded and quietly discard everything since
    debugc("datanet.archiveCurrentCharacter: no current character, nothing archived")
    return
  end
  datanet.sessions[datanet.current_character] = {
    tabs = datanet.state.tabs,
    count = datanet.state.count,
    current = datanet.state.current,
    last = datanet.state.last,
    history = datanet.state.history,
    cache = datanet.state.cache,
    schema = 1
  }
end

function datanet.saveSessions()
  datanet.archiveCurrentCharacter()

  if not io.exists(datanet.save_dir) then
    lfs.mkdir(datanet.save_dir)
  end

  local ok, err = pcall(table.save, datanet.save_path, datanet.sessions)
  if not ok then
    -- Loud on purpose: a silently failing save looks identical to a working one
    -- until the next restart, by which point the data is gone
    cecho("\n[<cyan>DataNet<reset>] <red>Could not save sessions<reset>: " .. tostring(err))
  end
end

function datanet.loadSessions()
  datanet.sessions = {}

  if not io.exists(datanet.save_path) then
    debugc("datanet.loadSessions: no saved sessions at " .. datanet.save_path)
    return
  end

  -- Mudlet fills the table passed in and returns nothing; some versions return
  -- the loaded table instead. Accept either rather than depending on one.
  local target = {}
  local ok, result = pcall(table.load, datanet.save_path, target)

  if not ok then
    cecho("\n[<cyan>DataNet<reset>] <red>Could not read saved sessions<reset>: " .. tostring(result))
    datanet.sessions = {}
    return
  end

  if type(result) == "table" and next(result) ~= nil then
    datanet.sessions = result
  else
    datanet.sessions = target
  end

  datanet.migrateSessions()
end

-- Pre-phase-3 sessions stored each page's body inline on its history entry and
-- had no cache at all. Backfill the cache from that content so previously
-- visited pages show up in the index, then drop the inline copy. Lossless --
-- the content is already on disk, it just moves.
function datanet.migrateSessions()
  for character, session in pairs(datanet.sessions) do
    if session.schema ~= 1 then
      session.cache = session.cache or {}

      for _, history in pairs(session.history or {}) do
        for _, entry in ipairs(history.entries or {}) do
          local url = datanet.helpers.urlFromCommand(entry.command)
          if url then
            entry.url = url
            local existing = session.cache[url]
            local stamp = entry.timestamp or 0
            if entry.content and (not existing or stamp >= (existing.timestamp or 0)) then
              session.cache[url] = {
                title = entry.title or "",
                content = entry.content,
                timestamp = stamp
              }
            end
            entry.content = nil
          end
        end
      end

      session.schema = 1
      debugc("datanet.migrateSessions: migrated " .. tostring(character))
    end
  end
end

-- Reset to a single blank tab with no history (used the first time a character is seen)
function datanet.resetState()
  datanet.state.tabs = {""}
  datanet.state.count = 1
  datanet.state.current = 1
  datanet.state.last = 1
  datanet.state.history = {}
  datanet.state.cache = {}
  -- Would otherwise point at a tab id that no longer exists, and the next
  -- capture targets whatever it names
  datanet.state.new_tab = nil
  datanet.temp_capture = nil
end

-- Tear down every tab's UI elements without touching datanet.state, so a fresh
-- state table can be swapped in and rebuilt via datanet.load()
function datanet.teardownAllTabs()
  for id, _ in pairs(datanet.state.tabs) do
    datanet.cleanupTab(id)
  end
end

-- Repaint every live tab's console from its own history, clearing stale text first.
-- Required after a character swap because rebuilt tabs reuse the previous
-- character's console buffer (see datanet.cleanupTab).
function datanet.repaintTabsFromHistory()
  for id, _ in pairs(datanet.state.tabs) do
    local console = datanet.helpers.getTabConsole(id)
    local console_name = datanet.helpers.getTabConsoleName(id)
    if console then
      console:clear()
      local history = datanet.state.history[id]
      local entry = history and history.entries[history.current_index]
      if entry then
        datanet.renderEntry(console_name, entry)
      end
    end
  end
end

-- Swap the active tabs/history to a different character, archiving the outgoing
-- character's session in memory so switching back this client run restores it
function datanet.switchCharacter(character)
  if not character or character == "" then return end
  if datanet.current_character == character then
    return
  end

  local outgoing = datanet.current_character
  debugc("datanet.switchCharacter: " .. tostring(outgoing) .. " -> " .. tostring(character))

  datanet.archiveCurrentCharacter()
  datanet.teardownAllTabs()

  local session = datanet.sessions[character]
  if session then
    datanet.state.tabs = session.tabs
    datanet.state.count = session.count
    datanet.state.current = session.current
    datanet.state.last = session.last
    datanet.state.history = session.history
    datanet.state.cache = session.cache or {}
    datanet.temp_capture = nil
  else
    datanet.resetState()
  end

  datanet.current_character = character
  datanet.load()
  datanet.repaintTabsFromHistory()

  -- Save only when there was something real to persist: an outgoing character
  -- whose tab changes were not page visits, or a restored session. A first-seen
  -- character starts blank, and writing that blank state immediately is what let
  -- a failed load destroy the save file. Its first page visit will save anyway.
  if outgoing or session then
    datanet.saveSessions()
  end
end

-- Detect character login/switch via GMCP so DataNet sessions stay isolated per character
function datanet.onCharacterInfo()
  if not gmcp or not gmcp.Char or not gmcp.Char.Info or not gmcp.Char.Info.name then
    debugc("datanet.onCharacterInfo: gmcp.Char.Info.name not available")
    return
  end
  datanet.switchCharacter(gmcp.Char.Info.name)
end

-- Handler ids live outside the datanet table on purpose: line 2 resets datanet to
-- {} on every script re-parse, so a guard stored inside it is always nil here and
-- would stack up a duplicate handler each reload. Registering by function *name*
-- rather than by value keeps the handler pointing at the current datanet table.
if datanetCharEventId then
  killAnonymousEventHandler(datanetCharEventId)
end
datanetCharEventId = registerAnonymousEventHandler("gmcp.Char.Info", "datanet.onCharacterInfo")

if datanetExitEventId then
  killAnonymousEventHandler(datanetExitEventId)
end
datanetExitEventId = registerAnonymousEventHandler("sysExitEvent", "datanet.saveSessions")

-- Initialize DataNet
datanet.loadSessions()
datanet.load()

-- Re-establish the character from the gmcp table already in memory. A script
-- re-parse (package reinstall, profile reload) resets current_character to nil,
-- and no fresh gmcp.Char.Info arrives while already connected -- leaving every
-- later save archiving nothing and silently rewriting stale state.
datanet.onCharacterInfo()

datanet.container:hide()

