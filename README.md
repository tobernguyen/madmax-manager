# MadMax Plotter Manager
Lightweight manager (zero dependencies) for [MadMax Plotter](https://github.com/madMAx43v3r/chia-plotter).

**Note: project is currently in alpha stage and still under active development.**

## Features
- Support multiple destination directories
- Auto calculate the number of plots for each destination directory
- Auto clear all tmp dirs before plotting
- Auto restart on plotter crash
- Tested on Ubuntu but should work on other Linux OS (please submit an issue if it doesn't work for you)

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
- [ ] Support MacOS and Windows
- [ ] One step installation script
- [ ] Push notifications on events
- [ ] Logs analyzer
