import 'package:buildpack_dart/buildpack.dart';
import 'package:shelf_hotreload/shelf_hotreload.dart';

void main() {
  withHotreload(run);
}
