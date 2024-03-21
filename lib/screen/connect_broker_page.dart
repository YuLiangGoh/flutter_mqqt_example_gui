import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_mqqt_example_gui/app/global.dart';
import 'package:flutter_mqqt_example_gui/main.dart';
import 'package:flutter_mqqt_example_gui/screen/mqtt_message_page.dart';
import 'package:flutter_mqqt_example_gui/utils/mqtt_utils.dart';
import 'package:random_name_generator/random_name_generator.dart';

class ConnectBrokerPage extends HookWidget {
  const ConnectBrokerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textEditingControllerBroker = useTextEditingController(
      text: '192.168.100.11',
    );
    final brokerEnabled = useState(true);
    final textEditingControllerClientId = useTextEditingController(
      text: RandomNames(Zone.us).manFullName(),
    );
    final cliendIDEnabled = useState(true);
    final textEditingControllerUserName = useTextEditingController(
      text: 'admin-user',
    );
    final userNameEnabled = useState(true);
    final textEditingControllerPassword = useTextEditingController(
      text: 'admin-password',
    );
    final passwordEnabled = useState(true);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Connect Broker'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: textEditingControllerBroker,
              enabled: brokerEnabled.value,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Broker',
              ),
            ),
            gapHeight12,
            TextField(
              controller: textEditingControllerClientId,
              enabled: cliendIDEnabled.value,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Client ID',
              ),
            ),
            gapHeight12,
            TextField(
              controller: textEditingControllerUserName,
              enabled: userNameEnabled.value,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'User Name (Optional)',
              ),
            ),
            gapHeight12,
            TextField(
              controller: textEditingControllerPassword,
              enabled: passwordEnabled.value,
              obscureText: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Password (Optional)',
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            minimumSize: const Size.fromHeight(60),
          ),
          onPressed: () async {
            brokerEnabled.value = false;
            cliendIDEnabled.value = false;
            userNameEnabled.value = false;
            passwordEnabled.value = false;

            final broker = textEditingControllerBroker.text.trim();
            final clientId = textEditingControllerClientId.text.trim();
            final userName = textEditingControllerUserName.text.trim();
            final password = textEditingControllerPassword.text.trim();

            final mqttUtils = MqttUtils();

            try {
              await mqttUtils.connect(broker, clientId, userName, password);

              brokerEnabled.value = true;
              cliendIDEnabled.value = true;
              userNameEnabled.value = true;
              passwordEnabled.value = true;

              if (context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return MQTTMessagePage(
                        mqttUtils: mqttUtils,
                      );
                    },
                  ),
                );

                const snackBar = SnackBar(
                  content: Text('Connected to Broker Successfully.'),
                );

                if (navigatorKey.currentContext != null) {
                  ScaffoldMessenger.of(navigatorKey.currentContext!)
                      .showSnackBar(snackBar);
                }
              }
            } catch (e) {
              brokerEnabled.value = true;
              cliendIDEnabled.value = true;
              userNameEnabled.value = true;
              passwordEnabled.value = true;

              final snackBar = SnackBar(
                content: Text(e.toString()),
              );

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(snackBar);
              }
              rethrow;
            }
          },
          child: const Text('Connect'),
        ),
      ),
    );
  }
}
