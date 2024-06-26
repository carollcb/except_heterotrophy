# Test hierarchical model for across sites 
# pooled by site as there was insufficient evidence of variation across siteyears
# A Carter

library(tidyverse)
library(brms)
library(lme4)
library(corrplot)

dat <- read_csv('data_working/across_sites_model_data.csv')

dat$PR = -dat$ann_GPP_C/dat$ann_ER_C
dat$NEP = dat$ann_GPP_C + dat$ann_ER_C

dd <- dat %>%
    filter(!is.na(PR),
           !is.na(drainage_density_connected),
           !is.infinite(drainage_density_connected),
           !is.na(Stream_PAR_sum), 
           !is.na(MOD_ann_NPP)) %>%
    mutate(width_to_area = Width/sqrt(ws_area_km2))%>%
    select(site_name, ER = ann_ER_C, GPP = ann_GPP_C, PR, NEP, 
           drainage_density_connected, drainage_density, Stream_PAR_sum,
           MOD_ann_NPP, PrecipWs, precip_runoff_ratio, Disch_cv, 
           max_interstorm, ws_area_km2, 
           width_to_area) %>%
    mutate(ER = - ER, 
           log_PR = log(PR),
           across(-site_name, ~scale(.)[, 1]))

cor(select(dd, where(is.numeric)), use = 'complete.obs')%>%
  as.data.frame() %>%
  select(GPP, ER) %>%
  arrange(desc(abs(GPP)))

cc <- cor(select(dd, where(is.numeric)), use = 'complete.obs')
cc_sig <- cor.mtest(select(dd, where(is.numeric)), conf.level=0.95)

corrplot(cc, type = "lower", order = "original", p.mat = cc_sig$p,
         tl.col = "black", tl.srt = 90, tl.cex = .7,
         method='color', diag=FALSE, cl.cex = .6,
         cl.length = 11,
         sig.level = c(0.05), insig = 'label_sig',
         pch.cex = 1, pch.col='grey20')
# look for correlation in predictors
select(dat, where(is.numeric)) %>%
  filter(!is.infinite(drainage_density_connected)) %>%
  cor( use = 'complete.obs') %>%
  as.data.frame()%>%
  select(ann_GPP_C) %>%
  arrange(desc(abs(ann_GPP_C)))

lm(GPP ~ width_to_area, data = dd) %>% summary()
lm(drainage_density~ ws_area_km2 , data = dd) %>% summary()

plot(dat$drainage_density_connected, dat$ann_GPP_C)
identify(dat$drainage_density_connected, dat$ann_ER_C, labels = dat$site_name)
plot(dd$width_to_area, dd$NEP, xlim = c(-0.51, 2))
plot(dd$max_interstorm, dd$GPP)
mods <- data.frame()
add_model_to_table <- function(b, mods){
  bb <- data.frame(fixef(b)) 
  bb$variable = rownames(bb)
  rownames(bb) <- NULL
  
  bb$mod <- as.character(b$formula)[1]
  bb$waic <- brms::waic(b)$waic
  
  mods <- bind_rows(mods, bb)
  return(mods)
}


b <- brm(log_PR ~ Stream_PAR_sum + MOD_ann_NPP + drainage_density_connected +
           Disch_cv + (1|site_name), data = dd)
post <- brms::posterior_samples(b,
              pars = c('Stream_PAR_sum', 'MOD_ann_NPP', 'drainage_density_connected', 'Disch_cv'))
pp <- post %>% pivot_longer(cols = everything(), names_to = 'parameter', values_to = 'samples') %>%
  mutate(parameter = factor(parameter, levels = c('b_Stream_PAR_sum', 'b_MOD_ann_NPP', 'b_drainage_density_connected', 'b_Disch_cv')))
p1 <- ggplot(pp, aes(x=parameter, y=samples)) + 
  geom_boxplot(fill='steelblue') +
  coord_flip() +
  ylim(-0.3, 0.5) +
  geom_hline(yintercept = 0)+
  theme(axis.text.y=element_blank(),
        axis.title.y=element_blank())

mods <- add_model_to_table(b, mods)

b2 <- brm(log_PR ~ Stream_PAR_sum + MOD_ann_NPP + drainage_density_connected +
           max_interstorm + (1|site_name), data = dd)

post <- brms::posterior_samples(b2,
              pars = c('Stream_PAR_sum', 'MOD_ann_NPP', 'drainage_density_connected', 'max_interstorm'))
pp <- post %>% pivot_longer(cols = everything(), names_to = 'parameter', values_to = 'samples') %>%
  mutate(parameter = factor(parameter, levels = c('b_Stream_PAR_sum', 'b_MOD_ann_NPP', 'b_drainage_density_connected', 'b_max_interstorm')))
p2 <- ggplot(pp, aes(x=parameter, y=samples)) + 
  geom_boxplot(fill='steelblue') +
  coord_flip() +
  ylim(-0.3, 0.5) +
  geom_hline(yintercept = 0)+
  theme(axis.text.y=element_blank(),
        axis.title.y=element_blank())

mods <- add_model_to_table(b2, mods)

b3 <- brm(log_PR ~ Stream_PAR_sum + MOD_ann_NPP + width_to_area +
           max_interstorm + (1|site_name), data = dd)

post <- brms::posterior_samples(b3,
              pars = c('Stream_PAR_sum', 'MOD_ann_NPP', 'width_to_area', 'max_interstorm'))
pp <- post %>% pivot_longer(cols = everything(), names_to = 'parameter', values_to = 'samples') %>%
  mutate(parameter = factor(parameter, levels = c('b_Stream_PAR_sum', 'b_MOD_ann_NPP', 'b_width_to_area', 'b_max_interstorm')))
p3 <- ggplot(pp, aes(x=parameter, y=samples)) + 
  geom_boxplot(fill='steelblue') +
  coord_flip() +
  ylim(-0.3, 0.5) +
  geom_hline(yintercept = 0)+
  theme(axis.text.y=element_blank(),
        axis.title.y=element_blank())


mods <- add_model_to_table(b3, mods)

b4 <- brm(log_PR ~ Stream_PAR_sum + MOD_ann_NPP + width_to_area +
           Disch_cv + (1|site_name), data = dd)

post <- brms::posterior_samples(b4,
              pars = c('Stream_PAR_sum', 'MOD_ann_NPP', 'width_to_area', 'Disch_cv'))
pp <- post %>% pivot_longer(cols = everything(), names_to = 'parameter', values_to = 'samples') %>%
  mutate(parameter = factor(parameter, levels = c('b_Stream_PAR_sum', 'b_MOD_ann_NPP', 'b_width_to_area', 'b_Disch_cv')))
p4 <- ggplot(pp, aes(x=parameter, y=samples)) + 
  geom_boxplot(fill='steelblue') +
  coord_flip() +
  ylim(-0.3, 0.5) +
  geom_hline(yintercept = 0) +
  theme(axis.text.y=element_blank(),
        axis.title.y=element_blank())



mods <- add_model_to_table(b4, mods)

mods <- read_csv('data_working/brms_models.csv')

ggpubr::ggarrange(p1,p2,p3,p4, ncol = 4)

#NEP
b <- brm(NEP ~ Stream_PAR_sum + MOD_ann_NPP + drainage_density_connected +
           Disch_cv + (1|site_name), data = dd)

post <- brms::posterior_samples(b,
                                pars = c('Stream_PAR_sum', 'MOD_ann_NPP', 'drainage_density_connected', 'Disch_cv'))
pp <- post %>% pivot_longer(cols = everything(), names_to = 'parameter', values_to = 'samples') %>%
  mutate(parameter = factor(parameter, levels = c('b_Stream_PAR_sum', 'b_MOD_ann_NPP', 'b_drainage_density_connected', 'b_Disch_cv')))
p1 <- ggplot(pp, aes(x=parameter, y=samples)) + 
  geom_boxplot(fill='steelblue') +
  coord_flip() +
  ylim(-0.3, 0.5) +
  geom_hline(yintercept = 0)+
  theme(axis.text.y=element_blank(),
        axis.title.y=element_blank())



# mods <- add_model_to_table(b, mods)

b2 <- brm(NEP ~ Stream_PAR_sum + MOD_ann_NPP + drainage_density_connected +
           max_interstorm + (1|site_name), data = dd)
post <- brms::posterior_samples(b2,
                                pars = c('Stream_PAR_sum', 'MOD_ann_NPP', 'drainage_density_connected', 'max_interstorm'))
pp <- post %>% pivot_longer(cols = everything(), names_to = 'parameter', values_to = 'samples') %>%
  mutate(parameter = factor(parameter, levels = c('b_Stream_PAR_sum', 'b_MOD_ann_NPP', 'b_drainage_density_connected', 'b_max_interstorm')))
p2 <- ggplot(pp, aes(x=parameter, y=samples)) + 
  geom_boxplot(fill='steelblue') +
  coord_flip() +
  ylim(-0.3, 0.5) +
  geom_hline(yintercept = 0)+
  theme(axis.text.y=element_blank(),
        axis.title.y=element_blank())

# mods <- add_model_to_table(b2, mods)

b3 <- brm(NEP ~ Stream_PAR_sum + MOD_ann_NPP + width_to_area +
           max_interstorm + (1|site_name), data = dd)
post <- brms::posterior_samples(b3,
                                pars = c('Stream_PAR_sum', 'MOD_ann_NPP', 'width_to_area', 'max_interstorm'))
pp <- post %>% pivot_longer(cols = everything(), names_to = 'parameter', values_to = 'samples') %>%
  mutate(parameter = factor(parameter, levels = c('b_Stream_PAR_sum', 'b_MOD_ann_NPP', 'b_width_to_area', 'b_max_interstorm')))
p3 <- ggplot(pp, aes(x=parameter, y=samples)) + 
  geom_boxplot(fill='steelblue') +
  coord_flip() +
  ylim(-0.3, 0.5) +
  geom_hline(yintercept = 0)+
  theme(axis.text.y=element_blank(),
        axis.title.y=element_blank())

# mods <- add_model_to_table(b3, mods)

b4 <- brm(NEP ~ Stream_PAR_sum + MOD_ann_NPP + width_to_area +
           Disch_cv + (1|site_name), data = dd)


post <- brms::posterior_samples(b4,
                                pars = c('Stream_PAR_sum', 'MOD_ann_NPP', 'width_to_area', 'Disch_cv'))
pp <- post %>% pivot_longer(cols = everything(), names_to = 'parameter', values_to = 'samples') %>%
  mutate(parameter = factor(parameter, levels = c('b_Stream_PAR_sum', 'b_MOD_ann_NPP', 'b_width_to_area', 'b_Disch_cv')))
p4 <- ggplot(pp, aes(x=parameter, y=samples)) + 
  geom_boxplot(fill='steelblue') +
  coord_flip() +
  ylim(-0.3, 0.5) +
  geom_hline(yintercept = 0) +
  theme(axis.text.y=element_blank(),
        axis.title.y=element_blank())


ggpubr::ggarrange(p1,p2,p3,p4, ncol = 4)


post <- brms::posterior_samples(b4,
              pars = c('Stream_PAR_sum', 'MOD_ann_NPP', 'width_to_area', 'Disch_cv'))
pp <- post %>% pivot_longer(cols = everything(), names_to = 'parameter', values_to = 'samples')
p4 <- ggplot(pp, aes(x=parameter, y=samples)) + 
  geom_boxplot(fill='steelblue') +
  coord_flip() +
  ylim(-0.3, 0.3)

mods <- add_model_to_table(b4, mods)

write_csv(mods, 'data_working/brms_models.csv')
plot(b4, pars = c('Stream_PAR_sum', 'MOD_ann_NPP', 'width_to_area', 'Disch_cv'))
p[[1]] + xlim(-.5, .5)
  
  plot(conditional_effects(b), points = TRUE)
pp_check(b)
b_NEP <- brm(NEP ~ Stream_PAR_sum + MOD_ann_NPP + drainage_density_connected + 
      (1|site_name), data = dd)

l <- lmer(GPP ~ Stream_PAR_sum + MOD_ann_NPP + Disch_cv +
            drainage_density_connected + (1|site_name), data = dd)

l_nep <- lmer(NEP ~ Stream_PAR_sum + MOD_ann_NPP + 
            drainage_density_connected + (1|site_name), data = dd)

summary(l)


sum(is.na(dat$MOD_ann_NPP))
