source("renv/activate.R")
require(tidyverse)
require(betareg)
require(broom)
require(patchwork)


forestplot <- function(df, effect.null = NULL, effect.pilot = 0.08830623
                       , breaks.x = c(0.05, 0.1, 0.15)
                       , limits.x = c(0, 0.2)
                       , breaks.y = designs
                       , axis.title.y = 'Confound regression strategy'
                       , estimate = 'Difference in fractional ocupancy between high- and low-occupancy brain states'
                       , dodge.width = -.75
                       ){
  df %>% 
    ggplot(aes(y = design, color = atlas, x = estimate, xmin = conf.low, xmax = conf.high, alpha = p.value < 0.05)) +
    geom_hline(data = NULL, yintercept = '36p', size = 20, color = 'lightyellow', alpha = .5) +
    geom_vline(xintercept = effect.null) +
    geom_vline(data = NULL, xintercept = effect.pilot, color = 'grey50') +
    geom_linerange(aes(y = design, group = atlas), position = position_dodge(width = dodge.width)
                   , xmin = -Inf, xmax = Inf, color = 'lightgrey', linetype = '52', alpha = .5, size = .25) +
    geom_point(size = 2, position = position_dodge(width = dodge.width), shape = 18) +
    geom_errorbarh(aes(size = atlas), height = .75, position = position_dodge(width = dodge.width)) +
    scale_x_continuous(name = estimate, limits = limits.x,  breaks = breaks.x, expand = expansion(0,0)) +
    scale_y_discrete(name = axis.title.y, limits = rev, breaks = breaks.y) +
    scale_color_discrete(name = 'Brain parcellation') +
    scale_size_manual(name = 'Brain parcellation', values = c(rep(.5,length(atlasses)-1), 1)) +
    scale_alpha_manual(values = c(`TRUE` = 1, `FALSE`=.25)) +
    guides(alpha = 'none') +
    theme_minimal() +
    theme(axis.text.y = element_text(angle = 90, hjust = .5)
          , legend.position = 'bottom'
          , legend.title.align = .5
          , panel.grid.major.y = element_blank()
          , panel.grid.minor = element_blank()
          , axis.title = element_text(size = 6)
          , axis.text = element_text(size = 4))  
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
  labeller.design <- df %>% group_by(design, atlas) %>% summarise(n=n()) %>% summarise(nn=mean(n)) %>% mutate(lab = paste0(design, '\n(n=', nn, ')')) %>% dplyr::select(-nn) %>% deframe()
  df %>% 
    ggplot(aes(x = {{x}}, y = {{y}})) +
    geom_rect(data = df.stats, aes(fill =  estimate < 1, alpha = p.value < 0.05), inherit.aes = FALSE,
              xmin = -Inf ,xmax = Inf, ymin = -Inf, ymax = Inf) +
    geom_point(alpha = .025, size = .5) +
    geom_smooth(method = smooth.method, formula = smooth.formula, method.args = smooth.method.args, color = 'brown', fill = 'orange', alpha = .2, size = .25) +
        scale_y_continuous(name = '', position = 'right') + # Fractional occupancy / TMT-B [s]
    scale_x_continuous(name = axis.title.x, trans = trans, breaks = breaks.x) +
    facet_grid(design ~ atlas, scales = 'free', switch = 'y', labeller = labeller(design = as_labeller(labeller.design))) +
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
