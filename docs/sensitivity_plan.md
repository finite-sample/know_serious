# Retrospective knowledge and item sensitivity plan

This plan follows examination of the published results, reproduced models, original
score distribution, missingness, and baseline probability contrasts. It is an
exploratory audit, not a preregistration or a blinded analysis. Baseline results
remain unchanged. No alternative-score model results have been examined at this
point in the audit.

The first comparison keeps Table 4's 1,260 respondents and 6,233 classifiable item
responses fixed, retains the original penalized multinomial random-intercept
likelihood and question effects, and changes only knowledge measurement. The target
is the modeled incentive effect on congenial-minus-uncongenial response probability
and how it varies with the measured score. Knowledge itself is not randomized.
Identification of an incentive effect conditional on knowledge also requires the
score to be measured before treatment and not affected by incentive assignment.

Compare these scores, each expressed on a 0–13 range:

1. The published twelve binary components plus fractional Senate credit.
2. Strict Senate credit using the appendix key: 51 Democrats or 49 Republicans.
3. Strict literal party-membership credit: 49 for either named party.
4. Omit the Senate component; multiply the twelve-item sum by 13/12.
5. Add the six available Iraq-vote and ideological-ordering items, with keys
   4/1/1/1/1/4, and multiply the nineteen-component sum by 13/19.

The last alternative broadens the construct and uses the checkpoint's scoring of
missing extra responses as zero. This is an explicit alternative measurement rule,
not a recovered publication rule. Verify the checkpoint's six binary components
against raw responses. For strict Senate variants, retain zero for missing numeric
responses only where the published Senate component already supplies zero; do not
impute respondents excluded by the published score. Report changed-score counts.

Use the same five-item mixture for every model prediction: each item receives
weight 1/5 and the random intercept is integrated out. Report incentive effects at
4.5 and 9.5 points (the baseline respondent quartiles), their difference, and
two-sided 95% delta-method intervals from each fit's inverse observed Hessian.
These are fixed fractions of the scale, not necessarily the alternative score's
quartiles or equivalent latent knowledge. They are model-based intervals,
conditional on each scoring specification; they do not include uncertainty about
which specification is appropriate. Report the joint interaction test, but do not
select a scoring rule by its p-value. The family is exploratory; intervals are
pointwise and no multiplicity-adjusted confirmatory claim is made.

Verify optimization and compare 31- and 61-node quadrature. Record sample counts
and preserve baseline outputs. Check independently whether filling the 103 missing
published knowledge scores could add any usable partisan-model respondents.

For economic-item selection, first omit each of the ten published economic items
in turn from the pooled monetary-versus-control descriptive comparison. Keep the
published partisan and reference-wording rules and report respondent-cluster delta
intervals. This measures dependence on particular included items. It does not
settle whether the omitted international-tax or campaign-proposal questions belong
in the target construct; adding those requires a separately documented direction
and definition of partisan-congenial answers.

Omitting a study-specific item also changes the relative numbers of observed
answers contributed by the two studies. These are response-weighted pooled
influence estimates, not effects standardized to a fixed study mixture.

Randomized knowledge-question formats and broader leave-one-knowledge-item-out
checks remain extensions. The initial family above directly tests Senate credit,
the Senate key, exclusion of that component, and the six excluded knowledge items.
