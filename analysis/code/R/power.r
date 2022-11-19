data <- d.dFC %>% dplyr::filter(design=='36p', atlas=='schaefer400x7')

sample.sizes <- c(nrow(data), 1500, seq(200,1600,200), seq(900,1100,10)) %>% sort() %>% unique()
sample.sizes

p <- function(data, i = 1:nrow(data)){
  lapply(sample.sizes, function(n){
    dd <- data %>% 
    inner_join(d.struct %>% dplyr::filter(cSVDmeas == 'WMHsmooth'), by = 'ID') %>% 
    inner_join(d.clinical, by = 'ID') %>% 
    slice_sample(., n = n, replace = TRUE)
    
    f <- 'FO.high ~ cSVDtrans + age + sex'
    f <- if_else(all(dd$yzero==0), f, paste(f, 'yzero', sep = '+'))
    
    betareg(as.formula(f), data = dd, link = 'logit', link.phi = 'log') %>% 
      tidy(., conf.int = TRUE) %>%
      mutate(across(c(estimate, starts_with('conf')), exp)) %>% 
      dplyr::filter(component == 'mean' & term == 'cSVDtrans') %>% 
      pull(p.value)
  }) %>% unlist() %>% setNames(sample.sizes)
}

p.out <- lapply(1:10000, function(k)p(data)) %>% 
  bind_rows() %>% 
  pivot_longer(cols = everything(), names_to = 'n', values_to = 'power') %>% 
  mutate(n = as.numeric(n)) %>%
  group_by(n) %>% 
  summarise(across(.cols = everything(), .fns = list(m = ~mean(. < 0.05), se = ~sd(. < 0.05)/sqrt(n()))))

n.80 <- p.out %>% dplyr::filter(power_m >= 0.80) %>% arrange(n) %>% slice_head() %>% pull(n)


p.out %>% 
  ggplot(aes(x = n, y = power_m)) +
  geom_line(size = 0.1) +
  geom_segment(data = ~dplyr::filter(., n %in% c(n.80, nrow(data), 1500)), aes(xend = n), yend = 0, color = 'orange') +
  geom_segment(data = ~dplyr::filter(., n %in% c(n.80, nrow(data), 1500)), aes(yend = power_m), xend = 0, color = 'orange') +
  geom_point(data = ~dplyr::filter(., n %in% c(n.80, nrow(data), 1500)), shape = 21, size = 5, color = 'orange', fill = 'yellow', stroke = 2) +
  geom_point(data = ~dplyr::filter(., ! n %in% c(n.80, nrow(data), 1500)), shape = 21, size = 2, color = 'black', fill = 'white', stroke = 1) +
  geom_smooth(method = 'loess', se = FALSE, color = 'darkblue') +
  scale_x_continuous(name = 'Sample size') +
  scale_y_continuous(name = 'Estimated power') +
  theme_bw() +
  theme(axis.text = element_text(size = 12)
        , axis.title = element_text(size = 16))

n.80
p.out %>% dplyr::filter(., n %in% c(n.80, nrow(data), 1500))
