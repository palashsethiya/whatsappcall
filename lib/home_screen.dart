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
    nameController.clear();
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
                    return Container(
                        width: MediaQuery.of(context).size.width,
                        margin: const EdgeInsets.only(left: 14.0, right: 14.0, top: 12.0),
                        padding: const EdgeInsets.only(left: 4.0, top: 4.0, bottom: 4.0),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 14.0, offset: const Offset(0, 0))]),
                        child: ListTile(
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
                            title: Text(listUser[index]["name"])));
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
            'Bearer ya29.c.c0ASRK0GYWJ2GQLUFtKC_ECCQ8ayy0uP_BqVT-ydznG4RpA15ECJ_vKWwWRfFSaZO4vlFO3mC4zjXyZC3VB_VXkj0Ai4HInbeih1vEc6b5E77FAnOmKw2kpmnXJ-gPT8R6-QVZARrk87m7sGQD9lFoH0QFOGyCV3fd_ZUtUG8c9g7ecdMwkK1j43ZBfVE9lNgEBFJYus5wyQK5m2U1pJruoTqzz8_uDEcU1gRw2mudeRnY04zzSIC1r-nISbRJQISfobTtoLViffxHSB4I77cLFlf01hVZRSy8z-v3TJrO3RXEh0DZVWsUkpvwuICf0Ja4AhTDJJBtUr5-CtJIEM7YxNsz0fROhc9NMcTIvDRgqAnW8UxucKbaY-RTaQG387CtrkM3JJdf-3wSF4kcvcv8xW2QyIv5tgRMs0RQ3bmf4bW_8JcORSleQM_Bn_balmbBd-jbbZuf1eV-rWc80_02kcrOQfoj_-JQVMU0fB8xrIlqm7XbeYuYw2jm8plMXUUI56yBZBrefqbylzips9BFpc9z7vbeFVzvBJ9zu027-ie7monmqeB2uo9uzY5f3XgoU91Yq9Rn-JtJeRvyQVqsWycz0Bnr63Ibp3y1o05r3W1r6VvBXQOOM310FU3BUgf5sX2yxFj5UX3IdwgtugZ9v_tad4zep0_wmZaenkajl0egFavFurvk9y_bwoIlSuvUqF4x7bfyxQQxnbFxoMlcV65m_oVRjlsVhpqZhtqn5WYr1IfY_pMybhS3Ohqm_vZ_m72voFzJ2bc2sMfp8bXdnF6belfi64mO3ZZz7IQO9drXWd18S_rJO_80odqvUn3voyu12MS8VtOkQURMUzWO_uMVI8JQZyyU8ny4Jy5ucSMcI1Q2jWfXQwFJ8FcMYwb6mn-4t-JrVk7Vo-vbIyBUpOx_Oix80Q-8sdFXsBa2yizZcVMB979k1-s_yV5relct8ssaBerbuhFqXiyOMltjoZ4XzwO82mM0ilal1x_ttQkB2IJZVm4xQoO'
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
