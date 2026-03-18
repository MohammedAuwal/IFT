class CloudinaryConfig {
  static const String cloudName = 'PUT_CLOUD_NAME_HERE';
  static const String uploadPreset = 'PUT_UNSIGNED_UPLOAD_PRESET_HERE';

  static String get uploadUrl =>
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload';
}
