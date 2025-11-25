-- ============================================================================
-- DataNet Plugin Registration
-- ============================================================================

-- Register DataNet with the plugin dock
function datanet.registerPlugin()
  if not (lotj and lotj.plugin and lotj.plugin.dock and lotj.plugin.dock.register) then 
    return 
  end

  lotj.plugin.dock.register("@PKGNAME@", {
    icon = getMudletHomeDir() .. '/@PKGNAME@/datanet_icon.png',
    hoverIcon = getMudletHomeDir() .. '/@PKGNAME@/datanet_icon_hover.gif',
    onClick = function()
      if datanet.container.hidden then
        datanet.show()
      else
        datanet.hide()
      end
    end
  })
end

datanet.registerPlugin()

-- Register event handler to clean up when package is uninstalled
registerAnonymousEventHandler("sysUninstallPackage", function(_, packageName)
  if packageName == "@PKGNAME@" then
      datanet.hide()
      datanet = nil
  end
end)