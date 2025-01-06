# FlexLM_usage_logger
# Bash script to collect FlexLM usage data. Based on lmstats command. Very common in O&G software.

INSTALL

# Create HOMEPPU
mkdir -p /opt/ppu/logs

# Put the script there
/opt/ppu/ppu.sh 

# Start script
Copy S99ppu script to the init default
e.g. /etc/rc5.d for Linux
e.g. /etc/rc2.d for Solaris

# CHECK IT!
FLEXLM_BIN=/usr/local/flexlm
LMSTAT="$FLEXLM_BIN/lmstat -a -c $PORT@$HOSTNAME"

# Add to crontab
# Sample run every minute
* * * * * /opt/ppu/ppu.sh port server

# Version 0.5
. Take care of multiple lics in one row

# Version 0.6
. Check OS
. Lock File
. Start script

# Version 1.0
. Verify if total licenses are formed by groups of INCREMENT

