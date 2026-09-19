-- Seeded randomness.
--
-- Procedural effects need variation, but variation that changes every time the
-- artist presses the button is not a tool, it is a slot machine. A seed makes
-- a result repeatable: the same seed rebuilds the same sparks in the same
-- places, so a preset can be saved, shared and trusted.
--
-- This deliberately does not use the interpreter's own generator, whose
-- sequence is free to differ between versions and platforms. A result produced
-- here must be identical everywhere, including inside the application's own
-- interpreter.

local M = {}

local MASK = 0xFFFFFFFF
local DIVISOR = 0x100000000

-- A zero state would stay zero forever, so it is replaced with an arbitrary
-- non-zero constant rather than being rejected: a seed of zero is a perfectly
-- reasonable thing for a caller to pass.
local ZERO_SEED_REPLACEMENT = 0x9E3779B9

local Source = {}
Source.__index = Source

function Source:reseed(seed)
  seed = math.floor(seed or 0) & MASK
  if seed == 0 then
    seed = ZERO_SEED_REPLACEMENT
  end
  self.state = seed
end

-- Xorshift: three shifts and three exclusive-ors, which is enough scatter for
-- sparks and debris and cheap enough to run thousands of times per effect.
function Source:nextInteger()
  local x = self.state
  x = x ~ ((x << 13) & MASK)
  x = x ~ (x >> 17)
  x = x ~ ((x << 5) & MASK)
  x = x & MASK
  self.state = x
  return x
end

--- A number in [0, 1).
function Source:float()
  return self:nextInteger() / DIVISOR
end

--- A number in [minimum, maximum].
function Source:range(minimum, maximum)
  return minimum + self:float() * (maximum - minimum)
end

--- A whole number in [minimum, maximum], both ends included.
function Source:integer(minimum, maximum)
  return minimum + math.floor(self:float() * (maximum - minimum + 1))
end

function M.new(seed)
  local source = setmetatable({ state = 0 }, Source)
  source:reseed(seed)
  return source
end

return M
