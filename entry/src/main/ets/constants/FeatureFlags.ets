export class FeatureFlags {
  // Release build keeps OCR entry but hides floating ball to reduce review permission scope.
  static readonly AUTO_BOOKKEEPING_VISIBLE: boolean = true;
  static readonly FLOATING_BALL_OCR_VISIBLE: boolean = false;
  // Notification/SMS capture stays hidden for release review because it needs higher-risk content access.
  static readonly NOTIFICATION_AUTO_CAPTURE_VISIBLE: boolean = false;
  // Manual Alipay CSV import uses the system document picker and needs no payment SDK permission.
  static readonly ALIPAY_BILL_IMPORT_VISIBLE: boolean = true;
}
