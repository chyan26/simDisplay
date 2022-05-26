import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:image/image.dart' as img_decode;


final List<File?> fileData = [];
int? interval = 30;

void main() => runApp(CarouselDemo());

final themeMode = ValueNotifier(2);

class CarouselDemo extends StatelessWidget {

  Future<void> _requestAssets() async {
    // Request permissions.
    final PermissionState _ps = await PhotoManager.requestPermissionExtend();
    if (_ps.isAuth) {
       final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList();
       List<AssetEntity> media = await paths[0].getAssetListPaged(page: 0, size: 20);
       for (int i = 0; i < media.length; i++) {
          fileData.add(await media[i].file);
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    _requestAssets();

    return ValueListenableBuilder(
      builder: (context, value, g) {
        return MaterialApp(
          initialRoute: '/',
          darkTheme: ThemeData.dark(),
          themeMode: ThemeMode.values.toList()[value as int],
          debugShowCheckedModeBanner: false,
          routes: {
            '/': (ctx) => CarouselDemoHome(),
            '/basic': (ctx) => BasicDemo(),
            '/setting': (ctx) => AppSetting(),
            '/yourpage': (ctx) => onTapHide(),
            '/image': (ctx) => Gallery(),
            //'/fullscreen': (ctx) => FullscreenSliderDemo(),
           },
        );
      },
      valueListenable: themeMode,
    );
  }
}

class DemoItem extends StatelessWidget {
  final String title;
  final String route;
  DemoItem(this.title, this.route);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      onTap: () {
        Navigator.pushNamed(context, route);
      },
    );
  }
}

class CarouselDemoHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('StarTracker Display'),
        actions: [
          IconButton(
              icon: Icon(Icons.nightlight_round),
              onPressed: () {
                themeMode.value = themeMode.value == 1 ? 2 : 1;
              })
        ],
      ),
      body: ListView(
        children: <Widget>[
          DemoItem('Single image mode', '/basic'),
          DemoItem('Display Setting', '/setting'),
          DemoItem('Start Image Display', '/yourpage'),
          DemoItem('Total image', '/image'),
          //DemoItem('Fullscreen carousel slider', '/fullscreen'),

        ],
      ),
    );
  }
}
class AppSetting extends StatelessWidget {
  const AppSetting({Key? key}) : super(key: key);

  //static const String _title = 'Flutter Code Sample';

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      //title: _title,
      home: Scaffold(
        appBar: AppBar(title: Text('App Setting')),
        body: _Sliders(),
      ),
    );
  }
}

class _Sliders extends StatefulWidget {
  @override
  _SlidersState createState() => _SlidersState();
}

class _SlidersState extends State<_Sliders> with RestorationMixin {
  final RestorableDouble _continuousValue = RestorableDouble(30);
  //final RestorableDouble _discreteValue = RestorableDouble(20);

  @override
  String get restorationId => 'slider_demo';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_continuousValue, 'continuous_value');
    //registerForRestoration(_discreteValue, 'discrete_value');
  }

  @override
  void dispose() {
    _continuousValue.dispose();
    //_discreteValue.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //print(_continuousValue.value.toInt());
    //final localizations = GalleryLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                label: 'Setting',
                child: SizedBox(
                  width: 64,
                  height: 48,
                  child: TextField(
                    textAlign: TextAlign.center,
                    onSubmitted: (value) {
                      final newValue = double.tryParse(value);
                      if (newValue != null &&
                          newValue != _continuousValue.value) {
                        setState(() {
                          _continuousValue.value =
                          newValue.clamp(0, 1000) as double;
                        });
                      }
                    },
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(
                      text: _continuousValue.value.toStringAsFixed(0),
                    ),
                  ),
                ),
              ),
              Slider(
                value: _continuousValue.value,
                min: 0,
                max: 300,
                onChanged: (value) {
                  setState(() {
                    _continuousValue.value = value;
                    interval = value.toInt();
                  });
                },
              ),
              Text('Setting the interval'),
            ],
          ),
          const SizedBox(height: 80),
          //interval = _continuousValue.value.toInt().toInt();
        ],
      ),
    );
  }


}

Uint8List get_decode_image(File? item){
  var data;
  data = item!.readAsBytesSync();
  img_decode.Image image = img_decode.decodeImage(data)!;
  var newData = Uint8List.fromList(img_decode.encodeBmp(image));
  return newData;
}

class BasicDemo extends StatelessWidget {



  @override
  Widget build(BuildContext context) {
    final double height = MediaQuery.of(context).size.height;
    return Scaffold(
      //appBar: AppBar(title: Text('Basic Demo')),
      body: Container(
          child: CarouselSlider(
            options: CarouselOptions(
              viewportFraction: 1.0,
              height: height,
            ),
            items: fileData
                .map((item) => Container(
              child: Center(
                  child: Image.memory(
                      get_decode_image(item),
                      fit: BoxFit.fitHeight,
                      scale: 1.0,
                      height: 900,
                      width: 900)),
              color: Colors.black,
            ))
                .toList(),
          )),
    );
  }
}



class Gallery extends StatefulWidget {
  @override
  _GalleryState createState() => _GalleryState();
}

class _GalleryState extends State<Gallery> {
  // This will hold all the assets we fetched
  List<AssetEntity> assets = [];
  _fetchAssets() async {
    // Set onlyAll to true, to fetch only the 'Recent' album
    // which contains all the photos/videos in the storage
    final albums = await PhotoManager.getAssetPathList(onlyAll: true);
    final recentAlbum = albums.first;

    // Now that we got the album, fetch all the assets it contains
    final recentAssets = await recentAlbum.getAssetListRange(
      start: 0, // start at index 0
      end: 1000000, // end at a very big index (to get all the assets)
    );

    // Update the state and notify UI
    setState(() => assets = recentAssets);
  }
  @override
  void initState() {
    _fetchAssets();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Gallery'),
        ),
        body: Center(
          // Modify this line as follows
          child: Text('There are ${assets.length} assets'),

        )
    );
  }
}

class onTapHide extends StatefulWidget {
  @override
  _onTapHidePage createState() => _onTapHidePage();
}

class _onTapHidePage extends State<onTapHide> {
  bool _showAppBar = true;

  @override
  Widget build(BuildContext context) {
    //print(interval);

    final double height = MediaQuery.of(context).size.height;
    final double width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: _showAppBar ? AppBar(title: Text('Tap to hide')) : null,
      body: Center(
        child: GestureDetector(
          onTap: () => setState(() => _showAppBar = !_showAppBar),
          child: Container(
            child: CarouselSlider(
                options: CarouselOptions(
                  autoPlay: true,
                  autoPlayInterval: Duration(milliseconds: interval!),
                  autoPlayAnimationDuration: Duration(milliseconds: 1),
                  height: height,
                  viewportFraction: 1.0,
                  enlargeCenterPage: false,
                ),
                items: fileData
                    .map((item) => Container(
                  child: Image.memory(
                      get_decode_image(item),
                      scale: 1.0,
                      fit: BoxFit.fitHeight,
                      width: width),
                  color: Colors.black,
                ))
                    .toList(),
            )
          ),
        ),
      ),
    );
  }
}

