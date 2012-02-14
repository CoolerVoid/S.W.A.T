#!/bin/bash

WORKSPACE_DIR="workspace"
PROJECT_DIR=""
PROJECT_NAME=""
TEMP_DIR="current"
FIRE_DIR=""
NEW_PROJECT="false"
CURRENT_CLEAN_FILE=""
EMAIL_REPORT=""
EXCLUDE_DIR=""
INTERACTIVE="false"

DEFAULT_PROJECT_DIRS=( "history-files" "proc" "logs" "reports" )


source define.sh
source isids_func.sh

function show_help {
    clear
    echo "SWAT IDS - Security Web Application Toolkit - Intrusion Detection System"
    echo "Author: Tiago Natel de Moura AKA i4k"
    echo "License: Apache"
    echo
    echo "This simple IDS is part of the S.W.A.T. Toolkit"
    echo
    echo -e "Usage:\t$0 <options>"
    echo -e "\t$0 -w <clean-workspace> -o <tmp-workspace> -d <dir-under-fire>"
    echo -e "\t\t-p <project-name> -e <email-report>"
    echo -e "\t\t-x <exclude-directories> -n"
    echo
    echo "************************************************************"
    echo "* Options"
    echo -e "* -w\tWorkspace where store project directories"
    echo -e "* -d\tDirectory that need monitoring for attacks"
    echo -e "* -p\tName of the project, this is used for restore a session existent"
    echo -e "* -e\tEmail to report incidents"
    echo -e "* -x\tComma-separated list of directories excluded of analysis"
    echo -e "* -n\tNew project"
    echo -e "* -t\tIterative mode. This option will ignore all the command-line options and will ask for the configuration iteratively"
    echo -e "*"
    echo -e "************************************************************"
    exit 0    
}

while getopts ":w:d:p:e:x:nh" opt; 
do
    case $opt in
	w)
	    WORKSPACE_DIR="$OPTARG"
            if [ "x$WORKSPACE_DIR" = "x" -o ! -d "$WORKSPACE_DIR" ];
            then
                echo "-w option invalid, $WORKSPACE_DIR is not a directory or permission denied to stat it"
                exit 1
            fi
	    ;;
	d)
	    FIRE_DIR="$OPTARG"
	    ;;
	n)
	    NEW_PROJECT="true"
	    ;;
	p)
	    PROJECT_NAME="$OPTARG"
	    ;;
	e)
	    EMAIL_REPORT="$OPTARG"
	    ;;
	x)
	    EXCLUDE_DIR="$OPTARG"
	    ;;
        t)
            INTERACTIVE="true"
            ;;
	h)
	    show_help
	    ;;
	\?)
	    echo "Invalid option: -$OPTARG" >&2
	    exit 1
	    ;;
	:)
	    echo "Option -$OPTARG requires an argument." >&2
	    exit 1
      ;;
    esac
done

shift $(($OPTIND - 1))

main

function main
{
    if [ -z "$PROJECT_NAME" -o -z "$FIRE_DIR" ];
    then
        if [ "x$ITERATIVE" = "x" ];
        then
            ids_setup_iterative
        else
            echo "[-] -d <dir-under-fire> and -p <project-name> are required options."
            echo "[!] Or you could use -i for configure in interactive mode."
            aborting 1
        fi
    fi

    PROJECT_DIR="$WORKSPACE_DIR/$PROJECT_NAME"

    if [ "x$NEW_PROJECT" = "x" ];
    then
        create_new_project
    fi
}

function create_new_project
{
    becho "[+] Creating new project.\n"
    # Checking if the project already exists
    if [ -d "$PROJECT_DIR" ];
    then
        becho "[-] Directory $PROJECT_DIR already exists.\n"
        if [ "x$INTERACTIVE" = "xtrue" ];
        then
            echo "What you want to do? [choice below]"
            echo "[d] Delete this project and create new project."
            echo "[r] Start $SOFTWARE_NAME with this project configuration."
            OPT=""
            while [ "x$OPT" = "x" ];
            do
                read -p "type (d/r): " OPT
                if [ ! "x$OPT" = "xd" -o ! "$xOPT" = "xr" ];
                then
                    OPT=""
                fi
            done

            if [ "x$OPT" = "xd" -a "xPROJECT_DIR"];
            then
                becho "[DANGER] This operation is very dangerous!!!\n"
                becho "[DANGER] The directory '$PROJECT_DIR' will be DELETED permanetly"
                OPT="n"
                read -p "Confirm ? (y/n)" OPT
                if [ "x$OPT" = "xy" -o "x$OPT" = "xY" ];
                then
                    echo "[+] removing the directory $PROJECT_DIR and its subfolders"
                # THIS IS REALLY SAFE??? I GUESS ...
                    rm -rf "$PROJECT_DIR"
                else
                    echo "[-] aborting"
                    exit 0
                fi
            elif [ "x$OPT" = "xr" ];
            then
                echo "[+] Using configurations in $PROJECT_DIR to start $SOFTWARE_NAME"
                echo "[+] Checking if is a valid project directory. Wait a minute..."
                check_project_files
                is_valid=$?
                if [ $is_valid -eq 1 ];
                then
                    echo "[-] Directory $PROJECT_DIR is not a valid project."
                    echo "[-] Aborting..."
                    aborting 0
                else
                    echo "[+] Using $PROJECT_DIR as project configuration"
                fi
            fi
        fi
    else
        local WORKSPACE=`dirname "$PROJECT_DIR"`
        # workspace exists ?
        if [ ! -d "$WORKSPACE" ];
        then
            becho "[-] [$WORKSPACE][DIRECTORY NOT FOUND]\n"
            echo "aborting..."
            aborting 1
        fi

        # is writable ?
        if [ ! -w "$WORKSPACE" ];
        then
            becho "[-][$WORKSPACE][NOT WRITABLE]\n"
            echo "[!] The workspace is not a directory writable by `whoami`"
            echo "[!] Possible solution: $ chown `whoami`.`whoami` $WORKSPACE"
            echo "aborting..."
            aborting $1
        fi

        mkdir "$PROJECT_DIR"
        if [ $? -ne 0 ];
        then
            becho "[-] Failed to create directory '$PROJECT_DIR'"
            becho "[!] check permissions..."
            aborting 1
        fi
        cd "$PROJECT_DIR"

        # creating default project directories
        for dir in $(seq 0 $((${#DEFAULT_PROJECT_DIRS[@]} - 1)));
        do
            mkdir "$dir"
        done

        # creating user file configuration
        touch "$PROJECT_NAME".conf
        if [ $? -ne 0 ];
        then
            becho "[-] Failed to create file '$PROJECT_DIR/$PROJECT_NAME.conf'"
            becho "[!] check permissions..."
            aborting 1
        fi
        
    fi
        
}

    PROJECT_DIR="$WORKSPACE_DIR/$PROJECT_NAME"



    if [ "x$FIRE_DIR" = "x" ];
    then
        FIRE_DIR=`it_fire_dir`
    fi
    
    CURRENT_CLEAN_FILE="$WORKSPACE_DIR/$PROJECT_NAME.cksum"
    echo -n "generating new database for directory "
    becho "$FIRE_DIR\n"
    echo -n "Saving result in "
    becho "$CURRENT_CLEAN_FILE\n"
    generate_cksum_database "$FIRE_DIR" "$CURRENT_CLEAN_FILE"
    if [ ! "x$EXCLUDE_DIR" = "x" ];
    then
	OLD_IFS="$IFS"
	export IFS=","
	for x_dir in $EXCLUDE_DIR;
	do
	    exclude_dir_from_file "$CURRENT_CLEAN_FILE" "$x_dir"
	done
	export IFS="$OLD_IFS"
    fi
fi

if [ "x$FIRE_DIR" = "x" ];
then
    echo "Please, provide a directory to monitor in command line. Use -d <dir>"
    exit 1
fi

if [ "x$EMAIL_REPORT" = "x" ];
then
    echo "Please, provide a email to reports. Use -e <email>"
    exit 1;
fi

echo "Entering monitor mode..."

while true;
do
    CUR_DATE=`date +%Y-%m-%d-%H.%M.%S`
    CUR_FILE="$TEMP_DIR/$PROJECT_NAME-$CUR_DATE.cksum"
    generate_cksum_database "$FIRE_DIR" "$CUR_FILE"
    if [ ! "x$EXCLUDE_DIR" = "$EXCLUDE_DIR" ];
    then
	OLD_IFS="$IFS"
	export IFS=","
	for x_dir in $EXCLUDE_DIR;
	do
	    exclude_dir_from_file "$CUR_FILE" "$x_dir"
	done
	export IFS="$OLD_IFS"
    fi

    cksum_all_cur=`md5sum "$CUR_FILE" | cut -d' ' -f1`
    cksum_all_clean=`md5sum "$CURRENT_CLEAN_FILE" | cut -d' ' -f1`

    CUR_FILE_BK="$CUR_FILE.bk"
    cp "$CUR_FILE" "$CUR_FILE.bk"
    
    if [ ! "x$cksum_all_cur" = "x$cksum_all_clean" ];
    then
	echo ""
	cecho "We have enemies? " $red true
	becho "It is extremely important that you review the log below!!!"
	echo "Files modified in the directory \"$FIRE_DIR\":"
	echo "processing..."
	echo "___________________________________________________"
	REPORT=""
	while read -r cksum_cur file_cur;
	do
	    file_in_clean=`cat "$CURRENT_CLEAN_FILE" | grep "$file_cur\$" | head -1`
	    
	    cksum_clean=""
#	    echo "verifying $file_in_clean"
	    if [ ! "x$file_in_clean" = "x" ];
	    then
		cksum_clean=`echo "$file_in_clean" | cut -d' ' -f1`
		file_clean=`echo "$file_in_clean" | cut -d' ' -f3`
#		echo "cksum_clean=$cksum_clean"
#		echo "file_clean=$file_clean"
		if [ ! "x$cksum_clean" = "x$cksum_cur" ];
		then
#		    cecho "file_clean: $file_clean - $cksum_clean != $cksum_cur" $red "true"
		    REPORT=`echo -e -n "$REPORT$file_clean modified.\n"`
		fi
	    else
		REPORT=`echo -e -n "$REPORT$file_cur added!!!\n"`
	    fi
	done < "$CUR_FILE"
	echo "$REPORT"
	echo
	echo "sending this log to your email: $EMAIL_REPORT"
	echo -e "Your project $PROJECT_NAME have files modified in the directory \"$FIRE_DIR\".\nWe strongly recommend that you check the archives below, they may have been modified by an intruder. \n\n$REPORT" | mail -t "$EMAIL_REPORT" -a "FROM: isdis@secplus.com.br" -s "[WARNING] i4k Simple Intrusion Detection System"
	mv "$CURRENT_CLEAN_FILE" "$CURRENT_CLEAN_FILE.1"
	sleep 3
	cp "$CUR_FILE_BK" "$CURRENT_CLEAN_FILE"
    fi

    echo -n "."
    sleep 5
done
