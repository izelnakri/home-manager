Timers = {}

function Timers.set_interval(func, interval, ...)
  local arguments = { ... }
  local timer = vim.uv.new_timer()
  timer:start(interval or 0, interval, function()
    func(unpack(arguments))
  end)
  return timer
end

function Timers.set_timeout(func, timeout, ...)
  local arguments = { ... }
  local timer = vim.uv.new_timer()
  timer:start(timeout or 0, 0, function()
    timer:stop()
    timer:close()
    func(unpack(arguments))
  end)
  return timer
end

function Timers.clear_interval(timer)
  timer:stop()
  timer:close()

  return timer
end

function Timers.clear_timeout(timer)
  timer:stop()
  timer:close()

  return timer
end

return Timers
