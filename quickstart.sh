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


echo -e "> checking for docker binary"
which docker > /dev/null
if [ $? -eq 1 ]
then
    echo -e ">   ${RED}not installed${RESET}"
    echo -e "error: Docker is needed, please install it before running this script: https://docs.docker.com/engine/install/"
    exit 1
else
    echo -e ">   ${GREEN}ok${RESET}"
fi

echo -e "> checking for netcat binary"
which nc > /dev/null
if [ $? -eq 1 ]
then
    echo -e ">   ${RED}not installed${RESET}"
    echo -e "error: Netcat is needed, please install it before running this script"
    exit 1
else
    echo -e ">   ${GREEN}ok${RESET}"
fi

echo -e "> raspi64 architecture?"
architecture=""
if [ "`uname -m`" = "aarch64" ]
then
    echo -e ">   yes"
    architecture="_raspi64"
else
    echo -e ">   no"
fi

echo -e "> creating openav Docker network"
docker swarm init 2>/dev/null
docker network create -d overlay --attachable openav 2>/dev/null

echo -e "> do you want to:"
echo -e "    1. load a simple OpenAV stack with small config to interact with a PJLink projector"
echo -e "    2. load all possible OpenAV microservices to talk with all supported AV devices"
echo -e "         this will take a few more minutes to retrieve and instantiate everything, but you'll have the whole array device make & models supported by OpenAV available"
echo -e "    3. pick and choose which microservices to load"

read_input_with_choices "1" "2" "3"

echo -e "> microservices"
microservices="microservice-biamp-tesira-dsp microservice-crestron-dm-switcher microservice-global-cache microservice-kramer-switcher microservice-nec-display microservice-pjlink microservice-qsc-core-dsp microservice-roku microservice-rs232-extron microservice-shure-dsp microservice-sony-fpd microservice-visca-ip microservice-zoom-room-cli"
if [ "$selection" == "1" ]
then
    microservices="microservice-pjlink"
elif [ "$selection" == "3" ]
then
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
    docker stop $microservice > /dev/null 2>&1
    docker rm $microservice > /dev/null 2>&1
    docker pull ghcr.io/dartmouth-openav/$microservice:production$architecture > /dev/null 2>&1
    docker run -tdi --restart unless-stopped --network openav --network-alias $microservice --name $microservice `docker inspect --format '{{ index .Config.Labels "CONTAINER_LAUNCH_EXTRA_PARAMETERS"}}' ghcr.io/dartmouth-openav/$microservice:production$architecture` ghcr.io/dartmouth-openav/$microservice:production$architecture > /dev/null 2>&1
    i=$((i+1))
done
echo -e ""


if [ "$selection" == "1" ]
then
    echo "> what is the IP or FQDN of the projector you want to interact with?"
    read projector
    if ! nc -z -w 3 -G 3 $projector 4352 2>/dev/null
    then
        echo -e ">   ${RED}unreachable${RESET}"
        echo -e "I couldn't open a socket to $projector on tcp:4352. Might be routing, might be firewalling, impossible to tell from here. Maybe the PJLink protocol is disabled in the settings? Please make sure that the network you are on allows you to talk to this projector and try again."
        exit 1
    else
        echo -e ">   ${GREEN}ok${RESET}"
    fi

    projectorcreds=""
    echo "> is PJlink configured with a password on this projector?"
    read_input_with_choices "y" "n"
    if [ "$selection" == "y" ]
    then
        echo "> please input that password"
        read projectorcreds
        projectorcreds=":$projectorcreds@"
    fi

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
    cat << EOF > ~/"OpenAV_system_configurations/test_123.json"
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
            "input_1": {
              "icon": "usb-c",
              "name": "Input 1",
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
            },
            "input_2": {
              "icon": "hdmi",
              "name": "Input 2",
              "value": {
                "set": [
                  {
                    "headers": [
                      "content-type: application/json"
                    ],
                    "driver": "dartmouth-openav/microservice-pjlink:current/$projectorcreds$projector/videoroute/1",
                    "method": "PUT",
                    "body": "2"
                  }
                ],
                "get": [
                  "dartmouth-openav/microservice-pjlink:current/$projectorcreds$projector/videoroute/1"
                ],
                "get_process": [
                  "2"
                ],
                "set_process": ""
              }
            },
            "input_3": {
              "icon": "laptop",
              "name": "Input 3",
              "value": {
                "set": [
                  {
                    "headers": [
                      "content-type: application/json"
                    ],
                    "driver": "dartmouth-openav/microservice-pjlink:current/$projectorcreds$projector/videoroute/1",
                    "method": "PUT",
                    "body": "3"
                  }
                ],
                "get": [
                  "dartmouth-openav/microservice-pjlink:current/$projectorcreds$projector/videoroute/1"
                ],
                "get_process": [
                  "3"
                ],
                "set_process": ""
              }
            }
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
    system_configs_folder=~/"OpenAV_system_configurations"
else
    echo -e "> please enter the folder containing system configurations: (in MacOS you can drag & drop a folder on the terminal)"
    read system_configs_folder
    while [ ! -d $system_configs_folder ]
    do
        echo -e ">   error: ${system_configs_folder} doesn't exist or isn't a valid directory"
        read system_configs_folder
    done
fi

echo -e "> instantiating orchestrator"
docker stop orchestrator > /dev/null 2>&1
docker rm orchestrator > /dev/null 2>&1
docker pull ghcr.io/dartmouth-openav/orchestrator:production$architecture > /dev/null 2>&1
echo -e ">   finding available port"
for orchestrator_port in $(seq 81 65535)
do
    echo -e ">     $orchestrator_port"
    if ! nc -z -w 3 -G 3 localhost $orchestrator_port 2>/dev/null
    then
        break
    fi
done
docker run -tdi \
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
docker exec -ti orchestrator sh -c 'echo \* > /authorization.json'

echo -e "> instantiating UI"
docker stop frontend-web > /dev/null 2>&1
docker rm frontend-web > /dev/null 2>&1
docker pull ghcr.io/dartmouth-openav/frontend-web:production$architecture > /dev/null 2>&1
echo -e ">   finding available port"
for ui_port in $(seq 80 65535)
do
    echo -e ">     $ui_port"
    if ! nc -z -w 3 -G 3 localhost $ui_port 2>/dev/null
    then
        break
    fi
done
docker run -tdi \
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

echo "> orchestrator available at: http://localhost:$orchestrator_port"
echo "> UI available at: http://localhost$ui_port_if_not_80?system=test_123"