#!/bin/bash

IP_LIST=("google.com" "69.69.420.420")
IP_LIST_NAME=("GOOGLE" "TEST")
IP_STATE=("" "")
STATUS_DURATION=("" "")
INTERVAL_SECONDS=30
TIMEZONE='' #EG: 'Asia/Kuala_Lumpur', 'America/New_York'. Default to GMT
TELEGRAM_BOT_API_TOKEN="" #YOUR_TOKEN
TELEGRAM_CHAT_ID="" #YOUR_CHAT_ID

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

seconds2time () {
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

sendMessage () {
  MESSAGE="$1"
  
  curl -s POST https://api.telegram.org/bot${TELEGRAM_BOT_API_TOKEN}/sendMessage -d chat_id=${TELEGRAM_CHAT_ID} -d parse_mode="html" -d text="${MESSAGE}"
}

update () {
  # Send notification if status changed from UP to DOWN and vice versa
  for (( i = 0; i < ${#IP_LIST[@]}; ++i )); do
    IP="${IP_LIST[i]##*/}"
    IP_NAME="${IP_LIST_NAME[i]##*/}"
    PREV_STATE="${IP_STATE[i]}"
    TIME_ELAPSED=$(($(date +%s)-$STATUS_DURATION))
    
    if ping -c 1 ${IP} &> /dev/null
    then
      if [[ "${PREV_STATE}" = "DOWN" ]]
      then
        echo -e "${YELLOW}${IP_NAME}${NC} (${IP}) is ${GREEN}UP${NC} again at: ${CYAN}$(TZ=${TIMEZONE} date)${NC}."
        echo -e "${YELLOW}${IP_NAME}${NC} was ${RED}DOWN${NC} for $(seconds2time ${TIME_ELAPSED})."
        sendMessage "<b>${IP_NAME}</b> (<i>${IP}</i>) is <b>UP</b> again at: $(TZ=${TIMEZONE} date +"%a %T %d %b %Y"). ${IP_NAME} was DOWN for $(seconds2time ${TIME_ELAPSED})"
        
        IP_STATE[i]="UP"
        STATUS_DURATION[i]=$(date +%s)
      else
        echo -e "${YELLOW}${IP_NAME}${NC} is still ${GREEN}UP${NC} at: ${CYAN}$(TZ=${TIMEZONE} date)${NC}."
        echo -e "${YELLOW}${IP_NAME}${NC} has been ${GREEN}UP${NC} for $(seconds2time ${TIME_ELAPSED})."
        
      fi
    else
      if [[ "${PREV_STATE}" = "UP" ]]
      then
        echo -e "${YELLOW}${IP_NAME}${NC} (${IP}) is ${RED}DOWN${NC} again at: ${CYAN}$(TZ=${TIMEZONE} date)${NC}."
        echo -e "${YELLOW}${IP_NAME}${NC} was ${GREEN}UP${NC} for $(seconds2time ${TIME_ELAPSED})."
        sendMessage "<b>${IP_NAME}</b> (<i>${IP}</i>) is <b>DOWN</b> again at: $(TZ=${TIMEZONE} date +"%a %T %d %b %Y"). ${IP_NAME} was UP for $(seconds2time ${TIME_ELAPSED})"
        
        IP_STATE[i]="DOWN"
        STATUS_DURATION[i]=$(date +%s)
      else
        echo -e "${YELLOW}${IP_NAME}${NC} is still ${RED}DOWN${NC} at: ${CYAN}$(TZ=${TIMEZONE} date)${NC}."
        echo -e "${YELLOW}${IP_NAME}${NC} has been ${RED}DOWN${NC} for $(seconds2time ${TIME_ELAPSED})."
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
    IP="${IP_LIST[i]##*/}"
    IP_NAME="${IP_LIST_NAME[i]##*/}"
    STATUS_DURATION[i]=$(date +%s)
    
    if ping -c 1 ${IP} &> /dev/null
    then
      IP_STATE[i]="UP"
      echo -e "${YELLOW}${IP_NAME}${NC} (${IP}) is ${GREEN}UP${NC} at: ${CYAN}$(TZ=${TIMEZONE} date)${NC}."
      sendMessage "<b>${IP_NAME}</b> (<i>${IP}</i>) is <b>UP</b> at: $(TZ=${TIMEZONE} date +"%a %T %d %b %Y")."
    else
      IP_STATE[i]="DOWN"
      echo -e "${YELLOW}${IP_NAME}${NC} (${IP}) is ${RED}DOWN${NC} at: ${CYAN}$(TZ=${TIMEZONE} date)${NC}."
      sendMessage "<b>${IP_NAME}</b> (<i>${IP}</i>) is <b>DOWN</b> at: $(TZ=${TIMEZONE} date +"%a %T %d %b %Y")."
    fi
  done
  
  update
}

main