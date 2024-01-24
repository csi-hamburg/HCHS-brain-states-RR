confounds <- list.files(path = './../../../derivatives/fmriprep', pattern = '*.tsv$', full.names = TRUE, recursive = TRUE)

d.motion <- map_df(.x = confounds, .f = ~read_tsv(., show_col_types = FALSE
                                               , col_types = cols_only(dvars = col_double()
                                                                       , framewise_displacement = col_double()
                                                                       , rmsd = col_double())), .id = 'filename') %>% 
  mutate(filename = confounds[as.numeric(filename)])

dd.motion <- d.motion %>% 
  mutate(ID = str_match(filename, "sub-\\s*(.*?)\\s*/ses")[,2]) %>% 
  group_by(ID) %>%
  summarise(across(c(dvars, rmsd, framewise_displacement), ~mean(., na.rm = TRUE))) %>% 
  ungroup() %>% 
  #summarise(across(c(dvars, rmsd, framewise_displacement), list(mean = ~mean(., na.rm = TRUE), sd = ~sd(., na.rm = TRUE)))) %>% 
  dplyr::filter(ID %in% read_lines('./../../../input/final_batch.dat'))

dd.motion %>% 
  pivot_longer(cols = dvars:framewise_displacement, names_to = 'motionvar', values_to = 'motionval') %>% 
  ungroup() %>% 
  group_by(motionvar) %>% 
  reframe(quantile(motionval), q = c(0, .25, .5, .75, 1))

dd.motion %>% left_join(d.struct) %>% 
  dplyr::filter(cSVDmeas == 'WMHsmooth') %>%
  pivot_longer(cols = dvars:framewise_displacement, names_to = 'motionvar', values_to = 'motionval') %>% 
  ggplot(aes(x = cSVDvalue, y = motionval, color = motionvar)) +
  scale_x_log10() +
  geom_point() +
  geom_smooth(method = 'glm', method.args = list(family = gaussian()), color = 'black', fill = 'black') +
  facet_wrap(~motionvar, scales = 'free_y')

## models
d.Fig2a.motion <- d.dFC %>% 
  inner_join(d.struct) %>%
  inner_join(d.clinical) %>% 
  inner_join(dd.motion) %>% 
  ungroup() %>% 
  dplyr::filter(design == '36p', atlas == 'schaefer400x7', cSVDmeas == 'WMHsmooth')  # primary analytical choices
m.Fig2a.motion <- betareg(FO.high ~ cSVDtrans + yzero + age + sex + dvars + rmsd + framewise_displacement, data = d.Fig2a.motion)
m.Fig2a.motion %>% 
  tidy(conf.int = TRUE) %>% 
  select(c(term, estimate, p.value, conf.low, conf.high)) %>% 
  mutate(across(c(estimate, starts_with('conf')), exp)) %>% 
  xtable::xtable(type = "latex", tabular.environment="longtable", digits = 4)

d.Fig2b.motion <- d.dFC %>% 
  inner_join(d.struct) %>%
  inner_join(d.clinical) %>%
  inner_join(dd.motion) %>% 
  ungroup() %>%  
  dplyr::filter(design == '36p', atlas == 'schaefer400x7', cSVDmeas == 'WMHsmooth', TMTB > 0)  # primary analytical choices

m.Fig2b.motion <- glm(TMTB ~ cSVDtrans + yzero + FO.high  + age + sex + educationyears + dvars + rmsd + framewise_displacement, data = d.Fig2b.motion, family = Gamma(link = 'log'))
m.Fig2b.motion %>% 
  tidy(exponentiate = TRUE, conf.int = TRUE) %>% 
  select(c(term, estimate, p.value, conf.low, conf.high)) %>% 
  xtable::xtable(type = "latex", tabular.environment="longtable", digits = 4)
