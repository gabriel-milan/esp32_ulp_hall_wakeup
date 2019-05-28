# ESP32 ULP Wake-up from Hall Sensor

In this short example, we'll wake the ESP32 up using readings from the internal hall sensor, according to a threshold.

This was based on the code from esp-iot-solution example.

## Let's do it!

First you've got to build your sdkconfig file:

```
make menuconfig
```

Go through "Component config" > "ESP32-specific" and enable "Enable Ultra Low Power (ULP) Coprocessor", setting "RTC slow memory reserver for coprocessor" as 1024.
Save it and then press Esc+Esc few times in order to exit.

After that, just do:

```
make flash monitor
```

And this code will be flashed into the ESP32 and serial monitor will open on your screen. Be happy!

## Changing threshold value

You just have to edit the ".set threshold, 70" line on hall_sensor.S to your desired value!