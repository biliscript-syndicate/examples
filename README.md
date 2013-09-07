Demos
=====

All code is expected to run in the [Bilibili](http://en.wikipedia.org/wiki/Bilibili) [Flash Player](https://static-s.bilibili.tv/play.swf) (account required).

- `Minecraft4K.as` A port of Notch's Minecraft4K; demostrating: procedural texture generation, texture mapping, manual 3D raycasting. The engine of biliscript sucks at performance. The FPS here is ~0.5.
- `u15transport.as` base32768 encoder and decoder using some unicode codepoints as the alphabet, operating on a ByteArray. Unit test cases are included.
- `TKKN.as` [A port of TKKN](http://www.bilibili.tv/video/av376363/), a bullet hell game; demostrating: base64 decoding, keyboard input, image materials, collision detection, BitmapData texture.
- `FSAA.as` A demo of Full-Scene Anti-Aliasing. Lines drawn by Flash runtime show greater aliasing at 45 degree.


脚本样例
========

- `FSAA.as` 演示过采样反走样。Flash的45度走样比较严重。
- `Minecraft4K.as` Notch自作代码移植版。主要演示：过程性生成材质，贴图，手动3D场景光线投射。biliscript性能不足，大概2秒一帧。
- `u15transport.as` base32768编解码器，处理ByteArray。
- `TKKN.as` [特训移植版](http://www.bilibili.tv/video/av376363/)。演示：base64解码，键盘管理，图像导入，碰撞检测，BitmapData贴图。
