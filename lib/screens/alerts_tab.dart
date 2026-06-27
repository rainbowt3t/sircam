import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/heart_rate_data.dart';

class AlertsTab extends StatefulWidget {
  const AlertsTab({Key? key}) : super(key: key);

  @override
  State<AlertsTab> createState() => _AlertsTabState();
}

class _AlertsTabState extends State<AlertsTab> {
  String _selectedFilter = "Todas";
  final _dbService = DatabaseService();
  List<CardiacAlert> _alerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final alerts = await _dbService.getAlerts();
      setState(() {
        _alerts = alerts;
      });
    } catch (e) {
      debugPrint("Error al cargar alertas: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<CardiacAlert> _getFilteredAlerts() {
    if (_selectedFilter == "Todas") return _alerts;
    if (_selectedFilter == "Críticas") {
      return _alerts.where((a) => a.type == "critica").toList();
    }
    // Informativas + Normales
    return _alerts.where((a) => a.type == "informativa" || a.type == "normal").toList();
  }

  String _formatTime(DateTime dt) {
    String hour = dt.hour.toString().padLeft(2, '0');
    String minute = dt.minute.toString().padLeft(2, '0');
    String period = dt.hour >= 12 ? "p. m." : "a. m.";
    int displayHour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    return "${displayHour.toString().padLeft(2, '0')}:$minute $period";
  }

  String _formatDate(DateTime dt) {
    String day = dt.day.toString().padLeft(2, '0');
    String month = dt.month.toString().padLeft(2, '0');
    return "$day/$month/${dt.year}";
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _getFilteredAlerts();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título e Icono de búsqueda/filtro
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Alertas",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.filter_list, color: Colors.greenAccent),
                onPressed: _loadAlerts,
                tooltip: "Actualizar",
              ),
            ],
          ),
        ),

        // Filtros (Todas, Críticas, Informativas)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Row(
            children: [
              _buildFilterButton("Todas"),
              const SizedBox(width: 10),
              _buildFilterButton("Críticas"),
              const SizedBox(width: 10),
              _buildFilterButton("Informativas"),
            ],
          ),
        ),
        const SizedBox(height: 15),

        // Lista de alertas
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.greenAccent))
              : filteredList.isEmpty
                  ? Center(
                      child: Text(
                        "No hay alertas registradas",
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final alert = filteredList[index];
                        return _buildAlertCard(alert);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildFilterButton(String label) {
    final isActive = _selectedFilter == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = label;
          });
        },
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? Colors.green : const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isActive ? Colors.green : Colors.grey[850]!),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlertCard(CardiacAlert alert) {
    Color cardBorderColor;
    Color iconColor;
    Color iconBgColor;
    IconData icon;

    switch (alert.type) {
      case "critica":
        cardBorderColor = Colors.redAccent.withOpacity(0.3);
        iconColor = Colors.white;
        iconBgColor = Colors.redAccent;
        icon = Icons.favorite;
        break;
      case "informativa":
        cardBorderColor = Colors.amberAccent.withOpacity(0.3);
        iconColor = Colors.white;
        iconBgColor = Colors.amber;
        icon = Icons.warning;
        break;
      case "normal":
      default:
        cardBorderColor = Colors.greenAccent.withOpacity(0.3);
        iconColor = Colors.white;
        iconBgColor = Colors.green;
        icon = Icons.check;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: cardBorderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icono circular izquierdo
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),

          // Texto descriptivo de la alerta
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${_formatDate(alert.timestamp)} - ${_formatTime(alert.timestamp)}",
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  alert.description,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          
          // Flecha de detalle
          const Center(
            child: Icon(
              Icons.chevron_right,
              color: Colors.grey,
              size: 24,
            ),
          )
        ],
      ),
    );
  }
}
