## Welcome to Dartmouth OpenAV👋

OpenAV is an open source audiovisual control system developed at [Dartmouth College](https://www.dartmouth.edu). The project began in 2019 and features a graphical touch interface for managing AV equipment in classrooms, conference rooms, and huddle spaces. The system supports a wide range of AV components, including projectors, flat panel displays, video switchers, projection screens, DSPs, microphones, speakers, and cameras. Integrated Zoom Rooms provide seamless video conferencing, while additional solutions include Lecture Capture for room recording and a conference room scheduler for displaying room availability.  We recently implemented and are deploying end to end system testing that fully automatically exercises each system thoroughly, synthesizing/recording/recognizing audio, recognizing april tags on displays, and joining Zoom meetings.  Passing these tests confirms that virtually all system functions are working properly: display and screen control, audio, speech and sound synthesis, microphones, cameras, display capture, and Zoom.

<img width="500" alt="OpenAV control panel" src="https://github.com/user-attachments/assets/bfc03b68-80a9-4c74-82af-48ef70b29515" />

Taking an IT-driven approach to AV, OpenAV uses **JSON** configuration files to manage system setups. Each component is a **Docker** image, and they talk to each other via **REST APIs**. Communication with AV devices is handled via TCP/IP, and control interfaces are built with standard HTML, CSS, and JavaScript. Whenever possible, Ethernet is utilized for control and power (PoE). The project also includes a web-based dashboard for system monitoring.

Dartmouth has over 200 OpenAV systems in production and that number is growing by over 20 per year.  We have over 3,000 devices in those systems.  We update software on all the systems four times a year, and we can update controls for any given system by simply changing its configuration file in GitHub.  Our oldest systems are just as up to date as our newest, and we will never need to replace a whole system again.  We can maintain/enhance/service systems ourselves (turned a simple lab into a venue just by adding DSP, microphones, Zoom Room and configuration changes - no need to remove or change any other devices).  Reliability has been excellent, and when we get a rare component failure, it's easy to replace just that component.  Downtime has been minimal, in part because can quickly fix things ourselves at opportunitistic times when rooms are available.  Users enjoy the easy-to-learn and consistent-across-all-systems controls.  

Other institutions are starting to leverage and contribute to OpenAV, and we welcome more collaborators!

For lots more information, check out our [wiki](https://github.com/Dartmouth-OpenAV/.github/wiki).

## Quickstart

[quickstart.sh](https://raw.githubusercontent.com/Dartmouth-OpenAV/.github/refs/heads/main/quickstart.sh)

This script instantiates OpenAV stack on your laptop, cloud server, Raspberry Pi or other. You'll need a terminal, Bash, and [Docker](https://docs.docker.com/engine/install/). It was tested on MacOS and a Raspberry Pi 4B.

Instantiate the script with: `bash <(curl -s https://raw.githubusercontent.com/Dartmouth-OpenAV/.github/refs/heads/main/quickstart.sh)`, keep in mind that running scripts straight from a remote source can be insecure.

If you download the script to run manually, make sure you launch it within a bash shell. Either with `chmod u+x quickstart.sh && ./quickstart.sh` or with `bash quickstart.sh`.

You can interact with it using the default UI it loads, or via the orchestrator's [collection of web requests](https://raw.githubusercontent.com/Dartmouth-OpenAV/orchestrator/refs/heads/main/orchestrator.collection.json) (with apps like Insomnia or Postman).
