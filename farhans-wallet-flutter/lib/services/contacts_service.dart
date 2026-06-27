import 'package:flutter_contacts/flutter_contacts.dart';

class PickedContact {
  final String name;
  final String? key;
  const PickedContact(this.name, this.key);
}

/// Lets the user attach a person from their address book to an expense or loan.
class ContactsService {
  Future<PickedContact?> pick() async {
    final granted = await FlutterContacts.requestPermission(readonly: true);
    if (!granted) return null;
    final contact = await FlutterContacts.openExternalPick();
    if (contact == null) return null;
    final name = contact.displayName.trim();
    return PickedContact(name.isEmpty ? 'Unknown' : name, contact.id);
  }
}
