enableTrigger('datanetLink')
enableTrigger('endCapture')
enableTrigger('enableGetData')

disableTrigger('getData')
disableTrigger('disableGetData')
disableTrigger('enableDisableGetData')

-- An interrupted capture can leave a url armed, which the next page would be
-- filed under
datanet.current_command = nil
datanet.temp_capture = nil