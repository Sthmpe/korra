enum ActivityType { payment, dueSoon, link, autopay, expired }

class ActivityItem {
  final String id;
  final ActivityType type;
  final String title;
  final String subtitle; // time / details
  const ActivityItem({required this.id, required this.type, required this.title, required this.subtitle});

  static List<ActivityItem> dummies() => const [
    ActivityItem(id:'a1', type: ActivityType.payment, title:'Installment paid • ₦12,500', subtitle:'Today 10:20 • iPhone 13'),
    ActivityItem(id:'a2', type: ActivityType.dueSoon, title:'Plan due tomorrow • ₦8,200', subtitle:'LG OLED C2 55”'),
    ActivityItem(id:'a3', type: ActivityType.link, title:'New reserve link from TechHub NG', subtitle:'Tap to review'),
  ];
}
