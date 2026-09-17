import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const NegocioApp());

// ============ MODELOS ============

class Producto {
  String id, nombre, categoria, moneda;
  int cantidad, stockMinimo;
  double costo, precio;
  Producto({required this.id, required this.nombre, this.categoria = 'General',
    this.cantidad = 0, this.costo = 0, required this.precio,
    this.stockMinimo = 0, this.moneda = 'CUP'});
  Map<String, dynamic> toJson() => {'id': id, 'nombre': nombre, 'categoria': categoria,
    'cantidad': cantidad, 'costo': costo, 'precio': precio,
    'stockMinimo': stockMinimo, 'moneda': moneda};
  factory Producto.fromJson(Map<String, dynamic> j) => Producto(
    id: j['id'] ?? '', nombre: j['nombre'] ?? '', categoria: j['categoria'] ?? 'General',
    cantidad: j['cantidad'] ?? 0, costo: (j['costo'] as num?)?.toDouble() ?? 0,
    precio: (j['precio'] as num?)?.toDouble() ?? 0,
    stockMinimo: j['stockMinimo'] ?? 0, moneda: j['moneda'] ?? 'CUP');
  Producto copy() => Producto.fromJson(toJson());
}

class Movimiento {
  String id, descripcion, moneda, categoria, formaPago;
  double monto;
  bool esIngreso, cobrado;
  String? clienteId;
  DateTime fecha;
  Movimiento({required this.id, required this.descripcion, required this.monto,
    this.moneda = 'CUP', this.esIngreso = true, this.categoria = 'Ventas',
    this.formaPago = 'Efectivo', this.clienteId, this.cobrado = true,
    required this.fecha});
  Map<String, dynamic> toJson() => {'id': id, 'descripcion': descripcion, 'monto': monto,
    'moneda': moneda, 'esIngreso': esIngreso, 'categoria': categoria,
    'formaPago': formaPago, 'clienteId': clienteId, 'cobrado': cobrado,
    'fecha': fecha.toIso8601String()};
  factory Movimiento.fromJson(Map<String, dynamic> j) => Movimiento(
    id: j['id'] ?? '', descripcion: j['descripcion'] ?? '',
    monto: (j['monto'] as num?)?.toDouble() ?? 0, moneda: j['moneda'] ?? 'CUP',
    esIngreso: j['esIngreso'] ?? true, categoria: j['categoria'] ?? 'Ventas',
    formaPago: j['formaPago'] ?? 'Efectivo', clienteId: j['clienteId'],
    cobrado: j['cobrado'] ?? true,
    fecha: DateTime.tryParse(j['fecha'] ?? '') ?? DateTime.now());
}

class Cliente {
  String id, nombre, telefono;
  Cliente({required this.id, required this.nombre, this.telefono = ''});
  Map<String, dynamic> toJson() => {'id': id, 'nombre': nombre, 'telefono': telefono};
  factory Cliente.fromJson(Map<String, dynamic> j) =>
      Cliente(id: j['id'] ?? '', nombre: j['nombre'] ?? '', telefono: j['telefono'] ?? '');
}

// ============ ALMACENAMIENTO ============

class Store {
  static const _kProd = 'productos_v2', _kMov = 'movimientos_v2',
      _kCli = 'clientes_v2', _kDen = 'denominaciones_v2',
      _kTasa = 'tasa', _kMon = 'moneda_principal';

  static Future<Map<String, dynamic>> loadAll() async {
    final sp = await SharedPreferences.getInstance();
    return {
      'productos': _pl(sp.getString(_kProd), (j) => Producto.fromJson(j)),
      'movimientos': _pl(sp.getString(_kMov), (j) => Movimiento.fromJson(j)),
      'clientes': _pl(sp.getString(_kCli), (j) => Cliente.fromJson(j)),
      'denominaciones': sp.getString(_kDen) != null
          ? Map<String, int>.from(jsonDecode(sp.getString(_kDen)!)) : <String, int>{},
      'tasa': sp.getDouble(_kTasa) ?? 300.0,
      'monedaPrincipal': sp.getString(_kMon) ?? 'CUP',
    };
  }
  static List<T> _pl<T>(String? s, T Function(Map<String, dynamic>) f) {
    if (s == null || s.isEmpty) return [];
    return (jsonDecode(s) as List).map((e) => f(e as Map<String, dynamic>)).toList();
  }
  static Future<void> save(String key, dynamic v) async {
    final sp = await SharedPreferences.getInstance();
    switch (key) {
      case 'productos': await sp.setString(_kProd, jsonEncode((v as List<Producto>).map((e) => e.toJson()).toList())); break;
      case 'movimientos': await sp.setString(_kMov, jsonEncode((v as List<Movimiento>).map((e) => e.toJson()).toList())); break;
      case 'clientes': await sp.setString(_kCli, jsonEncode((v as List<Cliente>).map((e) => e.toJson()).toList())); break;
      case 'denominaciones': await sp.setString(_kDen, jsonEncode(v)); break;
      case 'tasa': await sp.setDouble(_kTasa, v as double); break;
      case 'monedaPrincipal': await sp.setString(_kMon, v as String); break;
    }
  }
  static Future<String> exportar() async {
    final sp = await SharedPreferences.getInstance();
    return jsonEncode({
      'version': 2, 'exportado': DateTime.now().toIso8601String(),
      'productos': sp.getString(_kProd) != null ? jsonDecode(sp.getString(_kProd)!) : [],
      'movimientos': sp.getString(_kMov) != null ? jsonDecode(sp.getString(_kMov)!) : [],
      'clientes': sp.getString(_kCli) != null ? jsonDecode(sp.getString(_kCli)!) : [],
      'denominaciones': sp.getString(_kDen) != null ? jsonDecode(sp.getString(_kDen)!) : {},
      'tasa': sp.getDouble(_kTasa) ?? 300.0,
      'monedaPrincipal': sp.getString(_kMon) ?? 'CUP',
    });
  }
  static Future<void> importar(Map<String, dynamic> d) async {
    final sp = await SharedPreferences.getInstance();
    if (d['productos'] != null) await sp.setString(_kProd, jsonEncode(d['productos']));
    if (d['movimientos'] != null) await sp.setString(_kMov, jsonEncode(d['movimientos']));
    if (d['clientes'] != null) await sp.setString(_kCli, jsonEncode(d['clientes']));
    if (d['denominaciones'] != null) await sp.setString(_kDen, jsonEncode(d['denominaciones']));
    if (d['tasa'] != null) await sp.setDouble(_kTasa, (d['tasa'] as num).toDouble());
    if (d['monedaPrincipal'] != null) await sp.setString(_kMon, d['monedaPrincipal']);
  }
}

String uid() => DateTime.now().microsecondsSinceEpoch.toString();

// ============ APP ============

class NegocioApp extends StatelessWidget {
  const NegocioApp({super.key});
  @override
  Widget build(BuildContext c) => MaterialApp(
    title: 'Mi Negocio', debugShowCheckedModeBanner: false,
    theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal), useMaterial3: true),
    home: const HomePage());
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _idx = 0;
  List<Producto> _productos = [];
  List<Movimiento> _movimientos = [];
  List<Cliente> _clientes = [];
  Map<String, int> _denominaciones = {};
  double _tasa = 300;
  String _monedaPrincipal = 'CUP';
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final d = await Store.loadAll();
    if (!mounted) return;
    setState(() {
      _productos = List<Producto>.from(d['productos']);
      _movimientos = List<Movimiento>.from(d['movimientos']);
      _clientes = List<Cliente>.from(d['clientes']);
      _denominaciones = Map<String, int>.from(d['denominaciones']);
      _tasa = d['tasa']; _monedaPrincipal = d['monedaPrincipal']; _loading = false;
    });
  }

  void setProductos(List<Producto> l) { setState(() => _productos = l); Store.save('productos', l); }
  void setMovimientos(List<Movimiento> l) { setState(() => _movimientos = l); Store.save('movimientos', l); }
  void setClientes(List<Cliente> l) { setState(() => _clientes = l); Store.save('clientes', l); }
  void setDenominaciones(Map<String, int> m) { setState(() => _denominaciones = m); Store.save('denominaciones', m); }
  void setTasa(double t) { setState(() => _tasa = t); Store.save('tasa', t); }
  void setMonedaPrincipal(String m) { setState(() => _monedaPrincipal = m); Store.save('monedaPrincipal', m); }

  double conv(double m, String de, String a) {
    if (de == a) return m;
    if (a == 'CUP') return de == 'USD' ? m * _tasa : m;
    return de == 'CUP' ? m / _tasa : m;
  }

  @override
  Widget build(BuildContext c) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final pages = <Widget>[
      ResumenPage(productos: _productos, movimientos: _movimientos,
        clientes: _clientes, monedaPrincipal: _monedaPrincipal, conv: conv),
      VenderPage(productos: _productos, clientes: _clientes,
        monedaPrincipal: _monedaPrincipal, conv: conv,
        onVenta: (movs, prods) { setMovimientos([..._movimientos, ...movs]); setProductos(prods); }),
      ProductosPage(productos: _productos, onChange: setProductos),
      ClientesPage(clientes: _clientes, movimientos: _movimientos,
        monedaPrincipal: _monedaPrincipal, conv: conv,
        onClientes: setClientes, onMovimientos: setMovimientos),
      MasPage(movimientos: _movimientos, denominaciones: _denominaciones,
        tasa: _tasa, monedaPrincipal: _monedaPrincipal, conv: conv,
        onDenominaciones: setDenominaciones, onMovimientos: setMovimientos,
        onTasa: setTasa, onMonedaPrincipal: setMonedaPrincipal, onReload: _load),
    ];
    return Scaffold(
      body: pages[_idx],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        onDestinationSelected: (i) => setState(() => _idx = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Resumen'),
          NavigationDestination(icon: Icon(Icons.point_of_sale), label: 'Vender'),
          NavigationDestination(icon: Icon(Icons.inventory_2), label: 'Productos'),
          NavigationDestination(icon: Icon(Icons.people), label: 'Clientes'),
          NavigationDestination(icon: Icon(Icons.more_horiz), label: 'Más'),
        ]));
  }
}

String money(double v, String mon) => mon == 'USD' ? 'US\$${v.toStringAsFixed(2)}' : '\$${v.toStringAsFixed(2)}';

// ============ RESUMEN ============

class ResumenPage extends StatefulWidget {
  final List<Producto> productos;
  final List<Movimiento> movimientos;
  final List<Cliente> clientes;
  final String monedaPrincipal;
  final double Function(double, String, String) conv;
  const ResumenPage({super.key, required this.productos, required this.movimientos,
    required this.clientes, required this.monedaPrincipal, required this.conv});
  @override
  State<ResumenPage> createState() => _ResumenPageState();
}

class _ResumenPageState extends State<ResumenPage> {
  int _rango = 2;

  bool _enRango(DateTime f) {
    final n = DateTime.now();
    if (_rango == 0) return f.year == n.year && f.month == n.month && f.day == n.day;
    if (_rango == 1) return n.difference(f).inDays < 7;
    if (_rango == 2) return f.year == n.year && f.month == n.month;
    return true;
  }

  @override
  Widget build(BuildContext c) {
    final movs = widget.movimientos.where((m) => _enRango(m.fecha) && m.cobrado).toList();
    double ingCUP = 0, gasCUP = 0;
    for (final m in movs) {
      final v = widget.conv(m.monto, m.moneda, 'CUP');
      if (m.esIngreso) { ingCUP += v; } else { gasCUP += v; }
    }
    double invCUP = 0;
    for (final p in widget.productos) invCUP += widget.conv(p.precio * p.cantidad, p.moneda, 'CUP');
    final bajos = widget.productos.where((p) => p.stockMinimo > 0 && p.cantidad <= p.stockMinimo).toList();
    double fiadoCUP = 0;
    for (final m in widget.movimientos) if (!m.cobrado && m.clienteId != null) fiadoCUP += widget.conv(m.monto, m.moneda, 'CUP');

    final balCUP = ingCUP - gasCUP;
    final balUSD = widget.conv(balCUP, 'CUP', 'USD');
    final principal = widget.monedaPrincipal == 'CUP' ? balCUP : balUSD;

    return Scaffold(
      appBar: AppBar(title: const Text('Resumen'), backgroundColor: Colors.teal, foregroundColor: Colors.white),
      body: ListView(padding: const EdgeInsets.all(12), children: [
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 0, label: Text('Hoy')),
            ButtonSegment(value: 1, label: Text('7d')),
            ButtonSegment(value: 2, label: Text('Mes')),
            ButtonSegment(value: 3, label: Text('Todo')),
          ],
          selected: {_rango},
          onSelectionChanged: (s) => setState(() => _rango = s.first)),
        const SizedBox(height: 12),
        Card(color: principal >= 0 ? Colors.green[600] : Colors.red[600],
          child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
            Text('Balance (${widget.monedaPrincipal})', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 4),
            Text(money(principal, widget.monedaPrincipal),
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          ]))),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _mini('Ingresos', money(widget.conv(ingCUP, 'CUP', widget.monedaPrincipal), widget.monedaPrincipal), Colors.teal, Icons.arrow_upward)),
          const SizedBox(width: 8),
          Expanded(child: _mini('Gastos', money(widget.conv(gasCUP, 'CUP', widget.monedaPrincipal), widget.monedaPrincipal), Colors.orange, Icons.arrow_downward)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _mini('En CUP', money(balCUP, 'CUP'), Colors.blueGrey, Icons.attach_money)),
          const SizedBox(width: 8),
          Expanded(child: _mini('En USD', money(balUSD, 'USD'), Colors.indigo, Icons.attach_money)),
        ]),
        const SizedBox(height: 8),
        _mini('Valor inventario', money(widget.conv(invCUP, 'CUP', widget.monedaPrincipal), widget.monedaPrincipal), Colors.blue, Icons.inventory),
        if (bajos.isNotEmpty) ...[
          const SizedBox(height: 12),
          Card(color: Colors.red[50], child: Padding(padding: const EdgeInsets.all(12), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.warning, color: Colors.red),
                const SizedBox(width: 8),
                Text('Stock bajo (${bajos.length})', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
              ]),
              const SizedBox(height: 6),
              ...bajos.take(6).map((p) => Text('• ${p.nombre} — quedan ${p.cantidad}')),
            ]))),
        ],
        if (fiadoCUP > 0) ...[
          const SizedBox(height: 8),
          _mini('Por cobrar (fiado)', money(widget.conv(fiadoCUP, 'CUP', widget.monedaPrincipal), widget.monedaPrincipal), Colors.deepOrange, Icons.receipt_long),
        ],
        const SizedBox(height: 16),
        const Text('Últimos movimientos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        if (widget.movimientos.isEmpty) const Padding(padding: EdgeInsets.all(20), child: Center(child: Text('Sin movimientos'))),
        ...widget.movimientos.reversed.take(10).map((m) => ListTile(dense: true,
          leading: CircleAvatar(radius: 16,
            backgroundColor: (m.esIngreso ? Colors.green : Colors.red).withOpacity(0.15),
            child: Icon(m.esIngreso ? Icons.add : Icons.remove, size: 16, color: m.esIngreso ? Colors.green : Colors.red)),
          title: Text(m.descripcion),
          subtitle: Text('${m.fecha.day}/${m.fecha.month} • ${m.formaPago}${m.cobrado ? '' : ' · pendiente'}'),
          trailing: Text('${m.esIngreso ? "+" : "-"}${money(m.monto, m.moneda)}',
            style: TextStyle(color: m.esIngreso ? Colors.green : Colors.red, fontWeight: FontWeight.bold)))),
      ]));
  }

  Widget _mini(String t, String v, Color col, IconData ic) => Card(child: Padding(
    padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(ic, color: col, size: 18), const SizedBox(width: 6),
        Expanded(child: Text(t, style: TextStyle(color: Colors.grey[700], fontSize: 12)))]),
      const SizedBox(height: 6),
      Text(v, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: col)),
    ])));
}

// ============ VENDER (POS) ============

class VenderPage extends StatefulWidget {
  final List<Producto> productos;
  final List<Cliente> clientes;
  final String monedaPrincipal;
  final double Function(double, String, String) conv;
  final void Function(List<Movimiento>, List<Producto>) onVenta;
  const VenderPage({super.key, required this.productos, required this.clientes,
    required this.monedaPrincipal, required this.conv, required this.onVenta});
  @override
  State<VenderPage> createState() => _VenderPageState();
}

class _VenderPageState extends State<VenderPage> {
  final Map<String, int> _carrito = {};
  String _q = '';

  double _total(String mon) {
    double t = 0;
    for (final e in _carrito.entries) {
      final p = widget.productos.firstWhere((x) => x.id == e.key);
      t += widget.conv(p.precio * e.value, p.moneda, mon);
    }
    return t;
  }

  void _add(Producto p) {
    final a = _carrito[p.id] ?? 0;
    if (a >= p.cantidad) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sin stock suficiente')));
      return;
    }
    setState(() => _carrito[p.id] = a + 1);
  }
  void _dec(Producto p) {
    final a = _carrito[p.id] ?? 0;
    if (a <= 1) { setState(() => _carrito.remove(p.id)); }
    else { setState(() => _carrito[p.id] = a - 1); }
  }

  Future<void> _cobrar() async {
    if (_carrito.isEmpty) return;
    String forma = 'Efectivo';
    String mon = widget.monedaPrincipal;
    Cliente? cli;
    final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSt) => AlertDialog(
        title: const Text('Cobrar'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Total: ${money(_total(mon), mon)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            const Text('Forma de pago'),
            DropdownButton<String>(value: forma, isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'Efectivo', child: Text('Efectivo')),
                DropdownMenuItem(value: 'Transferencia', child: Text('Transferencia')),
                DropdownMenuItem(value: 'Fiado', child: Text('Fiado')),
              ], onChanged: (v) => setSt(() => forma = v ?? 'Efectivo')),
            const SizedBox(height: 10),
            const Text('Moneda de cobro'),
            DropdownButton<String>(value: mon, isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'CUP', child: Text('CUP')),
                DropdownMenuItem(value: 'USD', child: Text('USD')),
              ], onChanged: (v) => setSt(() => mon = v ?? 'CUP')),
            if (forma == 'Fiado') ...[
              const SizedBox(height: 10),
              const Text('Cliente'),
              if (widget.clientes.isEmpty)
                const Text('Añade un cliente primero en la pestaña Clientes.', style: TextStyle(color: Colors.red, fontSize: 12))
              else
                DropdownButton<Cliente>(value: cli, isExpanded: true, hint: const Text('Selecciona'),
                  items: widget.clientes.map((c) => DropdownMenuItem(value: c, child: Text(c.nombre))).toList(),
                  onChanged: (v) => setSt(() => cli = v)),
            ],
          ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () {
            if (forma == 'Fiado' && cli == null) return;
            Navigator.pop(ctx, true);
          }, child: const Text('Confirmar')),
        ])));
    if (ok != true) return;

    final total = _total(mon);
    final desc = _carrito.length == 1
        ? 'Venta: ${widget.productos.firstWhere((p) => p.id == _carrito.keys.first).nombre}'
        : 'Venta (${_carrito.length} productos)';
    final mov = Movimiento(id: uid(), descripcion: desc, monto: total, moneda: mon,
      esIngreso: true, categoria: 'Ventas', formaPago: forma,
      clienteId: cli?.id, cobrado: forma != 'Fiado', fecha: DateTime.now());

    final nuevos = List<Producto>.from(widget.productos);
    for (final e in _carrito.entries) {
      final i = nuevos.indexWhere((p) => p.id == e.key);
      if (i >= 0) { nuevos[i] = nuevos[i].copy()..cantidad -= e.value; if (nuevos[i].cantidad < 0) nuevos[i].cantidad = 0; }
    }
    widget.onVenta([mov], nuevos);
    setState(() => _carrito.clear());
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Venta: ${money(total, mon)}')));
  }

  @override
  Widget build(BuildContext c) {
    final fs = widget.productos.where((p) => _q.isEmpty ||
      p.nombre.toLowerCase().contains(_q.toLowerCase()) ||
      p.categoria.toLowerCase().contains(_q.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Vender'), backgroundColor: Colors.teal, foregroundColor: Colors.white),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(12), child: TextField(
          decoration: const InputDecoration(prefixIcon: Icon(Icons.search),
            hintText: 'Buscar producto...', border: OutlineInputBorder()),
          onChanged: (v) => setState(() => _q = v))),
        Expanded(child: fs.isEmpty
          ? const Center(child: Padding(padding: EdgeInsets.all(24),
              child: Text('No hay productos. Añádelos en la pestaña Productos.', textAlign: TextAlign.center)))
          : ListView.builder(itemCount: fs.length, itemBuilder: (_, i) {
              final p = fs[i];
              final n = _carrito[p.id] ?? 0;
              final sin = p.cantidad <= 0;
              return ListTile(enabled: !sin,
                leading: CircleAvatar(backgroundColor: sin ? Colors.grey[300] : Colors.teal[100],
                  child: Text('${p.cantidad}', style: TextStyle(color: sin ? Colors.grey : Colors.teal[900], fontWeight: FontWeight.bold))),
                title: Text(p.nombre),
                subtitle: Text('${money(p.precio, p.moneda)} • ${p.categoria}'),
                trailing: n > 0
                  ? Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => _dec(p)),
                      Text('$n', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => _add(p)),
                    ])
                  : IconButton(icon: const Icon(Icons.add_shopping_cart), onPressed: sin ? null : () => _add(p)));
            })),
        if (_carrito.isNotEmpty)
          Material(elevation: 10, color: Colors.teal[50], child: Padding(padding: const EdgeInsets.all(12),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('${_carrito.values.fold<int>(0, (a, b) => a + b)} items', style: const TextStyle(fontWeight: FontWeight.bold)),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('CUP: ${money(_total('CUP'), 'CUP')}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('USD: ${money(_total('USD'), 'USD')}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                ]),
              ]),
              const SizedBox(height: 10),
              SizedBox(width: double.infinity, child: FilledButton.icon(
                onPressed: _cobrar, icon: const Icon(Icons.point_of_sale), label: const Text('Cobrar'))),
            ]))),
      ]));
  }
}

// ============ PRODUCTOS ============

class ProductosPage extends StatefulWidget {
  final List<Producto> productos;
  final ValueChanged<List<Producto>> onChange;
  const ProductosPage({super.key, required this.productos, required this.onChange});
  @override
  State<ProductosPage> createState() => _ProductosPageState();
}

class _ProductosPageState extends State<ProductosPage> {
  String _q = '';

  Future<void> _editar(Producto? p) async {
    final nC = TextEditingController(text: p?.nombre ?? '');
    final catC = TextEditingController(text: p?.categoria ?? 'General');
    final canC = TextEditingController(text: p?.cantidad.toString() ?? '0');
    final cosC = TextEditingController(text: p?.costo.toString() ?? '0');
    final preC = TextEditingController(text: p?.precio.toString() ?? '');
    final minC = TextEditingController(text: p?.stockMinimo.toString() ?? '0');
    String mon = p?.moneda ?? 'CUP';

    final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSt) => AlertDialog(
        title: Text(p == null ? 'Nuevo producto' : 'Editar'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nC, decoration: const InputDecoration(labelText: 'Nombre *')),
          TextField(controller: catC, decoration: const InputDecoration(labelText: 'Categoría')),
          Row(children: [
            Expanded(child: TextField(controller: preC, keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Precio venta *'))),
            const SizedBox(width: 8),
            Expanded(child: DropdownButtonFormField<String>(value: mon,
              decoration: const InputDecoration(labelText: 'Moneda'),
              items: const [DropdownMenuItem(value: 'CUP', child: Text('CUP')),
                DropdownMenuItem(value: 'USD', child: Text('USD'))],
              onChanged: (v) => setSt(() => mon = v ?? 'CUP'))),
          ]),
          TextField(controller: cosC, keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Costo (para calcular margen)')),
          Row(children: [
            Expanded(child: TextField(controller: canC, keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Stock'))),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: minC, keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Stock mínimo'))),
          ]),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Guardar')),
        ])));
    if (ok != true) return;
    if (nC.text.trim().isEmpty || preC.text.trim().isEmpty) return;

    final nuevo = Producto(id: p?.id ?? uid(), nombre: nC.text.trim(),
      categoria: catC.text.trim().isEmpty ? 'General' : catC.text.trim(),
      cantidad: int.tryParse(canC.text) ?? 0,
      costo: double.tryParse(cosC.text) ?? 0,
      precio: double.tryParse(preC.text) ?? 0,
      stockMinimo: int.tryParse(minC.text) ?? 0, moneda: mon);

    final l = List<Producto>.from(widget.productos);
    if (p == null) { l.add(nuevo); } else { l[l.indexWhere((x) => x.id == p.id)] = nuevo; }
    widget.onChange(l);
  }

  @override
  Widget build(BuildContext c) {
    final fs = widget.productos.where((p) => _q.isEmpty ||
      p.nombre.toLowerCase().contains(_q.toLowerCase()) ||
      p.categoria.toLowerCase().contains(_q.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Productos'), backgroundColor: Colors.teal, foregroundColor: Colors.white),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _editar(null),
        icon: const Icon(Icons.add), label: const Text('Nuevo')),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(12), child: TextField(
          decoration: const InputDecoration(prefixIcon: Icon(Icons.search),
            hintText: 'Buscar...', border: OutlineInputBorder()),
          onChanged: (v) => setState(() => _q = v))),
        Expanded(child: fs.isEmpty
          ? const Center(child: Text('Sin productos'))
          : ListView.builder(itemCount: fs.length, itemBuilder: (_, i) {
              final p = fs[i];
              final bajo = p.stockMinimo > 0 && p.cantidad <= p.stockMinimo;
              final margen = p.costo > 0 ? ((p.precio - p.costo) / p.costo * 100) : null;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: bajo ? Colors.red[100] : Colors.teal[100],
                  child: Text('${p.cantidad}', style: TextStyle(color: bajo ? Colors.red[900] : Colors.teal[900], fontWeight: FontWeight.bold))),
                title: Text(p.nombre + (bajo ? '  ⚠️' : '')),
                subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${money(p.precio, p.moneda)} • ${p.categoria}'),
                  if (margen != null) Text('Margen: ${margen.toStringAsFixed(0)}%',
                    style: TextStyle(fontSize: 11, color: margen >= 20 ? Colors.green : Colors.orange)),
                ]),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') _editar(p);
                    if (v == 'del') {
                      widget.onChange(List<Producto>.from(widget.productos)..removeWhere((x) => x.id == p.id));
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Editar')),
                    PopupMenuItem(value: 'del', child: Text('Eliminar')),
                  ]));
            })),
      ]));
  }
}

// ============ CLIENTES ============

class ClientesPage extends StatelessWidget {
  final List<Cliente> clientes;
  final List<Movimiento> movimientos;
  final String monedaPrincipal;
  final double Function(double, String, String) conv;
  final ValueChanged<List<Cliente>> onClientes;
  final ValueChanged<List<Movimiento>> onMovimientos;
  const ClientesPage({super.key, required this.clientes, required this.movimientos,
    required this.monedaPrincipal, required this.conv,
    required this.onClientes, required this.onMovimientos});

  double _deuda(Cliente c) {
    double t = 0;
    for (final m in movimientos) if (!m.cobrado && m.clienteId == c.id) {
      t += conv(m.monto, m.moneda, monedaPrincipal);
    }
    return t;
  }

  Future<void> _nuevo(BuildContext ctx) async {
    final nC = TextEditingController();
    final tC = TextEditingController();
    final ok = await showDialog<bool>(context: ctx, builder: (c) => AlertDialog(
      title: const Text('Nuevo cliente'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nC, decoration: const InputDecoration(labelText: 'Nombre *')),
        TextField(controller: tC, decoration: const InputDecoration(labelText: 'Teléfono (opcional)')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Guardar')),
      ]));
    if (ok != true || nC.text.trim().isEmpty) return;
    onClientes([...clientes, Cliente(id: uid(), nombre: nC.text.trim(), telefono: tC.text.trim())]);
  }

  Future<void> _verCliente(BuildContext ctx, Cliente c) async {
    final pend = movimientos.where((m) => !m.cobrado && m.clienteId == c.id).toList();
    final ok = await showDialog<bool>(context: ctx, builder: (dctx) => AlertDialog(
      title: Text(c.nombre),
      content: SizedBox(width: double.maxFinite, child: pend.isEmpty
        ? const Text('Sin deudas pendientes.')
        : ListView(shrinkWrap: true, children: pend.map((m) => ListTile(
            dense: true,
            title: Text(m.descripcion),
            subtitle: Text('${m.fecha.day}/${m.fecha.month}/${m.fecha.year} • ${m.formaPago}'),
            trailing: Text(money(m.monto, m.moneda), style: const TextStyle(fontWeight: FontWeight.bold)),
          )).toList())),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dctx, false), child: const Text('Cerrar')),
        if (pend.isNotEmpty)
          FilledButton.icon(icon: const Icon(Icons.check), label: const Text('Cobrar todo'),
            onPressed: () => Navigator.pop(dctx, true)),
      ]));
    if (ok == true) {
      final nuevosMov = movimientos.map((m) => m.clienteId == c.id && !m.cobrado
        ? Movimiento.fromJson({...m.toJson(), 'cobrado': true}) : m).toList();
      for (final m in pend) {
        nuevosMov.add(Movimiento(id: uid(), descripcion: 'Cobro fiado: ${c.nombre}',
          monto: m.monto, moneda: m.moneda, esIngreso: true,
          categoria: 'Cobro fiado', formaPago: 'Efectivo', fecha: DateTime.now()));
      }
      onMovimientos(nuevosMov);
    }
  }

  @override
  Widget build(BuildContext c) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clientes'), backgroundColor: Colors.teal, foregroundColor: Colors.white),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _nuevo(c),
        icon: const Icon(Icons.person_add), label: const Text('Nuevo')),
      body: clientes.isEmpty
        ? const Center(child: Padding(padding: EdgeInsets.all(24),
            child: Text('Sin clientes.\nAñade uno con el botón + para llevar el fiado.',
              textAlign: TextAlign.center)))
        : ListView.builder(itemCount: clientes.length, itemBuilder: (_, i) {
            final cli = clientes[i];
            final d = _deuda(cli);
            return ListTile(
              leading: CircleAvatar(child: Text(cli.nombre.isNotEmpty ? cli.nombre[0].toUpperCase() : '?')),
              title: Text(cli.nombre),
              subtitle: Text(cli.telefono.isEmpty ? 'Sin teléfono' : cli.telefono),
              trailing: d > 0
                ? Text(money(d, monedaPrincipal), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
                : const Text('Al día', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              onTap: () => _verCliente(c, cli),
              onLongPress: () async {
                final ok = await showDialog<bool>(context: c, builder: (x) => AlertDialog(
                  title: const Text('Eliminar cliente'), content: Text('¿Eliminar a ${cli.nombre}?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(x, false), child: const Text('No')),
                    FilledButton(onPressed: () => Navigator.pop(x, true), child: const Text('Sí')),
                  ]));
                if (ok == true) onClientes(List<Cliente>.from(clientes)..removeWhere((x) => x.id == cli.id));
              });
          }));
  }
}

// ============ MÁS ============

class MasPage extends StatelessWidget {
  final List<Movimiento> movimientos;
  final Map<String, int> denominaciones;
  final double tasa;
  final String monedaPrincipal;
  final double Function(double, String, String) conv;
  final ValueChanged<Map<String, int>> onDenominaciones;
  final ValueChanged<List<Movimiento>> onMovimientos;
  final ValueChanged<double> onTasa;
  final ValueChanged<String> onMonedaPrincipal;
  final VoidCallback onReload;
  const MasPage({super.key, required this.movimientos, required this.denominaciones,
    required this.tasa, required this.monedaPrincipal, required this.conv,
    required this.onDenominaciones, required this.onMovimientos,
    required this.onTasa, required this.onMonedaPrincipal, required this.onReload});

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text('Más'), backgroundColor: Colors.teal, foregroundColor: Colors.white),
    body: ListView(children: [
      ListTile(leading: const Icon(Icons.swap_vert), title: const Text('Movimientos'),
        subtitle: Text('${movimientos.length} registros'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(c, MaterialPageRoute(builder: (_) =>
          MovimientosPage(movimientos: movimientos, onMovimientos: onMovimientos, monedaPrincipal: monedaPrincipal)))),
      ListTile(leading: const Icon(Icons.payments), title: const Text('Contador de dinero'),
        subtitle: const Text('Billetes y monedas CUP / USD'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(c, MaterialPageRoute(builder: (_) =>
          ContadorPage(denominaciones: denominaciones, onDenominaciones: onDenominaciones)))),
      ListTile(leading: const Icon(Icons.settings), title: const Text('Ajustes'),
        subtitle: Text('Tasa: $tasa CUP / USD · Principal: $monedaPrincipal'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(c, MaterialPageRoute(builder: (_) =>
          AjustesPage(tasa: tasa, monedaPrincipal: monedaPrincipal,
            onTasa: onTasa, onMonedaPrincipal: onMonedaPrincipal, onReload: onReload)))),
      const Divider(),
      const Padding(padding: EdgeInsets.all(16), child: Text(
        'Consejo: haz un backup cada semana desde Ajustes y guárdalo en tu correo o WhatsApp.',
        style: TextStyle(color: Colors.grey))),
    ]));
}

// ============ MOVIMIENTOS ============

class MovimientosPage extends StatefulWidget {
  final List<Movimiento> movimientos;
  final ValueChanged<List<Movimiento>> onMovimientos;
  final String monedaPrincipal;
  const MovimientosPage({super.key, required this.movimientos,
    required this.onMovimientos, required this.monedaPrincipal});
  @override
  State<MovimientosPage> createState() => _MovimientosPageState();
}

class _MovimientosPageState extends State<MovimientosPage> {
  String _q = '';
  String? _filtroCat;

  Future<void> _nuevo(bool ingreso) async {
    final dC = TextEditingController();
    final mC = TextEditingController();
    String mon = widget.monedaPrincipal;
    String cat = ingreso ? 'Ventas' : 'Compra mercancía';
    final catsIng = ['Ventas', 'Cobro fiado', 'Otros ingresos'];
    final catsGas = ['Compra mercancía', 'Alquiler', 'Electricidad', 'Transporte', 'Salarios', 'Otros gastos'];
    final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSt) => AlertDialog(
        title: Text(ingreso ? 'Nuevo ingreso' : 'Nuevo gasto'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: dC, decoration: const InputDecoration(labelText: 'Descripción')),
          TextField(controller: mC, keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Monto')),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(value: mon, decoration: const InputDecoration(labelText: 'Moneda'),
            items: const [DropdownMenuItem(value: 'CUP', child: Text('CUP')),
              DropdownMenuItem(value: 'USD', child: Text('USD'))],
            onChanged: (v) => setSt(() => mon = v ?? 'CUP')),
          DropdownButtonFormField<String>(value: cat, decoration: const InputDecoration(labelText: 'Categoría'),
            items: (ingreso ? catsIng : catsGas).map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setSt(() => cat = v ?? cat)),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Guardar')),
        ])));
    if (ok != true) return;
    final monto = double.tryParse(mC.text) ?? 0;
    if (monto <= 0) return;
    final m = Movimiento(id: uid(), descripcion: dC.text.trim().isEmpty ? cat : dC.text.trim(),
      monto: monto, moneda: mon, esIngreso: ingreso, categoria: cat,
      formaPago: 'Efectivo', fecha: DateTime.now());
    widget.onMovimientos([...widget.movimientos, m]);
  }

  @override
  Widget build(BuildContext c) {
    final cats = widget.movimientos.map((m) => m.categoria).toSet().toList()..sort();
    final fs = widget.movimientos.where((m) =>
      (_q.isEmpty || m.descripcion.toLowerCase().contains(_q.toLowerCase())) &&
      (_filtroCat == null || m.categoria == _filtroCat)).toList().reversed.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Movimientos'), backgroundColor: Colors.teal, foregroundColor: Colors.white),
      floatingActionButton: Column(mainAxisSize: MainAxisSize.min, children: [
        FloatingActionButton.extended(heroTag: 'in', backgroundColor: Colors.green,
          onPressed: () => _nuevo(true), icon: const Icon(Icons.add), label: const Text('Ingreso')),
        const SizedBox(height: 8),
        FloatingActionButton.extended(heroTag: 'ga', backgroundColor: Colors.red,
          onPressed: () => _nuevo(false), icon: const Icon(Icons.remove), label: const Text('Gasto')),
      ]),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(12), child: TextField(
          decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Buscar...', border: OutlineInputBorder()),
          onChanged: (v) => setState(() => _q = v))),
        if (cats.isNotEmpty) SizedBox(height: 40, child: ListView(scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12), children: [
            FilterChip(label: const Text('Todas'), selected: _filtroCat == null,
              onSelected: (_) => setState(() => _filtroCat = null)),
            const SizedBox(width: 6),
            ...cats.map((cat) => Padding(padding: const EdgeInsets.only(right: 6),
              child: FilterChip(label: Text(cat), selected: _filtroCat == cat,
                onSelected: (_) => setState(() => _filtroCat = _filtroCat == cat ? null : cat)))),
          ])),
        Expanded(child: fs.isEmpty
          ? const Center(child: Text('Sin movimientos'))
          : ListView.builder(itemCount: fs.length, itemBuilder: (_, i) {
              final m = fs[i];
              return Dismissible(key: ValueKey(m.id),
                background: Container(color: Colors.red, alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: Colors.white)),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) async => await showDialog<bool>(context: c, builder: (x) => AlertDialog(
                  title: const Text('Eliminar'), content: Text('¿Eliminar "${m.descripcion}"?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(x, false), child: const Text('No')),
                    FilledButton(onPressed: () => Navigator.pop(x, true), child: const Text('Sí')),
                  ])) ?? false,
                onDismissed: (_) => widget.onMovimientos(List<Movimiento>.from(widget.movimientos)..removeWhere((x) => x.id == m.id)),
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: (m.esIngreso ? Colors.green : Colors.red).withOpacity(0.15),
                    child: Icon(m.esIngreso ? Icons.add : Icons.remove, color: m.esIngreso ? Colors.green : Colors.red)),
                  title: Text(m.descripcion),
                  subtitle: Text('${m.fecha.day}/${m.fecha.month}/${m.fecha.year} ${m.fecha.hour}:${m.fecha.minute.toString().padLeft(2, '0')}\n${m.categoria} • ${m.formaPago}${m.cobrado ? '' : ' (pendiente)'}'),
                  isThreeLine: true,
                  trailing: Text('${m.esIngreso ? "+" : "-"}${money(m.monto, m.moneda)}',
                    style: TextStyle(color: m.esIngreso ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 15))));
            })),
      ]));
  }
}

// ============ CONTADOR ============

class ContadorPage extends StatefulWidget {
  final Map<String, int> denominaciones;
  final ValueChanged<Map<String, int>> onDenominaciones;
  const ContadorPage({super.key, required this.denominaciones, required this.onDenominaciones});
  @override
  State<ContadorPage> createState() => _ContadorPageState();
}

class _ContadorPageState extends State<ContadorPage> {
  static const billetesCUP = [1000, 500, 200, 100, 50, 20, 10, 5, 3, 1];
  static const monedasCUP = [5, 2, 1];
  static const billetesUSD = [100, 50, 20, 10, 5, 2, 1];

  double _total(String mon) {
    double t = 0;
    widget.denominaciones.forEach((k, v) {
      final partes = k.split('_');
      if (partes.length == 2 && partes[1] == mon) t += (int.tryParse(partes[0]) ?? 0) * v;
    });
    return t;
  }

  Widget _fila(int den, String mon, bool esBillete) {
    final key = '${den}_$mon';
    final cant = widget.denominaciones[key] ?? 0;
    return Card(margin: const EdgeInsets.symmetric(vertical: 3),
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: esBillete ? Colors.green[100] : Colors.amber[100],
              borderRadius: BorderRadius.circular(8)),
            child: Text(money(den.toDouble(), mon), style: const TextStyle(fontWeight: FontWeight.bold))),
          const SizedBox(width: 8),
          Expanded(child: Row(children: [
            IconButton(icon: const Icon(Icons.remove_circle_outline),
              onPressed: cant > 0 ? () {
                final m = Map<String, int>.from(widget.denominaciones);
                m[key] = cant - 1;
                if (m[key] == 0) m.remove(key);
                widget.onDenominaciones(m);
              } : null),
            Text('$cant', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () {
              final m = Map<String, int>.from(widget.denominaciones);
              m[key] = cant + 1;
              widget.onDenominaciones(m);
            }),
          ])),
          Text(money((den * cant).toDouble(), mon), style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold)),
        ])));
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text('Contador de dinero'), backgroundColor: Colors.teal, foregroundColor: Colors.white),
    body: ListView(padding: const EdgeInsets.all(12), children: [
      Card(color: Colors.teal, child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
        const Text('Total contado', style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 6),
        Text(money(_total('CUP'), 'CUP'), style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(money(_total('USD'), 'USD'), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
      ]))),
      const Padding(padding: EdgeInsets.all(8), child: Text('BILLETES CUP', style: TextStyle(fontWeight: FontWeight.bold))),
      ...billetesCUP.map((d) => _fila(d, 'CUP', true)),
      const Padding(padding: EdgeInsets.all(8), child: Text('MONEDAS CUP', style: TextStyle(fontWeight: FontWeight.bold))),
      ...monedasCUP.map((d) => _fila(d, 'CUP', false)),
      const Padding(padding: EdgeInsets.all(8), child: Text('BILLETES USD', style: TextStyle(fontWeight: FontWeight.bold))),
      ...billetesUSD.map((d) => _fila(d, 'USD', true)),
      const SizedBox(height: 12),
      OutlinedButton.icon(icon: const Icon(Icons.refresh), label: const Text('Reiniciar contador'),
        onPressed: () async {
          final ok = await showDialog<bool>(context: c, builder: (x) => AlertDialog(
            title: const Text('Reiniciar'), content: const Text('¿Borrar todo el conteo?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(x, false), child: const Text('No')),
              FilledButton(onPressed: () => Navigator.pop(x, true), child: const Text('Sí')),
            ]));
          if (ok == true) widget.onDenominaciones({});
        }),
      const SizedBox(height: 40),
    ]));
}

// ============ AJUSTES ============

class AjustesPage extends StatefulWidget {
  final double tasa;
  final String monedaPrincipal;
  final ValueChanged<double> onTasa;
  final ValueChanged<String> onMonedaPrincipal;
  final VoidCallback onReload;
  const AjustesPage({super.key, required this.tasa, required this.monedaPrincipal,
    required this.onTasa, required this.onMonedaPrincipal, required this.onReload});
  @override
  State<AjustesPage> createState() => _AjustesPageState();
}

class _AjustesPageState extends State<AjustesPage> {
  late TextEditingController _tasaC;

  @override
  void initState() { super.initState(); _tasaC = TextEditingController(text: widget.tasa.toString()); }

  Future<void> _exportar() async {
    final json = await Store.exportar();
    await Clipboard.setData(ClipboardData(text: json));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Backup copiado al portapapeles. Pégalo en un chat o nota para guardarlo.')));
  }

  Future<void> _importar() async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      title: const Text('Importar backup'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Pega aquí el JSON del backup. Se reemplazarán los datos actuales.'),
        const SizedBox(height: 8),
        TextField(controller: ctrl, maxLines: 6, decoration: const InputDecoration(border: OutlineInputBorder())),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Importar')),
      ]));
    if (ok != true) return;
    try {
      final data = jsonDecode(ctrl.text.trim()) as Map<String, dynamic>;
      await Store.importar(data);
      widget.onReload();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Datos importados correctamente')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text('Ajustes'), backgroundColor: Colors.teal, foregroundColor: Colors.white),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      const Text('Moneda', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      const SizedBox(height: 8),
      const Text('Moneda principal (para mostrar totales):'),
      const SizedBox(height: 6),
      SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'CUP', label: Text('CUP')),
          ButtonSegment(value: 'USD', label: Text('USD')),
        ],
        selected: {widget.monedaPrincipal},
        onSelectionChanged: (s) => widget.onMonedaPrincipal(s.first)),
      const SizedBox(height: 20),
      const Text('Tasa de cambio', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      const SizedBox(height: 4),
      const Text('Cuántos CUP equivalen a 1 USD (ajústala según el mercado):',
        style: TextStyle(color: Colors.grey, fontSize: 12)),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: TextField(controller: _tasaC, keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'CUP por 1 USD', border: OutlineInputBorder()))),
        const SizedBox(width: 8),
        FilledButton(onPressed: () {
          final t = double.tryParse(_tasaC.text) ?? 0;
          if (t > 0) { widget.onTasa(t); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tasa actualizada'))); }
        }, child: const Text('Guardar')),
      ]),
      const SizedBox(height: 8),
      Text('Ejemplo: 1 USD = ${_tasaC.text} CUP · 1000 CUP = ${(1000 / (double.tryParse(_tasaC.text) ?? 1)).toStringAsFixed(2)} USD',
        style: const TextStyle(color: Colors.grey, fontSize: 12)),
      const Divider(height: 40),
      const Text('Backup de datos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      const SizedBox(height: 8),
      const Text('Exporta un JSON y guárdalo en tu correo, WhatsApp o notas. Si cambias de teléfono o desinstalas la app, con ese JSON recuperas todo.',
        style: TextStyle(color: Colors.grey, fontSize: 12)),
      const SizedBox(height: 12),
      FilledButton.icon(onPressed: _exportar, icon: const Icon(Icons.upload), label: const Text('Exportar (copiar al portapapeles)')),
      const SizedBox(height: 8),
      OutlinedButton.icon(onPressed: _importar, icon: const Icon(Icons.download), label: const Text('Importar desde texto')),
      const Divider(height: 40),
      const Text('Sobre la app', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      const SizedBox(height: 8),
      const Text('Versión 2.0 · Datos 100% locales en tu teléfono. No se envía nada a internet.',
        style: TextStyle(color: Colors.grey, fontSize: 12)),
    ]));
}
