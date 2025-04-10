#!/bin/bash

BOLD="\033[1m"
BLACK="\033[30m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
MAGENTA="\033[35m"
CYAN="\033[36m"
WHITE="\033[37m"
RESET="\033[0m"


read_input_with_choices() {
    local choices="$@"

    echo -en "# choices ["
    for choice in $choices
    do
        echo -en "$choice,"
    done
    echo -e "\b]"

    while true
    do
        read -r selection
        if [[ " $choices " == *" $selection "* ]];
        then
            break
        else
            echo -e "${RED}invalid${RESET}"
        fi
    done
}


echo -e "   ___                      ___     __ "
echo -e "  / _ \ _ __   ___ _ __    / \ \   / / "
echo -e " | | | | '_ \ / _ \ '_ \  / _ \ \ / /  "
echo -e " | |_| | |_) |  __/ | | |/ ___ \ V /   "
echo -e "  \___/| .__/ \___|_| |_/_/   \_\_/    "
echo -e "       |_|                             "
echo -e ""

echo -e "> raspi64 architecture?"
architecture=""
if [ "`uname -m`" = "aarch64" ]
then
    echo -e ">   yes"
    architecture="_raspi64"
else
    echo -e ">   no"
fi

echo -e "> checking for docker binary"
which docker > /dev/null
if [ $? -eq 1 ]
then
    echo -e ">   ${RED}not installed${RESET}"
    if [ "$architecture" == "_raspi64" ]
    then
        echo ">      looks like we're running off a Pi, do you want to install Docker automatically?"
        read_input_with_choices "y" "n"
        if [ "$selection" == "y" ]
        then
            # instructions retrieved from: https://docs.docker.com/engine/install/debian/
            sudo DEBIAN_FRONTEND=noninteractive apt-get update -y
            sudo DEBIAN_FRONTEND=noninteractive apt-get install ca-certificates curl -y
            sudo install -m 0755 -d /etc/apt/keyrings
            sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
            sudo chmod a+r /etc/apt/keyrings/docker.asc
            echo \
              "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
              $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
              sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            sudo DEBIAN_FRONTEND=noninteractive apt-get update -y
            sudo DEBIAN_FRONTEND=noninteractive apt-get install docker-ce docker-ce-cli -y
            which docker > /dev/null
            if [ $? -eq 1 ]
            then
                echo -e "error: looks like I was unable to install Docker automatically, please install it manually before running this script: https://docs.docker.com/engine/install/"
                exit 1
            fi
        else
            echo -e "error: Docker is needed, please install it before running this script: https://docs.docker.com/engine/install/"
            exit 1
        fi
    else
        echo -e "error: Docker is needed, please install it before running this script: https://docs.docker.com/engine/install/"
        exit 1
    fi
else
    echo -e ">   ${GREEN}ok${RESET}"
fi
sudo_docker=""
if [ "$architecture" == "_raspi64" ]
then
    sudo_docker="sudo"
fi

echo -e "> checking for netcat binary"
which nc > /dev/null
if [ $? -eq 1 ]
then
    echo -e ">   ${RED}not installed${RESET}"
    echo ">      looks like we're running off a Pi, do you want to install netcat automatically?"
    read_input_with_choices "y" "n"
    if [ "$selection" == "y" ]
    then
        sudo DEBIAN_FRONTEND=noninteractive apt-get update -y
        sudo DEBIAN_FRONTEND=noninteractive apt-get install netcat-traditional -y
        which nc > /dev/null
        if [ $? -eq 1 ]
        then
            echo -e "error: looks like I was unable to install netcat automatically, please install it manually before running this script"
            exit 1
        fi
    else
        echo -e "error: netcat is needed, please install it before running this script"
        exit 1
    fi
else
    echo -e ">   ${GREEN}ok${RESET}"
fi
netcat_options=""
if [ "`uname -s`" == "Darwin" ];
then
    netcat_options = " -G 3 "
fi

echo -e "> creating openav Docker network"
$sudo_docker docker swarm init 2>/dev/null
$sudo_docker docker network create -d overlay --attachable openav 2>/dev/null

echo -e "> do you want to:"
echo -e "    (${BOLD}1${RESET}) load a simple OpenAV stack with just enough to interact with a PJLink projector"
echo -e "         use for dipping your toes into OpenAV"
echo -e "    (${BOLD}2${RESET}) load a full OpenAV stack including all possible ${MAGENTA}microservices${RESET}"
echo -e "         use if you already have configuration files defined"
echo -e "         this will take a few more minutes to retrieve and instantiate everything, but you'll have the whole array device make & models supported by OpenAV available"
echo -e "    (${BOLD}3${RESET}) load a full OpenAV stack, but pick and choose which microservices to load"
echo -e "         same as 2. but you know which ${MAGENTA}microservices${RESET} you need"

read_input_with_choices "1" "2" "3"
top_level_path_selection=$selection

microservices="microservice-biamp-tesira-dsp microservice-crestron-dm-switcher microservice-global-cache microservice-kramer-switcher microservice-nec-display microservice-pjlink microservice-qsc-core-dsp microservice-roku microservice-rs232-extron microservice-shure-dsp microservice-sony-fpd microservice-visca-ip microservice-zoom-room-cli"
if [ "$selection" == "1" ]
then
    microservices="microservice-pjlink"
elif [ "$selection" == "3" ]
then
    echo -e "> ${MAGENTA}microservices${RESET}"
    $new_microservices = ""
    for microservice in $microservices
    do
        echo -e "> load ${MAGENTA}$microservice${RESET} ?"
        read_input_with_choices "y" "n"
        if [ "$selection" == "y" ]
        then
            new_microservices="${new_microservices} ${microservice}"
        fi
    done
    microservices=$new_microservices
else
    for microservice in $microservices
    do
        echo -e "> ${MAGENTA}$microservice${RESET}"
    done
fi

echo -e "> instantiating microservices"
i=1
count=$(echo $microservices | wc -w | sed 's/ //g')
for microservice in $microservices
do
    echo -en "\033[2K\033[1G   ${i}/${count} ${MAGENTA}$microservice${RESET} ..."
    $sudo_docker docker stop $microservice > /dev/null 2>&1
    $sudo_docker docker rm $microservice > /dev/null 2>&1
    $sudo_docker docker pull ghcr.io/dartmouth-openav/$microservice:production$architecture > /dev/null 2>&1
    $sudo_docker docker run -tdi --restart unless-stopped --network openav --network-alias $microservice --name $microservice `$sudo_docker docker inspect --format '{{ index .Config.Labels "CONTAINER_LAUNCH_EXTRA_PARAMETERS"}}' ghcr.io/dartmouth-openav/$microservice:production$architecture` ghcr.io/dartmouth-openav/$microservice:production$architecture > /dev/null 2>&1
    i=$((i+1))
done
echo -e ""


echo -e "> we need a directory to store config file(s) into"
echo -e "    (${BOLD}1${RESET}) automatically create & use ~/OpenAV_system_configurations"
echo -e "    (${BOLD}2${RESET}) enter an existing directory manually"
read_input_with_choices "1" "2"
if [ "$selection" == "1" ]
then
    system_configs_folder=~/"OpenAV_system_configurations"
    if [ ! -d ~/"OpenAV_system_configurations" ]
    then
        echo -e "> creating system configuration directory ~/OpenAV_system_configurations"
        mkdir ~/"OpenAV_system_configurations"
        if [ $? -eq 1 ]
        then
            echo -e "error: couldn't create directory ~/OpenAV_system_configurations, can't proceed further"
            exit 1
        fi
    fi
elif [ "$selection" == "2" ]
then
    echo -e "> please enter the folder containing system configurations: (in MacOS you can drag & drop a folder on the terminal)"
    read system_configs_folder
    while [ ! -d $system_configs_folder ]
    do
        echo -e ">   error: ${system_configs_folder} doesn't exist or isn't a valid directory"
        read system_configs_folder
    done
fi


echo -e "> instantiating ${CYAN}orchestrator${RESET}"
$sudo_docker docker stop orchestrator > /dev/null 2>&1
$sudo_docker docker rm orchestrator > /dev/null 2>&1
$sudo_docker docker pull ghcr.io/dartmouth-openav/orchestrator:production$architecture > /dev/null 2>&1
echo -e ">   finding available port"
for orchestrator_port in $(seq 81 65535)
do
    echo -e ">     $orchestrator_port"
    if ! nc -z -w 3 $netcat_options localhost $orchestrator_port 2>/dev/null
    then
        break
    fi
done
$sudo_docker docker run -tdi \
    --restart unless-stopped \
    -p $orchestrator_port:80 \
    -e DNS_HARD_CACHE=false \
    -e SYSTEM_CONFIGURATIONS_VIA_VOLUME=true \
    -e SYSTEM_CONFIGURATIONS_INSTANT_REFRESH=true \
    -e ADDRESS_MICROSERVICES_BY_NAME=true \
    -v $system_configs_folder:/system_configurations \
    --network openav \
    --network-alias orchestrator \
    --name orchestrator \
    ghcr.io/dartmouth-openav/orchestrator:production$architecture > /dev/null 2>&1
$sudo_docker docker exec -ti orchestrator sh -c 'echo \* > /authorization.json'

echo -e "> instantiating ${BLUE}UI${RESET}"
$sudo_docker docker stop frontend-web > /dev/null 2>&1
$sudo_docker docker rm frontend-web > /dev/null 2>&1
$sudo_docker docker pull ghcr.io/dartmouth-openav/frontend-web:production$architecture > /dev/null 2>&1
echo -e ">   finding available port"
for ui_port in $(seq 80 65535)
do
    echo -e ">     $ui_port"
    if ! nc -z -w 3 $netcat_options localhost $ui_port 2>/dev/null
    then
        break
    fi
done
$sudo_docker docker run -tdi \
    --restart unless-stopped \
    -p $ui_port:80 \
    -e HOME_ORCHESTRATOR=http://localhost:$orchestrator_port \
    --network openav \
    --network-alias frontend-web \
    --name frontend-web \
    ghcr.io/dartmouth-openav/frontend-web:production$architecture > /dev/null 2>&1

ui_port_if_not_80=""
if [ "$ui_port" != "80" ]
then
    ui_port_if_not_80=":$ui_port"
fi


if [ "$top_level_path_selection" == "1" ]
then
    echo -e "> what is the IP or FQDN of the projector you want to interact with?"
    read projector
    if ! nc -z -w 3 $netcat_options $projector 4352 2>/dev/null
    then
        echo -e ">   ${RED}unreachable${RESET}"
        echo -e "I couldn't open a socket to $projector on tcp:4352. Might be routing, might be firewalling, impossible to tell from here. Maybe the PJLink protocol is disabled in the settings? Please make sure that the network you are on allows you to talk to this projector and try again."
        exit 1
    else
        echo -e ">   ${GREEN}ok${RESET}"
    fi

    projectorcreds=""
    echo -e "> is PJlink configured with a password on this projector?"
    read_input_with_choices "y" "n"
    if [ "$selection" == "y" ]
    then
        echo -e "> please input that password"
        read projectorcreds
        projectorcreds=":$projectorcreds@"
    fi    

    echo -e "> how do you want to define the projector's inputs?"
    echo -e "    (${BOLD}1${RESET}) change manually on the projector and scan resulting number"
    echo -e "    (${BOLD}2${RESET}) default to 1, 2, and 3 (not all projectors use these numbers)"
    read_input_with_choices "1" "2"

    read -r -d '' inputsection << EOF
"input_<inputcount>": {
  "icon": "<inputtype>",
  "name": "<inputnumber> <inputtype>",
  "value": {
    "set": [
      {
        "headers": [
          "content-type: application/json"
        ],
        "driver": "dartmouth-openav/microservice-pjlink:current/$projectorcreds$projector/videoroute/1",
        "method": "PUT",
        "body": "1"
      }
    ],
    "get": [
      "dartmouth-openav/microservice-pjlink:current/$projectorcreds$projector/videoroute/1"
    ],
    "get_process": [
      "1"
    ],
    "set_process": ""
  }
}
EOF

    
    cat << EOF > ~/"OpenAV_system_configurations/test_123.json.tmp"
{
  "system_name": "OpenAV Test",
  "control_sets": {
    "flat_panel": {
      "name": "TV",
      "icon": "screen",
      "controls": {
        "input_select": {
          "type": "display_source_radio",
          "channel": "main",
          "default_input": "hdmi",
          "options": {
EOF
    
    if [ "$selection" == "1" ]
    then
        want_to_define_another_input="y"
        inputcount=0
        while [ "$want_to_define_another_input" == "y" ]
        do
            inputcount=$((inputcount + 1))
            echo -e "> defining input $inputcount for projector"
            echo -e ">   please manually switch the projector to the input"
            read -p "press [enter] when done"
            echo -e "> detecting input # on projector"
            inputnumber=""
            safety_counter=0 
            while [ "$inputnumber" == "" -a $safety_counter -lt 10 ]
            do
                safety_counter=$((safety_counter + 1))
                echo -n "."
                inputnumber=`$sudo_docker docker exec -ti orchestrator bash -c 'curl -s "http://microservice-pjlink/'"$projectorcreds$projector"'/videoroute/1" | jq -r'`
                inputnumber=$(echo "$inputnumber" | tr -d '\r')
                if [ "$inputnumber" == "" ]
                then
                    sleep 1
                fi
            done
            if [ "$inputnumber" == "" ]
            then
                echo -e "error: unable to detect input number on projector, I'm not sure how to recover from this"
                exit 1
            fi
            echo -e ""
            echo -e ">   detected #$inputnumber"
            echo -e "> which type of input is this? (not functionally relevant, this is only to show the right label & icon)"
            read_input_with_choices "usb-c" "hdmi" "laptop"
            inputtype=$selection
            echo -e ">   adding to config"
            if [ $inputcount -gt 1 ]
            then
                echo -e "," >> ~/"OpenAV_system_configurations/test_123.json.tmp"
            fi
            echo -e $inputsection | sed 's/<inputnumber>/'$inputnumber'/g' | sed 's/<inputcount>/'$inputcount'/g' | sed 's/<inputtype>/'$inputtype'/g' >> ~/"OpenAV_system_configurations/test_123.json.tmp"
            echo -e "> do you want to define another input?"
            # echo -e "   (${BOLD}y${RESET})es"
            # echo -e "   (${BOLD}n${RESET})o"
            read_input_with_choices "y" "n"
            want_to_define_another_input=$selection
            echo -e "sleeping for 60 seconds before scanning projector again"
            sleep 60
        done
    elif [ "$selection" == "2" ]
    then
        echo -e $inputsection | sed 's/<inputnumber>/1/g' | sed 's/<inputcount>/1/g' | sed 's/<inputtype>/usb-c/g' >> ~/"OpenAV_system_configurations/test_123.json.tmp"
        echo -e ",$inputsection" | sed 's/<inputnumber>/2/g' | sed 's/<inputcount>/2/g' | sed 's/<inputtype>/hdmi/g' >> ~/"OpenAV_system_configurations/test_123.json.tmp"
        echo -e ",$inputsection" | sed 's/<inputnumber>/3/g' | sed 's/<inputcount>/3/g' | sed 's/<inputtype>/laptop/g' >> ~/"OpenAV_system_configurations/test_123.json.tmp"
    fi

    cat << EOF >> ~/"OpenAV_system_configurations/test_123.json.tmp"
          }
        },
        "pause": {
            "type": "video_mute",
            "channel": "screen_center",
            "value": {
                "set": [
                    {
                        "driver": "dartmouth-openav/microservice-pjlink:current/$projectorcreds$projector/audioandvideomute/1",
                        "method": "PUT",
                        "body": "\"\$on_or_off\"",
                        "headers": [
                            "content-type: application/json"
                        ]
                    }
                ],
                "set_process": {
                    "true": {
                        "on_or_off": "on"
                    },
                    "false": {
                        "on_or_off": "off"
                    }
                },
                "get": [
                    "dartmouth-openav/microservice-pjlink:current/$projectorcreds$projector/audioandvideomute/1"
                ],
                "get_process": [
                    "on"
                ]
            }
        },
        "power": {
          "type": "power",
          "name": "Power",
          "warmup_timer": 20,
          "channel": "main",
          "value": {
            "set": [
              {
                "driver": "dartmouth-openav/microservice-pjlink:current/$projectorcreds$projector/power",
                "method": "PUT",
                "body": "\"\$on_or_off\"",
                "headers": [
                  "content-type: application/json"
                ]
              }
            ],
            "set_process": {
              "true": {
                "on_or_off": "on"
              },
              "false": {
                "on_or_off": "off"
              }
            },
            "get": [
              "dartmouth-openav/microservice-pjlink:current/$projectorcreds$projector/power"
            ],
            "get_process": [
              "on"
            ]
          }
        }
      }
    },
    "audio": {
      "name": "Sound",
      "icon": "speaker",
      "display_options" : {
        "half_width" : true
      },
      "controls": {
        "mute": {
          "type": "mute",
          "channel": "audio",
          "value": {
            "set": [
              {
                "driver": "dartmouth-openav/microservice-pjlink:current/$projectorcreds$projector/audiomute/1",
                "method": "PUT",
                "body": "\"\$PROGRAM_MUTE\"",
                "headers": [
                  "content-type: application/json"
                ]
              }
            ],
            "set_process": {
              "true": {
                "PROGRAM_MUTE": "true"
              },
              "false": {
                "PROGRAM_MUTE": "false"
              }
            },
            "get": [
              "dartmouth-openav/microservice-pjlink:current/$projectorcreds$projector/audiomute/1"
            ],
            "get_process": [
              "true"
            ]
          }
        },
        "stateless_volume": {
            "type": "stateless_volume",
            "channel": "program",
            "value": {
                "set": [
                    {
                        "driver": "microservice-pjlink:current/$projectorcreds$projector/volume",
                        "method": "PUT",
                        "body": "\"\$up_or_down\"",
                        "headers": [
                            "content-type: application/json"
                        ]
                    }
                ],
                "set_process": {
                    "up": {
                        "up_or_down": "up"
                    },
                    "down": {
                        "up_or_down": "down"
                    }
                },
                "get": [],
                "get_process": ""
            }
        }
      }
    }
  }
}
EOF

mv ~/"OpenAV_system_configurations/test_123.json.tmp" ~/"OpenAV_system_configurations/test_123.json"
fi

echo -e "> ${CYAN}orchestrator${RESET} available at: http://localhost:$orchestrator_port"
echo -e "> ${BLUE}UI${RESET} available at: http://localhost$ui_port_if_not_80?system=test_123"
