#!/bin/bash
#
# Script for FSL BET Optimization 
# For RESPONSE Pilot data
# Runs BET with range of f- and g-values,
# Then renders results into .png for easy browsing and selection of ideal parameters
#
# ***** IMPORTANT! READ BELOW *****
# fsl_script.sh MUST be run before bet_optimizer can be run, as the optimizer requires FSL reoriented NIFTIS prior to extraction

# Read output directory from SubjectList.txt. 
OUTPUT_DIR="$(cat SubjectList.txt | grep OUTPUT_DIR | awk -F' ' '{ print $3 }')"

# Perform bet extraction over a range of f- and g- values then render each into a .png file for easy browsing and selection of ideal parameters
betoptimizer() {
	ROOTNAME="$(echo "$1" | sed 's|.nii.gz||')"
	
	#For loop for f-values
	echo "Trying different values of f and g"
	for fbet in $(seq 0 0.1 1);
	do
		for gbet in $(seq -1 0.2 1);
		do
			echo ""
			echo "Extracting $SUBJECT with f=$fbet g=$gbet ..."
			bet "$ROOTNAME"_reorient.nii.gz "$ROOTNAME"_reorient_brain_f"$fbet"_g"$gbet".nii.gz -f "$fbet" -g "$gbet"
			echo "Extracted NIFTI written to "$ROOTNAME"_reorient_brain_f"$fbet"_g"$gbet".nii.gz"
			echo "Rendering $SUBJECT ..."
			/usr/pubsw/packages/FSLeyes/0.22.4/fsleyes render -slightbox -zx Z -ss 4 -nr 5 -nc 10 --size 1920 1080 -of "$ROOTNAME"_reorient_brain_f"$fbet"_g"$gbet".png "$ROOTNAME"_reorient_brain_f"$fbet"_g"$gbet".nii.gz
			echo "Rendered extraction image to "$ROOTNAME"_reorient_brain_f"$fbet"_g"$gbet".png"
			mv "$ROOTNAME"*_f*_g*.* $DCM2NII_OUT/optimization					
		done
	done
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
	# Extract variables of interest from SubjectList.txt information
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
	mkdir -p $OUTPUT_DIR/$DIR/anat/optimization
	
	# Structural 
	DCM2NII_IN="$(find $DIR/*PRAGE*RMS* -maxdepth 0 | head -n 1)"
	DCM2NII_OUT="$OUTPUT_DIR/$DIR/anat"
	betoptimizer $DCM2NII_OUT/sagt1.nii.gz $FBET $GBET
	
done < "$SubjectList"

# Clean up temporary file
rm $SubjectList
