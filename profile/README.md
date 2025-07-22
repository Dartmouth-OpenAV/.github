## Welcome to Dartmouth OpenAV👋

OpenAV is an open source audiovisual control system developed at [Dartmouth College](https://www.dartmouth.edu). The project began in 2019 and features a graphical touch interface for managing AV equipment in classrooms, conference rooms, and huddle spaces. The system supports a wide range of AV components, including projectors, flat panel displays, video switchers, projection screens, DSPs, microphones, speakers, and cameras. Integrated Zoom Rooms provide seamless video conferencing, while additional solutions include Lecture Capture for room recording and a conference room scheduler for displaying room availability.

Taking an IT-driven approach to AV, OpenAV uses **JSON** configuration files to manage system setups. Each component is a **Docker** image, and they talk to each other via **REST APIs**. Communication with AV devices is handled via TCP/IP, and control interfaces are built with standard HTML, CSS, and JavaScript. Whenever possible, Ethernet is utilized for control and power (PoE). The project also includes a web-based dashboard for system monitoring.

For more information, check out our [wiki](https://github.com/Dartmouth-OpenAV/.github/wiki).

## Quickstart

[quickstart.sh](https://raw.githubusercontent.com/Dartmouth-OpenAV/.github/refs/heads/main/quickstart.sh)

This script instantiates OpenAV stack on your laptop, cloud server, Raspberry Pi or other. You'll need a terminal, Bash, and [Docker](https://docs.docker.com/engine/install/). It was tested on MacOS and a Raspberry Pi 4B.

Instantiate the script with: `bash <(curl -s https://raw.githubusercontent.com/Dartmouth-OpenAV/.github/refs/heads/main/quickstart.sh)`, keep in mind that running scripts straight from a remote source can be insecure.

If you download the script to run manually, make sure you launch it within a bash shell. Either with `chmod u+x quickstart.sh && ./quickstart.sh` or with `bash quickstart.sh`.

You can interact with it using the default UI it loads, or via the orchestrator's [collection of web requests](https://raw.githubusercontent.com/Dartmouth-OpenAV/orchestrator/refs/heads/main/orchestrator.collection.json) (with apps like Insomnia or Postman).
