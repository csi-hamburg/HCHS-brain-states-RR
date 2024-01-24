# Model cognitive measures as a function of FO.high
maxvalues <- c(HCH_MMST0033 = 30, HCH_STWA0003 = 10, HCH_MWTB0043 = 37)

m <- c(d.dFC %>% 
  inner_join(d.struct) %>% 
  inner_join(d.clinical) %>% 
  dplyr::filter(atlas == 'schaefer400x7', design == '36p', cSVDmeas == 'WMHsmooth') %>% 
  pivot_longer(cols = c('TMTB', 'HCH_TMTE0003', 'HCH_ANNA0003'), names_to = 'cogmeas', values_to = 'cogvalue') %>% 
  group_by(design, atlas, cSVDmeas, cogmeas) %>% 
  nest() %>% 
  mutate(mdl = map(data, ~glm(as.formula(paste0('cogvalue ~ I(5*FO.high)')), family = Gamma(link = 'log')
                              , data = dplyr::filter(., cSVDvalue > 0, cogvalue > 0)))
         , tidy = map(mdl, ~tidy(., exponentiate = TRUE, conf.int = TRUE))) %$% 
  setNames(as.list(.$mdl), .$cogmeas)
  
  , d.dFC %>% 
    inner_join(d.struct) %>% 
    inner_join(d.clinical) %>% 
    dplyr::filter(atlas == 'schaefer400x7', design == '36p', cSVDmeas == 'WMHsmooth') %>% 
    pivot_longer(cols = c('HCH_MMST0033', 'HCH_STWA0003', 'HCH_MWTB0043'), names_to = 'cogmeas', values_to = 'cogvalue') %>% 
    group_by(design, atlas, cSVDmeas, cogmeas) %>% 
    mutate(maxvalue = maxvalues[as.character(cogmeas)]) %>% 
    nest() %>% 
    mutate(mdl = map(data, ~glm(cbind(cogvalue, I(maxvalue-cogvalue)) ~ I(5*FO.high)
                                , family = binomial(link = 'logit')
                                , data = dplyr::filter(., cSVDvalue > 0), na.action = na.exclude)
           , tidy = map(mdl, ~tidy(., exponentiate = TRUE, conf.int = TRUE)))) %$% 
    setNames(as.list(.$mdl), .$cogmeas)
)

m.adj <- c(d.dFC %>% 
         inner_join(d.struct) %>% 
         inner_join(d.clinical) %>% 
         dplyr::filter(atlas == 'schaefer400x7', design == '36p', cSVDmeas == 'WMHsmooth') %>% 
         pivot_longer(cols = c('TMTB', 'HCH_TMTE0003', 'HCH_ANNA0003'), names_to = 'cogmeas', values_to = 'cogvalue') %>% 
         group_by(design, atlas, cSVDmeas, cogmeas) %>% 
         nest() %>% 
         mutate(mdl = map(data, ~glm(cogvalue ~ I(5*FO.high) + log10(cSVDvalue) + age + sex +educationyears, family = Gamma(link = 'log')
                                     , data = dplyr::filter(., cSVDvalue > 0, cogvalue > 0)))
                , tidy = map(mdl, ~tidy(., exponentiate = TRUE, conf.int = TRUE))) %$% 
         setNames(as.list(.$mdl), .$cogmeas)
       
       , d.dFC %>% 
         inner_join(d.struct) %>% 
         inner_join(d.clinical) %>% 
         dplyr::filter(atlas == 'schaefer400x7', design == '36p', cSVDmeas == 'WMHsmooth') %>% 
         pivot_longer(cols = c('HCH_MMST0033', 'HCH_STWA0003', 'HCH_MWTB0043'), names_to = 'cogmeas', values_to = 'cogvalue') %>% 
         group_by(design, atlas, cSVDmeas, cogmeas) %>% 
         mutate(maxvalue = maxvalues[as.character(cogmeas)]) %>% 
         nest() %>% 
         mutate(mdl = map(data, ~glm(cbind(cogvalue, I(maxvalue-cogvalue)) ~ I(5*FO.high) + log10(cSVDvalue) + age + sex +educationyears
                                     , family = binomial(link = 'logit')
                                     , data = dplyr::filter(., cSVDvalue > 0), na.action = na.exclude)
                          , tidy = map(mdl, ~tidy(., exponentiate = TRUE, conf.int = TRUE)))) %$% 
         setNames(as.list(.$mdl), .$cogmeas)
)

FO.high <- d.dFC %>%  dplyr::filter(atlas == 'schaefer400x7', design == '36p') %>% pull('FO.high')
newFO.high <- seq(min(FO.high, na.rm = TRUE), max(FO.high, na.rm = TRUE), length.out = 1e4)

newdata <- do.call(rbind,lapply(c("HCH_MMST0033", "HCH_MWTB0043", "HCH_STWA0003", "HCH_ANNA0003", "HCH_TMTE0003","TMTB")
                     , function(cogmeas){predict(m[[cogmeas]]
                                                 , type = 'response'
                                                 , se.fit = TRUE
                                                 , newdata = data.frame(FO.high = newFO.high)) %>% 
                         as.data.frame() %>% mutate(FO.high = newFO.high, cogmeas = cogmeas)})
) %>% 
  mutate(fit = case_when(cogmeas == 'HCH_MMST0033' ~ 30*fit
                         , cogmeas == 'HCH_STWA0003' ~ 10*fit
                         , cogmeas == 'HCH_MWTB0043' ~ 37*fit
                         , TRUE ~ fit)
         , se.fit = case_when(cogmeas == 'HCH_MMST0033' ~ 30*se.fit
                              , cogmeas == 'HCH_STWA0003' ~ 10*se.fit
                              , cogmeas == 'HCH_MWTB0043' ~ 37*se.fit
                              , TRUE ~ se.fit)) %>% 
  mutate(cogmeas = factor(cogmeas, levels = c('HCH_MMST0033','HCH_MWTB0043','HCH_STWA0003','HCH_ANNA0003','HCH_TMTE0003','TMTB'), ordered = TRUE))

labs <- lapply(m, function(x)tidy(x, exponentiate = TRUE, conf.int = TRUE)) %>% 
  enframe(name = 'cogmeas') %>% 
  mutate(adj = FALSE, es = if_else(cogmeas %in% c('TMTB', 'HCH_TMTE0003', 'HCH_ANNA0003'), 'exp(b)', 'OR')) %>% 
  unnest(value) %>% 
  dplyr::filter(term == 'I(5 * FO.high)') %>% 
  mutate(lab = paste0(es, ' = ', formatC(estimate, digits = 2, format = 'f')
                      , ' ('
                      , formatC(conf.low, digits = 2, format = 'f')
                      , '–'
                      , formatC(conf.high, digits = 2, format = 'f')
                      , ')'
                      #, P=', formatC(p.value, digits = 3, format = 'f')
                      )) %>% 
  dplyr::select(cogmeas, p.value, lab)

labs.adj <- lapply(m.adj, function(x)tidy(x, exponentiate = TRUE, conf.int = TRUE)) %>% 
  enframe(name = 'cogmeas') %>% 
  mutate(adj = TRUE, es = if_else(cogmeas %in% c('TMTB', 'HCH_TMTE0003', 'HCH_ANNA0003'), 'exp(b)', 'OR')) %>% 
  unnest(value) %>% 
  dplyr::filter(term == 'I(5 * FO.high)') %>% 
  mutate(lab.adj = paste0('a-', es, ' = ', formatC(estimate, digits = 2, format = 'f')
                          , ' (', formatC(conf.low, digits = 2, format = 'f')
                          , '–', formatC(conf.high, digits = 2, format = 'f')
                          , ')'
                          #, aP=', formatC(p.value, digits = 3, format = 'f')
                          )) %>% 
  dplyr::select(cogmeas, p.value.adj = p.value, lab.adj)

ll <- left_join(labs, labs.adj) %>% 
  mutate(ll = paste(lab, lab.adj, sep = '\n')) %>% 
  mutate(cogmeas = factor(cogmeas, levels = c('HCH_MMST0033','HCH_MWTB0043','HCH_STWA0003','HCH_ANNA0003','HCH_TMTE0003','TMTB'), ordered = TRUE))
  
square <- with(ll, data.frame( 
  x = c(-Inf, Inf, Inf, -Inf), 
  y = c(-Inf, -Inf, Inf, Inf)
))


plt.Fig4 <- d.dFC %>% 
  dplyr::filter(FO.high > 0) %>%
  inner_join(d.struct) %>% 
  inner_join(d.clinical) %>% 
  pivot_longer(cols = c("HCH_MMST0033", "HCH_MWTB0043", "HCH_STWA0003", "HCH_ANNA0003", "HCH_TMTE0003","TMTB"), names_to = 'cogmeas', values_to = 'cogvalue') %>% 
  mutate(cogmeas = factor(cogmeas, levels = c('HCH_MMST0033','HCH_MWTB0043','HCH_STWA0003','HCH_ANNA0003','HCH_TMTE0003','TMTB'), ordered = TRUE)) %>% 
  dplyr::filter(atlas == 'schaefer400x7', design == '36p', cSVDmeas == 'WMHsmooth') %>% 
  ggplot(aes(x = FO.high, y = cogvalue)) +
  geom_point(shape = 21, fill = 'lightblue', alpha = .5, size = 1, color = gray(.25)) +
  #geom_hex() + guides(fill = FALSE, color = FALSE) + 
  geom_line(data = newdata
            , aes(x = FO.high, y = fit), inherit.aes = FALSE, color = 'darkblue') +
  geom_ribbon(data = newdata
              , aes(x = FO.high, ymax = fit + 1.96*se.fit, ymin = fit - 1.96*se.fit), inherit.aes = FALSE, fill = 'deepskyblue3', alpha = .5) +
  #geom_polygon(data = merge(square, ll), aes(x = x, y = y, color = cogmeas == 'TMTB'), fill = NA, size = 2, hjust = 2) +
  geom_label(data = ll, mapping = aes(label = ll, x = .22, y  = Inf, color = cogmeas=='TMTB')
             , vjust = 1, size = 2, alpha = .5, inherit.aes = FALSE) +
  geom_text(data = ~group_by(., cogmeas) %>% summarise(N = sum(!is.na(cogvalue))), aes(label = paste0('N=', N), color = cogmeas=='TMTB')
            , x = .22, y = Inf, vjust = 4, inherit.aes = FALSE) +
  facet_wrap(~cogmeas, scales = 'free', strip.position = 'left'
             , labeller = labeller(cogmeas = c('HCH_MMST0033' = 'Mini-mental state exam'
                                               , 'HCH_STWA0003' = 'Word recall [#]'
                                               , 'HCH_TMTE0003' = 'TMT Part A [s]'
                                               , 'TMTB' = 'TMT Part B [s]'
                                               , 'HCH_MWTB0043' = 'Vocabulary [#]'
                                               , 'HCH_ANNA0003'= 'Animal Naming [#]'))) +
  scale_x_continuous('Fractional occupancy of DMN-related brain states', limits = c(0.03, .4), breaks = c(.1, .2, .3, .4), expand = expansion(0,0)) +
  scale_y_continuous('', breaks = scales::pretty_breaks(4), expand = expansion(c(0, .25))) +
  scale_color_manual(values = c('black', 'mediumblue')) +
  scale_fill_gradient(low = "lightblue", high = "darkblue", trans="log10") +
  #ggsci::scale_fill_material(palette = 'teal') +
  guides(color = 'none') +
  theme_classic() +
  theme(strip.placement = 'outside'
        , panel.grid = element_line(size = .25)
        , strip.background = element_blank()
        , axis.text = element_text(size = 8)
        , axis.title = element_text(size = 10))
plt.Fig4
ggsave(plot = plt.Fig4, filename =  'Fig4.svg', path = './../../derivatives/Figures', device = 'svg', width = 19, height = 15, units = 'cm')
