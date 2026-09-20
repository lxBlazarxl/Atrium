import 'models/transmission_detail.dart';

/// A folder or file in a torrent, built from Transmission's flat file list.
///
/// Transmission reports files as `a/b/c.ext` paths with no folder objects, so
/// the tree is derived, and everything a folder says about itself (size,
/// progress, wanted) is summed from the files beneath it.
class TransmissionFileNode {
  TransmissionFileNode({
    required this.name,
    required this.path,
    this.fileIndex,
    this.file,
  });

  final String name;

  /// The full slash-separated path, which `torrent-rename-path` addresses.
  final String path;
  final List<TransmissionFileNode> children = <TransmissionFileNode>[];

  /// Index into the torrent's file list; null for a folder.
  final int? fileIndex;
  final TransmissionFile? file;

  bool get isFolder => fileIndex == null;

  int get length =>
      file?.length ??
      children.fold(0, (int s, TransmissionFileNode c) => s + c.length);

  int get bytesCompleted =>
      file?.bytesCompleted ??
      children.fold(0, (int s, TransmissionFileNode c) => s + c.bytesCompleted);

  double get progress =>
      length <= 0 ? 0 : (bytesCompleted / length).clamp(0, 1).toDouble();

  /// Every file index under this node, in file order.
  List<int> get indices => isFolder
      ? <int>[for (final TransmissionFileNode c in children) ...c.indices]
      : <int>[fileIndex!];

  bool get allWanted => isFolder
      ? children.every((TransmissionFileNode c) => c.allWanted)
      : file!.wanted;

  bool get anyWanted => isFolder
      ? children.any((TransmissionFileNode c) => c.anyWanted)
      : file!.wanted;
}

/// Builds the tree. The root has an empty name; its children are the top
/// level, which for a single-file torrent is that one file.
TransmissionFileNode buildTransmissionFileTree(List<TransmissionFile> files) {
  final TransmissionFileNode root = TransmissionFileNode(name: '', path: '');
  for (int i = 0; i < files.length; i++) {
    final TransmissionFile f = files[i];
    final List<String> parts = f.name.split('/');
    TransmissionFileNode node = root;
    for (int p = 0; p < parts.length; p++) {
      final String part = parts[p];
      final String path = parts.sublist(0, p + 1).join('/');
      if (p == parts.length - 1) {
        node.children.add(
          TransmissionFileNode(name: part, path: path, fileIndex: i, file: f),
        );
      } else {
        TransmissionFileNode? folder;
        for (final TransmissionFileNode c in node.children) {
          if (c.isFolder && c.name == part) {
            folder = c;
            break;
          }
        }
        if (folder == null) {
          folder = TransmissionFileNode(name: part, path: path);
          node.children.add(folder);
        }
        node = folder;
      }
    }
  }
  return root;
}
