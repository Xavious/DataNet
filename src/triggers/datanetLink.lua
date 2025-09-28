datanet.link = matches[1]
selectString(matches[1], 1)
setUnderline(true)
setPopup("main", {
  [[send("datanet ]] .. datanet.link .. [[")]],
  [[datanet.addTab(true) send("datanet ]] .. datanet.link .. [[")]]
}, {
  datanet.link,
  "Open link in new tab"
})