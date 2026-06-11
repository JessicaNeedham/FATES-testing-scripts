#!/bin/bash

export COMPSET='HIST_DATM%CRUJRA2024_CLM60%FATES_SICE_SOCN_SROF_SGLC_SWAV_SESP'
export RES='f19_g17'
export MACH='olivia'
export PROJECT='nn9560k'

export USER='jessica'
export workpath='/cluster/work/projects/nn9560k/jessica'

export TAG='noresm-fates-f19-1917_h2oerr_dumpinfo'
export CASEROOT=$workpath/noresm_runs
export CIMEROOT=$workpath/noresm-h2o-test/CTSM/cime/scripts

cd ${CIMEROOT}

export CIME_HASH=`git log -n 1 --pretty=%h`
export NorESM_CTSM_HASH=`(cd ../..;git log -n 1 --pretty=%h)`
export FATES_HASH=`(cd src/fates;git log -n 1 --pretty=%h)`
export GIT_HASH=N${NorESM_CTSM_HASH}-F${FATES_HASH}	
export CASE_NAME=${CASEROOT}/${TAG}.`date +"%Y-%m-%d"`


# REMOVE EXISTING CASE DIRECTORY IF PRESENT 
rm -rf ${CASE_NAME}

# CREATE THE CASE
./create_newcase --case=${CASE_NAME} --res=${RES} --compset=${COMPSET} --mach=${MACH} --project=${PROJECT} --run-unsupported

cd ${CASE_NAME}

./xmlchange STOP_N=31
./xmlchange STOP_OPTION=nyears
./xmlchange REST_N=1
./xmlchange REST_OPTION=nmonths
./xmlchange RESUBMIT=0
./xmlchange DEBUG=FALSE

./xmlchange RUN_STARTDATE=1917-12-01
./xmlchange CLM_ACCELERATED_SPINUP=off
./xmlchange DATM_YR_START=1917
./xmlchange DATM_YR_END=2023
./xmlchange DATM_YR_ALIGN=1917
./xmlchange CLM_CO2_TYPE=diagnostic
./xmlchange DATM_CO2_TSERIES=20tr
./xmlchange CCSM_BGC=CO2A
./xmlchange DATM_PRESAERO=hist

# For real runs
./xmlchange --subgroup case.run JOB_WALLCLOCK_TIME=24:00:00
./xmlchange --subgroup case.st_archive JOB_WALLCLOCK_TIME=00:30:00

./xmlchange RUNDIR=${CASE_NAME}/run
./xmlchange EXEROOT=${CASE_NAME}/bld

# ./xmlchange BUILD_COMPLETE=TRUE
# ./xmlchange EXEROOT=/cluster/work/projects/nn9560k/jessica/noresm_runs/noresm-fates-f19-1901-2024_h2oerr.2026-06-04/bld

 # turn on megan
 ./xmlchange CLM_BLDNML_OPTS="-bgc fates -megan"

cat >>  user_nl_clm <<EOF
do_transient_lakes=.false.
do_transient_urban=.false.
irrigate=.false.
finidat='/cluster/work/projects/nn9560k/jessica/noresm_runs/noresm-fates-f19-1917_monthly_h2oerr.2026-06-05/run/noresm-fates-f19-1917_monthly_h2oerr.2026-06-05.clm2.r.1917-12-01-00000.nc'
fates_paramfile='/cluster/home/jessica/FATES-testing/param_files/fates_params_LU_PPE_fates_landuse_grazing_palatability_min.json'
use_fates_sp=.false.
use_fates_nocomp=.true.
use_fates_fixed_biogeog=.true.
fates_stomatal_model='medlyn2011'
fates_lu_transition_logic=1
use_fates_luh=.true.
use_fates_lupft=.true.
fates_harvest_mode='luhdata_area'
use_fates_potentialveg=.false.
fluh_timeseries='/cluster/work/projects/nn9560k/inputdata/lnd/clm2/surfdata_esmf/fates_LU_data_CMIP7/LUH3_timeseries_850-2024_surfdata_1.9x2.5_c260602.nc'
flandusepftdat='/cluster/work/projects/nn9560k/inputdata/lnd/clm2/surfdata_esmf/fates_LU_data_CMIP7/fates_landuse_pft_surfdata_1.9x2.5_c260513.nc'
fates_spitfire_mode=4
hist_fincl1='FATES_FRACTION','FATES_NOCOMP_PATCHAREA_PF', 'FATES_AUTORESP', 'HR', 'FATES_BURNFRAC', 'FATES_VEGC', 'FATES_VEGC_ABOVEGROUND',
'FATES_CROWNAREA_PF', 'FATES_STOREC_PF'
EOF


cat >> user_nl_datm_streams <<EOF
co2tseries.20tr:datafiles=/cluster/work/projects/nn9188k/jessica/trendy_co2/fco2_datm_global_simyr_1700-2024_TRENDY_c250625.nc
co2tseries.20tr:year_last=2023
co2tseries.20tr:year_first=1917
co2tseries.20tr:year_align=1917
EOF

./case.setup
./case.build
./case.submit
