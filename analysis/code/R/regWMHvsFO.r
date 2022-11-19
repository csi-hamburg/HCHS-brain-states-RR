f <- 'FO.high ~ cSVDtrans + age + sex'

m.FO <- d.dFC %>% 
    dplyr::filter(FO.high > 0) %>%
    inner_join(d.struct) %>% 
    inner_join(d.clinical) %>% 
    group_by(design, atlas, cSVDmeas) %>% 
    nest() %>% 
    mutate(f = map(data, ~if_else(all(.$yzero==0), f, paste(f, 'yzero', sep = '+'))) ## use mixture model only when they are zero values in the cSVD measure
           , mdl = map2(data, f, ~betareg(formula = as.formula(..2), data = ..1, link = 'logit', link.phi = 'log'))
           , tidy = map(mdl, ~tidy(., conf.int = TRUE))
           , n = map(data, nrow)
           ) %>%
  unnest(cols = c(tidy, n)) %>% 
  mutate(across(c(estimate, starts_with('conf')), exp)) 


