import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  runApp(const OxyTrackApp());
}

class OxyTrackApp extends StatelessWidget {
  const OxyTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OxyTrack',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF123B63)),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;

  Future<void> login() async {
    setState(() => isLoading = true);

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardPage()),
      );
    } on AuthException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terjadi kesalahan. Coba kembali.')),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FA),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_hospital,
                      size: 65,
                      color: Color(0xFF123B63),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'OxyTrack',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF123B63),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Sistem Manajemen Inventaris Tabung Medis',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        onPressed: isLoading ? null : login,
                        child: isLoading
                            ? const CircularProgressIndicator()
                            : const Text(
                                'MASUK',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'OxyTrack Hospital Inventory System',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool isLoading = true;
  String? errorMessage;

  int totalTabung = 0;
  int tabungFull = 0;
  int tabungEmpty = 0;
  int tabungHydrotest = 0;
  int tabungMaintenance = 0;

  @override
  void initState() {
    super.initState();
    loadInventory();
  }

  Future<void> loadInventory() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final stockData = await Supabase.instance.client
          .from('stock_balances')
          .select('item_type, status, quantity');

      final cylinderData = await Supabase.instance.client
          .from('cylinders')
          .select('item_type, status');

      int total = 0;
      int full = 0;
      int empty = 0;
      int hydrotest = 0;
      int maintenance = 0;

      for (final item in stockData) {
        final quantity = (item['quantity'] as num).toInt();
        total += quantity;

        if (item['status'] == 'Full') {
          full += quantity;
        } else if (item['status'] == 'Empty') {
          empty += quantity;
        }
      }

      for (final item in cylinderData) {
        total++;

        if (item['status'] == 'Full') {
          full++;
        } else if (item['status'] == 'Empty') {
          empty++;
        } else if (item['status'] == 'Hydrotest') {
          hydrotest++;
        } else if (item['status'] == 'Maintenance') {
          maintenance++;
        }
      }

      totalTabung = total;
      tabungFull = full;
      tabungEmpty = empty;
      tabungHydrotest = hydrotest;
      tabungMaintenance = maintenance;
    } catch (error) {
      errorMessage = 'Gagal mengambil data: $error';
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> logout() async {
    await Supabase.instance.client.auth.signOut();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  Widget inventoryCard(String title, int count, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 30, color: const Color(0xFF123B63)),
            const SizedBox(height: 12),
            Text(
              count.toString(),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            Text(title),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FA),
      appBar: AppBar(
        title: const Text('OxyTrack Dashboard'),
        backgroundColor: const Color(0xFF123B63),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: loadInventory,
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat ulang',
          ),
          IconButton(
            onPressed: logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Keluar',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadInventory,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Selamat Datang di OxyTrack',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: Color(0xFF123B63),
              ),
            ),
            const SizedBox(height: 6),
            Text(user?.email ?? ''),
            const SizedBox(height: 24),
            const Text(
              'Ringkasan Inventaris Tabung',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DistributionPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.local_shipping),
                label: const Text('Distribusi Tabung'),
              ),
            ),

            const SizedBox(height: 12),

            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (errorMessage != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(errorMessage!),
                ),
              )
            else
              Column(
                children: [
                  inventoryCard('Total Tabung', totalTabung, Icons.inventory_2),
                  inventoryCard(
                    'Tabung Kosong',
                    tabungEmpty,
                    Icons.inbox_outlined,
                  ),
                  inventoryCard(
                    'Dalam Hydrotest',
                    tabungHydrotest,
                    Icons.build_circle_outlined,
                  ),
                  inventoryCard(
                    'Maintenance',
                    tabungMaintenance,
                    Icons.handyman_outlined,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class DistributionPage extends StatefulWidget {
  const DistributionPage({super.key});

  @override
  State<DistributionPage> createState() => _DistributionPageState();
}

class _DistributionPageState extends State<DistributionPage> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> centralList = [];
  List<Map<String, dynamic>> roomList = [];

  String? selectedCentral;
  String? selectedRoom;
  String selectedStatus = 'Full';

  final quantityController = TextEditingController();
  final notesController = TextEditingController();

  bool isLoading = true;
bool isSaving = false;
bool isLoadingStock = false;
int availableStock = 0;
  @override
  void initState() {
    super.initState();
    loadUnits();
  }

  Future<void> loadUnits() async {
    try {
      final data = await supabase
          .from('units')
          .select('id, name, unit_type, parent_id')
          .order('name');

      final allUnits = List<Map<String, dynamic>>.from(data);

      centralList = allUnits
          .where((unit) => unit['unit_type'] == 'central')
          .toList();

      roomList = allUnits.where((unit) => unit['unit_type'] == 'room').toList();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat lokasi: $error')));
      }
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get availableRooms {
    if (selectedCentral == null) return [];

    return roomList
        .where((room) => room['parent_id'] == selectedCentral)
        .toList();
  }
Future<void> loadAvailableStock() async {
  if (selectedCentral == null) {
    setState(() {
      availableStock = 0;
      isLoadingStock = false;
    });
    return;
  }

  setState(() {
    isLoadingStock = true;
  });

  try {
    final data = await supabase
        .from('stock_balances')
        .select('quantity')
        .eq('unit_id', selectedCentral!)
        .eq('item_type', 'Besar')
        .eq('status', selectedStatus)
        .maybeSingle();

    if (!mounted) return;

    setState(() {
      availableStock =
          data == null ? 0 : (data['quantity'] as num).toInt();
      isLoadingStock = false;
    });
  } catch (error) {
    if (!mounted) return;

    setState(() {
      isLoadingStock = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Gagal memuat stok tersedia: $error')),
    );
  }
}
  Future<void> saveDistribution() async {
  if (selectedCentral == null ||
      selectedRoom == null ||
      quantityController.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lengkapi semua data distribusi')),
    );
    return;
  }

  final quantity = int.tryParse(quantityController.text.trim());

  if (quantity == null || quantity <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Jumlah tabung harus lebih dari nol')),
    );
    return;
  }

  if (isLoadingStock) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tunggu sampai stok selesai dimuat')),
    );
    return;
  }

  if (quantity > availableStock) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Stok tidak mencukupi. Stok tersedia hanya $availableStock tabung',
        ),
      ),
    );
    return;
  }

  setState(() {
    isSaving = true;
  });

  try {
    await supabase.rpc(
      'distribute_large_cylinder',
      params: {
        'p_from_unit_id': selectedCentral,
        'p_to_unit_id': selectedRoom,
        'p_status': selectedStatus,
        'p_quantity': quantity,
        'p_notes': notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
      },
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Distribusi tabung berhasil disimpan')),
    );

    Navigator.pop(context);
  } catch (error) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Distribusi gagal: $error')));
  } finally {
    if (mounted) {
      setState(() {
        isSaving = false;
      });
    }
  }
}
  @override
  void dispose() {
    quantityController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Distribusi Tabung')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Distribusi Tabung Besar',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  const Text('Central Asal'),
                  const SizedBox(height: 8),

                  DropdownButtonFormField<String>(
                    initialValue: selectedCentral,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Pilih Central',
                    ),
                    items: centralList.map((unit) {
                      return DropdownMenuItem<String>(
                        value: unit['id'] as String,
                        child: Text(unit['name'] as String),
                      );
                    }).toList(),
                   onChanged: (value) {
  setState(() {
    selectedCentral = value;
    selectedRoom = null;
  });
  loadAvailableStock();
},

                  const SizedBox(height: 20),

                  const Text('Ruangan Tujuan'),
                  const SizedBox(height: 8),

                  DropdownButtonFormField<String>(
                    initialValue: selectedRoom,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Pilih Ruangan',
                    ),
                    items: availableRooms.map((room) {
                      return DropdownMenuItem<String>(
                        value: room['id'] as String,
                        child: Text(room['name'] as String),
                      );
                    }).toList(),
                    onChanged: availableRooms.isEmpty
                        ? null
                        : (value) {
                            setState(() {
                              selectedRoom = value;
                            });
                          },
                  ),

                  const SizedBox(height: 20),

                  const Text('Status Tabung'),
                  const SizedBox(height: 8),

                  DropdownButtonFormField<String>(
                    initialValue: selectedStatus,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Full', child: Text('Full')),
                      DropdownMenuItem(value: 'Empty', child: Text('Empty')),
                    ],
                   onChanged: (value) {
  if (value != null) {
    setState(() {
      selectedStatus = value;
    });
    loadAvailableStock();
  }
},

                  const SizedBox(height: 20),

                  const Text('Jumlah Tabung'),
const SizedBox(height: 8),

Text(
  isLoadingStock
      ? 'Memuat stok tersedia...'
      : 'Stok tersedia: $availableStock tabung',
  style: const TextStyle(
    fontWeight: FontWeight.bold,
    color: Colors.green,
  ),
),

const SizedBox(height: 8),

                  TextField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Masukkan jumlah tabung',
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text('Catatan (Opsional)'),
                  const SizedBox(height: 8),

                  TextField(
                    controller: notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Tambahkan catatan distribusi',
                    ),
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: isSaving ? null : saveDistribution,
                      icon: isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                      label: Text(
                        isSaving ? 'Menyimpan...' : 'Simpan Distribusi',
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
