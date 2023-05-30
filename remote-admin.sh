#!/bin/bash
app_name="Remote Admin"
script_name="remote_admin.sh"
app_ver="1.0"
config_file="remote-admin.conf"
config_path="./"
sshconfig_file="$HOME/.ssh/config"
search_dir=(*)

# Load or Create a standard config file
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
        )

        printf "%s\n" "${config_lines[@]}" > "$config_file"
        # shellcheck source=/dev/null
        source "${config_path}${config_file}"
    fi
}

# Assign colors for easier to read output
function assign_colors() {
    if [ "$cmd_color_output" = "false" ]; then
        echo "Command color false"
        color_output=false
    else
        color_output=true
    fi

    if [ "$color_output" = "true" ]; then
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

# Display Help if an invalid argument or -h is used
function display_help() {
    local option_padding=25

    printf "%b%s %bv%s %b- Arguments and Examples\n" "${light_red}" "${app_name}" "${light_blue}" "${app_ver}" "${default}"
    printf "%b------------------------------------------\n\n" "${dark_gray}"

    printf "${light_cyan}Usage: ${light_green}%s ${light_blue}[options]\n\n${default}" "${script_name}"
    printf "${light_red}NOTE: ${light_magenta}Options are optional, if no options are used, %s\n" "${app_name}"
    printf "%bwill ask any qualifing questions to attempt the action you choose.\n\n" "${light_magenta}"
    printf "%bOptions:%b\n" "${light_cyan}" "${default}"
    printf "${light_blue}  -h${default}"
    printf "%*s${light_gray}Display help${default}\n" $((option_padding - 2))
    printf "${light_blue}  -H <hostname>${default}"
    printf "%*s${light_gray}Set the hostname${default}\n" $((option_padding - 13))
    printf "${light_blue}  --hostfile <file>${default}"
    printf "%*s${light_gray}Load hosts from a file${default}\n" $((option_padding - 17))
    printf "${light_blue}  -u, --user <username>${default}"
    printf "%*s${light_gray}Set the username${default}\n" $((option_padding - 21))
    printf "${light_blue}  -i, --identity <keyfile>${default}"
    printf "%*s${light_gray}Set the SSH key identity${default}\n" $((option_padding - 24))
    printf "${light_blue}  -c=<true|false>${default}"
    printf "%*s${light_gray}Set color output (default: ${light_blue}true${light_gray})${default}\n" $((option_padding - 15))

    exit 0
}

# Allow the user to build a config file with specified answers
function rebuild_config() {
    echo "Rebuild Config file with answered questions"
    
    exit 0
}

# Check and Open ${HOME}/.ssh/config file and display a list, 
# if nothing exists, then prompt for a hostname.
function getHost {
    if [ -e "$sshconfig_file" ]; then
        declare -a host_options=()

        while IFS= read -r line; do
            # Check if the line starts with "Host "
            if [[ $line == Host* ]]; then
                # Extract the hostname from the line
                host_options+=("${line#Host }")
            fi
        done < "$sshconfig_file"

        host_options+=("Type in Hostname")

        select_option "${host_options[@]}"
        host_choice=$?
        last_index=$(( ${#host_options[@]} - 1 ))  # Get the last index

        echo $last_index

        case $host_choice in
            "$last_index" )
                printf "Type a %bFQDN%b or %bFQHN%b to perform an action with\n" "${light_yellow}" "${default}" "${light_yellow}" "${default}"
                printf "%b═══════════════════════════════════════════════════════════════════════════════%b\n\n" "${dark_gray}" "${default}"

                read -p "Enter the host name: " custom_option
                hostname="$custom_option"
                return
                ;;
            *)
                # Handle selected option
                printf "%b%s%b was selected\n" "${light_yellow}" "${host_options[$host_choice]}" "${default}"
                printf "%b═══════════════════════════════════════════════════════════════════════════════%b\n\n" "${dark_gray}" "${default}"
                hostname="${host_options[$host_choice]}"
                return
                ;;
        esac
    else
        printf "Type a %bFQDN%b or %bFQHN%b to perform an action with\n" "${light_yellow}" "${default}" "${light_yellow}" "${default}"
        printf "%b═══════════════════════════════════════════════════════════════════════════════%b\n\n" "${dark_gray}" "${default}"

        read -p "Enter the host name: " custom_option
        hostname="$custom_option"
        return
    fi
}

# Get the list of files in the directory, and display them
# in a list.
function getHostFile {
    select_option "${search_dir[@]}"
    file_choice=$?

    # Read each line from the file and add it to the array
    while IFS= read -r line; do
        host_array+=("$line")
    done < "${search_dir[$file_choice]}"

    return
}

# Get the user from the config file, and ask if it needs to
# change
function getUser {
    # The user is specified in the config file, use it
    echo "Get User"
    return
}

# Get the identity from the config file, if it is empty, ask
# if they want to use on, else ask if they want to use the
# identity in the config file
function getIdentity {
    # The identity is specified in the config file, use it
    echo "Get Identity"
    return
}

# Have user select what action to perform if it wasn't specified
# in the arguments
function getAction {
    # Does hostname have a value, if not then host_array should
    if [ "${hostname}" = "" ]; then
        host_count=${#host_array[@]}

        display_host="${host_count} host"
        if [[ $host_count -ne 1 ]]; then
            display_host+="s"
        fi
        display_host+=" in ${search_dir[$file_choice]}"
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
    )

    printf "What action would you like to perform on %b%s%b\n" "${light_yellow}" "${display_host}" "${default}"
    printf "%b════════════════════════════════════════════════════════════════════════════════════════════════════════%b\n\n" "${dark_gray}" "${default}"

    select_option "${action_options[@]}"
    action_choice=$?

    case "$action_choice" in
        0)
            # Shell to host
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
                        echo "ssh ${ssh_identity}${username}@${hostname}"
                    else
                        echo "Unable to reach ${hostname}"
                    fi
                done
            fi
            ;;
        1)
            # Copy SSH Key
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
                        echo "ssh ${ssh_identity}${username}@${hostname}"
                    else
                        echo "Unable to reach ${hostname}"
                    fi
                done
            fi
            ;;
        2)
            # Check Security Updates
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
                        echo "ssh ${ssh_identity}${username}@${hostname}"
                    else
                        echo "Unable to reach ${hostname}"
                    fi
                done
            fi
            ;;
        3)
            # Refresh Subscription Manager
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
                        echo "ssh ${ssh_identity}${username}@${hostname}"
                    else
                        echo "Unable to reach ${hostname}"
                    fi
                done
            fi
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
                        echo "ssh ${ssh_identity}${username}@${hostname}"
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
                        echo "ssh ${ssh_identity}${username}@${hostname}"
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
                        echo "ssh ${ssh_identity}${username}@${hostname}"
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
                        echo "ssh ${ssh_identity}${username}@${hostname}"
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
                        echo "ssh ${ssh_identity}${username}@${hostname}"
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
                        echo "ssh ${ssh_identity}${username}@${hostname}"
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
                        echo "ssh ${ssh_identity}${username}@${hostname}"
                    else
                        echo "Unable to reach ${hostname}"
                    fi
                done
            fi
            ;;
        *)
            echo "Index ${action_choice} is ${action_options[$action_choice]} to $display_host"
            ;;
    esac
}

# Renders a text based list of options that can be selected by the
# user using up, down and enter keys and returns the chosen option.
function select_option {
    ESC=$( printf "\033")
    cursor_blink_on()  { printf "%b" "\033[?25h"; }
    cursor_blink_off() { printf "%b" "\033[?25l"; }
    cursor_to()        { printf "%b" "\033[$1;${2:-1}H"; }
    print_option()     { printf "%b" "   $1 "; }
    print_selected()   { printf "%b" "  \033[7m $1 $ESC[27m"; }
    get_cursor_row()   { IFS=';' read -sdR -r -p $'\E[6n' ROW COL; echo "${ROW#*[}"; }
    key_input()        { read -s -r -n3 key 2>/dev/null >&2
                         if [[ $key = $ESC[A ]]; then echo up;    fi
                         if [[ $key = $ESC[B ]]; then echo down;  fi
                         if [[ $key = ""     ]]; then echo enter; fi; }

    # initially print empty new lines (scroll down if at bottom of screen)
    for opt; do printf "\n"; done

    # determine current screen position for overwriting the options
    local lastrow=$(get_cursor_row)
    local startrow=$(($lastrow - $#))

    # ensure cursor and input echoing back on upon a ctrl+c during read -s
    trap "cursor_blink_on; stty echo; printf '\n'; exit" 2
    cursor_blink_off

    local selected=0
    while true; do
        # print options by overwriting the last lines
        local idx=0
        for opt; do
            cursor_to $(($startrow + $idx))
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
    cursor_to $lastrow
    printf "\n"
    cursor_blink_on

    return $selected
}

clear
if [[ $# -eq 0 ]]; then
    config
    assign_colors

    printf "A %bhost%b or %bhost file%b was not specified, choose if you want to select a specific host, or a multiple hosts\n" "${light_yellow}" "${default}" "${light_yellow}" "${default}"
    printf "%b════════════════════════════════════════════════════════════════════════════════════════════════════════%b\n\n" "${dark_gray}" "${default}"
    host_type=("Single Host" "Multiple Hosts with a file")
    select_option "${host_type[@]}"
    host_type_choice=$?

    case "$host_type_choice" in
        0)
            getHost
            ;;
        1)
            getHostFile
            ;;
        *)
            echo "Invalid Choice"
            ;;
    esac

    clear
    getUser
    clear
    getIdentity
    clear
    getAction
else
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

    config
    assign_colors

    [ "$help" = "true" ] && display_help
    [ "$configure" = "true" ] && rebuild_config

    # TODO: Need to check for hostfile if it was used.

    # Was Host or Host File specified, if not lets ask?
    if [ "$hostname" = "" ]; then
        printf "A %bhost%b or %bhost file%b was not specified, choose if you want to select a specific host, or a multiple hosts\n" "${light_yellow}" "${default}" "${light_yellow}" "${default}"
        printf "%b════════════════════════════════════════════════════════════════════════════════════════════════════════%b\n\n" "${dark_gray}" "${default}"
        host_type=("Single Host" "Multiple Hosts with a file")
        select_option "${host_type[@]}"
        host_type_choice=$?

        case "$host_type_choice" in
            0)
                getHost
                ;;
            1)
                getHostFile
                ;;
            *)
                echo "Invalid Choice"
                ;;
        esac
    fi

    # Was an action specified?
    if [ "$action" = "" ]; then
        getAction
    fi

    # A config file exists, don't need these questions
        # Was a User specified?
        # Was an Identity specified?
fi