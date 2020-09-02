import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:my_idena/backoffice/bean/dna_all.dart';
import 'package:my_idena/backoffice/factory/connectivity_service.dart';
import 'package:my_idena/backoffice/factory/httpService.dart';
import 'package:my_idena/beans/deepLinkParam.dart';
import 'package:my_idena/enums/connection_status.dart';
import 'package:my_idena/myIdena_app/myIdena_app_theme.dart';
import 'package:my_idena/pages/myIdena_home.dart';
import 'package:my_idena/pages/screens/on_boarding_screen.dart';
import 'package:my_idena/utils/app_localizations.dart';
import 'package:logger/logger.dart';
import 'package:my_idena/utils/util_deepLinks.dart';
import 'package:ntp/ntp.dart';
import 'package:provider/provider.dart';
import 'package:uni_links/uni_links.dart';
import 'package:url_launcher/url_launcher.dart';

DnaAll dnaAll = new DnaAll();
var logger = Logger();
String campaign = "v20200831.1";
DeepLinkParam deepLinkParam;
HttpService httpService = HttpService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown
  ]).then((_) => runApp(MyApp()));
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

enum UniLinksType { string, uri }

class _MyAppState extends State<MyApp> with SingleTickerProviderStateMixin {
  bool timeOk = false;
  bool nodeOk = false;

  @override
  initState() {
    super.initState();
    // initPlatformState();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness:
          Platform.isAndroid ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarDividerColor: Colors.grey,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
    return StreamProvider<ConnectivityStatus>(
        create: (contextStream) =>
            ConnectivityService().connectionStatusController.stream,
        child: MaterialApp(
            debugShowCheckedModeBanner: false,
            supportedLocales: [
              Locale('en', ''),
              Locale('fr', ''),
              Locale('ru', ''),
              Locale('cn', 'SC'),
              Locale('cn', 'TC'),
              Locale('sr', ''),
              Locale('sr', 'RS'),
            ],
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            theme: ThemeData(
              primarySwatch: Colors.grey,
              textTheme: MyIdenaAppTheme.textTheme,
              platform: TargetPlatform.iOS,
            ),
            home: StreamBuilder(
              stream: getLinksStream(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  var uri = Uri.parse(snapshot.data);
                  var list = uri.queryParametersAll.entries.toList();
                  deepLinkParam = new DeepLinkParam();
                  for (var i = 0; i < list.length; i++) {
                    switch (list[i].key) {
                      case "nonce_endpoint":
                        {
                          deepLinkParam.nonceEndpoint = list[i].value[0];
                        }
                        break;
                      case "token":
                        {
                          deepLinkParam.token = list[i].value[0];
                        }
                        break;
                      case "callback_url":
                        {
                          deepLinkParam.callbackUrl = list[i].value[0];
                        }
                        break;
                      case "authentication_endpoint":
                        {
                          deepLinkParam.authenticationEndpoint =
                              list[i].value[0];
                        }
                        break;
                    }
                  }
                  logger.i("nonce_endpoint: " + deepLinkParam.nonceEndpoint);
                  logger.i("token: " + deepLinkParam.token);
                  logger.i("callback_url: " + deepLinkParam.callbackUrl);
                  logger.i("authentication_endpoint: " +
                      deepLinkParam.authenticationEndpoint);
                  Timer.run(() {
                    onAfterBuild(context);
                  });

                  return Home();
                } else {
                  getStart();
                  if (nodeOk && timeOk) {
                    return Home();
                  } else {
                    return OnBoardingScreen();
                  }
                }
              },
            )));
  }

  void onAfterBuild(BuildContext context) {
    if (deepLinkParam != null) {
      showDialog(
          context: context,
          builder: (context) => SimpleDialog(
                contentPadding: EdgeInsets.zero,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Column(
                      children: <Widget>[
                        Text(
                          AppLocalizations.of(context)
                              .translate("Login confirmation"),
                          style: TextStyle(
                              fontFamily: MyIdenaAppTheme.fontName,
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                              letterSpacing: -0.1,
                              color: MyIdenaAppTheme.darkText),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 20,
                            ),
                            Text(AppLocalizations.of(context).translate(
                                "Please confirm that you want to use your public address for the website login")),
                            SizedBox(
                              height: 20,
                            ),
                            Text(
                              "Website: ",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: MyIdenaAppTheme.fontName,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                letterSpacing: -0.2,
                                color: MyIdenaAppTheme.darkText,
                              ),
                            ),
                            Text(deepLinkParam.nonceEndpoint != null
                                ? UtilDeepLinks()
                                    .getHostname(deepLinkParam.nonceEndpoint)
                                : ""),
                            SizedBox(
                              height: 20,
                            ),
                            Text(
                              "Address: ",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: MyIdenaAppTheme.fontName,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                letterSpacing: -0.2,
                                color: MyIdenaAppTheme.darkText,
                              ),
                            ),
                            Text(
                              dnaAll.dnaIdentityResponse.result.address != null
                                  ? dnaAll.dnaIdentityResponse.result.address
                                  : "",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: MyIdenaAppTheme.fontName,
                                fontSize: 13,
                                letterSpacing: -0.2,
                                color: MyIdenaAppTheme.darkText,
                              ),
                            ),
                            Image.network(
                              'https://robohash.org/${dnaAll.dnaIdentityResponse.result.address}',
                              width: 50,
                              height: 50,
                            ),
                            SizedBox(
                              height: 20,
                            ),
                            Text(
                              "Token: ",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: MyIdenaAppTheme.fontName,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                letterSpacing: -0.2,
                                color: MyIdenaAppTheme.darkText,
                              ),
                            ),
                            Text(deepLinkParam.token != null
                                ? deepLinkParam.token
                                : ""),
                            SizedBox(
                              height: 20,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                FlatButton(
                                    child: Text(
                                      AppLocalizations.of(context)
                                          .translate("Submit"),
                                    ),
                                    color: Colors.grey[200],
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(20.0)),
                                    onPressed: () {
                                      deepLinkParam.address = dnaAll
                                          .dnaIdentityResponse.result.address;
                                      _launchDeepLink(deepLinkParam);
                                      setState(() {
                                        Navigator.pop(context);
                                      });
                                    }),
                                FlatButton(
                                    child: Text(
                                      AppLocalizations.of(context)
                                          .translate("Cancel"),
                                    ),
                                    color: Colors.grey[200],
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(20.0)),
                                    onPressed: () {
                                      setState(() {
                                        Navigator.pop(context);
                                      });
                                    })
                              ],
                            ),
                          ],
                        )
                      ],
                    ),
                  )
                ],
              ));
    }
  }

  _launchDeepLink(deepLinkParam) async {
    deepLinkParam = await UtilDeepLinks().getNonce(deepLinkParam);
    deepLinkParam = await httpService.signin(deepLinkParam);
    deepLinkParam = await UtilDeepLinks().authenticate(deepLinkParam);
    if (await canLaunch(deepLinkParam.callback_url)) {
      await launch(deepLinkParam.callback_url);
    } else {
      logger.e('Could not  launch $deepLinkParam.callback_url');
    }
  }

  Future<void> getDifferenceTime() async {
    timeOk = false;
    try {
      DateTime _myTime = await NTP.now();
      final int offset = await NTP.getNtpOffset(localTime: DateTime.now());
      DateTime _ntpTime = _myTime.add(Duration(milliseconds: offset));
      int _differenceTime = _myTime.difference(_ntpTime).inMilliseconds;
      if (_differenceTime != null && _differenceTime.abs() <= 2000) {
        timeOk = true;
      }
    } catch (e) {}
  }

  Future<void> getStart() async {
    await getDifferenceTime();
    nodeOk = false;
    return FutureBuilder(
        future: httpService.getDnaAll(),
        // ignore: missing_return
        builder: (BuildContext context, AsyncSnapshot<DnaAll> snapshot) {
          if (snapshot.hasData) {
            dnaAll = snapshot.data;
            if (dnaAll != null && dnaAll.dnaIdentityResponse != null) {
              nodeOk = true;
            }
          }
        });
  }
}
