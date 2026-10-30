.PHONY: restore extract prepare analysis models audit sensitivity correctness lint test check ci-docker format tables-pdf
restore:
	Rscript -e 'if (!requireNamespace("renv", quietly = TRUE)) install.packages("renv", repos = "https://cloud.r-project.org"); dir.create(".library", showWarnings = FALSE); renv::restore(library = ".library", prompt = FALSE)'
extract:
	Rscript scripts/extract_sources.R
prepare:
	Rscript scripts/00_upstream.R
	Rscript scripts/00_prepare.R
analysis:
	Rscript scripts/99_run_all.R
models:
	Rscript scripts/02_models.R
audit:
	Rscript scripts/10_knowledge_audit.R
sensitivity:
	Rscript scripts/11_sensitivity.R
correctness:
	Rscript scripts/13_correctness_checks.R
	Rscript scripts/12_correctness_audit.R
	Rscript scripts/14_correctness_report.R
lint:
	Rscript -e 'l <- unlist(lapply(c("R", "scripts", "tests"), lintr::lint_dir), recursive = FALSE); print(l); quit(status = as.integer(length(l) > 0))'
test: prepare
	Rscript -e 'testthat::test_dir("tests/testthat", stop_on_failure = TRUE)'
check: analysis lint test
ci-docker:
	docker run --rm -v "$(CURDIR):/project" -v /project/.library -w /project rocker/verse:4.6.0 bash -c 'apt-get update && apt-get install -y jags && make restore check'
format:
	Rscript -e 'styler::cache_deactivate(); for (p in c("R", "scripts", "tests")) styler::style_dir(p)'

tables-pdf:
	Rscript scripts/08_tables.R
	latexmk -xelatex -interaction=nonstopmode -halt-on-error -outdir=data/build docs/tables.tex
	cp data/build/tables.pdf docs/tables.pdf
