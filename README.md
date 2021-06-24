# MadMax's Chia Plotter Manager
Lightweight manager (zero dependencies) for [madMAx43v3r/chia-plotter](https://github.com/madMAx43v3r/chia-plotter). Support both Linux (Ubuntu, CentOS, etc.) and Unix (macOS).

**Note: project is currently in alpha stage and still under active development.**

## Features
- Support multiple destination directories
- Auto calculate the number of plots for each destination directory
- Auto clear all tmp dirs before plotting
- Auto restart on plotter crash
- Tested on Ubuntu and macOS but should work on all Linux Distros as well (please submit an issue if it doesn't work for you)

## Usage
Clone the repository
```bash
git clone https://github.com/tobernguyen/madmax-manager.git
cd madmax-manager
```

Copy the `[config.init.example](./config.ini.example)` to `config.ini`
```bash
cp config.ini.example config.ini
```

Modify the `config.ini` to your need then run the manager
```bash
./plot.sh
```

## TODO
- [ ] Run the manager in the background
- [ ] More manager controls: stop, kill jobs, pause/resume jobs
- [ ] Auto start on system startup (systemd for Ubuntu)
- [ ] Support Windows
- [ ] One step installation script
- [ ] Push notifications on events
- [ ] Logs analyzer
