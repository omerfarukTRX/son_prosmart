import 'package:flutter/material.dart';
import 'package:prosmart/models/proje_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProjeForm extends StatefulWidget {
  final ProjeModel proje;
  final Function(ProjeModel)? onSaved;
  final GlobalKey<FormState>? formKey;
  final PageController? pageController;
  final GlobalKey<ProjeFormState>? projeFormKey;

  const ProjeForm({
    required this.proje,
    this.onSaved,
    this.formKey,
    this.pageController,
    this.projeFormKey,
    super.key,
  });

  @override
  State<ProjeForm> createState() => ProjeFormState();
}

class ProjeFormState extends State<ProjeForm> {
  late final GlobalKey<FormState> _formKey;
  late TextEditingController _unvanController;
  late TextEditingController _adresController;
  late TextEditingController _ibanController;
  late TextEditingController _vergiController;
  late int _blokSayisi;
  late int _bolumSayisi;
  late ProjeTipi _projeTipi;

  @override
  void initState() {
    super.initState();
    _formKey = widget.formKey ?? GlobalKey<FormState>();

    _unvanController = TextEditingController(text: widget.proje.unvan);
    _adresController = TextEditingController(text: widget.proje.adres);
    _ibanController = TextEditingController(text: widget.proje.ibanNo);
    _vergiController = TextEditingController(text: widget.proje.vergiNo);
    _blokSayisi = widget.proje.blokSayisi;
    _bolumSayisi = widget.proje.bagimsizBolumSayisi;
    _projeTipi = widget.proje.tip;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _unvanController,
            decoration: const InputDecoration(labelText: "Proje Ünvanı"),
            validator: (value) => value!.isEmpty ? "Zorunlu alan" : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _adresController,
            decoration: const InputDecoration(labelText: "Adres"),
            maxLines: 3,
            validator: (value) => value!.isEmpty ? "Zorunlu alan" : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<ProjeTipi>(
            value: _projeTipi,
            items: ProjeTipi.values.map((tip) {
              return DropdownMenuItem(
                value: tip,
                child: Text(tip.toString().split('.').last),
              );
            }).toList(),
            onChanged: (value) => setState(() => _projeTipi = value!),
            decoration: const InputDecoration(labelText: "Proje Tipi"),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: _blokSayisi.toString(),
                  decoration: const InputDecoration(labelText: "Blok Sayısı"),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => setState(() {
                    _blokSayisi = int.tryParse(value) ?? 0;
                  }),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  initialValue: _bolumSayisi.toString(),
                  decoration: const InputDecoration(labelText: "Bölüm Sayısı"),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => setState(() {
                    _bolumSayisi = int.tryParse(value) ?? 0;
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _ibanController,
            decoration: const InputDecoration(labelText: "IBAN No"),
            validator: (value) => value!.isEmpty ? "Zorunlu alan" : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _vergiController,
            decoration: const InputDecoration(labelText: "Vergi No"),
            validator: (value) => value!.isEmpty ? "Zorunlu alan" : null,
          ),
        ],
      ),
    );
  }

  ProjeModel getUpdatedModel() {
    // Mevcut modeli copyWith kullanarak güncelleyelim
    return widget.proje.copyWith(
      unvan: _unvanController.text,
      adres: _adresController.text,
      tip: _projeTipi,
      blokSayisi: _blokSayisi,
      bagimsizBolumSayisi: _bolumSayisi,
      ibanNo: _ibanController.text,
      vergiNo: _vergiController.text,
      guncellemeTarihi: Timestamp.now(),
    );
  }

  // Form değerlendirmesi ve kaydetme
  bool saveForm() {
    if (_formKey.currentState!.validate()) {
      if (widget.onSaved != null) {
        widget.onSaved!(getUpdatedModel());
      }
      return true;
    }
    return false;
  }

  @override
  void dispose() {
    _unvanController.dispose();
    _adresController.dispose();
    _ibanController.dispose();
    _vergiController.dispose();
    super.dispose();
  }
}
