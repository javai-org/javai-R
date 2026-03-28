#!/usr/bin/env Rscript
#
# Regenerate all conformance reference data.
#
# Usage:
#   Rscript scripts/generate_all.R
#
# This writes JSON files to inst/cases/. These files are committed to the
# repository so that consumers (punit, feotest, baseltest, ...) can read
# them without needing R installed.

# Source all R files (works without installing the package)
r_files <- list.files("R", pattern = "\\.R$", full.names = TRUE)
for (f in r_files) source(f)

output_dir <- file.path("inst", "cases")
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

suites <- list(
  wilson_ci = generate_wilson_ci_cases(),
  wilson_lower = generate_wilson_lower_cases(),
  threshold_derivation = generate_threshold_derivation_cases(),
  power_analysis = generate_power_analysis_cases(),
  feasibility = generate_feasibility_cases(),
  verdict = generate_verdict_cases()
)

for (name in names(suites)) {
  path <- file.path(output_dir, paste0(name, ".json"))
  jsonlite::write_json(suites[[name]], path, pretty = TRUE, auto_unbox = TRUE,
                       digits = NA)
  message("Wrote: ", path)
}

message("\nDone. ", length(suites), " suites generated.")
