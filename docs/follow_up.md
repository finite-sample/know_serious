# Deferred: knowledge measurement and item selection

Begin this work only after the published-specification replication and correctness
audit are complete. Preserve its outputs as the comparison baseline.

The question is how knowledge coding and economic-item selection affect the estimated
relationship between knowledge, partisan response bias, and accuracy incentives.
No alternative estimates have been generated for this follow-up.

1. Recover the full 2008 survey and `KN2008visual.recoding.do`, and document every
   general-knowledge item, answer key, modality, randomization, nonresponse code, and
   timing rule. The available checkpoint has additional e10/e11/e12 items and
   multiple historical knowledge scores that are absent from the released 13-point
   scale. Do not assume these are interchangeable measures.
2. Inspect how `kn_snmaj` was formed before its fractional recoding to .25/.50/.75/1;
   compare its scoring to the appendix's stated numeric answer key. Trace the
   treatment of don't-know, refusal, unasked, and timed-out responses separately.
3. Build an economic-item inclusion ledger from both questionnaires. The historical
   2004 script explicitly marks the US-versus-Europe tax item as not included; its
   presence does not establish that it belongs in the published estimand.
4. Before estimating alternatives, specify the item universe, measurement targets,
   scoring variants, missing-data rules, and how comparisons will separate changes
   in sample composition from changes in outcomes or knowledge measurement.
5. Compare a documented set of alternatives and leave-one-item-out estimates with
   the unchanged baseline. Show effects, intervals, sample sizes, and the role of
   each choice. Distinguish a corrected coding mistake from a different estimand.

Useful source locations: the original 2004 survey and questionnaire, the 2008
questionnaire and `temp.dta` checkpoint, `diff. dv codings/`, the historical Stata
recode scripts, and final appendix Tables A1–A2. This document records research work;
it does not change the first-phase coding rules or select a preferred alternative.
