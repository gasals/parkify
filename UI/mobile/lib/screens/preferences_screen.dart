import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/city_provider.dart';
import '../providers/preference_provider.dart';

class PreferencesSheet extends StatefulWidget {
  const PreferencesSheet({Key? key}) : super(key: key);

  @override
  State<PreferencesSheet> createState() => _PreferencesSheetState();
}

class _PreferencesSheetState extends State<PreferencesSheet> {
  int? _selectedCityId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final prefProvider = Provider.of<PreferenceProvider>(context, listen: false);
    _selectedCityId = prefProvider.userPreference?.preferredCityId;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Odaberi preferentni grad',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: Navigator.of(context).pop,
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            Consumer<CityProvider>(
              builder: (context, cityProvider, _) {
                if (cityProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final cities = cityProvider.cities;
                
                if (cities.isEmpty) {
                  return const Center(child: Text('Nema dostupnih gradova'));
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: cities.length,
                  itemBuilder: (context, index) {
                    final city = cities[index];
                    final isSelected = _selectedCityId == city.id;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: RadioListTile<int>(
                        value: city.id,
                        groupValue: _selectedCityId,
                        onChanged: (value) {
                          setState(() => _selectedCityId = value);
                        },
                        title: Row(
                          children: [
                            const Icon(Icons.location_city, 
                              color: AppColors.primary, 
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              city.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          '${city.latitude.toStringAsFixed(2)}, ${city.longitude.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        activeColor: AppColors.primary,
                        tileColor: isSelected 
                          ? AppColors.primary.withOpacity(0.1) 
                          : null,
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 24),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : Navigator.of(context).pop,
                    child: const Text('Otkaži'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _savePreference,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text(
                            'Spremi',
                            style: TextStyle(color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _savePreference() async {
    if (_selectedCityId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Odaberi grad'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final prefProvider = Provider.of<PreferenceProvider>(context, listen: false);
      
      await prefProvider.updatePreferredCity(
        userId: authProvider.user!.id,
        cityId: _selectedCityId!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preferentni grad ažuriran')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Greška: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
