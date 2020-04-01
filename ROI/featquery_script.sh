#!/bin/bash
#
# FSL featquery script
# For each subject in SubjectList.txt
# And each ROI in ROIlist.txt
#
# Reads output directory from SubjectList.txt. 
OUTPUT_DIR="$(cat SubjectList.txt | grep OUTPUT_DIR | awk -F' ' '{ print $3 }')"
# The below lines, if uncommented, override the output directory indicated above in the SubjectList.txt file
#OUTPUT_DIR="/autofs/space/nicc_001/RESPONSE/zdthrelkeld/Language"
#OUTPUT_DIR="/autofs/space/nicc_001/RESPONSE/TCRp"

# Read SubjectList.txt into temp file, ignoring commented lines
SubjectList=$(mktemp)
sed '/#/d' SubjectList.txt > "$SubjectList"

while read -r line
do
	# Read ROIlist.txt into an array and establish ROI variables
	ROIlist=$(mktemp)
	sed '/#/d' ROIlist.txt > "$ROIlist"
	readarray rois < $ROIlist
	NROI=${#rois[@]}
	echo ""
	echo "Using ${NROI} ROI(s)..."
	
	for (( i=0; i<${NROI}; i++ ));
	do
		roinames[$i]="$(echo "${rois[$i]}" | awk -F'/' '{ print $NF }' | awk -F'.' '{ print $1 }')"
		echo "ROI $i Name: ${roinames[$i]}"
		echo "ROI $i Location: ${rois[$i]}"
	done
	rm -rf $ROIlist

	# Establish variables
	DIR="$(echo "$line" | awk -F' ' '{ print $1 }')"
	SUBJECT_DIR="$(echo "$DIR" | tail -c 23)"
        SUBJECT="$(echo "$SUBJECT_DIR" | head -c 7)"
        SCAN_DATE="$(echo "$DIR" | tail -c 9)"
	FQDIR=$OUTPUT_DIR/$SUBJECT/stim_fMRI/final/language/$SCAN_DATE/level2_z3p1_FWHM10.gfeat

        echo "***************************************************************************************************"
        echo ""
        echo "Processing $SUBJECT scan from $SCAN_DATE"
        echo "Subject directory is $DIR/"
	echo "Using level 2 analyses in:"
	echo "   $FQDIR"
        echo ""
        echo "***************************************************************************************************"

	# featquery command
	for (( i=0; i<${NROI}; i++ ));
	do
		echo ""
		#echo "Featquerying $SUBJECT scan from $SCAN_DATE with ${roinames[$i]} ROI.."
		#/usr/pubsw/packages/fsl/current/bin/featquery 1 "$FQDIR/cope1.feat" \
		#6 stats/pe1 stats/cope1 stats/varcope1 stats/tstat1 stats/zstat1 thresh_zstat1 featquery -a 4 -p -s "${rois[$i]}"

		# Rename featquery folders more descriptively
		#mv $FQDIR/cope1.feat/featquery $FQDIR/cope1.feat/featquery_langforw_"${roinames[$i]}"

		/usr/pubsw/packages/fsl/current/bin/featquery 1 "$FQDIR/cope1.feat" \
		6 stats/pe1 stats/cope1 stats/varcope1 stats/tstat1 stats/zstat1 thresh_zstat1 featquery -a 4 -p -t 0 -s "${rois[$i]}"

		# Rename featquery folders more descriptively
		mv $FQDIR/cope1.feat/featquery $FQDIR/cope1.feat/featquery_langforw_"${roinames[$i]}"
	done

done < "$SubjectList"

# Clean up temp file
rm $SubjectList

