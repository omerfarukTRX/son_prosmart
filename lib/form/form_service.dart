import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:prosmart/form/form_element_model.dart';
import 'dart:typed_data';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:uuid/uuid.dart';

class FormService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Koleksiyon referansları
  CollectionReference get _formsCollection => _firestore.collection('forms');

  // Form oluşturma
  Future<String> createForm(DynamicForm form) async {
    try {
      // Form map'e çevrilir
      final formMap = form.toMap();

      // Firebase'e yazma
      final docRef = await _formsCollection.add(formMap);

      // Form URL ve QR kod URL'lerini oluştur
      final formId = docRef.id;
      final formUrl = await _generateFormUrl(formId);
      final qrCodeUrl = await _generateAndUploadQrCode(formId, formUrl);

      // Form URL ve QR kod URL'lerini güncelle
      await docRef.update({
        'formUrl': formUrl,
        'qrCodeUrl': qrCodeUrl,
      });

      return formId;
    } catch (e) {
      throw Exception('Form oluşturma hatası: $e');
    }
  }

  // Form güncelleme
  Future<void> updateForm(DynamicForm form) async {
    try {
      // QR kodları yeniden oluşturmayalım
      final formMap = form.toMap();
      formMap.remove('qrCodeUrl');
      formMap.remove('formUrl');

      await _formsCollection.doc(form.id).update(formMap);
    } catch (e) {
      throw Exception('Form güncelleme hatası: $e');
    }
  }

  // Form silme
  Future<void> deleteForm(String formId) async {
    try {
      // Form yanıtlarını da sil
      final responsesSnapshot =
          await _formsCollection.doc(formId).collection('responses').get();

      final batch = _firestore.batch();

      // Yanıtları batch ile sil
      for (var doc in responsesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Ana form belgesini de sil
      batch.delete(_formsCollection.doc(formId));

      // Batch işlemini uygula
      await batch.commit();

      // QR kod resmini sil
      try {
        await _storage.ref('qr_codes/$formId.png').delete();
      } catch (_) {
        // QR kod bulunamadıysa hata verme
      }
    } catch (e) {
      throw Exception('Form silme hatası: $e');
    }
  }

  // Form getirme
  Future<DynamicForm?> getForm(String formId) async {
    try {
      final doc = await _formsCollection.doc(formId).get();

      if (!doc.exists) {
        return null;
      }

      return DynamicForm.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      throw Exception('Form getirme hatası: $e');
    }
  }

  // Proje için tüm formları getirme
  Future<List<DynamicForm>> getFormsByProject(String projectId) async {
    try {
      final querySnapshot = await _formsCollection
          .where('projectId', isEqualTo: projectId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) =>
              DynamicForm.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Proje formlarını getirme hatası: $e');
    }
  }

  // Form yanıtı ekleme
  Future<String> submitFormResponse(FormResponse response) async {
    try {
      final responseMap = response.toMap();

      final docRef = await _formsCollection
          .doc(response.formId)
          .collection('responses')
          .add(responseMap);

      return docRef.id;
    } catch (e) {
      throw Exception('Form yanıtı gönderme hatası: $e');
    }
  }

  // Form yanıtlarını getirme
  Future<List<FormResponse>> getFormResponses(String formId) async {
    try {
      final querySnapshot = await _formsCollection
          .doc(formId)
          .collection('responses')
          .orderBy('submittedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => FormResponse.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Form yanıtlarını getirme hatası: $e');
    }
  }

  // Dosya yükleme
  Future<List<String>> uploadFormAttachments(
      String formId, String responseId, List<Uint8List> files) async {
    try {
      final List<String> urls = [];

      for (int i = 0; i < files.length; i++) {
        final file = files[i];
        final fileId = const Uuid().v4();
        final path = 'form_attachments/$formId/$responseId/$fileId';

        final uploadTask = _storage.ref(path).putData(
              file,
              SettableMetadata(contentType: 'application/octet-stream'),
            );

        final snapshot = await uploadTask;
        final url = await snapshot.ref.getDownloadURL();

        urls.add(url);
      }

      return urls;
    } catch (e) {
      throw Exception('Dosya yükleme hatası: $e');
    }
  }

  // Form URL'i oluşturma
  Future<String> _generateFormUrl(String formId) async {
    // Firebase Hosting kullanıldığı varsayımıyla
    const baseUrl = 'https://prosmart-app.web.app';
    return '$baseUrl/forms/$formId';
  }

  // QR kod oluşturma ve yükleme
  Future<String> _generateAndUploadQrCode(String formId, String formUrl) async {
    try {
      // QR kod oluştur
      final qrValidationResult = QrValidator.validate(
        data: formUrl,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
      );

      final qrCode = qrValidationResult.qrCode!;

      // QR kodu bir resim olarak render et
      final painter = QrPainter.withQr(
        qr: qrCode,
        color: const Color(0xFF000000),
        gapless: true,
        embeddedImageStyle: null,
        embeddedImage: null,
      );

      final imageSize = 200.0;

      // Burada düzeltme yaptık: Rect yerine Size kullanıyoruz
      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      // Size parametresi veriyoruz, Rect yerine
      painter.paint(canvas, Size(imageSize, imageSize));
      final picture = pictureRecorder.endRecording();

      final img = await picture.toImage(imageSize.toInt(), imageSize.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      // QR kodu Firebase Storage'a yükle
      final qrStoragePath = 'qr_codes/$formId.png';
      final uploadTask = _storage.ref(qrStoragePath).putData(
            pngBytes,
            SettableMetadata(contentType: 'image/png'),
          );

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('QR kod oluşturma hatası: $e');
    }
  }
}
