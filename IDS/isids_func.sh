#!/bin/bash
# This file is part of the i4k simple IDS scripts (ISIDS)
# Author: Tiago Natel de Moura AKA i4k
# License: GPL
# Early in the morning of 12/02/2012
#

export black='\E[30;47m'
export red='\E[31;47m'
export green='\E[32;47m'
export yellow='\E[33;47m'
export blue='\E[34;47m'
export magenta='\E[35;47m'
export cyan='\E[36;47m'
export white='\E[37;47m'

# Reset text terminal
export alias ResetTerminal="tput sgr0" 

# colored echo
# $1 = message
# $2 = color
# $3 = bold (true or false)
function cecho ()
{
    message="$1"
    # default color is black
    color=${2:-$black}

    if [ "x$3" = "xtrue" ];
    then
	message="\033[1m$message\033[0m"
    fi

    echo -e -n "$color"
    echo -e -n "$message"
    # Reset terminal to normal
    tput sgr0

  return
}  

function becho {
    echo -e -n "\033[1m$1\033[0m"
}

# Get the project name from user.
function it_create_project {
    PROJECT_NAME=""
    while [ "x$PROJECT_NAME" = "x" ];
    do
        read -p "Type a project name: " PROJECT_NAME
    done

    echo "$PROJECT_NAME"
}

# Get the directory under fire from user.
function it_fire_dir {
    FIRE_DIR=""
    while [ "x$FIRE_DIR" = "x" ];
    do
        read -p "Type a valid directory to monitor: " FIRE_DIR
        if [ ! -d "$FIRE_DIR" ];
        then
            FIRE_DIR=""
        fi
    done

    echo "$FIRE_DIR"
}

function it_email_report
{
    EMAIL_REPORT=""
    read -p "Type a valid email to send incident reports: " EMAIL_REPORT
    EMAIL_REPORT=`echo "$EMAIL_REPORT | grep '^[a-zA-Z0-9._%+-]*@[a-zA-Z0-9]*[\.[a-zA-Z0-9]*]*[a-zA-Z0-9]$'`

    echo "$EMAIL_REPORT"
}

# Iteratively set up the configurations
function ids_setup_iterative {
    PROJECT_NAME=`it_create_project`
    DIR_FIRE=`it_fire_dir`
    EMAIL_REPORT=`it_email_report`
}

function generate_cksum_database {
# $1 = INPUT DIRECTORY
# $2 = OUTPUT FILE

FILES=`find "$1"`
    for i in $FILES; 
    do 
	if [ ! -d "$i" ]; 
	then 
	    md5sum "$i" >> "$2"; 
	fi; 
    done

    return 0
}

function exclude_dir_from_file {
    mv "$1" "$1".bk
    PATTERN="s#$2##g"
    cat "$1".bk | sed "$PATTERN" > "$1"
    rm -f "$1".bk
    return
}

# Check if the $1 directory is a valid workspace directory
# return 0 on success and 1 if any error occurs
function check_project_files
{
    DIR="$1" # project directory
    NAME="$2"# project name
    ERROR=0
    if [ ! -d "$DIR" ];
    then
        echo "[-] $DIR is not a directory or permission denied to stat."
        return 1
    fi
    
    PROJECT_DIRS="$DIR/history-files" "$DIR/proc" "$DIR/logs" "$DIR/reports"
    PROJECT_FILES="$DIR/$NAME.conf"


    for file in $PROJECT_FILES;
    do
        if [ ! -f "$file" ];
        then
            echo "[-] File $file is missing."
            ERROR=1
        fi
    done

    for file in $PROJECT_DIRS;
    do
        if [ ! -d "$file" ];
        then
            echo "[-] Directory $file is missing."
            ERROR=1
        fi
    done

    return $ERROR
}
