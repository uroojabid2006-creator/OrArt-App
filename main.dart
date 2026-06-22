// Copy this entire file into lib/main.dart
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'theme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DemoData.load();
  runApp(const OrArtApp());
}

class DemoData {
  static final List<Map<String, dynamic>> artworks = [
    {
      'id': 'a1',
      'title': 'Dreamy Hills',
      'price': 115,
      'category': 'Paintings',
      'image':
          'https://images.unsplash.com/photo-1504198453319-5ce911bafcde?w=700&q=80',
      'desc': 'Soft pastel landscape, original on canvas.',
      'isLocalFile': false,
    },
    {
      'id': 'a2',
      'title': 'Serenity Script',
      'price': 360,
      'category': 'Calligraphy',
      'image':
          'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=700&q=80',
      'desc': 'Elegant calligraphy on handmade paper.',
      'isLocalFile': false,
    },
    {
      'id': 'a3',
      'title': 'Abstract Flow',
      'price': 95,
      'category': 'Paintings',
      'image':
          'https://images.unsplash.com/photo-1549880338-65ddcdfd017b?w=700&q=80',
      'desc': 'Modern abstract acrylic on board.',
      'isLocalFile': false,
    },
  ];

  // persistence keys and runtime lists
  static const String _kArtworks = 'orart_artworks_v1';
  static const String _kWishlist = 'orart_wishlist_v1';

  static final List<Map<String, dynamic>> cart = [];
  static final List<Map<String, dynamic>> wishlist = [];
  static final List<OrderModel> orders = [];

  // Save artworks + wishlist + orders
  static Future<void> save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // save artworks
      await prefs.setString(_kArtworks, jsonEncode(artworks));
      // save wishlist
      await prefs.setString(_kWishlist, jsonEncode(wishlist));
      // save orders to file
      await saveOrders();
    } catch (_) {}
  }

  static Future<void> saveWishlist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kWishlist, jsonEncode(wishlist));
    } catch (_) {}
  }

  static Future<File> _ordersFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}${Platform.pathSeparator}orart_orders.json');
  }

  static Future<void> saveOrders() async {
    try {
      final f = await _ordersFile();
      final list = orders.map((o) => o.toJson()).toList();
      await f.writeAsString(jsonEncode(list));
    } catch (_) {}
  }

  static Future<String?> copyFileToAppDir(String srcPath) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final ext = srcPath.split('.').last;
      final dest = File(
        '${dir.path}${Platform.pathSeparator}orart_${DateTime.now().millisecondsSinceEpoch}.$ext',
      );
      await File(srcPath).copy(dest.path);
      return dest.path;
    } catch (_) {
      return null;
    }
  }

  static Future<void> addToCart(Map<String, dynamic> art, {int qty = 1}) async {
    final id = art['id'] as String? ?? '';
    if (id.isEmpty) return;
    final existing = cart.indexWhere((c) => c['art']['id'] == id);
    if (existing >= 0) {
      cart[existing]['qty'] = (cart[existing]['qty'] as int) + qty;
    } else {
      cart.add({'art': Map<String, dynamic>.from(art), 'qty': qty});
    }
  }

  static Future<void> removeFromCart(String artId) async {
    cart.removeWhere((c) => c['art']['id'] == artId);
  }

  static Future<void> clearCart() async {
    cart.clear();
  }

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final s = prefs.getString(_kArtworks);
      if (s != null) {
        final list = jsonDecode(s);
        if (list is List) {
          artworks.clear();
          for (final e in list) {
            if (e is Map) artworks.add(Map<String, dynamic>.from(e));
          }
        }
      }
    } catch (_) {}
    await loadWishlist();
    await loadOrders();
  }

  static Future<void> loadWishlist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final s = prefs.getString(_kWishlist);
      if (s == null) return;
      final list = jsonDecode(s);
      if (list is List) {
        wishlist.clear();
        for (final e in list) {
          if (e is Map) wishlist.add(Map<String, dynamic>.from(e));
        }
      }
    } catch (_) {}
  }

  static Future<void> loadOrders() async {
    try {
      final f = await _ordersFile();
      if (!await f.exists()) return;
      final s = await f.readAsString();
      final list = jsonDecode(s);
      if (list is List) {
        orders.clear();
        for (final e in list) {
          if (e is Map) {
            try {
              orders.add(OrderModel.fromJson(Map<String, dynamic>.from(e)));
            } catch (_) {}
          }
        }
      }
    } catch (_) {}
  }

  static Future<void> addOrder(OrderModel order) async {
    orders.insert(0, order);
    await saveOrders();
  }

  static Future<void> removeOrder(String orderId) async {
    orders.removeWhere((o) => o.orderId == orderId);
    await saveOrders();
  }

  static bool isInWishlist(String artId) {
    return wishlist.any((w) => w['id'] == artId);
  }

  static Future<void> addToWishlist(Map<String, dynamic> art) async {
    if (!isInWishlist(art['id'])) {
      wishlist.insert(0, Map<String, dynamic>.from(art));
      await saveWishlist();
    }
  }

  static Future<void> removeFromWishlist(String artId) async {
    wishlist.removeWhere((w) => w['id'] == artId);
    await saveWishlist();
  }
}

class OrderModel {
  final String orderId;
  final String artworkTitle;
  final String artworkImagePath;
  final double artworkPrice;
  final int deliveryCharges;
  final double totalAmount;
  final String customerName;
  final String phone;
  final String address;
  final String dateTime;

  OrderModel({
    required this.orderId,
    required this.artworkTitle,
    required this.artworkImagePath,
    required this.artworkPrice,
    required this.deliveryCharges,
    required this.totalAmount,
    required this.customerName,
    required this.phone,
    required this.address,
    required this.dateTime,
  });

  Map<String, dynamic> toJson() => {
    'orderId': orderId,
    'artworkTitle': artworkTitle,
    'artworkImagePath': artworkImagePath,
    'artworkPrice': artworkPrice,
    'deliveryCharges': deliveryCharges,
    'totalAmount': totalAmount,
    'customerName': customerName,
    'phone': phone,
    'address': address,
    'dateTime': dateTime,
  };

  static OrderModel fromJson(Map<String, dynamic> j) => OrderModel(
    orderId: j['orderId'] ?? '',
    artworkTitle: j['artworkTitle'] ?? '',
    artworkImagePath: j['artworkImagePath'] ?? '',
    artworkPrice: (j['artworkPrice'] ?? 0).toDouble(),
    deliveryCharges: (j['deliveryCharges'] ?? 200) as int,
    totalAmount: (j['totalAmount'] ?? 0).toDouble(),
    customerName: j['customerName'] ?? '',
    phone: j['phone'] ?? '',
    address: j['address'] ?? '',
    dateTime: j['dateTime'] ?? '',
  );
}

class OrArtApp extends StatelessWidget {
  const OrArtApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OrArt (Demo)',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: false,
        brightness: Brightness.light,
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Sans',
      ),
      home: const SplashAndHome(),
    );
  }
}

class SplashAndHome extends StatefulWidget {
  const SplashAndHome({super.key});
  @override
  State<SplashAndHome> createState() => _SplashAndHomeState();
}

class _SplashAndHomeState extends State<SplashAndHome> {
  bool _splashDone = false;
  @override
  void initState() {
    super.initState();
    Future.delayed(
      const Duration(milliseconds: 600),
      () => setState(() => _splashDone = true),
    );
  }

  @override
  Widget build(BuildContext context) =>
      _splashDone ? const HomeShell() : const SplashScreen();
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEADFF6), Color(0xFFFFE6DE)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: Colors.white70,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.brush, size: 44, color: Colors.black87),
              ),
              const SizedBox(height: 18),
              const Text(
                'OrArt',
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                'Create • Customize • Collect',
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  late final List<Widget> pages;
  @override
  void initState() {
    super.initState();
    pages = [
      const MarketplaceScreen(),
      const DesignStudioScreen(),
      const CartScreen(),
      const WishlistScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.brush_outlined),
            label: 'Design Studio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            label: 'Wishlist',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

////////////////////////////////////////////////////////////////////////////////
// -------------------- Marketplace Screen --------------------
////////////////////////////////////////////////////////////////////////////////

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});
  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  String selectedCategory = 'All';
  final List<String> cats = ['All', 'Paintings', 'Calligraphy', 'Crochet'];

  List<Map<String, dynamic>> get filtered {
    if (selectedCategory == 'All') return DemoData.artworks;
    return DemoData.artworks
        .where((a) => a['category'] == selectedCategory)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'OrArt',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                ),
                IconButton(icon: const Icon(Icons.search), onPressed: () {}),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 46,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: cats.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final c = cats[i];
                final sel = c == selectedCategory;
                return ChoiceChip(
                  label: Text(c),
                  selected: sel,
                  onSelected: (_) => setState(() => selectedCategory = c),
                  selectedColor: Colors.deepPurple.shade50,
                  backgroundColor: Colors.white,
                  elevation: 0.5,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: GridView.builder(
                itemCount: filtered.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.64,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (_, idx) {
                  final art = filtered[idx];
                  return GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ArtworkDetailScreen(art: art),
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Color.fromRGBO(0, 0, 0, 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(14),
                              ),
                              child: art['image'] != null
                                  ? (art['isLocalFile'] == true
                                        ? Image.file(
                                            File(art['image']),
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                          )
                                        : Image.network(
                                            art['image'],
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                          ))
                                  : Container(color: Colors.grey[200]),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                Text(
                                  art['title'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'PKR ${art['price']}',
                                  style: const TextStyle(color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Orders have been moved to the Admin Panel — do not show them on the public marketplace/home.
          const Divider(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

////////////////////////////////////////////////////////////////////////////////
// -------------------- Artwork Details --------------------
////////////////////////////////////////////////////////////////////////////////

class ArtworkDetailScreen extends StatefulWidget {
  final Map<String, dynamic> art;
  const ArtworkDetailScreen({required this.art, super.key});
  @override
  State<ArtworkDetailScreen> createState() => _ArtworkDetailScreenState();
}

class _ArtworkDetailScreenState extends State<ArtworkDetailScreen> {
  late bool _isFav;

  @override
  void initState() {
    super.initState();
    final id = widget.art['id'] as String? ?? '';
    _isFav = id.isNotEmpty && DemoData.isInWishlist(id);
  }

  Future<void> _toggleFav() async {
    final art = widget.art;
    final id = art['id'] as String? ?? '';
    if (id.isEmpty) return;
    if (_isFav) {
      await DemoData.removeFromWishlist(id);
      setState(() => _isFav = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Removed from wishlist')));
    } else {
      await DemoData.addToWishlist(art);
      setState(() => _isFav = true);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Added to wishlist')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final art = widget.art;
    return Scaffold(
      appBar: AppBar(
        title: Text(art['title'], style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: art['image'] != null
                ? Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: (art['isLocalFile'] == true
                        ? Image.file(File(art['image']), fit: BoxFit.contain)
                        : Image.network(art['image'], fit: BoxFit.contain)),
                  )
                : Container(),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'PKR ${art['price']}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isFav ? Icons.favorite : Icons.favorite_border,
                        color: Colors.pink,
                      ),
                      onPressed: _toggleFav,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(art['desc'] ?? ''),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          DemoData.addToCart(art);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Added to cart (demo)'),
                            ),
                          );
                        },
                        child: const Text('Add to Cart'),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

////////////////////////////////////////////////////////////////////////////////
// -------------------- Design Studio (simple Canvas) --------------------
////////////////////////////////////////////////////////////////////////////////

class DesignStudioScreen extends StatefulWidget {
  const DesignStudioScreen({super.key});
  @override
  State<DesignStudioScreen> createState() => _DesignStudioScreenState();
}

class _DesignStudioScreenState extends State<DesignStudioScreen> {
  final List<_CanvasItem> items = [];
  int counter = 0;
  final GlobalKey _repaintKey = GlobalKey();
  // drawing/strokes
  bool _brushMode = false;
  final List<_Stroke> _strokes = [];
  _Stroke? _currentStroke;
  Color _brushColor = Colors.black;
  double _brushWidth = 4.0;
  String _brushType = 'pen'; // 'pen' | 'marker' | 'calligraphy'
  String _selectedFont = 'Sans';

  void _undo() {
    setState(() {
      // prefer undoing strokes first, otherwise remove last canvas item
      if (_strokes.isNotEmpty) {
        _strokes.removeLast();
        return;
      }
      if (items.isNotEmpty) {
        items.removeLast();
      }
    });
  }

  // eraser removed — only undo is available

  void _addText() async {
    final text = await showDialog<String>(
      context: context,
      builder: (c) {
        final ctrl = TextEditingController();
        return AlertDialog(
          title: const Text('Add Text'),
          content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(hintText: 'Enter text'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(c, ctrl.text),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
    if (text != null && text.trim().isNotEmpty) {
      setState(
        () => items.add(
          _CanvasItem(
            id: 't${counter++}',
            type: 'text',
            text: text,
            dx: 40,
            dy: 40,
            fontFamily: _selectedFont,
          ),
        ),
      );
    }
  }

  void _addImageUrl() async {
    final url = await showDialog<String>(
      context: context,
      builder: (c) {
        final ctrl = TextEditingController();
        return AlertDialog(
          title: const Text('Add Image by URL'),
          content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(hintText: 'Paste image URL'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(c, ctrl.text),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
    if (url != null && url.trim().isNotEmpty) {
      setState(
        () => items.add(
          _CanvasItem(
            id: 'i${counter++}',
            type: 'image',
            imageUrl: url.trim(),
            dx: 50,
            dy: 50,
          ),
        ),
      );
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final XFile? f = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (f != null) {
      // store local file path in items so it can be displayed with FileImage
      setState(() {
        items.add(
          _CanvasItem(
            id: 'p${counter++}',
            type: 'image',
            imageUrl: f.path,
            dx: 60,
            dy: 60,
            isLocalFile: true,
          ),
        );
      });
    }
  }

  Future<void> _saveDesign() async {
    // capture the canvas area and save as PNG to app documents; if calligraphy strokes are present, add to gallery
    try {
      final boundary =
          _repaintKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to capture design')),
        );
        return;
      }
      final ui.Image img = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to encode image')));
        return;
      }
      final bytes = byteData.buffer.asUint8List();
      final dir = await getApplicationDocumentsDirectory();
      final file = File(
        '${dir.path}${Platform.pathSeparator}design_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes);

      final hasCalligraphy = _strokes.any((s) => s.type == 'calligraphy');
      if (hasCalligraphy) {
        final art = {
          'id': 'd${DateTime.now().millisecondsSinceEpoch}',
          'title': 'Design ${DateTime.now().year}',
          'price': 0,
          'category': 'Designs',
          'image': file.path,
          'isLocalFile': true,
          'desc': 'Saved from Design Studio',
        };
        DemoData.artworks.insert(0, art);
        await DemoData.save();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Design saved to gallery')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // keep scaffold default resize behaviour to handle keyboard; toolbar moved to bottomNavigationBar
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            const Text(
              'Design Studio',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Stack(
                  children: [
                    // drawing canvas
                    Positioned.fill(
                      child: RepaintBoundary(
                        key: _repaintKey,
                        child: GestureDetector(
                          onPanStart: (p) {
                            if (!_brushMode) return;
                            setState(() {
                              _currentStroke = _Stroke(
                                [p.localPosition],
                                _brushColor,
                                _brushWidth,
                                _brushType,
                              );
                              _strokes.add(_currentStroke!);
                            });
                          },
                          onPanUpdate: (p) {
                            setState(() {
                              _currentStroke?.points.add(p.localPosition);
                            });
                          },
                          onPanEnd: (_) =>
                              setState(() => _currentStroke = null),
                          child: CustomPaint(painter: _StrokePainter(_strokes)),
                        ),
                      ),
                    ),
                    // existing items
                    ...items.map(
                      (it) => _DraggableCanvasItem(
                        item: it,
                        onMoved: () => setState(() {}),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (ctx, constraints) {
            final maxHeight = min(160.0, MediaQuery.of(ctx).size.height * 0.28);
            return Container(
              height: maxHeight,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: Wrap(
                    alignment: WrapAlignment.start,
                    runSpacing: 8,
                    spacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.start,
                    children: [
                      _StudioButton(
                        icon: Icons.text_fields,
                        label: 'T',
                        onTap: _addText,
                      ),
                      _StudioButton(
                        icon: Icons.image_outlined,
                        label: 'Img',
                        onTap: _addImageUrl,
                      ),
                      _StudioButton(
                        icon: Icons.photo_library,
                        label: 'Gallery',
                        onTap: _pickFromGallery,
                      ),
                      // Brush toggle: enables freehand drawing when active
                      GestureDetector(
                        onTap: () => setState(() => _brushMode = !_brushMode),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: _brushMode
                                  ? Colors.deepPurple
                                  : Colors.deepPurple.shade50,
                              child: Icon(
                                Icons.brush,
                                color: _brushMode
                                    ? Colors.white
                                    : Colors.deepPurple,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(_brushMode ? 'Brush' : 'Brush'),
                          ],
                        ),
                      ),
                      _StudioButton(
                        icon: Icons.undo,
                        label: 'Undo',
                        onTap: _undo,
                      ),
                      // Font selector (limited width)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Font:'),
                            const SizedBox(width: 8),
                            DropdownButton<String>(
                              value: _selectedFont,
                              items: const [
                                DropdownMenuItem(
                                  value: 'Sans',
                                  child: Text('Sans'),
                                ),
                                DropdownMenuItem(
                                  value: 'DancingScript',
                                  child: Text('Dancing Script'),
                                ),
                                DropdownMenuItem(
                                  value: 'GreatVibes',
                                  child: Text('Great Vibes'),
                                ),
                              ],
                              onChanged: (v) {
                                if (v != null)
                                  setState(() => _selectedFont = v);
                              },
                            ),
                          ],
                        ),
                      ),
                      // Brush controls: fixed width and internally scrollable to avoid expanding toolbar
                      SizedBox(
                        width: 240,
                        height: maxHeight - 16,
                        child: Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text('Color:'),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () => setState(
                                          () => _brushColor = Colors.black,
                                        ),
                                        child: const CircleAvatar(
                                          radius: 12,
                                          backgroundColor: Colors.black,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () => setState(
                                          () => _brushColor = Colors.red,
                                        ),
                                        child: const CircleAvatar(
                                          radius: 12,
                                          backgroundColor: Colors.red,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () => setState(
                                          () => _brushColor = Colors.blue,
                                        ),
                                        child: const CircleAvatar(
                                          radius: 12,
                                          backgroundColor: Colors.blue,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      TextButton(
                                        onPressed: () async {
                                          Color picked = _brushColor;
                                          final result = await showDialog<Color?>(
                                            context: context,
                                            builder: (ctx) {
                                              int r = picked.red;
                                              int g = picked.green;
                                              int b = picked.blue;
                                              return StatefulBuilder(
                                                builder: (c2, setStateSB) => AlertDialog(
                                                  title: const Text(
                                                    'Custom Color',
                                                  ),
                                                  content: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Container(
                                                        width: double.infinity,
                                                        height: 48,
                                                        color: Color.fromARGB(
                                                          255,
                                                          r,
                                                          g,
                                                          b,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Row(
                                                        children: [
                                                          const Text('R'),
                                                          Expanded(
                                                            child: Slider(
                                                              value: r
                                                                  .toDouble(),
                                                              min: 0,
                                                              max: 255,
                                                              onChanged: (v) =>
                                                                  setStateSB(
                                                                    () => r = v
                                                                        .toInt(),
                                                                  ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      Row(
                                                        children: [
                                                          const Text('G'),
                                                          Expanded(
                                                            child: Slider(
                                                              value: g
                                                                  .toDouble(),
                                                              min: 0,
                                                              max: 255,
                                                              onChanged: (v) =>
                                                                  setStateSB(
                                                                    () => g = v
                                                                        .toInt(),
                                                                  ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      Row(
                                                        children: [
                                                          const Text('B'),
                                                          Expanded(
                                                            child: Slider(
                                                              value: b
                                                                  .toDouble(),
                                                              min: 0,
                                                              max: 255,
                                                              onChanged: (v) =>
                                                                  setStateSB(
                                                                    () => b = v
                                                                        .toInt(),
                                                                  ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(c2),
                                                      child: const Text(
                                                        'Cancel',
                                                      ),
                                                    ),
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                            c2,
                                                            Color.fromARGB(
                                                              255,
                                                              r,
                                                              g,
                                                              b,
                                                            ),
                                                          ),
                                                      child: const Text('OK'),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          );
                                          if (result != null)
                                            setState(
                                              () => _brushColor = result,
                                            );
                                        },
                                        child: const Text('Custom'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Text('Type:'),
                                      const SizedBox(width: 8),
                                      DropdownButton<String>(
                                        value: _brushType,
                                        items: const [
                                          DropdownMenuItem(
                                            value: 'pen',
                                            child: Text('Pen'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'marker',
                                            child: Text('Marker'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'calligraphy',
                                            child: Text('Calligraphy'),
                                          ),
                                        ],
                                        onChanged: (v) {
                                          if (v != null)
                                            setState(() => _brushType = v);
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Text('Width:'),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Slider(
                                          value: _brushWidth,
                                          min: 1,
                                          max: 30,
                                          divisions: 29,
                                          label: _brushWidth.toStringAsFixed(0),
                                          onChanged: (v) =>
                                              setState(() => _brushWidth = v),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      _StudioButton(
                        icon: Icons.save,
                        label: 'Save',
                        onTap: _saveDesign,
                      ),
                      _StudioButton(
                        icon: Icons.layers,
                        label: 'Export',
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Export (demo)')),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),o987uytfdszZsdftyuiop[]\][pokjhgv\      '[poiuyggggcxzwertyuiopoiko]']
      ),iu9
    );  }
}

class _StudioButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _StudioButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.deepPurple.shade50,
            child: Icon(icon, color: Colors.deepPurple),
          ),
          const SizedBox(height: 6),
          Text(label),
        ],
      ),
    );
  }
}

class _CanvasItem {
  final String id;
  final String type; // 'text' or 'image'
  String? text;
  String? imageUrl;
  double dx;
  double dy;
  String? fontFamily;
  bool? isLocalFile;
  _CanvasItem({
    required this.id,
    required this.type,
    this.text,
    this.imageUrl,
    required this.dx,
    required this.dy,
    this.fontFamily,
    this.isLocalFile,
  });
}

class _Stroke {
  List<Offset> points;
  final Color color;
  final double width;
  final String type;
  _Stroke(this.points, this.color, this.width, this.type);
}

class _StrokePainter extends CustomPainter {
  final List<_Stroke> strokes;
  _StrokePainter(this.strokes);
  @override
  void paint(Canvas canvas, Size size) {
    for (final s in strokes) {
      final p = Paint()
        ..color = s.color
        ..strokeCap = s.type == 'calligraphy' ? StrokeCap.butt : StrokeCap.round
        ..style = PaintingStyle.stroke
        ..strokeWidth = s.width
        ..strokeJoin = StrokeJoin.round;
      if (s.type == 'marker') {
        p.maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
      }
      for (int i = 0; i < s.points.length - 1; i++) {
        canvas.drawLine(s.points[i], s.points[i + 1], p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StrokePainter oldDelegate) => true;
}

class _DraggableCanvasItem extends StatefulWidget {
  final _CanvasItem item;
  final VoidCallback onMoved;
  const _DraggableCanvasItem({required this.item, required this.onMoved});
  @override
  State<_DraggableCanvasItem> createState() => _DraggableCanvasItemState();
}

class _DraggableCanvasItemState extends State<_DraggableCanvasItem> {
  late double x, y;
  @override
  void initState() {
    super.initState();
    x = widget.item.dx;
    y = widget.item.dy;
  }

  @override
  Widget build(BuildContext context) {
    final it = widget.item;
    return Positioned(
      left: x,
      top: y,
      child: GestureDetector(
        onPanUpdate: (p) => setState(() {
          x += p.delta.dx;
          y += p.delta.dy;
          widget.item.dx = x;
          widget.item.dy = y;
          widget.onMoved();
        }),
        child: it.type == 'text'
            ? Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white70,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Builder(
                  builder: (_) {
                    final txt = it.text ?? '';
                    final f = it.fontFamily ?? 'Sans';
                    final ts = TextStyle(fontSize: 18);
                    if (f == 'Sans') return Text(txt, style: ts);
                    if (f == 'DancingScript') {
                      return Text(
                        txt,
                        style: GoogleFonts.dancingScript(textStyle: ts),
                      );
                    }
                    if (f == 'GreatVibes') {
                      return Text(
                        txt,
                        style: GoogleFonts.greatVibes(textStyle: ts),
                      );
                    }
                    return Text(txt, style: ts);
                  },
                ),
              )
            : (it.imageUrl != null
                  ? SizedBox(
                      width: 120,
                      height: 120,
                      child: it.isLocalFile == true
                          ? Image.file(File(it.imageUrl!), fit: BoxFit.cover)
                          : Image.network(it.imageUrl!, fit: BoxFit.cover),
                    )
                  : Container(
                      width: 120,
                      height: 120,
                      color: Colors.grey[200],
                    )),
      ),
    );
  }
}

// AR Preview removed — feature deprecated in this demo.

////////////////////////////////////////////////////////////////////////////////
// -------------------- Cart, Wishlist, Profile, Admin --------------------
////////////////////////////////////////////////////////////////////////////////

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 12),
          const Text(
            'Cart',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: DemoData.cart.isEmpty
                ? const Center(
                    child: Text(
                      'Your cart is empty. Add items from marketplace.',
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: DemoData.cart.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (_, i) {
                      final c = DemoData.cart[i];
                      final art = c['art'] as Map<String, dynamic>;
                      final qty = c['qty'] as int;
                      return ListTile(
                        leading: art['image'] != null
                            ? SizedBox(
                                width: 56,
                                child: art['isLocalFile'] == true
                                    ? Image.file(
                                        File(art['image']),
                                        fit: BoxFit.cover,
                                      )
                                    : Image.network(
                                        art['image'],
                                        fit: BoxFit.cover,
                                      ),
                              )
                            : null,
                        title: Text(art['title'] ?? 'Item'),
                        subtitle: Text('PKR ${art['price'] ?? 0} • Qty: $qty'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () {
                            setState(() {
                              DemoData.removeFromCart(art['id']);
                            });
                          },
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: DemoData.cart.isEmpty
                        ? null
                        : () {
                            setState(() {
                              DemoData.clearCart();
                            });
                          },
                    child: const Text('Clear Cart'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: DemoData.cart.isEmpty
                        ? null
                        : () async {
                            // navigate to checkout screen
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => CheckoutScreen(),
                              ),
                            );
                            // after returning, refresh state in case cart cleared
                            setState(() {});
                          },
                    child: const Text('Checkout'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Duplicate CartScreen removed - using the single stateful CartScreen defined earlier.

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});
  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 12),
          const Text(
            'Wishlist',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: DemoData.wishlist.isEmpty
                ? const Center(child: Text('Your wishlist is empty'))
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: DemoData.wishlist.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (_, i) {
                      final a = DemoData.wishlist[i];
                      return ListTile(
                        leading: a['image'] != null
                            ? SizedBox(
                                width: 56,
                                child: a['isLocalFile'] == true
                                    ? Image.file(
                                        File(a['image']),
                                        fit: BoxFit.cover,
                                      )
                                    : Image.network(
                                        a['image'],
                                        fit: BoxFit.cover,
                                      ),
                              )
                            : null,
                        title: Text(a['title'] ?? ''),
                        subtitle: Text(
                          'PKR ${a['price'] ?? 0} • ${a['category'] ?? ''}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            await DemoData.removeFromWishlist(a['id']);
                            if (!mounted) return;
                            setState(() {});
                          },
                        ),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ArtworkDetailScreen(art: a),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

////////////////////////////////////////////////////////////////////////////////
// -------------------- Checkout Screen & Orders --------------------
////////////////////////////////////////////////////////////////////////////////

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  int get deliveryCharges => 200; // PKR fixed

  double get artworksTotal {
    double s = 0;
    for (final c in DemoData.cart) {
      final art = c['art'] as Map<String, dynamic>;
      final price = (art['price'] ?? 0) as num;
      final qty = (c['qty'] ?? 1) as int;
      s += price * qty;
    }
    return s.toDouble();
  }

  double get grandTotal => artworksTotal + deliveryCharges;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final address = _addressCtrl.text.trim();

    // create one order per cart item (persist each)
    final now = DateTime.now();
    for (final c in List<Map<String, dynamic>>.from(DemoData.cart)) {
      final art = Map<String, dynamic>.from(c['art']);
      final price = (art['price'] ?? 0) as num;
      final qty = (c['qty'] ?? 1) as int;
      final priceDouble = price.toDouble();
      final total = priceDouble * qty + deliveryCharges;
      final orderModel = OrderModel(
        orderId:
            'o${DateTime.now().millisecondsSinceEpoch}${Random().nextInt(999)}',
        artworkTitle: art['title'] ?? '',
        artworkImagePath: art['image'] ?? '',
        artworkPrice: priceDouble,
        deliveryCharges: deliveryCharges,
        totalAmount: total,
        customerName: name,
        phone: phone,
        address: address,
        dateTime: now.toIso8601String(),
      );
      await DemoData.addOrder(orderModel);
    }

    // clear cart
    DemoData.clearCart();

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Order placed'),
        content: const Text('Your order(s) have been placed and saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Customer details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Enter name'
                              : null,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _phoneCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Enter phone'
                              : null,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _addressCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Address',
                          ),
                          minLines: 2,
                          maxLines: 4,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Enter address'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Order summary',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...DemoData.cart.map((c) {
                          final art = c['art'] as Map<String, dynamic>;
                          final qty = (c['qty'] ?? 1) as int;
                          final price = (art['price'] ?? 0) as num;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: art['image'] != null
                                ? SizedBox(
                                    width: 48,
                                    child: (art['isLocalFile'] == true
                                        ? Image.file(
                                            File(art['image']),
                                            fit: BoxFit.cover,
                                          )
                                        : Image.network(
                                            art['image'],
                                            fit: BoxFit.cover,
                                          )),
                                  )
                                : null,
                            title: Text(art['title'] ?? ''),
                            subtitle: Text(
                              'Qty: $qty • PKR ${price.toString()}',
                            ),
                            trailing: Text(
                              'PKR ${(price * qty).toStringAsFixed(0)}',
                            ),
                          );
                        }),
                        const Divider(),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Artworks total'),
                          trailing: Text(
                            'PKR ${artworksTotal.toStringAsFixed(0)}',
                          ),
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Delivery Charges'),
                          trailing: Text('PKR $deliveryCharges'),
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Total'),
                          trailing: Text(
                            'PKR ${grandTotal.toStringAsFixed(0)}',
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Payment method: Cash on Delivery',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: DemoData.cart.isEmpty ? null : _submit,
                  child: const Text('Place Order (COD)'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.deepPurple.shade50,
              child: const Icon(
                Icons.person,
                size: 40,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Artist / Owner',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const AdminPanel()));
              },
              child: const Text('Admin Panel'),
            ),
            const SizedBox(height: 20),
            const Text('Order History'),
            const SizedBox(height: 12),
            Expanded(
              child: DemoData.orders.isEmpty
                  ? const Center(child: Text('No orders yet'))
                  : ListView.separated(
                      itemCount: DemoData.orders.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (_, i) {
                        final OrderModel o = DemoData.orders[i];
                        Widget? leading;
                        if (o.artworkImagePath.isNotEmpty) {
                          leading = o.artworkImagePath.startsWith('http')
                              ? SizedBox(
                                  width: 64,
                                  child: Image.network(
                                    o.artworkImagePath,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : SizedBox(
                                  width: 64,
                                  child: Image.file(
                                    File(o.artworkImagePath),
                                    fit: BoxFit.cover,
                                  ),
                                );
                        }
                        return ListTile(
                          leading: leading,
                          title: Text(o.artworkTitle),
                          subtitle: Text(
                            '${o.customerName} • ${o.phone}\nTotal: PKR ${o.totalAmount.toStringAsFixed(0)}',
                          ),
                          isThreeLine: true,
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_forever),
                            onPressed: () async {
                              await DemoData.removeOrder(o.orderId);
                              if (!Navigator.of(context).mounted) return;
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});
  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  final _title = TextEditingController();
  final _price = TextEditingController();
  String _category = 'Paintings';
  final _image = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  void _add() {
    final t = _title.text.trim();
    final p = double.tryParse(_price.text.trim()) ?? 0.0;
    final url = _image.text.trim();
    if (t.isEmpty || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter title and image URL')),
      );
      return;
    }
    DemoData.artworks.insert(0, {
      'id': 'a${Random().nextInt(9999)}',
      'title': t,
      'price': p,
      'category': _category,
      'image': url,
      'isLocalFile': false,
      'desc': '',
    });
    _title.clear();
    _price.clear();
    _image.clear();
    setState(() {});
    // persist changes
    DemoData.save();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Artwork added and saved (demo)')),
    );
  }

  Future<void> _pickGalleryAsAdmin() async {
    final XFile? f = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (f == null) return;
    // Prompt admin for metadata (title/price/category)
    final meta = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (c) {
        final titleCtrl = TextEditingController(text: 'From Gallery');
        final priceCtrl = TextEditingController(text: '0');
        String category = 'Paintings';
        return AlertDialog(
          title: const Text('Artwork details'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: priceCtrl,
                  decoration: const InputDecoration(labelText: 'Price'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  items: const [
                    DropdownMenuItem(
                      value: 'Paintings',
                      child: Text('Paintings'),
                    ),
                    DropdownMenuItem(
                      value: 'Calligraphy',
                      child: Text('Calligraphy'),
                    ),
                    DropdownMenuItem(value: 'Crochet', child: Text('Crochet')),
                  ],
                  onChanged: (v) {
                    if (v != null) category = v;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final t = titleCtrl.text.trim();
                final p = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
                Navigator.pop(c, {
                  'title': t,
                  'price': p,
                  'category': category,
                });
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
    if (meta == null) return;

    // copy file into app documents so it persists across restarts
    final newPath = await DemoData.copyFileToAppDir(f.path);
    final art = {
      'id': 'a${Random().nextInt(9999)}',
      'title': meta['title'] ?? 'From Gallery',
      'price': meta['price'] ?? 0,
      'category': meta['category'] ?? 'Paintings',
      'image': newPath ?? f.path,
      'isLocalFile': newPath != null,
      'desc': 'Added from device gallery',
    };
    DemoData.artworks.insert(0, art);
    if (!mounted) return;
    setState(() {});
    // persist artworks metadata (and ensure image file is in app folder)
    await DemoData.save();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gallery artwork added and saved.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _price,
              decoration: const InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _category,
              items: const [
                DropdownMenuItem(value: 'Paintings', child: Text('Paintings')),
                DropdownMenuItem(
                  value: 'Calligraphy',
                  child: Text('Calligraphy'),
                ),
                DropdownMenuItem(value: 'Crochet', child: Text('Crochet')),
              ],
              onChanged: (v) {
                if (v != null) _category = v;
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _image,
              decoration: const InputDecoration(labelText: 'Image URL'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _add,
              child: const Text('Add Artwork (demo)'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _pickGalleryAsAdmin,
              child: const Text('Add from Gallery'),
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            const Text('Existing (demo)'),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: DemoData.artworks.length,
                itemBuilder: (_, i) {
                  final a = DemoData.artworks[i];
                  Widget? leading;
                  if (a['image'] != null) {
                    if (a['isLocalFile'] == true) {
                      leading = SizedBox(
                        width: 56,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.file(
                            File(a['image']),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    } else {
                      leading = SizedBox(
                        width: 56,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(a['image'], fit: BoxFit.cover),
                        ),
                      );
                    }
                  }
                  return ListTile(
                    leading: leading,
                    title: Text(a['title'] ?? ''),
                    subtitle: Text('PKR ${a['price']} • ${a['category']}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        // if local file, try to delete the copied file
                        try {
                          if (a['isLocalFile'] == true && a['image'] != null) {
                            final f = File(a['image']);
                            if (await f.exists()) await f.delete();
                          }
                        } catch (_) {}
                        DemoData.artworks.removeAt(i);
                        await DemoData.save();
                        setState(() {});
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            const Text('Orders (demo)'),
            const SizedBox(height: 8),
            Expanded(
              child: DemoData.orders.isEmpty
                  ? const Center(child: Text('No orders yet'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: DemoData.orders.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (_, i) {
                        final o = DemoData.orders[i];
                        Widget? leading;
                        if (o.artworkImagePath.isNotEmpty) {
                          if (o.artworkImagePath.startsWith('http')) {
                            leading = SizedBox(
                              width: 56,
                              child: Image.network(
                                o.artworkImagePath,
                                fit: BoxFit.cover,
                              ),
                            );
                          } else {
                            leading = SizedBox(
                              width: 56,
                              child: Image.file(
                                File(o.artworkImagePath),
                                fit: BoxFit.cover,
                              ),
                            );
                          }
                        }
                        return ListTile(
                          leading: leading,
                          title: Text(o.artworkTitle),
                          subtitle: Text(
                            '${o.customerName} • ${o.phone}\nTotal: PKR ${o.totalAmount.toStringAsFixed(0)}',
                          ),
                          isThreeLine: true,
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_forever),
                            onPressed: () async {
                              await DemoData.removeOrder(o.orderId);
                              if (!mounted) return;
                              setState(() {});
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Order deleted')),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
