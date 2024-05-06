import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pedfi/consts/app_color.dart';
import 'package:pedfi/pages/stock/stock_controller.dart';
import 'package:pedfi/provider/dark_theme_provider.dart';
import 'package:provider/provider.dart';

class StockPage extends GetView<StockController> {
  const StockPage({super.key});

  @override
  Widget build(BuildContext context) {

    final themeState = Provider.of<DarkThemeProvider>(context);

    final Color color = themeState.getDarkTheme ? 
    AppColor.textDarkThemeColor : AppColor.textLightThemeColor;
    
    final Color bgcolor = themeState.getDarkTheme ? 
    AppColor.bgDarkThemeColor : AppColor.bgLightThemeColor;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: bgcolor,
      ),
      body: Obx(() =>
        SingleChildScrollView(
          child: Row(
            children: [
              Text(
                'Stock screen',
                style: TextStyle(
                  color: color
                ),
              ),

              Text(
                controller.count.value,
                style:  TextStyle(
                  color: color
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

}