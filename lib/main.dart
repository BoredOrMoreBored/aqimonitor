import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:beautifulsoup/beautifulsoup.dart' as soup;
import 'dart:convert';

Future fetchPurpleAir() async{
  final response = await http.get(Uri.parse('https://www.purpleair.com/json?show=36843'));
  if (response.statusCode == 200){
    var json = jsonDecode(response.body);
    var data = json['results'][0]['Stats'];
    return jsonDecode(data)['v1'];
  }else{ 
    throw Exception('Error when pulling data');
  }
}

Future fetchStateAir() async{
  final response = await http.get(Uri.parse('https://www.stateair.mn/'));
  if (response.statusCode == 200){
    var html = soup.Beautifulsoup(response.body);
    var h4 = html.find_all('h4').map((e)=> (e.outerHtml)).toList();
    var text = soup.Beautifulsoup(h4[1]).get_text().split(' ')[0];
    return int.parse(text);
  }else{
    throw Exception('Error when pulling data');
  }
}

Future fetchWeather() async{
  final response = await http.get(Uri.parse('https://api.darksky.net/forecast/aa3ebfa6182e73e45caa906dfb9de93d/47.8864,106.9057'));
  if (response.statusCode == 200){
    return jsonDecode(response.body)['currently'];
  }else{
    throw  Exception('Error when pulling data');
  }
}

//Fix function bellow prob some math shit u can do
double convertAQI(double pmc){
  var values = [];
  if (pmc <= 12.0){
    values = [0,12,0,50];
  } else if (pmc <= 35.4){
    values = [12.1,35.4,51,100];
  } else if (pmc <= 55.4){
    values = [35.5,55.4,101,150];
  } else if (pmc <= 150.4){
    values = [55.5,150.4,151,200];
  } else if (pmc <= 250.4){
    values = [150.5,250.4,201,300];
  } else if (pmc <= 350.4){
    values = [250.5,350.4,301,400];
  }  else if (pmc <= 500.4){
    values = [350.5,500.4,401,500];
  }
  var aqi = (values[3]-values[2]) / (values[1]-values[0]) * (pmc-values[0]) + values[2];
  aqi = double.parse((aqi).toStringAsFixed(2));
  return aqi;
}

List getColor(int cat){
  switch(cat){
      case 1:
        return [Colors.green, 'Good'];
      case 2:
        return [Colors.yellow, 'Moderate'];
      case 3:
        return [Colors.orange, 'Unhealthy for Sensitive Groups'];
      case 4:
        return [Colors.red, 'Unhealthy'];
      case 5:
        return [Colors.purple, 'Very Unhealthy'];
      case 6:
        return [Colors.deepPurple[900], 'Hazardous'];
    }

}

int getCategory(num aqi){
  if (aqi <= 50) {
    return 1;
  }else if (aqi <= 100){
    return 2;
  }else if (aqi <= 150){
    return 3;
  }else if (aqi <= 200){
    return 4;
  }else if (aqi <= 300){
    return 5;
  }else{
    return 6;
  }
}

class AqiDisplay extends StatefulWidget {
  final Function fetch;
  final String dataFrom;

  const AqiDisplay(this.fetch,this.dataFrom);

  @override
  _DisplayState createState() => _DisplayState();
}

class _DisplayState extends State<AqiDisplay> {
  Future data;
  num aqi;
  Color color;
  String text;


  @override
  void initState(){
    data = widget.fetch();
    text = 'No Data';
    color = Colors.grey;
    aqi = null;
    Timer.periodic(Duration(minutes: 1), (Timer t) => _getData());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
            future: data,
            builder: (context, snapshot) {
              if (snapshot.hasData){
                aqi = snapshot.data;
                var style = getColor(getCategory(aqi));
                color = style[0];
                text = style[1];
                var textStyle = _checkAQI(aqi);
                return Container(
                      color: color,
                      height: 170.0,
                      child: Row(
                          children: [
                            Container(
                              width: MediaQuery.of(context).size.width*0.60,
                              padding: const EdgeInsets.all(8.0),
                              child: Center(
                                child: Text(widget.dataFrom + aqi.toString(), style: textStyle)
                                )
                              ),

                            Container(
                              width: MediaQuery.of(context).size.width*0.40,
                              padding: const EdgeInsets.all(8.0),
                              child: Center(
                                child: Text(text, style: textStyle, )
                                )
                            ),
                          ],
                        ),
                );
                
              } else if (snapshot.hasError){
                return Text("${snapshot.error}");
              }
              return Text('Loading...');
            });
            
  }

  TextStyle _checkAQI(num aqi){
    if (aqi > 200){
      return TextStyle(fontSize: 25, color: Colors.white);
    } else {
      return TextStyle(fontSize: 25);
    }
  }

  void _getData(){
    if (DateTime.now().minute == 5){
      final Future updatedData = widget.fetch();
      setState(() {
          data = updatedData;
        });
    }
  }

}

class WeatherMonitor extends StatefulWidget {
  WeatherMonitor();

  @override
  _WeatherMonitor createState() => _WeatherMonitor();
}

class _WeatherMonitor extends State<WeatherMonitor> {
  Future data;
  int fTemp;
  int cTemp;
  String weather;
  num precipProb;
  String precip;

  @override
  void initState(){
    data = fetchWeather();
    Timer.periodic(Duration(minutes: 15), (Timer t) => _getData());
    super.initState();
  }


  @override
  Widget build(BuildContext context){
    return FutureBuilder(
      future: data,
      builder: (context,snapshot){
        if (snapshot.hasData){
          var json = snapshot.data;
          fTemp = json['temperature'].round();
          cTemp = ((fTemp-32) * (5/9)).round();
          weather = json['summary'];
          precipProb = json['precipProbability'];
          precip = json['precipType']; 
          return Container(
            
            child: Row(
              children: [

                Container(
                  width: MediaQuery.of(context).size.width*0.5,
                  padding: const EdgeInsets.all(8.0),
                       
                  child : Column(
                    
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16.0),
                  
                        child: Center(
                          child: Text(fTemp.toString() + ' Fahrenheit', style: TextStyle(fontSize: 20), ),
                          ),
                    ),

                    Container(
                      padding: const EdgeInsets.all(16.0),
                  
                      child: Center(
                        child: Text(cTemp.toString()+ ' Celsius', style: TextStyle(fontSize: 20),),
                        ),
                    ),

                    ],
                  ),
                ),
                
                

                Container(
                  width: MediaQuery.of(context).size.width*0.5,
                  padding: const EdgeInsets.all(8.0),

                  child: 
                    Column(
                      children: [
                        
                        Container(
                          padding: const EdgeInsets.all(8.0),
                          child: Center(
                            child: Text('Forcast: \n' + weather, style: TextStyle(fontSize: 20),),
                            ),
                        ),

                        _checkPrecip(precipProb, precip),

                      ],
                    )
                  ),
                
              ],
              
              )

          );
        } else if (snapshot.hasError){
          return Text('${snapshot.error}');
        }
        return Text('Loading...');
      });
  }

  void _getData(){
    final updateWeather = fetchWeather();
    setState(() {
          data = updateWeather;
        });
  }

  Widget _checkPrecip(precip, type){
    if (precip != 0.00){
      return Container(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: Text('Chance of ' + type + ': \n' + (precip*100).toInt().toString() + '%', style: TextStyle(fontSize: 20),),
          ),
        );
    }else{
      return Container(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: Text('No Chance of Precipitation', style: TextStyle(fontSize: 20),),
          ),
        );
    }

  }

}




/*class HomePage extends StatefulWidget {
  HomePage();

  @overide
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

}*/



class MyApp extends StatefulWidget {
  MyApp();

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final DateFormat mins = DateFormat('hh:mm:ss a');
  String time;


  @override
  void initState() {
    time = mins.format(DateTime.now());
    Timer.periodic(Duration(seconds: 1), (Timer t) => getTime());
    super.initState();
  }

  @override 
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AQI Test',
      home: Scaffold(
        body: Center(
          child: GestureDetector(onHorizontalDragUpdate: (data){
            if (data.delta.dx < 0){

            }
          },
            child: Column(
              children: [
                Container(
                  height: 120,
                  child: Center(child: Text(time,style: TextStyle(fontSize: 20))),
                  ),

                AqiDisplay(()=>fetchPurpleAir(), 'Shangrila AQI: \n'),

                Divider(
                  height: 5,
                  thickness: 5,
                  color: Colors.black,
                ),

                AqiDisplay(()=>fetchStateAir(), 'US Embassy AQI: \n'),

                Divider(
                  height: 5,
                  thickness: 5,
                  color: Colors.black,
                ),
                
                //WeatherMonitor()


              ],
            ),
          ), 
        )
      )
    );
  }

  void getTime(){
    final DateTime now = DateTime.now();
    final String stringNow = mins.format(now);
    setState(() {
          time = stringNow;
        });
  }
}


void main() {
  runApp(MyApp());
}
