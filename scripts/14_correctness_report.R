read_table <- function(name) readr::read_csv(paste0("tabs/correctness_", name, ".csv"), show_col_types = FALSE)
markdown_table <- function(table) {
  c(
    paste0("| ", paste(names(table), collapse = " | "), " |"),
    paste0("| ", paste(rep("---", ncol(table)), collapse = " | "), " |"),
    apply(table, 1, function(row) paste0("| ", paste(row, collapse = " | "), " |")), ""
  )
}
interval <- function(table) sprintf("%.2f [%.2f, %.2f]", table$estimate_pp, table$lower_95_pp, table$upper_95_pp)
labels <- c(
  published_33 = "Published 33%", published_23 = "Published 23%", relative_10 = "Within 10% of key",
  payout = "Payment ranges", one_point_symmetric = "One percentage point / ten cents",
  worksheet_23_symmetric = "23%, symmetric uninsured range", dated_33 = "33%, date-linked keys"
)
windows <- read_table("windows")
main <- windows[windows$window == "33", ]
payment <- windows[windows$window == "po", ]
window_display <- data.frame(
  Item = main$item, Key = main$factual_key,
  Unit = c("%", "%", "$/gallon", "%", "%"),
  Main = paste(main$lower_inclusive, main$upper_inclusive, sep = "–"),
  Payment = paste(payment$lower_inclusive, payment$upper_inclusive, sep = "–")
)
names(window_display)[4:5] <- c("Main correct range", "Payment range")
effects <- read_table("effects")
pooled <- effects[effects$study == "pooled" & effects$statistic == "contrast_1_bias", ]
accuracy <- effects[effects$study == "pooled" & effects$statistic == "contrast_1_correct", ]
moderation <- read_table("knowledge_contrasts")
moderation <- moderation[moderation$contrast == "moderation", ]
diagnostics <- read_table("model_diagnostics")
stopifnot(setequal(pooled$variant, names(labels)), setequal(moderation$variant, names(labels)))
effect_display <- data.frame(
  Definition = unname(labels[pooled$variant]), Bias = interval(pooled),
  Accuracy = interval(accuracy[match(pooled$variant, accuracy$variant), ])
)
names(effect_display)[2:3] <- c("Monetary effect on bias, pp [95% CI]", "Monetary effect on correctness, pp [95% CI]")
moderation_display <- data.frame(
  Definition = unname(labels[moderation$variant]), Moderation = interval(moderation),
  Joint = sprintf("%.4f", diagnostics$p_value[match(moderation$variant, diagnostics$variant)])
)
names(moderation_display)[2:3] <- c("Knowledge moderation, pp [95% CI]", "Joint interaction p")
keys <- read_table("knowledge_keys")
key_display <- keys[c("item", "correct_code", "correct_answer", "included_in_published_score", "correct_responses")]
names(key_display) <- c("Item", "Key code", "Credited answer", "In published score", "Correct responses")
calibration <- read_table("calibration")
calibration$correct_percent <- round(calibration$correct_percent, 2)
changes <- read_table("classification_changes")
change_display <- changes[c(
  "comparison", "valid_responses", "changed_classification", "before_correct", "after_correct"
)]
normalization <- read_table("normalization")
count <- function(rule) normalization$count[match(rule, normalization$rule)]
nonresponse <- read_table("nonresponse")
direction <- read_table("direction_units")
writeLines(c(
  "# How correctness was coded", "",
  "The central issue is the meaning of a correct answer. The main economic outcome uses",
  "broad, empirically chosen intervals intended to classify roughly one-third of answers as",
  "correct. Those intervals differ from both the factual answer and the range that earned",
  "payment. The coding reproduces, but the magnitude and precision of the estimated effects",
  "depend on that definition. This audit separates that construct choice from key errors,",
  "historical inconsistencies, and the subsequent coding of partisan bias.", "",
  "This is a retrospective sensitivity analysis, specified in the [audit plan](correctness_plan.md).",
  "The published baseline remains intact. The earlier [knowledge audit](knowledge_audit.md)",
  "changes the predictor's composition; this audit changes how the outcome is classified.", "",
  "## Economic answers: factual keys, payment, and analytical correctness", "",
  markdown_table(window_display),
  "All boundaries are inclusive. A response below the interval is an underestimate; one above",
  "it is an overestimate. Thus 2% and 29% uninsured in 2004 both count as correct around a",
  "15.6% key. These are deliberately chosen analytical tolerances, not transcription mistakes.",
  "The manuscript explains that the 33% definition approximates the difficulty of the closed",
  "questions and limits the influence of extreme numeric answers. It also reports alternative",
  "23%, payment, and relative-10% definitions. Relative 10% is not ten percentage points:",
  "it gives gas a much wider window than the main definition and 2004 uninsured a much narrower one.", "",
  "The Census reports support",
  "[2003 uninsured 15.6% and poverty 12.5%](https://www2.census.gov/prod2/popscan/p60-226.pdf)",
  "and [2006 uninsured 15.8%](https://www2.census.gov/library/publications/2007/demo/p60-233/p60-233.pdf).",
  "These are historical releases, not today's revised series. The dated unemployment and gas keys",
  "require additional qualifications below. The [complete interval ledger](../tabs/correctness_windows.csv)",
  "includes every released definition and the offset of each interval's midpoint from its key.", "",
  "Closed economic items use these codes after reconstruction:", "",
  "| Item | Credited answer | Analysis code | Direction and limits |",
  "| --- | --- | --- | --- |",
  "| Debt 2004 | $7.5 trillion | 5 | Lower codes understate, higher codes overstate |",
  "| Debt 2008 | $9.5 trillion | 5 | Gross federal debt, not debt held by the public |",
  "| Unemployment 2004 | About 5% | 2 | Original q13 options are reversed before classification |",
  "| Estate tax, both studies | Fewer than 5% | 1 | Lowest offered category; no possible underestimated category |", "",
  "The [Federal Reserve debt table](https://www.federalreserve.gov/Pubs/supplement/2008/11/table1_41.htm)",
  "reports $9.438 trillion in 2008 Q1, consistent with the nearest offered $9.5 trillion answer.",
  "For estate tax, [IRS evidence on 2004 decedents](https://www.irs.gov/pub/irs-soi/04esreturnbul.pdf)",
  "supports the broad under-5% category, but is retrospective evidence rather than recovery of",
  "the original source used in designing both questionnaires. This audit verifies code mappings",
  "more completely than it recovers the original documentary source for every closed-item key.", "",
  "## Where the empirical windows came from", "",
  "The [March 2013 script](../data/raw/window_provenance/quick_analyses_2013_03_01.do)",
  "loads the full 2004 survey and constructs the windows without restricting to the short-time",
  "conditions used in the paper. Its comments match the full-sample rates below, including",
  "24-hour conditions excluded from the publication sample. This is evidence of the calibration",
  "population; it is not a recovered, executable algorithm for selecting an optimal window.", "",
  markdown_table(calibration),
  "The full-sample historical denominator retains nonnegative out-of-range answers; the final",
  "published denominator drops impossible uninsured percentages. Neither calibration is a",
  "control-only or independent validation sample. Standard errors below condition on fixed",
  "windows and do not account for their empirical selection.", "",
  "The [historical workbook](../data/raw/window_provenance/open_coding_4.xlsx), sheet `open.coding.3`,",
  "has the correct main bounds in G3/G4 but transposes the approximately 32.5% and 36.8%",
  "correct shares in G11/G12. That is a worksheet documentation error; the published code uses",
  "the intended bounds, so no coefficient change follows from correcting those two cells.", "",
  "## Specific inconsistencies and date-dependent keys", "",
  "**Uninsured 2008, 23% window.** The final [recode script](../data/raw/final_bundle/PSK_Recodes.do)",
  "uses 13.59–17, whose midpoint is 15.295 rather than 15.8. The historical script and workbook",
  "F7 instead use 14–17.6, symmetric around 15.8. Eight answers change category under that",
  "alternative. The historical evidence does not establish why the final asymmetric version",
  "was selected. Its model impact is small in this data, as the tables below show.", "",
  "**Auxiliary gas window.** `tri_pp` uses $3.17–$3.27 rather than the symmetric $3.17–$3.37.",
  "Changing the upper bound adds 268 correct answers. However, `tri_pp` is only tabulated in the",
  "released analysis; the published models use `tri_33`, `tri_23`, `tri_10`, or `tri_po`.",
  "The actual payment variable `tri_po` has the symmetric bound. This auxiliary inconsistency",
  "therefore has no demonstrated effect on a published model. The coherent one-point/ten-cent",
  "variant below is an additional definition, not a repair silently applied to the baseline.", "",
  "**Unemployment changed during fieldwork.** The questionnaire retained 4.8%, the latest figure",
  "at launch. BLS announced 5.1% at 8:30 a.m. EDT on",
  "[April 4, 2008](https://www.bls.gov/news.release/archives/empsit_04042008.htm).",
  sprintf(
    "There are %d valid responses from interviews starting April 5 or later; %d give 5.1%%.",
    count("dated_unemployment_valid"), count("dated_unemployment_answer_5_1")
  ),
  "The date-linked alternative moves the main interval from 4.2–5.4 to 4.5–5.7 for these interviews.",
  "The conservative next-day cutoff avoids relying on an unverified timestamp timezone. It does",
  "not identify the precise information available at the moment of each answer, and it is not",
  "a reconstruction of a changed payment rule.", "",
  "**Gas prices varied during fieldwork.** An existing respondent-linked file has national prices",
  "from $3.261 to $3.339, labeled as the previous day's price. Its values track interview finish",
  "dates. Centering the main ±$0.05 interval on these prices changes 38 classifications and",
  "reduces correct answers from 484 to 462. The original AAA download and item-specific times",
  "are unavailable, so this is a reference-date sensitivity, not a proven superior factual key.",
  "The public [derived reference file](../data/extracted/economic_references_2008.csv) contains",
  "only IDs and keys; extraction and source hashes document its lineage without publishing dates or geography.", "",
  markdown_table(change_display),
  "Counts above include all valid responses, irrespective of party or treatment. They are not",
  "the estimation samples used below. The date-linked model changes unemployment and gas together.", "",
  "## What changes in the estimates", "",
  "First, the pooled monetary-versus-control contrast uses the Table 1 sample and response weighting:",
  "valid partisan responses, no Bush reference, both studies. Bias is the share of congenial errors",
  "minus the share of uncongenial errors. Negative estimates mean less bias. Uncertainty uses",
  "respondent-cluster delta standard errors with two-sided 95% intervals; these are not the",
  "paper's one-sided tests or its exact bootstrap implementation.", "",
  markdown_table(effect_display),
  "Every definition retains a negative point estimate for the monetary effect on bias. Several",
  "intervals include zero. Thus direction is stable here, while magnitude and inferential precision",
  "depend on the definition of correctness. Crossing a significance threshold is not itself a",
  "test that two definitions yield different effects.", "",
  "Next, keep the published knowledge score and all 1,260 respondents / 6,233 responses in Table 4",
  "fixed. Refit the multinomial random-intercept model under each outcome definition. Here the",
  "incentive pools the appeal and monetary arms, unlike the monetary-only contrast above. Knowledge",
  "moderation is the incentive effect on bias at score 9.5 minus the effect at score 4.5, averaging",
  "equally over the five Study 2 items and integrating the random effect. Negative values indicate",
  "a larger bias reduction at higher knowledge. Intervals use the full inverse-Hessian delta method.", "",
  markdown_table(moderation_display),
  "Payment and coherent one-point ranges coincide for Study 2, so their Table 4 estimates are",
  "identical; they differ in the pooled contrast because their Study 1 ranges differ. The joint",
  "p-value tests two knowledge-by-incentive coefficients and is not the test for the displayed",
  "probability contrast. All alternative fits converged with positive Hessians; 31/61-node",
  "parameter differences are below 0.005. These exploratory intervals are pointwise and do not",
  "adjust for the family of definitions or for window selection.", "",
  "## General knowledge: which answers actually receive credit", "",
  "The table traces canonical numeric responses to the available checkpoint scores. All observed",
  "checkpoint scores agree with these keys. This validates the mapping in the available data,",
  "not the unavailable original survey deployment and visual-recoding script.", "",
  markdown_table(key_display),
  "Historical officeholding sources support the eight identification keys:",
  "[Gates](https://georgewbush-whitehouse.archives.gov/government/gates-bio.html),",
  "[Pelosi](https://history.house.gov/people/office/speakers-list/),",
  "[Roberts](https://www.supremecourt.gov/about/oath/oathsofthechiefjustices.aspx),",
  paste0("[Ahmadinejad, March 2008 presidential papers, printed p. 316]",
         "(https://www.govinfo.gov/content/pkg/WCPD-2008-03-10/pdf/WCPD-2008-03-10.pdf),"),
  "[Rice](https://history.state.gov/departmenthistory/people/rice-condoleezza),",
  "[Bernanke](https://www.federalreserve.gov/aboutthefed/bios/board/boardmembership.htm),",
  "[Mukasey](https://www.justice.gov/ag/bio/mukasey-michael-b), and",
  "[Sarkozy](https://www.elysee.fr/en/nicolas-sarkozy).",
  "[FEC primary results](https://www.fec.gov/documents/1660/2008pres.pdf) support the party keys.",
  "The [2002 Senate roll call](https://www.senate.gov/legislative/LIS/roll_call_votes/vote1072/vote_107_2_00237.htm)",
  "records Clinton, Edwards, and Biden voting for authorization; Obama was not then a US senator.", "",
  "**Rice note versus actual key.** The clean questionnaire's E5 programming note says Secretary",
  "of Defense, but its response labels, the appendix answer, and code 3 identify Secretary of",
  "State. The data credit Secretary of State. The note is wrong; there is no demonstrated",
  "mis-scoring of the 1,109 credited answers.", "",
  "**Randomized answer order.** Pelosi's identity is canonical code 1, while `e2_ord1`–`e2_ord4`",
  "record display positions. All 1,590 complete orders are permutations. Correct Pelosi answers",
  "appear in every display position (284, 291, 292, 270). E10 likewise stores named answer",
  "categories alongside an order indicator. Applying another position-to-identity conversion",
  "would change the meaning of these stored codes; the checkpoint gives no evidence that one",
  "is needed. Original deployment details remain unavailable.", "",
  "**Ideological ranking is a different kind of key.** E11 credits Gingrich as most conservative",
  "and E12 credits Kerry as most liberal. This audit verifies the recorded keys and scores, but",
  "does not establish a unique objective ideological scale for those comparisons. Both items",
  "are excluded from the published score. Their inclusion in the expanded-score sensitivity",
  "changes the construct as well as its length.", "",
  "**Senate composition.** The published item gives graded credit and treats 51 Democrats / 49",
  "Republicans as fully correct, counting the two independents with the Democratic caucus.",
  "The question's party-membership wording also supports 49 Democrats / 49 Republicans.",
  "The [previous audit](knowledge_audit.md) separately quantifies strict caucus, strict membership,",
  "and no-Senate scoring; it should not be conflated with an outcome-coding correction.", "",
  "## Units, missing answers, and partisan direction", "",
  sprintf(
    "The release converts %d gas answers of 100 or more from cents to dollars, including exactly 100.",
    count("gas_cents_divided_100")
  ),
  "The comment says greater than 100, but the condition is greater than or equal to 100. One",
  "source gas answer above 500 and one negative answer are removed upstream. Two impossible",
  "2004 uninsured percentages above 100 are removed; the other percentage items have no",
  "observed above-100 responses. Rounding answers to six decimal places changes no classification",
  "under any released window. The audit found no floating-point boundary defect.", "",
  "Economic negative codes become missing and leave the accuracy denominator. In the knowledge",
  "score, explicit don't-know and recorded -1 answers receive zero, while ordinary missing",
  "components propagate to a missing total. Some -1 values were synthesized from an observed",
  "timer and an absent answer, so they should not all be interpreted as deliberate refusals.",
  sprintf(
    paste0(
      "Counting these recorded economic nonanswers as incorrect adds %d pooled answers and changes ",
      "the monetary accuracy effect from %.2f to %.2f pp; its alternative 95%% interval is [%.2f, %.2f]."
    ),
    diff(nonresponse$usable_answers), nonresponse$estimate_pp[1], nonresponse$estimate_pp[2],
    nonresponse$lower_95_pp[2], nonresponse$upper_95_pp[2]
  ),
  "Unasked/system-missing responses remain excluded. No partisan direction is assigned to a nonanswer.", "",
  "Finally, correctness and congeniality are separate transformations. For most items,",
  "overestimates count as congenial for Democrats and underestimates for Republicans. Estate",
  "tax reverses that direction: an exaggerated tax reach is treated as congenial for Republicans.",
  "That interpretation is substantive, and the lowest offered correct category makes estate",
  "tax structurally one-sided. As a diagnostic, imposing the common direction on estate tax",
  sprintf(
    "changes the pooled monetary effect on bias from %.2f to %.2f pp; omitting unit conversion gives %.2f pp.",
    direction$estimate_pp[1], direction$estimate_pp[2], direction$estimate_pp[3]
  ),
  "Neither diagnostic is recommended as a correction: a uniform direction may misrepresent",
  "estate-tax rhetoric, and treating cents as dollars discards plausible unit information.", "",
  "## Remaining author/provenance questions", "",
  "The unresolved questions are why the final 23% uninsured interval became asymmetric; whether",
  "the full 2004 sample was the intended calibration population; and whether contemporaneous",
  "or fixed questionnaire keys best match the intended accuracy construct. The historical files",
  "establish what was coded more firmly than why. None of these gaps is evidence that a",
  "particular definition was selected to obtain a favorable result.", "",
  "## Reproduction", "",
  "After the original `make analysis`, run `make correctness`. It runs the item-level checks,",
  "refits outcome alternatives, and regenerates this report. It uses only public inputs;",
  "`make extract` is an optional maintainer step requiring hash-verified private originals.", "",
  "- [Window and factual-key ledger](../tabs/correctness_windows.csv)",
  "- [Item correct shares under all definitions](../tabs/correctness_item_rates.csv)",
  "- [Pooled and study-specific treatment contrasts](../tabs/correctness_effects.csv)",
  "- [Knowledge contrasts](../tabs/correctness_knowledge_contrasts.csv)",
  "  and [fit diagnostics](../tabs/correctness_model_diagnostics.csv)",
  "- [Knowledge keys and missingness](../tabs/correctness_knowledge_keys.csv)",
  "- [Calibration](../tabs/correctness_calibration.csv)",
  "  and [classification changes](../tabs/correctness_classification_changes.csv)",
  "- [Units and direction diagnostics](../tabs/correctness_direction_units.csv)",
  "- [Nonresponse](../tabs/correctness_nonresponse.csv)",
  "- [Normalization counts](../tabs/correctness_normalization.csv)",
  "- [Randomized positions](../tabs/correctness_randomization.csv)", ""
), "docs/correctness_audit.md")
