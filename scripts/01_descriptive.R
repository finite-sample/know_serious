source("R/descriptive.R")
responses <- readRDS("data/build/published_long.rds")
readr::write_csv(summarize_table_one(responses), "tabs/table_1.csv")
missingness <- as.data.frame(table(
  study_year = responses$pollid, treatment = responses$rd,
  response_missing = is.na(responses$cong_33)
))
names(missingness)[names(missingness) == "Freq"] <- "response_count"
readr::write_csv(
  missingness,
  "tabs/response_missingness.csv"
)
