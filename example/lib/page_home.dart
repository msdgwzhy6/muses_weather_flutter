import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:muses_weather_flutter_example/model/weather_info.dart';
import 'package:muses_weather_flutter_example/page_cities.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  String id;
  HomePage(this.id);
  @override
  State<StatefulWidget> createState() {
    return new _HomePageState(id);
  }
}

class _HomePageState extends State<HomePage> {
  double screenWidth = 0.0;
  File _image;
  List citiesMap;
  String extraId;
  _HomePageState(this.extraId);
  WeatherInfo weatherInfo = new WeatherInfo(
      realtime: new Realtime(),
      pm25: new PM25(),
      indexes: new List(),
      weathers: new List());

  Future getImage() async {
    var image = await ImagePicker.pickImage(source: ImageSource.gallery);
    setState(() {
      _image = image;
      _setImagePath(_image.path);
    });
  }

  @override
  void initState() {
    if(extraId != null){
      _fetchWeatherInfo(extraId);
    }else{
      _getCityId().then((id) {
        if (id != "") {
          _fetchWeatherInfo(id);
        } else {
          _fetchWeatherInfo("101010100");
        }
      });
    }
    _getImagePath();
    _loadCities();
  }

  @override
  Widget build(BuildContext context) {
    final searchController = TextEditingController();
    final theme = Theme.of(context);
    return new MaterialApp(
      home: new Scaffold(
        resizeToAvoidBottomPadding: false, //false键盘弹起不重新布局 避免挤压布局
        body: new Stack(
          children: <Widget>[
            new Container(
              child: _image == null
                  ? new Image.asset("images/bg.jpg", fit: BoxFit.fitHeight)
                  : new Image.file(_image, fit: BoxFit.fitHeight),
              width: double.infinity,
              height: double.infinity,
            ),
            SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Container(
                padding: EdgeInsets.only(top: 30.0),
                decoration: BoxDecoration(
                    color: Color(
                  0x66000000,
                )),
                child: Column(
                  children: <Widget>[
                    Container(
                      child: InkWell(
                        child: Icon(
                          Icons.list,
                          color: Colors.white,
                        ),
                        onTap: (){
                          Navigator.push<String>(context, new MaterialPageRoute(builder: (BuildContext context){
                            return new Cities();
                          }));
                        },
                      ),
                      padding: EdgeInsets.only(top: 5.0,right: 20.0),
                      alignment: Alignment.centerRight,
                    ),
                    Container(
                        margin: EdgeInsets.only(left: 20.0, right: 20.0),
                        child: new Theme(
                          data: theme.copyWith(primaryColor: Colors.white),
                          child: new TextField(
                            controller: searchController,
                            textInputAction: TextInputAction.search,
                            onSubmitted: (String _) {
                              _fetchWeatherInfo(_getIdByName(_));
                            },
                            maxLines: 1,
                            style: TextStyle(
                                fontSize: 16.0, color: Colors.white), //输入文本的样式
                            decoration: InputDecoration(
                              hintText: '查询其他城市',
                              hintStyle: TextStyle(
                                  fontSize: 14.0, color: Colors.white),
                              prefixIcon: new Icon(
                                Icons.search,
                                color: Colors.white,
                                size: 20.0,
                              ),
                            ),
                          ),
                        )),
                    Container(
                      margin: EdgeInsets.only(top: 30.0),
                      child: Text(
                        weatherInfo.city == null ? "XX" : weatherInfo.city,
                        style: new TextStyle(
                            fontSize: 18.0,
                            color: Colors.white,
                            fontWeight: FontWeight.w100),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.only(top: 5.0),
                      child: Text(
                        weatherInfo.realtime.time == null
                            ? " "
                            : weatherInfo.realtime.time.split(" ")[1] + " 更新",
                        style: TextStyle(color: Colors.white, fontSize: 12.0),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 40.0),
                      child: Text(
                        (weatherInfo.realtime.temp ??= "XX") + "℃",
                        style: new TextStyle(
                            fontSize: 80.0,
                            color: Colors.white,
                            fontWeight: FontWeight.w300),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 20.0),
                      child: Text(
                        weatherInfo.realtime.weather ??= "XX",
                        style: new TextStyle(
                            fontSize: 16.0,
                            color: Colors.white,
                            fontWeight: FontWeight.w100),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 20.0),
                      child: Text(
                        (weatherInfo.realtime.wD ??= "") +
                            " " +
                            (weatherInfo.realtime.wS ??= ""),
                        style: new TextStyle(
                            fontSize: 16.0,
                            color: Colors.white,
                            fontWeight: FontWeight.w100),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 15.0),
                      child: new Material(
                        borderRadius: BorderRadius.circular(10.0),
                        color: Colors.grey,
                        child: Container(
                          padding: EdgeInsets.only(
                              left: 5.0, right: 5.0, top: 2.0, bottom: 2.0),
                          child: Text(
                            (weatherInfo.pm25.aqi ??= "00") +
                                " " +
                                (weatherInfo.pm25.quality ??= "未知"),
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 20.0),
                      color: Color(0x3399CCFF),
                      child: Row(
                        children: _buildFutureWeathers(weatherInfo.weathers),
                      ),
                    ),
                    Column(
                      children: _buildLivingIndexes(weatherInfo.indexes),
                    ),
                    Padding(padding: EdgeInsets.only(top: 20.0)),
                    InkWell(
                      onTap: () {
                        getImage();
                      },
                      child: Text(
                        "自定义背景",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    Padding(padding: EdgeInsets.only(top: 20.0)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFutureWeathers(List<Weather> weathers) {
    List<Widget> widgets = new List();
    if (weathers.length > 0) {
      int index = 0;

      for (Weather weather in weathers) {
        widgets.add(_buildFutureWeather(
            index == 0 ? "今天" : weather.week,
            weather.weather,
            weather.temp_day_c + " ~ " + weather.temp_night_c));
        index++;
        if (index == 5) {
          break;
        }
      }
    }
    return widgets;
  }

  Widget _buildFutureWeather(String week, String weather, String temp) {
    return new Expanded(
      flex: 1,
      child: new Column(
        children: <Widget>[
          Padding(padding: EdgeInsets.only(top: 10.0)),
          Text(
            week,
            style: TextStyle(color: Colors.white),
          ),
          Padding(padding: EdgeInsets.only(top: 10.0)),
          Text(
            temp + "℃",
            style: TextStyle(color: Colors.white),
          ),
          Padding(padding: EdgeInsets.only(top: 10.0)),
          Text(
            weather,
            style: TextStyle(color: Colors.white),
          ),
          Padding(padding: EdgeInsets.only(top: 10.0)),
        ],
      ),
    );
  }

  List<Widget> _buildLivingIndexes(List<Index> indexes) {
    List<Widget> widgets = new List();
    if (indexes.length > 0) {
      for (Index index in indexes) {
        widgets.add(_buildLivingIndex(index));
      }
    }
    return widgets;
  }

  Widget _buildLivingIndex(Index index) {
    return new Container(
      color: Color(0x3399CCFF),
      margin: EdgeInsets.only(top: 10.0),
      padding:
          EdgeInsets.only(left: 15.0, right: 15.0, top: 10.0, bottom: 10.0),
      child: Row(
        children: <Widget>[
          Image.asset("images/" + index.abbreviation + ".png",
              width: 40.0, fit: BoxFit.fitWidth),
          Padding(padding: EdgeInsets.only(right: 10.0)),
          Column(
            children: <Widget>[
              Container(
                child: Text(index.name + " " + index.level,
                    style: TextStyle(color: Colors.white)),
                width: 280.0,
              ),
              Padding(padding: EdgeInsets.only(top: 10.0)),
              Container(
                child: Text(index.content,
                    style: TextStyle(color: Colors.white, fontSize: 12.0)),
                width: 280.0,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<String> _loadCitiesAsset() async {
    return await rootBundle.loadString('data/cities.json');
  }

  Future _loadCities() async {
    String jsonString = await _loadCitiesAsset();
    citiesMap = json.decode(jsonString)['cities'];
  }

  _getImagePath() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String path = prefs.get("bgpath");
    if (path != null) {
      setState(() {
        _image = new File(path);
      });
    }
  }

  _setImagePath(String path) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("bgpath", path);
  }

  _setCityId(String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("cityid", id);
  }

  _setCitiesId(String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> ids = prefs.getStringList("citiesids");
    if (ids == null) {
      ids = new List();
    }
    if(!ids.contains(id)){
      ids.add(id);
    }
    await prefs.setStringList("citiesids", ids);
  }

  Future<String> _getCityId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String id = prefs.get("cityid");
    if (id != null) {
      return id;
    }
    return "";
  }

  String _getIdByName(String name) {
    if (citiesMap.length > 0) {
      for (Map map in citiesMap) {
        if (map['city'] == name) {
          return map['cityid'];
        }
      }
    }
  }

  _fetchWeatherInfo(String id) async {
    var httpClient = new HttpClient();
    var uri = new Uri.http(
        'aider.meizu.com', '/app/weather/listWeather', {'cityIds': id});
    var request = await httpClient.getUrl(uri);
    var response = await request.close();
    try {
      if (response.statusCode == HttpStatus.ok) {
        _setCityId(id);
        _setCitiesId(id);
        var json = await response.transform(Utf8Decoder()).join();
        Map map = jsonDecode(json);
        print(map["value"][0].toString());
        setState(() {
          weatherInfo = WeatherInfo.fromJson(map["value"][0]);
        });
        print(weatherInfo.city);
      } else {
        print("============data is empty==============");
      }
    } catch (exception) {
      print("=============" + exception.toString() + "===============");
    }
  }
}
