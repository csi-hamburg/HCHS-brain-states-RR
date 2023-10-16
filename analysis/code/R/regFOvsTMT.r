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


