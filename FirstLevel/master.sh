#!/bin/bash
#
# Master script
# Calls script(s)
# Saves output of script(s) to same directory as textfile
#
# Each step of analysis may be run individually or with any combination of other steps
# By deleting the # at the beginning of the steps you wish to run
#
#sh ./fsl_script.sh > fsl_script_output.txt 2>&1
#sh ./bet_optimizer.sh > bet_optimizer_output.txt 2>&1
#sh ./feat_script.sh > feat_script_output.txt 2>&1
#sh ./featquery_script.sh > featquery_script_output.txt 2>&1
sh ./featquery_script_Control.sh > featquery_script_Control_output.txt 2>&1
