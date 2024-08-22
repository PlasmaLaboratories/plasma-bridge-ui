import 'package:apparatus_wallet/features/bridge/providers/utxos_state.dart';
import 'package:apparatus_wallet/router.dart';
import 'package:brambldart/brambldart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:topl_common/proto/brambl/models/address.pb.dart';
import 'package:topl_common/proto/brambl/models/box/value.pb.dart';
import 'package:topl_common/proto/brambl/models/transaction/io_transaction.pb.dart';
import 'package:topl_common/proto/brambl/models/transaction/spent_transaction_output.pb.dart';
import 'package:topl_common/proto/brambl/models/transaction/unspent_transaction_output.pb.dart';
import 'package:topl_common/proto/genus/genus_models.pb.dart';
import 'package:topl_common/proto/quivr/models/shared.pb.dart';

class UtxosView extends HookConsumerWidget {
  const UtxosView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final utxos = ref.watch(utxosStateProvider);

    return Scaffold(
      body: body(utxos),
    );
  }

  Widget body(AsyncValue<UtxosMap> utxos) {
    return switch (utxos) {
      AsyncData(:final value) =>
        TransactView(utxos: value, submitTransaction: (tx) {}),
      AsyncError(:final error) =>
        Center(child: Text("Utxos failed to load. Reason: $error")),
      _ => const Center(child: CircularProgressIndicator())
    };
  }
}

class TransactView extends StatefulWidget {
  final UtxosMap utxos;
  final Function(IoTransaction) submitTransaction;

  const TransactView(
      {super.key, required this.utxos, required this.submitTransaction});
  @override
  State<StatefulWidget> createState() => TransactViewState();
}

class TransactViewState extends State<TransactView> {
  // TODO: Move this state into Riverpod
  Set<TransactionOutputAddress> _selectedInputs = {};
  List<(String valueStr, String addressStr)> _newOutputEntries = [];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Card(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: ExpansionPanelList.radio(children: [
                  ExpansionPanelRadio(
                    value: "Inputs",
                    headerBuilder: (context, isExpanded) =>
                        const ListTile(title: Text("Inputs")),
                    body: _inputsTile(),
                  ),
                  ExpansionPanelRadio(
                      value: "Outputs",
                      headerBuilder: (context, isExpanded) =>
                          const ListTile(title: Text("Outputs")),
                      body: _outputsTile()),
                ]),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  label: const Text("Send"),
                  onPressed: _transact,
                  icon: const Icon(Icons.send),
                ),
                TextButton.icon(
                  label: const Text("Acquire tBTC"),
                  onPressed: () => context.go(homeRoute),
                  icon: const Icon(Icons.currency_bitcoin),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Int128 _inputSum() => _selectedInputs
      .toList()
      .map((v) => widget.utxos[v]!.transactionOutput.value.quantity)
      .nonNulls
      .fold(BigInt.zero.toInt128(), (a, b) => a + b);

  Future<IoTransaction> _createTransaction() async {
    var tx = IoTransaction();

    for (final ref in _selectedInputs) {
      final output = widget.utxos[ref]!;
      final input = SpentTransactionOutput()
        ..value = output.transactionOutput.value
        ..address = ref;
      tx.inputs.add(input);
    }

    for (final e in _newOutputEntries) {
      // TODO: Error handling
      final lockAddress = AddressCodecs.decode(e.$2).getOrThrow();
      // TODO: e.$1 value - is it a LVL?
      final value = Value();
      final output = UnspentTransactionOutput()
        ..address = lockAddress
        ..value = value;
      tx.outputs.add(output);
    }
    // TODO: Prove/sign

    return tx;
  }

  _transact() async {
    final tx = await _createTransaction();
    await widget.submitTransaction(tx);
    setState(() {
      _selectedInputs = {};
      _newOutputEntries = [];
    });
  }

  Widget _outputsTile() {
    return Column(
      children: [
        DataTable(
          columns: _outputTableHeader,
          rows: [
            ..._newOutputEntries.mapWithIndex(_outputEntryRow),
            _feeOutputRow()
          ],
        ),
        IconButton(onPressed: _addOutputEntry, icon: const Icon(Icons.add))
      ],
    );
  }

  static const _outputTableHeader = <DataColumn>[
    DataColumn(
      label: Expanded(
        child: Text(
          'Quantity',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      ),
    ),
    DataColumn(
      label: Expanded(
        child: Text(
          'Lock Address',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      ),
    ),
    DataColumn(
      label: Expanded(
        child: Text(
          'Remove',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      ),
    ),
  ];

  DataRow _outputEntryRow((String, String) entry, int index) {
    return DataRow(
      cells: [
        DataCell(TextFormField(
          initialValue: entry.$1,
          onChanged: (value) => _updateOutputEntryQuantity(index, value),
        )),
        DataCell(TextFormField(
          initialValue: entry.$2,
          onChanged: (value) => _updateOutputEntryAddress(index, value),
        )),
        DataCell(
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _deleteOutputEntry(index),
          ),
        ),
      ],
    );
  }

  DataRow _feeOutputRow() {
    Int128 outputSum = BigInt.zero.toInt128();
    String? errorText;
    for (final t in _newOutputEntries) {
      try {
        final parsed = BigInt.parse(t.$1).toInt128();
        outputSum += parsed;
      } catch (_) {
        errorText = "?";
        break;
      }
    }

    return DataRow(cells: [
      DataCell(
          Text(errorText ?? (_inputSum() - outputSum).toBigInt().toString())),
      const DataCell(Text("Tip")),
      const DataCell(IconButton(
        icon: Icon(Icons.cancel),
        onPressed: null,
      )),
    ]);
  }

  _updateOutputEntryQuantity(int index, String value) {
    setState(() {
      final (_, a) = _newOutputEntries[index];
      _newOutputEntries[index] = (value, a);
    });
  }

  _updateOutputEntryAddress(int index, String value) {
    setState(() {
      final (v, _) = _newOutputEntries[index];
      _newOutputEntries[index] = (v, value);
    });
  }

  _addOutputEntry() {
    setState(() {
      _newOutputEntries.add(const ("100", ""));
    });
  }

  _deleteOutputEntry(int index) {
    setState(() {
      _newOutputEntries.removeAt(index);
    });
  }

  Widget _inputsTile() {
    return Container(
        child: widget.utxos.isEmpty
            ? const Text("Empty wallet")
            : DataTable(
                columns: header,
                rows: widget.utxos.entries.map(_inputEntryRow).toList(),
              ));
  }

  DataRow _inputEntryRow(MapEntry<TransactionOutputAddress, Txo> entry) {
    final value = entry.value.transactionOutput.value;
    final quantityString = value.quantity?.show ?? "-";
    return DataRow(
      cells: [
        DataCell(_valueTypeIcon(value)),
        DataCell(Text(quantityString, style: const TextStyle(fontSize: 12))),
        DataCell(TextButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(
                text: AddressCodecs.encode(
                    entry.value.transactionOutput.address)));
          },
          child: Text(
              AddressCodecs.encode(entry.value.transactionOutput.address),
              style: const TextStyle(fontSize: 12)),
        )),
        DataCell(Checkbox(
            value: _selectedInputs.contains(entry.key),
            onChanged: (newValue) =>
                _updateInputEntry(entry.key, newValue ?? false))),
      ],
    );
  }

  _valueTypeIcon(Value value) {
    if (value.hasLvl()) {
      return const Text("LVL");
    } else if (value.hasTopl()) {
      return const Text("TOPL");
    } else if (value.hasAsset()) {
      return const Text("Asset");
    } else {
      return const Text("Other");
    }
  }

  _updateInputEntry(TransactionOutputAddress ref, bool retain) {
    setState(() {
      if (retain) {
        _selectedInputs.add(ref);
      } else {
        _selectedInputs.remove(ref);
      }
    });
  }

  static const header = <DataColumn>[
    DataColumn(
      label: Expanded(
        child: Text(
          'Type',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      ),
    ),
    DataColumn(
      label: Expanded(
        child: Text(
          'Quantity',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      ),
    ),
    DataColumn(
      label: Expanded(
        child: Text(
          'Lock Address',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      ),
    ),
    DataColumn(
      label: Expanded(
        child: Text(
          'Selected',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      ),
    ),
  ];
}
