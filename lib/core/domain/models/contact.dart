import 'tag.dart';

class Contact {
  final String name;
  final String initials;
  final List<Tag> tags;
  final int colorIndex;

  Contact(this.name, this.initials, this.tags, this.colorIndex);
}
