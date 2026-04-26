class Space {
  final String id;
  final String name;
  final String address;
  final double pricePerHour;
  final String imageUrl;
  final bool isAvailable;

  Space({
    required this.id,
    required this.name,
    required this.address,
    required this.pricePerHour,
    this.imageUrl = 'https://via.placeholder.com/150',
    this.isAvailable = true,
  });
}