import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pocketbase/pocketbase.dart';
import '../../providers/user_provider.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<List<RecordModel>> _ordersFuture;
  final _subscriptions = <dynamic>[];

  @override
  void initState() {
    super.initState();
    final userProvider = context.read<UserProvider>();
    _ordersFuture = _fetchOrders(userProvider);

    _setupRealtimeOrders(userProvider);
  }

  @override
  void dispose() {
    // ยกเลิก subscription ทุกตัวเมื่อ screen ถูกปิด
    for (var sub in _subscriptions) {
      sub.unsubscribe();
    }
    super.dispose();
  }

  void _setupRealtimeOrders(UserProvider userProvider) {
    final userId = userProvider.user?.id;
    if (userId == null) return;

    final sub = userProvider.pb.collection('orders').subscribe(
      'user="$userId"',
      (e) {
        print('Realtime event: ${e.action} on ${e.record?.id}');
        setState(() {
          _ordersFuture = _fetchOrders(userProvider);
        });
      },
    );

    _subscriptions.add(sub);
  }

  Future<List<RecordModel>> _fetchOrders(UserProvider userProvider) async {
    final userId = userProvider.user?.id;
    if (userId == null) return [];

    try {
      final records = await userProvider.pb.collection('orders').getFullList(
            filter: 'user = "$userId"',
            sort: '-created',
          );
      return records;
    } catch (e) {
      print('Error fetching orders: $e');
      return [];
    }
  }

  Uri? _getAvatarUrl(UserProvider userProvider) {
    final user = userProvider.user;
    final avatarFileName = user?.getDataValue<String>('avatar') ?? '';
    if (user == null || avatarFileName.isEmpty) return null;
    return userProvider.pb.getFileUrl(user, avatarFileName);
  }

  Uri? _getSlipUrl(RecordModel order) {
    final slipFileName = order.getDataValue<String>('paymentSlip') ?? '';
    if (slipFileName.isEmpty) return null;
    return context.read<UserProvider>().pb.getFileUrl(order, slipFileName);
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'paid':
        return Colors.green;
      case 'shipped':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final userEmail =
        userProvider.user?.getDataValue<String>('email') ?? 'Guest';
    final avatarUrl = _getAvatarUrl(userProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => userProvider.logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _ordersFuture = _fetchOrders(userProvider);
          });
        },
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // --- User Info Section ---
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: avatarUrl != null
                      ? NetworkImage(avatarUrl.toString())
                      : null,
                  backgroundColor: Colors.grey.shade200,
                  child: avatarUrl == null
                      ? const Icon(Icons.person, size: 40, color: Colors.grey)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome!',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        userEmail,
                        style: Theme.of(context).textTheme.headlineSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),

            // --- Section Header "My Orders" ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Orders',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh Orders',
                      onPressed: () async {
                        setState(() {
                          _ordersFuture = _fetchOrders(userProvider);
                        });
                      },
                    ),
                    // IconButton(
                    //   icon: const Icon(Icons.logout),
                    //   tooltip: 'Logout',
                    //   onPressed: () => userProvider.logout(),
                    // ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // --- Order List ---
            FutureBuilder<List<RecordModel>>(
              future: _ordersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text('You have no orders yet.'),
                    ),
                  );
                }

                final orders = snapshot.data!;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final totalAmount =
                        order.getDataValue<double>('totalAmount') ?? 0.0;
                    final status =
                        order.getDataValue<String>('status') ?? 'unknown';
                    final createdDate = DateTime.parse(order.created);
                    final formattedDate =
                        DateFormat.yMMMd().add_jm().format(createdDate);

                    final slipUrl = _getSlipUrl(order);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: slipUrl != null
                            ? SizedBox(
                                width: 50,
                                height: 50,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.network(
                                    slipUrl.toString(),
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, progress) {
                                      return progress == null
                                          ? child
                                          : const Center(
                                              child:
                                                  CircularProgressIndicator(strokeWidth: 2.0));
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                          Icons.image_not_supported,
                                          color: Colors.grey);
                                    },
                                  ),
                                ),
                              )
                            : const SizedBox(
                                width: 50,
                                height: 50,
                                child:
                                    Icon(Icons.receipt_long, color: Colors.grey)),
                        title: Text('Order on $formattedDate'),
                        subtitle: Text(
                          'Status: $status',
                          style: TextStyle(
                            color: _statusColor(status),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        trailing: Text(
                          '฿${totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
