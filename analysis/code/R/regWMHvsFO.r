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


