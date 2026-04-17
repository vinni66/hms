import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/colors.dart';
import '../../../data/services/api_service.dart';
import '../../widgets/liquid_background.dart';

class MedicineAvailabilityScreen extends StatefulWidget {
  final String? initialQuery;
  const MedicineAvailabilityScreen({super.key, this.initialQuery});

  @override
  State<MedicineAvailabilityScreen> createState() => _MedicineAvailabilityScreenState();
}

class _MedicineAvailabilityScreenState extends State<MedicineAvailabilityScreen> {
  final _api = ApiService();
  final _searchController = TextEditingController();
  List _results = [];
  bool _loading = false;
  String _lastSearch = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      WidgetsBinding.instance.addPostFrameCallback((_) => _search());
    }
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    
    setState(() { 
      _loading = true; 
      _lastSearch = query;
      _results = []; 
    });

    try {
      final res = await _api.checkPharmacyStock(query);
      if (mounted) setState(() { _results = res; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return LiquidBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Medicine Search'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Column(
          children: [
            // Search Bar Section
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark.withAlpha(200) : Colors.white.withAlpha(200),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 20)],
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _search(),
                  style: TextStyle(color: isDark ? AppColors.textDark : AppColors.textLight),
                  decoration: InputDecoration(
                    hintText: 'Search for medicine...',
                    prefixIcon: const Icon(LucideIcons.search, color: AppColors.primary),
                    suffixIcon: IconButton(
                      icon: const Icon(LucideIcons.arrowRight, color: AppColors.primary),
                      onPressed: _search,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(20),
                  ),
                ),
              ).animate().fadeIn().slideY(begin: -0.1),
            ),

            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _results.isEmpty && _lastSearch.isNotEmpty
                      ? _noResults(isDark)
                      : _lastSearch.isEmpty
                          ? _initialState(isDark)
                          : _resultsList(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _initialState(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.pill, size: 80, color: AppColors.primary.withAlpha(40)),
          const SizedBox(height: 16),
          Text('Enter a medicine name to check availability',
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary, fontSize: 16)),
        ],
      ).animate().fadeIn(),
    );
  }

  Widget _noResults(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.searchX, size: 60, color: AppColors.error.withAlpha(40)),
          const SizedBox(height: 16),
          Text('No local pharmacies found with "$_lastSearch"',
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)),
        ],
      ),
    );
  }

  Widget _resultsList(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: _results.length,
      itemBuilder: (ctx, i) {
        final p = _results[i];
        final inStock = p['stock_status'] == 'In Stock';
        return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark.withAlpha(220) : Colors.white.withAlpha(240),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: inStock ? AppColors.success.withAlpha(50) : AppColors.error.withAlpha(50)),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(isDark ? 30 : 10), blurRadius: 20)],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(child: Text(p['name'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? AppColors.textDark : AppColors.textLight))),
                Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: inStock ? AppColors.success.withAlpha(25) : AppColors.error.withAlpha(25), borderRadius: BorderRadius.circular(10)),
                    child: Text(p['stock_status'], style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: inStock ? AppColors.success : AppColors.error))
                )
              ]),
              const SizedBox(height: 12),
              Row(children: [
                const Icon(LucideIcons.mapPin, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(child: Text('${p['distance_km']} km away • ${p['address']}', style: TextStyle(fontSize: 14, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary))),
              ]),
              const SizedBox(height: 12),
              const Divider(height: 1, thickness: 0.5),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Price', style: TextStyle(fontSize: 11, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)),
                  Text('\$${p['price'].toString()}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: inStock ? AppColors.success : isDark ? AppColors.textDark : AppColors.textLight)),
                ]),
                ElevatedButton.icon(
                  onPressed: () {}, // Implementation for calling/booking could go here
                  icon: const Icon(LucideIcons.phone, size: 14),
                  label: Text(p['phone']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    elevation: 0,
                  ),
                )
              ])
            ])
        ).animate().fadeIn(delay: (i * 100).ms).slideX(begin: 0.1);
      },
    );
  }
}
