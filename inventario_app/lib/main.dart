import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show ImageFilter;
import 'package:fl_chart/fl_chart.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:image_picker/image_picker.dart';

// ⚠️ REEMPLAZA ESTA URL POR TU URL REAL DE RAILWAY
const String ipServidor = "https://imaginative-endurance-production-f769.up.railway.app";

String? tokenGlobal;
String? rolGlobal;
String? nombreGlobal;
int? idGlobal;

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: LoginScreen(),
  ));
}

List<dynamic> parsearLista(String body) {
  final decoded = jsonDecode(body);
  if (decoded is List) {
    return decoded;
  } else if (decoded is Map && decoded['mensaje'] != null) {
    throw Exception(decoded['mensaje']);
  } else if (decoded is Map && decoded['status'] == 'error') {
    throw Exception(decoded['mensaje'] ?? 'Error del servidor');
  } else {
    throw Exception("Respuesta inesperada del servidor");
  }
}

// ====== LOGIN ======
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final correoController = TextEditingController();
  final passwordController = TextEditingController();
  bool cargando = false;

  final Color azulPrincipal = const Color(0xFF3F51B5);
  final Color azulClaro = const Color(0xFF5C6BC0);

  Future<void> login() async {
    if (correoController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ingresa correo y contraseña")),
      );
      return;
    }

    setState(() => cargando = true);
    final url = Uri.parse("$ipServidor/login");

    try {
      final response = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "correo": correoController.text.trim(),
              "password": passwordController.text.trim(),
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;
      setState(() => cargando = false);

      final data = jsonDecode(response.body);

      if (data["status"] == "ok") {
        tokenGlobal = data["token"];
        rolGlobal = data["rol"];
        nombreGlobal = data["usuario"];
        idGlobal = data["id"];

        if (data["rol"] == "admin") {
          Navigator.push(
              context, MaterialPageRoute(builder: (_) => const PanelAdmin()));
        } else if (data["rol"] == "maestro") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  PanelMaestro(maestroNombre: data["usuario"] ?? "Maestro"),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Rol desconocido: ${data["rol"]}")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${data["mensaje"] ?? "desconocido"}")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No se pudo conectar al servidor: $e")),
      );
    }
  }

  Widget _glassField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.18), width: 1),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.55)),
          prefixIcon: Icon(icon, color: azulClaro, size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF050914), Color(0xFF0A1230), Color(0xFF050810)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -120,
              left: -100,
              child: Container(
                width: 340,
                height: 340,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [azulPrincipal.withOpacity(0.55), Colors.transparent],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -140,
              right: -100,
              child: Container(
                width: 380,
                height: 380,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [azulClaro.withOpacity(0.35), Colors.transparent],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 26),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        "INFRAMEN",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Control de Inventario",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.55),
                          fontSize: 14,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 50),
                      Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 45),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(28),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                                child: Container(
                                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 28),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.07),
                                    borderRadius: BorderRadius.circular(28),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.20),
                                      width: 1.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: azulPrincipal.withOpacity(0.35),
                                        blurRadius: 40,
                                        spreadRadius: -10,
                                        offset: const Offset(0, 20),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      const Text(
                                        "Iniciar Sesión",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Bienvenido de nuevo",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.55),
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 30),
                                      _glassField(
                                        controller: correoController,
                                        hint: "Correo",
                                        icon: Icons.email_outlined,
                                      ),
                                      _glassField(
                                        controller: passwordController,
                                        hint: "Contraseña",
                                        icon: Icons.lock_outline,
                                        obscure: true,
                                      ),
                                      const SizedBox(height: 8),
                                      ElevatedButton(
                                        onPressed: cargando ? null : login,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: azulPrincipal,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 18),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          elevation: 10,
                                          shadowColor: azulPrincipal.withOpacity(0.6),
                                        ),
                                        child: cargando
                                            ? const SizedBox(
                                                height: 22,
                                                width: 22,
                                                child: CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 3,
                                                ),
                                              )
                                            : const Text(
                                                "INICIAR SESIÓN",
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 1.5,
                                                ),
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: azulPrincipal.withOpacity(0.6),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Image.asset(
                                  'assets/logo_inventario.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.fact_check_rounded,
                                      color: Color(0xFF1A237E),
                                      size: 50,
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ====== PANEL ADMINISTRADOR ======
class PanelAdmin extends StatelessWidget {
  const PanelAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Panel Administrador",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              tokenGlobal = null;
              rolGlobal = null;
              idGlobal = null;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1A237E).withOpacity(0.45),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.admin_panel_settings,
                          color: Colors.white, size: 34),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Bienvenido",
                              style: TextStyle(color: Colors.white70, fontSize: 15)),
                          const SizedBox(height: 4),
                          Text(nombreGlobal ?? "Administrador",
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text("Acciones disponibles",
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70)),
              const SizedBox(height: 12),
              _BotonCapsula(
                texto: "Gestionar Materiales",
                icono: Icons.inventory_2,
                color: const Color(0xFF795548),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const GestionMateriales())),
              ),
              const SizedBox(height: 10),
              _BotonCapsula(
                texto: "Ver Dashboard",
                icono: Icons.dashboard,
                color: const Color(0xFF3F51B5),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const DashboardAdmin())),
              ),
              const SizedBox(height: 10),
              _BotonCapsula(
                texto: "Ver Préstamos",
                icono: Icons.list_alt_rounded,
                color: const Color(0xFF2196F3),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ListaPrestamos())),
              ),
              const SizedBox(height: 10),
              _BotonCapsula(
                texto: "Ver Reportes",
                icono: Icons.bar_chart_rounded,
                color: const Color(0xFFFF9800),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ReportesAdmin())),
              ),
              const SizedBox(height: 10),
              _BotonCapsula(
                texto: "Ver Gráficas",
                icono: Icons.pie_chart_rounded,
                color: const Color(0xFF9C27B0),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const GraficasReportes())),
              ),
              const SizedBox(height: 10),
              _BotonCapsula(
                texto: "Gestionar Permisos",
                icono: Icons.security_rounded,
                color: const Color(0xFF4CAF50),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const GestionPermisos())),
              ),
              const SizedBox(height: 10),
              _BotonCapsula(
                texto: "Reportes Filtrados (PDF/Excel)",
                icono: Icons.filter_alt_rounded,
                color: const Color(0xFF00BCD4),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ReportesFiltrados())),
              ),
              const SizedBox(height: 10),
              _BotonCapsula(
                texto: "Historial de Préstamos (Guía 17)",
                icono: Icons.history_rounded,
                color: const Color(0xFF673AB7),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const HistorialPrestamos())),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/* ============================================================
   GUÍA 16: GESTIÓN DE MATERIALES
   ============================================================ */
class GestionMateriales extends StatefulWidget {
  const GestionMateriales({super.key});
  @override
  GestionMaterialesState createState() => GestionMaterialesState();
}

class GestionMaterialesState extends State<GestionMateriales> {
  List materiales = [];
  bool cargando = true;
  String? errorMensaje;

  Future<void> cargarMateriales() async {
    setState(() {
      cargando = true;
      errorMensaje = null;
    });
    try {
      final res = await http.get(
        Uri.parse("$ipServidor/materiales"),
        headers: {"Authorization": "Bearer ${tokenGlobal ?? ""}"},
      );
      setState(() {
        materiales = parsearLista(res.body);
        cargando = false;
      });
    } catch (e) {
      setState(() {
        cargando = false;
        errorMensaje = e.toString().replaceFirst("Exception: ", "");
      });
    }
  }

  @override
  void initState() {
    super.initState();
    cargarMateriales();
  }

  Future<void> eliminar(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Eliminar material"),
        content: const Text("¿Estás seguro de eliminar este material?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Eliminar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    try {
      final res = await http.delete(
        Uri.parse("$ipServidor/materiales/$id"),
        headers: {"Authorization": "Bearer ${tokenGlobal ?? ""}"},
      );
      final data = jsonDecode(res.body);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data["mensaje"] ?? "Eliminado")),
      );
      cargarMateriales();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("Gestión de Materiales"),
        backgroundColor: const Color(0xFF3F51B5),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FormularioMaterial()),
          );
          cargarMateriales();
        },
        backgroundColor: const Color(0xFF4CAF50),
        icon: const Icon(Icons.add),
        label: const Text("Agregar"),
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : errorMensaje != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 60, color: Colors.red),
                        const SizedBox(height: 12),
                        Text("Error: $errorMensaje", textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: cargarMateriales,
                          child: const Text("Reintentar"),
                        ),
                      ],
                    ),
                  ),
                )
              : materiales.isEmpty
                  ? const Center(child: Text("No hay materiales registrados"))
                  : RefreshIndicator(
                      onRefresh: cargarMateriales,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: materiales.length,
                        itemBuilder: (ctx, i) {
                          final m = materiales[i];
                          final foto = m['foto'];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(10),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: foto != null && foto.toString().isNotEmpty
                                    ? Image.network(
                                        "$ipServidor/$foto",
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 60,
                                          height: 60,
                                          color: Colors.grey.shade300,
                                          child: const Icon(Icons.broken_image,
                                              color: Colors.grey),
                                        ),
                                      )
                                    : Container(
                                        width: 60,
                                        height: 60,
                                        color: const Color(0xFF3F51B5).withOpacity(0.2),
                                        child: const Icon(Icons.inventory_2,
                                            color: Color(0xFF3F51B5)),
                                      ),
                              ),
                              title: Text(
                                m['nombre'] ?? 'Sin nombre',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                "Categoría: ${m['categoria'] ?? 'Sin categoría'}\n"
                                "Cantidad: ${m['cantidad'] ?? 0}  |  Estado: ${m['estado'] ?? '-'}",
                              ),
                              isThreeLine: true,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.orange),
                                    onPressed: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => FormularioMaterial(material: m),
                                        ),
                                      );
                                      cargarMateriales();
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => eliminar(m['id']),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

class FormularioMaterial extends StatefulWidget {
  final Map? material;
  const FormularioMaterial({super.key, this.material});
  @override
  FormularioMaterialState createState() => FormularioMaterialState();
}

class FormularioMaterialState extends State<FormularioMaterial> {
  final nombreController = TextEditingController();
  final cantidadController = TextEditingController(text: "1");
  String categoria = "Deportes";
  String estado = "bueno";
  File? fotoSeleccionada;
  bool guardando = false;

  List<String> categorias = ["Deportes", "Laboratorio", "Tecnología", "Oficina", "General"];
  List<String> estados = ["bueno", "regular", "dañado"];

  @override
  void initState() {
    super.initState();
    if (widget.material != null) {
      nombreController.text = widget.material!['nombre'] ?? '';
      cantidadController.text = (widget.material!['cantidad'] ?? 1).toString();
      final cat = widget.material!['categoria'];
      if (cat != null && cat.toString().isNotEmpty) {
        categoria = cat.toString();
        if (!categorias.contains(categoria)) categorias.add(categoria);
      }
      final est = widget.material!['estado'];
      if (est != null && est.toString().isNotEmpty) {
        estado = est.toString();
        if (!estados.contains(estado)) estados.add(estado);
      }
    }
  }

  Future<void> seleccionarFoto() async {
    final picker = ImagePicker();
    final XFile? foto = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (foto != null) {
      setState(() => fotoSeleccionada = File(foto.path));
    }
  }

  Future<void> guardar() async {
    if (nombreController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ingresa el nombre del material")),
      );
      return;
    }

    setState(() => guardando = true);

    try {
      final uri = widget.material == null
          ? Uri.parse("$ipServidor/materiales")
          : Uri.parse("$ipServidor/materiales/${widget.material!['id']}");

      final request = http.MultipartRequest(
        widget.material == null ? "POST" : "PUT",
        uri,
      );
      request.headers["Authorization"] = "Bearer ${tokenGlobal ?? ""}";
      request.fields["nombre"] = nombreController.text.trim();
      request.fields["cantidad"] = cantidadController.text.trim();
      request.fields["categoria"] = categoria;
      request.fields["estado"] = estado;

      if (fotoSeleccionada != null) {
        request.files.add(
          await http.MultipartFile.fromPath("foto", fotoSeleccionada!.path),
        );
      }

      final streamed = await request.send();
      final res = await http.Response.fromStream(streamed);
      final data = jsonDecode(res.body);

      if (!mounted) return;
      setState(() => guardando = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data["mensaje"] ?? "Guardado")),
      );

      if (data["status"] == "ok") {
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => guardando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.material != null;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(esEdicion ? "Editar Material" : "Agregar Material"),
        backgroundColor: const Color(0xFF3F51B5),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: nombreController,
              decoration: const InputDecoration(
                labelText: "Nombre del material",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.inventory_2),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: cantidadController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Cantidad",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.numbers),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: categoria,
              decoration: const InputDecoration(
                labelText: "Categoría",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
                filled: true,
                fillColor: Colors.white,
              ),
              items: categorias
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => categoria = v!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: estado,
              decoration: const InputDecoration(
                labelText: "Estado",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.health_and_safety),
                filled: true,
                fillColor: Colors.white,
              ),
              items: estados
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => estado = v!),
            ),
            const SizedBox(height: 20),
            Center(
              child: GestureDetector(
                onTap: seleccionarFoto,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                    image: fotoSeleccionada != null
                        ? DecorationImage(
                            image: FileImage(fotoSeleccionada!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: fotoSeleccionada == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.add_a_photo,
                                size: 45, color: Color(0xFF3F51B5)),
                            SizedBox(height: 8),
                            Text("Seleccionar Foto",
                                style: TextStyle(
                                    color: Color(0xFF3F51B5),
                                    fontWeight: FontWeight.bold)),
                          ],
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: guardando ? null : guardar,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: guardando
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : Text(
                      esEdicion ? "Actualizar Material" : "Guardar Material",
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
/* ============================================================
   FIN GUÍA 16
   ============================================================ */

// ====== DASHBOARD ======
class DashboardAdmin extends StatefulWidget {
  const DashboardAdmin({super.key});
  @override
  DashboardAdminState createState() => DashboardAdminState();
}

class DashboardAdminState extends State<DashboardAdmin> {
  Map datos = {};
  bool cargando = true;

  Future<void> obtenerDatos() async {
    final url = Uri.parse("$ipServidor/dashboard");
    try {
      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer ${tokenGlobal ?? ""}"},
      );
      setState(() {
        datos = jsonDecode(response.body);
        cargando = false;
      });
    } catch (e) {
      setState(() => cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al cargar dashboard: $e")),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    obtenerDatos();
  }

  Widget _buildCard(String titulo, dynamic valor, Color color, IconData icono) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.85), color.withOpacity(0.55)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                shape: BoxShape.circle,
              ),
              child: Icon(icono, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 12),
            Text(titulo,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text("${valor ?? 0}",
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prestados = (datos["prestados"] ?? 0).toDouble();
    final devueltos = (datos["devueltos"] ?? 0).toDouble();
    final danados = (datos["danados"] ?? 0).toDouble();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Dashboard Inventario",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: obtenerDatos,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text("Métricas clave",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildCard("Total Materiales",
                            datos["total_materiales"], Colors.blue, Icons.inventory_2),
                        _buildCard("Prestados",
                            datos["prestados"], Colors.orange, Icons.assignment),
                      ],
                    ),
                    Row(
                      children: [
                        _buildCard("Devueltos",
                            datos["devueltos"], Colors.green, Icons.check_circle),
                        _buildCard("Dañados",
                            datos["danados"], Colors.red, Icons.warning),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text("Gráfica de estados",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: SizedBox(
                        height: 260,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 3,
                            centerSpaceRadius: 50,
                            sections: [
                              PieChartSectionData(
                                color: Colors.orange,
                                value: prestados,
                                title: '$prestados',
                                radius: 60,
                                titleStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                              PieChartSectionData(
                                color: Colors.green,
                                value: devueltos,
                                title: '$devueltos',
                                radius: 60,
                                titleStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                              PieChartSectionData(
                                color: Colors.red,
                                value: danados,
                                title: '$danados',
                                radius: 60,
                                titleStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: const [
                        _Leyenda(color: Colors.orange, texto: "Prestados"),
                        _Leyenda(color: Colors.green, texto: "Devueltos"),
                        _Leyenda(color: Colors.red, texto: "Dañados"),
                      ],
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }
}

class _Leyenda extends StatelessWidget {
  final Color color;
  final String texto;
  const _Leyenda({required this.color, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(texto, style: const TextStyle(color: Colors.white70, fontSize: 13)),
      ],
    );
  }
}

// ====== GESTIÓN DE PERMISOS ======
class GestionPermisos extends StatefulWidget {
  const GestionPermisos({super.key});
  @override
  GestionPermisosState createState() => GestionPermisosState();
}

class GestionPermisosState extends State<GestionPermisos> {
  List materiales = [];
  List docentes = [];
  String? docenteSeleccionado;
  String? materialSeleccionado;
  bool puedeVer = true;
  bool puedePrestar = false;
  bool puedeDevolver = false;
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  Future<void> cargarDatos() async {
    final headers = {"Authorization": "Bearer ${tokenGlobal ?? ""}"};
    try {
      final resMat = await http.get(Uri.parse("$ipServidor/materiales"), headers: headers);
      final resDoc = await http.get(Uri.parse("$ipServidor/usuarios?rol=maestro"), headers: headers);

      setState(() {
        materiales = parsearLista(resMat.body);
        docentes = parsearLista(resDoc.body);
        cargando = false;
      });
    } catch (e) {
      setState(() => cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al cargar datos: $e"), duration: const Duration(seconds: 5)),
      );
    }
  }

  Future<void> asignarPermiso() async {
    if (docenteSeleccionado == null || materialSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecciona docente y material")),
      );
      return;
    }
    final url = Uri.parse("$ipServidor/permisos");
    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${tokenGlobal ?? ""}",
        },
        body: jsonEncode({
          "docente_id": docenteSeleccionado,
          "material_id": materialSeleccionado,
          "puede_ver": puedeVer,
          "puede_prestar": puedePrestar,
          "puede_devolver": puedeDevolver,
        }),
      );
      final data = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Respuesta: ${data["mensaje"] ?? response.body}")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al conectar con el servidor")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context)),
        title: const Text("Gestión de Permisos",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: docenteSeleccionado,
                      decoration: const InputDecoration(
                        labelText: "Docente",
                        border: OutlineInputBorder(),
                      ),
                      items: docentes.map<DropdownMenuItem<String>>((d) {
                        return DropdownMenuItem<String>(
                          value: d["id"].toString(),
                          child: Text(d["nombre"]),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => docenteSeleccionado = v),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: materialSeleccionado,
                      decoration: const InputDecoration(
                        labelText: "Material",
                        border: OutlineInputBorder(),
                      ),
                      items: materiales.map<DropdownMenuItem<String>>((m) {
                        return DropdownMenuItem<String>(
                          value: m["id"].toString(),
                          child: Text(m["nombre"]),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => materialSeleccionado = v),
                    ),
                    const SizedBox(height: 20),
                    SwitchListTile(
                      title: const Text("Puede ver"),
                      value: puedeVer,
                      onChanged: (v) => setState(() => puedeVer = v),
                    ),
                    SwitchListTile(
                      title: const Text("Puede prestar"),
                      value: puedePrestar,
                      onChanged: (v) => setState(() => puedePrestar = v),
                    ),
                    SwitchListTile(
                      title: const Text("Puede devolver"),
                      value: puedeDevolver,
                      onChanged: (v) => setState(() => puedeDevolver = v),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: asignarPermiso,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Asignar Permiso",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// ====== PANEL MAESTRO ======
class PanelMaestro extends StatelessWidget {
  final String maestroNombre;
  PanelMaestro({required this.maestroNombre});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Panel Maestro",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              tokenGlobal = null;
              rolGlobal = null;
              idGlobal = null;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF283593), Color(0xFF3F51B5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF283593).withOpacity(0.45),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.school, color: Colors.white, size: 34),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Bienvenido",
                              style:
                                  TextStyle(color: Colors.white70, fontSize: 15)),
                          const SizedBox(height: 4),
                          Text(
                            maestroNombre,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text("Acciones disponibles",
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70)),
              const SizedBox(height: 12),
              _BotonCapsula(
                texto: "Registrar Préstamo Manual",
                icono: Icons.add_circle_outline,
                color: const Color(0xFF3F51B5),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const RegistroPrestamo())),
              ),
              const SizedBox(height: 10),
              _BotonCapsula(
                texto: "Escanear Retiro (QR)",
                icono: Icons.qr_code_scanner,
                color: const Color(0xFF4CAF50),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EscaneoQR(maestro: maestroNombre, esRetiro: true),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _BotonCapsula(
                texto: "Escanear Entrega (QR)",
                icono: Icons.qr_code_scanner,
                color: const Color(0xFFFF9800),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EscaneoQR(maestro: maestroNombre, esRetiro: false),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _BotonCapsula(
                texto: "Ver Préstamos",
                icono: Icons.list_alt_rounded,
                color: const Color(0xFF2196F3),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ListaPrestamos())),
              ),
              const SizedBox(height: 10),
              _BotonCapsula(
                texto: "Ver Notificaciones",
                icono: Icons.notifications_active_outlined,
                color: const Color(0xFF9C27B0),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            NotificacionesMaestro(maestro: maestroNombre)),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ====== BOTÓN CÁPSULA ======
class _BotonCapsula extends StatelessWidget {
  final String texto;
  final IconData icono;
  final Color color;
  final VoidCallback onTap;

  const _BotonCapsula({
    required this.texto,
    required this.icono,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: Ink(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.22),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icono, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    texto,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ====== ESCANEO QR ======
class EscaneoQR extends StatefulWidget {
  final String maestro;
  final bool esRetiro;
  EscaneoQR({required this.maestro, required this.esRetiro});

  @override
  EscaneoQRState createState() => EscaneoQRState();
}

class EscaneoQRState extends State<EscaneoQR> {
  final MobileScannerController controller = MobileScannerController();
  bool procesando = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (procesando) return;
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty || barcodes.first.rawValue == null) return;

    setState(() => procesando = true);
    String materialId = barcodes.first.rawValue!;
    await controller.stop();

    if (widget.esRetiro) {
      final url = Uri.parse("$ipServidor/prestamos");
      try {
        final response = await http.post(
          url,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer ${tokenGlobal ?? ""}",
          },
          body: jsonEncode({
            "material_id": materialId,
            "docente_id": idGlobal,
            "fecha_prestamo": DateTime.now().toIso8601String(),
          }),
        );
        final data = jsonDecode(response.body);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Retiro: ${data["mensaje"] ?? response.body}")),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al conectar con el servidor")),
        );
      }
    } else {
      final url = Uri.parse("$ipServidor/prestamos/devolver/mat/$materialId");
      try {
        final response = await http.put(
          url,
          headers: {"Authorization": "Bearer ${tokenGlobal ?? ""}"},
        );
        final data = jsonDecode(response.body);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Entrega: ${data["mensaje"] ?? response.body}")),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al conectar con el servidor")),
        );
      }
    }

    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => procesando = false);
      controller.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.esRetiro ? "Escanear Retiro" : "Escanear Entrega"),
        backgroundColor:
            widget.esRetiro ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: MobileScanner(controller: controller, onDetect: _onDetect),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                procesando
                    ? "Procesando..."
                    : (widget.esRetiro
                        ? "Apunta al QR para registrar el RETIRO"
                        : "Apunta al QR para registrar la ENTREGA"),
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ====== NOTIFICACIONES ======
class NotificacionesMaestro extends StatefulWidget {
  final String maestro;
  NotificacionesMaestro({required this.maestro});

  @override
  NotificacionesMaestroState createState() => NotificacionesMaestroState();
}

class NotificacionesMaestroState extends State<NotificacionesMaestro> {
  List pendientes = [];
  bool cargando = true;
  String? errorMensaje;

  Future<void> obtenerPendientes() async {
    setState(() {
      cargando = true;
      errorMensaje = null;
    });
    final url = Uri.parse("$ipServidor/notificaciones/${idGlobal ?? 0}");
    try {
      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer ${tokenGlobal ?? ""}"},
      );
      final lista = parsearLista(response.body);
      setState(() {
        pendientes = lista;
        cargando = false;
      });
    } catch (e) {
      setState(() {
        pendientes = [];
        cargando = false;
        errorMensaje = e.toString().replaceFirst("Exception: ", "");
      });
    }
  }

  @override
  void initState() {
    super.initState();
    obtenerPendientes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notificaciones")),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : errorMensaje != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text("Error: $errorMensaje", textAlign: TextAlign.center),
                  ),
                )
              : pendientes.isEmpty
                  ? const Center(child: Text("No tienes préstamos pendientes"))
                  : RefreshIndicator(
                      onRefresh: obtenerPendientes,
                      child: ListView.builder(
                        itemCount: pendientes.length,
                        itemBuilder: (context, index) {
                          final p = pendientes[index];
                          return ListTile(
                            title: Text("Material: ${p['material'] ?? 'Desconocido'}"),
                            subtitle: Text("Fecha préstamo: ${p['fecha_prestamo']}"),
                            trailing: const Text("Pendiente",
                                style: TextStyle(color: Colors.orange)),
                          );
                        },
                      ),
                    ),
    );
  }
}

// ====== REGISTRO DE PRÉSTAMOS ======
class RegistroPrestamo extends StatefulWidget {
  const RegistroPrestamo({super.key});
  @override
  RegistroPrestamoState createState() => RegistroPrestamoState();
}

class RegistroPrestamoState extends State<RegistroPrestamo> {
  final fechaPrestamoController = TextEditingController();
  List materiales = [];
  List docentes = [];
  String? materialSeleccionado;
  String? docenteSeleccionado;
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    final hoy = DateTime.now();
    fechaPrestamoController.text =
        "${hoy.year}-${hoy.month.toString().padLeft(2, '0')}-${hoy.day.toString().padLeft(2, '0')}";
    cargarDatos();
  }

  Future<void> cargarDatos() async {
    final headers = {"Authorization": "Bearer ${tokenGlobal ?? ""}"};
    try {
      final resMat = await http.get(Uri.parse("$ipServidor/materiales"), headers: headers);
      final resDoc = await http.get(Uri.parse("$ipServidor/usuarios?rol=maestro"), headers: headers);

      setState(() {
        materiales = parsearLista(resMat.body);
        docentes = parsearLista(resDoc.body);
        if (rolGlobal == 'maestro' && idGlobal != null) {
          docenteSeleccionado = idGlobal.toString();
        }
        cargando = false;
      });
    } catch (e) {
      setState(() => cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al cargar datos: $e"), duration: const Duration(seconds: 5)),
      );
    }
  }

  Future<void> _selectDate(TextEditingController controller) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        controller.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> registrarPrestamo() async {
    if (materialSeleccionado == null || docenteSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecciona material y docente")),
      );
      return;
    }

    if (fechaPrestamoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecciona la fecha de préstamo")),
      );
      return;
    }

    final url = Uri.parse("$ipServidor/prestamos");
    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${tokenGlobal ?? ""}",
        },
        body: jsonEncode({
          "material_id": materialSeleccionado,
          "docente_id": docenteSeleccionado,
          "fecha_prestamo": fechaPrestamoController.text,
        }),
      );
      final data = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Respuesta: ${data["mensaje"] ?? response.body}")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al conectar con el servidor")),
      );
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool isDate = false,
    TextInputType? keyboardType,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: isDate,
        onTap: isDate ? () => _selectDate(controller) : null,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF3F51B5)),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[600]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16.0),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context)),
        title: const Text("Registro de Préstamos",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<String>(
                      value: materialSeleccionado,
                      decoration: const InputDecoration(
                        labelText: "Material",
                        border: OutlineInputBorder(),
                      ),
                      items: materiales.map<DropdownMenuItem<String>>((m) {
                        return DropdownMenuItem<String>(
                          value: m["id"].toString(),
                          child: Text(m["nombre"]),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => materialSeleccionado = v),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: docenteSeleccionado,
                      decoration: const InputDecoration(
                        labelText: "Docente",
                        border: OutlineInputBorder(),
                      ),
                      items: docentes.map<DropdownMenuItem<String>>((d) {
                        return DropdownMenuItem<String>(
                          value: d["id"].toString(),
                          child: Text(d["nombre"]),
                        );
                      }).toList(),
                      onChanged: rolGlobal == 'admin'
                          ? (v) => setState(() => docenteSeleccionado = v)
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                        controller: fechaPrestamoController,
                        icon: Icons.calendar_today,
                        hint: "Fecha de préstamo",
                        isDate: true),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: registrarPrestamo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3F51B5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Registrar Préstamo",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// ====== LISTA DE PRÉSTAMOS ======
class ListaPrestamos extends StatefulWidget {
  const ListaPrestamos({super.key});
  @override
  ListaPrestamosState createState() => ListaPrestamosState();
}

class ListaPrestamosState extends State<ListaPrestamos> {
  List prestamos = [];
  bool cargando = true;
  String? errorMensaje;

  Future<void> obtenerPrestamos() async {
    setState(() {
      cargando = true;
      errorMensaje = null;
    });
    final url = Uri.parse("$ipServidor/prestamos");
    try {
      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer ${tokenGlobal ?? ""}"},
      );
      final lista = parsearLista(response.body);
      setState(() {
        prestamos = lista;
        cargando = false;
      });
    } catch (e) {
      setState(() {
        prestamos = [];
        cargando = false;
        errorMensaje = e.toString().replaceFirst("Exception: ", "");
      });
    }
  }

  @override
  void initState() {
    super.initState();
    obtenerPrestamos();
  }

  Future<void> _editarDevolucion(int id) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      String fecha =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      final url = Uri.parse("$ipServidor/prestamos/$id");
      try {
        final response = await http.put(
          url,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer ${tokenGlobal ?? ""}",
          },
          body: jsonEncode({"fecha_devolucion": fecha}),
        );
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("${data["mensaje"]}")));
        obtenerPrestamos();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al actualizar")),
        );
      }
    }
  }

  Future<void> _marcarDevuelto(int id) async {
    final url = Uri.parse("$ipServidor/prestamos/devolver/$id");
    try {
      final response = await http.put(
        url,
        headers: {"Authorization": "Bearer ${tokenGlobal ?? ""}"},
      );
      final data = jsonDecode(response.body);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("${data["mensaje"]}")));
      obtenerPrestamos();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al marcar devolución")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Lista de Préstamos")),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : errorMensaje != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 60, color: Colors.red),
                        const SizedBox(height: 12),
                        Text("Error: $errorMensaje", textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: obtenerPrestamos,
                          child: const Text("Reintentar"),
                        ),
                      ],
                    ),
                  ),
                )
              : prestamos.isEmpty
                  ? const Center(child: Text("No hay préstamos registrados"))
                  : RefreshIndicator(
                      onRefresh: obtenerPrestamos,
                      child: ListView.builder(
                        itemCount: prestamos.length,
                        itemBuilder: (context, index) {
                          final p = prestamos[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              leading: const Icon(Icons.assignment, color: Color(0xFF3F51B5)),
                              title: Text("Material: ${p['material'] ?? 'Sin nombre'}"),
                              subtitle: Text(
                                "Docente: ${p['docente'] ?? 'Desconocido'}\n"
                                "Préstamo: ${p['fecha_prestamo']}\n"
                                "Devolución: ${p['fecha_devolucion'] ?? 'Pendiente'}",
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.orange),
                                    onPressed: () => _editarDevolucion(p['id']),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.check_circle, color: Colors.green),
                                    onPressed: () => _marcarDevuelto(p['id']),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

// ====== REPORTES ======
class ReportesAdmin extends StatefulWidget {
  const ReportesAdmin({super.key});
  @override
  ReportesAdminState createState() => ReportesAdminState();
}

class ReportesAdminState extends State<ReportesAdmin> {
  int total = 0;
  int pendientes = 0;
  int devueltos = 0;
  bool cargando = true;

  Future<void> obtenerReportes() async {
    final urlTotal = Uri.parse("$ipServidor/reportes/total");
    final urlPendientes = Uri.parse("$ipServidor/reportes/pendientes");
    final urlDevueltos = Uri.parse("$ipServidor/reportes/devueltos");
    final headers = {"Authorization": "Bearer ${tokenGlobal ?? ""}"};
    try {
      final resTotal = await http.get(urlTotal, headers: headers);
      final resPendientes = await http.get(urlPendientes, headers: headers);
      final resDevueltos = await http.get(urlDevueltos, headers: headers);
      setState(() {
        total = jsonDecode(resTotal.body)["total"];
        pendientes = jsonDecode(resPendientes.body)["pendientes"];
        devueltos = jsonDecode(resDevueltos.body)["devueltos"];
        cargando = false;
      });
    } catch (e) {
      setState(() => cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al cargar reportes: $e")),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    obtenerReportes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reportes de Préstamos")),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.list, color: Colors.blue),
                      title: const Text("Total de préstamos"),
                      trailing: Text("$total",
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.hourglass_empty,
                          color: Colors.orange),
                      title: const Text("Pendientes de devolución"),
                      trailing: Text("$pendientes",
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading:
                          const Icon(Icons.check_circle, color: Colors.green),
                      title: const Text("Devueltos"),
                      trailing: Text("$devueltos",
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// ====== GRÁFICAS ======
class GraficasReportes extends StatefulWidget {
  const GraficasReportes({super.key});
  @override
  GraficasReportesState createState() => GraficasReportesState();
}

class GraficasReportesState extends State<GraficasReportes> {
  int total = 0;
  int pendientes = 0;
  int devueltos = 0;

  Future<void> obtenerReportes() async {
    final urlTotal = Uri.parse("$ipServidor/reportes/total");
    final urlPendientes = Uri.parse("$ipServidor/reportes/pendientes");
    final urlDevueltos = Uri.parse("$ipServidor/reportes/devueltos");
    final headers = {"Authorization": "Bearer ${tokenGlobal ?? ""}"};
    try {
      final resTotal = await http.get(urlTotal, headers: headers);
      final resPendientes = await http.get(urlPendientes, headers: headers);
      final resDevueltos = await http.get(urlDevueltos, headers: headers);
      setState(() {
        total = jsonDecode(resTotal.body)["total"];
        pendientes = jsonDecode(resPendientes.body)["pendientes"];
        devueltos = jsonDecode(resDevueltos.body)["devueltos"];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al cargar gráficas: $e")),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    obtenerReportes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gráficas de Reportes")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text("Gráfico de Barras (Pendientes vs Devueltos)",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Expanded(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY:
                      (pendientes > devueltos ? pendientes : devueltos).toDouble() + 1,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const Text('Pendientes');
                          if (value == 1) return const Text('Devueltos');
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                        sideTitles:
                            SideTitles(showTitles: true, reservedSize: 30)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(x: 0, barRods: [
                      BarChartRodData(
                        toY: pendientes.toDouble(),
                        color: Colors.orange,
                        width: 20,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ]),
                    BarChartGroupData(x: 1, barRods: [
                      BarChartRodData(
                        toY: devueltos.toDouble(),
                        color: Colors.green,
                        width: 20,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text("Gráfico de Pastel",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Expanded(
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: [
                    PieChartSectionData(
                      color: Colors.orange,
                      value: pendientes.toDouble(),
                      title: '$pendientes',
                      radius: 50,
                      titleStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    PieChartSectionData(
                      color: Colors.green,
                      value: devueltos.toDouble(),
                      title: '$devueltos',
                      radius: 50,
                      titleStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ====== REPORTES FILTRADOS + PDF/EXCEL ======
class ReportesFiltrados extends StatefulWidget {
  const ReportesFiltrados({super.key});
  @override
  ReportesFiltradosState createState() => ReportesFiltradosState();
}

class ReportesFiltradosState extends State<ReportesFiltrados> {
  final maestroController = TextEditingController();
  DateTime? fechaInicio;
  DateTime? fechaFin;
  List reportes = [];
  bool cargando = false;
  bool descargando = false;

  String _fmt(DateTime? d) =>
      d == null ? "" : "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  Future<void> _pickDate(bool isInicio) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isInicio) {
          fechaInicio = picked;
        } else {
          fechaFin = picked;
        }
      });
    }
  }

  Future<void> buscar() async {
    setState(() => cargando = true);
    final url = Uri.parse(
      "$ipServidor/reportes/filtrados"
      "?maestro=${maestroController.text.trim()}"
      "&fecha_inicio=${_fmt(fechaInicio)}"
      "&fecha_fin=${_fmt(fechaFin)}",
    );
    try {
      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer ${tokenGlobal ?? ""}"},
      );
      final lista = parsearLista(response.body);
      setState(() {
        reportes = lista;
        cargando = false;
      });
    } catch (e) {
      setState(() {
        reportes = [];
        cargando = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> descargarArchivo(String tipo) async {
    setState(() => descargando = true);
    final url = Uri.parse(
      "$ipServidor/reportes/$tipo"
      "?maestro=${maestroController.text.trim()}"
      "&fecha_inicio=${_fmt(fechaInicio)}"
      "&fecha_fin=${_fmt(fechaFin)}",
    );

    try {
      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer ${tokenGlobal ?? ""}"},
      );

      if (response.statusCode != 200 ||
          response.headers['content-type']?.contains('application/json') == true) {
        String mensajeError = "Error del servidor";
        try {
          final jsonError = jsonDecode(response.body);
          mensajeError = jsonError['mensaje'] ?? response.body;
        } catch (_) {
          mensajeError = response.body;
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Error: $mensajeError"),
              duration: const Duration(seconds: 5)),
        );
        setState(() => descargando = false);
        return;
      }

      final dir = await getApplicationDocumentsDirectory();
      final ext = tipo == "pdf" ? "pdf" : "xlsx";
      final file = File(
          "${dir.path}/reporte_${DateTime.now().millisecondsSinceEpoch}.$ext");
      await file.writeAsBytes(response.bodyBytes);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Archivo guardado en ${file.path}")),
      );

      try {
        await OpenFile.open(file.path);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  "Archivo guardado en ${file.path}, pero no se pudo abrir automáticamente."),
              duration: const Duration(seconds: 5)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Error de conexión: $e"),
            duration: const Duration(seconds: 5)),
      );
    } finally {
      if (mounted) setState(() => descargando = false);
    }
  }

  Widget _filtroFecha({
    required String label,
    required DateTime? fecha,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: Colors.black54),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF3F51B5), width: 2),
            ),
          ),
          child: Text(
            fecha == null ? "" : _fmt(fecha),
            style: const TextStyle(color: Colors.black87, fontSize: 16),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text("Reportes Filtrados",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: maestroController,
                    decoration: InputDecoration(
                      labelText: "Docente",
                      labelStyle: const TextStyle(color: Colors.black54),
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: Color(0xFF3F51B5), width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _filtroFecha(
                        label: "Desde",
                        fecha: fechaInicio,
                        onTap: () => _pickDate(true),
                      ),
                      const SizedBox(width: 16),
                      _filtroFecha(
                        label: "Hasta",
                        fecha: fechaFin,
                        onTap: () => _pickDate(false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: buscar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Buscar",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text("PDF"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: descargando ? null : () => descargarArchivo("pdf"),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.table_chart),
                    label: const Text("Excel"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed:
                        descargando ? null : () => descargarArchivo("excel"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (cargando)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (reportes.isEmpty)
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    Icon(Icons.inbox, size: 60, color: Colors.grey.shade400),
                    const SizedBox(height: 10),
                    Text(
                      "Sin resultados.\nAplica filtros y presiona Buscar.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: reportes.map<Widget>((r) {
                  final devuelto = r['fecha_devolucion'] != null;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            devuelto ? Colors.green : Colors.orange,
                        child: Icon(
                          devuelto ? Icons.check : Icons.hourglass_empty,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        r['material'] ?? 'Sin material',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "Docente: ${r['docente']}\n"
                        "Préstamo: ${_fmt(DateTime.tryParse(r['fecha_prestamo']?.toString() ?? ''))}\n"
                        "Devolución: ${devuelto ? _fmt(DateTime.tryParse(r['fecha_devolucion'].toString())) : 'Pendiente'}",
                      ),
                      isThreeLine: true,
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

/* ============================================================
   🆕 GUÍA 17: HISTORIAL DETALLADO DE PRÉSTAMOS
   ============================================================ */
class HistorialPrestamos extends StatefulWidget {
  const HistorialPrestamos({super.key});
  @override
  HistorialPrestamosState createState() => HistorialPrestamosState();
}

class HistorialPrestamosState extends State<HistorialPrestamos> {
  final maestroController = TextEditingController();
  final materialController = TextEditingController();
  DateTime? fechaInicio;
  DateTime? fechaFin;
  List historial = [];
  bool cargando = true;
  bool descargando = false;

  String _fmt(DateTime? d) => d == null
      ? ""
      : "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  @override
  void initState() {
    super.initState();
    obtenerHistorial();
  }

  Future<void> _pickDate(bool isInicio) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isInicio) {
          fechaInicio = picked;
        } else {
          fechaFin = picked;
        }
      });
    }
  }

  String _buildQuery() {
    return "?maestro=${Uri.encodeComponent(maestroController.text.trim())}"
        "&material=${Uri.encodeComponent(materialController.text.trim())}"
        "&fecha_inicio=${_fmt(fechaInicio)}"
        "&fecha_fin=${_fmt(fechaFin)}";
  }

  Future<void> obtenerHistorial() async {
    setState(() => cargando = true);
    final url = Uri.parse("$ipServidor/historial${_buildQuery()}");
    try {
      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer ${tokenGlobal ?? ""}"},
      );
      final lista = parsearLista(response.body);
      setState(() {
        historial = lista;
        cargando = false;
      });
    } catch (e) {
      setState(() {
        historial = [];
        cargando = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> descargarArchivo(String tipo) async {
    setState(() => descargando = true);
    final url =
        Uri.parse("$ipServidor/historial/$tipo${_buildQuery()}");

    try {
      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer ${tokenGlobal ?? ""}"},
      );

      if (response.statusCode != 200 ||
          response.headers['content-type']?.contains('application/json') == true) {
        String mensajeError = "Error del servidor";
        try {
          final jsonError = jsonDecode(response.body);
          mensajeError = jsonError['mensaje'] ?? response.body;
        } catch (_) {
          mensajeError = response.body;
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Error: $mensajeError"),
              duration: const Duration(seconds: 5)),
        );
        setState(() => descargando = false);
        return;
      }

      final dir = await getApplicationDocumentsDirectory();
      final ext = tipo == "pdf" ? "pdf" : "xlsx";
      final file = File(
          "${dir.path}/historial_${DateTime.now().millisecondsSinceEpoch}.$ext");
      await file.writeAsBytes(response.bodyBytes);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Archivo guardado en ${file.path}")),
      );

      try {
        await OpenFile.open(file.path);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  "Archivo guardado en ${file.path}, pero no se pudo abrir automáticamente."),
              duration: const Duration(seconds: 5)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Error de conexión: $e"),
            duration: const Duration(seconds: 5)),
      );
    } finally {
      if (mounted) setState(() => descargando = false);
    }
  }

  Widget _filtroFecha({
    required String label,
    required DateTime? fecha,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: Colors.black54),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF3F51B5), width: 2),
            ),
          ),
          child: Text(
            fecha == null ? "" : _fmt(fecha),
            style: const TextStyle(color: Colors.black87, fontSize: 16),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF673AB7),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text("Historial de Préstamos",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: maestroController,
                    decoration: InputDecoration(
                      labelText: "Docente (maestro)",
                      prefixIcon: const Icon(Icons.person_outline),
                      labelStyle: const TextStyle(color: Colors.black54),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 18, horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: Color(0xFF673AB7), width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: materialController,
                    decoration: InputDecoration(
                      labelText: "Material",
                      prefixIcon: const Icon(Icons.inventory_2_outlined),
                      labelStyle: const TextStyle(color: Colors.black54),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 18, horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: Color(0xFF673AB7), width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _filtroFecha(
                        label: "Desde",
                        fecha: fechaInicio,
                        onTap: () => _pickDate(true),
                      ),
                      const SizedBox(width: 16),
                      _filtroFecha(
                        label: "Hasta",
                        fecha: fechaFin,
                        onTap: () => _pickDate(false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: obtenerHistorial,
                      icon: const Icon(Icons.search),
                      label: const Text("Buscar",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF673AB7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        maestroController.clear();
                        materialController.clear();
                        fechaInicio = null;
                        fechaFin = null;
                      });
                      obtenerHistorial();
                    },
                    icon: const Icon(Icons.clear),
                    label: const Text("Limpiar filtros"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text("PDF"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: descargando ? null : () => descargarArchivo("pdf"),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.table_chart),
                    label: const Text("Excel"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: descargando ? null : () => descargarArchivo("excel"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (cargando)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (historial.isEmpty)
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    Icon(Icons.inbox, size: 60, color: Colors.grey.shade400),
                    const SizedBox(height: 10),
                    Text(
                      "Sin resultados.\nAplica filtros y presiona Buscar.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: historial.map<Widget>((r) {
                  final devuelto = r['fecha_devolucion'] != null;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: devuelto ? Colors.green : Colors.orange,
                        child: Icon(
                          devuelto ? Icons.check : Icons.hourglass_empty,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        r['material'] ?? 'Sin material',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "Docente: ${r['docente']}\n"
                        "Retiro: ${_fmt(DateTime.tryParse(r['fecha_prestamo']?.toString() ?? ''))}\n"
                        "Entrega: ${devuelto ? _fmt(DateTime.tryParse(r['fecha_devolucion'].toString())) : 'Pendiente'}",
                      ),
                      isThreeLine: true,
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}