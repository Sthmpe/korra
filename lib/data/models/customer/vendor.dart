class Vendor {
  final String id;
  final String name;
  final String avatarUrl;
  const Vendor({required this.id, required this.name, required this.avatarUrl});

  static List<Vendor> dummies() => const [
    Vendor(id:'v1', name:'TechHub NG', avatarUrl:'https://i.pravatar.cc/150?img=1'),
    Vendor(id:'v2', name:'HomeKraft',  avatarUrl:'https://i.pravatar.cc/150?img=2'),
    Vendor(id:'v3', name:'GadgetPlug', avatarUrl:'https://i.pravatar.cc/150?img=3'),
  ];
}
