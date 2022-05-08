# RocketBootstrap Example

An xpc service jailbreak daemon + tweak example. 

To communicate with a sandbox app, you may need to design your tweak in this pattern:

![xpc](https://user-images.githubusercontent.com/5410705/167263449-5a40e4ac-06c4-4148-ad11-3e253057ccdb.png)

Now here it is.


## Build

1. `Xcode` is required.
2. Install [theos](https://github.com/theos/theos) and [sdks](https://github.com/theos/sdks).
3. Install `RocketBootstrap` on your iOS jailbroken device.
4. Copy `/usr/include/rocketbootstrap*` from your device to `$THEOS/include/rocketbootstrap`.
5. Copy `/usr/lib/librocketbootstrap.dylib` from your device to `$THEOS/lib`.
6. Configure `THEOS_DEVICE_IP`, `THEOS_DEVICE_PORT`, and do `ssh-copy-id` to your development device.
7. `make package && make install`


## Usage

1. `ssh` into your development device.
2. Open sandbox app (i.e. App Store in this tweak).
3. `storeappversiontool your-name` and you will receive messages from sandbox app.

```shell
MyTest2:~ root# storeappversiontool Lessica
Hello Lessica, I am com.apple.AppStore.
```

