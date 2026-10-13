#!/bin/bash
# Unified non-interactive entry for the already verified Synopsys environment.
# This file intentionally does not edit or source any user's shell startup file.

export Synopsys_Dir=/opt/Synopsys
export SCL_HOME="$Synopsys_Dir/SCL11.11"
export Formality_HOME="$Synopsys_Dir/Formality2016"
export ICC_HOME="$Synopsys_Dir/ICC2016"
export PrimeTime_HOME="$Synopsys_Dir/PrimeTime2015"
export Synplify_HOME="$Synopsys_Dir/Synplify2015"
export VCS_HOME="$Synopsys_Dir/VCS2014"
export Verdi_HOME="$Synopsys_Dir/Verdi2015"
export SNPSLMD_LICENSE_FILE="$Synopsys_Dir/License/License.dat"
export EDA_DIGITAL_LIB=/home/IC/Foundry_Library/Digital

export PATH="$SCL_HOME/linux64/bin:$Formality_HOME/bin:$ICC_HOME/bin:$PrimeTime_HOME/bin:$Synplify_HOME/bin:$VCS_HOME/bin:$Verdi_HOME/bin:$PATH"

