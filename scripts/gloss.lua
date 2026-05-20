-- Glossary popover filter for STATISTICAL-MODEL-OVERVIEW.md.
-- Rewrites Pandoc bracketed spans of the form
--   [surface form]{.gloss term="entry-id"}
-- into an HTML popover button paired with a <span popover="auto"> body.
-- Definitions are read from docs/glossary.json, which is generated from
-- docs/glossary.yaml by the workflow before pandoc runs.

local f = io.open("docs/glossary.json", "r")
if not f then
  io.stderr:write("gloss.lua: docs/glossary.json not found\n")
  os.exit(1)
end
local raw = f:read("*a"); f:close()
local list = pandoc.json.decode(raw)
local entries = {}
for _, e in ipairs(list) do entries[e.id] = e end

local counter = 0

function Span(el)
  if not el.classes:includes("gloss") then return nil end
  local id = el.attributes["term"]
  local entry = entries[id]
  if not entry then
    io.stderr:write("gloss.lua: unknown term '" .. tostring(id) .. "'\n")
    os.exit(1)
  end
  counter = counter + 1
  local pop_id = "gloss-pop-" .. id .. "-" .. counter
  local surface = pandoc.utils.stringify(el.content)
  local function tidy(s)
    s = s:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
    -- Light markdown emphasis: *foo* → <em>foo</em>
    s = s:gsub("%*([^*]+)%*", "<em>%1</em>")
    return s
  end
  local short = tidy(entry.short)
  local aka_block = ""
  if entry.also_known_as and entry.also_known_as ~= "" then
    aka_block = string.format(
      '<span class="gloss__aka">%s</span>',
      tidy(entry.also_known_as))
  end
  local html = string.format(
    '<button type="button" class="gloss" popovertarget="%s" aria-describedby="%s">%s<span class="gloss__icon" aria-hidden="true">&#9432;</span></button><span id="%s" popover="auto" role="tooltip" class="gloss__pop">%s%s</span>',
    pop_id, pop_id, surface, pop_id, short, aka_block)
  return pandoc.RawInline("html", html)
end
