import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/colors.dart';
import '../../../data/services/api_service.dart';
import '../../widgets/liquid_background.dart';
import '../../widgets/glass_container.dart';

class FamilyDashboard extends StatefulWidget {
  const FamilyDashboard({super.key});

  @override
  State<FamilyDashboard> createState() => _FamilyDashboardState();
}

class _FamilyDashboardState extends State<FamilyDashboard> {
  final _api = ApiService();
  List _members = [];
  List _requests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final members = await _api.getFamilyMembersHealth();
      final links = await _api.getFamilyLinks();
      
      _members = members ?? [];
      _requests = (links ?? []).where((l) => l['status'] == 'pending' && l['target_id'] == _api.currentUser?['id']).toList();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _showAddMember() {
    final emailC = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        decoration: BoxDecoration(
          color: Theme.of(ctx).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Link Family Member', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Monitor health together for a safer home.', style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 24),
            TextField(
              controller: emailC,
              decoration: InputDecoration(
                hintText: 'Email Address',
                prefixIcon: const Icon(LucideIcons.mail),
                filled: true,
                fillColor: Colors.grey.withAlpha(20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () async {
                  if (emailC.text.isNotEmpty) {
                    try {
                      await _api.sendFamilyRequest(emailC.text);
                      if (mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request sent successfully!')));
                        _load();
                      }
                    } catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                    }
                  }
                },
                child: const Text('Send Request', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: LiquidBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(isDark),
              if (_requests.isNotEmpty) _buildPendingRequests(isDark),
              Expanded(
                child: _loading 
                  ? const Center(child: CircularProgressIndicator())
                  : _members.isEmpty 
                    ? _buildEmptyState(isDark)
                    : _buildMembersGrid(isDark),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMember,
        backgroundColor: AppColors.primary,
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: const Text('Connect', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(LucideIcons.arrowLeft, color: isDark ? Colors.white : Colors.black),
            padding: EdgeInsets.zero,
            alignment: Alignment.centerLeft,
          ),
          const SizedBox(height: 16),
          Text(
            'Family Circle',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : AppColors.textLight,
            ),
          ),
          Text(
            'Keep an eye on those who matter most.',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingRequests(bool isDark) {
    return GlassContainer(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(16),
      opacity: isDark ? 0.08 : 0.6,
      blur: 15,
      border: Border.all(color: AppColors.primary.withAlpha(isDark ? 50 : 100)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.userPlus, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'New Connection Requests',
                style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._requests.map((r) => ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(r['requester_name'] ?? 'Family Member'),
            subtitle: const Text('wants to share health data'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () async {
                    await _api.handleFamilyRequest(r['id'], 'approved');
                    _load();
                  },
                  icon: const Icon(LucideIcons.checkCircle, color: Colors.green),
                ),
                IconButton(
                  onPressed: () async {
                    await _api.handleFamilyRequest(r['id'], 'rejected');
                    _load();
                  },
                  icon: const Icon(LucideIcons.xCircle, color: Colors.red),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildMembersGrid(bool isDark) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: _members.length,
      itemBuilder: (ctx, i) {
        final m = _members[i];
        return _memberCard(m, isDark);
      },
    );
  }

  Widget _memberCard(dynamic m, bool isDark) {
    final vitals = m['vitals'] ?? {};
    final hr = vitals['heart_rate']?.toString() ?? '--';
    final sp = vitals['spo2']?.toString() ?? '--';
    
    // Simple risk check
    bool isRisk = false;
    if (vitals['heart_rate'] != null && (vitals['heart_rate'] > 100 || vitals['heart_rate'] < 50)) isRisk = true;
    if (vitals['spo2'] != null && vitals['spo2'] < 94) isRisk = true;

    return GlassContainer(
      opacity: isRisk ? 0.15 : (isDark ? 0.08 : 0.6),
      blur: 15,
      borderRadius: 24,
      border: Border.all(color: isRisk ? Colors.red.withAlpha(100) : Colors.white.withAlpha(isDark ? 20 : 100)),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Color(int.parse((m['avatar_color'] ?? '#667EEA').replaceAll('#', '0xFF'))),
                  child: Text(
                    m['name']?[0] ?? '?', 
                    style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  m['name'] ?? 'Member',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _vitalSmall(LucideIcons.heart, hr, Colors.red, 'BPM'),
                    _vitalSmall(LucideIcons.droplets, sp, Colors.blue, '%'),
                  ],
                ),
              ],
            ),
          ),
          if (isRisk)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                child: const Icon(LucideIcons.alertTriangle, color: Colors.white, size: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _vitalSmall(IconData icon, String value, Color color, String unit) {
    return Column(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        Text(unit, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.users, size: 80, color: Colors.grey.withAlpha(100)),
          const SizedBox(height: 16),
          Text(
            'Your circle is empty',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          const Text('Connect with family to share health data.'),
        ],
      ),
    );
  }
}
