library(tidyverse)

first_batch <- read_lines("RR_HCHS_dFC/input/HCHS996.dat")

cSVD_all <- read_csv( # nolint: object_name_linter.
    "RR_HCHS_dFC/derivatives/WMH/cSVD_all.csv",
    col_type = cols(
        ID = col_character(),
        WMHsmooth = col_double(),
        WMHsmoothdeep = col_double(),
        WMHsmoothperi = col_double(),
    )
)

wmh_complete <- pull(cSVD_all, ID)

next10000 <- read_lines("RR_HCHS_dFC/input/next10000.dat")

wmh_complete <- wmh_complete[!wmh_complete %in% next10000]

length(wmh_complete)

missings_exclusions <- read_csv(
    "RR_HCHS_dFC/input/CSI_HCHS_EXPORT_2600_MISSINGS_EXCLUSION.csv",
    col_type = cols(
        sub_id = col_character(),
        ses_id = col_double(),
        nrad_exclusion = col_double(),
        flair_exclusion = col_double(),
        freesurfer_exclusion = col_double(),
        wmh_exclusion = col_double(),
        missing_flair = col_double(),
        missing_t1 = col_double(),
        missing_t2 = col_double(),
        missing_dwi = col_double(),
        missing_func = col_double(),
        missing_asl = col_double(),
        dwi_exclusion = col_double(),
        tbss_exclusion = col_double(),
        psmd_exclusion = col_double(),
        t1_exclusion = col_double(),
        aslprep_exclusion = col_double()
)) |>
    mutate(
        sub_id = str_remove(sub_id, "sub-"),
    ) |>
    mutate_at(
        vars(-sub_id, -ses_id), as.factor)

mri_cohort <- pull(missings_exclusions, sub_id)

missing_t1 <- missings_exclusions |>
    filter(missing_t1 == 1) |> pull(sub_id)
missing_t2 <- missings_exclusions |>
    filter(missing_t2 == 1) |> pull(sub_id)
missing_flair <- missings_exclusions |>
    filter(missing_flair == 1) |> pull(sub_id)
missing_dwi <- missings_exclusions |>
    filter(missing_dwi == 1) |> pull(sub_id)
missing_func <- missings_exclusions |>
    filter(missing_func == 1) |> pull(sub_id)

intraax_raumf <- read_lines("RR_HCHS_dFC/input/subjects_mit_intraax_raumf.csv")

xcp_complete <- read_csv(
    "RR_HCHS_dFC/input/xcp_IDs.dat",
    col_types = cols(
        `24p` = col_character(),
        `24p_gsr` = col_character(),
        `36p` = col_character(),
        `36p_despike` = col_character(),
        `36p_scrub` = col_character(),
        `36p_spkreg` = col_character(),
        acompcor = col_character(),
        aroma = col_character(),
        `aroma-gsr` = col_character(),
        tcompcor = col_character()
)
) |>
    mutate_all(str_remove, "sub-")

xcp_24p <- xcp_complete |>
    filter(!is.na(`24p`)) |> pull(`24p`)
xcp_24p_gsr <- xcp_complete |>
    filter(!is.na(`24p_gsr`)) |> pull(`24p_gsr`)
xcp_36p <- xcp_complete |>
    filter(!is.na(`36p`)) |> pull(`36p`)
xcp_36p_despike <- xcp_complete |>
    filter(!is.na(`36p_despike`)) |> pull(`36p_despike`)
xcp_36p_scrub <- xcp_complete |>
    filter(!is.na(`36p_scrub`)) |> pull(`36p_scrub`)
xcp_36p_spkreg <- xcp_complete |>
    filter(!is.na(`36p_spkreg`)) |> pull(`36p_spkreg`)
xcp_acompcor <- xcp_complete |>
    filter(!is.na(acompcor)) |> pull(acompcor)
xcp_aroma <- xcp_complete |>
    filter(!is.na(aroma)) |> pull(aroma)
xcp_aroma_gsr <- xcp_complete |>
    filter(!is.na(`aroma-gsr`)) |> pull(`aroma-gsr`)
xcp_tcompcor <- xcp_complete |>
    filter(!is.na(tcompcor)) |> pull(tcompcor)

length(mri_cohort)

length(first_batch)

second_batch <- mri_cohort[!mri_cohort %in% first_batch]

length(second_batch)

curious_missings <- first_batch[!first_batch %in% mri_cohort]

length(curious_missings)

second_batch_missing_t1 <- missing_t1[missing_t1 %in% second_batch]

length(second_batch_missing_t1)

second_batch_missing_t2 <- missing_t2[missing_t2 %in% second_batch]

length(second_batch_missing_t2)

second_batch_missing_flair <- missing_flair[missing_flair %in% second_batch]

length(second_batch_missing_flair)

second_batch_missing_dwi <- missing_dwi[missing_dwi %in% second_batch]

length(second_batch_missing_dwi)

second_batch_missing_func <- missing_func[missing_func %in% second_batch]

length(second_batch_missing_func)

second_batch_ex_missing <- second_batch[!second_batch %in% c(second_batch_missing_t1, second_batch_missing_flair, second_batch_missing_func)]

length(second_batch_ex_missing)

second_batch_ex_tumor <- second_batch_ex_missing[!second_batch_ex_missing %in% intraax_raumf]

length(second_batch_ex_tumor)

second_batch_wmh <- wmh_complete[wmh_complete %in% second_batch_ex_tumor]

length(second_batch_wmh)

second_batch_24p <- xcp_24p[xcp_24p %in% second_batch_ex_tumor]

length(second_batch_24p)

unknown_reason_24p <- second_batch_ex_tumor[! second_batch_ex_tumor %in% second_batch_24p]

length(unknown_reason_24p)

unknown_reason_wmh <- second_batch_ex_tumor[! second_batch_ex_tumor %in% second_batch_wmh]

length(unknown_reason_wmh)

common_unknown_reason <- unknown_reason_wmh[unknown_reason_wmh %in% unknown_reason_24p]

length(common_unknown_reason)

unknown_reason_24p <- unknown_reason_24p[!unknown_reason_24p %in% common_unknown_reason]

length(unknown_reason_24p)

unknown_reason_wmh <- unknown_reason_wmh[!unknown_reason_wmh %in% common_unknown_reason]

length(unknown_reason_wmh)

final_batch <- second_batch_24p[second_batch_24p %in% second_batch_wmh]

length(final_batch)

nrad_exlusion <- missings_exclusions |>
    filter(nrad_exclusion == 1) |>
    pull(sub_id)


second_batch[second_batch %in% nrad_exlusion]

write_lines(final_batch, "data/final_batch.dat")
