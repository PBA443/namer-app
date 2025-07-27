// ---------------------------------------------------
// FILE: lib/presentation/features/auth/screens/user_registration/user_personal_info_page.dart (නිවැරදි කරන ලද කේතය)
// ---------------------------------------------------
// Constructor, auto-fill, සහ data saving logic එක නිවැරදි කර ඇත.
// ---------------------------------------------------

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../../data/services/firestore_service.dart'; // FirestoreService import
import '../registration_success_page.dart'; // SuccessPage import

class DriverPersonalInfoPage extends StatefulWidget {
  // --- නිවැරදි කිරීම 1: Constructor එක නිවැරදි කිරීම ---
  // RoleSelectionPage එකෙන් එන user object එක ලබාගෙන, class variable එකකට දාගන්නවා.
  final User user;
  const DriverPersonalInfoPage({super.key, required this.user});
  // ----------------------------------------------------

  @override
  State<DriverPersonalInfoPage> createState() => _DriverPersonalInfoPageState();
}

class _DriverPersonalInfoPageState extends State<DriverPersonalInfoPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Text field controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _nicController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _homeLocationController = TextEditingController();
  final _officeLocationController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    // --- නිවැරදි කිරීම 2: Auto-fill logic එක එකතු කිරීම ---
    // Page එක load වෙනකොටම, user data වලින් controllers වලට අගයන් දෙනවා
    _emailController.text = widget.user.email ?? '';

    final displayName = widget.user.displayName ?? '';
    if (displayName.isNotEmpty) {
      final names = displayName.split(' ');
      _firstNameController.text = names.first;
      if (names.length > 1) {
        _lastNameController.text = names.sublist(1).join(' ');
      }
    }
  }

  @override
  void dispose() {
    // Memory leaks වළක්වා ගැනීමට controllers dispose කරනවා
    _firstNameController.dispose();
    _lastNameController.dispose();
    _nicController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _companyNameController.dispose();
    _homeLocationController.dispose();
    _officeLocationController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // --- නිවැරදි කිරීම 3: "Continue" button එකේ නිවැරදි logic එක ---
  Future<void> _onContinue() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // FirestoreService එක call කරලා, form එකේ data ටික update කරනවා
        await FirestoreService().updateUserData(
          uid: widget.user.uid,
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          nic: _nicController.text.trim(),
          gender: _selectedGender,
          phoneNumber: _phoneController.text.trim(),
          companyName: _companyNameController.text.trim(),
          homeLocation: _homeLocationController.text.trim(),
          officeLocation: _officeLocationController.text.trim(),
        );

        if (!mounted) return;

        // Data ටික සාර්ථකව save වුනාට පස්සේ RegistrationSuccessPage එකට යනවා
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const RegistrationSuccessPage(),
          ),
          (route) => false,
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to save data. Please try again."),
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDD734),
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          'Personal Information',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '* Required',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                      const SizedBox(height: 24),

                      // --- Profile Picture Section ---
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: const Color(0xFFFAB52D),
                              child: CircleAvatar(
                                radius: 56,
                                backgroundImage: (widget.user.photoURL != null)
                                    ? NetworkImage(widget.user.photoURL!)
                                    : const NetworkImage(
                                            "https://placehold.co/150x150/FFFFFF/333333?text=Add\nPhoto",
                                          )
                                          as ImageProvider,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.black,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    /* Image picker logic */
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // --- Sections ---
                      _buildSection(
                        title: 'About You',
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextFormField(
                                  controller: _firstNameController,
                                  label: 'First Name *',
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTextFormField(
                                  controller: _lastNameController,
                                  label: 'Last Name *',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildTextFormField(
                            controller: _nicController,
                            label: 'NIC Number *',
                          ),
                          const SizedBox(height: 16),
                          _buildGenderDropdown(),
                        ],
                      ),

                      _buildSection(
                        title: 'Contact Details',
                        children: [
                          _buildTextFormField(
                            controller: _emailController,
                            label: 'Email *',
                            keyboardType: TextInputType.emailAddress,
                            readOnly:
                                true, // Email එක වෙනස් කරන්න බැරි වෙන්න හදනවා
                          ),
                          const SizedBox(height: 16),
                          _buildTextFormField(
                            controller: _phoneController,
                            label: 'Phone Number *',
                            keyboardType: TextInputType.phone,
                          ),
                        ],
                      ),

                      _buildSection(
                        title: 'Company Details',
                        children: [
                          _buildTextFormField(
                            controller: _companyNameController,
                            label: 'Company Name *',
                          ),
                        ],
                      ),

                      _buildSection(
                        title: 'Location Details',
                        children: [
                          _buildTextFormField(
                            controller: _homeLocationController,
                            label: 'Home *',
                          ),
                          const SizedBox(height: 16),
                          _buildTextFormField(
                            controller: _officeLocationController,
                            label: 'Office *',
                          ),
                        ],
                      ),

                      _buildSection(
                        title: 'Enter a password',
                        children: [
                          _buildTextFormField(
                            controller: _passwordController,
                            label: 'Password *',
                            isPassword: true,
                          ),
                          const SizedBox(height: 16),
                          _buildTextFormField(
                            controller: _confirmPasswordController,
                            label: 'Confirm Password *',
                            isPassword: true,
                            validator: (value) {
                              if (value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),

                      // --- Continue Button ---
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _onContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF07A0C),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // Section එකක් හදන Reusable function එකක්
  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        ...children,
        const SizedBox(height: 32),
      ],
    );
  }

  // Text field එකක් හදන Reusable function එකක්
  TextFormField _buildTextFormField({
    required TextEditingController controller,
    required String label,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'This field is required';
        }
        if (validator != null) {
          return validator(value);
        }
        return null;
      },
    );
  }

  // Gender dropdown එක හදන function එක
  DropdownButtonFormField<String> _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedGender,
      decoration: InputDecoration(
        labelText: 'Gender *',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      items: ['Male', 'Female', 'Other']
          .map((gender) => DropdownMenuItem(value: gender, child: Text(gender)))
          .toList(),
      onChanged: (value) {
        setState(() {
          _selectedGender = value;
        });
      },
      validator: (value) => value == null ? 'Please select a gender' : null,
    );
  }
}
