import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lifeline_nexus/models/medical_profile.dart';
import 'package:lifeline_nexus/providers/vault_provider.dart';
import 'package:lifeline_nexus/providers/auth_provider.dart';
import 'package:lifeline_nexus/ui/theme/app_theme.dart';
import 'package:flutter/services.dart';                                   


class MedicalVaultScreen extends ConsumerStatefulWidget {
  const MedicalVaultScreen({super.key});

  @override
  ConsumerState<MedicalVaultScreen> createState() => _MedicalVaultScreenState();
}

class _MedicalVaultScreenState extends ConsumerState<MedicalVaultScreen> {
  final _formKey = GlobalKey<FormState>();
  
  String _selectedBloodType = 'Unknown';
  final List<String> _medications = [];
  final List<String> _allergies = [];
  final List<String> _chronicIllnesses = [];
  final List<String> _specialConditions = [];
  final List<EmergencyContact> _emergencyContacts = [];
  final List<String> _documentUrls = [];

  final TextEditingController _medicationController = TextEditingController();
  final TextEditingController _allergyController = TextEditingController();

  final List<String> _bloodTypes = ['Unknown', 'A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];
  final List<String> _sexes = ['Unknown', 'Male', 'Female', 'Other'];

  String _dob = '';
  String _biologicalSex = 'Unknown';
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  bool _organDonor = false;

  bool _isSaving = false;
  bool _isPopulated = false;

  @override
  void dispose() {
    _medicationController.dispose();
    _allergyController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _populateFromProfile(MedicalProfile profile) {
    if (_isPopulated) return;

    setState(() {
      _selectedBloodType = _bloodTypes.contains(profile.demographics.bloodType) ? profile.demographics.bloodType : 'Unknown';
      _dob = profile.demographics.dob;
      _biologicalSex = _sexes.contains(profile.demographics.biologicalSex) ? profile.demographics.biologicalSex : 'Unknown';
      _heightController.text = profile.demographics.heightCm > 0 ? profile.demographics.heightCm.toString() : '';
      _weightController.text = profile.demographics.weightKg > 0 ? profile.demographics.weightKg.toString() : '';
      _organDonor = profile.demographics.organDonor;

      _medications.clear(); 
      _medications.addAll(profile.activeMedications.map((m) => m.name));
      
      _allergies.clear(); 
      _allergies.addAll(profile.allergies.map((a) => a.allergen));
      
      _chronicIllnesses.clear(); 
      _chronicIllnesses.addAll(profile.chronicConditions);
      
      _emergencyContacts.clear(); 
      _emergencyContacts.addAll(profile.emergencyContacts);
      
      _documentUrls.clear(); 
      _documentUrls.addAll(profile.documentUrls);
      _isPopulated = true;
    });
  }

  Future<void> _pickAndUploadDocument() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null && mounted) {
      HapticFeedback.mediumImpact();
      final user = ref.read(authStateProvider).value;
      final vaultService = ref.read(medicalVaultServiceProvider);

      if (user != null) {
        final url = await vaultService.uploadDocument(user.uid, File(pickedFile.path));
        if (url != null && mounted) {
          setState(() => _documentUrls.add(url));
        }
      }
    }
  }

  void _addContactDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final relationController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 40),
        decoration: const BoxDecoration(
          color: Color(0xFF0F0F0F),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('NEW GUARDIAN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2.0, fontSize: 16)),
            const SizedBox(height: 32),
            _buildDialogField(nameController, 'FULL NAME', Icons.person_outline),
            const SizedBox(height: 16),
            _buildDialogField(phoneController, 'PHONE NUMBER', Icons.phone_outlined, keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
            _buildDialogField(relationController, 'RELATION', Icons.link_rounded),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: () {
                if (nameController.text.isNotEmpty) {
                  setState(() {
                    _emergencyContacts.add(EmergencyContact(
                      name: nameController.text.trim(),
                      phone: phoneController.text.trim(),
                      relation: relationController.text.trim(),
                    ));
                  });
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: AppTheme.accentCyan,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text('ADD TO VAULT', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, letterSpacing: 1.0, fontSize: 12)),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogField(TextEditingController controller, String label, IconData icon, {TextInputType? keyboardType}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(5)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          icon: Icon(icon, color: Colors.white38, size: 20),
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white24, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.0),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    HapticFeedback.heavyImpact();
    setState(() => _isSaving = true);
    final user = ref.read(authStateProvider).value;
    final vaultService = ref.read(medicalVaultServiceProvider);

    if (user != null) {
      final profile = MedicalProfile(
        uid: user.uid,
        lastUpdated: DateTime.now(),
        demographics: Demographics(
          dob: _dob,
          biologicalSex: _biologicalSex,
          bloodType: _selectedBloodType,
          heightCm: double.tryParse(_heightController.text) ?? 0,
          weightKg: double.tryParse(_weightController.text) ?? 0,
          organDonor: _organDonor,
        ),
        activeMedications: _medications.map((m) => Medication(name: m, dosage: '', frequency: '')).toList(),
        allergies: _allergies.map((a) => Allergy(allergen: a, reaction: '', severity: 'LOW')).toList(),
        chronicConditions: _chronicIllnesses,
        specialStatus: SpecialStatus(isPregnant: false, mobilityIssues: false),
        emergencyContacts: _emergencyContacts,
        documentUrls: _documentUrls,
      );

      try {
        await vaultService.saveProfile(profile);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppTheme.accentCyan,
              content: const Text('VAULT SYNCHRONIZED', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 11)),
            ),
          );
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(medicalProfileProvider);

    ref.listen(medicalProfileProvider, (previous, next) {
      if (next.hasValue && next.value != null) {
        _populateFromProfile(next.value!);
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: profileState.when(
        data: (_) => _buildForm(),
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.accentCyan)),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.white38))),
      ),
      bottomNavigationBar: _buildBottomAction(),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withAlpha(0), Colors.black],
        ),
      ),
      child: GestureDetector(
        onTap: _isSaving ? null : _saveProfile,
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.white.withAlpha(20), blurRadius: 40)],
          ),
          child: Center(
            child: _isSaving
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3))
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shield_rounded, color: Colors.black, size: 20),
                      SizedBox(width: 12),
                      Text('SAVE TO SECURE VAULT', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, letterSpacing: 1.0, fontSize: 13)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          expandedHeight: 180.0,
          pinned: true,
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            title: const Text(
              'MEDICAL VALET',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 4.0, color: Colors.white, fontSize: 14),
            ),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppTheme.accentCyan.withAlpha(30), Colors.black],
                ),
              ),
              child: const Center(
                child: Icon(Icons.lock_person_rounded, color: Colors.white10, size: 100),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSectionHeader('VITAL CONFIGURATION', Icons.bolt_rounded, null),
                  
                  // Demographic Grid (DOB, Sex, Height, Weight)
                  _buildDemographicGrid(),
                  
                  const SizedBox(height: 24),
                  
                  // Blood Type Selector
                  _buildSectionLabel('BLOOD TYPE'),
                  const SizedBox(height: 12),
                  _buildBloodTypeSelector(),
                  
                  const SizedBox(height: 24),
                  
                  // Organ Donor Toggle
                  _buildOrganDonorToggle(),
                  
                  const SizedBox(height: 48),
                  _buildSectionHeader('ACTIVE MEDICATIONS', Icons.medication_rounded, null),
                  _buildInputGroup(_medicationController, 'e.g., Insulin, Aspirin...', _medications),
                  
                  const SizedBox(height: 48),
                  _buildSectionHeader('CRITICAL ALLERGIES', Icons.warning_rounded, null),
                  _buildInputGroup(_allergyController, 'e.g., Peanuts, Penicillin...', _allergies),
                  
                  const SizedBox(height: 48),
                  _buildSectionHeader('GUARDIAN CONTACTS', Icons.contact_emergency_rounded, _addContactDialog),
                  if (_emergencyContacts.isEmpty)
                    _buildEmptyState('No emergency guardians linked.')
                  else
                    ..._emergencyContacts.map((c) => _buildContactTile(c)),
                    
                  const SizedBox(height: 48),
                  _buildSectionHeader('MEDICAL RECORDS', Icons.description_rounded, _pickAndUploadDocument),
                  if (_documentUrls.isEmpty)
                    _buildEmptyState('No clinical records uploaded.')
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1,
                      ),
                      itemCount: _documentUrls.length,
                      itemBuilder: (context, index) => _buildDocumentThumbnail(_documentUrls[index]),
                    ),
                  
                  const SizedBox(height: 140),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBloodTypeSelector() {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _bloodTypes.length,
        itemBuilder: (context, index) {
          final type = _bloodTypes[index];
          final isSelected = _selectedBloodType == type;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedBloodType = type);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : const Color(0xFF0F0F0F),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSelected ? Colors.white : Colors.white.withAlpha(10)),
              ),
              child: Center(
                child: Text(
                  type,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white60,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white24,
        fontWeight: FontWeight.w900,
        fontSize: 10,
        letterSpacing: 2.0,
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, VoidCallback? onAdd) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppTheme.accentCyan.withAlpha(20), shape: BoxShape.circle),
            child: Icon(icon, size: 14, color: AppTheme.accentCyan),
          ),
          const SizedBox(width: 14),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2.5, color: Colors.white, fontSize: 10)),
          const Spacer(),
          if (onAdd != null)
            IconButton(
              onPressed: onAdd,
              icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.accentCyan, size: 24),
            ),
        ],
      ),
    );
  }

  Widget _buildDemographicGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildDatePicker()),
            const SizedBox(width: 12),
            Expanded(child: _buildSexSelector()),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildNumericField(_heightController, 'HEIGHT (CM)', Icons.height_rounded)),
            const SizedBox(width: 12),
            Expanded(child: _buildNumericField(_weightController, 'WEIGHT (KG)', Icons.monitor_weight_outlined)),
          ],
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AppTheme.accentCyan,
                onPrimary: Colors.black,
                surface: Color(0xFF0F0F0F),
              ),
            ),
            child: child!,
          ),
        );
        if (date != null) {
          setState(() => _dob = date.toString().split(' ').first);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0F0F0F),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withAlpha(5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('DATE OF BIRTH', style: TextStyle(color: Colors.white24, fontWeight: FontWeight.w900, fontSize: 8, letterSpacing: 1.0)),
            const SizedBox(height: 4),
            Text(_dob.isEmpty ? 'SELECT' : _dob, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildSexSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(5)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _biologicalSex,
          dropdownColor: const Color(0xFF0F0F0F),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white24),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
          items: _sexes.map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase()))).toList(),
          onChanged: (val) => setState(() => _biologicalSex = val!),
        ),
      ),
    );
  }

  Widget _buildNumericField(TextEditingController controller, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(5)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white24, fontWeight: FontWeight.w900, fontSize: 8, letterSpacing: 1.0),
          border: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildOrganDonorToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: _organDonor ? AppTheme.accentCyan.withAlpha(10) : const Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _organDonor ? AppTheme.accentCyan : Colors.white.withAlpha(5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.favorite_rounded, color: AppTheme.accentCyan, size: 18),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ORGAN DONOR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.0)),
                Text('Consent to organ donation', style: TextStyle(color: Colors.white24, fontSize: 9)),
              ],
            ),
          ),
          Switch(
            value: _organDonor,
            activeColor: AppTheme.accentCyan,
            onChanged: (val) => setState(() => _organDonor = val),
          ),
        ],
      ),
    );
  }

  Widget _buildInputGroup(TextEditingController controller, String hint, List<String> items) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F0F),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withAlpha(5)),
          ),
          child: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white12, fontSize: 14),
              border: InputBorder.none,
              suffixIcon: IconButton(
                icon: const Icon(Icons.add_rounded, color: AppTheme.accentCyan),
                onPressed: () {
                  if (controller.text.trim().isNotEmpty) {
                    HapticFeedback.lightImpact();
                    setState(() => items.add(controller.text.trim()));
                    controller.clear();
                  }
                },
              ),
            ),
            onSubmitted: (val) {
              if (val.trim().isNotEmpty) {
                HapticFeedback.lightImpact();
                setState(() => items.add(val.trim()));
                controller.clear();
              }
            },
          ),
        ),
        if (items.isNotEmpty) ...[
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items.map((item) => _buildChip(item, () => setState(() => items.remove(item)))).toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildChip(String text, VoidCallback onDelete) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onDelete,
            child: const Icon(Icons.close_rounded, color: Colors.white24, size: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildContactTile(EmergencyContact contact) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withAlpha(5)),
      ),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: const BoxDecoration(color: Colors.white10, shape: BoxShape.circle),
            child: const Center(child: Icon(Icons.person_rounded, color: Colors.white, size: 20)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(contact.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                const SizedBox(height: 4),
                Text('${contact.relation} • ${contact.phone}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _emergencyContacts.remove(contact)),
            icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.white12, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentThumbnail(String url) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(5)),
      ),
      child: Stack(
        children: [
          const Center(child: Icon(Icons.insert_drive_file_rounded, color: Colors.white24, size: 32)),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => setState(() => _documentUrls.remove(url)),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded, color: Colors.white, size: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withAlpha(5), style: BorderStyle.none),
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: Colors.white12, fontStyle: FontStyle.italic, fontSize: 13, letterSpacing: 0.5),
        ),
      ),
    );
  }
}
