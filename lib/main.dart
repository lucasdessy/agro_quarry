import 'package:agro_quarry/listview.dart';
import 'package:diacritic/diacritic.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_money_formatter/flutter_money_formatter.dart';
import 'package:intl/intl.dart';

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
  bool loading = true;
  bool error = false;
  String currentOption;
  @override
  void initState() {
    currentOption = 'Soja';
    _loadCotacoes(path: removeDiacritics(currentOption.toLowerCase()));
    super.initState();
  }

  Future<void> _loadCotacoes({@required String path}) async {
    String url;
 url = 'http://agroquarry.herokuapp.com/' + path;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(loading? 'Carregando':
            '$currentOption - Mostrando ${cotacoes.results.length} de ${cotacoes.count}'
          ),
          actions: <Widget>[
            PopupMenuButton<String>(
              onSelected: (String option) async {
                setState(() {
                  currentOption = option;
                });
                _loadCotacoes(path: removeDiacritics(currentOption.toLowerCase()));
              },
              itemBuilder: (context) {
                return {'Soja', 'Milho', 'Café'}
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
            await _loadCotacoes(path: removeDiacritics(currentOption.toLowerCase()));
          },
          child: loading
              ? Center(child: CircularProgressIndicator())
              : error
                  ? _messageWidget(message: 'Erro ao carregar cotações!')
                  : cotacoes.results.isEmpty
                      ? _messageWidget(
                          message: 'Não há nenhuma cotação disponível!')
                      : Center(
                          child: IncrementallyLoadingListView(
                              hasMore: cotacoes.hasMorePage,
                              loadMore: () async {
                                await loadMore(url: cotacoes.nextUrl());
                              },
                              loadMoreOffsetFromBottom: 5,
                              itemCount: () => cotacoes.results.length,
                              itemBuilder: (context, index) {
                                Cotacao _cotacao = cotacoes.results[index];
                                return _cotacaoCard(cotacao: _cotacao);
                              }),
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
                  await _loadCotacoes(path: removeDiacritics(currentOption.toLowerCase()));
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

  Widget _cotacaoCard({@required Cotacao cotacao}) {
    return Card(
      child: ListTile(
        title: Text('${DateFormat('dd/MM').format(cotacao.data)}'),
        trailing: Text(
          'Cotação: R\$ ${formatMoney(cotacao.cotacao)}',
          style: TextStyle(fontSize: 16),
        ),
        subtitle: Text('Variação: R\$ ${formatMoney(cotacao.variacao)}'),
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

class Cotacao {
  double id;
  DateTime data;
  double cotacao;
  double variacao;

  Cotacao({this.id, this.data, this.cotacao, this.variacao});

  factory Cotacao.fromJson(Map<String, dynamic> json) => Cotacao(
        id: double.parse(json['id'].toString()),
        data: DateTime.parse(json['data'].toString()),
        cotacao: double.parse(json['cotacao'].toString()),
        variacao: double.parse(json['variacao'].toString()),
      );
}

class RestResponse {
  int count;
  String next;
  String previous;
  List<Cotacao> results;

  RestResponse({this.count, this.next, this.previous, this.results});

  factory RestResponse.fromJson(Map<String, dynamic> json) {
    var list = json['results'] as List;
    List<Cotacao> _cotacoes = list.map((e) => Cotacao.fromJson(e)).toList();
    return RestResponse(
      count: double.parse(json['count'].toString()).toInt(),
      next: json['next'].toString(),
      previous: json['previous'],
      results: _cotacoes,
    );
  }

  void addCotacao(List<Cotacao> _cotacoes) {
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
