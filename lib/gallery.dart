import 'dart:io';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'database_helper.dart';
import 'product.dart';
import 'login.dart';

class Gallery extends StatefulWidget {
  @override
  _GalleryState createState() => _GalleryState();
}

class _GalleryState extends State<Gallery> {
  TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  bool _showProgressIndicator = false; // New state variable
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchController.addListener(_filterProducts);
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });
    _products = await DatabaseHelper.instance.getProducts();
    _filteredProducts = _products; // Initialize filteredProducts
    setState(() {
      _isLoading = false;
    });
  }

  void _filterProducts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProducts = _products.where((product) {
        final nameMatch = product.name!.toLowerCase().contains(query);
        final codeMatch = product.code!.toLowerCase().contains(query);
        return nameMatch || codeMatch;
      }).toList();
      _currentIndex = 0; // Reset carousel to the first item when searching
    });
  }

  Future<void> _refreshProducts() async {
    setState(() {
      _showProgressIndicator = true; // Show progress indicator
    });

    // Simulate a delay for showing the progress indicator
    await Future.delayed(Duration(seconds: 1));

    await _loadProducts(); // Reload the product data

    setState(() {
      _showProgressIndicator = false; // Hide progress indicator
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Product> productsWithImages = _filteredProducts
        .where((product) => product.image != null && product.image!.isNotEmpty)
        .toList();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pharoan Alur',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Image.asset(
                    'images/ph1.png',
                    width: 180,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                  Spacer(),
                  Center(
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.4,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              cursorColor: Colors.black,
                              decoration: InputDecoration(
                                hintText: 'Rechercher une image par nom ou code',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.black),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.black),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Container(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _filterProducts,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF1B0745),
                                padding: EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                              child: Icon(Icons.search, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Spacer(),
                  _showProgressIndicator
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Color(0xFF1B0745),
                      strokeWidth: 2,
                    ),
                  )
                      : IconButton(
                    onPressed: _refreshProducts,
                    icon: Icon(Icons.refresh, color: Color(0xFF1B0745), size: 25),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => Login()),
                      );
                    },
                    icon: Icon(Icons.exit_to_app, color: Color(0xFF1B0745), size: 25),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 200,
                    color: Color(0xFF1B0745),
                    child: Column(
                      children: [
                        SizedBox(height: 30),
                        Container(
                          width: 160,
                          height: 60,
                          child: Stack(
                            children: [
                              CustomPaint(
                                painter: DashedBorderPainter(),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        IconButton(
                                          onPressed: () => Navigator.of(context).pop(),
                                          icon: Icon(Icons.home),
                                          color: Colors.white,
                                          iconSize: 35,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Accueil',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: _isLoading
                          ? Center(child: CircularProgressIndicator())
                          : productsWithImages.isEmpty
                          ? Center(child: Text("Aucune image disponible"))
                          : productsWithImages.length == 1
                          ? Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                'Galerie',
                                style: TextStyle(
                                  color: Color(0xFF1B0745),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 25,
                                ),
                              )
                            ],
                          ),
                          SizedBox(height: 25),
                          Image.file(
                            File(productsWithImages[0].image!),
                            width: 300,
                            height: 300,
                          ),
                          SizedBox(height: 10),
                          Text(
                            '${productsWithImages[0].name}, ${productsWithImages[0].description}',
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                          : Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                'Galerie',
                                style: TextStyle(
                                  color: Color(0xFF1B0745),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 25,
                                ),
                              )
                            ],
                          ),
                          SizedBox(height: 25),
                          Expanded(
                            child: CarouselSlider.builder(
                              options: CarouselOptions(
                                height: double.infinity,
                                enlargeCenterPage: true,
                                autoPlay: true,
                                aspectRatio: 16 / 9,
                                autoPlayCurve: Curves.fastOutSlowIn,
                                enableInfiniteScroll: true,
                                autoPlayAnimationDuration: Duration(milliseconds: 800),
                                viewportFraction: 0.33,
                                onPageChanged: (index, reason) {
                                  setState(() {
                                    _currentIndex = index;
                                  });
                                },
                              ),
                              itemCount: productsWithImages.length,
                              itemBuilder: (context, index, realIdx) {
                                Product product = productsWithImages[index];
                                bool isSelected = _currentIndex == index;
                                return Builder(
                                  builder: (BuildContext context) {
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Column(
                                        children: [
                                          Container(
                                            width: isSelected ? 300 : 260,
                                            height: isSelected ? 300 : 260,
                                            child: Image.file(
                                              File(product.image!),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          SizedBox(height: 10),
                                          Text(
                                            '${product.name}, ${product.description}',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 16.0,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                          SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(productsWithImages.length, (index) {
                              return Container(
                                width: 6.0,
                                height: 6.0,
                                margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 2.0),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _currentIndex == index
                                      ? Color(0xFF1B0745)
                                      : Color.fromRGBO(0, 0, 0, 0.4),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final double dashWidth = 5.0;
    final double dashSpace = 3.0;

    final Path path = Path();
    double startX = 0;

    // Draw top border
    while (startX < size.width) {
      path.moveTo(startX, 0);
      path.lineTo(startX + dashWidth, 0);
      startX += dashWidth + dashSpace;
    }

    startX = 0;
    // Draw left border
    while (startX < size.height) {
      path.moveTo(0, startX);
      path.lineTo(0, startX + dashWidth);
      startX += dashWidth + dashSpace;
    }

    startX = size.width;
    // Draw bottom border
    while (startX > 0) {
      path.moveTo(startX, size.height);
      path.lineTo(startX - dashWidth, size.height);
      startX -= dashWidth + dashSpace;
    }

    startX = size.height;
    // Draw right border
    while (startX > 0) {
      path.moveTo(size.width, startX);
      path.lineTo(size.width, startX - dashWidth);
      startX -= dashWidth + dashSpace;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
