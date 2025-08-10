
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hash/app/modules/arena/controllers/cafe_controller.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/utils/widgets/glow_neon_loader.dart';
import 'package:hash/app/modules/arena/views/arena_view_detailed.dart';

class SearchResult extends StatefulWidget {
  final String? searchQuery;
  final String? location;
  
  const SearchResult({
    super.key,
    this.searchQuery,
    this.location,
  });

  @override
  State<SearchResult> createState() => _SearchResultState();
}

class _SearchResultState extends State<SearchResult> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // Controller for cafe data
  late final CybercafesController _cafeController;
  
  // Search state
  bool _isSearching = false;
  String _currentQuery = '';
  
  // Filter state
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Gaming', 'Cafe', 'Nearby', 'Open Now'];
  
  // Fallback images for cafes without cover images
  final List<String> _fallbackImages = [
    'https://next-level.gg/assets/cafes/11.jpg',
    'https://sm.ign.com/ign_in/screenshot/default/mobile-gaming-3_gsmk.jpg',
    'https://media.assettype.com/afkgaming/2024-04/e11d1515-bb0d-48a5-9ad9-1ddfdef286ef/Untitled_design_117_.png',
    'https://i.ytimg.com/vi/3ZPtQAKKado/maxresdefault.jpg',
    'https://pvplayer.com/wp-content/uploads/2024/04/kafejka-gamingowa.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _cafeController = Get.put(
      CybercafesController(remoteRepo: locator<RemoteRepoInterface>()),
    );
    _searchController.text = widget.searchQuery ?? '';
    _currentQuery = widget.searchQuery ?? '';
    
    // Fetch cafes if not already loaded
    if (_cafeController.cybercafes.isEmpty) {
      _performSearch();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _performSearch() {
    setState(() {
      _isSearching = true;
    });

    // Fetch cafes from API
    _cafeController.fetchCybercafes().then((_) {
      setState(() {
        _isSearching = false;
      });
    }).catchError((error) {
      setState(() {
        _isSearching = false;
      });
      Get.snackbar(
        'Error',
        'Failed to fetch cafes: $error',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    });
  }

  List<Map<String, dynamic>> get _filteredResults {
    List<Map<String, dynamic>> results = _cafeController.cybercafes.cast<Map<String, dynamic>>();
    
    // Apply search filter
    if (_currentQuery.isNotEmpty) {
      results = results.where((cafe) {
        final name = cafe['cafe_name']?.toString().toLowerCase() ?? '';
        final address = _getCafeAddress(cafe).toLowerCase();
        final query = _currentQuery.toLowerCase();
        
        return name.contains(query) || address.contains(query);
      }).toList();
    }
    
    // Apply category filter
    if (_selectedFilter != 'All') {
      results = results.where((cafe) {
        switch (_selectedFilter) {
          case 'Gaming':
            return cafe['type'] == 'gaming' || cafe['cafe_name']?.toString().toLowerCase().contains('gaming') == true;
          case 'Cafe':
            return cafe['type'] == 'cafe' || cafe['cafe_name']?.toString().toLowerCase().contains('cafe') == true;
          case 'Open Now':
            return cafe['status'] == 'active';
          case 'Nearby':
            // For now, show all cafes as "nearby"
            // You can implement distance-based filtering here
            return true;
          default:
            return true;
        }
      }).toList();
    }
    
    return results;
  }

  String _getCafeImage(Map<String, dynamic> cafe, int index) {
    final cover = cafe['cover'];
    if (cover != null && cover is String && cover.isNotEmpty) {
      return cover;
    }
    return _fallbackImages[index % _fallbackImages.length];
  }

  String _getCafeAddress(Map<String, dynamic> cafe) {
    // Handle different address structures
    final location = cafe['location'];
    if (location != null && location is Map<String, dynamic>) {
      final address = location['address'];
      if (address != null && address is String) {
        return address;
      }
    }
    
    // Fallback to direct address field
    final address = cafe['address'];
    if (address != null && address is String) {
      return address;
    }
    
    return 'Address not available';
  }

  List<String> _getCafeFeatures(Map<String, dynamic> cafe) {
    final features = <String>[];
    
    // Add games as features
    final games = cafe['games'];
    if (games != null && games is List) {
      for (var game in games.take(3)) {
        if (game != null) {
          features.add(game.toString());
        }
      }
    }
    
    // Add amenities if available
    final amenities = cafe['amenities'];
    if (amenities != null && amenities is List) {
      for (var amenity in amenities.take(2)) {
        if (amenity != null) {
          features.add(amenity.toString());
        }
      }
    }
    
    // Add default features if none available
    if (features.isEmpty) {
      features.addAll(['Gaming PCs', 'High-speed Internet', 'Gaming Setup']);
    }
    
    return features;
  }

  String _getCafePrice(Map<String, dynamic> cafe) {
    // You can implement actual pricing logic here
    // For now, return a default price
    return '₹200/hour';
  }

  double _getCafeRating(Map<String, dynamic> cafe) {
    // You can implement actual rating logic here
    // For now, return a default rating
    return 4.5;
  }

  String _getCafeDistance(Map<String, dynamic> cafe) {
    // You can implement actual distance calculation here
    // For now, return a default distance
    return '1.2 km';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildFilters(),
            Expanded(
              child: _buildResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Search Results',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (widget.location != null)
                  Text(
                    widget.location!,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(.15),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: const Color(0xff338125).withOpacity(.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Color(0xff338125)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: GoogleFonts.inter(color: Colors.white),
                    cursorColor: const Color(0xff338125),
                    decoration: InputDecoration(
                      hintText: 'Search gaming centers, cafes...',
                      hintStyle: GoogleFonts.inter(color: Colors.white70),
                      border: InputBorder.none,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _currentQuery = value;
                      });
                    },
                    onSubmitted: (_) => _performSearch(),
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(
                      Icons.clear,
                      color: Colors.white70,
                      size: 20,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _currentQuery = '';
                      });
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;
          
          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected 
                    ? const Color(0xff338125) 
                    : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isSelected 
                      ? const Color(0xff338125) 
                      : Colors.white.withOpacity(0.2),
                  ),
                ),
                child: Text(
                  filter,
                  style: GoogleFonts.inter(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResults() {
    return Obx(() {
      if (_cafeController.isLoading.value || _isSearching) {
        return const Center(
          child: RainbowGlowingLoader(size: 50),
        );
      }

      if (_filteredResults.isEmpty) {
        return _buildEmptyState();
      }

      return ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filteredResults.length,
        itemBuilder: (context, index) {
          final cafe = _filteredResults[index];
          return _buildResultCard(cafe, index);
        },
      );
    });
  }

  Widget _buildResultCard(Map<String, dynamic> cafe, int index) {
    final status = cafe['status'];
    final isOpen = status != null && status.toString() == 'active';
    final imageUrl = _getCafeImage(cafe, index);
    final address = _getCafeAddress(cafe);
    final features = _getCafeFeatures(cafe);
    final price = _getCafePrice(cafe);
    final rating = _getCafeRating(cafe);
    final distance = _getCafeDistance(cafe);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section
            Stack(
              children: [
                Container(
                  height: 200,
                  width: double.infinity,
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[800],
                      child: const Center(
                        child: RainbowGlowingLoader(size: 40),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[800],
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.white54,
                        size: 50,
                      ),
                    ),
                  ),
                ),
                // Status badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isOpen 
                        ? const Color(0xff338125) 
                        : Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isOpen ? 'OPEN' : 'CLOSED',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                // Type badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      (cafe['type'] ?? 'Gaming').toString(),
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // Content section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and rating
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          (cafe['cafe_name'] ?? 'Unknown Cafe').toString(),
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            rating.toString(),
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Address and distance
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: Colors.white54,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          address,
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Text(
                        distance,
                        style: GoogleFonts.inter(
                          color: const Color(0xff338125),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Features
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: features.map((feature) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xff338125).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xff338125).withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          feature,
                          style: GoogleFonts.inter(
                            color: const Color(0xff338125),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Price and action button
                  Row(
                    children: [
                      Text(
                        price,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xff338125),
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: isOpen ? () {
                          // Navigate to cafe details
                          Get.to(
                            () => ArenaDetailView(
                              images: imageUrl,
                              title: (cafe['cafe_name'] ?? 'Unknown Cafe').toString(),
                              address: address,
                              openingHours: '9 AM - 12 AM',
                              availableGames: features,
                              amenities: features,
                              phone: (cafe['phone'] ?? cafe['contact_number'] ?? 'Phone not available').toString(),
                              email: (cafe['email'] ?? 'Email not available').toString(),
                              ownerName: (cafe['owner_name'] ?? 'Owner not available').toString(),
                              reviews: const ['Great place!', 'Loved it!'],
                              vendorId: cafe['vendor_id'],
                            ),
                          );
                        } : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff338125),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: Text(
                          isOpen ? 'View Details' : 'Closed',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off,
              size: 64,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No cafes found',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _currentQuery = '';
                _selectedFilter = 'All';
                _searchController.clear();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff338125),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
            child: Text(
              'Clear Filters',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}