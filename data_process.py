import os
import sys
import pandas as pd
import numpy as np
import plotnine
from plotnine import *

from plydata.cat_tools import *


dir_base = os.getcwd()
dir_data = os.path.join(dir_base, 'data')
dir_figures = os.path.join(dir_base, 'figures')
dir_output = os.path.join(dir_base, 'output')
assert os.path.exists(dir_data)
dir_pho = os.path.join(dir_data,'PHO')
assert os.path.exists(dir_pho)
if not os.path.exists(dir_figures):
  os.mkdir(dir_figures)
  
if not os.path.exists(dir_output):
  os.mkdir(dir_output)

"""## (1.A) Merge data from PHO

https://www.publichealthontario.ca/en/data-and-analysis/substance-use/interactive-opioid-tool
"""

fn_data = pd.Series(os.listdir(dir_pho))
fn_data = fn_data[fn_data.str.contains('\\.csv$')]
holder = []
for fn in fn_data:
  tmp_phu = fn.split(',')[1]
  tmp_df = pd.read_csv(os.path.join(dir_pho,fn))
  tmp_df.insert(0,'phu',tmp_phu)
  holder.append(tmp_df)
# Merge and clean
df_phu = pd.concat(holder).reset_index(None,True)

cn_drop = ['change of ED visits (%)','change of Hospitalizations (%)','change of Deaths (%)']
di_cn = {'phu':'PHU','Year - Month':'date','Population':'population',
         'Rate of ED visits':'rate_ED','Count of ED visits':'count_ED',
         'Rate of Hospitalizations':'rate_hosp',
         'Count of Hospitalizations':'count_hosp',
         'Rate of Deaths':'rate_death','Count of Deaths':'count_death'}
df_phu = df_phu.drop(columns=cn_drop).rename(columns=di_cn)
df_phu.PHU = df_phu.PHU.str.strip()
df_phu.PHU = df_phu.PHU.str.replace('\\sHealth\\sUnit','')
df_phu.PHU = df_phu.PHU.str.replace('\\sPublic\\sHealth','')
df_phu.date = pd.to_datetime(df_phu.date.str.replace('\\s\\-\\s','-')+'-01')
df_phu.to_csv(os.path.join(dir_output,'df_phu.csv'),index=False)

"""## (1.B) Append data from Coroner's office"""

path = os.path.join(dir_data,'ON_Opioid_Deaths_Jan-Sept 2020 by PHU_Jan 29 2021_cleaned.csv')
df_cor = pd.read_csv(path)
df_cor.rename(columns={'Unnamed: 0':'PHU'},inplace=True)
df_cor.PHU = df_cor.PHU.str.replace('\\sHealth\\sUnit','')
df_cor.PHU = df_cor.PHU.str.replace('\\sPublic\\sHealth','')

di_fix = {'Leeds, Grenville & Lanark District':'Leeds',
          'Kingston, Frontenac and Lennox & Addington Publi':'Kingston',
          'Haliburton, Kawartha, Pine Ridge District Health':'Haliburton'}
tmp = df_cor.PHU.map(di_fix)
df_cor.PHU = np.where(tmp.isnull(),df_cor.PHU,tmp)
df_cor = df_cor.loc[1:].melt('PHU',None,'date','n').sort_values(['PHU','date'])
df_cor = df_cor.assign(idx=lambda x: x.date.str.split('\\.',2,True).iloc[:,1],
              date=lambda x: x.date.str.replace('\\.[1-2]',''))
df_cor = df_cor.assign(idx=lambda x: np.where(x.idx.isnull(),0,x.idx).astype(int))
df_cor = df_cor.assign(tt=lambda x: x.idx.map({0:'confirmed',1:'probable',2:'total'})).drop(columns='idx')
df_cor.date = df_cor.date.str.replace('\\s2020','')
tmp = df_cor.date.map({'Aug':'August','Sep':'September'})
df_cor.date = np.where(tmp.isnull(),df_cor.date,tmp)
df_cor.date = pd.to_datetime(df_cor.date+',2020',format='%B,%Y')
df_cor.n = df_cor.n.astype(float).fillna(0).astype(int)
# Double check total == confirmed + probable
assert df_cor.groupby(['PHU','tt']).n.sum().reset_index().pivot('PHU','tt','n').assign(check=lambda x: x.confirmed+x.probable==x.total).check.all()
# Merge Huron County and Perth District to Huron Perth
df_cor = df_cor.assign(PHU=lambda x: np.where(x.PHU.isin(['Huron County','Perth District']),'Huron Perth',x.PHU))
df_cor = df_cor.groupby(['PHU','date','tt']).n.sum().reset_index()
tmp1 = df_phu[['PHU','date','population','count_death']].rename(columns={'count_death':'n'})
tmp1 = tmp1.query('date >= 2005 & date<="2020-03-01"').assign(n=lambda x: x.n.astype(int))
tmp2 = df_cor.query('tt=="confirmed"').drop(columns='tt')
df_both = tmp1.merge(tmp2,'outer',['PHU','date'])
# df_both.query('date>=2020 & date<="2020-03-01"').assign(check=lambda x: x.n_x==x.n_y).query('check==False')
df_both = df_both.assign(n_death = lambda x: np.where(x.n_y.isnull(),x.n_x,x.n_y).astype(int)).drop(columns=['n_x','n_y'])
df_both.population = df_both.groupby('PHU').population.fillna(method='ffill').astype(int)
df_both = df_both.sort_values(['PHU','date']).reset_index(None, True)
df_both = df_both.assign(year=lambda x: x.date.dt.strftime('%Y').astype(int),
                          month=lambda x: x.date.dt.strftime('%m').astype(int))
df_both.to_csv(os.path.join(dir_output,'df_deaths.csv'),index=False)

