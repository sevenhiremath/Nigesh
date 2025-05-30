import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Contact {
  final String id, name, phone, email;
  bool isFavorite;
  Contact({required this.id, required this.name, required this.phone, required this.email, this.isFavorite = false});
  Contact copyWith({String? name, String? phone, String? email, bool? isFavorite}) => Contact(
    id: id, name: name ?? this.name, phone: phone ?? this.phone, email: email ?? this.email, isFavorite: isFavorite ?? this.isFavorite,
  );
}

void main() => runApp(const ContactsApp());

class ContactsApp extends StatelessWidget {
  const ContactsApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Contacts',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal, brightness: Brightness.dark, primary: Colors.teal[400], surface: Colors.grey[900]),
      textTheme: GoogleFonts.interTextTheme().apply(bodyColor: Colors.white, displayColor: Colors.white),
      useMaterial3: true,
      appBarTheme: AppBarTheme(backgroundColor: Colors.grey[900], foregroundColor: Colors.teal[400], elevation: 0),
      floatingActionButtonTheme: FloatingActionButtonThemeData(backgroundColor: Colors.teal[400], foregroundColor: Colors.black),
      cardTheme: CardThemeData(color: Colors.grey[900], elevation: 6, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.teal[400]!, width: 1))),
      elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[400], foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
      inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: Colors.grey[800], border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.teal[400]!)), focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.teal[200]!, width: 2))),
    ),
    home: const HomeScreen(),
    debugShowCheckedModeBanner: false,
  );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final _contacts = [
    Contact(id: '1', name: 'Alice Wonderland', phone: '123-456-7890', email: 'alice@example.com'),
    Contact(id: '2', name: 'Bob The Builder', phone: '987-654-3210', email: 'bob@example.com', isFavorite: true),
    Contact(id: '3', name: 'Charlie Chaplin', phone: '555-555-5555', email: 'charlie@example.com'),
  ];
  final _recentContactIds = <String>{};
  static const _maxRecents = 10;

  void _addContact(Contact c) => setState(() {
    _contacts.add(c);
    _contacts.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    _recentContactIds..remove(c.id)..add(c.id);
    if (_recentContactIds.length > _maxRecents) _recentContactIds.remove(_recentContactIds.first);
  });

  void _updateContact(Contact c) => setState(() {
    final i = _contacts.indexWhere((x) => x.id == c.id);
    if (i != -1) _contacts[i] = c;
    _contacts.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  });

  void _deleteContact(String id) => setState(() {
    _contacts.removeWhere((c) => c.id == id);
    _recentContactIds.remove(id);
  });

  void _toggleFavorite(Contact c) => setState(() {
    c.isFavorite = !c.isFavorite;
    _updateContact(c.copyWith());
  });

  List<Contact> _getRecentContacts() => _recentContactIds.toList().reversed
    .map((id) => _contacts.firstWhere((c) => c.id == id, orElse: () => Contact(id: '', name: '', phone: '', email: '')))
    .where((c) => c.id.isNotEmpty).toList();

  void _openDetails(Contact c) async {
    _recentContactIds..remove(c.id)..add(c.id);
    final updated = await Navigator.push<Contact>(context, MaterialPageRoute(
      builder: (_) => ContactDetailsScreen(
        contact: c,
        onUpdate: _updateContact,
        onDelete: _deleteContact,
        onToggleFavorite: _toggleFavorite,
      ),
    ));
    if (updated != null) _updateContact(updated);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final favorites = _contacts.where((c) => c.isFavorite).toList();
    final recents = _getRecentContacts();
    final tabs = [
      MainContactsTab(contacts: _contacts, onContactTap: _openDetails, onAddContact: () async {
        final newContact = await Navigator.push<Contact>(context, MaterialPageRoute(builder: (_) => const AddContactScreen()));
        if (newContact != null) _addContact(newContact);
      }),
      ContactsList(contacts: recents, emptyText: 'No recent contacts.', onTap: _openDetails),
      ContactsList(contacts: favorites, emptyText: 'No favorite contacts.', onTap: _openDetails, showStar: true),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Contacts')),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(image: AssetImage('assets/images/bg.jpg'), fit: BoxFit.cover, colorFilter: ColorFilter.mode(Colors.black87, BlendMode.darken)),
        ),
        child: tabs[_currentIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: Colors.teal[400],
        backgroundColor: Colors.grey[900],
        unselectedItemColor: Colors.grey[400],
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Contacts'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Recents'),
          BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Favorites'),
        ],
      ),
    );
  }
}

class MainContactsTab extends StatefulWidget {
  final List<Contact> contacts;
  final Function(Contact) onContactTap;
  final VoidCallback onAddContact;
  const MainContactsTab({super.key, required this.contacts, required this.onContactTap, required this.onAddContact});
  @override
  State<MainContactsTab> createState() => _MainContactsTabState();
}

class _MainContactsTabState extends State<MainContactsTab> {
  String _search = '';
  List<Contact> get _filtered => _search.isEmpty
    ? widget.contacts
    : widget.contacts.where((c) =>
      c.name.toLowerCase().contains(_search.toLowerCase()) ||
      c.phone.toLowerCase().contains(_search.toLowerCase()) ||
      c.email.toLowerCase().contains(_search.toLowerCase())
    ).toList();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Search Contacts',
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: Icon(Icons.search, color: Colors.teal[400]),
            border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.teal[400]!)),
          ),
          style: const TextStyle(color: Colors.white),
          onChanged: (v) => setState(() => _search = v),
        ),
      ),
      Expanded(
        child: ContactsList(
          contacts: _filtered,
          emptyText: 'No contacts. Add one!',
          onTap: widget.onContactTap,
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(16),
        child: FloatingActionButton.extended(
          onPressed: widget.onAddContact,
          label: const Text('Add Contact'),
          icon: const Icon(Icons.add),
        ),
      ),
    ],
  );
}

class ContactsList extends StatelessWidget {
  final List<Contact> contacts;
  final String emptyText;
  final Function(Contact) onTap;
  final bool showStar;
  const ContactsList({super.key, required this.contacts, required this.emptyText, required this.onTap, this.showStar = false});
  @override
  Widget build(BuildContext context) => contacts.isEmpty
    ? Center(child: Text(emptyText, style: const TextStyle(color: Colors.white)))
    : ListView.builder(
      itemCount: contacts.length,
      itemBuilder: (_, i) {
        final c = contacts[i];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey[800],
              child: Text(c.name[0].toUpperCase(), style: TextStyle(fontSize: 20, color: Colors.teal[400])),
            ),
            title: Text(c.name, style: const TextStyle(color: Colors.white)),
            subtitle: Text(c.phone, style: TextStyle(color: Colors.grey[400])),
            trailing: (showStar || c.isFavorite) ? Icon(Icons.star, color: Colors.teal[200]) : null,
            onTap: () => onTap(c),
          ),
        );
      },
    );
}

class AddContactScreen extends StatefulWidget {
  const AddContactScreen({super.key});
  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController(), _phone = TextEditingController(), _email = TextEditingController();
  @override
  void dispose() { _name.dispose(); _phone.dispose(); _email.dispose(); super.dispose(); }
  void _save() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, Contact(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _name.text, phone: _phone.text, email: _email.text,
      ));
    }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Add Contact')),
    body: _ContactForm(formKey: _formKey, name: _name, phone: _phone, email: _email, onSave: _save, buttonText: 'Save Contact'),
  );
}

class EditContactScreen extends StatefulWidget {
  final Contact contact;
  const EditContactScreen({super.key, required this.contact});
  @override
  State<EditContactScreen> createState() => _EditContactScreenState();
}

class _EditContactScreenState extends State<EditContactScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.contact.name);
  late final _phone = TextEditingController(text: widget.contact.phone);
  late final _email = TextEditingController(text: widget.contact.email);
  late bool _isFavorite = widget.contact.isFavorite;
  @override
  void dispose() { _name.dispose(); _phone.dispose(); _email.dispose(); super.dispose(); }
  void _save() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, widget.contact.copyWith(
        name: _name.text, phone: _phone.text, email: _email.text, isFavorite: _isFavorite,
      ));
    }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Edit Contact')),
    body: _ContactForm(
      formKey: _formKey, name: _name, phone: _phone, email: _email, onSave: _save, buttonText: 'Save Changes',
      isFavorite: _isFavorite, onFavoriteChanged: (v) => setState(() => _isFavorite = v),
    ),
  );
}

class _ContactForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController name, phone, email;
  final VoidCallback onSave;
  final String buttonText;
  final bool? isFavorite;
  final ValueChanged<bool>? onFavoriteChanged;
  const _ContactForm({
    required this.formKey, required this.name, required this.phone, required this.email, required this.onSave, required this.buttonText,
    this.isFavorite, this.onFavoriteChanged,
  });
  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      image: DecorationImage(image: AssetImage('assets/images/bg.jpg'), fit: BoxFit.cover, colorFilter: ColorFilter.mode(Colors.black87, BlendMode.darken)),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: formKey,
        child: ListView(
          children: [
            TextFormField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Name'),
              style: const TextStyle(color: Colors.white),
              validator: (v) => v!.isEmpty ? 'Enter a name' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: phone,
              decoration: const InputDecoration(labelText: 'Phone'),
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.phone,
              validator: (v) => v!.isEmpty ? 'Enter a phone number' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: email,
              decoration: const InputDecoration(labelText: 'Email'),
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.emailAddress,
              validator: (v) => v!.isNotEmpty && !v.contains('@') ? 'Enter a valid email' : null,
            ),
            if (isFavorite != null && onFavoriteChanged != null)
              SwitchListTile(
                title: const Text('Favorite', style: TextStyle(color: Colors.white)),
                value: isFavorite!,
                onChanged: onFavoriteChanged,
                activeColor: Colors.teal[200],
              ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: onSave, child: Text(buttonText)),
          ],
        ),
      ),
    ),
  );
}

class ContactDetailsScreen extends StatelessWidget {
  final Contact contact;
  final Function(Contact) onUpdate, onToggleFavorite;
  final Function(String) onDelete;
  const ContactDetailsScreen({super.key, required this.contact, required this.onUpdate, required this.onToggleFavorite, required this.onDelete});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(contact.name),
      actions: [
        IconButton(
          icon: Icon(contact.isFavorite ? Icons.star : Icons.star_border, color: contact.isFavorite ? Colors.teal[200] : Colors.teal[400]),
          onPressed: () => onToggleFavorite(contact),
        ),
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () async {
            final updated = await Navigator.push<Contact>(context, MaterialPageRoute(builder: (_) => EditContactScreen(contact: contact)));
            if (updated != null) onUpdate(updated);
          },
        ),
        IconButton(
          icon: Icon(Icons.delete, color: Colors.red[400]),
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                backgroundColor: Colors.grey[900],
                title: const Text('Delete Contact', style: TextStyle(color: Colors.white)),
                content: Text('Delete ${contact.name}?', style: const TextStyle(color: Colors.white)),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: Colors.teal[400]))),
                  TextButton(
                    onPressed: () {
                      onDelete(contact.id);
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    child: Text('Delete', style: TextStyle(color: Colors.red[400])),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    ),
    body: Container(
      decoration: const BoxDecoration(
        image: DecorationImage(image: AssetImage('assets/images/bg.jpg'), fit: BoxFit.cover, colorFilter: ColorFilter.mode(Colors.black87, BlendMode.darken)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[800],
                child: Text(contact.name[0].toUpperCase(), style: TextStyle(fontSize: 40, color: Colors.teal[400])),
              ),
            ),
            const SizedBox(height: 24),
            ...[
              [Icons.person, 'Name', contact.name],
              [Icons.phone, 'Phone', contact.phone],
              [Icons.email, 'Email', contact.email.isEmpty ? 'Not provided' : contact.email],
            ].map((e) => Card(
              child: ListTile(
                leading: Icon(e[0] as IconData, color: Colors.teal[400]),
                title: Text(e[1] as String, style: const TextStyle(color: Colors.white)),
                subtitle: Text(e[2] as String, style: TextStyle(color: Colors.grey[400])),
              ),
            )),
          ],
        ),
      ),
    ),
  );
}
