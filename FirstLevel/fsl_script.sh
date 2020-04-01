#!/bin/bash
#
# Script for analysis of FSL data from the DICOM level
# Converts DICOMs to FSL reoriented NIFTIs
# Note that DICOMs have not been shared as they are potentially identifiable
# The output of this script has been shared on OpenNeuro
#
# Reads output directory from SubjectList.txt. 
OUTPUT_DIR="$(cat SubjectList.txt | grep OUTPUT_DIR | awk -F' ' '{ print $3 }')"


########################
# FUNCTION DEFINITIONS #
########################

# convertdcm() Function
# Converts DICOMs to NIFTI
convertdcm() {
	dcm2nii -n y -d n -f y -o $1 $2
}

# fslprep() Function
# Function to reorient and average for FSL use
# Takes as argument a given NIFTI file; must be in the format *.nii.gz 
fslprep() {
	ROOTNAME="$(echo "$1" | sed 's|.nii.gz||')"

	fslreorient2std $1 "$ROOTNAME"_reorient.nii.gz
	fslmaths "$ROOTNAME"_reorient.nii.gz -Tmean "$ROOTNAME"_reorient_avg.nii.gz
	fsl_motion_outliers -i "$ROOTNAME"_reorient.nii.gz -o "$ROOTNAME"_confound.txt --dummy=$DUMMY

	# If structural, set f- and g- BET values to those set in SubjectList.txt and generate SUBJ_reorient_brain.nii.gz' 
	# If functional, set f=0.3 and g=0, and generate SUBJ_reorient_avg_brain.nii.gz
	if [[ $1 = *"sagt1"* ]]; then
		fbet=$2
		gbet=$3
		echo "Extracting structural with f=$fbet and g=$gbet"
		echo "Extracting to "$ROOTNAME"_reorient_brain.nii.gz"
		bet "$ROOTNAME"_reorient.nii.gz "$ROOTNAME"_reorient_brain.nii.gz -f $fbet -g $gbet
	else
		fbet=0.3
		gbet=0
		echo "Extracting functional to "$ROOTNAME"_reorient_avg_brain.nii.gz"
		bet "$ROOTNAME"_reorient_avg.nii.gz "$ROOTNAME"_reorient_avg_brain.nii.gz -f $fbet -g $gbet
	fi
}

########################
#        SCRIPT        #
########################

# Read SubjectList.txt into temporary file, ignoring commented lines
SubjectList=$(mktemp)
sed '/#/d' SubjectList.txt > "$SubjectList"

# Read subject of interest from SubjectList.txt (in same folder as script)
while read -r line
do
	DIR="$(echo "$line" | awk -F' ' '{ print $1 }')"
	FBET="$(echo "$line" | awk -F' ' '{ print $2 }')"
	GBET="$(echo "$line" | awk -F' ' '{ print $3 }')"
	SUBJECT_DIR="$(echo "$DIR")"
	SUBJECT="$(echo "$SUBJECT_DIR" | head -c 7)"
	
	echo "***************************************************************************************************"
	echo ""
	echo "Processing $SUBJECT scan"
	echo "Subject directory is $DIR/"
	echo "BET f is set to $FBET"
	echo "BET g is set to $GBET"
	echo "Outputting to $OUTPUT_DIR/$DIR/"
	echo ""
	echo "***************************************************************************************************"

	# Directory creation
	mkdir -p $OUTPUT_DIR/$DIR/func/language
	mkdir -p $OUTPUT_DIR/$DIR/anat

	# For each sequence, call functions to convert DICOM to NIFTI
	# Then reorient, average, extract, and generate motion outliers

	# Structural 
	DCM2NII_IN="$(find $DIR/*PRAGE*RMS* -maxdepth 0 | head -n 1)"
	DCM2NII_OUT="$OUTPUT_DIR/$DIR/anat"
	convertdcm $DCM2NII_OUT $DCM2NII_IN 
	rsync $DCM2NII_OUT/IM*.nii.gz $DCM2NII_OUT/sagt1.nii.gz
	rm -rf $DCM2NII_OUT/*IM*.nii.gz
	fslprep $DCM2NII_OUT/sagt1.nii.gz $FBET $GBET

	# Language 1 
	DCM2NII_IN="$(find $DIR/ -maxdepth 1 -name *LANGUAGE_1* -o -name "*LANG_1*")"
	DCM2NII_OUT="$OUTPUT_DIR/$DIR/func/language"
	convertdcm $DCM2NII_OUT $DCM2NII_IN 
	# The following if...else statement is required due to differences in DICOM naming conventions
	# Some subjects are named ...LANG_1..., while others are named LANGUAGE_1...
	if [[ $DCM2NII_IN = *"LANG_1"* ]]; then
		rsync $DCM2NII_OUT/IM*LANG1*.nii.gz $DCM2NII_OUT/lang1.nii.gz
	else
		rsync $DCM2NII_OUT/IM*LANGUAGE1*.nii.gz $DCM2NII_OUT/lang1.nii.gz
	fi
	rm -rf $DCM2NII_OUT/*IM*.nii.gz
	fslprep $DCM2NII_OUT/lang1.nii.gz $FBET $GBET

	# Language 2
	DCM2NII_IN="$(find $DIR/ -maxdepth 1 -name "*LANGUAGE_2*" -o -name "*LANG_2*")"
	DCM2NII_OUT="$OUTPUT_DIR/$DIR/func/language"
	convertdcm $DCM2NII_OUT $DCM2NII_IN 
	# The following if...else statement is required due to differences in RESPONSE DICOM naming conventions
	# Some subjects are named ...LANG_1..., while others are named LANGUAGE_1...
	if [[ $DCM2NII_IN = *"LANG_2"* ]]; then
		rsync $DCM2NII_OUT/IM*LANG2*.nii.gz $DCM2NII_OUT/lang2.nii.gz
	else
		rsync $DCM2NII_OUT/IM*LANGUAGE2*.nii.gz $DCM2NII_OUT/lang2.nii.gz
	fi
	rm -rf $DCM2NII_OUT/*IM*.nii.gz
	fslprep $DCM2NII_OUT/lang2.nii.gz $FBET $GBET

done < "$SubjectList"

# Clean up temporary file
rm $SubjectList
