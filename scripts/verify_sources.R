manifest <- readr::read_csv("docs/archive_manifest.csv", show_col_types = FALSE)
actual <- vapply(manifest$path, digest::digest, character(1), file = TRUE, algo = "sha256")
stopifnot(identical(unname(actual), manifest$sha256))
message("Verified ", nrow(manifest), " immutable source files")
