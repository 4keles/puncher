-- The demonstration dash.
--
-- A preset is data, not code: these numbers are what makes this motion feel
-- the way it does, and changing them must never mean editing the engine.
--
-- Deliberately the simplest motion that exercises the whole chain. There is no
-- anticipation, no squash, no trail; those belong to the motion engine work
-- that follows this groundwork.

return {
  -- Few frames over a long distance. The gap between one frame and the next is
  -- what reads as speed; crossing a short distance in many small steps reads
  -- as sliding instead, however fast it is played.
  frameCount = 6,
  distance = 128,

  -- Out fast, then settle. The burst belongs at the start of a dash. A sharper
  -- curve than this spends its last frames almost motionless, which reads as
  -- the animation having stopped early rather than as an arrival.
  curve = "quadOut",

  -- One beat before the move and two after it. The pause at the end is what
  -- makes a short dash read as an arrival rather than a stop.
  holdFirst = 1,
  holdLast = 2,

  -- Roughly a third of a second from first beat to last. A dash that takes
  -- longer stops being a dash, whatever path it follows.
  baseDuration = 30,
  holdMultiplier = 2,
}
