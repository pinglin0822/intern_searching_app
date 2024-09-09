import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'database_helper.dart';

class DataAnalystPage extends StatefulWidget {
  @override
  _DataAnalystPageState createState() => _DataAnalystPageState();
}

class _DataAnalystPageState extends State<DataAnalystPage> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final List<String> _areas = [
    'Johor',
    'Kedah',
    'Kelantan',
    'Kuala Lumpur',
    'Melaka',
    'Negeri Sembilan',
    'Pahang',
    'Perak',
    'Perlis',
    'Penang',
    'Sabah',
    'Sarawak',
    'Selangor',
    'Terengganu',
  ];

  List<BarChartGroupData> _barGroups = [];
  Map<String, double> _averageSalaries = {}; // To hold the average salary for each area
  bool _loading = true;
  double _maxY = 0; // Keep track of the maximum y value for the chart

  @override
  void initState() {
    super.initState();
    _fetchPostData();
  }

  Future<void> _fetchPostData() async {
    List<Map<String, dynamic>> posts = await _databaseHelper.fetchPosts();

    // Calculate the total posts per area and average salary
    Map<String, int> areaPostCounts = {};
    Map<String, double> areaSalarySums = {};

    for (var area in _areas) {
      var postsInArea = posts.where((post) => post['area'] == area).toList();

      // Calculate the total posts for each area
      areaPostCounts[area] = postsInArea.length;

      // Calculate the total salary for each area
      double totalSalary = postsInArea.fold(
        0,
        (sum, post) {
          double lowestSalary = post['lowestSalary']?.toDouble() ?? 0;
          double highestSalary = post['highestSalary']?.toDouble() ?? 0;
          double averageSalary = (lowestSalary + highestSalary) / 2;
          return sum + averageSalary;
          },
      );

      // Calculate the average salary for each area
      if (areaPostCounts[area]! > 0) {
        _averageSalaries[area] = totalSalary / areaPostCounts[area]!;
      } else {
        _averageSalaries[area] = 0;
      }
    }

    // Determine the maximum value for the y-axis
    int maxPostCount = areaPostCounts.values.isNotEmpty
        ? areaPostCounts.values.reduce((a, b) => a > b ? a : b)
        : 0;

    List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < _areas.length; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: areaPostCounts[_areas[i]]?.toDouble() ?? 0,
              color: Colors.blue,
              width: 16,
              borderRadius: BorderRadius.circular(6),
            ),
          ],
        ),
      );
    }

    setState(() {
      _barGroups = barGroups;
      _maxY = maxPostCount.toDouble();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Data Analyst'),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total job posts in each area',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),

                    // Scrollable horizontal chart
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: _areas.length * 80.0,
                        ),
                        child: SizedBox(
                          height: 400,
                          child: BarChart(
                            BarChartData(
                              maxY: _maxY + 1, // Set maxY slightly above the maximum value
                              gridData: FlGridData(
                                show: true,
                                getDrawingHorizontalLine: (value) => FlLine(
                                  color: Colors.grey.shade300,
                                  strokeWidth: 1,
                                ),
                              ),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 40,
                                    getTitlesWidget: (value, meta) {
                                      if (value % 10 == 0) {
                                        return Text('${value.toInt()}');
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      final index = value.toInt();
                                      if (index < 0 || index >= _areas.length)
                                        return const SizedBox.shrink();
                                      return SideTitleWidget(
                                        axisSide: meta.axisSide,
                                        child: Text(
                                          _areas[index],
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                rightTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              borderData: FlBorderData(
                                show: true,
                                border: Border.all(color: Colors.black, width: 1),
                              ),
                              barGroups: _barGroups,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 32),

                    // Table for average salary
                    Text(
                      'Average salary in each area (RM)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const <DataColumn>[
                          DataColumn(
                            label: Text('Area'),
                          ),
                          DataColumn(
                            label: Text('Average Salary (RM)'),
                          ),
                        ],
                        rows: _areas
                            .map(
                              (area) => DataRow(
                                cells: <DataCell>[
                                  DataCell(Text(area)),
                                  DataCell(Text(
                                    _averageSalaries[area]?.toStringAsFixed(2) ?? '0.00',
                                  )),
                                ],
                              ),
                            )
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
