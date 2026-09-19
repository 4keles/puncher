-- The unit interval.
--
-- Every curve and every arc in this layer is defined for a progress value
-- between zero and one, and every one of them has to decide what to do when
-- it is handed something outside that range. They all make the same decision,
-- so it is made once here: clamp rather than extrapolate, because a caller
-- passing 1.2 wants the end of the motion, not a position past it.

local M = {}

M.MINIMUM = 0
M.MAXIMUM = 1

--- Bring a progress value inside the unit interval.
-- @tparam number t
-- @treturn number
function M.clamp(t)
  if t < M.MINIMUM then
    return M.MINIMUM
  end
  if t > M.MAXIMUM then
    return M.MAXIMUM
  end
  return t
end

return M
