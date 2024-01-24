
p.forest.gamma <- m.TMT %>% 
  ungroup() %>% 
  group_by(cSVDmeas) %>% 
  nest() %>% 
  mutate(plt = map(data, ~forestplot(df = dplyr::filter(., term == 'I(20 * FO.high)')
                                     , breaks.x = c(.92, .96, 1, 1.06), limits.x = c(0.88, 1.05)
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



