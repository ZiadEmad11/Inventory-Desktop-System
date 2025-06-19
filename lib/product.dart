class Product {
  final int? id;
  final String name;
  final String description;
  final double price;
  final int quantity;
  final String image;
  final String code;
  final String color;

  Product({
    this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.quantity,
    required this.image,
    required this.code,
    required this.color,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'quantity': quantity,
      'image': image,
      'code': code,
      'color': color,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      price: map['price'] as double,
      quantity: map['quantity'],
      image: map['image'],
      code: map['code'],
      color: map['color'],
    );
  }
}
