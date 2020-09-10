import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'music.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import 'package:audioplayer2/audioplayer2.dart';
import 'package:volume/volume.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "YeeziMusic",
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MyHomePage(title: "YeeziMusic"),
      debugShowCheckedModeBanner: false,
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
  AudioPlayer audioPlayer;
  StreamSubscription positionSub;
  StreamSubscription stateSub;

  Music actualMusic;
  Duration position = new Duration(seconds: 0);
  Duration duree = new Duration(seconds: 30);
  int index = 0;
  PlayerState statut = PlayerState.STOPPED;
  bool mute = false;
  int maxVol = 0, currentVol = 0;

  List<Music> musicList = [
    new Music("Ramadan", "Ahmad", "assets/img/ramadan.jpg",
        "https://testabilisation.000webhostapp.com/musicApp/Ramdam.mp3"),
    new Music("Surah Yusuf", "Yusuf", "assets/img/SurahYusuf.jpg",
        "https://testabilisation.000webhostapp.com/musicApp/Yusuf_Islam_Our_Guide_Is_The_Quran.mp3"),
    new Music("Dua al qunut", "Mishary", "assets/img/qunoot.jpg",
        "https://testabilisation.000webhostapp.com/musicApp/dua%20al%20qunut.mp3")
  ];

  @override
  void initState() {
    super.initState();
    actualMusic = musicList[index];
    configAudioPlayer();
    initPlatfomState();
    updatevolume();
  }

  @override
  Widget build(BuildContext context) {
    double largeur = MediaQuery.of(context).size.width;
    int newVol = getVolumePercent().toInt();
    return Scaffold(
      appBar: AppBar(
        title: new Text(widget.title),
        centerTitle: true,
        elevation: 20,
        backgroundColor: Colors.pink[200],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            new Container(
              width: 200,
              //margin: EdgeInsets.only(top: 20),
              child: new Image.asset(actualMusic.imagePath),
            ),
            new Container(
              margin: EdgeInsets.only(top: 20),
              child: new Text(
                actualMusic.title,
                textScaleFactor: 2,
              ),
            ),
            new Container(
              margin: EdgeInsets.only(top: 5),
              child: new Text(
                actualMusic.author,
              ),
            ),
            new Container(
              height: largeur / 5,
              margin: EdgeInsets.only(left: 10, right: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  new IconButton(
                      icon: new Icon(Icons.fast_rewind), onPressed: rewind),
                  new IconButton(
                      icon: (statut != PlayerState.PLAYING)
                          ? new Icon(Icons.play_arrow)
                          : new Icon(Icons.pause),
                      iconSize: 50,
                      onPressed:
                          (statut != PlayerState.PLAYING) ? play : pause),
                  new IconButton(
                      icon: new Icon(Icons.fast_forward), onPressed: forward),
                  new IconButton(
                      icon: (mute)
                          ? new Icon(Icons.headset_off)
                          : new Icon(Icons.headset),
                      onPressed: muted),
                ],
              ),
            ),
            new Container(
              margin: EdgeInsets.only(left: 10, right: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  textWithStyle(fromDuration(position), 0.8),
                  textWithStyle(fromDuration(duree), 0.8)
                ],
              ),
            ),
            new Container(
              margin: EdgeInsets.only(left: 10, right: 10),
              child: new Slider(
                  value: position.inSeconds.toDouble(),
                  min: 0.0,
                  max: duree.inSeconds.toDouble(),
                  inactiveColor: Colors.grey,
                  activeColor: Colors.deepPurpleAccent,
                  onChanged: (double d) {
                    setState(() {
                      audioPlayer.seek(d);
                    });
                  }),
            ),
            new Container(
              height: largeur / 4,
              margin: EdgeInsets.only(left: 0, right: 0, top: 0),
              child: new Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  new IconButton(
                    icon: new Icon(Icons.remove),
                    iconSize: 18,
                    onPressed: () {
                      if (!mute) {
                        volDown();
                        updatevolume();
                      }
                    },
                  ),
                  new Slider(
                      value: (mute) ? 0.0 : currentVol.toDouble(),
                      min: 0.0,
                      max: maxVol.toDouble(),
                      inactiveColor: (mute) ? Colors.red : Colors.grey[500],
                      activeColor: (mute) ? Colors.red : Colors.blue,
                      onChanged: (double d) {
                        setState(() {
                          if (!mute) {
                            Volume.setVol(d.toInt());
                            updatevolume();
                          }
                        });
                      }),
                  new Text((mute) ? 'Mute' : '$newVol%'),
                  new IconButton(
                    icon: new Icon(Icons.add),
                    iconSize: 18,
                    onPressed: () {
                      if (!mute) {
                        volUp();
                        updatevolume();
                      }
                    },
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  double getVolumePercent() {
    return (currentVol / maxVol) * 100;
  }

  ///Initialiser le volume
  Future<void> initPlatfomState() async {
    await Volume.controlVolume(AudioManager.STREAM_MUSIC);
  }

  ///Update le volume
  updatevolume() async {
    maxVol = await Volume.getMaxVol;
    currentVol = await Volume.getVol;
    setState(() {});
  }

  ///Définir le volume
  setVol(int i) async {
    await Volume.setVol(i);
  }

  volDown() async {
    setVol(currentVol - 1);
  }

  volUp() async {
    setVol(currentVol + 1);
  }

  ///Gestion des Texte avec style
  Text textWithStyle(String data, double scale) {
    return new Text(
      data,
      textScaleFactor: scale,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.black,
        fontSize: 15,
      ),
    );
  }

  ///Gestion des boutons
  IconButton button(IconData icon, double height, ActionMusic actionMusic) {
    return new IconButton(
      icon: new Icon(icon),
      iconSize: height,
      color: Colors.black,
      onPressed: () {
        switch (actionMusic) {
          case ActionMusic.PLAY:
            play();
            break;
          case ActionMusic.PAUSE:
            pause();
            break;
          case ActionMusic.REWIND:
            rewind();
            break;
          case ActionMusic.FORWARD:
            forward();
            break;
          default:
            break;
        }
      },
    );
  }

  /// Configutration de l'AudioPlayer
  void configAudioPlayer() {
    audioPlayer = new AudioPlayer();
    positionSub = audioPlayer.onAudioPositionChanged.listen((event) {
      setState(() {
        position = event;
      });
      if (position >= duree) {
        position = new Duration(seconds: 0);
        // PASSER À LA MUSIQUE SUIVANTE (forward)
      }
    });
    stateSub = audioPlayer.onPlayerStateChanged.listen((event) {
      if (event == AudioPlayerState.PLAYING) {
        setState(() {
          duree = audioPlayer.duration;
        });
      } else if (event == AudioPlayerState.STOPPED) {
        setState(() {
          statut = PlayerState.STOPPED;
        });
      }
    }, onError: (msg) {
      print("aaa" + msg);
      setState(() {
        statut = PlayerState.STOPPED;
        duree = new Duration(seconds: 0);
        position = new Duration(seconds: 0);
      });
    });
  }

  Future<void> play() async {
    await audioPlayer.play(actualMusic.musicURL);
    setState(() {
      statut = PlayerState.PLAYING;
    });
  }

  Future<void> pause() async {
    await audioPlayer.pause();
    setState(() {
      statut = PlayerState.PAUSED;
    });
  }

  Future<void> muted() async {
    await audioPlayer.mute(!mute);
    setState(() {
      mute = !mute;
    });
  }

  /// Passer  à la musique suivante
  void forward() {
    if (index == (musicList.length - 1)) {
      index = 0;
    } else {
      index++;
    }
    actualMusic = musicList[index];
    audioPlayer.stop();
    configAudioPlayer();
    play();
  }

  /// Retour  à la musique précédente
  void rewind() {
    if (index == 0) {
      audioPlayer.seek(0);
      index = musicList.length - 1;
    } else {
      index--;
    }
    actualMusic = musicList[index];
    audioPlayer.stop();
    configAudioPlayer();
    play();
  }

  String fromDuration(Duration dure) {
    return dure.toString().split(".").first;
  }
}

enum ActionMusic { PLAY, PAUSE, REWIND, FORWARD }

enum PlayerState { PLAYING, STOPPED, PAUSED }
