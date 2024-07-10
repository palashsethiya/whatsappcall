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
      // if (kDebugMode) {
        print('device token');
        print(value);
        setState(() {
          deviceToken = value;
        });
        getFirebaseToken();
      // }
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
            'Bearer ya29.c.c0ASRK0GaHl8WE9owUsNG1FkwfCP8wn5y-ivjyDvJ9dDFLIxAq4PEofPaQMYLffjp5L6pe2Vafx7rIOk8jeqLY0Tv8CXnc7sZMhhIlLIiH1Ameu8yXdNvP4urDWN0a79P_MAs1cJgc8s9i03pkL5VRuDdReewcEeIMxRnhCZE_tDx_gQkI3Sm6Xu1oORyI1P8qXUsHI8kujalqT4C54Vu5ojeqS8RxM8RFpfrYK-vrrrRJvoxoFH3P-9RQExIzduGVxsp4xnNsBm8LMbthQkHovdirf7erozPdTvKCNaJ-qCEwUbqn-pGO5s3sOJQf-F2w17AZe6CePffVCfjFAWthgdTpAdO4M_oniQ-9acEAKrIS0UbLLxkYVZtEL385K0FOJcY0dcJi7IIklak2pQ8OnJWyb03JrqOY9eIc-5vxun6rZjwYR-ewr3f1_M8O_mgW59Q71mlkroan4gme7kIX2OzXohzt5sV1vB4aW4X6QM3nalU-xJ1bUQfsXII6g5bjj9yxFei97O2ng8RU1nBh9MxqQiBeqOcMjJ1R6t28Oa_ytSeOhSFybjjdwR04x6lraIcg2oc8njmeRziWMI4ddf13Rg5u7Ykgq0ZYB9OJ1_nXrZdhi4myF2-6OfXrzMtsIR3kmrc2eOYqaYr5kZVhsVqVOl54cmu8jYZXmiOuVMesaF94VWhtreIaOWhnrs8IUfWvoJJZ8r5Bvdy5v9mbYfgso8a-j8Uw6QOI6vBi6nIdJlb-vdl-afQU9wtgrp66QqIQBhbp1Jhmj5vosp-mf8oFVgUU8hifUqpstp0j9ZimVXBO-uSBRpOnMhou14nijza3xin8f8JU8cogfhdiM5dXlJydmWiOsipj5QfI_oZtYsOUJbBpOcB0cneFoyvk0u88wQ3WdhV5U5v1Ybu2Xb8cMWOV9_d4j_Sfzk26izp7gQIkoOmao2_i_ttJ2anFym2104y4RqlU0MUOWbmvI0q31kbBWf2U_B16wq0y1ooq5QfxhgnbZIq'
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
