f <- 'TMTB ~ FO.high + cSVDtrans + age + sex + educationyears'

m.TMT <- d.dFC %>% 
  dplyr::filter(FO.high > 0) %>%
  inner_join(d.struct) %>% 
  inner_join(d.clinical) %>% 
  group_by(design, atlas, cSVDmeas) %>% 
  dplyr::filter(TMTB > 0, educationyears > 0) %>% 
  nest() %>% 
  mutate(f = map(data, ~if_else(all(.$yzero==0), f, paste(f, 'yzero', sep = '+'))) ## use mixture model only when they are zero values in the cSVD measure
         , mdl = map2(data, f, ~glm(formula = as.formula(..2), data = ..1, family = Gamma(link = 'log')))
         , tidy = map(mdl, ~tidy(., exponentiate = TRUE, conf.int = TRUE))
         , n = map(data, nrow)
  ) %>%
  unnest(cols = c(tidy, n))

