import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_mqqt_example_gui/utils/mqtt_utils.dart';
import 'package:mqtt_client/mqtt_client.dart';

class MQTTMessagePage extends HookWidget {
  const MQTTMessagePage({
    super.key,
    required this.mqttUtils,
  });

  final MqttUtils mqttUtils;

  @override
  Widget build(BuildContext context) {
    final textEditingControllerMessage = useTextEditingController();
    final subscribedTopics = useState<Map<String, List<String>>>({});
    final alertNewMessage = useState<Map<String, bool>>({});
    final currentIndex = useState<int>(0);

    useEffect(() {
      mqttUtils.client.updates!
          .listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
        final recMess = c![0].payload as MqttPublishMessage;
        final pt =
            MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

        final topic = c[0].topic;
        final message = pt;

        subscribedTopics.value = {
          ...subscribedTopics.value,
          topic: [
            ...(subscribedTopics.value[topic] ?? []),
            message,
          ],
        };

        if (subscribedTopics.value.keys.elementAt(currentIndex.value) !=
            topic) {
          alertNewMessage.value = {
            ...alertNewMessage.value,
            topic: true,
          };
        }
      });
      return;
    }, []);

    return PopScope(
      onPopInvoked: (status) async {
        await mqttUtils.disconnect();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text('Message'),
          actions: [
            IconButton(
              onPressed: () async {
                // Show dialog to input message
                final topic = await showDialog<String>(
                  context: context,
                  builder: (context) {
                    final textEditingController = TextEditingController();
                    return AlertDialog(
                      title: const Text('Subscribe to Topic'),
                      content: TextField(
                        controller: textEditingController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Topic',
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context)
                                .pop(textEditingController.text.trim());
                          },
                          child: const Text('Add'),
                        ),
                      ],
                    );
                  },
                );

                if (topic != null &&
                    topic.isNotEmpty &&
                    subscribedTopics.value[topic] == null) {
                  await mqttUtils.subscribeTo(topic);
                  subscribedTopics.value = {
                    ...subscribedTopics.value,
                    topic: [],
                  };
                }
              },
              icon: const Icon(
                Icons.add_rounded,
              ),
            ),
          ],
        ),
        body: DefaultTabController(
          length: subscribedTopics.value.length,
          child: Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              flexibleSpace: TabBar(
                isScrollable: true,
                tabs: subscribedTopics.value.keys
                    .map(
                      (e) => Badge(
                        backgroundColor: alertNewMessage.value[e] == true
                            ? Colors.red
                            : Colors.transparent,
                        child: Tab(text: e),
                      ),
                    )
                    .toList(),
                onTap: (value) {
                  alertNewMessage.value = {
                    ...alertNewMessage.value,
                    subscribedTopics.value.keys.elementAt(value): false,
                  };

                  currentIndex.value = value;
                },
              ),
            ),
            body: Padding(
              padding: const EdgeInsets.only(bottom: 100),
              child: TabBarView(
                children: subscribedTopics.value.keys
                    .map(
                      (e) => Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.all(16),
                        child: Scrollbar(
                          thumbVisibility: true,
                          trackVisibility: true,
                          child: SingleChildScrollView(
                            child: Text(
                              subscribedTopics.value[e]?.join('\n') ?? '',
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
        bottomSheet: subscribedTopics.value.isEmpty
            ? null
            : Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 24,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Flexible(
                      flex: 3,
                      child: TextField(
                        controller: textEditingControllerMessage,
                        decoration: const InputDecoration(
                          border: UnderlineInputBorder(),
                          labelText: 'Message',
                        ),
                      ),
                    ),
                    Flexible(
                      flex: 1,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        onPressed: () {
                          mqttUtils.publish(
                            subscribedTopics.value.keys
                                .elementAt(currentIndex.value),
                            textEditingControllerMessage.text.trim(),
                          );

                          textEditingControllerMessage.clear();
                        },
                        child: const Text('Send'),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
