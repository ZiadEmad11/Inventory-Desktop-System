import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart'; // Import color picker
import 'package:pharoanalur/home.dart';
import 'database_helper.dart';
import 'login.dart';
import 'product.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({Key? key}) : super(key: key);

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
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

  void _pickColor() async {
    Color? pickedColor = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Choisissez une couleur'),
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

  void _addProduct() async {
    setState(() {
      _showValidationErrors = true;
      _errorMessage = '';
    });

    bool isPriceValid = _validatePrice(_priceController.text);
    bool isQuantityValid = _validateQuantity(_quantityController.text);

    if (!isPriceValid || !isQuantityValid) {
      if (!isPriceValid && !isQuantityValid) {
        setState(() {
          _errorMessage = 'Veuillez saisir des valeurs valides pour le prix et la quantité.';
        });
      } else if (!isPriceValid) {
        setState(() {
          _errorMessage = 'Veuillez saisir un prix valide (uniquement des chiffres et des virgules).';
        });
      } else if (!isQuantityValid) {
        setState(() {
          _errorMessage = 'Veuillez saisir une quantité valide (uniquement des entiers).';
        });
      }
      return;
    }

    bool isValid = _nameController.text.isNotEmpty &&
        _descriptionController.text.isNotEmpty &&
        _quantityController.text.isNotEmpty &&
        _codeController.text.isNotEmpty;

    if (isValid) {
      final product = Product(
        name: _nameController.text,
        description: _descriptionController.text,
        price: double.tryParse(_priceController.text.replaceAll(',', '')) ?? 0,
        quantity: int.tryParse(_quantityController.text) ?? 0,
        image: _image?.path ?? '',
        code: _codeController.text,
        color: _colorController.text,
      );
      await dbHelper.insertProduct(product);
      Navigator.pop(context);
    }
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
                                  'Ajouter un produit',
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
                                  child: _buildTextField(_nameController, 'Nom', Icons.person, isRequired: true),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: _buildTextField(_descriptionController, 'Description', Icons.description, isRequired: true),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: _buildTextField(_priceController, 'Prix', Icons.currency_franc, keyboardType: TextInputType.number),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(_quantityController, 'Quantité', Icons.code, keyboardType: TextInputType.number, isRequired: true),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: _buildTextField(_codeController, 'Code', Icons.numbers, isRequired: true),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: _buildTextField(_colorController, 'Couleur', Icons.color_lens, isColorField: true),
                                ),
                              ],
                            ),SizedBox(height: 16),
                            Row(
                              children: [
                                Text(
                                  'Image',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(width: 16),
                                IconButton(
                                  onPressed: _pickImage,
                                  icon: Icon(Icons.upload_file, color: Color(0xFF1B0745)),
                                  iconSize: 30,
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    _imagePath != null ? _imagePath! : 'Aucun fichier sélectionné',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 25),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                ElevatedButton(
                                  onPressed: _addProduct,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF1B0745),
                                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    textStyle: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  child: Text('Ajouter',style: TextStyle(color: Colors.white),),
                                ),
                                SizedBox(width: 16),
                                if (_showValidationErrors && _errorMessage.isNotEmpty)
                                  Expanded(
                                    child: Text(
                                      _errorMessage,
                                      style: TextStyle(color: Colors.red, fontSize: 16),
                                    ),
                                  ),
                              ],
                            ),

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

  Widget _buildTextField(TextEditingController controller, String labelText, IconData icon, {TextInputType keyboardType = TextInputType.text, bool isColorField = false, bool isRequired = false}) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool _isFieldEmpty = controller.text.isEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '$labelText',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                if (_showValidationErrors && _isFieldEmpty && isRequired)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(
                      '*',
                      style: TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 8),
            Container(
              width: double.infinity,
              child: TextFormField(
                cursorColor: Colors.black,
                controller: controller,
                keyboardType: keyboardType,
                decoration: InputDecoration(
                  prefixIcon: isColorField
                      ? IconButton(
                    icon: Icon(icon, color: Colors.black),
                    onPressed: _pickColor,
                  )
                      : Icon(icon, color: Colors.black),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (value) {
                  setState(() {});
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _navigateToAddProduct() async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return Home();
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