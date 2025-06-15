---
title: Implementation References
navOrder: 40
---
## Notes
To learn about execution order, you can add `print()` statements to the Flutter tool at desired
locations. To get those `print()` statements to run, you'll need to trigger a rebuild of the Flutter
tool. To do that, delete the file at `[my_flutter_sdk]/bin/cache/flutter_tools.snapshot`. The next
time a `flutter` command is executed, it will rebuild the tool from source, and include your
`print()` statements.

## Key Stack Traces
Some stack traces that show execution path.

**Execution from test command launch:**
This captures the start of execution, and also captures the handoff point from the
`flutter_tools` package to the `test_core` package.

```
executable.dart - main()
StackTrace:
#0      main (package:test_core/src/executable.dart:39:36)
#1      _DefaultTestWrapper.main (package:flutter_tools/src/test/test_wrapper.dart:31:16)
#2      FlutterTestRunner.runTests (package:flutter_tools/src/test/runner.dart:179:25)
#3      TestCommand.runCommand (package:flutter_tools/src/commands/test.dart:664:33)
<asynchronous suspension>
#4      FlutterCommand.run.<anonymous closure> (package:flutter_tools/src/runner/flutter_command.dart:1558:27)
<asynchronous suspension>
#5      AppContext.run.<anonymous closure> (package:flutter_tools/src/base/context.dart:154:19)
<asynchronous suspension>
#6      CommandRunner.runCommand (package:args/command_runner.dart:212:13)
<asynchronous suspension>
#7      FlutterCommandRunner.runCommand.<anonymous closure> (package:flutter_tools/src/runner/flutter_command_runner.dart:496:9)
<asynchronous suspension>
#8      AppContext.run.<anonymous closure> (package:flutter_tools/src/base/context.dart:154:19)
<asynchronous suspension>
#9      FlutterCommandRunner.runCommand (package:flutter_tools/src/runner/flutter_command_runner.dart:431:5)
<asynchronous suspension>
#10     run.<anonymous closure>.<anonymous closure> (package:flutter_tools/runner.dart:98:11)
<asynchronous suspension>
#11     AppContext.run.<anonymous closure> (package:flutter_tools/src/base/context.dart:154:19)
<asynchronous suspension>
#12     main (package:flutter_tools/executable.dart:99:3)
<asynchronous suspension>
```

**test_core run():**

```
Runner.run()
_loadSuites()
loadFile() - path: /Users/admin/Projects/flutter_test_goldens/test_goldens/flutter/failing_test.dart
LoadSuite() - name: loading /Users/admin/Projects/flutter_test_goldens/test_goldens/flutter/failing_test.dart, path: /Users/admin/Projects/flutter_test_goldens/test_goldens/flutter/failing_test.dart
StackTrace:
#0      new LoadSuite (package:test_core/src/runner/load_suite.dart:88:78)
#1      Loader.loadFile (package:test_core/src/runner/loader.dart:208:15)
<asynchronous suspension>
#2      _StreamController.add (dart:async/stream_controller.dart:616:3)
<asynchronous suspension>
#3      _ForwardingStreamSubscription._handleData (dart:async/stream_pipe.dart:183:3)
<asynchronous suspension>
```

**Generate the code that bootstraps the test:**
The `test_core` package hands control back to `flutter_tools` to bootstrap a test.

```
Generate test bootstrap:
#0      generateTestBootstrap (package:flutter_tools/src/test/flutter_platform.dart:155:49)
#1      FlutterPlatform._generateTestMain (package:flutter_tools/src/test/flutter_platform.dart:813:12)
#2      FlutterPlatform._createListenerDart (package:flutter_tools/src/test/flutter_platform.dart:798:7)
#3      FlutterPlatform._startTest (package:flutter_tools/src/test/flutter_platform.dart:651:20)
#4      FlutterPlatform.loadChannel (package:flutter_tools/src/test/flutter_platform.dart:443:36)
#5      FlutterPlatform.load (package:flutter_tools/src/test/flutter_platform.dart:395:44)
#6      Loader.loadFile.<anonymous closure> (package:test_core/src/runner/loader.dart:216:40)
<asynchronous suspension>
#7      new LoadSuite.<anonymous closure>.<anonymous closure> (package:test_core/src/runner/load_suite.dart:98:19)
<asynchronous suspension>
```