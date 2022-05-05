<!-- 
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages). 

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages). 
-->


This rendering library exposes a way to to render SVG paths in a drawing like fashion.

## Features


| <img src="https://github.com/biocarl/img/raw/master/drawing_animation/met_dynamic_1.gif" width="400px" > |*more coming soon*<br/>... | <img src="https://github.com/biocarl/img/raw/master/drawing_animation/loader_1.gif" width="400px"> 

## Getting started


To get started with the `draw_svg` package you need a valid Svg file.
1. **Add dependency in your `pubspec.yaml`**
```yaml
dependencies:
  draw_svg: ^0.0.1

```

2. **Add the SVG asset**
```yaml
assets:
  - assets/my_drawing.svg
```




## Usage


```dart

    Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HomePage'),
      ),
      body: DrawAnimation.svg('assets/sample.svg'),
    );
  }
```


## Additional information


## Credits
This package is highly inspired by the drawing animation package which is no longer maintaine . Try to rewrite this package in more modern way.


# Author 
Faisal Kabir Galib