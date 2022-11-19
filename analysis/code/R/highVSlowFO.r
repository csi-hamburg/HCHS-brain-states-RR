d.tt <- d.dFC %>% 
  nest() %>% 
  mutate(t.out = map(data, ~t.test(.$FO.high, .$FO.low, paired = TRUE))
         , estimate = map_dbl(t.out, ~.$estimate)
         , p.value = map_dbl(t.out, ~.$p.value)
         , conf.low = map_dbl(t.out, ~.$conf.int[[1]])
         , conf.high = map_dbl(t.out, ~.$conf.int[[2]])) %>% 
  unnest(cols = c(estimate, p.value, conf.low, conf.high))


