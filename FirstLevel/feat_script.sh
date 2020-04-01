#!/bin/bash
#
# FEAT Script
#
# Creates fMRI design file (*.fsf) from template for each subject
# Performs first-level and second-level FEAT analysis 
#
# Reads output directory from SubjectList.txt. 
OUTPUT_DIR="$(cat SubjectList.txt | grep OUTPUT_DIR | awk -F' ' '{ print $3 }')"

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
	TEMPLATE_DIR="./"
	
        echo "***************************************************************************************************"
        echo ""
        echo "Processing $SUBJECT scan"
        echo "Subject directory is $DIR/"
        echo "Outputting to $OUTPUT_DIR/$DIR/"
        echo ""
        echo "***************************************************************************************************"
	
	# Language 1
	echo ""
	echo "Language 1 Processing"	
	echo "Generating fMRI design file based on $TEMPLATE_DIR/lang_level1_z3p1_FWHM10.fsf"
	rsync $TEMPLATE_DIR/lang_level1_z3p1_FWHM10.fsf $OUTPUT_DIR/$DIR/func/language/lang1_level1_z3p1_FWHM10.fsf

	sed -i "s|SUBJECTDIR|$OUTPUT_DIR/$DIR|g" \
		$OUTPUT_DIR/$SUBJECT/stim_fMRI/final/language/$SCAN_DATE/lang1_level1_z3p1_FWHM10.fsf
	echo "fMRI design file created at $OUTPUT_DIR/$DIR/func/language/lang1_level1_z3p1_FWHM10.fsf"
	echo "Performing FEAT analysis using $OUTPUT_DIR/$DIR/func/language/lang1_level1_z3p1_FWHM10.fsf"
	feat $OUTPUT_DIR/$DIR/func/language/lang1_level1_z3p1_FWHM10.fsf &
	pids[1]=$!

	# Language 2
	echo ""	
	echo "Language 2 Processing"	
	echo "Generating fMRI design file based on $TEMPLATE_DIR/lang_level1_z3p1_FWHM10.fsf"
	rsync $TEMPLATE_DIR/lang_level1_z3p1_FWHM10.fsf $OUTPUT_DIR/$DIR/func/language/lang2_level1_z3p1_FWHM10.fsf
	sed -i "s|SUBJECTDIR|$OUTPUT_DIR/$DIR|g" \
		$OUTPUT_DIR/$DIR/func/language/lang2_level1_z3p1_FWHM10.fsf
	sed -i "s|lang1|lang2|g" \
		$OUTPUT_DIR/$DIR/func/language/lang2_level1_z3p1_FWHM10.fsf
	echo "fMRI design file created at $OUTPUT_DIR/$DIR/func/language/lang2_level1_z3p1_FWHM10.fsf"
	echo "Performing FEAT analysis using $OUTPUT_DIR/$DIR/func/language/lang2_level1_z3p1_FWHM10.fsf"
	feat $OUTPUT_DIR/$DIR/func/language/lang2_level1_z3p1_FWHM10.fsf &
	pids[2]=$!

	# Each run is executed in parallel, now wait until all processes complete (otherwise could easily overload a system when many subjects run simultaneously!)
	for pid in ${pids[*]}; do
		wait $pid
	done
	echo ""
	echo "***** FIRST-LEVEL ANALYSIS COMPLETED FOR $SUBJECT *****"
	echo ""
	
	# Language Second-Level
	echo ""
	echo "Language Level 2 Processing"
	echo "Generating fMRI design file based on $TEMPLATE_DIR/lang_level2_z3p1_FWHM10.fsf"
	rsync $TEMPLATE_DIR/lang_level2_z3p1_FWHM10.fsf $OUTPUT_DIR/$SUBJECT/stim_fMRI/final/language/$SCAN_DATE/
	sed -i "s|SUBJECTDIR|$OUTPUT_DIR/$DIR|g" \
		$OUTPUT_DIR/$DIR/func/language/lang_level2_z3p1_FWHM10.fsf
	echo "fMRI design file created at $OUTPUT_DIR/$DIR/func/language/lang_level2_z3p1_FWHM10.fsf"
	echo "Performing second-level FEAT analysis using $OUTPUT_DIR/$DIR/func/language/lang_level2_z3p1_FWHM10.fsf"
	feat $OUTPUT_DIR/$DIR/func/language/lang_level2_z3p1_FWHM10.fsf &
	pids[1]=$!

	# Each run is executed in parallel, now wait until all processes complete (otherwise could easily overload a system when many subjects run simultaneously!)
	for pid in ${pids[*]}; do
		wait $pid
	done
	echo ""
	echo "***** SECOND-LEVEL ANALYSIS COMPLETED FOR $SUBJECT *****"
	echo ""

done < "$SubjectList"

# Clean up temp file
rm $SubjectList
