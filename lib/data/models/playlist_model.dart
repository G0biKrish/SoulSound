import 'package:isar/isar.dart';

part 'playlist_model.g.dart';

@collection
class PlaylistModel {
  Id id = Isar.autoIncrement;

  late String name;

  late DateTime dateCreated;

  int? iconCode;

  String? artworkPath; // Custom user image path

  // Storing song IDs directly is simpler than Links for manual reordering
  // but Links ensure integrity.
  // For playlist ordering, we might need a separate join or just a list of IDs.
  // Isar List<int> is efficient.
  List<int> songIds = [];
}
