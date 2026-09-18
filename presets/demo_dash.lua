-- The demonstration dash.
--
-- A preset is data, not code: these numbers are what makes this motion feel
-- the way it does, and changing them must never mean editing the engine.
--
-- Deliberately the simplest motion that exercises the whole chain. There is no
-- anticipation, no squash, no trail; those belong to the motion engine work
-- that follows this groundwork.

return {
  frameCount = 8,
  distance = 32,
  curve = "cubicOut",

  -- One beat before the move and two after it. The pause at the end is what
  -- makes a short dash read as an arrival rather than a stop.
  holdFirst = 1,
  holdLast = 2,

  baseDuration = 60,
  holdMultiplier = 2,
}
