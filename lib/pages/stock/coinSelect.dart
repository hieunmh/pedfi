// ignore_for_file: library_private_types_in_public_api

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pedfi/consts/app_color.dart';
import 'package:pedfi/pages/stock/overview/overview_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:pedfi/model/candle_ticker_model.dart';
import 'package:pedfi/candlestick/candlesticks.dart';
import './repository.dart';
import 'package:pedfi/candlestick/models/candle.dart';
import 'package:pedfi/candlestick/models/indicator.dart';
import 'package:pedfi/candlestick/utils/indicators/bollinger_bands_indicator.dart';
import 'package:pedfi/candlestick/utils/indicators/weighted_moving_average.dart';
import 'package:pedfi/candlestick/widgets/toolbar_action.dart';
import 'package:pedfi/provider/dark_theme_provider.dart';
import 'package:provider/provider.dart';

class CustomTextField extends StatelessWidget {
  final void Function(String) onChanged;
  const CustomTextField({Key? key, required this.onChanged}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      autofocus: true,
      cursorColor: const Color(0xFF494537),
      decoration: const InputDecoration(
        prefixIcon: Icon(
          Icons.search,
          color: Color(0xFF494537),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide:
              BorderSide(width: 3, color: Color(0xFF494537)), //<-- SEE HER
        ),
        border: OutlineInputBorder(
          borderSide:
              BorderSide(width: 3, color: Color(0xFF494537)), //<-- SEE HER
        ),
        focusedBorder: OutlineInputBorder(
          borderSide:
              BorderSide(width: 3, color: Color(0xFF494537)), //<-- SEE HER
        ),
      ),
      onChanged: onChanged,
    );
  }
}

class CoinSelect extends StatefulWidget {
  const CoinSelect({Key? key}) : super(key: key);

  @override
  _CoinSelectState createState() => _CoinSelectState();
}

class SymbolsSearchModal extends StatefulWidget {
  final Function(String symbol) onSelect;

  final List<String> symbols;
  const SymbolsSearchModal({
    Key? key,
    required this.onSelect,
    required this.symbols,
  }) : super(key: key);

  @override
  State<SymbolsSearchModal> createState() => _SymbolSearchModalState();
}

class _CoinSelectState extends State<CoinSelect> {
  BinanceRepository repository = BinanceRepository();

  List<Candle> candles = [];
  WebSocketChannel? _channel;
  String currentInterval = "1m";
  final intervals = [
    '1m',
    '3m',
    '5m',
    '15m',
    '30m',
    '1h',
    '2h',
    '4h',
    '6h',
    '8h',
    '12h',
    '1d',
    '3d',
    '1w',
    '1M',
  ];
  List<String> symbols = [];
  String currentSymbol = "ETHBTC";
  double availability = 0.0;
  final quantityController = TextEditingController(text: '1');
  var maxStock = 0.0;
  var overviewController = Get.find<OverviewController>();

  List<Indicator> indicators = [
    BollingerBandsIndicator(
      length: 20,
      stdDev: 2,
      upperColor: const Color(0xFF2962FF),
      basisColor: const Color(0xFFFF6D00),
      lowerColor: const Color(0xFF2962FF),
    ),
    WeightedMovingAverageIndicator(
      length: 100,
      color: Colors.green.shade600,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final themeState = Provider.of<DarkThemeProvider>(context);
    bool themeIsDark = themeState.getDarkTheme;
    return MaterialApp(
      theme: themeIsDark ? ThemeData.dark() : ThemeData.light(),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: themeIsDark ? Colors.blueGrey[900] : Colors.amber,
          title: Text(
            "Finance Trading Analytics",
            style: TextStyle(
              color: themeIsDark ? Colors.white : Colors.black,
            ),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: StreamBuilder(
            stream: _channel == null ? null : _channel!.stream,
            builder: (context, snapshot) {
              updateCandlesFromSnapshot(snapshot);
              return Column(
                children: [
                  Container(
                    color: themeIsDark ? const Color(0xFF191B20) : Colors.white,
                    height: 80,
                    width: double.maxFinite,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 10, right: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!snapshot.hasData)
                            const Center(
                              child: CircularProgressIndicator(),
                            ),
                          if (snapshot.hasData)
                            InkWell(
                              onTap: () {
                                showModalBottomSheet(
                                  backgroundColor: Colors.transparent,
                                  context: context,
                                  builder: (context) {
                                    return SymbolsSearchModal(
                                      onSelect: (symbol) {
                                        setState(() {
                                          currentSymbol = symbol;
                                          fetchCandles(symbol, currentInterval);
                                        });
                                      },
                                      symbols: symbols,
                                    );
                                  },
                                );
                              },
                              child: Text(
                                currentSymbol,
                                style: const TextStyle(
                                  fontSize: 20,
                                ),
                              ),
                          ),
                          const SizedBox(width: 10),
                          
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                candles.isNotEmpty
                                    ? candles.last.close.toStringAsFixed(2)
                                    : "0.00",
                                style: TextStyle(
                                  fontSize: 15,
                                  color: candles.isNotEmpty
                                      ? candles.last.close >
                                              candles[candles.length - 2].close
                                          ? Colors.green
                                          : Colors.red
                                      : Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                "\$${candles.isNotEmpty ? candles.last.close.toStringAsFixed(2) : ""}",
                                style: const TextStyle(
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 10),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'Open',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(candles.isNotEmpty
                                  ? candles.last.open.toStringAsFixed(2)
                                  : "0.00"),
                            ],
                          ),
                          const SizedBox(width: 10),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'Close',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(candles.isNotEmpty
                                  ? candles.last.close.toStringAsFixed(2)
                                  : "0.00"),
                            ],
                          ),
                          const SizedBox(width: 10),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'High',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(candles.isNotEmpty
                                  ? candles.last.high.toStringAsFixed(2)
                                  : "0.00"),
                            ],
                          ),
                          const SizedBox(width: 10),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'Low',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(candles.isNotEmpty
                                  ? candles.last.low.toStringAsFixed(2)
                                  : "0.00"),
                            ],
                          ),
                          const SizedBox(width: 10),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'Change',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(candles.isNotEmpty
                                  ? (candles.last.close - candles.last.open)
                                      .toStringAsFixed(2)
                                  : "0.00"),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Show Streaming data in json form
                  // Text(snapshot.hasData ? '${snapshot.data}' : ''),
                  const Divider(
                    height: 1,
                    color: Colors.grey,
                  ),
                  Expanded(
                    child: Candlesticks(
                      key: Key(currentSymbol + currentInterval),
                      indicators: indicators,
                      candles: candles,
                      onLoadMoreCandles: loadMoreCandles,
                      onRemoveIndicator: (String indicator) {
                        setState(() {
                          indicators = [...indicators];
                          indicators.removeWhere(
                              (element) => element.name == indicator);
                        });
                      },
                      actions: [
                        ToolBarAction(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) {
                                return Center(
                                  child: Container(
                                    width: 200,
                                    color:
                                        Theme.of(context).dialogBackgroundColor,
                                    child: Wrap(
                                      children: intervals
                                          .map((e) => Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: SizedBox(
                                                  width: 50,
                                                  height: 30,
                                                  child: RawMaterialButton(
                                                    elevation: 0,
                                                    fillColor:
                                                        const Color(0xFF494537),
                                                    onPressed: () {
                                                      fetchCandles(
                                                          currentSymbol, e);
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                    child: Text(
                                                      e,
                                                      style: const TextStyle( 
                                                        color:
                                                            Color(0xFFF0B90A),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ))
                                          .toList(),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          child: Text(
                            currentInterval,
                          ),
                        ),
                        ToolBarAction(
                          width: 100,
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) {
                                return SymbolsSearchModal(
                                  symbols: symbols,
                                  onSelect: (value) {
                                    fetchCandles(value, currentInterval);
                                  },
                                );
                              },
                            );
                          },
                          child: Text(
                            currentSymbol,
                          ),
                        )
                      ],
                    ),
                  ),
                  const Divider(
                    height: 1,
                    color: Colors.grey,
                  ),
                  Container(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () {
                              getMaxStock();
                              showDialog(
                                context: context, 
                                builder: (_) {
                                  return Dialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)
                                    ),
                                    child: IntrinsicWidth(
                                      child: IntrinsicHeight(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                          child: Column(
                                            children: [
                                              
                                              const Text(
                                                'Buy',
                                                style: TextStyle(
                                                  fontSize: 20
                                                ),
                                              ),

                                              const SizedBox(height: 10),
                                          
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade200,
                                                  borderRadius: BorderRadius.circular(5)
                                                ),
                                                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [                                        
                                                    Column(
                                                      children: [
                                                        const Text(
                                                          'Value (USDT)',
                                                          style: TextStyle(
                                                            color: Colors.grey,
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.w500
                                                          ),
                                                        ),

                                                        Text(
                                                          candles.last.close.toString(),
                                                          style: const TextStyle(
                                                            fontWeight: FontWeight.w600,
                                                            fontSize: 14
                                                          ),
                                                        )
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              const SizedBox(height: 10),

                                              Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade200,
                                                  borderRadius: BorderRadius.circular(5)
                                                ),
                                                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [                                          
                                                    Column(
                                                      children: [
                                                        const Text(
                                                          'Quantity',
                                                          style: TextStyle(
                                                            color: Colors.grey,
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.w500
                                                          ),
                                                        ),

                                                        SizedBox(
                                                          height: 20,
                                                          width: 50,
                                                          child: TextField(
                                                            textAlignVertical: TextAlignVertical.top,
                                                            controller: quantityController,
                                                            style: const TextStyle(
                                                              fontWeight: FontWeight.w700,
                                                              
                                                            ),
                                                        
                                                            keyboardType: TextInputType.number,
                                                            cursorColor: Colors.black,
                                                            decoration: const InputDecoration(
                                                              border: InputBorder.none,
                                                              hintText: '0', 
                                                              hintStyle: TextStyle(
                                                                color: Colors.black,
                                                                fontWeight: FontWeight.w500
                                                              )
                                                            ),
                                                          ),
                                                        )
                                                      ],
                                                    ),
                                        
                                                  ],
                                                ),
                                              ),

                                              const SizedBox(height: 10),

                                              const Divider(),

                                              const SizedBox(height: 10),

                                              Container(
                                                width: double.infinity,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade200,
                                                  borderRadius: BorderRadius.circular(5)
                                                ),
                                                padding: const EdgeInsets.all(10),
                                                child: const Center(
                                                  child: Text(
                                                    'Total(USDT)',
                                                    style:  TextStyle(
                                                      fontWeight: FontWeight.w600
                                                    ),
                                                  ),
                                                )
                                              ),

                                              const SizedBox(height: 10),

                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  const Text(
                                                    'Availability',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.w500,
                                                      fontSize: 12
                                                    ),
                                                  ),

                                                  Text(
                                                    '$availability USDT',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.w500,
                                                      fontSize: 12
                                                    ),
                                                  )
                                                ],
                                              ),

                                              const SizedBox(height: 5),

                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  const Text(
                                                    'Buy max',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.w500,
                                                      fontSize: 12,
                                                      decoration: TextDecoration.underline
                                                    ),
                                                  ),

                                                  Text(
                                                    "${(availability / candles.last.close).toStringAsFixed(2)} $currentSymbol",
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.w500,
                                                      fontSize: 12
                                                    ),
                                                  )
                                                ],
                                              ),

                                              const SizedBox(height: 5),

                                              const Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    'Expected fee',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.w500,
                                                      fontSize: 12,
                                                      decoration: TextDecoration.underline
                                                    ),
                                                  ),

                                                  Text(
                                                    '0.01%',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.w500,
                                                      fontSize: 12
                                                    ),
                                                  )
                                                ],
                                              ),

                                              const SizedBox(height: 10),

                                              GestureDetector(
                                                onTap: () async {
                                                  await transactionStock(true, double.parse(quantityController.text));
                                                  await getMaxStock();
                                                  await overviewController.getWalletCoin();
                                                  await overviewController.getCoinList();
                                                  await overviewController.getCoinHistory();
                                                  Get.back();
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                                  width: double.infinity,
                                                  decoration: BoxDecoration(
                                                    color: AppColor.incomeDarkColor,
                                                    borderRadius: BorderRadius.circular(5)
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      'Buy $currentSymbol',
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w500
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                    )
                                  );
                                }
                              );
                            },
                            child: Container(
                              width: 110,
                              height: 30,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                color: AppColor.incomeDarkColor),
                              child: const Center(
                                child: Text("Buy",
                                style:  TextStyle(fontSize: 16))),
                            ),
                          ),

                          const SizedBox(width: 25),

                          GestureDetector(
                            onTap: () {
                              getMaxStock();
                              showDialog(
                                context: context, 
                                builder: (_) {
                                  return Dialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)
                                    ),
                                    child: IntrinsicWidth(
                                      child: IntrinsicHeight(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                          child: Column(
                                            children: [
                                              
                                              const Text(
                                                'Sell',
                                                style: TextStyle(
                                                  fontSize: 20
                                                ),
                                              ),

                                              const SizedBox(height: 10),
                                          
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade200,
                                                  borderRadius: BorderRadius.circular(5)
                                                ),
                                                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Column(
                                                      children: [
                                                        const Text(
                                                          'Value (USDT)',
                                                          style: TextStyle(
                                                            color: Colors.grey,
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.w500
                                                          ),
                                                        ),

                                                        Text(
                                                          candles.last.close.toString(),
                                                          style: const TextStyle(
                                                            fontWeight: FontWeight.w600,
                                                            fontSize: 14
                                                          ),
                                                        )
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              const SizedBox(height: 10),

                                              Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade200,
                                                  borderRadius: BorderRadius.circular(5)
                                                ),
                                                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                          
                                                    Column(
                                                      children: [
                                                        const Text(
                                                          'Quantity',
                                                          style: TextStyle(
                                                            color: Colors.grey,
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.w500
                                                          ),
                                                        ),

                                                        SizedBox(
                                                          height: 20,
                                                          width: 50,
                                                          child: TextField(
                                                            textAlignVertical: TextAlignVertical.top,
                                                            controller: quantityController,
                                                            style: const TextStyle(
                                                              fontWeight: FontWeight.w700,
                                                              
                                                            ),
                                                        
                                                            keyboardType: TextInputType.number,
                                                            cursorColor: Colors.black,
                                                            decoration: const InputDecoration(
                                                              border: InputBorder.none,
                                                              hintText: '0', 
                                                              hintStyle: TextStyle(
                                                                color: Colors.black,
                                                                fontWeight: FontWeight.w500
                                                              )
                                                            ),
                                                          ),
                                                        )
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              const SizedBox(height: 10),

                                              const Divider(),

                                              const SizedBox(height: 10),

                                              Container(
                                                width: double.infinity,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade200,
                                                  borderRadius: BorderRadius.circular(5)
                                                ),
                                                padding: const EdgeInsets.all(10),
                                                child: const Center(
                                                  child: Text(
                                                    'Total(USDT)',
                                                    style:  TextStyle(
                                                      fontWeight: FontWeight.w600
                                                    ),
                                                  ),
                                                )
                                              ),

                                              const SizedBox(height: 10),

                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  const Text(
                                                    'Availability',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.w500,
                                                      fontSize: 12
                                                    ),
                                                  ),

                                                  Text(
                                                    '$availability USDT',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.w500,
                                                      fontSize: 12
                                                    ),
                                                  )
                                                ],
                                              ),

                                              const SizedBox(height: 5),

                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  const Text(
                                                    'Sell max',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.w500,
                                                      fontSize: 12,
                                                      decoration: TextDecoration.underline
                                                    ),
                                                  ),

                                                  Text(
                                                    '$maxStock $currentSymbol',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.w500,
                                                      fontSize: 12
                                                    ),
                                                  )
                                                ],
                                              ),

                                              const SizedBox(height: 5),

                                              const Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    'Expected fee',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.w500,
                                                      fontSize: 12,
                                                      decoration: TextDecoration.underline
                                                    ),
                                                  ),

                                                  Text(
                                                    '0.01%',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.w500,
                                                      fontSize: 12
                                                    ),
                                                  )
                                                ],
                                              ),

                                              const SizedBox(height: 10),

                                              GestureDetector(
                                                onTap: () async {
                                                  await transactionStock(false, double.parse(quantityController.text));
                                                  await getMaxStock();
                                                  await overviewController.getWalletCoin();
                                                  await overviewController.getCoinList();
                                                  await overviewController.getCoinHistory();
                                                  Get.back();
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                                  width: double.infinity,
                                                  decoration: BoxDecoration(
                                                    color: AppColor.expenseDarkColor,
                                                    borderRadius: BorderRadius.circular(5)
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      'Sell $currentSymbol',
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w500
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                    )
                                  );
                                }
                              );
                            },
                            child: Container(
                              width: 110,
                              height: 30,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5),
                                  color: AppColor.expenseDarkColor),
                              child: const Center(
                                child: Text("Sell",
                                style: TextStyle(fontSize: 16))),
                            ),
                          ),
                        ],
                      ))
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (_channel != null) _channel!.sink.close();
    super.dispose();
  }

  Future<void> fetchCandles(String symbol, String interval) async {
    // close current channel if exists
    if (_channel != null) {
      _channel!.sink.close();
      _channel = null;
    }
    // clear last candle list
    setState(() {
      candles = [];
      currentInterval = interval;
    });

    try {
      // load candles info
      final data =
          await repository.fetchCandles(symbol: symbol, interval: interval);
      // connect to binance stream
      _channel =
          repository.establishConnection(symbol.toLowerCase(), currentInterval);
      // update candles
      setState(() {
        candles = data;
        currentInterval = interval;
        currentSymbol = symbol;
      });
    } catch (e) {
      // handle error
      return;
    }
  }

  Future<List<String>> fetchSymbols() async {
    try {
      // load candles info
      final data = await repository.fetchSymbols();
      return data;
    } catch (e) {
      // handle error
      return [];
    }
  }

  @override
  void initState() {
    fetchSymbols().then((value) {
      symbols = value;
      if (symbols.isNotEmpty) fetchCandles(symbols[0], currentInterval);
    });
    super.initState();
    getWalletCoin();
    getMaxStock();
  }

  Future<void> getMaxStock() async {
    final supabase = Supabase.instance.client;
    var id = supabase.auth.currentUser?.id.toString() ?? '';

    var res = await supabase.from('Coins').select()
    .eq('user_id', id).eq('coin_id', currentSymbol);
    
    if (res.isEmpty) {
      return;
    }

    setState(() {
      maxStock = res[0]['amount'].toDouble();
    });
  }

  Future<void> getWalletCoin() async {
    final supabase = Supabase.instance.client;
    var id = supabase.auth.currentUser?.id.toString() ?? '';
    var res = await supabase.from('Wallets')
    .select().eq('user_id', id).eq('name', 'coin').single();

    setState(() {
      availability = res['value'].toDouble();
    });
  }

  Future<void> transactionStock(bool type, double amount) async {
    final supabase = Supabase.instance.client;
    var id = supabase.auth.currentUser?.id.toString() ?? '';

    if (!type && maxStock == 0.0) {
      return;
    }

    var res = await supabase.from('Coins').select()
    .eq('user_id', id).eq('coin_id', currentSymbol);

    if (res.isEmpty) {
      await supabase.from('Coins').insert({
        'user_id': id,
        'coin_id': currentSymbol,
        'amount': amount,
        'average_price': candles.last.close
      });
    } else {
      await supabase.from('Coins').update({
        'user_id': id,
        'coin_id': currentSymbol,
        'amount': type == true ? res[0]['amount'] + amount : res[0]['amount'] - amount,
        'average_price': candles.last.close
      }).eq('user_id', id).eq('coin_id', currentSymbol);
    }


    await supabase.from('CoinTransHistory').insert({
      'user_id': id,
      'coin_id': currentSymbol,
      'amount': amount,
      'price': candles.last.close,
      'type_order': type 
    });

    final z = amount * candles.last.close; 

    // update value
    await supabase.from('Wallets').update({
      'value': type == true ? availability - z : availability + z
    })
    .eq('user_id', id).eq('name', 'coin');

    quantityController.text = '1';
  }

  Future<void> loadMoreCandles() async {
    try {
      // load candles info
      final data = await repository.fetchCandles(
          symbol: currentSymbol,
          interval: currentInterval,
          endTime: candles.last.date.millisecondsSinceEpoch);
      candles.removeLast();
      setState(() {
        candles.addAll(data);
      });
    } catch (e) {
      // handle error
      return;
    }
  }

  void updateCandlesFromSnapshot(AsyncSnapshot<Object?> snapshot) {
    if (candles.isEmpty) return;
    if (snapshot.data != null) {
      final map = jsonDecode(snapshot.data as String) as Map<String, dynamic>;
      if (map.containsKey("k") == true) {
        final candleTicker = CandleTickerModel.fromJson(map);

        // cehck if incoming candle is an update on current last candle, or a new one
        if (candles[0].date == candleTicker.candle.date &&
            candles[0].open == candleTicker.candle.open) {
          // update last candle
          candles[0] = candleTicker.candle;
        }
        // check if incoming new candle is next candle so the difrence
        // between times must be the same as last existing 2 candles
        else if (candleTicker.candle.date.difference(candles[0].date) ==
            candles[0].date.difference(candles[1].date)) {
          // add new candle to list
          candles.insert(0, candleTicker.candle);
        }
      }
    }
  }
}

class _SymbolSearchModalState extends State<SymbolsSearchModal> {
  String symbolSearch = "";
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 300,
          height: MediaQuery.of(context).size.height * 0.75,
          color: Theme.of(context).dialogBackgroundColor.withOpacity(0.5),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CustomTextField(
                  onChanged: (value) {
                    setState(() {
                      symbolSearch = value;
                    });
                  },
                ),
              ),
              Expanded(
                child: ListView(
                  children: widget.symbols
                      .where((element) => element
                          .toLowerCase()
                          .contains(symbolSearch.toLowerCase()))
                      .map((e) => Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SizedBox(
                              width: 50,
                              height: 30,
                              child: RawMaterialButton(
                                elevation: 0,
                                fillColor: const Color(0xFF494537),
                                onPressed: () {
                                  widget.onSelect(e);
                                  Navigator.of(context).pop();
                                },
                                child: Text(
                                  e,
                                  style: const TextStyle(
                                    color: Color(0xFFF0B90A),
                                  ),
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
