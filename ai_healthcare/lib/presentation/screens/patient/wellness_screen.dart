import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/colors.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/liquid_background.dart';
import '../../../data/services/api_service.dart';
import '../../../data/models/wellness_goal.dart';

class WellnessScreen extends StatefulWidget {
  const WellnessScreen({super.key});

  @override
  State<WellnessScreen> createState() => _WellnessScreenState();
}

class _WellnessScreenState extends State<WellnessScreen> {
  final _api = ApiService();
  bool _loading = true;
  List<WellnessGoal> _goals = [];
  Map<String, double> _progress = {
    'water': 0,
    'steps': 0,
    'calories': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final goals = await _api.getWellnessGoals();
      final progress = await _api.getDailyWellnessProgress();
      
      setState(() {
        _goals = goals;
        for (var p in (progress ?? [])) {
          final type = p['type']?.toString().toLowerCase() ?? '';
          if (_progress.containsKey(type)) {
            _progress[type] = (p['total'] as num).toDouble();
          }
        }
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _logMetric(String type, double value, String unit) async {
    try {
      await _api.addMetric({
        'user_id': _api.currentUser?['id'],
        'type': type,
        'value': value,
        'unit': unit,
      });
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to log $type')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: LiquidBackground(
        child: SafeArea(
          child: _loading 
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(isDark),
                      const SizedBox(height: 32),
                      _buildHealthScore(isDark),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(child: _buildWaterTracker(isDark)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildFitnessRings(isDark)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildNutritionSection(isDark),
                      const SizedBox(height: 100), // Bottom padding for FAB/Navbar
                    ],
                  ),
                ),
              ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Wellness Hub',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textLight,
          ),
        ),
        Text(
          'Your holistic health partner',
          style: TextStyle(
            fontSize: 16,
            color: isDark ? Colors.white70 : AppColors.textLightSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildHealthScore(bool isDark) {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      opacity: isDark ? 0.08 : 0.6,
      blur: 25,
      child: Row(
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [AppColors.primary, AppColors.accent]),
            ),
            child: const Center(
              child: Text(
                '84',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Health Score',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Great job! You\'re 12% better than yesterday.',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : AppColors.textLightSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterTracker(bool isDark) {
    final goal = _goals.firstWhere((g) => g.type == 'water', orElse: () => WellnessGoal(id: '', userId: '', type: 'water', targetValue: 3000, unit: 'ml', updatedAt: DateTime.now()));
    final current = _progress['water'] ?? 0;
    final percent = (current / goal.targetValue).clamp(0.0, 1.0);

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      opacity: isDark ? 0.08 : 0.6,
      height: 220,
      child: Column(
        children: [
          const Icon(LucideIcons.droplets, color: Colors.blueAccent, size: 28),
          const SizedBox(height: 12),
          const Text('Water', style: TextStyle(fontWeight: FontWeight.w600)),
          const Spacer(),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80, height: 80,
                child: CircularProgressIndicator(
                  value: percent,
                  strokeWidth: 8,
                  backgroundColor: Colors.blueAccent.withAlpha(30),
                  color: Colors.blueAccent,
                ),
              ),
              Text('${(percent * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSmallLogButton(isDark, '+250ml', () => _logMetric('Water', 250, 'ml')),
              const SizedBox(width: 8),
              _buildSmallLogButton(isDark, '+500ml', () => _logMetric('Water', 500, 'ml')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFitnessRings(bool isDark) {
    final stepsGoal = _goals.firstWhere((g) => g.type == 'steps', orElse: () => WellnessGoal(id: '', userId: '', type: 'steps', targetValue: 10000, unit: 'steps', updatedAt: DateTime.now()));
    final currentSteps = _progress['steps'] ?? 0;
    final percent = (currentSteps / stepsGoal.targetValue).clamp(0.0, 1.0);

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      opacity: isDark ? 0.08 : 0.6,
      height: 220,
      child: Column(
        children: [
          const Icon(LucideIcons.flame, color: Colors.orangeAccent, size: 28),
          const SizedBox(height: 12),
          const Text('Fitness', style: TextStyle(fontWeight: FontWeight.w600)),
          const Spacer(),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80, height: 80,
                child: CircularProgressIndicator(
                  value: percent,
                  strokeWidth: 8,
                  backgroundColor: Colors.orangeAccent.withAlpha(30),
                  color: Colors.orangeAccent,
                ),
              ),
              const Icon(LucideIcons.footprints, size: 24, color: Colors.orangeAccent),
            ],
          ),
          const Spacer(),
          Text(
            '${currentSteps.toInt()} / ${stepsGoal.targetValue.toInt()}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          const Text('Steps Today', style: TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildNutritionSection(bool isDark) {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      opacity: isDark ? 0.08 : 0.6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Nutrition', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton.icon(
                onPressed: () {}, 
                icon: const Icon(LucideIcons.plus, size: 16),
                label: const Text('Log Meal'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMacroItem('Carbs', 0.4, Colors.green),
              _buildMacroItem('Protein', 0.7, Colors.redAccent),
              _buildMacroItem('Fats', 0.3, Colors.yellow[700]!),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroItem(String label, double percent, Color color) {
    return Column(
      children: [
        SizedBox(
          width: 60, height: 60,
          child: CircularProgressIndicator(
            value: percent,
            strokeWidth: 6,
            backgroundColor: color.withAlpha(30),
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildSmallLogButton(bool isDark, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withAlpha(10)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
