from __future__ import annotations

from dataclasses import dataclass
from typing import Any

import usb.core
import usb.util
from PySide6.QtCore import (
    Property,
    QAbstractListModel,
    QModelIndex,
    QObject,
    Qt,
    QTimer,
    Signal,
    Slot,
)
from serial.tools import list_ports


@dataclass(frozen=True)
class DeviceRecord:
    """Normalized device payload exposed to QML."""

    device_type: str
    name: str
    description: str
    manufacturer: str
    vid: str
    pid: str
    path: str
    hardware_id: str
    status: str
    icon: str


class DeviceListModel(QAbstractListModel):
    """List model for devices shown in QML views."""

    DeviceTypeRole = Qt.ItemDataRole.UserRole + 1
    NameRole = Qt.ItemDataRole.UserRole + 2
    DescriptionRole = Qt.ItemDataRole.UserRole + 3
    ManufacturerRole = Qt.ItemDataRole.UserRole + 4
    VidRole = Qt.ItemDataRole.UserRole + 5
    PidRole = Qt.ItemDataRole.UserRole + 6
    PathRole = Qt.ItemDataRole.UserRole + 7
    HardwareIdRole = Qt.ItemDataRole.UserRole + 8
    StatusRole = Qt.ItemDataRole.UserRole + 9
    IconRole = Qt.ItemDataRole.UserRole + 10

    def __init__(self, parent: QObject | None = None) -> None:
        super().__init__(parent)
        self._devices: list[DeviceRecord] = []

    def rowCount(self, parent: QModelIndex = QModelIndex()) -> int:  # noqa: N802
        if parent.isValid():
            return 0
        return len(self._devices)

    def data(self, index: QModelIndex, role: int = Qt.ItemDataRole.DisplayRole) -> Any:
        if not index.isValid():
            return None

        row = index.row()
        if row < 0 or row >= len(self._devices):
            return None

        device = self._devices[row]
        role_map = {
            self.DeviceTypeRole: device.device_type,
            self.NameRole: device.name,
            self.DescriptionRole: device.description,
            self.ManufacturerRole: device.manufacturer,
            self.VidRole: device.vid,
            self.PidRole: device.pid,
            self.PathRole: device.path,
            self.HardwareIdRole: device.hardware_id,
            self.StatusRole: device.status,
            self.IconRole: device.icon,
        }
        return role_map.get(role)

    def roleNames(self) -> dict[int, bytes]:  # noqa: N802
        return {
            self.DeviceTypeRole: b'deviceType',
            self.NameRole: b'name',
            self.DescriptionRole: b'description',
            self.ManufacturerRole: b'manufacturer',
            self.VidRole: b'vid',
            self.PidRole: b'pid',
            self.PathRole: b'path',
            self.HardwareIdRole: b'hardwareId',
            self.StatusRole: b'status',
            self.IconRole: b'icon',
        }

    def set_devices(self, devices: list[DeviceRecord]) -> None:
        """Reset model with a refreshed list."""
        self.beginResetModel()
        self._devices = devices
        self.endResetModel()


class DeviceManager(QObject):
    """Coordinates hardware scanning, filtering, and selection state."""

    modelChanged = Signal()
    selectedIndexChanged = Signal()
    selectedDeviceChanged = Signal()
    filterTypeChanged = Signal()
    searchTextChanged = Signal()
    lastErrorChanged = Signal()

    def __init__(self, parent: QObject | None = None) -> None:
        super().__init__(parent)
        self._model = DeviceListModel(self)
        self._all_devices: list[DeviceRecord] = []
        self._selected_index = -1
        self._selected_key = ''
        self._filter_type = 'all'
        self._search_text = ''
        self._last_error = ''

        self._refresh_timer = QTimer(self)
        self._refresh_timer.setInterval(3000)
        self._refresh_timer.timeout.connect(self.refresh_devices)

        self.refresh_devices()
        self._refresh_timer.start()

    @Property(QObject, notify=modelChanged)
    def model(self) -> QObject:
        return self._model

    @Property(int, notify=selectedIndexChanged)
    def selectedIndex(self) -> int:  # noqa: N802
        return self._selected_index

    @selectedIndex.setter
    def selectedIndex(self, value: int) -> None:  # noqa: N802
        if value == self._selected_index:
            return
        self._selected_index = value
        self.selectedIndexChanged.emit()
        self._sync_selected_key()
        self.selectedDeviceChanged.emit()

    @Property(str, notify=filterTypeChanged)
    def filterType(self) -> str:  # noqa: N802
        return self._filter_type

    @filterType.setter
    def filterType(self, value: str) -> None:  # noqa: N802
        normalized = value.lower().strip()
        if normalized not in {'all', 'usb', 'com'}:
            normalized = 'all'
        if normalized == self._filter_type:
            return
        self._filter_type = normalized
        self.filterTypeChanged.emit()
        self._apply_filters()

    @Property(str, notify=searchTextChanged)
    def searchText(self) -> str:  # noqa: N802
        return self._search_text

    @searchText.setter
    def searchText(self, value: str) -> None:  # noqa: N802
        new_value = value.strip()
        if new_value == self._search_text:
            return
        self._search_text = new_value
        self.searchTextChanged.emit()
        self._apply_filters()

    @Property(str, notify=lastErrorChanged)
    def lastError(self) -> str:  # noqa: N802
        return self._last_error

    @Property('QVariantMap', notify=selectedDeviceChanged)
    def selectedDevice(self) -> dict[str, str]:  # noqa: N802
        if self._selected_index < 0:
            return {}

        index = self._model.index(self._selected_index, 0)
        if not index.isValid():
            return {}

        return {
            'deviceType': self._model.data(index, DeviceListModel.DeviceTypeRole) or '',
            'name': self._model.data(index, DeviceListModel.NameRole) or '',
            'description': self._model.data(index, DeviceListModel.DescriptionRole) or '',
            'manufacturer': self._model.data(index, DeviceListModel.ManufacturerRole) or '',
            'vid': self._model.data(index, DeviceListModel.VidRole) or '',
            'pid': self._model.data(index, DeviceListModel.PidRole) or '',
            'path': self._model.data(index, DeviceListModel.PathRole) or '',
            'hardwareId': self._model.data(index, DeviceListModel.HardwareIdRole) or '',
            'status': self._model.data(index, DeviceListModel.StatusRole) or '',
            'icon': self._model.data(index, DeviceListModel.IconRole) or '',
        }

    @Slot()
    def refresh_devices(self) -> None:
        """Re-scan all devices and update model."""
        usb_devices, usb_error = self._scan_usb_devices()
        com_devices = self._scan_serial_ports()

        self._all_devices = sorted(
            usb_devices + com_devices,
            key=lambda item: (item.device_type, item.name.lower(), item.path.lower()),
        )

        self._set_error(usb_error)
        self._apply_filters()

    @Slot(int)
    def selectIndex(self, index: int) -> None:  # noqa: N802
        self.selectedIndex = index

    @Slot(str)
    def setFilterType(self, value: str) -> None:  # noqa: N802
        self.filterType = value

    @Slot(str)
    def setSearchText(self, value: str) -> None:  # noqa: N802
        self.searchText = value

    def _apply_filters(self) -> None:
        filtered = self._all_devices

        if self._filter_type != 'all':
            filtered = [item for item in filtered if item.device_type == self._filter_type]

        if self._search_text:
            needle = self._search_text.lower()
            filtered = [
                item
                for item in filtered
                if needle in item.name.lower()
                or needle in item.description.lower()
                or needle in item.path.lower()
                or needle in item.hardware_id.lower()
            ]

        self._model.set_devices(filtered)
        self._restore_selection()
        self.selectedDeviceChanged.emit()

    def _sync_selected_key(self) -> None:
        if self._selected_index < 0:
            self._selected_key = ''
            return

        index = self._model.index(self._selected_index, 0)
        if not index.isValid():
            self._selected_key = ''
            return

        key_parts = [
            self._model.data(index, DeviceListModel.DeviceTypeRole) or '',
            self._model.data(index, DeviceListModel.PathRole) or '',
            self._model.data(index, DeviceListModel.VidRole) or '',
            self._model.data(index, DeviceListModel.PidRole) or '',
            self._model.data(index, DeviceListModel.HardwareIdRole) or '',
        ]
        self._selected_key = '|'.join(key_parts)

    def _restore_selection(self) -> None:
        restored_index = -1
        if self._selected_key:
            for row in range(self._model.rowCount()):
                index = self._model.index(row, 0)
                key_parts = [
                    self._model.data(index, DeviceListModel.DeviceTypeRole) or '',
                    self._model.data(index, DeviceListModel.PathRole) or '',
                    self._model.data(index, DeviceListModel.VidRole) or '',
                    self._model.data(index, DeviceListModel.PidRole) or '',
                    self._model.data(index, DeviceListModel.HardwareIdRole) or '',
                ]
                if '|'.join(key_parts) == self._selected_key:
                    restored_index = row
                    break

        if restored_index < 0 and self._model.rowCount() > 0:
            restored_index = 0

        if restored_index != self._selected_index:
            self._selected_index = restored_index
            self.selectedIndexChanged.emit()

        self._sync_selected_key()

    def _set_error(self, message: str) -> None:
        if message == self._last_error:
            return
        self._last_error = message
        self.lastErrorChanged.emit()

    def _scan_serial_ports(self) -> list[DeviceRecord]:
        devices: list[DeviceRecord] = []
        for port in list_ports.comports():
            devices.append(
                DeviceRecord(
                    device_type='com',
                    name=port.device,
                    description=port.description or 'Serial Port',
                    manufacturer=port.manufacturer or 'Unknown',
                    vid=f'0x{port.vid:04X}' if port.vid is not None else '-',
                    pid=f'0x{port.pid:04X}' if port.pid is not None else '-',
                    path=port.device,
                    hardware_id=port.hwid or '-',
                    status='Connected',
                    icon='serial',
                )
            )
        return devices

    def _scan_usb_devices(self) -> tuple[list[DeviceRecord], str]:
        devices: list[DeviceRecord] = []
        error = ''
        try:
            for dev in usb.core.find(find_all=True):
                vid = getattr(dev, 'idVendor', None)
                pid = getattr(dev, 'idProduct', None)
                bus = getattr(dev, 'bus', None)
                address = getattr(dev, 'address', None)

                if bus is not None and address is not None:
                    path = f'bus {bus} address {address}'
                else:
                    path = 'USB device'

                product_name = self._safe_usb_string(dev, 'product')
                manufacturer = self._safe_usb_string(dev, 'manufacturer')
                serial_number = self._safe_usb_string(dev, 'serialNumber')

                if product_name:
                    name = product_name
                elif vid is not None and pid is not None:
                    name = f'USB Device {vid:04X}:{pid:04X}'
                else:
                    name = 'USB Device'

                description_parts: list[str] = []
                if manufacturer:
                    description_parts.append(manufacturer)
                if product_name and product_name != name:
                    description_parts.append(product_name)
                if serial_number:
                    description_parts.append(f'SN: {serial_number}')

                if not description_parts and vid is not None and pid is not None:
                    description_parts.append(f'VID:PID {vid:04X}:{pid:04X}')

                description = ' | '.join(description_parts) if description_parts else 'USB Device'

                devices.append(
                    DeviceRecord(
                        device_type='usb',
                        name=name,
                        description=description,
                        manufacturer=manufacturer or 'Unknown',
                        vid=f'0x{vid:04X}' if vid is not None else '-',
                        pid=f'0x{pid:04X}' if pid is not None else '-',
                        path=path,
                        hardware_id='-',
                        status='Connected',
                        icon='usb',
                    )
                )
        except usb.core.USBError as exc:
            error = f'USB access error: {exc}'
        except Exception as exc:  # noqa: BLE001
            error = f'USB scan error: {exc}'

        return devices, error

    @staticmethod
    def _safe_usb_string(device: Any, attr_name: str) -> str:
        """Read optional descriptor strings without breaking scan flow."""
        index = getattr(device, f'i{attr_name.capitalize()}', None)
        if not index:
            return ''

        try:
            value = usb.util.get_string(device, index)
            return value or ''
        except Exception:  # noqa: BLE001
            return ''
