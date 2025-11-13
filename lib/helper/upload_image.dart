import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';


Future<String?> uploadImageToSupabase({
  required String role,
  required String uid,
  required String type,
  required XFile? file,
}) async {
  try {
    // Expect caller to provide an already picked file (do not open picker here)
    if (file == null) return null;

    final f = File(file.path);

    // Ensure single .jpg extension
    final normalizedType = type.toLowerCase().endsWith('.jpg') ? type.substring(0, type.length - 4) : type;
    final filePath = '$role/$uid/${uid}-$normalizedType.jpg';

    final client = Supabase.instance.client;

    // Upload file to Supabase bucket
    await client.storage
        .from('app-images')
        .upload(filePath, f, fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'));

    // Get the public URL
    final publicUrl = client.storage
        .from('app-images')
        .getPublicUrl(filePath);

    return publicUrl;
  } catch (e) {
    print('Error uploading image: $e');
    return null;
  }
}
