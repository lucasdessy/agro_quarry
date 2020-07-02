import 'package:agro_quarry/listview.dart';
import 'package:diacritic/diacritic.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:flutter_money_formatter/flutter_money_formatter.dart';
import 'package:intl/intl.dart';
import 'package:charts_flutter/flutter.dart' as charts;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agro Quarry',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  RestResponse cotacoes;
  bool isCafe = false;
  bool loading = true;
  bool error = false;
  String currentOption;
  DateTime startDate;
  DateTime endDate;

  @override
  void initState() {
    currentOption = 'Soja';
    _loadCotacoes(path: currentOption);
    super.initState();
  }

  Future<void> _loadCotacoes({@required String path}) async {
    String url;
    url = 'http://agroquarry.herokuapp.com/' +
        removeDiacritics(path.toLowerCase().replaceAll(' ', '/')) +
        '?';
    if (startDate != null) {
      url += '&data_inicio=${DateFormat('yyyy-MM-dd').format(startDate)}';
    }
    if (endDate != null) {
      url += '&data_fim=${DateFormat('yyyy-MM-dd').format(endDate)}';
    }
    print(url);
    setState(() {
      loading = true;
    });
    Dio dio = Dio();
    try {
      Response response = await dio.get(url);

      cotacoes = RestResponse.fromJson(response.data);

      setState(() {
        error = false;
      });
    } catch (e) {
      print(e);
      setState(() {
        error = true;
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> loadMore({@required String url}) async {
    Dio dio = Dio();
    Response response = await dio.get(url);
    RestResponse _cotacoes = RestResponse.fromJson(response.data);
    cotacoes.addCotacao(_cotacoes.results);
    cotacoes.updateNext(_cotacoes.next);
    setState(() {});
    return;
  }

  List<charts.Series<TimeSeriesSales, DateTime>> _createSampleData() {
    if (!isCafe) {
      List<TimeSeriesSales> data = List<TimeSeriesSales>();
      cotacoes.results.forEach((element) {
        data.add(TimeSeriesSales(element.data, element.cotacao));
      });

      return [
        new charts.Series<TimeSeriesSales, DateTime>(
          id: 'graph',
          colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
          domainFn: (TimeSeriesSales sales, _) => sales.time,
          measureFn: (TimeSeriesSales sales, _) => sales.sales,
          data: data,
          displayName: currentOption,
        )
      ];
    } else {
      List<TimeSeriesSales> arabica = List<TimeSeriesSales>();
      cotacoes.results.forEach((element) {
        if (element.tipo.toLowerCase() == 'arabica') {
          arabica.add(TimeSeriesSales(element.data, element.cotacao));
        }
      });
      List<TimeSeriesSales> conillon = List<TimeSeriesSales>();
      cotacoes.results.forEach((element) {
        if (element.tipo.toLowerCase() == 'conillon') {
          conillon.add(TimeSeriesSales(element.data, element.cotacao));
        }
      });
      return [
        new charts.Series<TimeSeriesSales, DateTime>(
          id: 'arabica',
          colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
          domainFn: (TimeSeriesSales sales, _) => sales.time,
          measureFn: (TimeSeriesSales sales, _) => sales.sales,
          data: arabica,
          displayName: 'Arábica',
        ),
        new charts.Series<TimeSeriesSales, DateTime>(
          id: 'conillon',
          colorFn: (_, __) => charts.MaterialPalette.red.shadeDefault,
          domainFn: (TimeSeriesSales sales, _) => sales.time,
          measureFn: (TimeSeriesSales sales, _) => sales.sales,
          data: conillon,
          displayName: 'Conillon',
        )
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(loading
              ? 'Carregando'
              : '$currentOption - ${cotacoes?.results?.length} de ${cotacoes?.count}'),
          actions: <Widget>[
            GestureDetector(
              onTap: () async {
                showModalBottomSheet(
                    context: context,
                    builder: (context) {
                      return Container(
                        child: Wrap(
                          children: <Widget>[
                            ListTile(
                              leading: Icon(
                                Icons.date_range,
                                color: Colors.blue,
                              ),
                              title: Text(
                                  'Data de início ${startDate == null ? '' : '- ' + DateFormat('dd/MM/yyyy').format(startDate)}'),
                              onTap: () async {
                                await DatePicker.showDatePicker(context,
                                    locale: LocaleType.pt,
                                    currentTime: startDate == null
                                        ? DateTime.now()
                                        : startDate, onConfirm: (date) {
                                  setState(() {
                                    startDate = date;
                                  });
                                  _loadCotacoes(path: currentOption);
                                });
                                Navigator.of(context).pop();
                              },
                            ),
                            ListTile(
                              leading: Icon(
                                Icons.date_range,
                                color: Colors.green,
                              ),
                              title: Text(
                                  'Data de Término ${endDate == null ? '' : '- ' + DateFormat('dd/MM/yyyy').format(endDate)}'),
                              onTap: () async {
                                await DatePicker.showDatePicker(context,
                                    locale: LocaleType.pt,
                                    currentTime: endDate == null
                                        ? DateTime.now()
                                        : endDate, onConfirm: (date) {
                                  setState(() {
                                    endDate = date;
                                  });
                                  _loadCotacoes(path: currentOption);
                                });
                                Navigator.of(context).pop();
                              },
                            ),
                            ListTile(
                              leading: Icon(
                                Icons.clear,
                                color: Colors.red,
                              ),
                              title: Text('Remover filtro'),
                              onTap: () {
                                setState(() {
                                  startDate = null;
                                  endDate = null;
                                });
                                _loadCotacoes(path: currentOption);
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        ),
                      );
                    });
              },
              child: Icon(Icons.filter_list),
            ),
            PopupMenuButton<String>(
              onSelected: (String option) async {
                setState(() {
                  if (option == 'Café') {
                    isCafe = true;
                  } else {
                    isCafe = false;
                  }
                  currentOption = option;
                });
                _loadCotacoes(path: currentOption);
              },
              itemBuilder: (context) {
                return {
                  'Soja',
                  'Milho',
                  'Café',
                  'Café Conillon',
                  'Café Arábica'
                }
                    .map((e) => PopupMenuItem(
                          value: e,
                          child: Text(e),
                        ))
                    .toList();
              },
            )
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            await _loadCotacoes(path: currentOption);
          },
          child: loading
              ? Center(child: CircularProgressIndicator())
              : error
                  ? _messageWidget(message: 'Erro ao carregar cotações!')
                  : cotacoes.results.isEmpty
                      ? _messageWidget(
                          message: 'Não há nenhuma cotação disponível!')
                      : Column(
                          children: <Widget>[
                            Container(
                              height: 150,
                              child: SimpleTimeSeriesChart(
                                _createSampleData(),
                                animate: true,
                              ),
                            ),
                            Expanded(
                              child: IncrementallyLoadingListView(
                                  hasMore: cotacoes.hasMorePage,
                                  loadMore: () async {
                                    await loadMore(url: cotacoes.nextUrl());
                                  },
                                  loadMoreOffsetFromBottom: 5,
                                  itemCount: () => cotacoes.results.length,
                                  itemBuilder: (context, index) {
                                    Results _cotacao = cotacoes.results[index];
                                    return _cotacaoCard(cotacao: _cotacao);
                                  }),
                            ),
                          ],
                        ),
        ));
  }

  Widget _messageWidget({String message}) => Center(
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Text(
                message,
                style: TextStyle(fontSize: 17),
              ),
              SizedBox(
                height: 10,
              ),
              RaisedButton(
                onPressed: () async {
                  await _loadCotacoes(path: currentOption);
                },
                child: Text(
                  'Recarregar',
                  style: TextStyle(color: Colors.white),
                ),
                color: Colors.blue,
              )
            ],
          ),
        ),
      );

  Widget _cotacaoCard({@required Results cotacao}) {
    return Card(
      child: ListTile(
        title: Text('${DateFormat('dd/MM/yyyy').format(cotacao.data)}'),
        trailing: Text(
          'Cotação: R\$ ${formatMoney(cotacao.cotacao)}',
          style: TextStyle(fontSize: 16),
        ),
        subtitle: Text(
            'Variação: R\$ ${formatMoney(cotacao.variacao)} ${isCafe ? '\nTipo do café: ${cotacao.tipo}' : ''}'),
      ),
    );
  }

  String formatMoney(double valor) {
    return FlutterMoneyFormatter(
        amount: valor,
        settings: MoneyFormatterSettings(
          thousandSeparator: '.',
          decimalSeparator: ',',
          fractionDigits: 2,
        )).output.nonSymbol;
  }
}

class RestResponse {
  int count;
  String next;
  String previous;
  List<Results> results;

  RestResponse({this.count, this.next, this.previous, this.results});

  RestResponse.fromJson(Map<String, dynamic> json) {
    count = json['count'];
    next = json['next'];
    previous = json['previous'];
    if (json['results'] != null) {
      results = new List<Results>();
      json['results'].forEach((v) {
        results.add(new Results.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['count'] = this.count;
    data['next'] = this.next;
    data['previous'] = this.previous;
    if (this.results != null) {
      data['results'] = this.results.map((v) => v.toJson()).toList();
    }
    return data;
  }

  void addCotacao(List<Results> _cotacoes) {
    _cotacoes.forEach((element) {
      this.results.add(element);
    });
  }

  String nextUrl() {
    return this.next;
  }

  void updateNext(String url) {
    this.next = url;
  }

  bool hasMorePage() {
    return this.next != 'null';
  }
}

class Results {
  int id;
  String tipo;
  DateTime data;
  double cotacao;
  double variacao;

  Results({this.id, this.tipo, this.data, this.cotacao, this.variacao});

  Results.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    tipo = json['tipo'];
    data = DateTime.parse(json['data']);
    cotacao = json['cotacao'];
    variacao = json['variacao'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['tipo'] = this.tipo;
    data['data'] = this.data;
    data['cotacao'] = this.cotacao;
    data['variacao'] = this.variacao;
    return data;
  }
}

class SimpleTimeSeriesChart extends StatelessWidget {
  final List<charts.Series> seriesList;
  final bool animate;

  SimpleTimeSeriesChart(this.seriesList, {this.animate});

  @override
  Widget build(BuildContext context) {
    return new charts.TimeSeriesChart(
      seriesList,
      animate: animate,
      dateTimeFactory: const charts.LocalDateTimeFactory(),
      behaviors: [
        new charts.SeriesLegend(position: charts.BehaviorPosition.bottom)
      ],
    );
  }
}

class TimeSeriesSales {
  final DateTime time;
  final double sales;

  TimeSeriesSales(this.time, this.sales);
}
