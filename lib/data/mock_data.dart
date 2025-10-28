enum OrderStatus { pending, inProgress, completed }

class Order {
  final String id;
  final String title;
  final String client;
  final String daysLeft;
  final String price;
  final OrderStatus status;

  Order({
    required this.id,
    required this.title,
    required this.client,
    required this.daysLeft,
    required this.price,
    required this.status,
  });
}

// ✅ Updated List with Pending Included
final List<Order> mockOrders = [
  Order(
    id: '#12345',
    title: 'Suit Alteration',
    client: 'Atif Aslam',
    daysLeft: '2 days left',
    price: '1000 Pkr',
    status: OrderStatus.pending,
  ),
  Order(
    id: '#12346',
    title: 'Bridal Suit',
    client: 'Atif Aslam',
    daysLeft: '10 days left',
    price: '9000 Pkr',
    status: OrderStatus.completed,
  ),
  Order(
    id: '#12347',
    title: 'Custom Tuxedo',
    client: 'Hamid',
    daysLeft: '5 days left',
    price: '8000 Pkr',
    status: OrderStatus.inProgress,
  ),
  Order(
    id: '#12348',
    title: 'Party Dress',
    client: 'Justin Bieber',
    daysLeft: '10 days left',
    price: '5500 Pkr',
    status: OrderStatus.inProgress,
  ),
  Order(
    id: '#12349',
    title: 'Lehenga Stitching',
    client: 'Tooba Fayyaz',
    daysLeft: '28 days left',
    price: '7000 Pkr',
    status: OrderStatus.inProgress,
  ),
];
