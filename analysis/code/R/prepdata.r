states <- c(`1`='DMN-1',`2`='DMN-2', `3`='S3', `4`='S4', `5`='S5')
cSVD <- c('WMHsmooth','WMHsmoothperi', 'WMHsmoothdeep')


designs <- c( "24p", "24p_gsr", "36p", "36p_spkreg", "36p_despike", "36p_scrub", "acompcor", "tcompcor", "aroma")
atlasses <- c("desikanKilliany", "aal116", "HarvardOxford", "power264", "gordon333", "glasser360", "schaefer100x7", "schaefer200x7", "schaefer400x7")

d.struct <- read.csv('./../../../derivatives/WMH/cSVD.csv', header = TRUE) %>% 
  as_tibble() %>% 
  mutate(across(starts_with('WMH'), ~./1000))  %>% 
  pivot_longer(cols = all_of(cSVD), names_to = 'cSVDmeas', values_to = 'cSVDvalue', values_drop_na = TRUE) %>% 
  group_by(cSVDmeas) %>% 
  mutate(cSVDvalueNA = ifelse(cSVDvalue > 0, cSVDvalue, NA)) %>% 
  mutate(q1 = quantile(cSVDvalueNA, prob = .75, na.rm = TRUE)
         , q3 = quantile(cSVDvalueNA, prob = .25, na.rm = TRUE)
         , cSVDtrans = log(cSVDvalueNA, q1/q3)) %>% 
  mutate(yzero = as.numeric(is.na(cSVDvalueNA))) %>% 
  mutate(cSVDtrans = ifelse(is.na(cSVDvalueNA), 0, cSVDtrans))

d.struct %>% summarise(n())

filenames <- list.files(path = './../../derivatives/data', pattern = 'dFC.*~.dat$', full.names = TRUE)
d.dFC <- map_df(.x = filenames, .f = ~read_csv(.), .id = 'filename') %>% 
  mutate(filename = filenames[as.numeric(filename)]) %>% 
  separate(filename, '~', into = c('pre','design','atlas','post')) %>% 
  dplyr::select(-c(pre, post)) %>% 
  mutate(ID = stringr::str_sub(ID, 5, 13)) %>% 
  dplyr::select(design, atlas, ID, starts_with('fracocc')) %>% 
  pivot_longer(cols = starts_with('fracocc')) %>% 
  separate(name , '_', into = c('meas', 'state')) %>% 
  mutate(state = recode(as.numeric(state), !!!states) %>% factor(levels = states, ordered = TRUE)) %>% 
  rename(frac_occ = value) %>% 
  group_by(design, atlas, ID) %>% 
  summarise(FO.high = mean(frac_occ[1:2])
            , FO.low = mean(frac_occ[3:5])) %>%  # automatically drops column 'meas'
  mutate(design = factor(design, levels = designs)
         , atlas = factor(atlas, levels = atlasses))

d.dFC %>% group_by(design) %>% summarise(n() / length(atlasses)) %>% print(n=Inf)

d.clinical <- read.csv('./../../../input/hchs.csv', header = TRUE)  %>% 
  mutate(across(c(ID, sex), as.factor))

d.clinical %>% nrow()

save(list = c("designs", "atlasses", "d.clinical", "d.dFC", "d.struct"), file = "data.Rdata")
