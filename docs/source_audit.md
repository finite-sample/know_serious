# Source reconstruction and audit status

The canonical source is the July 29, 2015 release in the original
`PSK_Replication.zip`, now preserved locally under `historical/` and copied to
the tracked `data/raw/final_bundle/`. All 41 columns and 2,251
respondents in its `psk_wide.dta` reconstruct exactly from the earliest available
inputs. This verifies the release assembly numerically; the original 2008 survey
delivery and its first recoding script are still unavailable.

## Inputs and reconstruction

The paths below describe local originals, excluded from Git. The executable public
pipeline reads their column projections in `data/extracted/`; the original hashes
and column inventory are preserved in `docs/private_source_manifest.csv` and
`docs/source_columns.csv`. See [public data scope](public_data.md).

- `data/raw/upstream/PriorLupia2004/PriorLupia20004.surveydata.dta`: 1,550 records and
  132 variables. Selecting `ex_group` 1 or 3 yields the 618 released cases. Add
  10,000 to identifiers; experimental groups 1 and 3 map to control and monetary
  incentive. Reverse positive q13 and q14 response codes, preserving negative
  nonresponse codes. Outcomes map from q13, q14, q16, q15, and q18. The original
  `incomp` field maps to the released `dropout` field, including seven ones.
- `data/raw/upstream/KN2008 and Gas/temp.dta`: 1,633 records and 470 variables. This
  is the earliest located 2008 checkpoint, not an unmodified survey delivery.
  Historical `KN2008.Partisan.Recode.do` loads
  `KnowledgeNetworksSurvey2008/data/kn2008_survey.dta` and executes
  `KN2008visual.recoding.do` before saving the checkpoint. Neither source was found.
  Already derived party identification and Senate knowledge values therefore
  cannot be audited all the way back to original inputs without those files.
- `data/raw/upstream/merged.dta` adds gas-price references and a merge marker to the
  checkpoint; those reference prices are not inputs to the released wide file.
- No script creating `psk_wide.dta` was located. `R/upstream.R` reconstructs that
  assembly using historical code and exact identifier-aligned comparisons. Exact
  values establish numerical equivalence, not identity with the missing script.

In 2008, missing e1–e8 and economic responses with observed item timers become -1
(refusal). The e9 battery requires a positive timer; two zero-time cases stay
missing. Approval coalesces k3a and m1_1. Instruction time sums observed
condition-specific timers, remaining missing when all are absent. The published
`h1c` and `r_PIDloc` fields copy directly from the checkpoint. The raw 2008 `dropout`
field is missing; its derivation belongs to the subsequent published recode.

The historical `KN2008.Partisan.Recode.do`, lines 104–105, excludes gas values below
zero or above 500 before refusal coding. This explains both formerly questioned
cells: case 1616's approximately 1.445455e25 and case 1287's -5 become -1. They are
recovered documented transformations, not defects.

## Completion and dropout

Final `PSK_Recodes.do` explicitly defines Study 2 completion as nonmissing l5. It
then defines post-randomization dropout from missing l5, party-question order, and
an observed h1c or presidential-approval response as appropriate. This yields 1,511
completions and eight dropouts (control 2, appeal 5, monetary 1), matching the
appendix. The final source does not have the historical 13-versus-eight defect.

The original 2004 `treat == 1` field verifies 775 assignments to the 60-second
condition. The release retains 618 cases, four with `l10 == -2` (not asked) and
`dropout == 1`. Thus 614 have a recorded final-item response, including refusals,
whereas the manuscript reports 618 completions and defines completion as reaching
the final economic item. This is an unresolved difference between recorded codes
and the stated definition, not proof that four respondents never reached a screen.
Historical timing or assembly records could explain that distinction. All 618
released cases remain in the replication baseline.

## Numerical claims and interpretation

`scripts/05_claims.R` generates `tabs/prose_claims.csv`: 28 targeted checks covering
assignment, recorded completion, instruction times, extreme answers, correct and
refusal rates, party composition, observed bias, and model-predicted bias. The final
script's extreme-answer comments are 9.97%, 9.78%, and 9.46%, which reproduce at the
stated precision. Their denominators include negative nonresponse codes; each also
supports the manuscript's approximate “ten percent” description.

The printed consistent-partisan control bias of 14.6 points uses Study 2 only,
while the accompanying “whole sample” 11.5-point comparator pools both studies.
The same-study unrestricted control bias is 9.915 points. Both printed values
reproduce, but their comparison changes study coverage as well as composition.

The incentive-by-cue interaction's reported one-tailed p=.23 does not establish
attenuation. Failure to reject equality of incentive effects is not an equivalence
test. Reproducing estimates does not resolve those interpretation limits. The
response-level estimand also weights people by their number of classifiable answers;
it is not an equally weighted respondent-level mean when response counts differ.
See `descriptive_audit.md` and `model_audit.md` for implementation validation limits.

## Version reconciliation

The audit initially examined an older extracted July 15 directory. Its `incomp`
construction was missing, its appendix command produced 13 dropouts, and two
extreme-answer comments were stale (10.16% and 9.99%). Those findings are historical
and superseded by the canonical July 29 ZIP. They are not corrections required by
the final replication package. The final scripts also revise Figure 1's hardcoded
intervals and explicitly state the completed-sample composition denominator.

A complete normalized diff found unchanged `PSK_Functions.do`, bootstrap commands,
model specifications, knowledge scoring, economic scoring, and LOWESS commands.
The manuscript comparison targets are the local final July 31, 2015 DOCX files.
Tables 1–4 and targeted headline passages also agree with the typeset publication;
see `publication_verification.md`. The separately published appendix has not been
verified against its typeset version.
Figure 1 combines GLLAMM point predictions with JAGS intervals, so they must not be
presented as estimates from one common fitted model.

## Re-run and remaining inputs

Run `Rscript scripts/00_upstream.R` from the archive root. It saves
`data/build/upstream_wide.rds` and `tabs/upstream_comparison.csv`; all 41 mismatch
counts must be zero. Subsequent preparation compares recoded wide and long data
to the final release checkpoints. The original sources remain unchanged.

Completing the provenance chain requires the missing 2008 survey delivery and
`KN2008visual.recoding.do`; the historical assembly script would additionally
confirm the reconstructed mappings. These missing files do not prevent exact
replication from the available checkpoint. They do limit an audit of original
knowledge coding, assessed in the [separate sensitivity audit](knowledge_audit.md).
