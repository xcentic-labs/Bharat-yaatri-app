import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class UploadPhotosPage extends StatefulWidget {
  final String userId;
  const UploadPhotosPage({Key? key, required this.userId}) : super(key: key);

  @override
  State<UploadPhotosPage> createState() => _UploadPhotosPageState();
}

class _UploadPhotosPageState extends State<UploadPhotosPage> {
  File? _profileImage;
  File? _numberPlateImage;
  File? _aadharImage;
  File? _dlImage;

  String? _profileImageUrl;
  String? _numberPlateImageUrl;
  String? _aadharImageUrl;
  String? _dlImageUrl;

  bool? _profileImageVerified;
  bool? _numberPlateVerified;
  bool? _aadharVerified;
  bool? _dlVerified;

  final String baseUrl = "https://api.bharatyaatri.com";
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  bool _hideHomeInstruction = false;

  @override
  void initState() {
    super.initState();
    _fetchUserPhotos();
    _loadHideHomeInstruction();
  }

  Future<void> _fetchUserPhotos() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/user/getuser/${widget.userId}'));

      if (response.statusCode == 200) {
        print('Response Body: ${response.body}');

        final List<dynamic> dataList = jsonDecode(response.body);

        if (dataList.isNotEmpty) {
          final Map<String, dynamic> userData = dataList[0];

          // Function to format image URLs
          String? formatUrl(String? url) {
            if (url == null || url.isEmpty) return null;

            if (url.contains('baseurl')) {
              return url;
            } else {
              String cleanBaseUrl = baseUrl.endsWith('/')
                  ? baseUrl.substring(0, baseUrl.length - 1)
                  : baseUrl;
              String completeUrl = '$cleanBaseUrl/$url';

              Uri uri = Uri.parse(completeUrl);
              return uri.toString();
            }
          }

          // Safe getter for nested properties
          String? getImageUrl(Map<String, dynamic>? data) {
            return data?['imageUrl'] != null ? formatUrl(data?['imageUrl']) : null;
          }

          bool getVerificationStatus(Map<String, dynamic>? data) {
            return data?['verificationStatus'] ?? false;
          }

          setState(() {
            _profileImageUrl = getImageUrl(userData['profilePhoto']);
            _numberPlateImageUrl = getImageUrl(userData['NumberPlate']);
            _aadharImageUrl = getImageUrl(userData['aadhaarPhoto']);
            _dlImageUrl = getImageUrl(userData['dlPhoto']);

            _profileImageVerified = getVerificationStatus(userData['profilePhoto']);
            _numberPlateVerified = getVerificationStatus(userData['NumberPlate']);
            _aadharVerified = getVerificationStatus(userData['aadhaarPhoto']);
            _dlVerified = getVerificationStatus(userData['dlPhoto']);
          });

        } else {
          print('No user data found.');
        }
      } else {
        print('Failed to fetch photos: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching photos.');
    }
  }

  Future<void> _loadHideHomeInstruction() async {
    final hide = await _secureStorage.read(key: 'hideHomeInstruction');
    setState(() {
      _hideHomeInstruction = hide == 'true';
    });
  }

  Future<void> _pickImage(Function(File) setImage) async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _getImage(ImageSource.gallery, setImage);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _getImage(ImageSource.camera, setImage);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _getImage(ImageSource source, Function(File) setImage) async {
    final pickedFile = await ImagePicker().pickImage(source: source, imageQuality: 50);
    if (pickedFile != null) {
      setState(() {
        setImage(File(pickedFile.path));
      });
    }
  }

  Future<void> _uploadPhoto(File? image, String endpoint) async {
    if (image == null) return;
    try {
      var request = http.MultipartRequest('PATCH', Uri.parse('$baseUrl/api/user/$endpoint/${widget.userId}'));
      request.files.add(await http.MultipartFile.fromPath('image', image.path));
      var response = await request.send();
      if (response.statusCode != 200) {
        throw Exception("Failed to upload $endpoint.");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$endpoint upload error: $e")));
    }
  }

  Future<void> _uploadAllPhotos() async {
    await _uploadPhoto(_profileImage, "uploadphoto");
    await _uploadPhoto(_numberPlateImage, "uploadnumberplate");
    await _uploadPhoto(_aadharImage, "uploadaadhar");
    await _uploadPhoto(_dlImage, "uploaddl");

    await _secureStorage.write(key: "userId", value: widget.userId);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("All photos uploaded successfully.")));
    Navigator.pushReplacementNamed(context, '/main');
  }

  Widget _buildImagePicker(
      String label,
      File? image,
      String? imageUrl,
      Function() onTap,
      bool? verificationStatus
      ) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange),
                  ),
                  Text(
                    verificationStatus == true ? "Verified ✅" : "Not Verified ❌",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: verificationStatus == true ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              image != null
                  ? Image.file(image, height: 200, fit: BoxFit.cover)
                  : imageUrl != null
                  ? Image.network(imageUrl, height: 200, fit: BoxFit.cover)
                  : const Icon(Icons.camera_alt, color: Colors.grey, size: 40),
            ],
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5EE),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Upload Photos",
                style: TextStyle(
                  color: Color(0xFFE96E03),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              _buildImagePicker(
                "Profile Photo",
                _profileImage,
                _profileImageUrl,
                    () => _pickImage((file) => _profileImage = file),
                _profileImageVerified,
              ),
              _buildImagePicker(
                "Number Plate",
                _numberPlateImage,
                _numberPlateImageUrl,
                    () => _pickImage((file) => _numberPlateImage = file),
                _numberPlateVerified,
              ),
              _buildImagePicker(
                "Aadhaar Card",
                _aadharImage,
                _aadharImageUrl,
                    () => _pickImage((file) => _aadharImage = file),
                _aadharVerified,
              ),
              _buildImagePicker(
                "Driving License",
                _dlImage,
                _dlImageUrl,
                    () => _pickImage((file) => _dlImage = file),
                _dlVerified,
              ),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _uploadAllPhotos,
                child: const Text("Upload Photos", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  final newValue = !_hideHomeInstruction;
                  await _secureStorage.write(key: 'hideHomeInstruction', value: newValue ? 'true' : 'false');
                  setState(() {
                    _hideHomeInstruction = newValue;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(newValue ? 'Home screen instructions will be hidden.' : 'Home screen instructions will be shown.')),
                  );
                },
                child: Text(_hideHomeInstruction ? 'Show Home Instructions' : 'Hide Home Instructions', style: const TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
