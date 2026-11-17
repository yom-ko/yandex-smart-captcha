import 'dart:io';
import 'dart:isolate';

Future<void> main() async {
  final packageConfig = await Isolate.packageConfig;
  final packageRoot = await Isolate.resolvePackageUri(
    Uri.parse('package:patrol_mcp/'),
  );

  if (packageConfig == null || packageRoot == null) {
    throw StateError(
      'Patrol MCP is not resolved. Run flutter pub get in example/ and launch '
      'with --packages=example/.dart_tool/package_config.json.',
    );
  }

  final projectRoot = Directory.fromUri(Platform.script.resolve('../example/'));
  // Bypass Pub startup so the child inherits the MCP streams without a relay.
  final process = await Process.start(
    Platform.resolvedExecutable,
    [
      '--packages=${File.fromUri(packageConfig).path}',
      File.fromUri(packageRoot.resolve('../bin/patrol_mcp.dart')).path,
    ],
    workingDirectory: projectRoot.path,
    environment: {'PROJECT_ROOT': projectRoot.path},
    mode: ProcessStartMode.inheritStdio,
  );
  exitCode = await process.exitCode;
}
