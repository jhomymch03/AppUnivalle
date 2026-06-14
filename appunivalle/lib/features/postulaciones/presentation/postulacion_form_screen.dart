// lib/features/postulaciones/presentation/postulacion_form_screen.dart
/// Formulario de postulacion (Fase C). Crea si no hay activa, edita si la hay,
/// y permite enviar a secretaria. Replica `Postulacion.vue` del web: datos del
/// proyecto, tutor interno/externo, declaracion de veracidad y readonly segun
/// estado.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/di/app_dependencies.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/form_section.dart';
import '../../archivos/presentation/archivo_upload_field.dart';
import '../../notificaciones/presentation/notifications_bell.dart';
import '../../shell/presentation/app_drawer.dart';
import '../application/postulacion_actual.dart';
import '../data/models/postulacion.dart';
import '../data/models/postulacion_form_data.dart';
import '../data/models/tipo_tutor.dart';
import 'widgets/estado_badge.dart';
import 'widgets/estado_banner.dart';
import 'widgets/stepper_proceso.dart';

class PostulacionFormScreen extends StatefulWidget {
  const PostulacionFormScreen({super.key});

  @override
  State<PostulacionFormScreen> createState() => _PostulacionFormScreenState();
}

class _PostulacionFormScreenState extends State<PostulacionFormScreen> {
  late Future<void> _carga;

  Postulacion? _activa;
  List<String> _modalidades = const [];
  List<({String id, String nombre})> _tutores = const [];

  final _form = PostulacionFormData();
  Map<String, String> _errores = const {};
  bool _declaracion = false;
  bool _guardando = false;
  bool _enviando = false;

  bool get _editable => _activa == null || esEditable(_activa!.estado);

  @override
  void initState() {
    super.initState();
    _carga = _cargar();
  }

  Future<void> _cargar() async {
    // Capture deps before the first await to avoid use_build_context_synchronously.
    final deps = context.read<AppDependencies>();
    final lista = await deps.postulacionesRepository.listarMias();
    final mods = await deps.modalidadesRepository.listar();
    final ops = await deps.tutoresRepository.listarOpcionesTutor();

    _modalidades = mods;
    _tutores =
        ops.map((o) => (id: o.docenteId, nombre: o.nombreCompleto)).toList();
    _activa = pickActiva(lista);

    final a = _activa;
    if (a != null) {
      // Si la modalidad guardada ya no figura en el catalogo activo, la
      // agregamos para que el Dropdown no falle (su value debe existir entre
      // los items).
      if (a.modalidad.isNotEmpty && !_modalidades.contains(a.modalidad)) {
        _modalidades = [..._modalidades, a.modalidad];
      }
      _form
        ..titulo = a.titulo
        ..descripcion = a.descripcion
        ..modalidad = a.modalidad
        ..tipoTutor = a.tipoTutor
        ..tutorDocenteId = a.tutorDocenteId
        ..tutorExternoNombres = a.tutorExternoNombres
        ..tutorExternoApellidos = a.tutorExternoApellidos
        ..tutorExternoCi = a.tutorExternoCi
        ..tutorExternoEmail = a.tutorExternoEmail
        ..tutorExternoTelefono = a.tutorExternoTelefono
        ..tutorExternoCvArchivoId = a.tutorExternoCvArchivoId
        ..tutorExternoTituloArchivoId = a.tutorExternoTituloArchivoId;
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _guardar() async {
    setState(() => _errores = _form.validar());
    if (_errores.isNotEmpty) return;

    setState(() => _guardando = true);
    // Capture repo before the first await to avoid use_build_context_synchronously.
    final repo = context.read<AppDependencies>().postulacionesRepository;
    try {
      if (_activa == null) {
        final creada = await repo.crear(_form.toJson());
        if (!mounted) return;
        setState(() => _activa = creada);
        _snack('Postulación creada (borrador).');
      } else {
        final editada = await repo.editar(_activa!.id, _form.toJson());
        if (!mounted) return;
        setState(() => _activa = editada);
        _snack('Cambios guardados.');
      }
    } on ApiException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _enviar() async {
    final a = _activa;
    if (a == null) return;
    setState(() => _enviando = true);
    // Capture repo before the first await to avoid use_build_context_synchronously.
    final repo = context.read<AppDependencies>().postulacionesRepository;
    try {
      final enviada = await repo.enviarASecretaria(a.id);
      if (!mounted) return;
      setState(() => _activa = enviada);
      _snack('Postulación enviada a secretaría.');
    } on ApiException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(_activa == null ? 'Nueva postulación' : 'Mi postulación'),
        actions: const [NotificationsBell()],
      ),
      body: FutureBuilder<void>(
        future: _carga,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  snapshot.error is ApiException
                      ? (snapshot.error as ApiException).message
                      : 'No se pudo cargar el formulario.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return _buildForm(context);
        },
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final a = _activa;
    final puedeEnviar = a != null && esEditable(a.estado) && _declaracion;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (a != null) ...[
          Row(
            children: [
              Expanded(
                child: Text(a.codigoCorto,
                    style: Theme.of(context).textTheme.bodySmall),
              ),
              EstadoBadge(estado: a.estado),
            ],
          ),
          const SizedBox(height: 8),
          EstadoBanner(estado: a.estado, motivoRechazo: a.motivoRechazo),
          const SizedBox(height: 8),
          StepperProceso(estado: a.estado),
          const SizedBox(height: 16),
        ],

        // --- Datos del proyecto ---
        FormSection(
          icon: Icons.description_outlined,
          titulo: 'Datos del proyecto',
          children: [
            TextFormField(
              initialValue: _form.titulo,
              enabled: _editable,
              maxLength: 500,
              buildCounter: (_,
                      {required currentLength,
                      required isFocused,
                      maxLength}) =>
                  null,
              decoration: InputDecoration(
                labelText: 'Título del proyecto',
                errorText: _errores['titulo'],
              ),
              onChanged: (v) => _form.titulo = v,
            ),
            DropdownButtonFormField<String>(
              initialValue: _form.modalidad.isEmpty ? null : _form.modalidad,
              decoration: InputDecoration(
                labelText: 'Modalidad',
                errorText: _errores['modalidad'],
              ),
              items: [
                for (final m in _modalidades)
                  DropdownMenuItem(value: m, child: Text(m)),
              ],
              onChanged: _editable ? (v) => _form.modalidad = v ?? '' : null,
            ),
            TextFormField(
              initialValue: _form.descripcion,
              enabled: _editable,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Descripción y justificación',
                errorText: _errores['descripcion'],
              ),
              onChanged: (v) => _form.descripcion = v,
            ),
          ],
        ),
        const SizedBox(height: 20),

        // --- Tutor propuesto ---
        FormSection(
          icon: Icons.person_outline,
          titulo: 'Tutor propuesto',
          children: [
            RadioGroup<TipoTutor>(
              groupValue: _form.tipoTutor,
              onChanged: _editable
                  ? (v) {
                      if (v != null) setState(() => _form.tipoTutor = v);
                    }
                  : (_) {},
              child: const Column(
                children: [
                  RadioListTile<TipoTutor>(
                    value: TipoTutor.interno,
                    title: Text('Tutor interno'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  RadioListTile<TipoTutor>(
                    value: TipoTutor.externo,
                    title: Text('Tutor externo'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            if (_form.tipoTutor == TipoTutor.interno)
              _buildTutorInterno(context)
            else
              _buildTutorExterno(context),
          ],
        ),

        const SizedBox(height: 20),

        // --- Declaracion + acciones ---
        if (a != null)
          CheckboxListTile(
            value: _declaracion,
            onChanged: _editable
                ? (v) => setState(() => _declaracion = v ?? false)
                : null,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text(
                'Declaro que la información proporcionada es veraz y correcta.'),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: SecondaryButton(
                label: _guardando
                    ? 'Guardando...'
                    : (a == null ? 'Crear borrador' : 'Guardar cambios'),
                onPressed: (!_editable || _guardando) ? null : _guardar,
              ),
            ),
            if (a != null) ...[
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  label: _enviando ? 'Enviando...' : 'Enviar a secretaría',
                  onPressed: (!puedeEnviar || _enviando) ? null : _enviar,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildTutorInterno(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: _form.tutorDocenteId,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Tutor (de la lista de habilitados)',
        errorText: _errores['tutorDocenteId'],
      ),
      items: [
        for (final t in _tutores)
          DropdownMenuItem(value: t.id, child: Text(t.nombre)),
      ],
      onChanged: _editable ? (v) => _form.tutorDocenteId = v : null,
    );
  }

  Widget _buildTutorExterno(BuildContext context) {
    const gap = SizedBox(height: 16);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          initialValue: _form.tutorExternoNombres,
          enabled: _editable,
          decoration: InputDecoration(
            labelText: 'Nombres',
            errorText: _errores['tutorExternoNombres'],
          ),
          onChanged: (v) => _form.tutorExternoNombres = v,
        ),
        gap,
        TextFormField(
          initialValue: _form.tutorExternoApellidos,
          enabled: _editable,
          decoration: InputDecoration(
            labelText: 'Apellidos',
            errorText: _errores['tutorExternoApellidos'],
          ),
          onChanged: (v) => _form.tutorExternoApellidos = v,
        ),
        gap,
        TextFormField(
          initialValue: _form.tutorExternoCi,
          enabled: _editable,
          decoration: const InputDecoration(labelText: 'CI (opcional)'),
          onChanged: (v) => _form.tutorExternoCi = v,
        ),
        gap,
        TextFormField(
          initialValue: _form.tutorExternoEmail,
          enabled: _editable,
          decoration: InputDecoration(
            labelText: 'Email (opcional)',
            errorText: _errores['tutorExternoEmail'],
          ),
          onChanged: (v) => _form.tutorExternoEmail = v,
        ),
        gap,
        TextFormField(
          initialValue: _form.tutorExternoTelefono,
          enabled: _editable,
          decoration: const InputDecoration(labelText: 'Teléfono (opcional)'),
          onChanged: (v) => _form.tutorExternoTelefono = v,
        ),
        gap,
        ArchivoUploadField(
          label: 'CV del tutor (PDF)',
          archivoId: _form.tutorExternoCvArchivoId,
          enabled: _editable,
          onChanged: (id) => setState(() => _form.tutorExternoCvArchivoId = id),
        ),
        gap,
        ArchivoUploadField(
          label: 'Título académico (PDF)',
          archivoId: _form.tutorExternoTituloArchivoId,
          enabled: _editable,
          onChanged: (id) =>
              setState(() => _form.tutorExternoTituloArchivoId = id),
        ),
      ],
    );
  }
}
