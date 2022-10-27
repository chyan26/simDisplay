import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:image/image.dart' as img_decode;
import 'package:flutter/services.dart' show FilteringTextInputFormatter, rootBundle;


final List<File?> fileData=[];
final List<File?> assetData = [];
int? interval = 2000;

final themeMode = ValueNotifier(2);

Future<File> getImageFileFromAssets(String path) async {
  final byteData = await rootBundle.load(path);

  final file = File('/data/data/com.asiaa.sim_display/cache/test.tiff');
  await file.writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));

  return file;
}

void main() => runApp(const CarouselDemo());


class CarouselDemo extends StatelessWidget {

  const CarouselDemo({Key? key}) : super(key: key);

  Future<void> _requestAssets() async {
    // Request permissions.
    final PermissionState _ps = await PhotoManager.requestPermissionExtend();

    assetData.add(await getImageFileFromAssets('images/simStarTracker_matrix.tiff'));
    print(assetData.length);
    if (_ps.isAuth) {
       final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList();
       for (int i = 0; i< paths.length; i++){
            if (paths[i].name == 'Pictures'){
                print('We have pictures');
                List<AssetEntity> media = await paths[i].getAssetListRange(start: 0, end: 1000);
                for (int j = 0; j < media.length; j++) {
                  //print(media[j].file.);
                  fileData.add(await media[j].file);
                }
                fileData.sort((a, b) => a!.path.compareTo(b!.path));
                print(fileData.length);
            }
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
            '/matrix': (ctx) => MatrixDemo(),
            '/basic': (ctx) => BasicDemo(),
            '/setting': (ctx) => AppSetting(),
            '/yourpage': (ctx) => onTapHide(),
            '/image': (ctx) => Gallery(),
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
  const CarouselDemoHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('StarTracker Display'),
        actions: [
          IconButton(
              icon: const Icon(Icons.nightlight_round),
              onPressed: () {
                themeMode.value = themeMode.value == 1 ? 2 : 1;
              })
        ],
      ),
      body: ListView(
        children: <Widget>[
          DemoItem('Display matrix image', '/matrix'),
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
        appBar: AppBar(title: const Text('App Setting')),
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
                          interval = newValue.toInt();
                        });
                      }
                    },
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly
                    ],
                    controller: TextEditingController(
                      text: _continuousValue.value.toStringAsFixed(0),
                    ),
                  ),
                ),
              ),
              Slider(
                value: _continuousValue.value,
                min: 0,
                max: 2000,
                onChanged: (value) {
                  setState(() {
                    _continuousValue.value = value;
                    interval = value.toInt();
                  });
                },
              ),
              const Text('Setting the interval'),
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
  var newData = Uint8List.fromList(img_decode.encodeJpg(image));
  return newData;
}


class MatrixDemo extends StatelessWidget {
  const MatrixDemo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double height = MediaQuery.of(context).size.height;
    return Scaffold(
      //appBar: AppBar(title: Text('Basic Demo')),
      body: CarouselSlider(
        options: CarouselOptions(
          viewportFraction: 1.0,
          height: 2434,
          initialPage: 0,
          reverse: false,
          autoPlay: false,
        ),
        items: assetData
            .map((item) => Container(
          color: Colors.black,
          child: Center(
              child: Image.memory(
                  get_decode_image(item),
                  fit: BoxFit.fitHeight,
                  scale: 1.0,
                  height: 2434,
                  width: 1096)),
        ))
            .toList(),
      ),
    );
  }
}


class BasicDemo extends StatelessWidget {
  const BasicDemo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double height = MediaQuery.of(context).size.height;
    return Scaffold(
      //appBar: AppBar(title: Text('Basic Demo')),
      body: Container(
          child: CarouselSlider(
            options: CarouselOptions(
              viewportFraction: 1.0,
              height: 2434,
              initialPage: 0,
              reverse: false,
              autoPlay: false,
            ),
            items: fileData
                .map((item) => Container(
              color: Colors.black,
              child: Center(
                  child: Image.memory(
                      get_decode_image(item),
                      fit: BoxFit.fitHeight,
                      scale: 1.0,
                      height: 2434,
                      width: 1096)),
            ))
                .toList(),
          )),
    );
  }
}

class BasicDemoTIFF extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    final double height = MediaQuery.of(context).size.height;
    return Scaffold(
      //appBar: AppBar(title: Text('Basic Demo')),
      body: Container(
          child: CarouselSlider(
            options: CarouselOptions(
              viewportFraction: 1.0,
              height: 2434,
            ),
            items: fileData
                .map((item) => Container(
              color: Colors.black,
              child: Center(
                  child: Image.file(
                      item!,
                      fit: BoxFit.fitHeight,
                      scale: 1.0,
                      height: 2434,
                      width: 1096)),
            ))
                .toList(),
          )),
    );
  }
}





class Gallery extends StatefulWidget {
  const Gallery({Key? key}) : super(key: key);

  @override
  _GalleryState createState() => _GalleryState();
}

class _GalleryState extends State<Gallery> {
  // This will hold all the assets we fetched
  List<AssetEntity> assets = [];

  _fetchAssets() async {
    // Set onlyAll to true, to fetch only the 'Recent' album
    // which contains all the photos/videos in the storage
    final albums = await PhotoManager.getAssetPathList();
    for (int i = 0; i < albums.length; i++) {
      if (albums[i].name == 'Pictures') {
        final pictureAlbum = albums[i];
        final recentAssets = await pictureAlbum.getAssetListRange(
          start: 0, // start at index 0
          end: 1000000, // end at a very big index (to get all the assets)
        );
        setState(() => assets = recentAssets);
      }
    }
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
          title: const Text('Gallery'),
        ),
        body: Center(
          // Modify this line as follows
          child: Text('There are ${assets.length} assets'),

        )
    );
  }
}

class onTapHide extends StatefulWidget {
  const onTapHide({Key? key}) : super(key: key);
  @override
  _onTapHidePage createState() => _onTapHidePage();
}

class _onTapHidePage extends State<onTapHide> {
  bool _showAppBar = false;

  @override
  Widget build(BuildContext context) {
    print(interval);
    final double height = MediaQuery.of(context).size.height;
    final double ratio = MediaQuery.of(context).devicePixelRatio;
    final double width = MediaQuery.of(context).size.width;
    //print('test =  $height $width $ratio');
    return Scaffold(
      //appBar: _showAppBar ? AppBar(title: const Text('Tap to hide')) : null,
      body: Center(
        child: GestureDetector(
          onTap: () => setState(() => _showAppBar = !_showAppBar),
          child: CarouselSlider(
              options: CarouselOptions(
                autoPlay: true,
                autoPlayInterval: Duration(milliseconds: interval!),
                autoPlayAnimationDuration: const Duration(milliseconds: 1),
                height: 2434,
                viewportFraction: 1.0,
                enlargeCenterPage: false,
                pauseAutoPlayOnTouch: false,
                initialPage: 0,
                reverse: true,
              ),
              items: fileData
                  .map((item) => Container(
                color: Colors.black,
                child: Image.memory(
                    get_decode_image(item),
                    scale: 1.0,
                    fit: BoxFit.fitHeight,
                    width: 1096,
                    height :2434),
              ))
                  .toList(),
          ),
        ),
      ),
    );
  }
}

