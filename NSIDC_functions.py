# -*- coding: utf-8 -*-
"""
Created on Sat Jul  8 10:12:21 2023

@author: Sean Horvath
"""
import requests
import os
from datetime import datetime

def get_latest_sept_extent():
    downloaded_files = os.listdir('data/SeptMonthlyExtent')
    available_years = []
    for f in downloaded_files:
        available_years.append(f.split('_')[1][0:4])
    
    current_year = datetime.today().year
    needed_years = list(range(1979,current_year))
    needed_years = list(map(str, needed_years))
    
    needed_years = list(set(needed_years).difference(set(available_years)))
    
    base_url = 'https://noaadata.apps.nsidc.org/NOAA/G02135/north/monthly/geotiff/09_Sep/'
    for yr in needed_years:
        file_url = base_url + 'N_' + yr + '09_extent_v3.0.tif'
        r = requests.get(file_url)
    
        with open('data/SeptMonthlyExtent/' + 'N_' + yr + '09_extent_v3.0.tif', "wb") as f:
            f.write(r.content)

def get_latest_seaice_conc():
    downloaded_files = os.listdir('data/Ice Concentration')
    available_yearmonths = []
    for f in downloaded_files:
        available_yearmonths.append(f.split('_')[1][0:6])
    
    current_year = datetime.today().year
    current_month = datetime.today().month
    needed_years = list(range(1979,current_year + 1))
    needed_years = list(map(str, needed_years))
    
    needed_yearmonths = [sub + str(current_month - 1).zfill(2) for sub in needed_years]
    needed_yearmonths = list(set(needed_yearmonths).difference(set(available_yearmonths)))
    
    directory_dict = {'01': '01_Jan/',
                      '02': '02_Feb/',
                      '03': '03_Mar/',
                      '04': '04_Apr/',
                      '05': '05_May/',
                      '06': '06_Jun/',
                      '07': '07_Jul/',
                      '08': '08_Aug/',
                      '09': '09_Sep/',
                      '10': '10_Oct/',
                      '11': '11_Nov/',
                      '12': '12_Dec/',
                      }
    
    base_url = 'https://noaadata.apps.nsidc.org/NOAA/G02135/north/monthly/geotiff/'
    for yr in needed_yearmonths:
        file_url = base_url + directory_dict.get(yr[4:6]) + 'N_' + yr + '_concentration_v3.0.tif'
        r = requests.get(file_url)
    
        with open('data/Ice Concentration/' + 'N_' + yr + '_concentration_v3.0.tif', "wb") as f:
            f.write(r.content)




















