
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



