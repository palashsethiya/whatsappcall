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
            child: Text("For provide permission (Setting -> Other Permission -> Show on Lock screen)"),
          ),
          ElevatedButton(
              onPressed: () {
                if (listToken.isNotEmpty) {
                  sendCallingNotification(0);
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
            'Bearer ya29.c.c0AY_VpZhAwwtXoBYCMr68pPBxJfZiCrwrZuNgZG4_ugQKowncY61_0gZ1beI-RcT2A0xKHsxm5Ia61gQFMYP1h1cVzoxzZ6jAErpe9gtdogr4jPhQC4mNL3xCYGehnbr7MpbrlRhB2jRK6oaUOgt5kPmWQMRKnRkCF-XeFup2B25bb1I4xHeE7YKdPhYLKNxQdSkuPT6QoFyiKklgGlV7tUqntzcTYO9CEMD9zPGG2nXxJZmhskVP1XxTfi9GQcEX5xz6J2UhY1llOZZ-SrtCA-DZyz6QZzcG4J2PR9v2j9_4TjQDsYtNhNVfGeVbZDZOUayNdrRZBNqDF_fA6lxdV87bAqBw9dR02qpzz_M4V3e0Z4yZ4juN8aMT384AfIWYJuaam6gwadXsvjOYdtqpMeXO2a8rbgR84cSMO86FFR6-1Ivg8Iqx5YS1R7lFrdIggORMbQ0uSbo3U19xSISkrXrQY_hmXaBnR8jajvOk020larOxbu3l8BB6rX592erFz_ZWtBgep2s4ci-Sh5QVnMU18Ilr1gVF795Bhomc40o_ZtJep5lu9Uu7dmr0hwZrV50Vexyj7UnZ6ao-maR7x7nbYb5voySzhth7FSojdg9MdQjxrpdOOWu8YYraX7w5Yh2du4Owfh8iu26012qMO03brkrlQt97gZyFdFJ038z1f7ak0jg8-0iaS5fBMrYw5MQ07tuc9etljb6pmi_6qsvSiRm_uaBSxd66M_uUc3Yxc_Vno9bYr9e2fRxio7vid0nM-8eOdWffidcoOboOI354_aaYv7YFXJ6Wz_4fUhOz5Bxgu-a3csbVZwmduSacrhS-6OevBdd4h0dqhhMpXmc7isVclX3407ocxcjv1Vj8nxsZ63YbQl4zRxm8Jwh4Mq9UM2t3YStQ8SI_p2mxgp7f6ISJ3WY7qve-UiQX2yoRWy7xUZIy4pbM7_Ocu6jhnt9i53Z2RJc_yp38wRB55gtBq79bmVXOu3SeziIVq2MuuXQJeseinXa'
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
