source("renv/activate.R")
require(tidyverse)
require(betareg)
require(broom)
require(patchwork)
require(gtsummary)
require(effects)

design_keys <- c(`24p` = '24p', `24p_gsr` = '24p + GSR'
                 , `36p` = '36p', `36p_spkreg` = '36p + spike regression', `36p_despike` = '36p + despiking', `36p_scrub` = '36p + motion scrubbing'
                 , `acompcor` = 'a-CompCor', `tcompcor` = 't-CompCor', `aroma` = 'ICA-AROMA')
atlas_keys <- c(`desikanKilliany` = 'Desikan-Killiany', `aal116` = 'AAL-116'
                , `HarvardOxford` = 'Harvard-Oxford', `power264` = 'Power-264', `gordon333` = 'Gordon-333', `glasser360` = 'Glasser-360'
                , `schaefer100x7` = 'Schaefer-100', `schaefer200x7` = 'Schaefer-200', `schaefer400x7` = 'Schaefer-400')

forestplot <- function(df, effect.null = NULL, effect.pilot = 0.08830623
                       , breaks.x = c(0, 0.05, 0.1)
                       , limits.x = c(0, 0.12)
                       , breaks.y = atlas_keys
                       , axis.title.y = 'Confound regression strategy'
                       , estimate = 'Difference in fractional ocupancy between high- and low-occupancy brain states'
                       , dodge.width = -.75
                       ){
  
  df %>% 
    mutate(design = dplyr::recode(design, !!!design_keys)
           , atlas = dplyr::recode(atlas, !!!atlas_keys)) %>% 
    ggplot(aes(y = atlas, x = estimate, xmin = conf.low, xmax = conf.high, alpha = p.value < 0.05, color = design, shape = design)) +
    geom_hline(data = NULL, yintercept = 'Schaefer-400', linewidth = 20, color = 'lightblue', alpha = .5) +
    geom_vline(xintercept = effect.null) +
    geom_vline(data = NULL, xintercept = effect.pilot, color = 'deepskyblue3') +
    annotate("text", x = effect.pilot, y = 0, label = formatC(effect.pilot, digits = 2), color = 'deepskyblue3', vjust = 1.5, size = 3) +
    geom_point(aes(group = design), size = 1.5, position = position_dodge(width = dodge.width)) +
    geom_linerange(aes(size = design, linetype = design), position = position_dodge(width = dodge.width)) + 
    scale_x_continuous(name = estimate, limits = limits.x,  breaks = breaks.x, expand = expansion(0,0)) +
    scale_y_discrete(name = axis.title.y, limits = rev, breaks = breaks.y, guide = guide_axis(n.dodge = 2)) +
    scale_color_manual(name = 'Confound regression strategy', values = c(rep('black',2), 'mediumblue', rep('black',6))) +
    scale_size_manual(name = 'Confound regression strategy', values = c(rep(.1,2), .2, rep(.1,6))) +
    scale_alpha_manual(values = c(`TRUE` = 1, `FALSE` = .5)) +
    scale_shape_manual(name = 'Confound regression strategy', values = c(rep(18,2), 16, rep(18,6))) +
    scale_linetype_discrete(name = 'Confound regression strategy') +
    guides(alpha = 'none', color = guide_legend(title.position = 'top')) +
    coord_cartesian(clip = 'off') +
    theme_minimal() +
    theme(axis.text.y = element_text(angle = 90, hjust = .5)
          , legend.position = 'bottom'
          , legend.key.width = unit(2.7,"line")
          , legend.key.height = unit(.5,"line")
          , legend.text = element_text(size = 5)
          , legend.title = element_text(size = 6)
          , legend.title.align = 0
          , panel.grid.major.y = element_blank()
          , panel.grid.minor = element_blank()
          , axis.title = element_text(size = 6)
          , axis.text = element_text(size = 5))
}


cSVDlabels <- c('WMHsmooth' = 'Total white matter hyperintensity volume [ml]'
                , 'WMHsmoothperi' = 'Periventricular white matter hyperintensity volume [ml]'
                , 'WMHsmoothdeep' = 'Deep white matter hyperintensity volume [ml]'
                , 'psmd' = 'PSMD')

panelplot <- function(df, df.stats, x = cSVDvalue, y = FO.high
                      , trans = 'log10'
                      , cSVDmeas 
                      , axis.title.x = cSVDlabels[cSVDmeas]
                      , breaks.x = c(0.1, 1, 10)
                      , smooth.method = 'lm', smooth.formula = 'y~x', smooth.method.args = NULL){
  labeller.design <- df %>%
    group_by(design, atlas) %>% 
    summarise(n=n()) %>% 
    summarise(nn=mean(n)) %>% 
    mutate(lab = paste0(design, '\n(n=', nn, ')')) %>% 
    dplyr::select(-nn) %>% 
    deframe()
  
  df %>% 
    ggplot(aes(x = {{x}}, y = {{y}})) +
    geom_rect(data = df.stats, aes(fill =  estimate < 1, alpha = p.value < 0.05), inherit.aes = FALSE,
              xmin = -Inf ,xmax = Inf, ymin = -Inf, ymax = Inf) +
    geom_point(alpha = .025, size = .5) +
    geom_smooth(method = smooth.method, formula = smooth.formula, method.args = smooth.method.args, color = 'brown', fill = 'orange', alpha = .2, linewidth = .25) +
        scale_y_continuous(name = '', position = 'right') + # Fractional occupancy / TMT-B [s]
    scale_x_continuous(name = axis.title.x, trans = trans, breaks = breaks.x) +
    facet_grid(atlas ~ design, scales = 'free', switch = 'y', labeller = labeller(design = as_labeller(labeller.design))) +
    guides(fill = 'none', alpha = 'none') +
    theme_bw() +
    theme(panel.grid = element_blank()
          , strip.background = element_blank()
          , strip.text = element_text(size = 4)
          , legend.position = 'bottom', legend.direction = 'horizontal'
          , axis.title = element_text(size = 6)
          , axis.text = element_text(size = 4)
          , axis.ticks = element_line(size = 0.1))
  
}

