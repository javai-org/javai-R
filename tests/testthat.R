library(testthat)

# Standard R CMD check / installed-package path: javair has been installed
# and its tests/testthat/ directory ships inside the install tree.
installed_tests <- system.file("tests", "testthat", package = "javair")

if (nzchar(installed_tests) && length(list.files(installed_tests)) > 0) {
  library(javair)
  test_check("javair")
} else {
  # Source-tree dev path: package is loaded but not installed (e.g. running
  # `Rscript tests/testthat.R` from the repo root). Fall back to devtools::test().
  if (!requireNamespace("devtools", quietly = TRUE)) {
    stop(
      "javair is not installed with its tests, and devtools is not available ",
      "for the source-tree fallback. Either run `R CMD INSTALL .` first, or ",
      "install devtools, or run `Rscript -e 'devtools::test()'` directly.",
      call. = FALSE
    )
  }
  message("javair not installed with tests; running devtools::test() from source.")
  devtools::test()
}
