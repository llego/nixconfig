--- @since 26.5.6

local ZFS_SIGN = "ZFS"

local function unescape_mount_path(path)
	return path:gsub("\\([0-7][0-7][0-7])", function(oct)
		return string.char(tonumber(oct, 8))
	end)
end

local function zfs_mounts()
	local mounts = {}
	local file = io.open("/proc/self/mountinfo", "r")
	if not file then
		return mounts
	end

	for line in file:lines() do
		local before, after = line:match("^(.-) %- (.*)$")
		if before and after then
			local mountpoint = before:match("^%S+ %S+ %S+ %S+ (%S+)")
			local fstype, source = after:match("^(%S+) (%S+)")
			if mountpoint and fstype == "zfs" then
				mounts[unescape_mount_path(mountpoint)] = unescape_mount_path(source or "")
			end
		end
	end

	file:close()
	return mounts
end

local add = ya.sync(function(state, items)
	state.datasets = state.datasets or {}
	for path, dataset in pairs(items) do
		if dataset == false then
			state.datasets[path] = nil
		else
			state.datasets[path] = dataset
		end
	end
	ui.render()
end)

local function setup(state, opts)
	state.datasets = {}
	opts = opts or {}
	opts.order = opts.order or 1500

	Linemode:children_add(function(self)
		if not self._file.in_current then
			return ""
		end

		local dataset = state.datasets[tostring(self._file.url)]
		if not dataset then
			return ""
		end

		local sign = opts.show_name and dataset or ZFS_SIGN
		if self._file.is_hovered then
			return ui.Line { " ", sign }
		else
			return ui.Line { " ", ui.Span(sign):fg("cyan") }
		end
	end, opts.order)
end

local function fetch(_, job)
	local mounts = zfs_mounts()
	local items = {}

	for _, file in ipairs(job.files) do
		local path = tostring(file.url)
		items[path] = file.cha.is_dir and mounts[path] or false
	end

	add(items)
	return true
end

return { setup = setup, fetch = fetch }
