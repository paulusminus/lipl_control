import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:logging/logging.dart';

final liplDisplayServiceUuid =
    Guid.fromString('27a70fc8-dc38-40c7-80bc-359462e4b808');

/// Uuid identifying the text characteristic on the gatt peripheral
final characteristicTextUuid =
    Guid.fromString("04973569-c039-4ce9-ad96-861589a74f9e");

/// Uuid identifying the status characteristic on the gatt peripheral
final characteristicStatusUuid =
    Guid.fromString("61a8cb7f-d4c1-49b7-a3cf-f2c69dbb7aeb");

/// Uuid identifying the command characteristic on the gatt peripheral
final characteristicCommandUuid =
    Guid.fromString("da35e0b2-7864-49e5-aa47-8050d1cc1484");

class ConnectedDevice extends Equatable {
  const ConnectedDevice({
    required this.device,
    required this.textCharacteristic,
    required this.statusCharacteristic,
    required this.commandCharacteristic,
  });
  final BluetoothDevice device;
  final BluetoothCharacteristic textCharacteristic;
  final BluetoothCharacteristic statusCharacteristic;
  final BluetoothCharacteristic commandCharacteristic;

  @override
  List<Object?> get props =>
      [device, textCharacteristic, statusCharacteristic, commandCharacteristic];
}

class ScanState extends Equatable {
  const ScanState(
      {required this.scanResults,
      required this.isScanning,
      required this.connectedDevice});
  final List<ScanResult> scanResults;
  final ConnectedDevice? connectedDevice;
  final bool isScanning;

  factory ScanState.initial() => ScanState(
        scanResults: const [],
        isScanning: FlutterBluePlus.isScanningNow,
        connectedDevice: null,
      );

  ScanState copyWith({
    List<ScanResult>? scanResults,
    bool? isScanning,
    ConnectedDevice? Function()? connectedDevice,
  }) =>
      ScanState(
        scanResults: scanResults ?? this.scanResults,
        isScanning: isScanning ?? this.isScanning,
        connectedDevice:
            connectedDevice == null ? this.connectedDevice : connectedDevice(),
      );

  @override
  List<Object?> get props => [scanResults, isScanning, connectedDevice];
}

class ScanResultsCubit extends Cubit<ScanState> {
  ScanResultsCubit({required this.logger}) : super(ScanState.initial()) {
    FlutterBluePlus.isScanning.listen(
      (isScanning) {
        emit(state.copyWith(isScanning: isScanning));
      },
    );
    _streamSubscription = FlutterBluePlus.scanResults.listen(
      (scanResults) {
        emit(state.copyWith(scanResults: scanResults));
      },
      onError: (error) {
        addError(error);
      },
    );
  }

  final Logger logger;
  StreamSubscription<List<ScanResult>>? _streamSubscription;

  Future<void> start() async {
    emit(state.copyWith(isScanning: true));
    await FlutterBluePlus.startScan(withKeywords: ['lipl']);
    emit(state.copyWith(isScanning: false));
  }

  Future<void> writeText(String text) async {
    await state.connectedDevice?.textCharacteristic
        .write(text.codeUnits, withoutResponse: true);
  }

  Future<void> writeStatus(String text) async {
    await state.connectedDevice?.statusCharacteristic
        .write(text.codeUnits, withoutResponse: true);
  }

  Future<void> writeCommand(String text) async {
    await state.connectedDevice?.commandCharacteristic
        .write(text.codeUnits, withoutResponse: true);
  }

  Future<void> connect(BluetoothDevice device) async {
    try {
      await disconnect();
      await device.connect();
      await device.discoverServices();
      logger.info('Service list ${device.servicesList}');
      final service = device.servicesList
          .where((e) => e.serviceUuid == liplDisplayServiceUuid)
          .where(
            (element) => element.isPrimary,
          )
          .firstOrNull;
      final textCharacteristic = service?.characteristics
          .where((characteristic) =>
              characteristic.characteristicUuid == characteristicTextUuid)
          .firstOrNull;
      final statusCharacteristic = service?.characteristics
          .where((characteristic) =>
              characteristic.characteristicUuid == characteristicStatusUuid)
          .firstOrNull;
      final commandCharacteristic = service?.characteristics
          .where((characteristic) =>
              characteristic.characteristicUuid == characteristicCommandUuid)
          .firstOrNull;
      logger.info("Found dislay service");

      if (service != null &&
          textCharacteristic != null &&
          statusCharacteristic != null &&
          commandCharacteristic != null) {
        final connectedDevice = ConnectedDevice(
          device: device,
          textCharacteristic: textCharacteristic,
          statusCharacteristic: statusCharacteristic,
          commandCharacteristic: commandCharacteristic,
        );
        emit(state.copyWith(connectedDevice: () => connectedDevice));
      }
    } catch (error) {
      addError(error);
    }
  }

  Future<void> disconnect() async {
    try {
      await state.connectedDevice?.device.disconnect();
      emit(state.copyWith(connectedDevice: () => null));
    } catch (error) {
      addError(error);
    }
  }

  Future<void> stop() async {
    await FlutterBluePlus.stopScan();
    emit(state.copyWith(isScanning: false));
  }

  @override
  Future<void> close() async {
    await _streamSubscription?.cancel();
    await super.close();
  }
}
