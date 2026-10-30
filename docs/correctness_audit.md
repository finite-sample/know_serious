# How correctness was coded

The central issue is the meaning of a correct answer. The main economic outcome uses
broad, empirically chosen intervals intended to classify roughly one-third of answers as
correct. Those intervals differ from both the factual answer and the range that earned
payment. The coding reproduces, but the magnitude and precision of the estimated effects
depend on that definition. This audit separates that construct choice from key errors,
historical inconsistencies, and the subsequent coding of partisan bias.

This is a retrospective sensitivity analysis, specified in the [audit plan](correctness_plan.md).
The published baseline remains intact. The earlier [knowledge audit](knowledge_audit.md)
changes the predictor's composition; this audit changes how the outcome is classified.

## Economic answers: factual keys, payment, and analytical correctness

| Item | Key | Unit | Main correct range | Payment range |
| --- | --- | --- | --- | --- |
| Unemployment 2008 |  4.80 | % | 4.2–5.4 | 3.8–5.8 |
| Uninsured 2008 | 15.80 | % | 12.6–19 | 14.8–16.8 |
| Gas Price 2008 |  3.27 | $/gallon | 3.22–3.32 | 3.17–3.37 |
| Uninsured 2004 | 15.60 | % | 2–29.2 | 12.6–18.6 |
| Poverty 2004 | 12.50 | % | 4.5–20.5 | 9.5–15.5 |

All boundaries are inclusive. A response below the interval is an underestimate; one above
it is an overestimate. Thus 2% and 29% uninsured in 2004 both count as correct around a
15.6% key. These are deliberately chosen analytical tolerances, not transcription mistakes.
The manuscript explains that the 33% definition approximates the difficulty of the closed
questions and limits the influence of extreme numeric answers. It also reports alternative
23%, payment, and relative-10% definitions. Relative 10% is not ten percentage points:
it gives gas a much wider window than the main definition and 2004 uninsured a much narrower one.

The Census reports support
[2003 uninsured 15.6% and poverty 12.5%](https://www2.census.gov/prod2/popscan/p60-226.pdf)
and [2006 uninsured 15.8%](https://www2.census.gov/library/publications/2007/demo/p60-233/p60-233.pdf).
These are historical releases, not today's revised series. The dated unemployment and gas keys
require additional qualifications below. The [complete interval ledger](../tabs/correctness_windows.csv)
includes every released definition and the offset of each interval's midpoint from its key.

Closed economic items use these codes after reconstruction:

| Item | Credited answer | Analysis code | Direction and limits |
| --- | --- | --- | --- |
| Debt 2004 | $7.5 trillion | 5 | Lower codes understate, higher codes overstate |
| Debt 2008 | $9.5 trillion | 5 | Gross federal debt, not debt held by the public |
| Unemployment 2004 | About 5% | 2 | Original q13 options are reversed before classification |
| Estate tax, both studies | Fewer than 5% | 1 | Lowest offered category; no possible underestimated category |

The [Federal Reserve debt table](https://www.federalreserve.gov/Pubs/supplement/2008/11/table1_41.htm)
reports $9.438 trillion in 2008 Q1, consistent with the nearest offered $9.5 trillion answer.
For estate tax, [IRS evidence on 2004 decedents](https://www.irs.gov/pub/irs-soi/04esreturnbul.pdf)
supports the broad under-5% category, but is retrospective evidence rather than recovery of
the original source used in designing both questionnaires. This audit verifies code mappings
more completely than it recovers the original documentary source for every closed-item key.

## Where the empirical windows came from

The [March 2013 script](../data/raw/window_provenance/quick_analyses_2013_03_01.do)
loads the full 2004 survey and constructs the windows without restricting to the short-time
conditions used in the paper. Its comments match the full-sample rates below, including
24-hour conditions excluded from the publication sample. This is evidence of the calibration
population; it is not a recovered, executable algorithm for selecting an optimal window.

| item | frame | valid_responses | correct_responses | correct_percent |
| --- | --- | --- | --- | --- |
| Uninsured 2004 | full_2004_nonnegative | 1175 | 382 | 32.51 |
| Uninsured 2004 | published_2004_valid |  591 | 176 | 29.78 |
| Poverty 2004 | full_2004_nonnegative | 1176 | 433 | 36.82 |
| Poverty 2004 | published_2004_valid |  601 | 211 | 35.11 |

The full-sample historical denominator retains nonnegative out-of-range answers; the final
published denominator drops impossible uninsured percentages. Neither calibration is a
control-only or independent validation sample. Standard errors below condition on fixed
windows and do not account for their empirical selection.

The [historical workbook](../data/raw/window_provenance/open_coding_4.xlsx), sheet `open.coding.3`,
has the correct main bounds in G3/G4 but transposes the approximately 32.5% and 36.8%
correct shares in G11/G12. That is a worksheet documentation error; the published code uses
the intended bounds, so no coefficient change follows from correcting those two cells.

## Specific inconsistencies and date-dependent keys

**Uninsured 2008, 23% window.** The final [recode script](../data/raw/final_bundle/PSK_Recodes.do)
uses 13.59–17, whose midpoint is 15.295 rather than 15.8. The historical script and workbook
F7 instead use 14–17.6, symmetric around 15.8. Eight answers change category under that
alternative. The historical evidence does not establish why the final asymmetric version
was selected. Its model impact is small in this data, as the tables below show.

**Auxiliary gas window.** `tri_pp` uses $3.17–$3.27 rather than the symmetric $3.17–$3.37.
Changing the upper bound adds 268 correct answers. However, `tri_pp` is only tabulated in the
released analysis; the published models use `tri_33`, `tri_23`, `tri_10`, or `tri_po`.
The actual payment variable `tri_po` has the symmetric bound. This auxiliary inconsistency
therefore has no demonstrated effect on a published model. The coherent one-point/ten-cent
variant below is an additional definition, not a repair silently applied to the baseline.

**Unemployment changed during fieldwork.** The questionnaire retained 4.8%, the latest figure
at launch. BLS announced 5.1% at 8:30 a.m. EDT on
[April 4, 2008](https://www.bls.gov/news.release/archives/empsit_04042008.htm).
There are 92 valid responses from interviews starting April 5 or later; 8 give 5.1%.
The date-linked alternative moves the main interval from 4.2–5.4 to 4.5–5.7 for these interviews.
The conservative next-day cutoff avoids relying on an unverified timestamp timezone. It does
not identify the precise information available at the moment of each answer, and it is not
a reconstruction of a changed payment rule.

**Gas prices varied during fieldwork.** An existing respondent-linked file has national prices
from $3.261 to $3.339, labeled as the previous day's price. Its values track interview finish
dates. Centering the main ±$0.05 interval on these prices changes 38 classifications and
reduces correct answers from 484 to 462. The original AAA download and item-specific times
are unavailable, so this is a reference-date sensitivity, not a proven superior factual key.
The public [derived reference file](../data/extracted/economic_references_2008.csv) contains
only IDs and keys; extraction and source hashes document its lineage without publishing dates or geography.

| comparison | valid_responses | changed_classification | before_correct | after_correct |
| --- | --- | --- | --- | --- |
| uninsured_23_symmetric | 1482 |   8 | 353 | 357 |
| gas_auxiliary_symmetric | 1488 | 268 | 421 | 689 |
| unemployment_dated | 1486 |   6 | 498 | 502 |
| gas_dated | 1488 |  38 | 484 | 462 |

Counts above include all valid responses, irrespective of party or treatment. They are not
the estimation samples used below. The date-linked model changes unemployment and gas together.

## What changes in the estimates

First, the pooled monetary-versus-control contrast uses the Table 1 sample and response weighting:
valid partisan responses, no Bush reference, both studies. Bias is the share of congenial errors
minus the share of uncongenial errors. Negative estimates mean less bias. Uncertainty uses
respondent-cluster delta standard errors with two-sided 95% intervals; these are not the
paper's one-sided tests or its exact bootstrap implementation.

| Definition | Monetary effect on bias, pp [95% CI] | Monetary effect on correctness, pp [95% CI] |
| --- | --- | --- |
| Published 33% | -5.38 [-10.27, -0.49] | 4.16 [0.83, 7.48] |
| Published 23% | -6.17 [-11.33, -1.01] | 4.12 [1.09, 7.16] |
| Within 10% of key | -4.42 [-9.51, 0.67] | 2.97 [-0.01, 5.95] |
| Payment ranges | -4.42 [-9.55, 0.70] | 3.30 [0.25, 6.35] |
| One percentage point / ten cents | -4.76 [-9.98, 0.45] | 3.27 [0.30, 6.25] |
| 23%, symmetric uninsured range | -6.13 [-11.28, -0.97] | 4.17 [1.14, 7.21] |
| 33%, date-linked keys | -5.56 [-10.46, -0.67] | 3.96 [0.65, 7.28] |

Every definition retains a negative point estimate for the monetary effect on bias. Several
intervals include zero. Thus direction is stable here, while magnitude and inferential precision
depend on the definition of correctness. Crossing a significance threshold is not itself a
test that two definitions yield different effects.

Next, keep the published knowledge score and all 1,260 respondents / 6,233 responses in Table 4
fixed. Refit the multinomial random-intercept model under each outcome definition. Here the
incentive pools the appeal and monetary arms, unlike the monetary-only contrast above. Knowledge
moderation is the incentive effect on bias at score 9.5 minus the effect at score 4.5, averaging
equally over the five Study 2 items and integrating the random effect. Negative values indicate
a larger bias reduction at higher knowledge. Intervals use the full inverse-Hessian delta method.

| Definition | Knowledge moderation, pp [95% CI] | Joint interaction p |
| --- | --- | --- |
| Published 33% | -7.82 [-14.70, -0.93] | 0.0366 |
| Published 23% | -8.61 [-15.78, -1.43] | 0.0323 |
| Within 10% of key | -5.02 [-11.46, 1.42] | 0.1883 |
| Payment ranges | -8.37 [-15.28, -1.46] | 0.0102 |
| One percentage point / ten cents | -8.37 [-15.28, -1.46] | 0.0102 |
| 23%, symmetric uninsured range | -8.51 [-15.69, -1.33] | 0.0362 |
| 33%, date-linked keys | -8.19 [-15.09, -1.30] | 0.0274 |

Payment and coherent one-point ranges coincide for Study 2, so their Table 4 estimates are
identical; they differ in the pooled contrast because their Study 1 ranges differ. The joint
p-value tests two knowledge-by-incentive coefficients and is not the test for the displayed
probability contrast. All alternative fits converged with positive Hessians; 31/61-node
parameter differences are below 0.005. These exploratory intervals are pointwise and do not
adjust for the family of definitions or for window selection.

## General knowledge: which answers actually receive credit

The table traces canonical numeric responses to the available checkpoint scores. All observed
checkpoint scores agree with these keys. This validates the mapping in the available data,
not the unavailable original survey deployment and visual-recoding script.

| Item | Key code | Credited answer | In published score | Correct responses |
| --- | --- | --- | --- | --- |
| e1 | 3 | Robert Gates | TRUE |  651 |
| e2 | 1 | Nancy Pelosi | TRUE | 1137 |
| e3 | 2 | John Roberts | TRUE |  495 |
| e4 | 1 | Mahmoud Ahmadinejad | TRUE |  892 |
| e5 | 3 | Secretary of State | TRUE | 1109 |
| e6 | 2 | Ben Bernanke | TRUE |  576 |
| e7 | 1 | Michael Mukasey | TRUE |  342 |
| e8 | 1 | Nicolas Sarkozy | TRUE |  605 |
| e9_1 | 2 | Democrat | TRUE |  750 |
| e9_2 | 1 | Republican | TRUE | 1044 |
| e9_3 | 1 | Republican | TRUE | 1110 |
| e9_4 | 1 | Republican | TRUE |  660 |
| e10_1 | 4 | Not a US senator in 2002 | FALSE |  281 |
| e10_2 | 1 | For the bill | FALSE | 1025 |
| e10_3 | 1 | For the bill | FALSE |  592 |
| e10_4 | 1 | For the bill | FALSE |  598 |
| e11 | 1 | Newt Gingrich | FALSE |  781 |
| e12 | 4 | John Kerry | FALSE |  837 |

Historical officeholding sources support the eight identification keys:
[Gates](https://georgewbush-whitehouse.archives.gov/government/gates-bio.html),
[Pelosi](https://history.house.gov/people/office/speakers-list/),
[Roberts](https://www.supremecourt.gov/about/oath/oathsofthechiefjustices.aspx),
[Ahmadinejad, March 2008 presidential papers, printed p. 316](https://www.govinfo.gov/content/pkg/WCPD-2008-03-10/pdf/WCPD-2008-03-10.pdf),
[Rice](https://history.state.gov/departmenthistory/people/rice-condoleezza),
[Bernanke](https://www.federalreserve.gov/aboutthefed/bios/board/boardmembership.htm),
[Mukasey](https://www.justice.gov/ag/bio/mukasey-michael-b), and
[Sarkozy](https://www.elysee.fr/en/nicolas-sarkozy).
[FEC primary results](https://www.fec.gov/documents/1660/2008pres.pdf) support the party keys.
The [2002 Senate roll call](https://www.senate.gov/legislative/LIS/roll_call_votes/vote1072/vote_107_2_00237.htm)
records Clinton, Edwards, and Biden voting for authorization; Obama was not then a US senator.

**Rice note versus actual key.** The clean questionnaire's E5 programming note says Secretary
of Defense, but its response labels, the appendix answer, and code 3 identify Secretary of
State. The data credit Secretary of State. The note is wrong; there is no demonstrated
mis-scoring of the 1,109 credited answers.

**Randomized answer order.** Pelosi's identity is canonical code 1, while `e2_ord1`–`e2_ord4`
record display positions. All 1,590 complete orders are permutations. Correct Pelosi answers
appear in every display position (284, 291, 292, 270). E10 likewise stores named answer
categories alongside an order indicator. Applying another position-to-identity conversion
would change the meaning of these stored codes; the checkpoint gives no evidence that one
is needed. Original deployment details remain unavailable.

**Ideological ranking is a different kind of key.** E11 credits Gingrich as most conservative
and E12 credits Kerry as most liberal. This audit verifies the recorded keys and scores, but
does not establish a unique objective ideological scale for those comparisons. Both items
are excluded from the published score. Their inclusion in the expanded-score sensitivity
changes the construct as well as its length.

**Senate composition.** The published item gives graded credit and treats 51 Democrats / 49
Republicans as fully correct, counting the two independents with the Democratic caucus.
The question's party-membership wording also supports 49 Democrats / 49 Republicans.
The [previous audit](knowledge_audit.md) separately quantifies strict caucus, strict membership,
and no-Senate scoring; it should not be conflated with an outcome-coding correction.

## Units, missing answers, and partisan direction

The release converts 132 gas answers of 100 or more from cents to dollars, including exactly 100.
The comment says greater than 100, but the condition is greater than or equal to 100. One
source gas answer above 500 and one negative answer are removed upstream. Two impossible
2004 uninsured percentages above 100 are removed; the other percentage items have no
observed above-100 responses. Rounding answers to six decimal places changes no classification
under any released window. The audit found no floating-point boundary defect.

Economic negative codes become missing and leave the accuracy denominator. In the knowledge
score, explicit don't-know and recorded -1 answers receive zero, while ordinary missing
components propagate to a missing total. Some -1 values were synthesized from an observed
timer and an absent answer, so they should not all be interpreted as deliberate refusals.
Counting these recorded economic nonanswers as incorrect adds 79 pooled answers and changes the monetary accuracy effect from 4.16 to 4.28 pp; its alternative 95% interval is [0.99, 7.58].
Unasked/system-missing responses remain excluded. No partisan direction is assigned to a nonanswer.

Finally, correctness and congeniality are separate transformations. For most items,
overestimates count as congenial for Democrats and underestimates for Republicans. Estate
tax reverses that direction: an exaggerated tax reach is treated as congenial for Republicans.
That interpretation is substantive, and the lowest offered correct category makes estate
tax structurally one-sided. As a diagnostic, imposing the common direction on estate tax
changes the pooled monetary effect on bias from -5.38 to -7.25 pp; omitting unit conversion gives -5.32 pp.
Neither diagnostic is recommended as a correction: a uniform direction may misrepresent
estate-tax rhetoric, and treating cents as dollars discards plausible unit information.

## Remaining author/provenance questions

The unresolved questions are why the final 23% uninsured interval became asymmetric; whether
the full 2004 sample was the intended calibration population; and whether contemporaneous
or fixed questionnaire keys best match the intended accuracy construct. The historical files
establish what was coded more firmly than why. None of these gaps is evidence that a
particular definition was selected to obtain a favorable result.

## Reproduction

After the original `make analysis`, run `make correctness`. It runs the item-level checks,
refits outcome alternatives, and regenerates this report. It uses only public inputs;
`make extract` is an optional maintainer step requiring hash-verified private originals.

- [Window and factual-key ledger](../tabs/correctness_windows.csv)
- [Item correct shares under all definitions](../tabs/correctness_item_rates.csv)
- [Pooled and study-specific treatment contrasts](../tabs/correctness_effects.csv)
- [Knowledge contrasts](../tabs/correctness_knowledge_contrasts.csv)
  and [fit diagnostics](../tabs/correctness_model_diagnostics.csv)
- [Knowledge keys and missingness](../tabs/correctness_knowledge_keys.csv)
- [Calibration](../tabs/correctness_calibration.csv)
  and [classification changes](../tabs/correctness_classification_changes.csv)
- [Units and direction diagnostics](../tabs/correctness_direction_units.csv)
- [Nonresponse](../tabs/correctness_nonresponse.csv)
- [Normalization counts](../tabs/correctness_normalization.csv)
- [Randomized positions](../tabs/correctness_randomization.csv)

