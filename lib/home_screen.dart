import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:machinetest_call/notification_services.dart';
import 'package:machinetest_call/utils.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String deviceToken = "";
  NotificationServices notificationServices = NotificationServices();
  List<String> listToken = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    notificationServices.requestNotificationPermission();
    notificationServices.forgroundMessage();
    notificationServices.firebaseInit(context);
    notificationServices.setupInteractMessage(context);
    notificationServices.isTokenRefresh();

    notificationServices.getDeviceToken().then((value) {
      if (kDebugMode) {
        print('device token');
        print(value);
        setState(() {
          deviceToken = value;
        });
        addFirebaseToken(value);
        getFirebaseToken(value);
      }
    });

    disableKeyguard();
  }

  addFirebaseToken(String deviceToken) {
    CollectionReference collectionReference = FirebaseFirestore.instance.collection("users");
    collectionReference.add({"deviceToken": deviceToken});
  }

  getFirebaseToken(String currentDeviceToken) {
    listToken.clear();
    CollectionReference users = FirebaseFirestore.instance.collection('users');

    return users.get().then((QuerySnapshot snapshot) {
      snapshot.docs.forEach((doc) {
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
        if (currentDeviceToken.compareTo(userData["deviceToken"]) != 0 && !listToken.contains(userData["deviceToken"])) {
          listToken.add(userData["deviceToken"]);
        }
        print('${doc.id} => ${doc.data()}');
      });
      print(listToken);
    }).catchError((error) => print("Failed to fetch users: $error"));
  }

  Future<void> disableKeyguard() async {
    const platform = MethodChannel('ShowOnLockScreen');
    try {
      await platform.invokeMethod('disableKeyguard');
      // Handle success
    } on PlatformException catch (e) {
      // Handle error
      print("Failed to disable keyguard: '${e.message}'.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Notifications'),
      ),
      body: Center(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 24.0, right: 24.0, bottom: 24.0),
            child: Text("To grant permission (Settings -> Other Permissions -> Show on Lock Screen)"),
          ),
          ElevatedButton(
              onPressed: () {
                if (listToken.isNotEmpty) {
                  sendCallingNotification(0);
                } else {
                  Utils.showToast("Please install the app on the other device.");
                }
              },
              child: const Text('Call')),
        ],
      )),
    );
  }

  sendCallingNotification(int count) async {
    // send notification from one device to another
    // notificationServices.getDeviceToken().then((value) async {
    try {
      var data = {
        "message": {
          'token': listToken[count],
          'notification': {'title': 'Palash Sethiya', 'body': 'Calling...'},
        }
      };

      await http.post(Uri.parse('https://fcm.googleapis.com/v1/projects/whatsapp-call-7435a/messages:send'), body: jsonEncode(data), headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization':
            'Bearer ya29.c.c0AY_VpZjWf2rNX5aVokoZNfAUQyj23c8FHezT3JPB0-1HwLrVde-I31oWd-HMGnU7MjFmVLhc58ksKKEOnNwKcnY2soK_5J_AWKTJGRVGgUwlJK7e0tmpHibGly29QjtQHHrrq53Xb02w3HwjSEN5kGJ-Jz326v1CAOmSVnwS1jp09QEHXvqnUHpFGonBn8WZXTRa2mV0c8uMb0S8OJrUa-7c5u_JbxLam593ju_gHdOuDwo7vU_-yZCEnNGnq6gHUv1zUNejbvm_bb1gCOZQwA-FMRV2YdO6cBdCyK-cqdlKCsjKKwhapEQ0VHR-WyFZsoTUnfDeNZLH83Y2R2Mih74GjQquLyRNZrtABA0O97C-K4oX4zXQDw9nL385A-jlXkkz8p4blY2WlWURX3eglq0tv_cnB3z0U1xf___ghazmYI7tnjV-MgMFraFZrXnfJiROorMp_2kyhwzpmgl246BFp9Sw1J_3v4kSIrjw9t9OsBFW5f1-gilZjnY5djMpqnecrxq7nbiM3kaQih0vOXbQ4Mq_a_aw5qd2Y3vpnsp3cu_Mos26wi6oYS_-7rg9uOcbWRfseoYWmpXexleV4Zvyaqu1WQZQRrcBMfOoWw08xxfcBVglshQlSI2-oJaRF0hOlw6Jr4Ur_egi3q_OaIrIhsnbyzgY6QraeUR8WB4F0kn6mxtdjxayFvRezczqp1z4OOtiBj2bu-7eq9MxixgzvFnBVO-UScii6QB3SahlVi0QYiOVV51l29Ilo8veZY1FdFYfyOBwJ_h4fqQdJr0lwUVy4eS7dMncVWhBeQgwh3asYl5YqI65ZF7Z9O5i1Sh_SpB1qby98OdaIxMJ6kF4fiBSZSf0iw9rau8QzsRvd1wg4XsyxwRYk-8cwQ9ftc82S2-_4xBsIdj6OxbyRM8J15QbrI7eYzB0SIx07pRhpnY1n8nJwtXSs5F2yxV5wBq92in23dUW_0dgOaI6myvx4Osndf23q1JmBufooZg4-WeW2mxyR9t'
      }).then((value) {
        ++count;
        if (listToken.length > count) {
          sendCallingNotification(count);
        }
        if (kDebugMode) {
          Utils.showToast(value.body);
          print(value.body.toString());
        }
      }).onError((error, stackTrace) {
        Utils.showAlertDialog(context, "Alert...!", "$error");
        ++count;
        if (listToken.length > count) {
          sendCallingNotification(count);
        }
        if (kDebugMode) {
          print(error);
        }
      }).catchError((error) {
        Utils.showAlertDialog(context, "Alert...!", "$error");
      });
    } catch (e) {
      Utils.showToast("$e");
    }
    // });
  }
}
