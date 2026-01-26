import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/user.dart';
import '../../models/transaction.dart' as model;
import '../../services/data/transaction_service.dart';
import 'user_detail_screen.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<User> _users = [];
  bool _isLoading = true;
  final TransactionService _transactionService = TransactionService();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);

    try {
      final userBox = await Hive.openBox<User>('users');
      _users = userBox.values.toList();

      // Sort by createdAt desc
      _users.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      print('Error loading users: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<int> _getUserTransactionCount(String userId) async {
    final transactions = await _transactionService.getTransactionsByUserId(
      userId,
    );
    return transactions.length;
  }

  Future<double> _getUserTotalExpense(String userId) async {
    final transactions = await _transactionService.getTransactionsByUserId(
      userId,
    );
    return transactions
        .where((t) => t.type == model.TransactionType.expense)
        .fold<double>(0, (sum, t) => sum + t.amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryTeal,
        title: Text(
          'Quản lý Users',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUsers,
              child: _users.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: _users.length,
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        return _buildUserCard(user);
                      },
                    ),
            ),
    );
  }

  Widget _buildUserCard(User user) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserDetailScreen(user: user),
            ),
          ).then((_) => _loadUsers());
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: user.isVerified
                        ? AppTheme.primaryTeal.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.2),
                    child: Text(
                      user.firstName.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: user.isVerified
                            ? AppTheme.primaryTeal
                            : Colors.grey,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  // User info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${user.firstName} ${user.lastName}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            if (user.isVerified) ...[
                              SizedBox(width: 6),
                              Icon(
                                Icons.verified,
                                size: 18,
                                color: Colors.green,
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          user.email,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Arrow icon
                  Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ],
              ),
              SizedBox(height: 12),
              Divider(height: 1),
              SizedBox(height: 12),
              // Stats row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    icon: Icons.receipt_long,
                    label: 'Giao dịch',
                    value: FutureBuilder<int>(
                      future: _getUserTransactionCount(user.id),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return Text('...');
                        return Text(
                          snapshot.data.toString(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryTeal,
                          ),
                        );
                      },
                    ),
                  ),
                  _buildStatItem(
                    icon: Icons.attach_money,
                    label: 'Chi tiêu',
                    value: FutureBuilder<double>(
                      future: _getUserTotalExpense(user.id),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return Text('...');
                        return Text(
                          NumberFormat.compact(
                            locale: 'vi',
                          ).format(snapshot.data),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        );
                      },
                    ),
                  ),
                  _buildStatItem(
                    icon: Icons.calendar_today,
                    label: 'Tham gia',
                    value: Text(
                      DateFormat('dd/MM/yy').format(user.createdAt),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required Widget value,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        SizedBox(height: 4),
        value,
        SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey[300]),
          SizedBox(height: 16),
          Text(
            'Chưa có người dùng nào',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
