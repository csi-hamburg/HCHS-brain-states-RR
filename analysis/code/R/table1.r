library(tidyverse)
library(kableExtra)

clinical <- read_csv(
  "input/hchs_batch2.csv",
  col_types = cols(
    ID = col_character(),
    age = col_double(),
    sex = col_factor(levels = c("0", "1")),
    HCH_MMST0033 = col_double(),
    HCH_MWTB0043 = col_double(),
    HCH_STWA0003 = col_double(),
    HCH_ANNA0003 = col_double(),
    HCH_TMTE0003 = col_double(),
    TMTB = col_double(),
    educationyears = col_double()
  )
) |>
  filter(ID %in% read_lines("input/final_batch.dat")) |>
  left_join(
    read_csv(
      "input/table1_data.csv",
      col_types = cols(
      sub_id = col_character(),
      HCH_SVAH0001 = col_factor(),
      HCH_SVDM0001 = col_factor(),
      vf_rauch_001 = col_factor(),
      HCH_SVHL0001 = col_factor(),
      HCH_ANAM0015 = col_factor()
      )
    ),
    by = join_by("ID" == "sub_id")
  )  |>
  rename(
    female = sex,
    hypertention = HCH_SVAH0001,
    diabetes = HCH_SVDM0001,
    smoking = vf_rauch_001, # 0=nie, 1=raucher, 2=ex-raucher
    hlp = HCH_SVHL0001,
    dementia = HCH_ANAM0015
  ) |>
  mutate(
    hypertention = recode_factor(
      hypertention, "1 - ja" = "1", "0 - nein" = "0"),
    diabetes = recode_factor(diabetes, "1 - ja" = "1", "0 - nein" = "0"),
    smoking = recode_factor(
      smoking, "1" = "1", "0" = "0", "2" = "0",
      "8888" = NA_character_, "9999" = NA_character_),
    hlp = recode_factor(hlp, "1 - ja" = "1", "0 - nein" = "0"),
    dementia = recode_factor(dementia, "1 - ja" = "1", "0 - nein" = "0")
  )

continuous_vars <- c("age", "educationyears")
categorical_vars <- c(
    "female", "hypertention", "diabetes",
    "smoking", "hlp", "dementia")

continuous <- clinical |>
  select(ID, all_of(continuous_vars)) |>
  pivot_longer(
    cols = !ID
  ) |>
  filter(!is.na(value)) |>
  summarise(
    .by = "name",
    Count = n(),
    min = min(value),
    max = max(value),
    mean = mean(value),
    SD = sd(value),
    median = median(value),
    Q1 = quantile(value, probs = .25),
    Q3 = quantile(value, probs = .75)
  ) |>
  mutate(
    print = paste0(median, " (", Q1, " - ", Q3, ")")
  ) |>
  select(
    name,
    Count,
    print
  )

categorical <- clinical |>
  select(ID, all_of(categorical_vars)) |>
  pivot_longer(
    cols = !ID
  ) |>
  filter(!is.na(value)) |>
  summarise(
    .by = "name",
    Count = n(),
    n = sum(value == "1"),
    percent = (n / Count * 100) |> round(1)
  ) |>
  mutate(
    print = paste0(n, " (", percent, ")")
  ) |>
  select(
    name,
    Count,
    print
  )

  continuous |>
  bind_rows(categorical) |>
  mutate(
    name = factor(
      name, 
      levels = c(
        "age", "female", "hypertention", "diabetes",
        "smoking", "hlp", "dementia", "educationyears")
      )
  ) |>
  arrange(name) |>
  kbl(
    caption = "Descriptive statistics of clinical variables in the final cohort. Data are presented as median (interquartile range) or count (percentage), as appropriate.",
    format = "latex",
    col.names = c("", "N", "n (%)/median (IQR)"),
    align = "lrr"
  ) |>
  write_lines("manuscript/src/tables/table1.tex")