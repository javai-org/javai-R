-- wrap-tables.lua
-- Pandoc filter that assigns each table column a relative width
-- proportional to its content length, so that long-content columns
-- (e.g. a Milestone description) get more horizontal space than short
-- ones (e.g. a single-digit row number).
--
-- Pipe tables in GFM/markdown do not carry width hints through pandoc's
-- AST (colspecs come out as ColWidthDefault), so pandoc emits
-- longtable{@{}lll@{}} with natural-width left-aligned columns that do
-- not wrap. Setting widths here forces pandoc to emit p{...} columns
-- that do wrap.
--
-- Heuristic: weight column = sqrt(total cell text length in that column).
-- Square-root dampens extreme ratios (a 400-char column shouldn't get
-- 100x the width of a 4-char column — it should get ~10x). A minimum
-- fraction per column (MIN_FRAC) prevents narrow columns from becoming
-- unreadably thin.

local MIN_FRAC = 0.04   -- every column gets at least 4% of \linewidth
local stringify = pandoc.utils.stringify

local function add_row_lengths(row, lengths)
  for i, cell in ipairs(row.cells) do
    lengths[i] = (lengths[i] or 0) + #stringify(cell.contents)
  end
end

function Table(tbl)
  local ncols = #tbl.colspecs
  if ncols == 0 then return nil end

  local lengths = {}
  for i = 1, ncols do lengths[i] = 0 end

  if tbl.head and tbl.head.rows then
    for _, row in ipairs(tbl.head.rows) do add_row_lengths(row, lengths) end
  end
  for _, body in ipairs(tbl.bodies) do
    if body.body then
      for _, row in ipairs(body.body) do add_row_lengths(row, lengths) end
    end
    if body.head then
      for _, row in ipairs(body.head) do add_row_lengths(row, lengths) end
    end
  end
  if tbl.foot and tbl.foot.rows then
    for _, row in ipairs(tbl.foot.rows) do add_row_lengths(row, lengths) end
  end

  -- sqrt-dampened weights; +1 avoids zero for empty columns.
  local weights = {}
  local total_w = 0
  for i = 1, ncols do
    weights[i] = math.sqrt(lengths[i] + 1)
    total_w = total_w + weights[i]
  end

  local remaining = 1.0 - MIN_FRAC * ncols
  if remaining < 0 then remaining = 0 end

  for i = 1, ncols do
    tbl.colspecs[i][2] = MIN_FRAC + remaining * (weights[i] / total_w)
  end

  return tbl
end
