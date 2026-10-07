debugc("endCapture")
disableTrigger('getData')
disableTrigger('enableDisableGetData')
enableTrigger('enableGetData')

-- The capture failed, so do not leave this url armed for the next one to claim
datanet.current_command = nil