pckgs <- c('dplyr','tidyr','readr','magrittr','stringr','forcats','data.table','broom',
           'ggplot2','cowplot','ggmap','ggh4x',
           'sf', 'rgdal','maptools')
for (pp in pckgs) { library(pp,character.only=T,quietly = T,warn.conflicts = F)}

dir_base <- getwd()
dir_output <- file.path(dir_base, 'output')

# ---- (1) LOAD DATA ---- #

df_phu <- read_csv(file.path(dir_output, 'df_phu.csv'))
df_deaths <- read_csv(file.path(dir_output, 'df_deaths.csv'))
df_deaths

# dat_agg = df_both.groupby('date').n_death.sum().reset_index()
# dat_PHU_year = df_both.groupby(['year','PHU']).n_death.mean().reset_index()
# dat_PHU_year = dat_PHU_year.assign(n_death=lambda x: np.round(x.n_death*12).astype(int))
# 
# dat_pop = df_both.groupby('PHU').population.mean().reset_index().sort_values('population',ascending=False)
# dat_pop.population = dat_pop.population/1e4
# dat_pop = dat_pop.reset_index(None,True)
# dat_pop['pcat'] = pd.cut(dat_pop.population,[0,10,13,16,19,30,50,90,300])
# # dat_pop.groupby(['pcat','PHU']).size().reset_index().rename(columns={0:'n'}).query('n>0')
# # dat_pop.pcat.value_counts()
# di_pcat = dict(zip(dat_pop.PHU,dat_pop.pcat))
# dat_pop['icat'] = dat_pop.groupby('pcat').cumcount()
# 
# tmp = dat_PHU_year.merge(dat_pop)
# tmp = tmp.assign(drate=lambda x: x.n_death/x.population*10)
# tmp = tmp.melt(['year','PHU','pcat','icat'],['n_death','drate'],'msr')
# tmp.pcat = cat_rev(tmp.pcat.values)
# 
# tmp2 = tmp.groupby(['pcat','PHU','msr']).value.max().reset_index().reset_index().query('value>0')
# tmp2 = tmp2.merge(dat_pop).drop(columns='population')
# tmp2 = tmp2.sort_values(['msr','pcat','icat'])
# tmp2 = tmp2.merge(tmp2.groupby(['msr','pcat']).value.max().reset_index().rename(columns={'value':'mx'}),'left')
# tmp2= tmp2.assign(y=lambda x: 0.9*(x.mx*(1-0.1*x.icat)), x=2012)
# qq = 'County|Region|\\sHealth\\sDepartment|Services|City\\sof\\s|District|Public\\sHealth|\\sof|\\sand\\sEmergency'
# tmp2.PHU = tmp2.PHU.str.replace(qq,'').str.strip()
# tmp2.pcat = cat_rev(tmp2.pcat.values)
# 
# gg_all = (ggplot(tmp.query('msr=="n_death"'),aes(x='year',y='value',color='factor(icat)')) + 
#             geom_line() + theme_bw() + labs(y='Opioid deaths') + 
#             theme(axis_text_x=element_text(angle=45),axis_title_x=element_blank(),
#                   subplots_adjust={'wspace':0.20}) + 
#             ggtitle('Year Opioid deaths in Ontario') + 
#             facet_wrap('~pcat',scales='free_y') + 
#             guides(color=False) + 
#             geom_text(aes(label='PHU',y='y',x='x'),data=tmp2.query('msr=="n_death"'),size=8) + 
#             scale_x_continuous(breaks=list(range(2006,2021,2))) + 
#             geom_vline(xintercept=2017,linetype='--'))
# 
# gg_rate = (ggplot(tmp.query('msr=="drate"'),aes(x='year',y='value',color='factor(icat)')) + 
#              geom_line() + theme_bw() + labs(y='Opioid death rate') + 
#              theme(axis_text_x=element_text(angle=45),axis_title_x=element_blank(),
#                    subplots_adjust={'wspace':0.20}) + 
#              ggtitle('Yearly Opioid death rates in Ontario') + 
#              facet_wrap('~pcat') + 
#              guides(color=False) + 
#              geom_text(aes(label='PHU',y='y',x='x'),data=tmp2.query('msr=="drate"'),size=8) + 
#              scale_x_continuous(breaks=list(range(2006,2021,2))) + 
#              geom_vline(xintercept=2017,linetype='--'))
