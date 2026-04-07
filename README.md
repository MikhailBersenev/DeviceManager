# DeviceManager

Modern desktop app for monitoring USB devices and serial (COM) ports using Python, PySide6, and QML.

Copyright (C) Mikhail Bersenev, 2026. Licensed under GPL.

## Features

- Continuous device discovery with periodic refresh
- Unified list of USB devices and serial ports
- Search and type filter (All / USB / COM)
- Detailed side panel for selected device
- Dark modern UI with smooth transitions
- Error reporting for permission or backend issues

## Tech Stack

- Python 3.10+
- PySide6 (Qt for Python)
- Qt Quick / QML
- pyserial (`serial.tools.list_ports`)
- pyusb (`usb.core`)

## Project Structure

- `main.py` - app bootstrap and QML wiring
- `src/devicemanager/device_manager.py` - model, scanning, filtering, refresh timer
- `src/devicemanager/__init__.py` - package init
- `qml/Main.qml` - root UI
- `qml/components/TopBar.qml` - title and refresh controls
- `qml/components/DeviceListPanel.qml` - search, filters, list view
- `qml/components/DeviceDetailsPanel.qml` - selected device details
- `requirements.txt` - Python dependencies

## Install

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## Run

```bash
python main.py
```

## Notes

- USB device details may require extra permissions on Linux.
- If USB access is restricted, the app still shows serial ports and reports USB read errors in the UI.
