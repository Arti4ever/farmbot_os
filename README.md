<!-- DON'T CHANGE THE TEXT BELOW. It is used in documentation links. -->
# :floppy_disk: Latest OS Image Downloads
<!-- DON'T CHANGE THE TEXT ABOVE. It is used in documentation links. -->

Download the version of FarmBot OS that corresponds to the FarmBot kit and computer you have:

| FarmBot Kit  | Computer | Download Link |
| --- | --- | --- |
| Genesis v1.2, Genesis v1.3, Genesis v1.4, Genesis XL v1.4 | Raspberry Pi 3 | [Download FBOS](https://github.com/FarmBot/farmbot_os/releases/download/v9.0.3/farmbot-rpi3-9.0.3.img) |
| Express v1.0, Express XL v1.0 | Raspberry Pi Zero W | Coming soon |

---

## Build status
| Master Build Status  | Staging Build Status |
| :---: | :---: |
| [![Master Build Status](https://circleci.com/gh/FarmBot/farmbot_os/tree/master.svg?style=svg)](https://circleci.com/gh/FarmBot/farmbot_os/tree/master) | [![Staging Build Status](https://circleci.com/gh/FarmBot/farmbot_os/tree/staging.svg?style=svg)](https://circleci.com/gh/FarmBot/farmbot_os/tree/staging) |

---

## Installation
Installation should be fairly straight forward, you will need a computer for this step.
(everything after this can be set up on a mobile device.)

### Windows users

 1. download and install [Etcher](https://etcher.io/).
 0. download the [latest release](#floppy_disk-latest-os-image-downloads).
 0. insert an SD Card into your PC.
 0. open Etcher, and select the `.img` file you just downloaded.
 0. select your SD Card.
 0. Burn.

### Linux/OSX

 1. download the [latest release file, available for download here](#floppy_disk-latest-os-image-downloads).
 0. ```dd if=</path/to/file> of=/dev/<sddevice> bs=4``` or use [Etcher](https://etcher.io/).

---

## Running
_Refer to the [software documentation Configurator page](https://software.farm.bot/docs/configurator) for more detailed instructions._

 1. Plug your SD Card into your Raspberry Pi
 0. Plug your Arduino into your Raspberry Pi
 0. Plug your power into your Raspberry Pi
 0. From a WiFi enabled device*, search for the SSID `farmbot-XXXX`
 0. Connect to that and open a web browser to [http://192.168.24.1/](http://192.168.24.1)
 0. Follow the on screen instructions to configure your FarmBot. Once you save your configuration FarmBot will connect to your home WiFi network and to the FarmBot web application.

\* If you are using a smartphone you may need to disable cellular data to allow your phone's browser to connect to the configurator.

## Problems?

See the [FAQ](docs/target_development/target_faq.md)
If your problem isn't solved there please file an issue on [Github](https://github.com/FarmBot/farmbot_os/issues/new)

## Security Concerns?

We take security seriously and value the input of independent researchers. Please see our [responsible disclosure guidelines](https://farm.bot/responsible-disclosure-of-security-vulnerabilities/).

## Want to Help?

[Low Hanging Fruit](https://github.com/FarmBot/farmbot_os/search?utf8=%E2%9C%93&q=TODO)
[Development](CONTRIBUTING.md)
