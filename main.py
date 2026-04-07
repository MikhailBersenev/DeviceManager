import os
import sys
from pathlib import Path

from PySide6.QtCore import QUrl
from PySide6.QtGui import QGuiApplication, QIcon
from PySide6.QtQml import QQmlApplicationEngine

from src.devicemanager.device_manager import DeviceManager


def main() -> int:
    """Application entry point."""
    os.environ.setdefault('QT_QUICK_CONTROLS_STYLE', 'Fusion')

    app = QGuiApplication(sys.argv)
    app.setApplicationName('DeviceManager')
    icon_path = Path(__file__).resolve().parent / 'assets' / 'app_icon.svg'
    if icon_path.exists():
        app.setWindowIcon(QIcon(str(icon_path)))

    engine = QQmlApplicationEngine()
    device_manager = DeviceManager()

    engine.rootContext().setContextProperty('deviceManager', device_manager)
    qml_file = Path(__file__).resolve().parent / 'qml' / 'Main.qml'
    engine.load(QUrl.fromLocalFile(str(qml_file)))

    if not engine.rootObjects():
        return -1

    return app.exec()


if __name__ == '__main__':
    raise SystemExit(main())
