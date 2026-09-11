function Linemode:size_and_mtime()
    local size = self._file:size()
    local size_str = size and ya.readable_size(size) or "-"

    local mtime = math.floor(self._file.cha.mtime or 0)
    local time_str = mtime == 0
        and "-"
        or os.date("%y/%m/%d %H:%M", mtime)

    return string.format("%10s  %14s", size_str, time_str)
end
