import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';
import '../../theme/app_theme.dart';
import '../../data/services/supabase_service.dart';

class DamageReportScreen extends StatefulWidget {
  final String taskId;
  final String? itemId;
  final String? sku;

  const DamageReportScreen({
    super.key,
    required this.taskId,
    this.itemId,
    this.sku,
  });

  @override
  State<DamageReportScreen> createState() => _DamageReportScreenState();
}

class _DamageReportScreenState extends State<DamageReportScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  final List<XFile> _images = [];
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;

  Future<void> _pickImage(ImageSource source) async {
    // Check Permissions
    PermissionStatus status;
    if (source == ImageSource.camera) {
      status = await Permission.camera.request();
    } else {
      // Para Android 13+ (Photos)
      if (Platform.isAndroid) {
        status = await Permission.photos.request();
        // Fallback para versões anteriores se photos retornar negado por ser API < 33
        if (status.isDenied) {
          status = await Permission.storage.request();
        }
      } else {
        status = await Permission.photos.request();
      }
    }

    if (status.isPermanentlyDenied) {
      if (mounted) {
        _showPermissionDialog();
      }
      return;
    }

    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Acesso negado. Para anexar fotos, autorize nas configurações.'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1200,
      );
      if (image != null) {
        setState(() {
          _images.add(image);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao acessar camera: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Permissão Necessária', style: TextStyle(color: AppTheme.goldPrimary)),
        content: const Text(
          'O acesso à câmera/galeria foi bloqueado permanentemente. Deseja abrir as configurações para autorizar?',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('CONFIGURAÇÕES'),
          ),
        ],
      ),
    );
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  Future<void> _submitReport() async {
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, descreva a avaria.'), backgroundColor: AppTheme.errorRed),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      List<String> imageUrls = [];
      
      // Upload images
      for (var image in _images) {
        final publicUrl = await SupabaseService.uploadArquivo(
          'avarias', 
          'tasks/${widget.taskId}', 
          File(image.path)
        );
        if (publicUrl != null) imageUrls.add(publicUrl);
      }

      final success = await SupabaseService.registrarAvaria(
        tarefaId: widget.taskId,
        itemId: widget.itemId,
        descricao: _descriptionController.text.trim(),
        fotos: imageUrls,
      );

      if (mounted) {
        setState(() => _isSubmitting = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Avaria registrada com sucesso!'), backgroundColor: AppTheme.successGreen),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao salvar no banco.'), backgroundColor: AppTheme.errorRed),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro crítico: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RELATAR AVARIA'),
        backgroundColor: AppTheme.darkBackground,
      ),
      body: Padding(
        padding: EdgeInsets.all(4.w),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.sku != null) ...[
                Text('ITEM:', style: TextStyle(color: AppTheme.goldPrimary, fontSize: 10.sp, fontWeight: FontWeight.bold)),
                Text(widget.sku!, style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.bold)),
                SizedBox(height: 2.h),
              ],
              
              Text('DESCRIÇÃO DA AVARIA', style: TextStyle(color: AppTheme.goldPrimary, fontSize: 10.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 1.h),
              TextField(
                controller: _descriptionController,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Descreva detalhadamente o problema encontrado...',
                  hintStyle: TextStyle(color: AppTheme.textMuted),
                  fillColor: AppTheme.surfaceDark,
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              
              SizedBox(height: 4.h),
              
              Text('FOTOS DA AVARIA (${_images.length}/5)', 
                style: TextStyle(color: AppTheme.goldPrimary, fontSize: 10.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 2.h),
              
              // Photo Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _images.length < 5 ? _images.length + 1 : 5,
                itemBuilder: (context, index) {
                  if (index == _images.length && _images.length < 5) {
                    return InkWell(
                      onTap: () => _showPickerOptions(),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceDark,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.5)),
                        ),
                        child: const Icon(Icons.add_a_photo, color: AppTheme.goldPrimary),
                      ),
                    );
                  }
                  
                  return Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: FileImage(File(_images[index].path)),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: InkWell(
                          onTap: () => _removeImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(color: AppTheme.errorRed, shape: BoxShape.circle),
                            child: const Icon(Icons.close, size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              
              SizedBox(height: 6.h),
              
              SizedBox(
                width: double.infinity,
                height: 8.h,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReport,
                  child: _isSubmitting 
                    ? const CircularProgressIndicator(color: AppTheme.darkBackground)
                    : const Text('ENVIAR RELATÓRIO', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppTheme.goldPrimary),
                title: const Text('Câmera', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppTheme.goldPrimary),
                title: const Text('Galeria', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
