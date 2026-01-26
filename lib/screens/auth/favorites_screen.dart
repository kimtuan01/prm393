import 'package:flutter/material.dart';
import '../../config/theme.dart';
import 'congrats_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final List<Map<String, dynamic>> _preferences = [
    {
      'icon': Icons.calculate,
      'text': 'Quản lý chi tiêu hàng ngày',
      'selected': false,
    },
    {
      'icon': Icons.receipt_long,
      'text': 'Tìm kiếm cho tiết cải nhất',
      'selected': false,
    },
    {'icon': Icons.calendar_today, 'text': 'Thêm sự dậu ra', 'selected': false},
    {
      'icon': Icons.notifications,
      'text': 'Gửi nhắc nhở cho chuẩn để nhất',
      'selected': false,
    },
    {
      'icon': Icons.analytics,
      'text': 'Quản lý chi tiết hết đủ ròng',
      'selected': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;
    final padding = screenWidth * 0.06;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: isSmallScreen ? 12 : 20),

              // Logo
              _buildLogo(isSmallScreen),

              SizedBox(height: isSmallScreen ? 24 : 32),

              // Title
              Text(
                'BẠN ĐANG QUAN TÂM ĐẾN ĐIỀU GÌ?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isSmallScreen ? 18 : 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),

              SizedBox(height: isSmallScreen ? 24 : 32),

              // Preference Items
              Expanded(
                child: ListView.builder(
                  itemCount: _preferences.length,
                  itemBuilder: (context, index) {
                    return _buildPreferenceItem(index, isSmallScreen);
                  },
                ),
              ),

              SizedBox(height: isSmallScreen ? 16 : 24),

              // Continue Button
              SizedBox(
                height: isSmallScreen ? 50 : 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => CongratsScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryTeal,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'XÁC NHẬN',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 16 : 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              SizedBox(height: isSmallScreen ? 12 : 16),

              // Skip Button
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => CongratsScreen()),
                  );
                },
                child: Text(
                  'BỎ QUA',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(bool isSmallScreen) {
    return Column(
      children: [
        Container(
          width: isSmallScreen ? 70 : 80,
          height: isSmallScreen ? 70 : 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.primaryTeal,
          ),
          child: Icon(
            Icons.account_balance_wallet_rounded,
            size: isSmallScreen ? 35 : 40,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'FINTRACKER',
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildPreferenceItem(int index, bool isSmallScreen) {
    return Container(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 10 : 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: _preferences[index]['selected']
              ? AppTheme.primaryTeal
              : AppTheme.textSecondary.withOpacity(0.3),
          width: _preferences[index]['selected'] ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: CheckboxListTile(
        value: _preferences[index]['selected'],
        onChanged: (bool? value) {
          setState(() {
            _preferences[index]['selected'] = value ?? false;
          });
        },
        title: Row(
          children: [
            Icon(
              _preferences[index]['icon'],
              color: _preferences[index]['selected']
                  ? AppTheme.primaryTeal
                  : AppTheme.textSecondary,
              size: isSmallScreen ? 20 : 24,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                _preferences[index]['text'],
                style: TextStyle(
                  fontSize: isSmallScreen ? 13 : 14,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
        activeColor: AppTheme.primaryTeal,
        controlAffinity: ListTileControlAffinity.trailing,
      ),
    );
  }
}
