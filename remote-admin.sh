#!/bin/bash
# shellcheck disable=SC2034  # Unused variables left for readability
# shellcheck disable=SC2162  # Backslashes are used for ESC characters
# shellcheck disable=SC2181  # mycmd #? is used for return value of ping

app_name="Remote Admin"
script_name="remote_admin.sh"
app_ver="1.0"
config_file="remote-admin.conf"
config_path="./"
tmpfile=sshtorc-${USER}
search_dir=(*)
LINES=$( tput lines )
COLS=$( tput cols )
# Description: Open the ssh config file, look for any includes, and include each file, seperate
#              all hosts, place them into an array.
CONFILES=$(shopt -s nullglob; echo ~/.ssh/{config,config*[!~],config*[!~]/*})
# CONFILES=$(find ~/.ssh/ -type f -name 'config*')

# Function: bye
# Description: Close remote-admin and clean up any set variables left behind. Display
#              exit message.
#   TODO: Display a nice goodbye message
function bye {
    assigned_vars=(
        "app_name" "script_name" "app_ver" "config_file" "config_path" "sshconfig_file" "search_dir"
        "black" "red" "green" "yellow" "blue" "magenta" "cyan" "light_gray" "dark_gray" "light_red" 
        "light_green" "light_yellow" "light_blue" "light_magenta" "light_cyan" "white" "default"
        "config_lines" "cmd_color_output" "color_output" "option_padding" "color_selection" 
        "username_option" "username" "host_options" "host_choice" "last_index" "hostname" "line"
        "host_count" "display_host" "action_options" "counter" "port" "counter" "host_counter" "ESC"
        "key" "lastrow" "startrow" "host_type_choice" "idx" "opt"
    )

    for vars in assigned_vars[@]; do
        unset "${vars}"
    done

    exit 0
}

# Function: config
# Description: This function checks for the existence of a configuration file.
#              If the file exists, it sources it to load the configuration settings.
#              If the file does not exist, it creates a new configuration file with
#              default settings.
function config() {
    if [ -e "${config_path}${config_file}" ]; then
        # shellcheck source=/dev/null
        source "${config_path}${config_file}"
    else
        declare -a config_lines=(
            "# ${app_name} v${app_ver} automated configurations"
            "color_output=true"
            "username=${USER}"
            "identity_file=\"\""
            "port=22"
        )

        printf "%s\n" "${config_lines[@]}" > "$config_file"
        # shellcheck source=/dev/null
        source "${config_path}${config_file}"
    fi
}

# Function: assign_colors
# Description: This function assigns color codes to variables based on the value of 
#              the 'color_output' variable. The color codes are ANSI escape sequences 
#              for terminal color formatting.
function assign_colors() {
    # Check the value of 'cmd_color_output' to determine the value of 'color_output'
    if [ "$cmd_color_output" = "false" ]; then
        color_output=false
    elif [ "$cmd_color_output" = "true" ]; then
        color_output=true
    fi

    # Assign color codes to variables based on the value of 'color_output'
    if [ "$color_output" = "true" ]; then
        # Color codes for colored output
        readonly black='\033[0;30m'
        readonly red='\033[0;31m'
        readonly green='\033[0;32m'
        readonly yellow='\033[0;33m'
        readonly blue='\033[0;34m'
        readonly magenta='\033[0;35m'
        readonly cyan='\033[0;36m'
        readonly light_gray='\033[0;37m'
        readonly dark_gray='\033[1;30m'
        readonly light_red='\033[1;31m'
        readonly light_green='\033[1;32m'
        readonly light_yellow='\033[1;33m'
        readonly light_blue='\033[1;34m'
        readonly light_magenta='\033[1;35m'
        readonly light_cyan='\033[1;36m'
        readonly white='\033[1;37m'
        readonly default='\033[0m'
    else
        # Color codes for non-colored output
        readonly black='\033[0m'
        readonly red='\033[0m'
        readonly green='\033[0m'
        readonly yellow='\033[0m'
        readonly blue='\033[0m'
        readonly magenta='\033[0m'
        readonly cyan='\033[0m'
        readonly light_gray='\033[0m'
        readonly dark_gray='\033[0m'
        readonly light_red='\033[0m'
        readonly light_green='\033[0m'
        readonly light_yellow='\033[0m'
        readonly light_blue='\033[0m'
        readonly light_magenta='\033[0m'
        readonly light_cyan='\033[0m'
        readonly white='\033[0m'
        readonly default='\033[0m'
    fi
}


pause() {
    read -rp "Press Enter to continue..."
}

# Function: select_file
# Description: This function allows the user to select a file from the list of files
#              in the current directory
#   TODO: Need to have the ability to traverse directories
#   TODO: Need the ability for the user to type in a directory and or file
function select_file() {
    # Prompt the user to select a host file
    select_option "${search_dir[@]}"
    file_choice=$?
}

# Function: copy_file
# Description: This function gathers a list of files, displays them in a list and copies
#              that file to the host.
function copy_file() {
    select_file
    cp_file_name="${search_dir[$file_choice]}"
    return
}

# Function: display_help
# Description: This function displays the help information for the script, including 
#              available options and examples.
#   TODO: Clean up, and have a nice display for the help system
function display_help() {
    # Define the padding size for option descriptions
    local option_padding=25

    # Display the application name, version, and header for arguments and examples
    printf "%b%s %bv%s %b- Arguments and Examples\n" "${light_red}" "${app_name}" "${light_blue}" "${app_ver}" "${default}"
    printf "%b------------------------------------------\n\n" "${dark_gray}"

    # Display the script usage information
    printf "${light_cyan}Usage: ${light_green}%s ${light_blue}[options]\n\n${default}" "${script_name}"
    printf "%bNOTE: %bIf no options are provided, %b%s%b will prompt the user\n" "${light_red}" "${light_magenta}" "${white}" "${app_name}" "${light_magenta}"
    printf "%bwith relevant questions to gather the necessary arguments. The options\n" "${light_magenta}"
    printf "%bserve as an alternative way to provide the required information, but\n" "${light_magenta}"
    printf "%bthey are not mandatory.\n\n" "${light_magenta}"

    # Display the available options
    printf "%bOptions:%b\n" "${light_cyan}" "${default}"
    printf "%b  -a%b" "${light_blue}" "${default}"
    printf "%*s${light_gray}Invoke action${default}\n" $((option_padding - 2))
    printf "%b  -h%b" "${light_blue}" "${default}"
    printf "%*s${light_gray}Display help${default}\n" $((option_padding - 2))
    printf "%b  -H <hostname>%b" "${light_blue}" "${default}"
    printf "%*s${light_gray}Set the hostname${default}\n" $((option_padding - 13))
    printf "%b  --hostfile <file>%b" "${light_blue}" "${default}"
    printf "%*s${light_gray}Load hosts from a file${default}\n" $((option_padding - 17))
    printf "%b  -u, --user <username>%b" "${light_blue}" "${default}"
    printf "%*s${light_gray}Set the username${default}\n" $((option_padding - 21))
    printf "%b  -i, --identity <keyfile>%b" "${light_blue}" "${default}"
    printf "%*s${light_gray}Set the SSH key identity${default}\n" $((option_padding - 24))
    printf "%b  -p%b" "${light_blue}" "${default}"
    printf "%*s${light_gray}Specify port${default}\n" $((option_padding - 2))
    printf "%b  -c=<true|false>%b" "${light_blue}" "${default}"
    printf "%*s${light_gray}Set color output (default: ${light_blue}true${light_gray})${default}\n\n" $((option_padding - 15))

    # Exit the script with a success status code
    exit 0
}

# Allow the user to build a config file with specified answers
#   TODO: Complete this function
function rebuild_config() {
    color_selection=("Yes" "No")
    printf "Would you like color output\n"
    select_option "${color_selection[@]}"
    
    read -r "Enter the user to connect to host :" username_option
    exit 0
}

# Function: select_hosts function
# Description: Prompts the user to select hostnames from the host_options array and 
#              assigns the selected hostnames to the host_array variable. # If the
#              user selects the "Type in # Hostname" option, it prompts the user to 
#              enter a custom hostname.
function select_hosts() {
    declare -A target
    colmax=5
    offset=$(( COLS / colmax ))
    idx=0
    dbg=0
    status=1

    # Add the "Type in Hostname" option to the host_options array
    multiselect result $colmax $offset host_options preselection "SELECT HOSTNAMES" 

    # display all of the choices
    for option in "${host_options[@]}"; do
        if  [[ ${result[idx]} == true ]]; then
            if [ $dbg -eq 1 ]; then
                echo -e "$option\t=> ${result[idx]}"
                pause
            fi
            target+=("${option}")
            status=0
        fi  
        ((idx++))
    done

    mapfile -t array <<< "${target}"

    if [ $status -eq 0 ] ; then
        host_array=("${target[@]}")
    else
        echo -e "$light_green No items selected... $default"
        exit 0
    fi

    return
}

# Function: type_host function
# Description: Prompts the user to type in a hostname to
function type_host() {
    # User chose the "Type in Hostname" option
    printf "Type a %bFQDN%b or %bFQHN%b to perform an action with\n" "${light_yellow}" "${default}" "${light_yellow}" "${default}"
    printf "%b═══════════════════════════════════════════════════════════════════════════════%b\n\n" "${dark_gray}" "${default}"

    read -p "Enter the host name: " custom_option
    hostname="$custom_option"
    return
}

# Function: get_host
# Description: This function checks if the ${HOME}/.ssh/config file exists and displays 
#              a list of hosts from it. If the file does not exist, it prompts the user 
#              to enter a hostname manually.
function get_host() {
    desclength=20
    declare -A hostnames

    while read -r name hostname desc; do
        case    ${name,,} in
            'group_name') name="{ $desc }"
                name_length=${#name}
                name_left=$(( (40 - name_length) / 2 ))
                name_right=$(( 40 - name_left + name_length ))
                printf -v tmp "%${name_left}s_NAME_%${name_right}s"
                tmp=${tmp// /-}  name=${tmp//_NAME_/$name}
                content+=( "$desc" );  desc='_LINE_';;
            '#'*) continue;;
        esac

        hostnames["$name"]=$hostname #Create host-hostname pairs in hostnames array
        fullist+=("$name")   #Add Host and Description to the list
    done < <(gawk '
    BEGIN{IGNORECASE=1}
    /^Host /{
        strt=1
        host=$2
        next
    }
    strt && /HostName /{
        hostname=$2
        print host, hostname, desc
        strt=0
    }' $CONFILES)

    # Assign all hosts found to a variable
    host_options=( "${fullist[@]}" )
    preselection=false
    search_dir[file_choice]="ssh config file"

    select_hosts
    return
}

# Function: get_host_file
# Description: This function prompts the user to select a host file from a list and 
#              reads the selected file. It reads each line from the file and adds it 
#              to the `host_array` array.
function get_host_file() {
    declare -A preselection
    select_file

    # Read each non-empty line from the selected file and add it to the host_options array
    while IFS= read -r line; do
        if [[ -n $line ]]; then
            host_options+=("$line")
        fi
    done < "${search_dir[$file_choice]}"
    host_count=${#host_options[@]}
    
    for ((i=0; i<host_count; i++)); do
        preselection[$i]=true
        echo $i
    done

    select_hosts
}

function line() {
    printf -v _L %$2s; printf -- "${_L// /$1}";
}

function save_tmp(){
    echo "$1" > "$tmpfile"
    chmod 600 "$tmpfile"
}

function new_list() {
    list=(); match=
    for item in "${selected_list[@]}" "${fullist[@]}"; {
        case         $item:$match    in
                 *{\ *\ }*:1) break  ;;
           *{\ $filter\ }*:*) match=1;;
        esac
        [[ $match ]] && list+=( "$item" )
    }
    [[ $filter =~ Selected ]] && return
    [[ ${list[*]} ]] && save_tmp "filter='$filter'" || { list=( "${fullist[@]}" ); rm "$tmpfile"; }
}

# Get the user from the config file, and ask if it needs to
# change
#   TODO: Complete this function
function get_user {
    # The user is specified in the config file, use it
    echo "Get User"
    return
}

# Get the identity from the config file, if it is empty, ask
# if they want to use on, else ask if they want to use the
# identity in the config file
#   TODO: Complete this function
function get_identity {
    # The identity is specified in the config file, use it
    echo "Get Identity"
    return
}

# Function: get_action
# Description: This function prompts the user to select an action to perform on the 
#              host(s) and performs the selected action.
function get_action {
    # Does hostname have a value, if not then host_array should have value
    if [ "${hostname}" = "" ]; then
        host_count=${#host_array[@]}
        display_host="${host_count} host"

        if [[ $host_count -ne 1 ]]; then
            display_host+="s"
        fi

        display_host+=" in ${search_dir[$file_choice]}"
        # host_array=("${host_options[@]}")
    else
        display_host=$hostname
    fi

    action_options=(
        "Shell" #0
        "Copy SSH Key" #1
        "Check Security Updates" #2
        "Refresh Subscription Manager" #3
        "Copy File" #4
        "Get File" #5
        "Check Memory" #6
        "Check Disk Space" #7
        "Check Load" #8
        "Reboot Host" #9
        "Shutdown Host" #10
        "Exit ${app_name}" #11
    )

    printf "%b%s%b\n" "${light_yellow}" "${display_host}" "${default}"
    printf "%b════════════════════════════════════════════════════════════════════════════════════════════════════════%b\n\n" "${dark_gray}" "${default}"

    select_option "${action_options[@]}"
    action_choice=$?

    # Build the SSH command
    if [ "${identity_file}" = "" ]; then
        ssh_identity=" "
    else
        ssh_identity="-i ${identity_file} "
    fi

    if [ "${username}" = "" ]; then
        username=${USER}
    fi

    case "$action_choice" in
        0) # Shell to host
            clear
            counter=0
            host_counter=1

            if [[ $host_count -gt 0 ]]; then
                # More than one host, loop through them
                for hostname in "${host_array[@]}"; do
                    if [ ! "${hostname}" = "" ]; then
                        # Test if the hostname is accessable
                        # ping -c 1 "${hostname}" >/dev/null 2>&1
                        # if [[ $? -eq 0 ]]; then
                            clear
                            printf "Connecting to %b%s%b using port %b%s%b and identity file %b%s%b with user %b%s%b\n" "${light_red}" "${hostname}" "${default}" "${light_cyan}" "${port}" "${default}" "${light_blue}" "${ssh_identity}" "${default}" "${white}" "${username}" "${default}"
                            printf "%b═════════════════════════════════════════════════════════════════════════════════════════════════════%b\n" "${dark_gray}" "${default}"
                            printf "%s to %b%s%b (%b%s%b of %b%s%b)\n" "${action_options[$action_choice]}" "${light_red}" "${hostname}" "${default}" "${yellow}" "${host_counter}" "${default}" "${yellow}" "${host_count}" "${default}"
                            printf "%b═════════════════════════════════════════════════════════════════════════════════════════════════════%b\n\n" "${dark_gray}" "${default}"
                            ssh -F "${sshconfig_file}" -p "${port}" "${ssh_identity}${username}@${hostname}"
                            ((host_counter++))
                        # else
                        #     printf "%bUnable to reach %b%s%b\n" "${light_red}" "${white}" "${hostname}" "${default}"
                        #     ((counter++))
                        # fi
                    fi
                done
            else
                # ping -c 1 "${hostname}" >/dev/null 2>&1
                # if [[ $? -eq 0 ]]; then      
                    clear
                    printf "Connecting to %b%s%b using port %b%s%b and identity file %b%s%b with user %b%s%b\n" "${light_red}" "${hostname}" "${default}" "${light_cyan}" "${port}" "${default}" "${light_blue}" "${ssh_identity}" "${default}" "${white}" "${username}" "${default}"
                    printf "%b═════════════════════════════════════════════════════════════════════════════════════════════════════%b\n" "${dark_gray}" "${default}"
                    printf "%s to %b%s%b (%b%s%b of %b%s%b)\n" "${action_options[$action_choice]}" "${light_red}" "${hostname}" "${default}" "${yellow}" "${host_counter}" "${default}" "${yellow}" "${host_count}" "${default}"
                    printf "%b═════════════════════════════════════════════════════════════════════════════════════════════════════%b\n\n" "${dark_gray}" "${default}"
                    ssh -F "${sshconfig_file}" -p "${port}" "${ssh_identity}${username}@${hostname}"
                # else
                #     printf "%bUnable to reach %b%s%b\n" "${light_red}" "${white}" "${hostname}" "${default}"
                #     ((counter++))
                # fi
            fi
            
            if [ ${counter} -eq 1 ]; then
                counted_hosts="host"
            else
                counted_hosts="hosts"
            fi

            printf "%b%s %b%s%b could not connect\n\n" "${light_red}" "${counter}" "${white}" "${counted_hosts}" "${default}"
            ;;
        1) # Copy SSH Key
            clear
            counter=0
            host_counter=1

            if [[ $host_count -gt 0 ]]; then
                # More than one host, loop through them
                for hostname in "${host_array[@]}"; do
                    if [ ! "${hostname}" = "" ]; then
                        # ping -c 1 "${hostname}" >/dev/null 2>&1
                        # if [[ $? -eq 0 ]]; then
                            clear
                            printf "%s to %b%s%b (%b%s%b of %b%s%b)\n" "${action_options[$action_choice]}" "${light_red}" "${hostname}" "${default}" "${yellow}" "${host_counter}" "${default}" "${yellow}" "${host_count}" "${default}"
                            printf "%b═════════════════════════════════════════════════════════════════════════════════════════════════════%b\n\n" "${dark_gray}" "${default}"
                            ssh-copy-id -o StrictHostKeychecking=no -p "${port}" "${ssh_identity}${hostname}"
                            ((host_counter++))
                        # else
                        #     printf "%bUnable to reach %b%s%b\n" "${light_red}" "${white}" "${hostname}" "${default}"
                        #     ((counter++))
                        # fi
                    fi
                done
            else
                ping -c 1 "${hostname}" >/dev/null 2>&1
                # if [[ $? -eq 0 ]]; then
                    clear
                    printf "%s to %b%s%b (%b%s%b of %b%s%b)\n" "${action_options[$action_choice]}" "${light_red}" "${hostname}" "${default}" "${yellow}" "${host_counter}" "${default}" "${yellow}" "${host_count}" "${default}"
                    printf "%b═════════════════════════════════════════════════════════════════════════════════════════════════════%b\n\n" "${dark_gray}" "${default}"
                    ssh-copy-id -o StrictHostKeychecking=no -p "${port}" "${ssh_identity}${hostname}"
                # else
                #     printf "%bUnable to reach %b%s%b\n" "${light_red}" "${white}" "${hostname}" "${default}"
                #     ((counter++)) 
                # fi
            fi
            
            if [ ${counter} -eq 1 ]; then
                counted_hosts="host"
            else
                counted_hosts="hosts"
            fi

            printf "%b%s %b%s%b could not connect\n\n" "${light_red}" "${counter}" "${white}" "${counted_hosts}" "${default}"
            ;;
        2) # Check Security Updates
            clear
            counter=0
            host_counter=1

            if [[ $host_count -gt 0 ]]; then
                # More than one host, loop through them
                for hostname in "${host_array[@]}"; do
                    if [ ! "${hostname}" = "" ]; then
                        # ping -c 1 "${hostname}" >/dev/null 2>&1
                        # if [[ $? -eq 0 ]]; then
                            clear
                            printf "%s to %b%s%b (%b%s%b of %b%s%b)\n" "${action_options[$action_choice]}" "${light_red}" "${hostname}" "${default}" "${yellow}" "${host_counter}" "${default}" "${yellow}" "${host_count}" "${default}"
                            printf "%b═════════════════════════════════════════════════════════════════════════════════════════════════════%b\n\n" "${dark_gray}" "${default}"
                            ssh -F "${sshconfig_file}" -p "${port}" "${ssh_identity}${username}@${hostname}" "sudo yum --security check-update > ${hostname}_security_check_update_$(date +"%Y-%m-%d").log"
                            scp -F "${sshconfig_file}" -P "${port}" "${ssh_identity}${username}@${hostname}:~/${hostname}_security_check_update_$(date +"%Y-%m-%d").log" ./reports/
                            ((host_counter++))
                        # else
                        #     printf "%bUnable to reach %b%s%b\n" "${light_red}" "${white}" "${hostname}" "${default}"
                        #     ((counter++))
                        # fi
                    fi
                done
            else
                ping -c 1 "${hostname}" >/dev/null 2>&1
                # if [[ $? -eq 0 ]]; then
                    clear
                    printf "%s to %b%s%b (%b%s%b of %b1%b)\n" "${action_options[$action_choice]}" "${light_red}" "${hostname}" "${default}" "${yellow}" "${host_counter}" "${default}" "${yellow}" "${default}"
                    printf "%b═════════════════════════════════════════════════════════════════════════════════════════════════════%b\n\n" "${dark_gray}" "${default}"
                    ssh -F "${sshconfig_file}" -p "${port}" "${ssh_identity}${username}@${hostname}" "sudo yum --security check-update > $(hostname -s)_security_check_update_$(date +"%Y-%m-%d").log"
                    scp -F "${sshconfig_file}" -p "${port}" "${ssh_identity}${username}@${hostname}:~/${hostname}_security_check_update_$(date +"%Y-%m-%d").log" ./reports/
                # else
                #     printf "%bUnable to reach %b%s%b\n" "${light_red}" "${white}" "${hostname}" "${default}"
                #     ((counter++))
                # fi
            fi
            
            if [ ${counter} -eq 1 ]; then
                counted_hosts="host"
            else
                counted_hosts="hosts"
            fi

            printf "%b%s %b%s%b could not connect\n\n" "${light_red}" "${counter}" "${white}" "${counted_hosts}" "${default}"
            ;;
        3) # Refresh Subscription Manager
            clear
            counter=0
            host_counter=1

            if [[ $host_count -gt 0 ]]; then
                # More than one host, loop through them
                for hostname in "${host_array[@]}"; do
                    if [ ! "${hostname}" = "" ]; then
                        # ping -c 1 "${hostname}" >/dev/null 2>&1
                        # if [[ $? -eq 0 ]]; then
                            clear
                            printf "%s to %b%s%b (%b%s%b of %b%s%b)\n" "${action_options[$action_choice]}" "${light_red}" "${hostname}" "${default}" "${yellow}" "${host_counter}" "${default}" "${yellow}" "${host_count}" "${default}"
                            printf "%b═════════════════════════════════════════════════════════════════════════════════════════════════════%b\n\n" "${dark_gray}" "${default}"
                            ssh -F ${sshconfig_file} -p ${port} ${ssh_identity}${username}@${hostname} "sudo subscription-manager refresh"
                            ((host_counter++))
                        # else
                        #     printf "%bUnable to reach %b%s%b\n" "${light_red}" "${white}" "${hostname}" "${default}"
                        #     ((counter++))
                        # fi
                    fi
                done
            else
                ping -c 1 "${hostname}" >/dev/null 2>&1
                # if [[ $? -eq 0 ]]; then
                    clear
                    printf "%s to %b%s%b (%b%s%b of %b%s%b)\n" "${action_options[$action_choice]}" "${light_red}" "${hostname}" "${default}" "${yellow}" "${host_counter}" "${default}" "${yellow}" "${host_count}" "${default}"
                    printf "%b═════════════════════════════════════════════════════════════════════════════════════════════════════%b\n\n" "${dark_gray}" "${default}"
                    ssh -F ${sshconfig_file} -p ${port} ${ssh_identity}${username}@${hostname} "sudo subscription-manager refresh"
                # else
                #     printf "%bUnable to reach %b%s%b\n" "${light_red}" "${white}" "${hostname}" "${default}"
                #     ((counter++))
                # fi
            fi

            if [ ${counter} -eq 1 ]; then
                counted_hosts="host"
            else
                counted_hosts="hosts"
            fi

            printf "%b%s %b%s%b could not connect\n\n" "${light_red}" "${counter}" "${white}" "${counted_hosts}" "${default}"
            ;;
        4)
             # Copy File
            echo "Index ${action_choice} is ${action_options[$action_choice]} to $display_host"
            if [[ $host_count -gt 1 ]]; then
                # More than one host, loop through them
                for hostname in "${host_array[@]}"; do
                    # Build the SSH command
                    if [ "${identity_file}" = "" ]; then
                        ssh_identity=" "
                    else
                        ssh_identity="-i ${identity_file}"
                    fi

                    if [ "${username}" = "" ]; then
                        username=${USER}
                    fi

                    ping -c 1 "${hostname}" >/dev/null 2>&1
                    if [[ $? -eq 0 ]]; then
                        copy_file
                        scp "${cp_file_name}" -p "${port}" "${ssh_identity}${username}@${hostname}"
                    else
                        echo "Unable to reach ${hostname}"
                    fi
                done
            fi
            ;;
        5)
            # Get File
            echo "Index ${action_choice} is ${action_options[$action_choice]} to $display_host"
            if [[ $host_count -gt 1 ]]; then
                # More than one host, loop through them
                for hostname in "${host_array[@]}"; do
                    # Build the SSH command
                    if [ "${identity_file}" = "" ]; then
                        ssh_identity=" "
                    else
                        ssh_identity="-i ${identity_file}"
                    fi

                    if [ "${username}" = "" ]; then
                        username=${USER}
                    fi

                    ping -c 1 "${hostname}" >/dev/null 2>&1
                    if [[ $? -eq 0 ]]; then      
                        echo "ssh -p ${port} ${ssh_identity}${username}@${hostname}"
                    else
                        echo "Unable to reach ${hostname}"
                    fi
                done
            fi
            ;;
        6)
            # Check Memory
            echo "Index ${action_choice} is ${action_options[$action_choice]} to $display_host"
            if [[ $host_count -gt 1 ]]; then
                # More than one host, loop through them
                for hostname in "${host_array[@]}"; do
                    # Build the SSH command
                    if [ "${identity_file}" = "" ]; then
                        ssh_identity=" "
                    else
                        ssh_identity="-i ${identity_file}"
                    fi

                    if [ "${username}" = "" ]; then
                        username=${USER}
                    fi

                    ping -c 1 "${hostname}" >/dev/null 2>&1
                    if [[ $? -eq 0 ]]; then      
                        echo "ssh -p ${port} ${ssh_identity}${username}@${hostname}"
                    else
                        echo "Unable to reach ${hostname}"
                    fi
                done
            fi
            ;;
        7)
            # Check Disk Space
            echo "Index ${action_choice} is ${action_options[$action_choice]} to $display_host"
            if [[ $host_count -gt 1 ]]; then
                # More than one host, loop through them
                for hostname in "${host_array[@]}"; do
                    # Build the SSH command
                    if [ "${identity_file}" = "" ]; then
                        ssh_identity=" "
                    else
                        ssh_identity="-i ${identity_file}"
                    fi

                    if [ "${username}" = "" ]; then
                        username=${USER}
                    fi

                    ping -c 1 "${hostname}" >/dev/null 2>&1
                    if [[ $? -eq 0 ]]; then      
                        echo "ssh -p ${port} ${ssh_identity}${username}@${hostname}"
                    else
                        echo "Unable to reach ${hostname}"
                    fi
                done
            fi
            ;;
        8)
            # Check Load
            echo "Index ${action_choice} is ${action_options[$action_choice]} to $display_host"
            if [[ $host_count -gt 1 ]]; then
                # More than one host, loop through them
                for hostname in "${host_array[@]}"; do
                    # Build the SSH command
                    if [ "${identity_file}" = "" ]; then
                        ssh_identity=" "
                    else
                        ssh_identity="-i ${identity_file}"
                    fi

                    if [ "${username}" = "" ]; then
                        username=${USER}
                    fi

                    ping -c 1 "${hostname}" >/dev/null 2>&1
                    if [[ $? -eq 0 ]]; then      
                        echo "ssh -p ${port} ${ssh_identity}${username}@${hostname}"
                    else
                        echo "Unable to reach ${hostname}"
                    fi
                done
            fi
            ;;
        9)
            # Reboot Host
            echo "Index ${action_choice} is ${action_options[$action_choice]} to $display_host"
            if [[ $host_count -gt 1 ]]; then
                # More than one host, loop through them
                for hostname in "${host_array[@]}"; do
                    # Build the SSH command
                    if [ "${identity_file}" = "" ]; then
                        ssh_identity=" "
                    else
                        ssh_identity="-i ${identity_file}"
                    fi

                    if [ "${username}" = "" ]; then
                        username=${USER}
                    fi

                    ping -c 1 "${hostname}" >/dev/null 2>&1
                    if [[ $? -eq 0 ]]; then      
                        echo "ssh -p ${port} ${ssh_identity}${username}@${hostname}"
                    else
                        echo "Unable to reach ${hostname}"
                    fi
                done
            fi
            ;;
        10)
            # Shutdown Host
            echo "Index ${action_choice} is ${action_options[$action_choice]} to $display_host"
            if [[ $host_count -gt 1 ]]; then
                # More than one host, loop through them
                for hostname in "${host_array[@]}"; do
                    # Build the SSH command
                    if [ "${identity_file}" = "" ]; then
                        ssh_identity=" "
                    else
                        ssh_identity="-i ${identity_file}"
                    fi

                    if [ "${username}" = "" ]; then
                        username=${USER}
                    fi

                    ping -c 1 "${hostname}" >/dev/null 2>&1
                    if [[ $? -eq 0 ]]; then      
                        echo "ssh -p ${port} ${ssh_identity}${username}@${hostname}"
                    else
                        echo "Unable to reach ${hostname}"
                    fi
                done
            fi
            ;;
        11) # Exit Remote Admin
            bye
            ;;
        *)
            echo "Index ${action_choice} is ${action_options[$action_choice]} to $display_host"
            ;;
    esac
}

# Function: multiselect
# Description: 
function multiselect {
    ESC=$(printf "\033")
    cursor_blink_on()   { printf "%b" "${ESC}[?25h"; }
    cursor_blink_off()  { printf "%b" "${ESC}[?25l"; }
    cursor_to()         { printf "%b" "${ESC}[$1;${2:-1}H"; }
    print_inactive()    { printf "%b   %b " "$2" "$1"; }
    print_active()      { printf "%b  %b %b %b" "$2" "${ESC}[7m" "$1" "${ESC}[27m"; }
    get_cursor_row()    { IFS=';' read -sdR -r -p $'\E[6n' ROW COL; echo "${ROW#*[}"; }
    get_cursor_col()    { IFS=';' read -sdR -r -p $'\E[6n' ROW COL; echo "${COL#*[}"; }

    local return_value=$1
    local colmax=$2
    local offset=$3
    local -n options=$4
    local -n defaults=$5
    local title=$6

    clear

    local selected=()
    for ((i=0; i<${#options[@]}; i++)); do
        if [[ ${defaults[i]} = "true" ]]; then
            selected+=("true")
        else
            selected+=("false")
        fi
        printf "\n"
    done

    cursor_to $(( LINES - 2 ))
    printf "_%.s" $(seq "$COLS")
    echo -e "${light_blue} ${title} | ${white}[space]${light_green} select | (${white}[n]${light_green})${white}[a]${light_green} (un)select all | ${white}up/down/left/right${light_green} or ${white}k/j/l/h${light_green} move" | column 

    # determine current screen position for overwriting the options
    local lastrow=$(get_cursor_row)
    local lastcol=$(get_cursor_col)
    local startrow=1
    local startcol=1

    # ensure cursor and input echoing back on upon a ctrl+c during read -s
    trap "cursor_blink_on; stty echo; printf '\n'; exit" 2
    cursor_blink_off

    key_input() {
        local key
        IFS= read -rsn1 key 2>/dev/null >&2
        if [[ $key = "" ]]; then echo enter; fi;
        if [[ $key = $'\x20' ]]; then echo space; fi;
        if [[ $key = "k" ]]; then echo up; fi;
        if [[ $key = "j" ]]; then echo down; fi;
        if [[ $key = "h" ]]; then echo left; fi;
        if [[ $key = "l" ]]; then echo right; fi;
        if [[ $key = "a" ]]; then echo all; fi;
        if [[ $key = "n" ]]; then echo none; fi;
        if [[ $key = $'\x1b' ]]; then
            read -rsn2 key
            if [[ $key = [A || $key = k ]]; then echo up;    fi;
            if [[ $key = [B || $key = j ]]; then echo down;  fi;
            if [[ $key = [C || $key = l ]]; then echo right; fi;
            if [[ $key = [D || $key = h ]]; then echo left;  fi;
        fi
    }

    toggle_option() {
        local option=$1
        if [[ ${selected[option]} == true ]]; then
            selected[option]=false
        else
            selected[option]=true
        fi
    }

    toggle_option_multicol() {
        local option_row=$1
        local option_col=$2

        if [[ $option_row -eq -10 ]] && [[ $option_row -eq -10 ]]; then
            for ((option=0; option<${#selected[@]}; option++)); do
                selected[option]=true
            done
        else
            if [[ $option_row -eq -100 ]] && [[ $option_row -eq -100 ]]; then
                for ((option=0; option<${#selected[@]}; option++)); do
                    selected[option]=false
                done
            else
                option=$(( option_col + option_row * colmax ))

                if [[ ${selected[option]} == true ]]; then
                    selected[option]=false
                else
                    selected[option]=true
                fi
            fi
        fi
    }

    print_options_multicol() {
        # print options by overwriting the last lines
        local curr_col=$1
        local curr_row=$2
        local curr_idx=0

        local idx=0
        local row=0
        local col=0

        curr_idx=$(( curr_col + curr_row * colmax ))

        for option in "${options[@]}"; do
            local prefix="${dark_gray}[ ]${default}"
            if [[ ${selected[idx]} == true ]]; then
              prefix="${light_green}[${light_green}✔${default}${light_green}]${default}"
            fi

            row=$(( idx/colmax ))
            col=$(( idx - row * colmax ))

            cursor_to $(( startrow + row + 1)) $(( offset * col + 1))
            if [ $idx -eq $curr_idx ]; then
                print_active "${option}" "${prefix}"
            else
                print_inactive "${option}" "${prefix}"
            fi
            ((idx++))
        done
    }

    local active_row=0
    local active_col=0

    while true; do
        print_options_multicol $active_col $active_row

        # user key control
        case $(key_input) in
            space)  
                    toggle_option_multicol $active_row $active_col
                    ;;
            enter)  
                    print_options_multicol -1 -1
                    break
                    ;;
            up)     
                    ((active_row--))
                    if [ $active_row -lt 0 ]; then 
                        active_row=0
                    fi;;
            down)   
                    ((active_row++))
                    if [ $active_row -ge $(( ${#options[@]} / colmax )) ]; then 
                        active_row=$(( ${#options[@]} / colmax ))
                    fi
                    ;;
            left)   
                    ((active_col=active_col - 1))
                    if [ $active_col -lt 0 ]; then 
                        active_col=0; 
                    fi
                    ;;
            right)  
                    ((active_col=active_col + 1))
                    if [ $active_col -ge "$colmax" ]; then 
                        active_col=$(( colmax - 1 ))
                    fi
                    ;;
            all)    
                    toggle_option_multicol -10 -10
                    ;;
            none)   
                    toggle_option_multicol -100 -100
                    ;;
        esac
    done

    # cursor position back to normal
    cursor_to "$lastrow"
    printf "\n"
    cursor_blink_on

    eval "$return_value"='("${selected[@]}")'
    clear
}

# Function: select_option
# Description: This function displays a menu of options and allows the user to select 
#              one option. It handles the user's key inputs and returns the index of 
#              the selected option.
function select_option {
    stty sane
    if [ -e $ESC ]; then
        local ESC=$( printf "\033")
    fi

    cursor_blink_on()  { printf "%b" "\033[?25h"; }
    cursor_blink_off() { printf "%b" "\033[?25l"; }
    cursor_to()        { printf "%b" "\033[$1;${2:-1}H"; }
    print_option()     { printf "%b" "   $1 "; }
    print_selected()   { printf "%b" "  \033[7m $1 ${ESC}[27m"; }
    get_cursor_row()   { IFS=';' read -sdR -r -p $'\E[6n' ROW COL; echo "${ROW#*[}"; }
    key_input()        { read -s -r -n3 key 2>/dev/null >&2
                         if [[ $key = ${ESC}[A ]]; then echo up;    fi
                         if [[ $key = ${ESC}[B ]]; then echo down;  fi
                         if [[ $key = ""     ]]; then echo enter; fi; }

    # initially print empty new lines (scroll down if at bottom of screen)
    for opt; do printf "\n"; done

    # determine current screen position for overwriting the options
    local lastrow=$(get_cursor_row)
    local startrow=$((lastrow - $#))

    # ensure cursor and input echoing back on upon a ctrl+c during read -s
    trap "cursor_blink_on; stty echo; printf '\n'; exit" 2
    cursor_blink_off

    local selected=0
    while true; do
        # print options by overwriting the last lines
        local idx=0
        for opt; do
            cursor_to $((startrow + idx))
            if [ $idx -eq $selected ]; then
                print_selected "$opt"
            else
                print_option "$opt"
            fi
            ((idx++))
        done

        # user key control
        case $(key_input) in
            enter) break;;
            up)    ((selected--));
                   if [ $selected -lt 0 ]; then selected=$(($# - 1)); fi;;
            down)  ((selected++));
                   if [ $selected -ge $# ]; then selected=0; fi;;
        esac
    done

    # cursor position back to normal
    cursor_to "$lastrow"
    printf "\n"
    cursor_blink_on

    return $selected
}

clear

# Check if no command-line arguments are provided
if [[ $# -eq 0 ]]; then
    # Configuration and color assignment
    config
    assign_colors

    # Prompt the user to select a host or host file
    printf "A %bhost%b or %bhost file%b was not specified, choose if you want to select a specific hosts, or a multiple hosts\n" "${light_yellow}" "${default}" "${light_yellow}" "${default}"
    printf "%b══════════════════════════════════════════════════════════════════════════════════════════=══════════════%b\n\n" "${dark_gray}" "${default}"
    host_type=("Hosts from config" "Hosts from a file" "Type in a hostname")
    select_option "${host_type[@]}"
    host_type_choice=$?

    case "$host_type_choice" in
        0)
            get_host
            ;;
        1)
            get_host_file
            ;;
        2)
            type_host
            ;;
    esac

    clear
    get_user
    clear
    get_identity
    clear
    get_action
else
    # Command-line arguments are provided
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -a=*|--action=*)
                action="${1#*=}"
                ;;
            -c=*|--color=*)
                cmd_color_output="${1#*=}"
                ;;
            -h|--help)
                help=true
                ;;
            -H|--host)
                hostname="$2"
                shift
                ;;
            -F|--hostfile)
                hostfile="$2"
                shift
                ;;
            -u|--user)
                username="$2"
                shift
                ;;
            -p|--port)
                port="$2"
                shift
                ;;
            -f|--force)
                force=true
                shift
                ;;
            -i|--identity)
                identity_file="$2"
                shift
                ;;
            --configure)
                configure=true
                ;;
            *)
                echo "Invalid option: $1"
                display_help
                ;;
        esac
        shift
    done

    # Configuration and color assignment
    config
    assign_colors

    [ "$help" = "true" ] && display_help
    [ "$configure" = "true" ] && rebuild_config

    # TODO: Need to check for hostfile if it was used.

    # Check if a host or host file is specified, if not, prompt the user to select
    if [ "$hostname" = "" ]; then
        printf "A %bhost%b or %bhost file%b was not specified, choose if you want to select a specific host, or a multiple hosts\n" "${light_yellow}" "${default}" "${light_yellow}" "${default}"
        printf "%b════════════════════════════════════════════════════════════════════════════════════════════════════════%b\n\n" "${dark_gray}" "${default}"
        host_type=("Single Host" "Multiple Hosts with a file")
        select_option "${host_type[@]}"
        host_type_choice=$?

        case "$host_type_choice" in
            0)
                get_host
                ;;
            1)
                get_host_file
                ;;
            *)
                echo "Invalid Choice"
                ;;
        esac
    fi

    # Was an action specified?
    if [ "$action" = "" ]; then
        get_action
    fi

    # A config file exists, don't need these questions
        # Was a User specified?
        # Was an Identity specified?
fi
