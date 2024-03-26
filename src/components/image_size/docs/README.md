The `Athena::ImageSize` component allows measuring the size of various [image formats][Athena::ImageSize::Image::Format].

## Installation

First, install the component by adding the following to your `shard.yml`, then running `shards install`:

```yaml
dependencies:
  athena-image_size:
    github: athena-framework/image-size
    version: ~> 0.1.0
```

## Usage

an [AIS::Image][] instance can be instantiated given a path to an image file, or via an [IO](https://crystal-lang.org/api/IO.html).
From there, information about the image can be accessed off of the instance.

```crystal
AIS::Image.from_file_path "spec/images/jpeg/436x429_8_3.jpeg" # =>
# Athena::ImageSize::Image(
# @bits=8,
# @channels=3,
# @format=JPEG,
# @height=429,
# @width=436)
```
