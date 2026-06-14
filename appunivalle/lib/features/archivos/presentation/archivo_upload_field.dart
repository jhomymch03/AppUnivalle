// lib/features/archivos/presentation/archivo_upload_field.dart
/// Campo para adjuntar un PDF: elige archivo (file_picker), lo sube
/// (`ArchivosRepository`) y reporta el id resultante via [onChanged]. Muestra
/// el estado (subiendo / listo / error) y permite quitarlo.
library;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/di/app_dependencies.dart';
import '../../../core/network/api_exception.dart';

class ArchivoUploadField extends StatefulWidget {
  const ArchivoUploadField({
    super.key,
    required this.label,
    required this.archivoId,
    required this.onChanged,
    this.enabled = true,
  });

  final String label;
  final String? archivoId;
  final ValueChanged<String?> onChanged;
  final bool enabled;

  @override
  State<ArchivoUploadField> createState() => _ArchivoUploadFieldState();
}

class _ArchivoUploadFieldState extends State<ArchivoUploadField> {
  bool _subiendo = false;
  String? _nombre;
  String? _error;

  Future<void> _elegir() async {
    setState(() => _error = null);
    final repo = context.read<AppDependencies>().archivosRepository;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null) return; // cancelado
    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) {
      setState(() => _error = 'No se pudo leer el archivo.');
      return;
    }

    setState(() {
      _subiendo = true;
      _nombre = file.name;
    });
    try {
      final subido = await repo.subir(bytes: bytes, nombre: file.name);
      if (!mounted) return;
      widget.onChanged(subido.id);
      setState(() => _subiendo = false);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _subiendo = false;
        _nombre = null;
        _error = e.message;
      });
    }
  }

  void _quitar() {
    setState(() {
      _nombre = null;
      _error = null;
    });
    widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final tieneArchivo = widget.archivoId != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        if (_subiendo)
          const Row(
            children: [
              SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 8),
              Text('Subiendo...'),
            ],
          )
        else if (tieneArchivo)
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
              const SizedBox(width: 6),
              Expanded(
                child: Text(_nombre ?? 'Archivo adjunto',
                    overflow: TextOverflow.ellipsis),
              ),
              if (widget.enabled)
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Quitar',
                  onPressed: _quitar,
                ),
            ],
          )
        else
          OutlinedButton.icon(
            onPressed: widget.enabled ? _elegir : null,
            icon: const Icon(Icons.upload_file),
            label: const Text('Adjuntar PDF'),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(_error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
      ],
    );
  }
}
