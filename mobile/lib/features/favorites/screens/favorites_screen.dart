import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late SharedPreferences _prefs;
  List<Map<String, dynamic>> favorites = [];
  bool _isLoading = true;

  // Sample favorite services - in a real app, this would come from the API
  final List<Map<String, dynamic>> sampleServices = [
    {
      'id': '1',
      'name': 'Plumbing Repair',
      'category': 'Plumbing',
      'rating': 4.8,
      'reviews': '245 reviews',
      'price': '\$50-150',
      'image': '🔧',
    },
    {
      'id': '2',
      'name': 'Electrical Services',
      'category': 'Electrical',
      'rating': 4.9,
      'reviews': '312 reviews',
      'price': '\$60-180',
      'image': '⚡',
    },
    {
      'id': '3',
      'name': 'HVAC Maintenance',
      'category': 'HVAC',
      'rating': 4.7,
      'reviews': '156 reviews',
      'price': '\$100-250',
      'image': '❄️',
    },
    {
      'id': '4',
      'name': 'Cleaning Service',
      'category': 'Cleaning',
      'rating': 4.6,
      'reviews': '428 reviews',
      'price': '\$40-120',
      'image': '🧹',
    },
    {
      'id': '5',
      'name': 'Carpentry Work',
      'category': 'Carpentry',
      'rating': 4.9,
      'reviews': '189 reviews',
      'price': '\$80-200',
      'image': '🔨',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    _prefs = await SharedPreferences.getInstance();
    final favoritesJson = _prefs.getStringList('favorites') ?? [];

    setState(() {
      favorites = favoritesJson
          .map((json) => jsonDecode(json) as Map<String, dynamic>)
          .toList();
      _isLoading = false;
    });
  }

  Future<void> _addFavorite(Map<String, dynamic> service) async {
    final isFavorited = favorites.any((fav) => fav['id'] == service['id']);

    if (!isFavorited) {
      setState(() {
        favorites.add(service);
      });

      final favoritesJson = favorites.map((fav) => jsonEncode(fav)).toList();
      await _prefs.setStringList('favorites', favoritesJson);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${service['name']} added to favorites')),
        );
      }
    }
  }

  Future<void> _removeFavorite(String serviceId) async {
    setState(() {
      favorites.removeWhere((fav) => fav['id'] == serviceId);
    });

    final favoritesJson = favorites.map((fav) => jsonEncode(fav)).toList();
    await _prefs.setStringList('favorites', favoritesJson);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Removed from favorites')),
    );
  }

  void _showAddFavoritesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add to Favorites'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: sampleServices.length,
            itemBuilder: (context, index) {
              final service = sampleServices[index];
              final isFavorited =
                  favorites.any((fav) => fav['id'] == service['id']);

              return ListTile(
                leading: Text(service['image'],
                    style: const TextStyle(fontSize: 24)),
                title: Text(service['name']),
                subtitle: Text(service['category']),
                trailing: isFavorited
                    ? const Icon(Icons.favorite, color: Colors.red)
                    : const Icon(Icons.favorite_border),
                onTap: () {
                  if (!isFavorited) {
                    _addFavorite(service);
                  }
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Favorites'),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddFavoritesDialog,
            tooltip: 'Add to favorites',
          ),
        ],
      ),
      body: favorites.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No favorites yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add your favorite services to quick access them later',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _showAddFavoritesDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Favorite'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final favorite = favorites[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          favorite['image'] ?? '⭐',
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
                    title: Text(
                      favorite['name'] ?? 'Service',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          '${favorite['category'] ?? 'N/A'} • ${favorite['price'] ?? ''}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.star,
                                size: 14, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              '${favorite['rating']} (${favorite['reviews']})',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.favorite, color: Colors.red),
                      onPressed: () =>
                          _removeFavorite(favorite['id'] as String),
                    ),
                    onTap: () {
                      // In a real app, this would navigate to service details
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Viewing ${favorite['name']}'),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
