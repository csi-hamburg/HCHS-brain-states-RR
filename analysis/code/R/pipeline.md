---
title: "Functional MRI brain state occupancy in the presence of cerebral small vessel disease – Statistical analysis pipeline for a pre-registered replication analysis of the Hamburg City Health Study"
author: "Eckhard Schlemm"
date: "21 Januar, 2024"
output: 
  html_document:
    keep_md: true
---



In this repository we present the statistical analysis pipeline for a replication of the main effects reported in [Schlemm et al, 2022](https://doi.org/10.1016/j.biopsych.2022.03.019). The replication analysis is based on an independent sample of approximately 1500 HCHS subjects.

# MRI data preprocessing,  white matter lesion segmentation and covariates
Structural and functional MR imaging data have been quality assessed and processed using FreeSurfer, sMRIprep, and fMRIprep. [xcpEngine](https://github.com/PennLINC/xcpEngine) output is available as

`
./derivatives/xcpengine/{design}/sub-{subjectID}/fcon/{atlas}/sub-{subjectID}_{atlas}_ts.1D
`

In [Schlemm et al, 2022](https://doi.org/10.1016/j.biopsych.2022.03.019), we used the '36p' confound regression strategy and the 'schaefer400' atlas. In the following multiverse analysis, we used additional regression strategies and brain parcellations, namely

`
24p, 24p_gsr, 36p_spkreg, 36p_despike, 36p_scrub, aCompCor, tCompCpr, aroma
`

and

`
Desikan-Killiany, AAL-116, Harvard-Oxford, Power-264, Gordon-333, Glasser-360, Schaefer-100, Schaefer-200
`

White matter hyperintensity volumes (total, deep and periventricular) are available in [derivatives/WMH/cSVD.csv](./../../../derivatives/WMH/cSVD_all.csv).

Covariates age, gender and years of education are imported from [input/hchs.csv](./../../../input/hchs_batch2.csv).

# Brain state estimation
k=5 discrete brain states were estimated by clustering BOLD-signals in brain activation space. We use the `kmeans` algorithm implemented in Matlab with the Pearson correlation as distance measure. The relevant code is given in [analysis/code/Matlab/clustering.m](./../Matlab/clustering.m). The script produces subject-specific estimates of fractional occupancies of five brain states, ordered by average fractional occupancy. These are saved as

`
./analysis/derivatives/data/dFCmetrics~{design}~{atlas}~.dat
`

# Statistical analysis

## Data import and preprocessing


```r
source('.Rprofile', chdir = TRUE)
#source('prepdata.r')
load('data.Rdata')
#load('./../../../pilot/data.Rdata')
```


## Check for separation between high- and low occupancy states

We used paired t-tests to compare average fractional occupancy in the two high-occupancy states with the average occupancy in the three low-occupancy states.

```r
d.tt <- d.dFC %>% 
  nest() %>% 
  mutate(t.out = map(data, ~t.test(.$FO.high, .$FO.low, paired = TRUE))
         , estimate = map_dbl(t.out, ~.$estimate)
         , p.value = map_dbl(t.out, ~.$p.value)
         , conf.low = map_dbl(t.out, ~.$conf.int[[1]])
         , conf.high = map_dbl(t.out, ~.$conf.int[[2]])) %>% 
  unnest(cols = c(estimate, p.value, conf.low, conf.high))
```

```r
p.forest.tt <- forestplot(d.tt)
p.forest.tt + theme(legend.position = 'bottom', legend.title = element_blank())
```

![](pipeline_files/figure-html/highVSlowFOplot-1.png)<!-- -->

Point estimates and 95% confidence intervals for the mean in fractional occupancy between high- and low occupancy states are shown for different confound regression strategies and brain parcellations. The primary choices ('36p' and 'schaefer400') are highlighted by a light blue box and dark blue markers, respectively. The effect size reported in [Schlemm et al, 2022](https://doi.org/10.1016/j.biopsych.2022.03.019) is indicated by a vertical line at 0.08830623.

## Association between WMH volume and fractional occupancy
Next, we performed a fixed-dispersion beta-regression between WMH lesion load and average fractional occupancy in the two high-occupancy states. WMH volume was log-transformed, with the base of the log given by the interquartile ratio of the non-zero WMH volumes. Zero WMH volume were recoded as zero after the log-transformation and a zero-indicator (`yzero`) was included in the regression model. Other covariates were age and sex. Estimates were transformed into 'odds ratios' using the exponential function.


```r
f <- 'FO.high ~ cSVDtrans + I(age/10) + sex'

m.preFO <- d.dFC %>% 
    dplyr::filter(FO.high > 0) %>%
    inner_join(d.struct, relationship = 'many-to-many') %>% 
    inner_join(d.clinical, relationship = 'many-to-many') %>% 
    #inner_join(dd.motion) %>% 
    group_by(design, atlas, cSVDmeas) %>% 
    nest() %>% 
    mutate(ff = map(data, ~if_else(all(.$yzero==0), f, paste(f, 'yzero', sep = '+'))) ## use mixture model only when they are zero values in the cSVD measure
           , mdl = map2(data, ff, ~betareg(formula = as.formula(..2), data = ..1, link = 'logit', link.phi = 'log', type = "BC"))
           , tidy = map(mdl, ~tidy(., conf.int = TRUE))
           , n = map(data, nrow)
           )

m.FO <- m.preFO %>% 
  unnest(cols = c(tidy, n)) %>% 
  mutate(across(c(estimate, starts_with('conf')), exp)) 
```


```r
p.forest.beta <- m.FO %>% 
  ungroup() %>% 
  group_by(cSVDmeas) %>% 
  nest() %>% 
  mutate(plt = map(data, ~forestplot(df = dplyr::filter(., term == 'cSVDtrans')
                            , breaks.x = c(.9, 1, 1.1), limits.x = c(.85, 1.1)
                            , breaks.y = atlas_keys
                            , axis.title.y = 'Brain parcellation'
                            , effect.null = 1, effect.pilot = 0.9486211
                            , estimate = 'Association of FO with WMH \n(adjusted odds ratio)')
                ))


p.panel.beta <- d.dFC %>% 
  inner_join(d.struct) %>%
  ungroup() %>% 
  group_by(cSVDmeas) %>% 
  nest() %>% 
  mutate(plt = map2(data, cSVDmeas, ~panelplot(df = ..1
                                    , df.stats = m.FO %>% dplyr::filter(cSVDmeas == ..2, term == 'cSVDtrans')
                                    , cSVDmeas = ..2)))
```

```r
p.panel.beta$plt[[1]] + p.forest.beta$plt[[1]] +  plot_layout(widths = c(2, 1)) & guides(color = 'none', size = 'none') & 
  theme(axis.title = element_text(size = 8), axis.text = element_text(size = 6), strip.text = element_text(size = 6))
```

![](pipeline_files/figure-html/regWMHvsFOplot-1.png)<!-- -->

On the left, we show scatter plots of average FO in high-occupancy states against WMH volume on a logarithmic scale (base 10 for easier visualization) for different combinations of confound regression strategies and brain parcellations. Linear regression lines are visually indistinguishable from beta regression lines and indicate the direction of the unadjusted association between  log(WMH) and FO. Background color of individual panels indicates the direction of the association after adjustment for age, sex and zero WMH volume (green, negative; red, positive). A pale background indicates that the association between log(WMH) and average fractional occupancy is not statistically different from zero. On the right, the same information is shown using point estimates and 95% confidence intervals for the adjusted odds ratio of the association. The effect size reported in [Schlemm et al, 2022](https://doi.org/10.1016/j.biopsych.2022.03.019) is indicated by a vertical line at 0.9486211.

## Association between fractional occupancy and executive function
For this secondary hypothesis, we performed a Poisson regression between average occupancy in the two high-occupancy states and TMT-B scores. WMH volume was included as a covariate and transformed in the same way as before. Other covariates were age, sex and years of education.


```r
f <- 'TMTB ~ I(20*FO.high) + cSVDtrans + I(age/10) + sex + educationyears'

m.preTMT <- d.dFC %>% 
  dplyr::filter(FO.high > 0) %>%
  inner_join(d.struct, relationship = 'many-to-many') %>% 
  inner_join(d.clinical, relationship = 'many-to-many') %>% 
  group_by(design, atlas, cSVDmeas) %>% 
  dplyr::filter(TMTB > 0, educationyears > 0) %>% 
  nest() %>% 
  mutate(f = map(data, ~if_else(all(.$yzero==0), f, paste(f, 'yzero', sep = '+'))) ## use mixture model only when they are zero values in the cSVD measure
         , mdl = map2(data, f, ~glm(formula = as.formula(..2), data = ..1, family = Gamma(link = 'log')))
         , tidy = map(mdl, ~tidy(., exponentiate = TRUE, conf.int = TRUE))
         , n = map(data, nrow)
  ) 

m.TMT <- m.preTMT %>%
  unnest(cols = c(tidy, n))
```


```r
p.forest.gamma <- m.TMT %>% 
  ungroup() %>% 
  group_by(cSVDmeas) %>% 
  nest() %>% 
  mutate(plt = map(data, ~forestplot(df = dplyr::filter(., term == 'I(20 * FO.high)')
                                     , breaks.x = c(.92, .96, 1, 1.06), limits.x = c(0.89, 1.05)
                                     , breaks.y = ''
                                     , axis.title.y = ''
                                     , effect.null = 1, effect.pilot = exp(log(0.735124)/20)
                                     , estimate = 'Association of TMT-B with FO \n(adjusted odds ratio)')
  ))

p.panel.gamma <- d.dFC %>% 
  inner_join(d.struct) %>%
  inner_join(d.clinical) %>%
  ungroup() %>% 
  group_by(cSVDmeas) %>% 
  nest() %>% 
  mutate(plt = map2(data, cSVDmeas, ~panelplot(df = ..1
                                               , df.stats = m.TMT %>% dplyr::filter(cSVDmeas == ..2, term == 'I(20 * FO.high)')
                                               , x = FO.high, y = TMTB
                                               , cSVDmeas = ..2
                                               , axis.title.x = 'Average occupancy in high-occupancy states'
                                               , trans = 'identity'
                                               , breaks.x = c(.1, .2, .3, .4)
                                               , smooth.method = 'glm'
                                               , smooth.method.args = list(family = Gamma(link = 'log')))))
```

```r
p.panel.gamma$plt[[1]] + p.forest.gamma$plt[[1]] +  plot_layout(widths = c(2, 1)) & guides(color = 'none', size = 'none') & 
  theme(axis.title = element_text(size = 8), axis.text = element_text(size = 6), strip.text = element_text(size = 6))
```

![](pipeline_files/figure-html/regFOvsTMTplot-1.png)<!-- -->


## Alternative operationalizations of cSVD severity

### Association between WMH volume and fractional occupancy

Here, we present results for deep and periventricular white matter lesion volume.

```r
p.panel.beta$plt[[2]] + p.forest.beta$plt[[2]] +  plot_layout(widths = c(2, 1)) & guides(color = 'none', size = 'none') & 
  theme(axis.title = element_text(size = 8), axis.text = element_text(size = 6), strip.text = element_text(size = 6))
```

![](pipeline_files/figure-html/regWMHvsFOplot-sens-1.png)<!-- -->

```r
p.panel.beta$plt[[3]] + p.forest.beta$plt[[3]] +  plot_layout(widths = c(2, 1)) & guides(color = 'none', size = 'none') & 
  theme(axis.title = element_text(size = 8), axis.text = element_text(size = 6), strip.text = element_text(size = 6))
```

![](pipeline_files/figure-html/regWMHvsFOplot-sens-2.png)<!-- -->

### Association between fractional occupancy and executive function


```r
p.panel.gamma$plt[[2]] + p.forest.gamma$plt[[2]] +  plot_layout(widths = c(2, 1)) & guides(color = 'none', size = 'none') & 
  theme(axis.title = element_text(size = 8), axis.text = element_text(size = 6), strip.text = element_text(size = 6))
```

![](pipeline_files/figure-html/regFOvsTMTplot-sens-1.png)<!-- -->

```r
p.panel.gamma$plt[[3]] + p.forest.gamma$plt[[3]] +  plot_layout(widths = c(2, 1)) & guides(color = 'none', size = 'none') & 
  theme(axis.title = element_text(size = 8), axis.text = element_text(size = 6), strip.text = element_text(size = 6))
```

![](pipeline_files/figure-html/regFOvsTMTplot-sens-2.png)<!-- -->

# Session info

```r
sessionInfo()
```

```
## R version 4.2.1 (2022-06-23)
## Platform: x86_64-pc-linux-gnu (64-bit)
## Running under: Ubuntu 22.10
## 
## Matrix products: default
## BLAS:   /usr/lib/x86_64-linux-gnu/blas/libblas.so.3.10.1
## LAPACK: /usr/lib/x86_64-linux-gnu/lapack/liblapack.so.3.10.1
## 
## locale:
##  [1] LC_CTYPE=en_US.UTF-8       LC_NUMERIC=C              
##  [3] LC_TIME=de_DE.UTF-8        LC_COLLATE=en_US.UTF-8    
##  [5] LC_MONETARY=de_DE.UTF-8    LC_MESSAGES=en_US.UTF-8   
##  [7] LC_PAPER=de_DE.UTF-8       LC_NAME=C                 
##  [9] LC_ADDRESS=C               LC_TELEPHONE=C            
## [11] LC_MEASUREMENT=de_DE.UTF-8 LC_IDENTIFICATION=C       
## 
## attached base packages:
## [1] stats     graphics  grDevices datasets  utils     methods   base     
## 
## other attached packages:
##  [1] effects_4.2-2   carData_3.0-5   gtsummary_1.7.2 patchwork_1.1.2
##  [5] broom_1.0.1     betareg_3.1-4   forcats_1.0.0   stringr_1.4.1  
##  [9] dplyr_1.1.2     purrr_1.0.2     readr_2.1.3     tidyr_1.2.1    
## [13] tibble_3.2.1    ggplot2_3.4.0   tidyverse_1.3.2
## 
## loaded via a namespace (and not attached):
##  [1] nlme_3.1-159         fs_1.6.2             lubridate_1.9.0     
##  [4] insight_0.19.3       httr_1.4.4           tools_4.2.1         
##  [7] backports_1.4.1      bslib_0.4.1          utf8_1.2.2          
## [10] R6_2.5.1             mgcv_1.8-40          DBI_1.1.3           
## [13] colorspace_2.0-3     nnet_7.3-17          withr_2.5.0         
## [16] tidyselect_1.2.0     compiler_4.2.1       cli_3.6.1           
## [19] rvest_1.0.3          gt_0.9.0             xml2_1.3.3          
## [22] sandwich_3.0-2       labeling_0.4.2       sass_0.4.7          
## [25] scales_1.2.1         lmtest_0.9-40        digest_0.6.30       
## [28] minqa_1.2.5          rmarkdown_2.18       pkgconfig_2.0.3     
## [31] htmltools_0.5.5      lme4_1.1-33          highr_0.9           
## [34] dbplyr_2.2.1         fastmap_1.1.1        rlang_1.1.1         
## [37] readxl_1.4.1         rstudioapi_0.14      farver_2.1.1        
## [40] jquerylib_0.1.4      generics_0.1.3       zoo_1.8-11          
## [43] jsonlite_1.8.3       googlesheets4_1.0.1  magrittr_2.0.3      
## [46] modeltools_0.2-23    Formula_1.2-4        Matrix_1.4-1        
## [49] Rcpp_1.0.10          munsell_0.5.0        fansi_1.0.3         
## [52] lifecycle_1.0.3      stringi_1.7.8        yaml_2.3.6          
## [55] MASS_7.3-58.1        flexmix_2.3-18       grid_4.2.1          
## [58] crayon_1.5.2         lattice_0.20-45      haven_2.5.1         
## [61] splines_4.2.1        hms_1.1.2            knitr_1.40          
## [64] pillar_1.9.0         boot_1.3-28          stats4_4.2.1        
## [67] reprex_2.0.2         glue_1.6.2           evaluate_0.18       
## [70] mitools_2.4          renv_0.17.3          broom.helpers_1.13.0
## [73] modelr_0.1.10        vctrs_0.6.3          nloptr_2.0.3        
## [76] tzdb_0.3.0           cellranger_1.1.0     gtable_0.3.1        
## [79] assertthat_0.2.1     cachem_1.0.6         xfun_0.40           
## [82] survey_4.2-1         survival_3.4-0       googledrive_2.0.0   
## [85] gargle_1.2.1         timechange_0.1.1     ellipsis_0.3.2
```

