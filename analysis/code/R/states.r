d.states <- read.csv('./../../derivatives/data/spiderdatall_36p~schaefer400x7.dat', header = FALSE) %>% 
  as_tibble() %>% 
  setNames(c('state', 'network', 'sign', 'value'))

require(magrittr)
require(ggradar)
d.states
p.spider <- d.states %>% 
  mutate(state = recode(state, !!!states) %>% factor(levels = states, ordered = TRUE)) %>% 
  arrange(state) %>% 
  group_by(state) %>% nest() %>%  
  bind_cols(tibble(FO = d.predFC %>% dplyr::filter(design == '36p', atlas == 'schaefer400x7') %>% summarise(across(starts_with('fracocc'), mean)) %>% as.numeric)) %>% 
  mutate(plt = map(data, function(d){d %>% pivot_wider(names_from = network, values_from = value) %>% 
      ggradar(base.size = 6
              #, axis.labels = c('FPCN','DMN','DAT','LIM','SAL','SMN','Vis')
              , axis.labels = c('Vis','SMN','DAT','SAL','LIM','FPCN','DMN')
              , group.point.size = 1, group.line.width = .25
              , axis.label.size = 2, grid.label.size = 2
              , gridline.mid.colour = 'grey'
              , group.colours = c('1'='darkgreen', '-1'='darkred')
              , gridline.max.linetype	= 'solid', values.radar = c("", "50%", "100%")
              , plot.title = paste0(state, " (", scales::percent(FO, accuracy = 0.1), ")"), legend.text.size = 2) + 
      guides(color = 'none') +
      theme(plot.tag = element_text(size = 8)
            , title = element_text(size = 8)
            , legend.title = element_text(size = 8))}
  )) %>% 
  pull('plt') %$% 
  do.call(patchwork::wrap_plots, c(., ncol = 5))

p.spider
ggsave(plot = p.spider, filename =  'spiderplot_36p~schaefer400x7.svg', path = './../../derivatives/Figures', device = 'svg', width = 18, height = 4, units = 'cm')
