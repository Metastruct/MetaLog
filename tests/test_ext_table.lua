function table.Empty (tab)
	for k in next, tab do
		tab [k] = nil
	end
end

function table.GetKeys (tab)
	local keys = {}

	for k in next, tab do
		table.insert (keys, k)
	end

	return keys
end
