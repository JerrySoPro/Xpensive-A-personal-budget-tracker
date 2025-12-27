import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user.dart';
import '../services/firebase_service.dart';
import '../providers/theme_provider.dart';
import 'login_screen.dart';
import 'statistics_screen.dart';

class ProfileScreen extends StatefulWidget {
  final User user;
  final ThemeProvider themeProvider;

  const ProfileScreen({
    super.key,
    required this.user,
    required this.themeProvider,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseService _firebase = FirebaseService.instance;
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();

  late TextEditingController _displayNameController;
  late TextEditingController _emailController;

  bool _isEditing = false;
  bool _isLoading = false;
  bool _isUploadingImage = false;
  String? _profilePhotoUrl;

  // Stats
  int _totalAccounts = 0;
  int _totalTransactions = 0;
  double _totalIncome = 0;
  double _totalExpense = 0;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(
      text: widget.user.displayName,
    );
    _emailController = TextEditingController(text: widget.user.email);
    _profilePhotoUrl = widget.user.profilePhoto;
    _loadStats();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);

    final accounts = await _firebase.getAccountsByUserId(widget.user.id);
    final transactions = await _firebase.getTransactionsByUserId(
      widget.user.id,
    );
    final totalIncome = await _firebase.getTotalIncome(widget.user.id);
    final totalExpense = await _firebase.getTotalExpense(widget.user.id);

    setState(() {
      _totalAccounts = accounts.length;
      _totalTransactions = transactions.length;
      _totalIncome = totalIncome;
      _totalExpense = totalExpense;
      _isLoading = false;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (pickedFile != null) {
        await _uploadProfileImage(pickedFile);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadProfileImage(XFile imageFile) async {
    setState(() => _isUploadingImage = true);

    try {
      // Read image as bytes and convert to base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      // Update user profile with base64 image
      await _firebase.updateUserProfile(
        widget.user.id,
        profilePhoto: base64Image,
      );

      setState(() {
        _profilePhotoUrl = base64Image;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isUploadingImage = false);
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Change Profile Photo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.photo_library, color: Colors.white),
                ),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Icon(Icons.camera_alt, color: Colors.white),
                ),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              if (_profilePhotoUrl != null)
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.red,
                    child: Icon(Icons.delete, color: Colors.white),
                  ),
                  title: const Text('Remove Photo'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _removeProfilePhoto();
                  },
                ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _removeProfilePhoto() async {
    setState(() => _isUploadingImage = true);

    try {
      // Update user profile to remove photo
      await _firebase.updateUserProfile(widget.user.id, profilePhoto: '');

      setState(() {
        _profilePhotoUrl = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo removed'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _firebase.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) =>
                LoginScreen(themeProvider: widget.themeProvider),
          ),
          (route) => false,
        );
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _firebase.updateUserProfile(
        widget.user.id,
        displayName: _displayNameController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() => _isEditing = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return '৳${formatter.format(amount)}';
  }

  ImageProvider? _getProfileImage() {
    if (_profilePhotoUrl == null || _profilePhotoUrl!.isEmpty) {
      return null;
    }
    // Check if it's a base64 image
    if (_profilePhotoUrl!.startsWith('data:image')) {
      final base64String = _profilePhotoUrl!.split(',').last;
      return MemoryImage(base64Decode(base64String));
    }
    // Otherwise assume it's a URL
    return NetworkImage(_profilePhotoUrl!);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
              tooltip: 'Edit Profile',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Profile Header
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [
                                  Colors.deepPurple.shade800,
                                  Colors.deepPurple.shade600,
                                ]
                              : [
                                  Colors.deepPurple.shade700,
                                  Colors.deepPurple.shade400,
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _isUploadingImage
                                ? null
                                : _showImagePickerOptions,
                            child: Stack(
                              children: [
                                _isUploadingImage
                                    ? const CircleAvatar(
                                        radius: 50,
                                        backgroundColor: Colors.white24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                        ),
                                      )
                                    : CircleAvatar(
                                        radius: 50,
                                        backgroundColor: Colors.white
                                            .withOpacity(0.2),
                                        backgroundImage: _getProfileImage(),
                                        child:
                                            _profilePhotoUrl == null ||
                                                _profilePhotoUrl!.isEmpty
                                            ? Text(
                                                widget
                                                        .user
                                                        .displayName
                                                        .isNotEmpty
                                                    ? widget.user.displayName[0]
                                                          .toUpperCase()
                                                    : 'U',
                                                style: const TextStyle(
                                                  fontSize: 40,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : null,
                                      ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.deepPurple.shade300,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.user.displayName,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '@${widget.user.username}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.user.email,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Stats Grid
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Accounts',
                          _totalAccounts.toString(),
                          Icons.account_balance_wallet,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Transactions',
                          _totalTransactions.toString(),
                          Icons.receipt_long,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total Income',
                          _formatCurrency(_totalIncome),
                          Icons.trending_up,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Total Expense',
                          _formatCurrency(_totalExpense),
                          Icons.trending_down,
                          Colors.red,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Edit Profile Form
                  if (_isEditing)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Edit Profile',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _displayNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Display Name',
                                  prefixIcon: Icon(Icons.person),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter your name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _emailController,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.email),
                                ),
                                enabled:
                                    false, // Email can't be changed easily with Firebase
                              ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      _displayNameController.text =
                                          widget.user.displayName;
                                      setState(() => _isEditing = false);
                                    },
                                    child: const Text('Cancel'),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: _updateProfile,
                                    child: const Text('Save Changes'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Settings Section
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(
                            Icons.pie_chart,
                            color: Colors.deepPurple,
                          ),
                          title: const Text('Statistics & Reports'),
                          subtitle: const Text('View your financial insights'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    StatisticsScreen(user: widget.user),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: Icon(
                            isDark ? Icons.dark_mode : Icons.light_mode,
                          ),
                          title: const Text('Dark Mode'),
                          subtitle: Text(isDark ? 'Enabled' : 'Disabled'),
                          trailing: Switch(
                            value: isDark,
                            onChanged: (value) {
                              widget.themeProvider.toggleTheme();
                            },
                            activeColor: Colors.deepPurple,
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.calendar_today),
                          title: const Text('Member Since'),
                          subtitle: Text(
                            DateFormat(
                              'MMMM dd, yyyy',
                            ).format(widget.user.createdAt),
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.access_time),
                          title: const Text('Last Login'),
                          subtitle: Text(
                            widget.user.lastLogin != null
                                ? DateFormat(
                                    'MMM dd, yyyy - hh:mm a',
                                  ).format(widget.user.lastLogin!)
                                : 'N/A',
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // App Info
                  Text(
                    'Xpensive v1.0.0',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
