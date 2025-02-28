# DDSKit
*DDSKit* is an inter-process communication library built using [FastDDS](https://fast-dds.docs.eprosima.com/en/latest/index.html).
DDSKit aims provide a simpler and easier-to-use API in Swift, including asynchronous operations using await and a request-reply model, while still remaining performant.
DDSKit enables FastDDS's datasharing, intra-process, and zero-copy delivery methods for faster communication between threads or processes on the same machine.

Some use cases for this library are:
  - Robotics/Interfacing with ROS2
  - Distributed systems
  - High data rate communitcation

## Supported Platforms
| Platform        | Support                    |
| --------------- | -------------------------- |
| Linux           | Supported*[^1]             |
| MacOS           | Supported*[^1]             |
| Other Apple OSs | Supported*[^1]*[^2]        |
| Windows         | Absolutely no clue, but it might work*[^1] |

[^1]: Needs tests

[^2]: Prebuilt dylibs of fastdds and fastcdr are required

## Example
The following code publishes a message on a topic
```swift
import DDSKit

let participant = DDSParticipant()
let publisher = participant.publish(to: "hello/world")
publisher.publish(message)
```
To recieve this message, the following code subscribers to the topic
```swift
import DDSKit

let participant = DDSParticipant()
let subscriber = participant.subscribe(to: "hello/world")
for await message in subscriber.messages {
    print(message)
}
```

## Using DDSKit
DDSKit is available as a Swift Package Manager package. To use it in a package,  add the following dependency in your `Package.swift`
```swift
.package(
    url: "https://github.com/literally-anything/DDSKit.git",
    from: "tag"
),
```
Replace "tag" with any release number: [tags](https://github.com/literally-anything/DDSKit/tags).
To use the `DDSKit` library, add
```swift
.product(name: "DDSKit", package: "DDSKit"),
```
to your target's dependencies.
