import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class GraphView extends StatefulWidget {
  const GraphView({super.key});

  @override
  State<GraphView> createState() => _GraphViewState();
}

class _GraphViewState extends State<GraphView> {
  List<_SalesData> data = [
    _SalesData('Jan', 35),
    _SalesData('Feb', 28),
    _SalesData('Mar', 34),
    _SalesData('Apr', 90),
    _SalesData('May', 40),
    _SalesData('Jun', 35),
    _SalesData('July', 28),
    _SalesData('Aug', 34),
    _SalesData('Sep', 70),
    _SalesData('Oct', 40),
    _SalesData('Nov', 20),
    _SalesData('Dec', 50)
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                SfCartesianChart(
                    primaryXAxis: CategoryAxis(interval: 1, labelRotation: -90, title: AxisTitle(text: 'Month')),
                    // Chart title
                    title: ChartTitle(text: 'Monthly sales analysis line chart'),
                    // Enable legend
                    legend: Legend(isVisible: true),
                    // Enable tooltip
                    tooltipBehavior: TooltipBehavior(enable: true),
                    series: <CartesianSeries<_SalesData, String>>[
                      LineSeries<_SalesData, String>(
                          enableTooltip: true,
                          dataSource: data,
                          xValueMapper: (_SalesData sales, _) => sales.month,
                          yValueMapper: (_SalesData sales, _) => sales.sales,
                          name: 'Sales',
                          dataLabelSettings: DataLabelSettings(
                              isVisible: true,
                          ),
                        markerSettings: MarkerSettings(
                            isVisible: true,
                            height: 4,
                            width: 4,
                            shape: DataMarkerType.circle,
                            borderWidth: 3,
                            borderColor: Colors.black),
                      ),
                    ],
                  zoomPanBehavior: ZoomPanBehavior(
                      enablePanning: true,
                      enablePinching: true,
                      zoomMode: ZoomMode.x
                  ),
                ),
                Divider(),
                SfCartesianChart(
                  primaryXAxis: CategoryAxis(
                    majorGridLines: MajorGridLines(width: 0),
                    labelPlacement: LabelPlacement.onTicks,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      color: Colors.black,
                    ),
                  ),
                  title: ChartTitle(text: 'Monthly Sales Bar Chart'),
                  legend: Legend(isVisible: true),
                  tooltipBehavior: TooltipBehavior(enable: true),
                  series: <CartesianSeries<_SalesData, String>>[
                    ColumnSeries<_SalesData, String>(
                      dataSource: data,
                      xValueMapper: (_SalesData sales, _) => sales.month,
                      yValueMapper: (_SalesData sales, _) => sales.sales,
                      name: 'Sales',
                      dataLabelSettings: DataLabelSettings(isVisible: true),
                      pointColorMapper: (_SalesData sales, _) => sales.sales%4==0?Colors.green:Colors.orange,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ));
  }
}

class _SalesData {
  _SalesData(this.month, this.sales);
  final String month;
  final double sales;
}
