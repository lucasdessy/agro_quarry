import 'dart:convert';

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
      home: MyHomePage(title: 'Agro Quarry'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Cotacao> cotacoes = List<Cotacao>();
  bool loading = true;
  bool error = false;

  @override
  void initState() {
    _loadCotacoes();
    super.initState();
  }

  Future<void> _loadCotacoes({String path}) async {
    String url;
    path == null
        ? url = 'http://agroquarry.herokuapp.com/soja'
        : url = 'http://agroquarry.herokuapp.com/' + path;
    print(url);
    setState(() {
      loading = true;
    });
    Dio dio = Dio();
    try {
      Response response = await dio.get(url);
      print(response.data);
      List _cotacoes = response.data;
      cotacoes.clear();
      if (_cotacoes.isNotEmpty) {
        for (var i = 0; i < _cotacoes.length; i++) {
          Cotacao _tempCotacao = Cotacao.fromJson(_cotacoes[i]);
          cotacoes.add(_tempCotacao);
        }
      }
      setState(() {
        error = false;
      });
    } catch (e) {
      setState(() {
        error = true;
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  List value;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          actions: <Widget>[
            PopupMenuButton<String>(
              onSelected: (String option) async {
                _loadCotacoes(path: removeDiacritics(option.toLowerCase()));
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
            await _loadCotacoes();
          },
          child: loading
              ? Center(child: CircularProgressIndicator())
              : error
                  ? _messageWidget(message: 'Erro ao carregar cotações!')
                  : cotacoes.isEmpty
                      ? _messageWidget(
                          message: 'Não há nenhuma cotação disponível!')
                      : Center(
                          child: ListView.builder(
                              itemCount: cotacoes.length,
                              itemBuilder: (context, index) {
                                Cotacao _cotacao = cotacoes[index];
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
                  await _loadCotacoes();
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

  factory Cotacao.fromJson(dynamic json) => Cotacao(
        id: double.parse(json['id'].toString()),
        data: DateTime.parse(json['data'].toString()),
        cotacao: double.parse(json['cotacao'].toString()),
        variacao: double.parse(json['variacao'].toString()),
      );
}
