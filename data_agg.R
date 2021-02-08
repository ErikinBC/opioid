pckgs <- c('dplyr','tidyr','readr','magrittr','stringr','forcats','data.table','broom',
           'ggplot2','cowplot','ggmap','ggh4x','ggrepel',
           'sf', 'rgdal','maptools')
for (pp in pckgs) { library(pp,character.only=T,quietly = T,warn.conflicts = F)}

dir_base <- getwd()
dir_output <- file.path(dir_base, 'output')
dir_figures <- file.path(dir_base, 'figures')

###########################
# ---- (1) LOAD DATA ---- #

df_phu <- read_csv(file.path(dir_output, 'df_phu.csv'))
df_deaths <- read_csv(file.path(dir_output, 'df_deaths.csv'))

######################################
# ---- (2) PERFORM AGGREGATIONS ---- #

# How we should stratify the population
pcat_bins <- c(0,10,13,16,19,30,50,90,300)
pcat_lbls <- str_c(str_c(pcat_bins[1:length(pcat_bins)-1],
      pcat_bins[2:length(pcat_bins)],sep='-'),'K')
pc <- 1e4  # Per capita denomiator

# Total death and death-rate by month
tot_deaths <- df_deaths %>% group_by(date) %>%
  summarise(n_death=12*sum(n_death), pop=sum(population)/pc) %>% 
  mutate(r_death=n_death/pop) %>% 
  pivot_longer(c(n_death, r_death),names_to='msr') %>% 
  dplyr::select(-pop) %>% arrange(msr,date)
# and by year

# PHU deaths by year
phu_deaths_year <- df_deaths %>% group_by(year, PHU) %>%
  summarise(n_death=12*mean(n_death), pop=mean(population)/pc)
# Calculate the population category
phu_pcat <- phu_deaths_year %>% group_by(PHU) %>%
  summarise(pop=mean(pop))  %>% arrange(pop) %>% 
  mutate(pcat = cut(x=pop,breaks=pcat_bins,labels = pcat_lbls)) %>% 
  # group_by(pcat) %>% mutate(ridx=row_number()) %>% 
  ungroup() %>% dplyr::select(-pop)
# Rejoin
phu_deaths_year <- phu_deaths_year %>% left_join(phu_pcat,by='PHU') %>% 
  arrange(year,pcat) %>% 
  mutate(r_death=12*n_death/pop) %>% ungroup %>% 
  pivot_longer(c(n_death, r_death),names_to='msr') %>%  # Long-format 
  arrange(msr,year,pcat)
# Calculate the relative index for labels
phu_txt_lbs <- phu_deaths_year %>%
  filter(year==max(year)) %>% dplyr::select(-c(pop)) %>% 
  mutate(year=min(phu_deaths_year$year)) %>%
  arrange(msr,pcat,value) %>% 
  group_by(msr,pcat) %>% 
  mutate(ridx=row_number(),value=max(value)) %>% 
  mutate(value=value*(1-0.75*(1-ridx/max(ridx)))) %>% ungroup

# Save for later
write_csv(x=phu_deaths_year,file=file.path(dir_output,'phu_deaths_year.csv'))


##################################
# ---- (X) FIGURES ---- #       

di_msr <- c('n_death'='# Deaths', 'r_death'='Death Rate (per 100K)')

# (i) Total monthly deaths
for (msr in names(di_msr)) {
  path <- file.path(dir_figures,str_c('total_',msr,'.png'))
  tmp_gg <- filter(tot_deaths, msr == {{msr}}) %>% 
    ggplot(aes(x=date,y=value)) + theme_bw() + 
    geom_point(size=0.75) + geom_line(size=0.25,alpha=0.5) + 
    labs(y=di_msr[msr]) + 
    theme(axis.title.x = element_blank()) + 
    ggtitle('Opioid deaths in Ontario')
  save_plot(path, tmp_gg,base_height=3,base_width=4)
}


# (ii) Total yearly deaths by PHU (strata on pcat)
for (msr in names(di_msr)) {
  path <- file.path(dir_figures,str_c('phu_',msr,'.png'))
  tmp_df1 <- filter(phu_deaths_year, msr == {{msr}})
  tmp_df2 <-
    filter(phu_txt_lbs, msr == {{msr}}) %>%
    mutate(vmax=max(value)) %>% group_by(pcat) %>% 
    mutate(value=ifelse(msr=='r_death',vmax*(1-0.75*(1-ridx/max(ridx))),value))
  tmp_df1 <- tmp_df1 %>% left_join(dplyr::select(tmp_df2,-c(value,year)))
  tmp_gg <- ggplot(tmp_df1,aes(x=year,y=value,color=factor(ridx))) + theme_bw()  + 
    geom_point() + geom_line() + 
    facet_wrap(~pcat,scales=ifelse(msr=='r_death','fixed','free_y'),nrow=2) + 
    labs(y=di_msr[msr]) + 
    theme(axis.title.x = element_blank()) + 
    guides(color=F) + 
    geom_text_repel(aes(label=PHU),data=tmp_df2) + 
    ggtitle('Opioid deaths in Ontario by PHU')
  save_plot(path, tmp_gg,base_height=6,base_width=18)
}




























