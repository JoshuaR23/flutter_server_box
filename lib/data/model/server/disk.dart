import '../../res/misc.dart';

class Disk {
  final String path;
  final String loc;
  final int usedPercent;
  final String used;
  final String size;
  final String avail;

  Disk({
    required this.path,
    required this.loc,
    required this.usedPercent,
    required this.used,
    required this.size,
    required this.avail,
  });
}

List<Disk> parseDisk(String raw) {
  final list = <Disk>[];
  final items = raw.split('\n');
  items.removeAt(0);
  var pathCache = '';
  for (var item in items) {
    if (item.isEmpty) {
      continue;
    }
    final vals = item.split(numReg);
    if (vals.length == 1) {
      pathCache = vals[0];
      continue;
    }
    if (pathCache != '') {
      vals[0] = pathCache;
      pathCache = '';
    }
    list.add(Disk(
      path: vals[0],
      loc: vals[5],
      usedPercent: int.parse(vals[4].replaceFirst('%', '')),
      used: vals[2],
      size: vals[1],
      avail: vals[3],
    ));
  }
  return list;
}