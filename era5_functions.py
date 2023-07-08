# -*- coding: utf-8 -*-
"""
Created on Fri Jul  7 14:58:38 2023

@author: Sean Horvath
"""

import cdsapi
import pandas as pd
import xarray as xr
from datetime import datetime

def get_era5_data(month, year):

    c = cdsapi.Client()
    
    c.retrieve(
        'reanalysis-era5-single-levels-monthly-means',
        {
            'format': 'netcdf',
            'product_type': 'monthly_averaged_reanalysis',
            'variable': [
                '2m_temperature', 'mean_surface_downward_long_wave_radiation_flux', 'mean_surface_downward_short_wave_radiation_flux',
                'sea_surface_temperature',
            ],
            'year': year,
            'month': month,
            'time': '00:00',
        },
        'data/single_level/' + year + month + '.nc')
    
    c.retrieve(
        'reanalysis-era5-pressure-levels-monthly-means',
        {
            'format': 'netcdf',
            'product_type': 'monthly_averaged_reanalysis',
            'variable': 'geopotential',
            'pressure_level': '500',
            'year': year,
            'month': month,
            'time': '00:00',
            'area': [90, -180, 60, 180,],
        },
        'data/pressure_level/' + year + month + '.nc')

def check_era5_dates(filename, current_time=datetime.today()):
    with xr.open_dataset(filename) as file:
        yr_mos = file.time.values.astype('datetime64[M]').astype(str)
    
    date_list = pd.date_range(datetime(1979,5,1),current_time,freq='M')
    date_list = date_list[date_list.month.isin([5,6,7,8])]
    date_list = date_list.strftime('%Y-%m')
    
    missing_dates = list(set(date_list).difference(set(yr_mos)))
    return missing_dates
    
def download_missing_data(filename):
    missing_dates = check_era5_dates(filename)
    missing_dates = [i.split('-') for i in missing_dates]
    
    for yr_mo in missing_dates:
        get_era5_data(yr_mo[1], yr_mo[0])
    
def combine_netcdfs(filepath):
    ds = xr.open_mfdataset(filepath + '/*.nc',
                           combine='by_coords')
    
    ds.to_netcdf(filepath + 'full_data_new.nc')
    
def create_temp_netcdf(filepath):
    ds = xr.open_dataset(filepath + 'full_data_new.nc')
    # Use .groupby('time.month') to organize the data into months
    # then use .groups to extract the indices for each month
    month_idxs = ds.groupby('time.month').groups
    
    # get previous month integer
    previous_month = datetime.today().month - 1
    # Extract the time indices corresponding to all the Januarys 
    month_idxs = month_idxs[previous_month]
    
    # Extract the month by selecting 
    # the relevant indices
    ds_temp = ds.isel(time=month_idxs)
    ds_temp.to_netcdf(filepath + 'temp.nc')
    
    
    