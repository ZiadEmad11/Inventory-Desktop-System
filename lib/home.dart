import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as syncfusion_pdf;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'database_helper.dart';
import 'addproduct.dart';
import 'details.dart';
import 'gallery.dart';
import 'login.dart';
import 'product.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/services.dart' show rootBundle;
import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final dbHelper = DatabaseHelper.instance;
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = false;
  TextEditingController _searchController = TextEditingController();
  String _sortOption = 'A-Z'; // Default sorting option

  final _noteController = TextEditingController();
  final _dateTimeController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();



  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchController.addListener(_filterProducts);
  }

  void _loadProducts() async {
    try {
      final products = await dbHelper.getProducts();
      setState(() {
        _products = products;
        _filteredProducts = products; // Initialize filtered products
      });
    } catch (e) {
      print("Error loading products: $e");
    }
  }

  void _filterProducts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProducts = _products.where((product) {
        final nameLower = product.name.toLowerCase();
        final codeLower = product.code.toLowerCase();
        return nameLower.contains(query) || codeLower.contains(query);
      }).toList();
      _sortProducts(); // Sort products after filtering
    });
  }

  void _sortProducts() {
    switch (_sortOption) {
      case 'A-Z':
        _filteredProducts.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'Z-A':
        _filteredProducts.sort((a, b) => b.name.compareTo(a.name));
        break;
      case 'Price: Low to Hight':
        _filteredProducts.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Price: Hight to Low':
        _filteredProducts.sort((a, b) => b.price.compareTo(a.price));
        break;
    }
  }

  void _navigateToAddProduct() async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return AddProductPage();
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Fade transition
          const begin = 0.0;
          const end = 1.0;
          const curve = Curves.easeInOut;

          var tween = Tween(begin: begin, end: end);
          var opacityAnimation = animation.drive(tween.chain(CurveTween(curve: curve)));

          return FadeTransition(opacity: opacityAnimation, child: child);
        },
      ),
    );

    _loadProducts(); // Reload products after adding a new one
  }

  void _navigateTodetails(Product product) async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return Details();
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Fade transition
          const begin = 0.0;
          const end = 1.0;
          const curve = Curves.easeInOut;

          var tween = Tween(begin: begin, end: end);
          var opacityAnimation = animation.drive(tween.chain(CurveTween(curve: curve)));

          return FadeTransition(opacity: opacityAnimation, child: child);
        },
      ),
    );

    _loadProducts(); // Reload products after adding a new one
  }



  void _refreshProducts() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate a delay
    await Future.delayed(Duration(seconds: 1));

    _loadProducts();

    setState(() {
      _isLoading = false;
    });
  }

  void _showImageDialog(String imagePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.7, // Set the size
            height: MediaQuery.of(context).size.height * 0.7,
            child: Image.file(
              File(imagePath),
              fit: BoxFit.contain,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Fermer', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDeleteProduct(int id) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmation de suppression'),
          content: Text('Êtes-vous sûr de vouloir supprimer ce produit ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Annuler', style: TextStyle(color:Color(0xFF8D0000))),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await dbHelper.deleteProduct(id);
                _loadProducts(); // Reload products after deletion
              },
              child: Text('Oui', style: TextStyle(color: Color(0xFF1B0745))),
            ),
          ],
        );
      },
    );
  }


  Future<void> _generateAndOpenPdf() async {
    final pdf = pw.Document();

    // Load fonts
    final arabicFontData = await rootBundle.load('fonts/NotoSansArabic-Regular.ttf');
    final arabicFont = pw.Font.ttf(arabicFontData);

    final defaultFontData = await rootBundle.load('fonts/Helvetica.ttf');
    final defaultFont = pw.Font.ttf(defaultFontData);

    // Load image
    final imageData = await rootBundle.load('images/imgpdf.png');
    final pdfImage = pw.MemoryImage(imageData.buffer.asUint8List());

    // Initialize timezone data
    tz.initializeTimeZones();
    final liberville = tz.getLocation('Africa/Libreville');

    // Get current time in Libreville timezone
    final now = tz.TZDateTime.now(liberville);
    final formattedDate = DateFormat('yyyy-MM-dd \nHH:mm').format(now);

    // Define table headers
    final headers = ['#', 'Nom', 'Description', 'Prix', 'Quantité', 'Code', 'Couleur'];

    // Define column widths
    final columnWidths = {
      0: pw.FixedColumnWidth(80),  // # Column
      1: pw.IntrinsicColumnWidth(), // Name Column
      2: pw.IntrinsicColumnWidth(), // Description Column
      3: pw.FixedColumnWidth(150),  // Price Column
      4: pw.FixedColumnWidth(150),  // Quantity Column
      5: pw.FixedColumnWidth(150), // Code Column
      6: pw.FixedColumnWidth(150), // Color Column
    };

    // Determine which products to include in the PDF
    final List<Product> productsToPrint = _selectedRows.isNotEmpty
        ? _selectedRows.map((index) => _filteredProducts[index]).toList()
        : _filteredProducts;

    // Generate the PDF with watermark
    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: pw.EdgeInsets.all(20),
          buildBackground: (pw.Context context) => pw.Stack(
            children: [
              // Watermark background text
              pw.Positioned.fill(
                child: pw.Center(
                  child: pw.Transform.rotate(
                    angle: 45 * 3.1415927 / 180, // Rotate text 45 degrees
                    child: pw.Opacity(
                      opacity: 0.1, // Light opacity for watermark
                      child: pw.Text(
                        'Pharoan Alur',
                        style: pw.TextStyle(
                          fontSize: 75, // Large font size to cover the page
                          font: defaultFont,
                          color: PdfColors.grey, // Grey color for watermark
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        header: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Image(pdfImage, width: 140, height: 120),
                pw.Text(
                  formattedDate,
                  style: pw.TextStyle(font: defaultFont, fontSize: 12),
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: columnWidths,
              children: [
                _buildTableRow(headers, defaultFont, arabicFont, true, columnWidths),
              ],
            ),
          ],
        ),
        build: (pw.Context context) => [
          pw.Table(
            border: pw.TableBorder.all(),
            columnWidths: columnWidths,
            children: [
              ...productsToPrint.asMap().entries.map((entry) {
                int index = entry.key;
                Product product = entry.value;
                return _buildTableRow([
                  (index + 1).toString(),
                  product.name,
                  product.description,
                  product.price == 0.0 ? '-' : product.price.toString(),
                  product.quantity.toString(),
                  product.code,
                  product.color,
                ], defaultFont, arabicFont, false, columnWidths);
              }).toList(),
            ],
          ),
          pw.SizedBox(height: 30),
          pw.Align(
            alignment: pw.Alignment.bottomRight,
            child: pw.Text(
              'Signature',
              style: pw.TextStyle(font: defaultFont, fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    // Save the PDF
    final outputFile = File('${(await getTemporaryDirectory()).path}/ProductList.pdf');
    await outputFile.writeAsBytes(await pdf.save());
    OpenFile.open(outputFile.path);
  }



  pw.TableRow _buildTableRow(List<String> data, pw.Font defaultFont, pw.Font arabicFont, bool isHeader, Map<int, pw.TableColumnWidth> columnWidths) {
    return pw.TableRow(
      decoration: isHeader ? pw.BoxDecoration(color: PdfColor.fromInt(0xFF1B0745)) : null,
      children: data.asMap().entries.map((entry) {
        int index = entry.key;
        String text = entry.value.isEmpty ? '-' : entry.value;

        // Determine the alignment based on the column width type
        final alignment = columnWidths[index] is pw.FixedColumnWidth
            ? pw.Alignment.center
            : pw.Alignment.centerLeft;

        // Extract the width from the FixedColumnWidth class or set default for IntrinsicColumnWidth
        final cellWidth = columnWidths[index] is pw.FixedColumnWidth
            ? (columnWidths[index] as pw.FixedColumnWidth).width
            : 150.0; // Default width for IntrinsicColumnWidth

        final cellHeight = isHeader ? 15.0 : null; // Set a fixed height for header cells

        // Apply text splitting only to 'name' and 'description'
        if (index == 1 || index == 2) {
          final segments = _splitText(text);
          return pw.Padding(
            padding: pw.EdgeInsets.all(8.0),
            child: pw.Container(
              width: cellWidth,
              height: cellHeight,
              alignment: alignment,
              child: pw.Wrap(
                children: segments.map((segment) {
                  return pw.Text(
                    segment['text'] as String,
                    style: _getFontStyle(segment['text'] as String, arabicFont, defaultFont, isHeader),
                    textDirection: segment['direction'] as pw.TextDirection,
                  );
                }).toList(),
              ),
            ),
          );
        } else {
          return pw.Padding(
            padding: pw.EdgeInsets.all(8.0),
            child: pw.Container(
              width: cellWidth,
              height: cellHeight,
              alignment: alignment,
              color: isHeader ? PdfColor.fromInt(0xFF1B0745) : null,
              child: pw.Text(
                text,
                style: _getFontStyle(text, arabicFont, defaultFont, isHeader),
                overflow: pw.TextOverflow.clip,
              ),
            ),
          );
        }
      }).toList(),
    );
  }

  List<Map<String, dynamic>> _splitText(String text) {
    // Extract English and Arabic text separately
    final englishMatches = RegExp(r'[a-zA-Z0-9\s.,!@#$%^&*()_+-=<>?/\\]+').allMatches(text).map((match) => match.group(0)).where((e) => e != null);
    final arabicMatches = RegExp(r'[\u0600-\u06FF\s.,/\\]+').allMatches(text).map((match) => match.group(0)).where((e) => e != null);

    // Combine segments into a single list of maps
    final combinedText = <Map<String, dynamic>>[];

    // Add English text segments
    if (englishMatches.isNotEmpty) {
      combinedText.add({
        'text': englishMatches.join(''),
        'direction': pw.TextDirection.ltr,
      });
    }

    // Add Arabic text segments
    if (arabicMatches.isNotEmpty) {
      combinedText.add({
        'text': arabicMatches.join(' '),
        'direction': pw.TextDirection.rtl,
      });
    }

    return combinedText;
  }

  pw.TextStyle _getFontStyle(String text, pw.Font arabicFont, pw.Font defaultFont, bool isHeader) {
    final font = text.contains(RegExp(r'[\u0600-\u06FF]')) ? arabicFont : defaultFont;
    return pw.TextStyle(
      font: font,
      fontSize: isHeader ? 12 : 10,
      fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
      color: isHeader ? PdfColors.white : null,
    );
  }



  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Set<int> _selectedRows = {}; // Track selected rows

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedRows.contains(index)) {
        _selectedRows.remove(index);
      } else {
        _selectedRows.add(index);
      }
    });
  }


  @override
  Widget build(BuildContext context) {
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
                                hintText: 'Rechercher un produit par nom ou code',
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
                  _isLoading
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
                                          onPressed: _navigateToAddProduct,
                                          icon: Icon(Icons.add_circle_outline),
                                          color: Colors.white,
                                          iconSize: 35,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Ajouter\nun produit',
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
                        Row(
                          children: [
                            SizedBox(width: 33),
                            IconButton(
                              onPressed:(){Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation, secondaryAnimation) {
                                    return Gallery();
                                  },
                                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                    // Fade transition
                                    const begin = 0.0;
                                    const end = 1.0;
                                    const curve = Curves.easeInOut;

                                    var tween = Tween(begin: begin, end: end);
                                    var opacityAnimation = animation.drive(tween.chain(CurveTween(curve: curve)));

                                    return FadeTransition(opacity: opacityAnimation, child: child);
                                  },
                                ),
                              );},
                              icon: Icon(Icons.image_search),
                              color: Colors.white,
                              iconSize: 35,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Galerie',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        Row(
                          children: [
                            SizedBox(width: 33),
                            IconButton(
                              onPressed:_generateAndOpenPdf,
                              icon: Icon(Icons.local_print_shop_outlined),
                              color: Colors.white,
                              iconSize: 35,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Imprimer',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Tous les produits',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: PopupMenuButton<String>(
                                      icon: Container(
                                        decoration: BoxDecoration(
                                          color: Color(0xFF1B0745),
                                          borderRadius: BorderRadius.circular(25),
                                        ),
                                        padding: EdgeInsets.all(8),
                                        child: Icon(
                                          Icons.filter_list,
                                          color: Colors.white,
                                        ),
                                      ),
                                      itemBuilder: (BuildContext context) {
                                        return [
                                          PopupMenuItem<String>(
                                            value: 'A-Z',
                                            child: Text('A-Z'),
                                          ),
                                          PopupMenuItem<String>(
                                            value: 'Z-A',
                                            child: Text('Z-A'),
                                          ),
                                          PopupMenuItem<String>(
                                            value: 'Price: Low to Hight',
                                            child: Text('Du plus bas au plus élevé (FCFA)'),
                                          ),
                                          PopupMenuItem<String>(
                                            value: 'Price: Hight to Low',
                                            child: Text('Du plus élevé au plus bas (FCFA)'),
                                          ),
                                        ];
                                      },
                                      onSelected: (String value) {
                                        setState(() {
                                          _sortOption = value;
                                          _sortProducts();
                                        });
                                      },
                                      offset: Offset(175, 0), // Adjust this offset as needed
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: _filteredProducts.isEmpty
                                ? Center(
                              child: Text(
                                'Aucune donnée à afficher',
                                style: TextStyle(fontSize: 18, color: Colors.grey),
                              ),
                            )
                                : SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Container(
                                  color: Colors.white,
                                  child: DataTable(
                                    columnSpacing: 10.0,
                                    dataRowHeight: 60.0,
                                    columns: [
                                      DataColumn(
                                        label: Container(
                                          width: 100,
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text('#'),
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Container(
                                          width: 100,
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text('Nom'),
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Container(
                                          width: 100,
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text('Description'),
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Container(
                                          width: 100,
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text('Prix'),
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Container(
                                          width: 100,
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text('Quantité'),
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Container(
                                          width: 100,
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text('Image'),
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Container(
                                          width: 100,
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text('Code'),
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Container(
                                          width: 100,
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text('Couleur'),
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Container(
                                          width: 100,
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text('Supprimer'),
                                          ),
                                        ),
                                      ),
                                    ],
                                    rows:_filteredProducts.asMap().entries.map((entry) {
                                      int index = entry.key;
                                      Product product = entry.value;
                                      return DataRow(
                                        selected: _selectedRows.contains(index), // Highlight row if selected
                                        color: MaterialStateProperty.resolveWith<Color?>(
                                              (Set<MaterialState> states) {
                                            if (states.contains(MaterialState.selected)) {
                                              return Color(
                                                  0xFF33BE41); // Change background color for selected rows
                                            }
                                            return null; // Use default background color for other rows
                                          },
                                        ),
                                        cells: [
                                          DataCell(
                                            GestureDetector(
                                              onTap: () => _toggleSelection(index), // Toggle selection on tap
                                              child: Container(
                                                width: 100,
                                                height: 60.0,
                                                alignment: Alignment.centerLeft,
                                                child: Text((index + 1).toString(),
                                                    style: TextStyle(
                                                      color: _selectedRows.contains(index) ? Colors.white : Colors.black, // Change text color
                                                    )),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Container(
                                              width: 100,
                                              height: 60.0,
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(product.name),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Container(
                                              width: 100,
                                              height: 60.0,
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(product.description),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Container(
                                              width: 100,
                                              height: 60.0,
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(product.price == 0.0 ? '-' : product.price.toString()),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Container(
                                              width: 100,
                                              height: 60.0,
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(product.quantity.toString()),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Container(
                                              width: 100,
                                              height: 60.0,
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: product.image.isNotEmpty
                                                    ? IconButton(
                                                  icon: Icon(Icons.image),
                                                  onPressed: () {
                                                    _showImageDialog(product.image);
                                                  },
                                                )
                                                    : IconButton(
                                                  icon: Icon(Icons.image_not_supported),
                                                  onPressed: () {},
                                                ),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            GestureDetector(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  PageRouteBuilder(
                                                    pageBuilder: (context, animation, secondaryAnimation) {
                                                      return Details(product: product);
                                                    },
                                                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                                      const begin = 0.0;
                                                      const end = 1.0;
                                                      const curve = Curves.easeInOut;

                                                      var tween = Tween(begin: begin, end: end);
                                                      var opacityAnimation = animation.drive(tween.chain(CurveTween(curve: curve)));

                                                      return FadeTransition(opacity: opacityAnimation, child: child);
                                                    },
                                                  ),
                                                );
                                              },
                                              child: Container(
                                                width: 100,
                                                height: 60.0,
                                                child: Align(
                                                  alignment: Alignment.centerLeft,
                                                  child: Text(
                                                    product.code,
                                                    style: TextStyle(color: Color(
                                                        0xFF00108C)),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Container(
                                              width: 100,
                                              height: 60.0,
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(product.color.isEmpty ? '-' : product.color),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Container(
                                              width: 100,
                                              height: 60.0,
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: IconButton(
                                                  icon: Icon(Icons.delete, color: Color(0xFFD50000)),
                                                  onPressed: () => _confirmDeleteProduct(product.id!.toInt()),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ),
                          )



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
