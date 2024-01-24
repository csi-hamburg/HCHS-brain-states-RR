attr(d.clinical$age, "label")                   = "Age"
attr(d.clinical$sex, "label")                   = "Sex"
attr(d.clinical$HCH_MMST0033, "label")          = "MMSE"
attr(d.clinical$HCH_MWTB0043, "label")          = "Vocabulary (MWT-B) (max. 37)"
attr(d.clinical$HCH_STWA0003, "label")          = "Word recall (max. 10)"
attr(d.clinical$HCH_ANNA0003, "label")          = "Animal Naming"
attr(d.clinical$HCH_TMTE0003, "label")          = "TMA-A, seconds"
attr(d.clinical$TMTB, "label")                  = "TMT-B, seconds"
attr(d.clinical$educationyears, "label")        = "Years of education"


d.clinical %>% 
  select(-ID) %>% 
  tbl_summary(missing_text = "Missing"
              , missing = "no"
              , type = all_continuous() ~ "continuous2"
              , statistic = all_continuous() ~ c("{median} ({p25}, {p75})",
                                                 "{N_miss} ({p_miss}%)")
              , digits = educationyears ~ 0) %>% 
  modify_header(label ~ "**Variable**") %>% 
  as_gt() %>%
  gt::as_latex() %>% 
  as.character() %>% 
  writeLines()

d.struct %>% 
  select(-ID) %>% 
  tbl_summary(by = "cSVDmeas")

d.dFC %>% 
  dplyr::filter(design == '36p', atlas == 'schaefer400x7') %>% 
  droplevels() %>% 
  select(-ID) %>% 
  tbl_summary()

d.dFC %>% 
  dplyr::filter(design == '36p', atlas == 'schaefer400x7', stringr::str_starts(state, 'DMN')) %>% 
  droplevels() %>% 
  pivot_wider(names_from = 'state', values_from = 'frac_occ') %$% 
  lm(`DMN+` ~ `DMN-`, data = .) %>% summary()
  cor(.['DMN+'], .['DMN-'])
  
d.dFC %>% 
  dplyr::filter(design == '36p', atlas == 'schaefer400x7', stringr::str_starts(state, 'DMN')) %>% 
  droplevels() %>% 
  pivot_wider(names_from = 'state', values_from = 'frac_occ') %>% 
  ggplot(aes(x = `DMN+`, y= `DMN-`)) +
  geom_jitter(shape = 21, alpha = .5) +
  geom_smooth(method = 'lm') +
  theme_classic()

ggsave(plot = last_plot(), filename =  'DMN+corDMN-.svg', path = './../../derivatives/Figures', device = 'svg', width = 9, height = 9, units = 'cm')


d.predFC %>% 
  ungroup() %>% 
  dplyr::filter(design == '36p', atlas == 'schaefer400x7') %>% 
  droplevels() %>% 
  select(-c(ID, design, atlas)) %>%
  tbl_summary(digits = starts_with('fracocc') ~ style_percent) %>% 
  modify_header(label ~ "**Variable**") %>% 
  as_gt() %>%
  gt::as_latex() %>% 
  as.character() %>% 
  writeLines()




m.FO %>% dplyr::filter(design == '36p', atlas == 'schaefer400x7', cSVDmeas == 'WMHsmooth') %>% 
  select(8:15) %>% 
  ungroup() %>% 
  select(c(term, estimate, p.value, conf.low, conf.high)) %>% 
  xtable::xtable(type = "latex", tabular.environment="longtable", digits = 4)

m.FO %>% 
  dplyr::filter(design == '36p', atlas == 'schaefer400x7', cSVDmeas == 'WMHsmooth', component == 'mean') %>%  # primary analytical choices
  ungroup() %>% 
  dplyr::select(term, estimate, conf.low, conf.high, p.value) %>% 
  write.csv(file = './../../derivatives/Tab2a.dat', row.names = FALSE)


## Plot Fig 2a

d.Fig2a <- d.dFC %>% 
  inner_join(d.struct) %>%
  inner_join(d.clinical) %>% 
  ungroup() %>% 
  dplyr::filter(design == '36p', atlas == 'schaefer400x7', cSVDmeas == 'WMHsmooth', cSVDvalue > 0)  # primary analytical choices
m.Fig2a <- betareg(FO.high ~ cSVDtrans + age + sex, data = d.Fig2a)


m.FO %>% dplyr::filter(design == '36p', atlas == 'schaefer400x7', cSVDmeas == 'WMHsmooth') %>% 
  select(8:15) %>% 
  gridExtra::tableGrob(rows = NULL) %>% 
  grid::grid.draw()

Effects.Fig2a <- as.data.frame(allEffects(m.Fig2a, xlevels=list(cSVDtrans = d.Fig2a$cSVDtrans)))$cSVDtrans

plt.Fig2a <-  d.Fig2a %>% 
  ggplot(aes(x = cSVDvalue, y = FO.high)) +
  geom_point(shape = 21, fill = 'lightblue', size = 1, alpha = .5, color = gray(.25)) +
  #geom_smooth(method = 'lm') +
  geom_ribbon(data = Effects.Fig2a, aes(x = 10^cSVDtrans, ymin = lower, ymax = upper), inherit.aes = FALSE, alpha = .5, fill = 'deepskyblue3') +
  geom_line(data = Effects.Fig2a, aes(x = 10^cSVDtrans, y = fit), inherit.aes = FALSE, color = 'darkblue') +
  scale_x_continuous(name = 'WMH volume [ml]', trans = 'log10', breaks = c(.1, 1, 10), limits = c(.01, 50),  labels = scales::number_format(accuracy = .01)) +
  scale_y_continuous(name = 'Frac. occupancy in DMN-related states') +
  theme_classic()
plt.Fig2a
ggsave(plot = plt.Fig2a, filename =  'Fig_hyp1.svg', path = './../../derivatives/Figures', device = 'svg', width = 9, height = 9, units = 'cm')


m.TMT %>% dplyr::filter(design == '36p', atlas == 'schaefer400x7', cSVDmeas == 'WMHsmoothdeep') %>% 
  select(7:14)

m.TMT %>% 
  dplyr::filter(design == '36p', atlas == 'schaefer400x7', cSVDmeas == 'WMHsmoothdeep') %>%  # primary analytical choices
  ungroup() %>% 
  select(c(term, estimate, p.value, conf.low, conf.high)) %>% 
  xtable::xtable(type = "latex", tabular.environment="longtable", digits = 4)


## Plot Fig 2b
d.Fig2b <- d.dFC %>% 
  inner_join(d.struct) %>%
  inner_join(d.clinical) %>%
  ungroup() %>%  
  dplyr::filter(design == '36p', atlas == 'schaefer400x7', cSVDmeas == 'WMHsmooth', cSVDvalue > 0, TMTB > 0)  # primary analytical choices

m.Fig2b <- glm(TMTB ~ cSVDtrans + FO.high  + age + sex + educationyears, data = d.Fig2b, family = Gamma(link = 'log'))

Effects.Fig2b <- as.data.frame(allEffects(m.Fig2b, xlevels=list(FO.high = d.Fig2b$FO.high)))$FO.high

plt.Fig2b <- d.Fig2b %>% 
  ggplot(aes(x = FO.high, y = TMTB)) +
  geom_point(shape = 21, fill = 'lightblue', size = 1, alpha = .5, color = gray(.25)) +
  #geom_smooth(method = 'glm', method.args = list(family = Gamma(link = 'log'))) +
  geom_ribbon(data = Effects.Fig2b, aes(x = FO.high, ymin = lower, ymax = upper), inherit.aes = FALSE, alpha = .5, fill = 'deepskyblue3') +
  geom_line(data = Effects.Fig2b, aes(x = FO.high, y = fit), inherit.aes = FALSE, color = 'darkblue') +
  scale_x_continuous(name = 'Frac. occupancy in DMN-related states', labels = scales::number_format(accuracy = .01)) +
  scale_y_continuous(name = 'TMT-B [s]', trans = 'log10') +
  theme_classic()

plt.Fig2b

ggsave(plot = plt.Fig2b, filename =  'Fig_hyp2.svg', path = './../../derivatives/Figures', device = 'svg', width = 9, height = 9, units = 'cm')


plt.Fig2 <- plt.Fig2a + plt.Fig2b + plot_layout(ncol = 2) + plot_annotation(tag_levels = 'A', tag_suffix = ')')
plt.Fig2
ggsave(plot = plt.Fig2, filename =  'Fig2.svg', path = './../../derivatives/Figures', device = 'svg', width = 18, height = 9, units = 'cm')

plt.Fig2a + plt.Fig2b + plot_layout(nrow = 2) + plot_annotation(tag_levels = 'A', tag_suffix = ')')
#ggsave(plot = last_plot(), filename =  'Fig2deep_poster.svg', path = './../../derivatives/Figures', device = 'svg', width = 12, height = 24, units = 'cm')


plt.Fig3 <- (p.forest.beta$plt[[1]] + ggtitle(parse(text = c('FO^high %~% bold(log^pos~(WMH)) + I[(WMH>0)] + age + sex')))) + 
  (p.forest.gamma$plt[[1]] + ggtitle(parse(text = c('TMT-B %~% bold(FO^high) + log^pos~(WMH) + I[(WMH>0)] + age + sex + education')))) + 
  plot_layout(ncol = 2, guides = 'collect') + 
  plot_annotation(tag_levels = 'A', tag_suffix = ')') & 
  theme(legend.position = 'bottom', title = element_text(size = 3))
plt.Fig3
#ggsave(plot = plt.Fig3, filename =  'Fig3.svg', path = './../../derivatives/Figures', device = 'svg', width = 9, height = 18, units = 'cm')


plt.Fig3 & 
  guides(y = guide_axis(n.dodge = 2)) & 
  theme(axis.text = element_text(size = 8)
        , axis.title = element_text(size = 10)
        , title = element_text(size = 5)
        , legend.text = element_text(size = 6))
ggsave(plot = last_plot(), filename =  'Fig3.svg', path = './../../derivatives/Figures', device = 'svg', width = 18, height = 18, units = 'cm')
