import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const NegocioApp());

class NegocioApp extends StatelessWidget {
  const NegocioApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mi Negocio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

// ---------------- MODELOS ----------------
class Producto {
  String nombre;
  int cantidad;
  double precio;
  Producto({required this.nombre, required this.cantidad, required this.precio});
  Map<String, dynamic> toJson() =>
      {'nombre': nombre, 'cantidad': cantidad, 'precio': precio};
  factory Producto.fromJson(Map<String, dynamic> j) => Producto(
        nombre: j['nombre'],
        cantidad: j['cantidad'],
        precio: (j['precio'] as num).toDouble(),
      );
}

class Movimiento {
  String descripcion;
  double monto;
  bool esIngreso;
  DateTime fecha;
  Movimiento({
    required this.descripcion,
    required this.monto,
    required this.esIngreso,
    required this.fecha,
  });
  Map<String, dynamic> toJson() => {
        'descripcion': descripcion,
        'monto': monto,
        'esIngreso': esIngreso,
        'fecha': fecha.toIso8601String()
      };
  factory Movimiento.fromJson(Map<String, dynamic> j) => Movimiento(
        descripcion: j['descripcion'],
        monto: (j['monto'] as num).toDouble(),
        esIngreso: j['esIngreso'],
        fecha: DateTime.parse(j['fecha']),
      );
}

// ---------------- ALMACENAMIENTO ----------------
class Store {
  static const _kProd = 'productos';
  static const _kMov = 'movimientos';
  static const _kDen = 'denominaciones';

  static Future<List<Producto>> getProductos() async {
    final sp = await SharedPreferences.getInstance();
    final s = sp.getString(_kProd);
    if (s == null) return [];
    return (jsonDecode(s) as List).map((e) => Producto.fromJson(e)).toList();
  }

  static Future<void> setProductos(List<Producto> l) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kProd, jsonEncode(l.map((e) => e.toJson()).toList()));
  }

  static Future<List<Movimiento>> getMovimientos() async {
    final sp = await SharedPreferences.getInstance();
    final s = sp.getString(_kMov);
    if (s == null) return [];
    return (jsonDecode(s) as List).map((e) => Movimiento.fromJson(e)).toList();
  }

  static Future<void> setMovimientos(List<Movimiento> l) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kMov, jsonEncode(l.map((e) => e.toJson()).toList()));
  }

  static Future<Map<String, int>> getDenominaciones() async {
    final sp = await SharedPreferences.getInstance();
    final s = sp.getString(_kDen);
    if (s == null) return {};
    return Map<String, int>.from(jsonDecode(s));
  }

  static Future<void> setDenominaciones(Map<String, int> m) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kDen, jsonEncode(m));
  }
}

// ---------------- HOME ----------------
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _idx = 0;
  List<Producto> _productos = [];
  List<Movimiento> _movimientos = [];
  Map<String, int> _denominaciones = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final p = await Store.getProductos();
    final m = await Store.getMovimientos();
    final d = await Store.getDenominaciones();
    if (!mounted) return;
    setState(() {
      _productos = p;
      _movimientos = m;
      _denominaciones = d;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final pages = [
      _Dashboard(productos: _productos, movimientos: _movimientos),
      _ProductosPage(
        productos: _productos,
        onChange: (l) {
          setState(() => _productos = l);
          Store.setProductos(l);
        },
      ),
      _GananciasPage(
        movimientos: _movimientos,
        onChange: (l) {
          setState(() => _movimientos = l);
          Store.setMovimientos(l);
        },
      ),
      _ContadorPage(
        denominaciones: _denominaciones,
        onChange: (m) {
          setState(() => _denominaciones = m);
          Store.setDenominaciones(m);
        },
      ),
    ];
    return Scaffold(
      body: pages[_idx],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        onDestinationSelected: (i) => setState(() => _idx = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Resumen'),
          NavigationDestination(icon: Icon(Icons.inventory_2), label: 'Productos'),
          NavigationDestination(icon: Icon(Icons.trending_up), label: 'Ganancias'),
          NavigationDestination(icon: Icon(Icons.payments), label: 'Contador'),
        ],
      ),
    );
  }
}

// ---------------- DASHBOARD ----------------
class _Dashboard extends StatelessWidget {
  final List<Producto> productos;
  final List<Movimiento> movimientos;
  const _Dashboard({required this.productos, required this.movimientos});

  @override
  Widget build(BuildContext context) {
    double ingresos = 0, gastos = 0;
    for (final m in movimientos) {
      if (m.esIngreso) {
        ingresos += m.monto;
      } else {
        gastos += m.monto;
      }
    }
    final balance = ingresos - gastos;
    double valorInventario = 0;
    for (final p in productos) {
      valorInventario += p.precio * p.cantidad;
    }
    final totalUnidades = productos.fold<int>(0, (s, p) => s + p.cantidad);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen del Negocio'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _InfoCard(
            'Balance total',
            '\$${balance.toStringAsFixed(2)}',
            balance >= 0 ? Colors.green : Colors.red,
            Icons.account_balance_wallet,
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: _InfoCard('Ingresos', '\$${ingresos.toStringAsFixed(2)}',
                  Colors.teal, Icons.arrow_upward),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _InfoCard('Gastos', '\$${gastos.toStringAsFixed(2)}',
                  Colors.orange, Icons.arrow_downward),
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: _InfoCard('Productos', '${productos.length}',
                  Colors.indigo, Icons.category),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _InfoCard('Unidades', '$totalUnidades', Colors.purple,
                  Icons.numbers),
            ),
          ]),
          const SizedBox(height: 12),
          _InfoCard(
            'Valor del inventario',
            '\$${valorInventario.toStringAsFixed(2)}',
            Colors.blueGrey,
            Icons.inventory,
          ),
          const SizedBox(height: 20),
          const Text('Últimos movimientos',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ...movimientos.reversed.take(5).map((m) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: (m.esIngreso ? Colors.green : Colors.red)
                      .withOpacity(0.2),
                  child: Icon(
                    m.esIngreso ? Icons.add : Icons.remove,
                    color: m.esIngreso ? Colors.green : Colors.red,
                  ),
                ),
                title: Text(m.descripcion),
                subtitle: Text(
                    '${m.fecha.day}/${m.fecha.month}/${m.fecha.year}'),
                trailing: Text(
                  '${m.esIngreso ? "+" : "-"}\$${m.monto.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: m.esIngreso ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String titulo, valor;
  final Color color;
  final IconData icon;
  const _InfoCard(this.titulo, this.valor, this.color, this.icon);
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(titulo,
                    style: TextStyle(color: Colors.grey[700], fontSize: 13)),
              ),
            ]),
            const SizedBox(height: 8),
            Text(valor,
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}

// ---------------- PRODUCTOS ----------------
class _ProductosPage extends StatelessWidget {
  final List<Producto> productos;
  final ValueChanged<List<Producto>> onChange;
  const _ProductosPage({required this.productos, required this.onChange});

  void _editar(BuildContext context, int? index) {
    final p = index == null ? null : productos[index];
    final nCtrl = TextEditingController(text: p?.nombre ?? '');
    final cCtrl = TextEditingController(text: p?.cantidad.toString() ?? '');
    final pCtrl = TextEditingController(text: p?.precio.toString() ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(index == null ? 'Nuevo producto' : 'Editar producto'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
                controller: nCtrl,
                decoration: const InputDecoration(labelText: 'Nombre')),
            TextField(
                controller: cCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Cantidad')),
            TextField(
                controller: pCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Precio')),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              final nuevo = Producto(
                nombre: nCtrl.text.trim(),
                cantidad: int.tryParse(cCtrl.text) ?? 0,
                precio: double.tryParse(pCtrl.text) ?? 0,
              );
              if (nuevo.nombre.isEmpty) return;
              final lista = List<Producto>.from(productos);
              if (index == null) {
                lista.add(nuevo);
              } else {
                lista[index] = nuevo;
              }
              onChange(lista);
              Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _editar(context, null),
        child: const Icon(Icons.add),
      ),
      body: productos.isEmpty
          ? const Center(
              child: Text('No hay productos. Añade uno con el botón +'))
          : ListView.builder(
              itemCount: productos.length,
              itemBuilder: (_, i) {
                final p = productos[i];
                return ListTile(
                  leading: CircleAvatar(child: Text('${p.cantidad}')),
                  title: Text(p.nombre),
                  subtitle: Text(
                      'Precio: \$${p.precio.toStringAsFixed(2)}  •  Total: \$${(p.precio * p.cantidad).toStringAsFixed(2)}'),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editar(context, i)),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        final lista = List<Producto>.from(productos)
                          ..removeAt(i);
                        onChange(lista);
                      },
                    ),
                  ]),
                );
              },
            ),
    );
  }
}

// ---------------- GANANCIAS ----------------
class _GananciasPage extends StatelessWidget {
  final List<Movimiento> movimientos;
  final ValueChanged<List<Movimiento>> onChange;
  const _GananciasPage({required this.movimientos, required this.onChange});

  void _nuevo(BuildContext context, bool esIngreso) {
    final dCtrl = TextEditingController();
    final mCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(esIngreso ? 'Nuevo ingreso' : 'Nuevo gasto'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
                controller: dCtrl,
                decoration: const InputDecoration(labelText: 'Descripción')),
            TextField(
                controller: mCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Monto')),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              final monto = double.tryParse(mCtrl.text) ?? 0;
              if (monto <= 0) return;
              final lista = List<Movimiento>.from(movimientos)
                ..add(Movimiento(
                  descripcion: dCtrl.text.trim().isEmpty
                      ? (esIngreso ? 'Ingreso' : 'Gasto')
                      : dCtrl.text.trim(),
                  monto: monto,
                  esIngreso: esIngreso,
                  fecha: DateTime.now(),
                ));
              onChange(lista);
              Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ganancias'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: movimientos.isEmpty
          ? const Center(child: Text('No hay movimientos registrados'))
          : ListView.builder(
              itemCount: movimientos.length,
              itemBuilder: (_, i) {
                final m = movimientos[movimientos.length - 1 - i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: (m.esIngreso ? Colors.green : Colors.red)
                        .withOpacity(0.2),
                    child: Icon(m.esIngreso ? Icons.add : Icons.remove,
                        color: m.esIngreso ? Colors.green : Colors.red),
                  ),
                  title: Text(m.descripcion),
                  subtitle: Text(
                      '${m.fecha.day}/${m.fecha.month}/${m.fecha.year} ${m.fecha.hour}:${m.fecha.minute.toString().padLeft(2, '0')}'),
                  trailing: Text(
                    '${m.esIngreso ? "+" : "-"}\$${m.monto.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: m.esIngreso ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'ing',
            backgroundColor: Colors.green,
            onPressed: () => _nuevo(context, true),
            icon: const Icon(Icons.add),
            label: const Text('Ingreso'),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            heroTag: 'gas',
            backgroundColor: Colors.red,
            onPressed: () => _nuevo(context, false),
            icon: const Icon(Icons.remove),
            label: const Text('Gasto'),
          ),
        ],
      ),
    );
  }
}

// ---------------- CONTADOR ----------------
class _ContadorPage extends StatefulWidget {
  final Map<String, int> denominaciones;
  final ValueChanged<Map<String, int>> onChange;
  const _ContadorPage({required this.denominaciones, required this.onChange});
  @override
  State<_ContadorPage> createState() => _ContadorPageState();
}

class _ContadorPageState extends State<_ContadorPage> {
  static const List<int> billetes = [1000, 500, 200, 100, 50, 20, 10, 5, 3, 1];
  static const List<int> monedas = [5, 2, 1];

  double get _total {
    double t = 0;
    widget.denominaciones.forEach((k, v) {
      t += (int.tryParse(k) ?? 0) * v;
    });
    return t;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contador de dinero'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            color: Colors.teal,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                const Text('Total contado',
                    style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 4),
                Text('\$${_total.toStringAsFixed(2)}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold)),
              ]),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text('BILLETES',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ...billetes.map((d) => _fila(d, esBillete: true)),
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text('MONEDAS',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ...monedas.map((d) => _fila(d, esBillete: false)),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Reiniciar contador'),
            onPressed: () {
              widget.onChange({});
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _fila(int den, {required bool esBillete}) {
    final key = den.toString();
    final cant = widget.denominaciones[key] ?? 0;
    final sub = den * cant;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: esBillete ? Colors.green[100] : Colors.amber[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('\$$den',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: cant > 0
                    ? () {
                        final m = Map<String, int>.from(widget.denominaciones);
                        m[key] = cant - 1;
                        if (m[key] == 0) m.remove(key);
                        widget.onChange(m);
                      }
                    : null,
              ),
              Text('$cant',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () {
                  final m = Map<String, int>.from(widget.denominaciones);
                  m[key] = cant + 1;
                  widget.onChange(m);
                },
              ),
            ]),
          ),
          Text('\$${sub.toString()}',
              style: TextStyle(
                  color: Colors.grey[700], fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }
}
