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
  List<Map<String, dynamic>> listUser = [];
  final nameController = TextEditingController();

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
        getFirebaseToken();
      }
    });

    disableKeyguard();
  }

  addFirebaseToken(String name, String deviceToken) {
    CollectionReference collectionReference = FirebaseFirestore.instance.collection("users");
    collectionReference.add({"name": name, "deviceToken": deviceToken});
    Utils.showToast("Add Successfully");
    getFirebaseToken();
  }

  getFirebaseToken() {
    listUser.clear();
    CollectionReference users = FirebaseFirestore.instance.collection('users');

    users.get().then((QuerySnapshot snapshot) {
      snapshot.docs.forEach((doc) {
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
        // if (currentDeviceToken.compareTo(userData["deviceToken"]) != 0 && !listUser.contains(userData["deviceToken"])) {
        setState(() {
          listUser.add(userData);
        });
        // }
        print('${doc.id} => ${doc.data()}');
      });
      print(listUser);
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
        title: const Text('Whatsapp Calling'),
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
          const SizedBox(
            height: 16.0,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 24.0, right: 24.0),
            child: TextFormField(
                decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(
                        borderRadius: const BorderRadius.all(Radius.circular(8.0)), borderSide: BorderSide(color: Colors.grey.withOpacity(0.2))),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: const BorderRadius.all(Radius.circular(8.0)), borderSide: BorderSide(color: Colors.grey.withOpacity(0.3))),
                    filled: true,
                    fillColor: Colors.grey.withOpacity(0.1),
                    hintText: "Enter your name"),
                controller: nameController,
                keyboardType: TextInputType.name),
          ),
          const SizedBox(
            height: 16.0,
          ),
          ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  addFirebaseToken(nameController.text, deviceToken);
                }
              },
              child: const Text('Add User')),
          GestureDetector(
            onTap: () {
              getFirebaseToken();
            },
            child: const Padding(
              padding: EdgeInsets.only(left: 24.0, top: 24.0),
              child: Row(
                children: [
                  Text(
                    "Tap to refresh list",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(
                    width: 4.0,
                  ),
                  Icon(Icons.refresh)
                ],
              ),
            ),
          ),
          Expanded(
              child: ListView.builder(
                  itemCount: listUser.length,
                  itemBuilder: (BuildContext context, int index) {
                    return ListTile(
                        leading: const Icon(Icons.call),
                        trailing: ElevatedButton(
                            onPressed: deviceToken.compareTo(listUser[index]["deviceToken"]) != 0
                                ? () {
                                    if (listUser.isNotEmpty) {
                                      sendCallingNotification(listUser[index]);
                                    } else {
                                      Utils.showToast("Please install the app on the other device.");
                                    }
                                  }
                                : null,
                            child: const Text('Call')),
                        title: Text(listUser[index]["name"]));
                  })),
        ],
      )),
    );
  }

  sendCallingNotification(Map<String, dynamic> user) async {
    // send notification from one device to another
    // notificationServices.getDeviceToken().then((value) async {
    try {
      var data = {
        "message": {
          'token': user["deviceToken"],
          'notification': {'title': user["name"], 'body': 'Calling...'},
        }
      };

      await http.post(Uri.parse('https://fcm.googleapis.com/v1/projects/whatsapp-call-7435a/messages:send'), body: jsonEncode(data), headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization':
            'Bearer ya29.c.c0AY_VpZjxr1PPbc0JvRYg8dBfZtcXkpQieCcpVgVBfW1sx7aaXqWYGs9wbOIxL5yhyBl-5qeOQiqMKwXK_DHyRQr3MbwumuXm25EBai9YkFKy_zw66GbSFfK5C5m70QdrrooQxjH2dP8cjGlSJKv0KIDw81dCk5hHI3OZOSEEt6SdpbciUNS0NapctBPVcVi34DW8dJ6Fmwhb5_TvTPNW-qMKOrhUvroRFmEk_5VcA9F8L96SBH2Vwq3J41oxH7VOxSsaglwD_dkhU6cpUyIHGFrSzysSQjmV_GPdjjZP8G_4V2SwO0qqO5dS9E_e-Wrl1G-WGvgi424FoW9278FFRz5v810Mg_tYkUpZhBBbn6dd4GAXxloXdcbwT385DUa29qI8yWs6vwdMbZ1omFMMmrvQZbQ1l7uh0s0Xi7J_QsYe3FUewfliBv1wdjvlnIU3h3_Z172Waybc722kIZdb8r3oofUIlX3MJzpZQavsWn_UJu-JrbOpnZZQe8whY4krrvlkI7fW98Sd13r_p25aZa8sXRZy_xh04OSf6cYkt79nMiYaYM13l_nZhibguI7YVFXdIm-0fw4Mgv1qkVzZtmIWme_fabvYwwa6FstR7uza6_RezSp-ZZa09Wxe4__eUkemr_YipB0qMJzZ-10Mljjjv1xwUqa7UrhvbsY5VomkS2en34WSwOQMt92S1ufSMv_FOnxjdw3qXQl-7e54aIxp6outJ4dhdoJjqnYzIniO_Q067x4uuSd_0b2nRnX623Yxoon0ORcjYM5sw9sSii1Y3WcO6y_gMzevkhUy5J43fjzk8t1jWk-OX258kVI0J1oFBpo6JaocdaJS7nSmp6JVQW2zhuskfhwetIp-OS576WJzVjXw8bv83y5dhBzSjOm1t5ji4yzI8MnOXfpaV-f08ay8R8aeFzfJmvjgbuUmRlJvjXtvb3SkcqQ8zisB2dj9rYUFQFguUS11sgyUrc-QRn9e1ynjiIYw_lfmX_5nuY4VBiSXZUi'
      }).then((value) {
        if (kDebugMode) {
          Utils.showToast(value.body);
          print(value.body.toString());
        }
      }).onError((error, stackTrace) {
        Utils.showAlertDialog(context, "Alert...!", "$error");
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
