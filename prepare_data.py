# -*- coding: utf-8 -*-
"""
Created on Fri Jul  7 11:50:00 2023

@author: Sean Horvath
"""

import era5_functions
import NSIDC_functions


#---------------------------------------------------
# Get up to date ERA5 data
#---------------------------------------------------

era5_functions.download_missing_data('data/single_level/full_data.nc')
era5_functions.combine_netcdfs('data/single_level/')
era5_functions.combine_netcdfs('data/pressure_level/')

# Create a temporary netcdf file with relevent covariates
era5_functions.create_temp_netcdf('data/pressure_level/')
era5_functions.create_temp_netcdf('data/single_level/')

#---------------------------------------------------
# Get up to date NSIDC data
#---------------------------------------------------

NSIDC_functions.get_latest_sept_extent()
NSIDC_functions.get_latest_seaice_conc()

