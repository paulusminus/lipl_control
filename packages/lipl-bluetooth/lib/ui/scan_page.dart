import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lipl_bluetooth/lipl_bluetooth.dart';

class ScanPage extends StatelessWidget {
  const ScanPage({
    super.key,
  });

  static Route<void> route() => MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => const ScanPage(),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ScaffoldMessenger(
      child:
          BlocBuilder<ScanResultsCubit, ScanState>(builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: Text(l10n?.bluetoothTitle ?? 'TV Connections')),
          body: Column(
            children: [
              if (state.isConnected())
                Column(
                  children: [
                    Text(
                      l10n?.bluetoothActiveConnection ?? 'Now connected to',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    ListTile(
                      title: Text(
                          '${l10n?.connectTo} ${state.connectedDevice!.device.remoteId} / ${state.connectedDevice!.device.advName}  '),
                      trailing: IconButton(
                        icon: const Icon(Icons.tv_off),
                        onPressed: () {
                          context.read<ScanResultsCubit>().disconnect();
                        },
                      ),
                    ),
                  ],
                ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      l10n?.bluetoothPossibleConnections ??
                          'Possible connections',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    ListView(
                      children: state.scanResults
                          .where((scanResult) =>
                              scanResult.device !=
                              state.connectedDevice?.device)
                          .map(
                            (scanResult) => ListTile(
                              title: Text(scanResult.advertisementData.advName),
                              trailing: IconButton(
                                icon: const Icon(Icons.connected_tv),
                                onPressed: () async {
                                  await context
                                      .read<ScanResultsCubit>()
                                      .connect(scanResult.device);
                                },
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            child:
                Icon(state.isScanning ? Icons.stop : Icons.bluetooth_searching),
            onPressed: () async {
              state.isScanning
                  ? await context.read<ScanResultsCubit>().stopScanning()
                  : await context.read<ScanResultsCubit>().startScanning();
            },
          ),
        );
      }),
    );
  }
}
