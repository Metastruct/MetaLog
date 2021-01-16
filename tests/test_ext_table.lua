function table.Empty (tab)
	for k in next, tab do
		tab [k] = nil
	end
end