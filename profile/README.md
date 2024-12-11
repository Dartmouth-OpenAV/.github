## Welcome to Dartmouth OpenAV👋

OpenAV is an audiovisual control system developed at [Dartmouth College](https://www.dartmouth.edu). The project began in 2019 and features a graphical touch interface for managing AV equipment in classrooms, conference rooms, and huddle spaces. The system supports a wide range of AV components, including projectors, flat panel displays, video switchers, projection screens, DSPs, microphones, speakers, and cameras. Integrated Zoom Rooms provide seamless video conferencing, while additional solutions include Lecture Capture for room recording and a conference room scheduler for displaying room availability.

Taking an IT-driven approach to AV, OpenAV uses **JSON** configuration files to manage system setups. Each component is a **Docker** image, and they talk to each other via **REST APIs**. O  Communication with AV devices is handled via TCP/IP, and control interfaces are built with standard HTML, CSS, and JavaScript. Whenever possible, Ethernet is utilized for control and power (PoE). The project also includes a web-based dashboard for system monitoring.

## Quickstart

Here's a script that can instantiate an OpenAV stack on your laptop, cloud server, Raspberry Pi or other. [Docker](https://docs.docker.com/engine/install/) is required to run it as OpenAV relies heavily on it.

