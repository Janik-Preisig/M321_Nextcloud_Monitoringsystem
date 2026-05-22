package com.example;

import static org.junit.jupiter.api.Assertions.assertEquals;

import org.junit.jupiter.api.Test;

public class AppTest {

    @Test
    public void virtualSensorKeepsConfiguredTopic() {
        App.VirtualSensor sensor = new App.VirtualSensor("test-sensor", "java/r1", 21.0, 3.0, 0.35, 0.0);

        assertEquals("java/r1", sensor.topic());
    }

    @Test
    public void virtualSensorStartsAtBaseValueWithoutPhase() {
        App.VirtualSensor sensor = new App.VirtualSensor("test-sensor", "java/r1", 21.0, 3.0, 0.35, 0.0);

        assertEquals(21.0, sensor.valueAt(0), 0.0001);
    }
}
