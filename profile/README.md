## Welcome to Dartmouth OpenAV👋

OpenAV is an audiovisual control system developed at [Dartmouth College](https://www.dartmouth.edu). The project began in 2019 and features a graphical touch interface for managing AV equipment in classrooms, conference rooms, and huddle spaces. The system supports a wide range of AV components, including projectors, flat panel displays, video switchers, projection screens, DSPs, microphones, speakers, and cameras. Integrated Zoom Rooms provide seamless video conferencing, while additional solutions include Lecture Capture for room recording and a conference room scheduler for displaying room availability.

Taking an IT-driven approach to AV, OpenAV uses **JSON** configuration files to manage system setups. Each component is a **Docker** image, and they talk to each other via **REST APIs**. O  Communication with AV devices is handled via TCP/IP, and control interfaces are built with standard HTML, CSS, and JavaScript. Whenever possible, Ethernet is utilized for control and power (PoE). The project also includes a web-based dashboard for system monitoring.

## Quickstart

Here's a script to instantiate an quick OpenAV stack on your laptop, cloud server, Raspberry Pi or other. You'll need a terminal, Bash, and Docker [Docker](https://docs.docker.com/engine/install/).

[quickstart.sh](https://raw.githubusercontent.com/Dartmouth-OpenAV/.github/refs/heads/main/quickstart.sh)

For the moment, it does not load a User Interface to interact with, it stops at the [Orchestrator](https://github.com/Dartmouth-OpenAV/orchestrator), and so you would interact with it using its [collection of web requests](https://raw.githubusercontent.com/Dartmouth-OpenAV/orchestrator/refs/heads/main/orchestrator.collection.json) (with apps like Insomnia or PostMan).
