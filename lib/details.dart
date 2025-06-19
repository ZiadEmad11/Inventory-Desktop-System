import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart'; // Import color picker
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:pharoanalur/home.dart';
import 'database_helper.dart';
import 'login.dart';
import 'product.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/widgets.dart' as pdfWidgets;
import 'package:pdf/widgets.dart' as pdf;
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/services.dart' show ByteData, Uint8List, rootBundle;

class Details extends StatefulWidget {
  final Product? product;

  const Details({Key? key, this.product}) : super(key: key);

  @override
  State<Details> createState() => _DetailsState();
}

class _DetailsState extends State<Details> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _codeController = TextEditingController();
  final _colorController = TextEditingController();
  final dbHelper = DatabaseHelper.instance;

  File? _image;
  String? _imagePath;
  Color _selectedColor = Colors.transparent;
  bool _showValidationErrors = false;
  String _errorMessage = '';
  bool _isEditing = false; // To manage the enabled state of text fields

  @override
  void initState() {
    super.initState();

    // Initialize the text controllers with the product data
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _descriptionController.text = widget.product!.description;
      _priceController.text = widget.product!.price.toString();
      _quantityController.text = widget.product!.quantity.toString();
      _codeController.text = widget.product!.code;
      _colorController.text = widget.product!.color;
      _selectedColor = _stringToColor(widget.product!.color);
      _imagePath = widget.product!.image;
      if (_imagePath != null) {
        _image = File(_imagePath!);
      }
    }
  }

  Color _stringToColor(String colorString) {
    if (colorString.isEmpty) return Colors.transparent;
    final colorValue =
        int.tryParse(colorString.replaceFirst('#', ''), radix: 16) ?? 0;
    return Color(colorValue);
  }

  void _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    if (result != null) {
      setState(() {
        _image = File(result.files.single.path!);
        _imagePath = result.files.single.path;
      });
    }
  }

  void _showImagePreview() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.7, // Set the size
            height: MediaQuery.of(context).size.height * 0.7,
            child: Image.file(File(_imagePath!)),
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

  void _pickColor() async {
    Color? pickedColor = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Choisir une couleur'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: _selectedColor,
              onColorChanged: (color) {
                setState(() {
                  _selectedColor = color;
                });
              },
              showLabel: true,
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Sélectionner', style: TextStyle(color: Color(0xFF1B0745))),
              onPressed: () {
                Navigator.of(context).pop(_selectedColor);
              },
            ),
            TextButton(
              child: Text('Annuler', style: TextStyle(color: Color(0xFF8D0000))),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
    if (pickedColor != null) {
      setState(() {
        _selectedColor = pickedColor;
        _colorController.text = _colorToString(pickedColor);
      });
    }
  }

  String _colorToString(Color color) {
    return '#${color.value.toRadixString(16).substring(2)}';
  }

  bool _validatePrice(String value) {
    if (value.isEmpty) return true;

    final cleanedValue = value.replaceAll(',', '');
    return double.tryParse(cleanedValue) != null;
  }

  bool _validateQuantity(String value) {
    if (value.isEmpty) return true;

    return int.tryParse(value) != null;
  }

  void _updateProduct() async {
    String quantityText = _quantityController.text;
    int finalQuantity = _evaluateQuantity(quantityText);
    if (_formKey.currentState!.validate()) {
      final product = Product(
        id: widget.product?.id, // Keep the same ID for the update
        name: _nameController.text,
        description: _descriptionController.text,
        price: double.tryParse(_priceController.text.replaceAll(',', '')) ?? 0,
        quantity: finalQuantity,
        image: _image?.path ?? '',
        code: _codeController.text,
        color: _colorController.text,
      );
      await dbHelper.updateProduct(product);
      Navigator.pop(context);
    }
  }

  void _showUpdateConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmation de mise à jour'),
          content: Text('Êtes-vous sûr de vouloir mettre à jour ce produit ?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Annuler', style: TextStyle(color: Color(0xFF8D0000))),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _updateProduct();
              },
              child: Text('Oui', style: TextStyle(color: Color(0xFF1B0745))),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmation de suppression'),
          content: Text('Êtes-vous sûr de vouloir supprimer ce produit ?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Close the dialog
              child: Text('Annuler', style: TextStyle(color: Color(0xFF8D0000))),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog
                await _deleteProduct(); // Delete the product
              },
              child: Text('Oui', style: TextStyle(color: Color(0xFF1B0745))),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteProduct() async {
    if (widget.product != null) {
      await dbHelper.deleteProduct(
          widget.product!.id!); // Delete the product from the database
      Navigator.pop(context); // Navigate back to the previous screen
    }
  }

  Future<void> generateProductPDF() async {
    final pdfDocument = pw.Document();

    // Load the fonts
    final ByteData arabicFontData = await rootBundle.load('fonts/NotoSansArabic-Regular.ttf');
    final Uint8List arabicFontBytes = arabicFontData.buffer.asUint8List();
    final pw.Font arabicFont = pw.Font.ttf(arabicFontData);

    final ByteData defaultFontData = await rootBundle.load('fonts/Helvetica.ttf');
    final Uint8List defaultFontBytes = defaultFontData.buffer.asUint8List();
    final pw.Font defaultFont = pw.Font.ttf(defaultFontData);

    // Load the logo image
    final ByteData logoImageData = await rootBundle.load('images/imgpdf.png');
    final Uint8List logoImageBytes = logoImageData.buffer.asUint8List();
    final pw.ImageProvider logoImage = pw.MemoryImage(logoImageBytes);

    // Get current date and time in Libreville time zone
    final DateTime now = DateTime.now().toUtc().add(const Duration(hours: 1)); // GMT+1
    final DateFormat dateFormat = DateFormat('yyyy-MM-dd\nHH:mm:ss');
    final String formattedDate = dateFormat.format(now);

    pdfDocument.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Stack(
          children: [
            // Watermark text background
            pw.Positioned.fill(
              child: pw.Center(
                child: pw.Transform.rotate(
                  angle: 45 * 3.1415927 / 180, // Rotate by 45 degrees
                  child: pw.Opacity(
                    opacity: 0.1, // Set opacity for the watermark
                    child: pw.Text(
                      'Pharoan Alur',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: 70, // Large font size to span the page
                        font: defaultFont,
                        color: PdfColors.grey, // Light color for watermark
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 5
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Main content of the PDF
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header with logo and date/time
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Image(logoImage, width: 140, height: 120), // Adjust width/height as needed
                    pw.Text(formattedDate, style: pw.TextStyle(fontSize: 12, font: defaultFont)),
                  ],
                ),
                pw.SizedBox(height: 70),

                // Centered product details title
                pw.Center(
                  child: pw.Text(
                    'Détails du produit ${_codeController.text}',
                    style: pw.TextStyle(
                      fontSize: 15,
                      font: defaultFont,
                      decoration: pw.TextDecoration.underline,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 30),

                // Product details with checks for empty color and zero price
                _createTextField('Nom: ${_nameController.text}', arabicFont, defaultFont),
                pw.SizedBox(height: 20),
                _createTextField('Description: ${_descriptionController.text}', arabicFont, defaultFont),
                pw.SizedBox(height: 20),
                pw.Text('Prix: ${_priceController.text.isEmpty || double.tryParse(_priceController.text) == 0.0 ? '-' : _priceController.text}', style: pw.TextStyle(fontSize: 13, font: defaultFont)),
                pw.SizedBox(height: 20),
                pw.Text('Quantité: ${_quantityController.text}', style: pw.TextStyle(fontSize: 13, font: defaultFont)),
                pw.SizedBox(height: 20),
                pw.Text('Code: ${_codeController.text}', style: pw.TextStyle(fontSize: 13, font: defaultFont)),
                pw.SizedBox(height: 20),
                pw.Text('Couleur: ${_colorController.text.isEmpty ? '-' : _colorController.text}', style: pw.TextStyle(fontSize: 13, font: defaultFont)),
                pw.SizedBox(height: 70),

                // Load the image from file and display it
                if (_imagePath != null && _imagePath!.isNotEmpty)
                  pw.Center(
                    child: pw.Image(
                      pw.MemoryImage(File(_imagePath!).readAsBytesSync()),
                      width: 180,
                      height: 180,
                    ),
                  ),

                pw.SizedBox(height: 20),
                pw.Align(
                  alignment: pw.Alignment.bottomRight,
                  child: pw.Text(
                    'Signature',
                    style: pw.TextStyle(
                      font: defaultFont,
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    // Save the PDF to a file
    final outputFile = File('product_details.pdf');
    await outputFile.writeAsBytes(await pdfDocument.save());

    // Open the PDF file
    OpenFile.open(outputFile.path);
  }


  pw.Widget _createTextField(String text, pw.Font arabicFont, pw.Font defaultFont) {
    // Extract English and Arabic text separately
    final segments = _splitText(text);

    // Build the text widget with appropriate styles
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: segments.map((segment) {
        return pw.Text(
          segment['text'] as String,
          style: _getFontStyle(segment['text'] as String, arabicFont, defaultFont),
          textDirection: segment['direction'] as pw.TextDirection,
        );
      }).toList(),
    );
  }

  List<Map<String, dynamic>> _splitText(String text) {
    // Extract English and Arabic text separately
    final englishMatches = RegExp(r'[a-zA-Z0-9\s.,!@#$%^&*()_+-=<>?/\\]+').allMatches(text).map((match) => match.group(0)).where((e) => e != null);
    final arabicMatches = RegExp(r'[\u0600-\u06FF\s.,/\\]+').allMatches(text).map((match) => match.group(0)).where((e) => e != null);

    // Combine segments into a single list of maps
    final combinedText = <Map<String, dynamic>>[];

    // Add English text segments first
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

  pw.TextStyle _getFontStyle(String text, pw.Font arabicFont, pw.Font defaultFont) {
    final font = text.contains(RegExp(r'[\u0600-\u06FF]')) ? arabicFont : defaultFont;
    return pw.TextStyle(
      font: font,
      fontSize: 13, // Adjust font size as needed
    );
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
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => Login()),
                      );
                    },
                    icon: Icon(Icons.exit_to_app,
                        color: Color(0xFF1B0745), size: 25),
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Détails du produit',
                                  style: TextStyle(
                                    color: Color(0xFF1B0745),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 25,
                                  ),
                                )
                              ],
                            ),
                            SizedBox(height: 25),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                      _nameController, 'Nom', Icons.person,
                                      isRequired: true),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: _buildTextField(_descriptionController,
                                      'Description', Icons.description,
                                      isRequired: true),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(_priceController,
                                      'Prix', Icons.currency_franc,
                                      isPrice: true),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: _buildTextField(_quantityController,
                                      'Quantité', Icons.code,
                                      isQuantity: true, isRequired: true),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    _codeController,
                                    'Code',
                                    Icons.numbers,
                                    isRequired: true,
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: _buildTextField(
                                    _colorController,
                                    'Couleur',
                                    Icons.color_lens,
                                    onIconTap:
                                        _pickColor, // Trigger the color picker when icon is tapped
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: _isEditing
                                        ? _pickImage
                                        : null, // Disable tap if not editing
                                    child: Container(
                                      height: 60,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: Colors.black, // Border color
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          SizedBox(width: 10),
                                          IconButton(
                                            onPressed: _isEditing
                                                ? _pickImage
                                                : null, // Enable only when editing
                                            icon: Icon(Icons.upload_file,
                                                color: _isEditing
                                                    ? Color(0xFF1B0745)
                                                    : Colors.grey),
                                          ),
                                          SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              _imagePath != null &&
                                                      _imagePath!.isNotEmpty
                                                  ? _imagePath!
                                                  : 'Aucun fichier sélectionné',
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(fontSize: 14),
                                            ),
                                          ),
                                          if (_image != null &&
                                              _imagePath!.isNotEmpty)
                                            IconButton(
                                              onPressed: _showImagePreview,
                                              icon: Icon(
                                                Icons.remove_red_eye,
                                                color: Color(0xFF1B0745),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: SizedBox.shrink(),
                                ),
                              ],
                            ),
                            SizedBox(height: 30),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Visibility(
                                  visible: !_isEditing,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        _isEditing = true;
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF1B0745),
                                      padding: EdgeInsets.symmetric(
                                          vertical: 15, horizontal: 30),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      textStyle: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    child: Text('Mettre à jour',style: TextStyle(color: Colors.white)),
                                  ),
                                ),
                                Visibility(
                                  visible: _isEditing,
                                  child: ElevatedButton(
                                    onPressed: _showUpdateConfirmationDialog,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF1B0745),
                                      padding: EdgeInsets.symmetric(
                                          vertical: 15, horizontal: 30),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      textStyle: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    child: Text('Appliquer',style: TextStyle(color: Colors.white)),
                                  ),
                                ),
                                SizedBox(width: 20),
                                ElevatedButton(
                                  onPressed: _showDeleteConfirmationDialog,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF1B0745),
                                    padding: EdgeInsets.symmetric(
                                        vertical: 15, horizontal: 30),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    textStyle: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  child: Text('Annuler',style: TextStyle(color: Colors.white)),
                                ),
                                SizedBox(width: 20),
                                ElevatedButton(
                                  onPressed: generateProductPDF,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF1B0745),
                                    padding: EdgeInsets.symmetric(
                                        vertical: 15, horizontal: 30),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    textStyle: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  child: Text('Imprimer',style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                            if (_errorMessage.isNotEmpty) ...[
                              SizedBox(height: 8),
                              Text(
                                _errorMessage,
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ],
                        ),
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

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {bool isRequired = false,
      bool isPrice = false,
      bool isQuantity = false,
      VoidCallback? onIconTap // Added parameter for icon tap handling
      }) {
    return TextFormField(
      controller: controller,
      keyboardType: isQuantity ? TextInputType.text : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: GestureDetector(
          onTap:
              onIconTap, // Call the provided callback when the icon is tapped
          child: Icon(icon, color: Colors.black),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Color(0xFF1B0745)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Color(0xFF1B0745)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Color(0xFF1B0745)),
        ),
        labelStyle: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
        suffixIcon: isRequired && controller.text.isEmpty
            ? Icon(Icons.error, color: Colors.red)
            : null,
      ),
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return 'Ce champ est requis';
        }
        if (isPrice && !_validatePrice(value!)) {
          return 'Veuillez entrer un prix valide';
        }
        if (isQuantity && !_validateQuantity(value!)) {
          return 'Veuillez entrer une quantité valide';
        }
        return null;
      },
      enabled: _isEditing,
      onChanged: isQuantity ? _evaluateQuantity : null,
    );
  }


  int _evaluateQuantity(String value) {
    try {
      // Remove all spaces
      String sanitizedValue = value.replaceAll(' ', '');

      // Split the expression into numbers and operators
      List<String> parts = sanitizedValue.split(RegExp(r'(\+|\-)'));
      List<String> operators = sanitizedValue.split(RegExp(r'\d+')).where((e) => e.isNotEmpty).toList();

      int result = int.parse(parts[0]);

      for (int i = 1; i < parts.length; i++) {
        if (operators[i - 1] == '+') {
          result += int.parse(parts[i]);
        } else if (operators[i - 1] == '-') {
          result -= int.parse(parts[i]);
        }
      }

      return result;
    } catch (e) {
      print('Invalid expression: $e');
      return 0;
    }
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
