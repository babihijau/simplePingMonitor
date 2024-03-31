#!/bin/bash

IP_LIST=("google.com" "69.69.420.420")
IP_LIST_NAME=("GOOGLE" "TEST")
IP_STATE=("" "")
STATUS_DURATION=("" "")
INTERVAL_SECONDS=30
TIMEZONE='' #EG: 'Asia/Kuala_Lumpur', 'America/New_York'. Default to GMT
TELEGRAM_BOT_API_TOKEN="" #YOUR_TOKEN
TELEGRAM_CHAT_ID_LIST=("" "") #YOUR_RECEPIENT_IDS

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

mkdir -p monitorLogs
LOGFILE="./monitorLogs/monitor_$(date +'%Y%m%d_%H%M').log"

secondsToTime () {
  T=$1
  D=$((T/60/60/24))
  H=$((T/60/60%24))
  M=$((T/60%60))
  S=$((T%60))
  
  if [[ ${D} != 0 ]]
  then
    printf '%d days %02d hours %02d minutes %02d seconds' $D $H $M $S
  else
    printf '%02d hours %02d minutes %02d seconds' $H $M $S
  fi
}

logOutput () {
  # strip console color for logfile
  OUTPUT="$1"
  
  echo -e $OUTPUT | tee >(sed $'s/\033[[][^A-Za-z]*[A-Za-z]//g' >> $LOGFILE)
}

sendMessage () {
  # send telegram to all
  MESSAGE="$1"
  
  for (( j = 0; j < ${#TELEGRAM_CHAT_ID_LIST[@]}; ++j )); do
    TELEGRAM_CHAT_ID="${TELEGRAM_CHAT_ID_LIST[j]}"
    
    curl -s POST https://api.telegram.org/bot${TELEGRAM_BOT_API_TOKEN}/sendMessage -d chat_id=${TELEGRAM_CHAT_ID} -d parse_mode="html" -d text="${MESSAGE}" &> /dev/null
  done
}

update () {
  # Send notification if status changed from UP to DOWN and vice versa
  for (( i = 0; i < ${#IP_LIST[@]}; ++i )); do
    IP="${IP_LIST[i]}"
    IP_NAME="${IP_LIST_NAME[i]}"
    PREV_STATE="${IP_STATE[i]}"
    
    if ping -c 1 ${IP} &> /dev/null
    then
      TIME_ELAPSED=$(($(date +%s)-$STATUS_DURATION))
      
      if [[ "${PREV_STATE}" = "DOWN" ]]
      then
        logOutput "${YELLOW}${IP_NAME}${NC} (${IP}) is ${GREEN}UP${NC} again at: ${CYAN}$(TZ=${TIMEZONE} date)${NC}. Was ${RED}DOWN${NC} for $(secondsToTime ${TIME_ELAPSED})."
        sendMessage "<b>${IP_NAME}</b> (<i>${IP}</i>) is <b>UP</b> again at: $(TZ=${TIMEZONE} date +"%a %T %d %b %Y"). ${IP_NAME} was DOWN for $(secondsToTime ${TIME_ELAPSED})"
        
        IP_STATE[i]="UP"
        STATUS_DURATION[i]=$(date +%s)
      else
        logOutput "${YELLOW}${IP_NAME}${NC} (${IP}) is still ${GREEN}UP${NC} at: ${CYAN}$(TZ=${TIMEZONE} date)${NC}. Has been ${GREEN}UP${NC} for $(secondsToTime ${TIME_ELAPSED})."
      fi
    else
      TIME_ELAPSED=$(($(date +%s)-$STATUS_DURATION))
      
      if [[ "${PREV_STATE}" = "UP" ]]
      then
        logOutput "${YELLOW}${IP_NAME}${NC} (${IP}) is ${RED}DOWN${NC} again at: ${CYAN}$(TZ=${TIMEZONE} date)${NC}. Was ${GREEN}UP${NC} for $(secondsToTime ${TIME_ELAPSED})."
        sendMessage "<b>${IP_NAME}</b> (<i>${IP}</i>) is <b>DOWN</b> again at: $(TZ=${TIMEZONE} date +"%a %T %d %b %Y"). ${IP_NAME} was UP for $(secondsToTime ${TIME_ELAPSED})"
        
        IP_STATE[i]="DOWN"
        STATUS_DURATION[i]=$(date +%s)
      else
        logOutput "${YELLOW}${IP_NAME}${NC} (${IP}) is still ${RED}DOWN${NC} at: ${CYAN}$(TZ=${TIMEZONE} date)${NC}. Has been ${RED}DOWN${NC} for $(secondsToTime ${TIME_ELAPSED})."
      fi
    fi
  done
  
  sleep ${INTERVAL_SECONDS}
  update
}

main () {
  echo "Starting the monitor at: $(TZ=${TIMEZONE} date). Retry interval is ${INTERVAL_SECONDS} seconds."
  sendMessage "Starting the monitor at $(TZ=${TIMEZONE} date +"%a %T %d %b %Y"). Retry interval is ${INTERVAL_SECONDS} seconds."
  
  # 1st check
  for (( i = 0; i < ${#IP_LIST[@]}; ++i )); do
    IP="${IP_LIST[i]}"
    IP_NAME="${IP_LIST_NAME[i]}"
    STATUS_DURATION[i]=$(date +%s)
    
    if ping -c 1 ${IP} &> /dev/null
    then
      IP_STATE[i]="UP"
      logOutput "${YELLOW}${IP_NAME}${NC} (${IP}) is ${GREEN}UP${NC} at: ${CYAN}$(TZ=${TIMEZONE} date)${NC}."
      sendMessage "<b>${IP_NAME}</b> (<i>${IP}</i>) is <b>UP</b> at: $(TZ=${TIMEZONE} date +"%a %T %d %b %Y")."
    else
      IP_STATE[i]="DOWN"
      logOutput "${YELLOW}${IP_NAME}${NC} (${IP}) is ${RED}DOWN${NC} at: ${CYAN}$(TZ=${TIMEZONE} date)${NC}."
      sendMessage "<b>${IP_NAME}</b> (<i>${IP}</i>) is <b>DOWN</b> at: $(TZ=${TIMEZONE} date +"%a %T %d %b %Y")."
    fi
  done
  
  update
}

beforeExit () {
  logOutput "Stopping the monitor at: ${CYAN}$(TZ=${TIMEZONE} date)${NC}."
  sendMessage "Stopping the monitor at: $(TZ=${TIMEZONE} date +"%a %T %d %b %Y")."
}

trap beforeExit EXIT
main