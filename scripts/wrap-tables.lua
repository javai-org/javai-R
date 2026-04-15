-- wrap-tables.lua
-- Pandoc filter that assigns an equal fractional width to every column in
-- every table, so that pandoc emits p{...}-style LaTeX columns and cell
-- content wraps automatically. Without this filter, GFM pipe tables
-- produce longtable output with l-type columns that do not wrap and
-- overflow the page for long cells.
--
-- Trade-off: equal-width columns are a pragmatic default; they are not
-- always aesthetically ideal. Upgrade this filter to compute widths
-- proportional to content length if specific tables warrant it.

function Table(tbl)
  local n = #tbl.colspecs
  if n == 0 then return nil end
  for i = 1, n do
    tbl.colspecs[i][2] = 1.0 / n
  end
  return tbl
end
