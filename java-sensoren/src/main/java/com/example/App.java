package com.example;

import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.concurrent.atomic.AtomicBoolean;

import org.eclipse.paho.client.mqttv3.MqttClient;
import org.eclipse.paho.client.mqttv3.MqttException;
import org.eclipse.paho.client.mqttv3.MqttMessage;
import org.eclipse.paho.client.mqttv3.persist.MemoryPersistence;

public class App {
    private static final String DEFAULT_BROKER = "tcp://localhost:1883";
    private static final String COMMAND_TOPIC = "java/commands";
    private static final String COMMANDS = "status, pause, resume, stop";
    private static final List<VirtualSensor> SENSORS = List.of(
            new VirtualSensor("java-wohnzimmer-temperatur", "java/r1", 21.0, 3.0, 0.35, 0.0),
            new VirtualSensor("java-küche-energie", "java/r2", 420.0, 90.0, 0.22, 1.2),
            new VirtualSensor("java-keller-luftqualität", "java/r3", 650.0, 160.0, 0.18, 2.4));

    public static void main(String[] args) {
        String broker = args.length > 0 ? args[0] : System.getenv().getOrDefault("MQTT_BROKER", DEFAULT_BROKER);
        AtomicBoolean running = new AtomicBoolean(true);
        List<SensorClient> clients = new ArrayList<>();
        List<Thread> threads = new ArrayList<>();

        try {
            System.out.println("[java] Starte Java-Sensoren");
            System.out.println("[java] Broker: " + broker);
            System.out.println("[java] Publish-Topics: java/r1, java/r2, java/r3");
            System.out.println("[java] Subscriber-Topic: " + COMMAND_TOPIC);
            System.out.println("[java] Befehle: " + COMMANDS);

            for (VirtualSensor sensor : SENSORS) {
                SensorClient client = new SensorClient(broker, sensor, running);
                client.connect();
                clients.add(client);
            }

            Runtime.getRuntime().addShutdownHook(new Thread(() -> clients.forEach(SensorClient::disconnectQuietly)));

            for (SensorClient client : clients) {
                Thread thread = new Thread(client, client.sensorName());
                thread.start();
                threads.add(thread);
            }

            for (Thread thread : threads) {
                thread.join();
            }

            System.out.println("[java] Java-Sensoren beendet.");
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            clients.forEach(SensorClient::disconnectQuietly);
        }
    }

    private static final class SensorClient implements Runnable {
        private final String broker;
        private final VirtualSensor sensor;
        private final AtomicBoolean running;
        private final AtomicBoolean publishingActive = new AtomicBoolean(true);
        private MqttClient client;

        SensorClient(String broker, VirtualSensor sensor, AtomicBoolean running) {
            this.broker = broker;
            this.sensor = sensor;
            this.running = running;
        }

        void connect() throws MqttException {
            String clientId = sensor.name() + "-" + System.currentTimeMillis();
            client = new MqttClient(broker, clientId, new MemoryPersistence());
            client.connect();
            client.subscribe(COMMAND_TOPIC, this::handleMessage);
            System.out.println("[java] Verbunden Sensorname=" + sensor.name()
                    + " PublishTopic=" + sensor.topic()
                    + " SubscribeTopic=" + COMMAND_TOPIC
                    + " Broker=" + broker);
        }

        String sensorName() {
            return sensor.name();
        }

        @Override
        public void run() {
            long tick = 0;

            while (running.get()) {
                if (publishingActive.get()) {
                    publishValue(tick);
                    tick++;
                }

                sleepOneSecond();
            }
        }

        private void publishValue(long tick) {
            try {
                double value = sensor.valueAt(tick);
                String payload = String.format(Locale.US, "%.2f", value);
                MqttMessage mqttMessage = new MqttMessage(payload.getBytes(StandardCharsets.UTF_8));
                mqttMessage.setQos(0);

                client.publish(sensor.topic(), mqttMessage);
                System.out.println("[java] Sensorname=" + sensor.name()
                        + " Topic=" + sensor.topic()
                        + " Broker=" + broker
                        + " Wert=" + payload);
            } catch (MqttException e) {
                System.err.println("[java] Fehler: " + sensor.name()
                        + " konnte nicht auf " + sensor.topic()
                        + " senden: " + e.getMessage());
            }
        }

        private void handleMessage(String topic, MqttMessage message) {
            String command = new String(message.getPayload(), StandardCharsets.UTF_8).trim().toLowerCase(Locale.ROOT);

            switch (command) {
                case "pause" -> {
                    publishingActive.set(false);
                    System.out.println("[java] Sensorname=" + sensor.name()
                            + " SubscribeTopic=" + topic
                            + " Befehl=pause Aktion=Publishing pausiert");
                }
                case "resume" -> {
                    publishingActive.set(true);
                    System.out.println("[java] Sensorname=" + sensor.name()
                            + " SubscribeTopic=" + topic
                            + " Befehl=resume Aktion=Publishing aktiv");
                }
                case "status" -> System.out.println("[java] Sensorname=" + sensor.name()
                        + " PublishTopic=" + sensor.topic()
                        + " SubscribeTopic=" + topic
                        + " Befehl=status PublishingAktiv=" + publishingActive.get());
                case "stop" -> {
                    running.set(false);
                    System.out.println("[java] Sensorname=" + sensor.name()
                            + " SubscribeTopic=" + topic
                            + " Befehl=stop Aktion=Java-Sensoren werden beendet");
                }
                default -> {
                    if (!command.isBlank()) {
                        System.out.println("[java] Sensorname=" + sensor.name()
                                + " SubscribeTopic=" + topic
                                + " UnbekannterBefehl=" + command
                                + " Erlaubt=" + COMMANDS);
                    }
                }
            }
        }

        private void sleepOneSecond() {
            try {
                Thread.sleep(1000);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                running.set(false);
            }
        }

        private void disconnectQuietly() {
            try {
                if (client != null && client.isConnected()) {
                    client.disconnect();
                }
            } catch (Exception ignored) {
            }
        }
    }

    record VirtualSensor(String name, String topic, double base, double amplitude, double speed, double phase) {
        double valueAt(long tick) {
            return base + Math.sin((tick * speed) + phase) * amplitude;
        }
    }
}
