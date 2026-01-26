import 'package:flutter/material.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  String _selectedLanguage = 'vi'; // 'vi' for Vietnamese, 'en' for English

  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'QUẢN LÝ VÀ GIÁM SÁT\nCHI TIÊU HÀNG NGÀY',
      'subtitle':
          'Theo dõi mọi khoản chi tiêu một cách dễ dàng và chính xác nhất.',
      'icon': Icons.analytics_outlined,
      'color': Color(0xFF4ECDC4),
    },
    {
      'title': 'NHẬP CHI HÓA ĐƠN\nTỰ ĐỘNG, DỄ DÀNG',
      'subtitle': 'Quét mã QR hoặc chụp ảnh hóa đơn để tự động nhập thông tin.',
      'icon': Icons.receipt_long_outlined,
      'color': Color(0xFF3498DB),
    },
    {
      'title': 'THIẾT LẬP NGÂN SÁCH\nHẠN MỨC PHÙ HỢP',
      'subtitle':
          'Đặt ngân sách hàng tháng và nhận thông báo khi sắp vượt mức.',
      'icon': Icons.savings_outlined,
      'color': Color(0xFF27AE60),
    },
    {
      'title': 'BẢO MẬT TỐI ƯU\nAN TOÀN TUYỆT ĐỐI',
      'subtitle':
          'Dữ liệu được mã hóa và bảo vệ với công nghệ bảo mật tiên tiến.',
      'icon': Icons.security_outlined,
      'color': Color(0xFF2C3E50),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700 || screenWidth < 360;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isSmallScreen, screenWidth),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) =>
                    _buildPage(_pages[index], isSmallScreen),
              ),
            ),
            _buildBottomSection(isSmallScreen),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isSmallScreen, double screenWidth) {
    return Padding(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo Section
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: isSmallScreen ? 35 : 40,
                  height: isSmallScreen ? 35 : 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF4ECDC4),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Colors.white,
                    size: isSmallScreen ? 18 : 20,
                  ),
                ),
                SizedBox(width: isSmallScreen ? 8 : 12),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'FINTRAKCER',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Smart spend, Bright future',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 9 : 10,
                          color: Color(0xFF7F8C8D),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Language Selector
          PopupMenuButton<String>(
            offset: Offset(0, 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (String value) {
              setState(() {
                _selectedLanguage = value;
              });
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                value: 'vi',
                child: Row(
                  children: [
                    Icon(
                      Icons.check,
                      size: 16,
                      color: _selectedLanguage == 'vi'
                          ? Color(0xFF4ECDC4)
                          : Colors.transparent,
                    ),
                    SizedBox(width: 8),
                    Text('Tiếng Việt'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'en',
                child: Row(
                  children: [
                    Icon(
                      Icons.check,
                      size: 16,
                      color: _selectedLanguage == 'en'
                          ? Color(0xFF4ECDC4)
                          : Colors.transparent,
                    ),
                    SizedBox(width: 8),
                    Text('English'),
                  ],
                ),
              ),
            ],
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 8 : 12,
                vertical: isSmallScreen ? 4 : 6,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: Color(0xFF4ECDC4), width: 1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.language,
                    size: isSmallScreen ? 14 : 16,
                    color: Color(0xFF4ECDC4),
                  ),
                  SizedBox(width: 4),
                  Text(
                    _selectedLanguage == 'vi' ? 'VI' : 'EN',
                    style: TextStyle(
                      color: Color(0xFF4ECDC4),
                      fontSize: isSmallScreen ? 11 : 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: isSmallScreen ? 14 : 16,
                    color: Color(0xFF4ECDC4),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(Map<String, dynamic> page, bool isSmallScreen) {
    final illustrationSize = isSmallScreen ? 200.0 : 280.0;
    final innerSize1 = isSmallScreen ? 140.0 : 200.0;
    final innerSize2 = isSmallScreen ? 100.0 : 140.0;
    final innerSize3 = isSmallScreen ? 60.0 : 80.0;
    final iconSize = isSmallScreen ? 30.0 : 40.0;

    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: isSmallScreen ? 20 : 40),

            // Illustration
            Container(
              width: illustrationSize,
              height: illustrationSize,
              decoration: BoxDecoration(
                color: page['color'].withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: innerSize1,
                    height: innerSize1,
                    decoration: BoxDecoration(
                      color: page['color'].withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: innerSize2,
                    height: innerSize2,
                    decoration: BoxDecoration(
                      color: page['color'].withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: innerSize3,
                    height: innerSize3,
                    decoration: BoxDecoration(
                      color: page['color'],
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: page['color'].withOpacity(0.3),
                          blurRadius: isSmallScreen ? 15 : 20,
                          offset: Offset(0, isSmallScreen ? 6 : 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      page['icon'],
                      size: iconSize,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: isSmallScreen ? 30 : 48),

            Text(
              page['title'],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isSmallScreen ? 18 : 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
                height: 1.3,
              ),
            ),

            SizedBox(height: isSmallScreen ? 12 : 16),

            Text(
              page['subtitle'],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                color: Color(0xFF7F8C8D),
                height: 1.5,
              ),
            ),

            SizedBox(height: isSmallScreen ? 20 : 40),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSection(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      child: Column(
        children: [
          // Page Indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_pages.length, (index) {
              return Container(
                margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 3 : 4),
                width: _currentIndex == index
                    ? (isSmallScreen ? 20 : 24)
                    : (isSmallScreen ? 6 : 8),
                height: isSmallScreen ? 6 : 8,
                decoration: BoxDecoration(
                  color: _currentIndex == index
                      ? _pages[_currentIndex]['color']
                      : Color(0xFF7F8C8D).withAlpha((0.3 * 255).round()),
                  borderRadius: BorderRadius.circular(isSmallScreen ? 3 : 4),
                ),
              );
            }),
          ),

          SizedBox(height: isSmallScreen ? 20 : 32),

          // Single Register Button
          SizedBox(
            width: double.infinity,
            height: isSmallScreen ? 50 : 56,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return RegisterScreen();
                    },
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4ECDC4),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'ĐĂNG KÝ MIỄN PHÍ',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          SizedBox(height: 4),

          // Login Link
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return LoginScreen();
                  },
                ),
              );
            },
            child: Text(
              'ĐĂNG NHẬP',
              style: TextStyle(
                color: Color(0xFF4ECDC4),
                fontSize: isSmallScreen ? 14 : 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          if (!isSmallScreen) SizedBox(height: 8),

          // Version Text
          Text(
            'Phiên bản 1.1',
            style: TextStyle(
              color: Colors.grey,
              fontSize: isSmallScreen ? 11 : 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
