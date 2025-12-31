// filepath: lib/SignupPage/signup_screen.dart

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import '../Services/global_variables.dart';
import '../service/global_method.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  final _signUpFormKey = GlobalKey<FormState>();

  File? imageFile;

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailTextController = TextEditingController();
  final TextEditingController _passTextController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _phoneNumberFocusNode = FocusNode();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? imageUrl;

  bool _obscureText = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.linear),
    )..addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fullNameController.dispose();
    _emailTextController.dispose();
    _passTextController.dispose();
    _phoneNumberController.dispose();
    _locationController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _phoneNumberFocusNode.dispose();
    super.dispose();
  }

  void _showImageDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Please Choose an option'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: _getFromCamera,
                child: const Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(Icons.camera_alt, color: Colors.purple),
                    ),
                    Text('Camera', style: TextStyle(color: Colors.purple)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: _getFromGallery,
                child: const Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(Icons.image, color: Colors.purple),
                    ),
                    Text('Gallery', style: TextStyle(color: Colors.purple)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _getFromCamera() async {
    XFile? pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile != null) _cropImage(pickedFile.path);
    if (mounted) Navigator.pop(context);
  }

  void _getFromGallery() async {
    XFile? pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) _cropImage(pickedFile.path);
    if (mounted) Navigator.pop(context);
  }

  void _cropImage(String filePath) async {
    CroppedFile? croppedImage = await ImageCropper().cropImage(
      sourcePath: filePath,
      maxWidth: 1080,
      maxHeight: 1080,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: Colors.cyan,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
          aspectRatioPresets: [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio3x2,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9,
          ],
        ),
        IOSUiSettings(title: 'Crop Image'),
        WebUiSettings(
          context: context,
          presentStyle: WebPresentStyle.dialog,
          size: const CropperSize(width: 520, height: 520),
        ),
      ],
    );

    if (croppedImage != null) {
      setState(() {
        imageFile = File(croppedImage.path);
      });
    }
  }

  // FIXED: Proper await on upload + better error handling
  void _submitFormOnSignUp() async {
    final isValid = _signUpFormKey.currentState!.validate();
    if (!isValid) return;

    if (imageFile == null) {
      GlobalMethod.showErrorDialog(
        error: 'Please pick an image',
        ctx: context,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Create user in Firebase Auth
      await _auth.createUserWithEmailAndPassword(
        email: _emailTextController.text.trim().toLowerCase(),
        password: _passTextController.text.trim(),
      );

      final User? user = _auth.currentUser;
      final String uid = user!.uid;

      // 2. Upload image — MUST await the task!
      final UploadTask uploadTask = FirebaseStorage.instance
          .ref()
          .child('userImages')
          .child('$uid.png')
          .putFile(imageFile!);

      final TaskSnapshot snapshot = await uploadTask;
      imageUrl = await snapshot.ref.getDownloadURL();

      // 3. Save user data to Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'id': uid,
        'name': _fullNameController.text.trim(),
        'email': _emailTextController.text.trim().toLowerCase(),
        'userImage': imageUrl,
        'phoneNumber': _phoneNumberController.text.trim(),
        'location': _locationController.text.trim(),
        'createdAt': Timestamp.now(),
      });

      // SUCCESS!
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );

        Navigator.canPop(context) ? Navigator.pop(context) : null;
      }
    } on FirebaseAuthException catch (e) {
      GlobalMethod.showErrorDialog(error: e.message ?? 'Authentication failed', ctx: context);
    } on FirebaseException catch (e) {
      GlobalMethod.showErrorDialog(error: e.message ?? 'Upload/Firestore failed', ctx: context);
    } catch (e) {
      GlobalMethod.showErrorDialog(error: 'Unexpected error: $e', ctx: context);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/signup.jpg',
              fit: BoxFit.cover,
              alignment: FractionalOffset(_animation.value, 0), // Keeps your sliding animation!
            ),
          ),

          Container(
            color: Colors.black54,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 80),
              child: ListView(
                children: [
                  Form(
                    key: _signUpFormKey,
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _showImageDialog,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                              width: size.width * 0.24,
                              height: size.width * 0.24,
                              decoration: BoxDecoration(
                                border: Border.all(width: 1, color: Colors.cyan),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: imageFile == null
                                    ? const Icon(Icons.camera_enhance_sharp, color: Colors.cyan, size: 30)
                                    : Image.file(imageFile!, fit: BoxFit.cover),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),
                        const Text(
                          'Tap the circle to add profile picture',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),

                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _fullNameController,
                          textInputAction: TextInputAction.next,
                          onEditingComplete: () => FocusScope.of(context).requestFocus(_emailFocusNode),
                          keyboardType: TextInputType.name,
                          validator: (value) => value!.isEmpty ? 'This field is missing' : null,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Full name / Company name',
                            hintStyle: TextStyle(color: Colors.white),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                          ),
                        ),

                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _emailTextController,
                          textInputAction: TextInputAction.next,
                          onEditingComplete: () => FocusScope.of(context).requestFocus(_passwordFocusNode),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) => value!.isEmpty || !value.contains('@')
                              ? 'Please enter a valid email address'
                              : null,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Email',
                            hintStyle: TextStyle(color: Colors.white),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                          ),
                        ),

                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _passTextController,
                          textInputAction: TextInputAction.next,
                          onEditingComplete: () => FocusScope.of(context).requestFocus(_phoneNumberFocusNode),
                          keyboardType: TextInputType.visiblePassword,
                          obscureText: !_obscureText,
                          validator: (value) => value!.isEmpty || value.length < 7
                              ? 'Please enter a valid password (min 7 characters)'
                              : null,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Password',
                            hintStyle: const TextStyle(color: Colors.white),
                            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                            suffixIcon: GestureDetector(
                              onTap: () => setState(() => _obscureText = !_obscureText),
                              child: Icon(_obscureText ? Icons.visibility : Icons.visibility_off, color: Colors.white),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _phoneNumberController,
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.phone,
                          validator: (value) => value!.isEmpty ? 'This field is missing' : null,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Phone Number',
                            hintStyle: TextStyle(color: Colors.white),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                          ),
                        ),

                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _locationController,
                          textInputAction: TextInputAction.done,
                          keyboardType: TextInputType.text,
                          validator: (value) => value!.isEmpty ? 'This field is missing' : null,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Company Address',
                            hintStyle: TextStyle(color: Colors.white),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                          ),
                        ),

                        const SizedBox(height: 30),
                        _isLoading
                            ? const Center(
                          child: SizedBox(
                            width: 70,
                            height: 70,
                            child: CircularProgressIndicator(color: Colors.cyan),
                          ),
                        )
                            : MaterialButton(
                          onPressed: _submitFormOnSignUp,
                          color: Colors.cyan,
                          elevation: 8,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Sign Up',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),
                        Center(
                          child: RichText(
                            text: TextSpan(
                              children: [
                                const TextSpan(
                                  text: 'Already have an Account? ',
                                  style: TextStyle(color: Colors.white, fontSize: 16),
                                ),
                                TextSpan(
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () => Navigator.canPop(context) ? Navigator.pop(context) : null,
                                  text: 'Login',
                                  style: const TextStyle(color: Colors.cyan, fontSize: 16, fontWeight: FontWeight.bold),
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
          ),
        ],
      ),
    );
  }
}