# Published-version verification

Checked on 2026-10-29 against the author-hosted [typeset QJPS paper](https://static1.squarespace.com/static/5d7bd0207606e352c9d8019e/t/5e77aa79b0412f11a912a318/1584900740714/You+Cannot+Be+Serious.pdf),
volume 10 (2015), pages 489–518, DOI 10.1561/100.00014127. Its title page records
receipt of the final version on July 29, consistent with the canonical ZIP.
The local comparison manuscript is `PSK Partisan Bias QJPS.Final ms (1).docx`.

| Published location | Comparison with local manuscript and archive benchmarks |
|---|---|
| p. 498, footnote 4 | Assignment/completion counts and last-economic-item completion definition agree. |
| p. 503, Table 1 | All 44 estimates, 44 printed standard errors, 14 counts, and significance markers agree. |
| p. 504, Table 2 | All coefficients, standard errors, variances, counts, log-likelihoods, and equality tests agree. |
| p. 507, Table 3 | Same agreement, including the interaction and equality tests. |
| p. 510, Table 4 | Same agreement, including the three IIA diagnostics. |
| pp. 497, 499–504, 506–507, 509 | Checked instruction times, accuracy/refusal rates, party shares, bias reductions, consistent-partisan comparison, interaction claim, and incentive-pooling test agree. |

Publication did not resolve the completion-definition, study-scope, or interpretation
issues documented in the other audit reports. No numerical version difference was
found in these checks. The appendix is separate and was not publication-verified here.

## Significance wording audit

The results paragraph on p. 502 claims a pooled congenial-response reduction with
p < .001; Table 1 marks that result **, denoting p < .01. The paragraph also claims
p < .05 for the accuracy appeal, whereas the table marks +, denoting p < .10.
The same inconsistencies appear in the local final manuscript. Table 1 explicitly
specifies one-sided normal z-tests.

`scripts/05_claims.R` now produces `tabs/prose_significance.csv` from the exact
replicated effects, the current bootstrap results, and an independent respondent-
cluster delta-method calculation. Results below are our calculations, not recovered
historical Stata p-values:

| Congenial-response contrast | Exact effect (points) | Bootstrap SE (points) | One-sided p | Delta SE (points) | One-sided p |
|---|---:|---:|---:|---:|---:|
| Pooled monetary | -4.769162 | 1.649490 | .001918 | 1.603174 | .001466 |
| Study 2 accuracy appeal | -3.391377 | 2.010775 | .045840 | 2.047417 | .048819 |

For the pooled contrast, any SE that rounds to the reported 1.6 points must be at
least 1.55 points. Combining that lower bound with the exact effect gives
`pnorm(-4.769161968 / 1.55) = .001045902`. Therefore p < .001 is incompatible with
the exact effect, the reported SE precision, and the stated test. The pooled
congenial-response reduction remains significant at .01 under both reconstructed
uncertainty estimates; this finding corrects the strength of the significance
claim, not the effect's sign or the general evidence for H1.

For the accuracy appeal, SEs rounding to 2.1 points permit p-values from .049030
to .057354. Rounding therefore cannot settle whether the original p-value crossed
.05. The table symbol and prose conflict, while our current bootstrap and delta
calculations lie just below .05. Sampling-frame and Monte Carlo qualifications
remain material for this borderline result.

## Verification method and limits

The web PDF reader supplied page-indexed text. Local DOCX table XML and footnotes
were checked against that extraction and the benchmark CSVs. PDF page indices are
zero-based: published p. 498 is index 9; Tables 1–4 are indices 14, 15, 18, and 21.
Screenshot attempts failed with cache/content-type errors; no pixel-level table or
figure equivalence is claimed. Graph coordinates and interval endpoints were not
validated from the typeset figures. This is a targeted publication check, not a
character-by-character comparison of the entire article or a new validation of the
original bootstrap random stream.
