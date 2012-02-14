#!/bin/bash
#
# Project Name:: S.W.A.T. IDS
#
# Copyright 2012, Tiago Natel de Moura
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# This file is part of the i4k simple IDS scripts (ISIDS)
# Author: Tiago Natel de Moura AKA i4k
# License: GPL
# Early in the morning of 12/02/2012
#

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
function it_monitor_dir {
    MONITOR_DIR=""
    while [ "x$MONITOR_DIR" = "x" ];
    do
        read -p "Type a valid directory to monitor: " MONITOR_DIR
        if [ ! -d "$MONITOR_DIR" ];
        then
            MONITOR_DIR=""
        fi
    done

    echo "$MONITOR_DIR"
}

function it_email_report
{
    EMAIL_REPORT=""
    while [ "x$EMAIL_REPORT" = "x" ];
    do
        read -p "Type a valid email to send incident reports: " EMAIL_REPORT
        EMAIL_REPORT=`echo "$EMAIL_REPORT" | grep '^[a-zA-Z0-9._%+-]*@[a-zA-Z0-9]*[\.[a-zA-Z0-9]*]*[a-zA-Z0-9]$'`
    done

    echo "$EMAIL_REPORT"
}

# Iteratively set up the configurations
function ids_setup_iterative {
    local OPT=""
    PROJECT_NAME=`it_create_project`
    DIR_FIRE=`it_monitor_dir`

    echo "[!] Do you want receive reports of incidents by email ?"
    
    while [ "x$OPT" = "x" ];
    do
        read -p "[y/n]: " OPT
        if [ "x$OPT" != "xy" -a "x$OPT" != "xn" -a "x$OPT" != "xN" -a "x$OPT" != "xY" ];
        then
            OPT=""
        fi
    done

    if [ "x$OPT" = "xy" -o "x$OPT" = "xY" ];
    then
        EMAIL_REPORT=`it_email_report`
    fi
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
# return 0 on project exists and is OK, 1 if exists but contain errors
# and 2 if not exists.
function check_project_files
{
    DIR="$1" # project directory
    NAME="$2" # project name
    ERROR=0
    
    if [ ! -d "$DIR" ];
    then
        return 2
    fi

    echo "[!] Project exists! Checking if is a valid project directory..."
    
    PROJECT_DIRS=( "$DIR/history-files" "$DIR/proc" "$DIR/logs" "$DIR/reports" )
    PROJECT_FILES=( "$DIR/$NAME.conf" )


    for i in $(seq 0 $((${#PROJECT_FILES[@]} - 1)));
    do
        if [ ! -f "${PROJECT_FILES[$i]}" ];
        then
            becho "[-][`basename ${PROJECT_FILES[$i]}`][MISSING]\n"
            ERROR=1
        else
            becho "[+][`basename ${PROJECT_FILES[$i]}`][FOUND]\n"
        fi
    done

    for i in $(seq 0 $((${#PROJECT_DIRS[@]} - 1)));
    do
        if [ ! -d "${PROJECT_DIRS[$i]}" ];
        then
            becho "[-][`basename ${PROJECT_DIRS[$i]}`][MISSING]\n"
            ERROR=1
        else
            becho "[+][`basename ${PROJECT_DIRS[$i]}`][FOUND]\n"
        fi
    done

    return $ERROR
}

function aborting
{
    echo "aborting..."
    exit $1
}
