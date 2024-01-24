data <- d.dFC %>% dplyr::filter(design=='36p', atlas=='schaefer400x7')

sample.sizes <- c(1651, nrow(data), 1500, seq(200,1600,200), seq(900,1100,10)) %>% sort() %>% unique()
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

n.80 <- power_results$p.out %>% dplyr::filter(power_m >= 0.80) %>% arrange(n) %>% slice_head() %>% pull(n)


plt.Fig1 <- power_results$p.out %>% 
  ggplot(aes(x = n, y = power_m)) +
  #geom_line(size = 0.1) +
  geom_segment(data = ~dplyr::filter(., n %in% c(n.80, nrow(data), 1500, 1651)), aes(xend = n), yend = 0, color = 'orange', linewidth = .25) +
  geom_segment(data = ~dplyr::filter(., n %in% c(n.80, nrow(data), 1500, 1651)), aes(yend = power_m), xend = 0, color = 'orange', linewidth = .25) +
  geom_point(data = ~dplyr::filter(., n %in% c(n.80, nrow(data), 1500, 1651)), shape = 21, size = 1.5, color = 'orange', fill = 'yellow', stroke = 1) +
  geom_point(data = ~dplyr::filter(., ! n %in% c(n.80, nrow(data), 1500, 1651)), shape = 21, size = .75, color = 'black', fill = 'white', stroke = .5) +
  ggtext::geom_richtext(data = ~dplyr::filter(., n %in% c(n.80, nrow(data), 1500, 1651)) %>% add_column(vjust = c(.45,.55,.6,.55), hjust = c(1.25,-.25,.5,.5))
                        , mapping = aes(x = n, label = n, vjust = vjust, hjust = hjust), y = .35, size = 1.5
                        , nudge_x = .5, angle = 90, label.padding = unit(c(0,.1,0,.1), 'lines'), label.size = 0, label.margin = unit(c(0,0,0,0), 'lines'), inherit.aes = FALSE) +
  ggtext::geom_richtext(data = ~dplyr::filter(., n %in% c(n.80, nrow(data), 1500, 1651)) %>% add_column(vjust = c(.6,.47,.6,.6), hjust = c(1.25,-.25,1.5,-.5))
                        , mapping = aes(y = power_m, label = power_m, vjust = vjust, hjust = hjust), x = 300, size = 1.5
                        , nudge_x = .5, angle = 0, label.padding = unit(c(0,.1,0,.1), 'lines'), label.size = 0, label.margin = unit(.1, 'lines'), inherit.aes = FALSE) +
  geom_smooth(method = 'loess', se = FALSE, color = 'darkblue', size = .5) +
  scale_x_continuous(name = 'Sample size', limits = c(0,1700), expand = expansion(0,0)) +
  scale_y_continuous(name = 'Estimated power') +
  theme_classic(base_size = 10)
plt.Fig1
ggsave(plot = plt.Fig1, filename =  'Fig1.svg', path = './../../derivatives/Figures', device = 'svg', width = 9, height = 6, units = 'cm')

n.80
power_results$p.out %>% dplyr::filter(., n %in% c(1651, n.80, nrow(data), 1500))
