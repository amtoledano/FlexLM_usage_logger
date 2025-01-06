#!/bin/bash
# ppu.sh PPU log script
#
# Script by [atoledano@yahoo.com].
# Version 1.0
# 
# Parameters 
PORT=$1
HOSTNAME=$2
OS=`uname -s`

# To Set
PPUHOME=/opt/ppu
PPULOG=$PPUHOME/logs
FLEXLM_BIN=/opt/ppu/bin
LMSTAT="$FLEXLM_BIN/lmstat -a -c $PORT@$HOSTNAME"
LOCKFILE=$PPULOG/$PORT$HOSTNAME.run

# Check OS
if [ $OS = "SunOS" ]
then
	DELETE="/usr/bin/rm -f"
	AWK=/usr/bin/awk
	CUT=/usr/bin/cut
	WC=/usr/bin/wc
	CAT=/usr/bin/cat
	TOUCH=/usr/bin/touch
else
	if [ $OS = "Linux" ]
	then
		DELETE="/bin/rm -f"
		AWK=/bin/awk
		CUT=/bin/cut
		WC=/usr/bin/wc
		CAT=/bin/cat
		TOUCH=/bin/touch
	else
		echo "Only SUN or Linux supported"
		exit
	fi		
fi

# Check LockFile
if [ -f $LOCKFILE ]
then
        exit
else
        $TOUCH $LOCKFILE
fi

# TimeStamp
DIA=`date '+%d'`
MES=`date '+%m'`
YEAR=`date '+%y'`
HORA=`date '+%H'`
MINUTO=`date '+%M'`
FECHA=$DIA$MES$YEAR$HORA$MINUTO
DATE=$MES/$DIA/$YEAR
TIME=$HORA:$MINUTO

# Files and Logs
TMPFILE="$PPULOG/$PORT$HOSTNAME.out"
LOGFILE="$PPULOG/$HOSTNAME$MES$YEAR.log"
DATFILE="$PPULOG/$HOSTNAME$MES$YEAR.dat"
ERRFILE="$PPULOG/$HOSTNAME$MES$YEAR.err"
SOURCEFILE="$PPULOG/$PORT$HOSTNAME$DIA$MES$YEAR$HORA$MINUTO.dat"

# Clear error log
echo "" > $ERRFILE

# Func
usage()
{
    echo "Usage: ppu.sh PORT SERVER" 2>&1
    echo "Eg: ppu.sh 1700 flexserver" 2>&1
    exit 
}

# Parameter Control
if [ $# -lt 2 ]
then
	usage
else
	if [ $# -gt 2 ]
	then
		usage
	fi
fi

# RUN
# Make $TMPFILE
$LMSTAT > $TMPFILE
# Make source file = $TMPFILE without empty lines
$AWK 'NF > 0' $TMPFILE > $SOURCEFILE
#
# Parse txt
COUNT=`$CAT $SOURCEFILE|wc -l`
COUNTER="1"
$CAT $SOURCEFILE | while read LINE
do
		# COL1 line type = User/Cannot/Error
		COL1=`echo $LINE | $AWK '{printf $1}'`
		# COL3 Feature COL3N and COL3NN used for cut last character
		COL3=`echo $LINE | $AWK '{printf $3}'`
		COL3N=`echo $LINE | $AWK '{printf $3}' | $WC -c`
		COL3NN=`expr $COL3N - 1`
		# COL4 Total or Error
		COL4=`echo $LINE | $AWK '{printf $4}'`
		# COL6 Total lic
		COL6=`echo $LINE | $AWK '{printf $6}'`
		# COL11 features in use
		COL11=`echo $LINE | $AWK '{printf $11}'`
		if [ -z $COL11 ] 
		then 
			COL11="0" 
		fi
			if [ $COL1 = "Users" ]
			# Is a Feature
			then
				# COL3 cuted
				COL3=`echo $LINE | $AWK '{printf $3}' | $CUT -b1-$COL3NN`
					if [ $COL4 = "(Error:" ]
					# Is a Feature but has errors
					then
						echo $DATE $TIME FEATURE $COL3 informa ERROR >> $ERRFILE
					else
						if [ $COL4 = "Cannot" ]
						# Is a Feature but cannot get data
						then
							echo $DATE $TIME FEATURE $COL3 Cannot get info ERROR >> $ERRFILE
						else
							 # Is a valid Feature
							if [ $COL11 = "0" ]
							then
								# but not in use
								# output format DDMMYYhhmm Feature Total InUse
								## echo $FECHA	$COL3	$COL6	$COL11 >> $LOGFILE
								echo $DATE	$TIME	$COL3	$COL6	$COL11  >> /dev/null
							else
								# Is in use
								echo $DATE	$TIME	$COL3	$COL6	$COL11 >> $LOGFILE
								PUNTERO=`expr $COUNTER + 3`
								TOTLIC="0" 
								# List all in use
								while [ $TOTLIC -lt $COL11 ]
								do
									CANTLIC=`$CAT $SOURCEFILE | $AWK 'NR == '$PUNTERO' {print $0 }'| $AWK '{printf $11}' `
									# This field exist if a multiple licenses occours eg parallel
                                                                	if [ -z $CANTLIC ]
                                                                	then
										# Check if starts w/" then INCREMENT
										INCREMENT=`$CAT $SOURCEFILE | $AWK 'NR == '$PUNTERO' {print $0 }' | $AWK '{printf $1}' |$CUT -b1`
										if [ $INCREMENT = \" ] 
											then
											PUNTERO=`expr $PUNTERO + 2`
										fi
										$CAT $SOURCEFILE | $AWK 'NR == '$PUNTERO' {print $0 }' | $AWK '{printf date "\t" time "\t" $1 "\t" $2 "\t" col3 "\t" 1 "\n"}' date=$DATE time=$TIME col3=$COL3 >> $DATFILE
										TOTLIC=`expr $TOTLIC + 1`
										PUNTERO=`expr $PUNTERO + 1`
									else
										# Check if starts w/" then INCREMENT
										INCREMENT=`$CAT $SOURCEFILE | $AWK 'NR == '$PUNTERO' {print $0 }' | $AWK '{printf $1}' |$CUT -b1`
										if [ $INCREMENT = \" ] 
											then
											PUNTERO=`expr $PUNTERO + 2`
										fi
										$CAT $SOURCEFILE | $AWK 'NR == '$PUNTERO' {print $0 }' | $AWK '{printf date "\t" time "\t" $1 "\t" $2 "\t" col3 "\t" cantlic "\n"}' date=$DATE time=$TIME col3=$COL3 cantlic=$CANTLIC >> $DATFILE
										TOTLIC=`expr $TOTLIC + $CANTLIC`
										PUNTERO=`expr $PUNTERO + 1`
									fi
								done
							fi
						fi
					fi	
			# Is not a Feature, header, servers etc...
			fi
COUNTER=`expr $COUNTER + 1`
done
# Clean Files
$DELETE $TMPFILE 
$DELETE $SOURCEFILE
$DELETE $LOCKFILE
exit
