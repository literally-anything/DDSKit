# DDSKit
![License](https://img.shields.io/badge/license-MIT-green.svg?style=flat)
![GitHub Release Date](https://img.shields.io/github/release-date/literally-anything/DDSKit)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fliterally-anything%2FDDSKit%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/literally-anything/DDSKit)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fliterally-anything%2FDDSKit%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/literally-anything/DDSKit)

*DDSKit* is an inter-process communication library built using [FastDDS](https://fast-dds.docs.eprosima.com/en/latest/index.html).
DDSKit aims provide a simpler and easier-to-use API in Swift, including asynchronous operations using await and a request-reply model, while still remaining performant.
DDSKit enables FastDDS's datasharing, intra-process, and zero-copy delivery methods for faster communication between threads or processes on the same machine.

#### This does actually run on Linux, even though the SPI says it won't. I haven't gotten around to making a docker container that has FastDDS installed, so it will fail to build on the SPI's Linux builds.

Some use cases for this library are:
  - Robotics/Interfacing with ROS2
  - Distributed systems
  - High data rate communitcation

## Supported Platforms
| Platform        | Support                    |
| --------------- | -------------------------- |
| Linux           | Supported*[^1]*[^3]        |
| MacOS           | Supported*[^2]*[^3]        |
| Other Apple OSs | Supported*[^2]*[^3]        |
| Windows         | Absolutely no clue, but it might work*[^3] |

[^1]: FastDDS must be installed and it needs to findable using pkg-config for it to work with no exta setup. 

[^2]: Prebuilt dylibs of fastdds and fastcdr are required. This is temporary for MacOS. In the future you should be able to use a global install of FastDDS on MacOS as well.

[^3]: Needs tests

## Example
The following code publishes a message on a topic
```swift
import DDSKit

struct HelloWorld {
    var index: Int
    var message: String
}

let participant = DDSParticipant()
let publisher = participant.publish(to: "hello/world", type: HelloWorld.self)
publisher.publish(message)
```
To recieve this message, the following code subscribes to the topic and prints each message as it arrives
```swift
import DDSKit

let participant = DDSParticipant()
let subscriber = participant.subscribe(to: "hello/world", type: HelloWorld.self)
for await message in subscriber.messages {
    print(message)
}
```

## Using DDSKit
If you are on Linux, you need to install FastDDS as well. Apple platforms default to using a prebuilt version.
DDSKit is available as a Swift Package Manager package. To use it in a package,  add the following dependency in your `Package.swift`
```swift
.package(
    url: "https://github.com/literally-anything/DDSKit.git",
    from: "1.0.0"
)
```
Replace "tag" with any release number: [tags](https://github.com/literally-anything/DDSKit/tags).
To use the `DDSKit` library, add
```swift
.product(name: "DDSKit", package: "DDSKit")
```
to your target's dependencies.
