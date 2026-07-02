import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @appName.
  ///
  /// In tr, this message translates to:
  /// **'Matchly'**
  String get appName;

  /// No description provided for @signIn.
  ///
  /// In tr, this message translates to:
  /// **'Giriş yap'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In tr, this message translates to:
  /// **'Hesap oluştur'**
  String get signUp;

  /// No description provided for @email.
  ///
  /// In tr, this message translates to:
  /// **'E-posta'**
  String get email;

  /// No description provided for @password.
  ///
  /// In tr, this message translates to:
  /// **'Şifre'**
  String get password;

  /// No description provided for @username.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı adı'**
  String get username;

  /// No description provided for @error.
  ///
  /// In tr, this message translates to:
  /// **'Bir hata oluştu'**
  String get error;

  /// No description provided for @loading.
  ///
  /// In tr, this message translates to:
  /// **'Yükleniyor...'**
  String get loading;

  /// No description provided for @active.
  ///
  /// In tr, this message translates to:
  /// **'Aktif'**
  String get active;

  /// No description provided for @won.
  ///
  /// In tr, this message translates to:
  /// **'Kazandı'**
  String get won;

  /// No description provided for @lost.
  ///
  /// In tr, this message translates to:
  /// **'Kaybetti'**
  String get lost;

  /// No description provided for @pending.
  ///
  /// In tr, this message translates to:
  /// **'Bekliyor'**
  String get pending;

  /// No description provided for @profile.
  ///
  /// In tr, this message translates to:
  /// **'Profil'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get settings;

  /// No description provided for @logout.
  ///
  /// In tr, this message translates to:
  /// **'Çıkış yap'**
  String get logout;

  /// No description provided for @darkMode.
  ///
  /// In tr, this message translates to:
  /// **'Karanlık mod'**
  String get darkMode;

  /// No description provided for @lightMode.
  ///
  /// In tr, this message translates to:
  /// **'Aydınlık mod'**
  String get lightMode;

  /// No description provided for @language.
  ///
  /// In tr, this message translates to:
  /// **'Dil'**
  String get language;

  /// No description provided for @notifications.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler'**
  String get notifications;

  /// No description provided for @statistics.
  ///
  /// In tr, this message translates to:
  /// **'İstatistikler'**
  String get statistics;

  /// No description provided for @coupons.
  ///
  /// In tr, this message translates to:
  /// **'Kuponlar'**
  String get coupons;

  /// No description provided for @activeCoupons.
  ///
  /// In tr, this message translates to:
  /// **'Aktif kuponlar'**
  String get activeCoupons;

  /// No description provided for @totalStake.
  ///
  /// In tr, this message translates to:
  /// **'Toplam bahis'**
  String get totalStake;

  /// No description provided for @totalPotential.
  ///
  /// In tr, this message translates to:
  /// **'Toplam beklenti'**
  String get totalPotential;

  /// No description provided for @authTagline.
  ///
  /// In tr, this message translates to:
  /// **'Kuponlarını hesabına kaydet.'**
  String get authTagline;

  /// No description provided for @usernameRequiredError.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı adı gerekli'**
  String get usernameRequiredError;

  /// No description provided for @emailPasswordRequiredError.
  ///
  /// In tr, this message translates to:
  /// **'E-posta ve şifre gerekli'**
  String get emailPasswordRequiredError;

  /// No description provided for @passwordMinLengthError.
  ///
  /// In tr, this message translates to:
  /// **'Şifre en az 8 karakter olmalı'**
  String get passwordMinLengthError;

  /// No description provided for @passwordNeedsDigitError.
  ///
  /// In tr, this message translates to:
  /// **'Şifre en az bir rakam içermeli'**
  String get passwordNeedsDigitError;

  /// No description provided for @passwordsDontMatchError.
  ///
  /// In tr, this message translates to:
  /// **'Şifreler eşleşmiyor'**
  String get passwordsDontMatchError;

  /// No description provided for @passwordConfirmHint.
  ///
  /// In tr, this message translates to:
  /// **'Şifre tekrar'**
  String get passwordConfirmHint;

  /// No description provided for @orDivider.
  ///
  /// In tr, this message translates to:
  /// **'veya'**
  String get orDivider;

  /// No description provided for @continueWithApple.
  ///
  /// In tr, this message translates to:
  /// **'Apple ile Devam Et'**
  String get continueWithApple;

  /// No description provided for @continueWithGoogle.
  ///
  /// In tr, this message translates to:
  /// **'Google ile Devam Et'**
  String get continueWithGoogle;

  /// No description provided for @noAccountSignUp.
  ///
  /// In tr, this message translates to:
  /// **'Hesabın yok mu? Kayıt ol'**
  String get noAccountSignUp;

  /// No description provided for @haveAccountSignIn.
  ///
  /// In tr, this message translates to:
  /// **'Zaten hesabın var mı? Giriş yap'**
  String get haveAccountSignIn;

  /// No description provided for @chooseUsernameTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı adı seç'**
  String get chooseUsernameTitle;

  /// No description provided for @chooseUsernameSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Bu ad profilinde görünecek.'**
  String get chooseUsernameSubtitle;

  /// No description provided for @usernameHintPlaceholder.
  ///
  /// In tr, this message translates to:
  /// **'kullanici_adi'**
  String get usernameHintPlaceholder;

  /// No description provided for @continueButton.
  ///
  /// In tr, this message translates to:
  /// **'Devam Et'**
  String get continueButton;

  /// No description provided for @usernameMinLengthError.
  ///
  /// In tr, this message translates to:
  /// **'En az 3 karakter olmalı'**
  String get usernameMinLengthError;

  /// No description provided for @ayarlarSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama tercihleri'**
  String get ayarlarSubtitle;

  /// No description provided for @sectionAccount.
  ///
  /// In tr, this message translates to:
  /// **'HESAP'**
  String get sectionAccount;

  /// No description provided for @sectionHistory.
  ///
  /// In tr, this message translates to:
  /// **'GEÇMİŞ'**
  String get sectionHistory;

  /// No description provided for @sectionGeneral.
  ///
  /// In tr, this message translates to:
  /// **'GENEL'**
  String get sectionGeneral;

  /// No description provided for @sectionData.
  ///
  /// In tr, this message translates to:
  /// **'VERİLER'**
  String get sectionData;

  /// No description provided for @sectionAbout.
  ///
  /// In tr, this message translates to:
  /// **'HAKKINDA'**
  String get sectionAbout;

  /// No description provided for @changeUsername.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı Adı Değiştir'**
  String get changeUsername;

  /// No description provided for @changePassword.
  ///
  /// In tr, this message translates to:
  /// **'Şifre Değiştir'**
  String get changePassword;

  /// No description provided for @couponHistory.
  ///
  /// In tr, this message translates to:
  /// **'Kupon Geçmişi'**
  String get couponHistory;

  /// No description provided for @couponHistorySubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Tamamlanan kuponları görüntüle'**
  String get couponHistorySubtitle;

  /// No description provided for @notificationsSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Kupon güncellemeleri'**
  String get notificationsSubtitle;

  /// No description provided for @darkThemeLabel.
  ///
  /// In tr, this message translates to:
  /// **'Karanlık Tema'**
  String get darkThemeLabel;

  /// No description provided for @darkThemeSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama görünümü'**
  String get darkThemeSubtitle;

  /// No description provided for @autoUpdateLabel.
  ///
  /// In tr, this message translates to:
  /// **'Otomatik Güncelleme'**
  String get autoUpdateLabel;

  /// No description provided for @autoUpdateSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Arka planda veri yenile'**
  String get autoUpdateSubtitle;

  /// No description provided for @dailyReportLabel.
  ///
  /// In tr, this message translates to:
  /// **'Gün Sonu Raporu'**
  String get dailyReportLabel;

  /// No description provided for @pickReportTimeHelp.
  ///
  /// In tr, this message translates to:
  /// **'Rapor saatini seç'**
  String get pickReportTimeHelp;

  /// No description provided for @clearDataLabel.
  ///
  /// In tr, this message translates to:
  /// **'Verileri Temizle'**
  String get clearDataLabel;

  /// No description provided for @clearDataSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Tüm kuponları sil'**
  String get clearDataSubtitle;

  /// No description provided for @deleteAccountLabel.
  ///
  /// In tr, this message translates to:
  /// **'Hesabı Sil'**
  String get deleteAccountLabel;

  /// No description provided for @deleteAccountSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Hesabını ve tüm verilerini kalıcı olarak sil'**
  String get deleteAccountSubtitle;

  /// No description provided for @deleteAccountConfirmTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hesabı Kalıcı Olarak Sil'**
  String get deleteAccountConfirmTitle;

  /// No description provided for @deleteAccountConfirmBody.
  ///
  /// In tr, this message translates to:
  /// **'Bu işlem geri alınamaz. Hesabın, tüm kuponların, yorumların ve verilerin kalıcı olarak silinecek.'**
  String get deleteAccountConfirmBody;

  /// No description provided for @deleteAccountConfirmButton.
  ///
  /// In tr, this message translates to:
  /// **'Evet, Hesabımı Sil'**
  String get deleteAccountConfirmButton;

  /// No description provided for @deleteAccountFailedMessage.
  ///
  /// In tr, this message translates to:
  /// **'Hesap silinemedi, lütfen tekrar dene'**
  String get deleteAccountFailedMessage;

  /// No description provided for @signOutLabel.
  ///
  /// In tr, this message translates to:
  /// **'Çıkış Yap'**
  String get signOutLabel;

  /// No description provided for @signOutSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Hesabından çıkış yap'**
  String get signOutSubtitle;

  /// No description provided for @signOutConfirmBody.
  ///
  /// In tr, this message translates to:
  /// **'Hesabından çıkmak istediğine emin misin?'**
  String get signOutConfirmBody;

  /// No description provided for @cancelLabel.
  ///
  /// In tr, this message translates to:
  /// **'İptal'**
  String get cancelLabel;

  /// No description provided for @saveLabel.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get saveLabel;

  /// No description provided for @okLabel.
  ///
  /// In tr, this message translates to:
  /// **'Tamam'**
  String get okLabel;

  /// No description provided for @legalInfoTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yasal Bilgi'**
  String get legalInfoTitle;

  /// No description provided for @legalInfoBody.
  ///
  /// In tr, this message translates to:
  /// **'Matchly bir bahis operatörü değildir. Bahis almaz, oran sunmaz, para veya bakiye işlemi yapmaz ve gerçek bir bahis hesabına bağlanmaz. Uygulamadaki tüm kupon bilgileri, kullanıcı tarafından manuel olarak girilen kişisel notlardır. Matchly, herhangi bir spor ligi, takım veya bahis şirketiyle ilişkili değildir.'**
  String get legalInfoBody;

  /// No description provided for @versionLabel.
  ///
  /// In tr, this message translates to:
  /// **'Sürüm'**
  String get versionLabel;

  /// No description provided for @comingSoonMessage.
  ///
  /// In tr, this message translates to:
  /// **'Bu özellik yakında geliyor'**
  String get comingSoonMessage;

  /// No description provided for @comingSoonBadge.
  ///
  /// In tr, this message translates to:
  /// **'Yakında'**
  String get comingSoonBadge;

  /// No description provided for @aboutMatchlyBody.
  ///
  /// In tr, this message translates to:
  /// **'Matchly, bahis kuponlarını kişisel olarak takip etmen için tasarlanmış bir uygulamadır. Kuponlarını kaydet, sonuçlarını otomatik takip et, istatistiklerini gör ve dilersen arkadaşlarınla paylaş.\n\nSoru, öneri veya geri bildirimlerin için:\ndestek@matchlyapp.com\n\nGizlilik Politikası:\nhttps://matchlyapp.com/privacy'**
  String get aboutMatchlyBody;

  /// No description provided for @newUsernameHint.
  ///
  /// In tr, this message translates to:
  /// **'Yeni kullanıcı adı'**
  String get newUsernameHint;

  /// No description provided for @currentPasswordHint.
  ///
  /// In tr, this message translates to:
  /// **'Mevcut şifre'**
  String get currentPasswordHint;

  /// No description provided for @newPasswordHint.
  ///
  /// In tr, this message translates to:
  /// **'Yeni şifre (min 8 karakter, rakam içermeli)'**
  String get newPasswordHint;

  /// No description provided for @currentPasswordRequiredError.
  ///
  /// In tr, this message translates to:
  /// **'Mevcut şifre gerekli'**
  String get currentPasswordRequiredError;

  /// No description provided for @newPasswordMinLengthError.
  ///
  /// In tr, this message translates to:
  /// **'En az 8 karakter olmalı'**
  String get newPasswordMinLengthError;

  /// No description provided for @newPasswordNeedsDigitError.
  ///
  /// In tr, this message translates to:
  /// **'En az bir rakam içermeli'**
  String get newPasswordNeedsDigitError;

  /// No description provided for @passwordUpdatedMessage.
  ///
  /// In tr, this message translates to:
  /// **'Şifre güncellendi ✓'**
  String get passwordUpdatedMessage;

  /// No description provided for @currentPasswordWrongError.
  ///
  /// In tr, this message translates to:
  /// **'Mevcut şifre yanlış'**
  String get currentPasswordWrongError;

  /// No description provided for @defaultUserFallback.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı'**
  String get defaultUserFallback;

  /// No description provided for @languageSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama dili'**
  String get languageSubtitle;

  /// No description provided for @turkishLabel.
  ///
  /// In tr, this message translates to:
  /// **'Türkçe'**
  String get turkishLabel;

  /// No description provided for @englishLabel.
  ///
  /// In tr, this message translates to:
  /// **'English'**
  String get englishLabel;

  /// No description provided for @statsPageSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Kupon performans özeti'**
  String get statsPageSubtitle;

  /// No description provided for @totalLabel.
  ///
  /// In tr, this message translates to:
  /// **'Toplam'**
  String get totalLabel;

  /// No description provided for @wonLabel.
  ///
  /// In tr, this message translates to:
  /// **'Kazanan'**
  String get wonLabel;

  /// No description provided for @lostLabel.
  ///
  /// In tr, this message translates to:
  /// **'Kaybeden'**
  String get lostLabel;

  /// No description provided for @successRateLabel.
  ///
  /// In tr, this message translates to:
  /// **'Başarı'**
  String get successRateLabel;

  /// No description provided for @statusDistributionTitle.
  ///
  /// In tr, this message translates to:
  /// **'DURUM DAĞILIMI'**
  String get statusDistributionTitle;

  /// No description provided for @cancelledLabel.
  ///
  /// In tr, this message translates to:
  /// **'İptal'**
  String get cancelledLabel;

  /// No description provided for @netProfitLossTitle.
  ///
  /// In tr, this message translates to:
  /// **'Net Kar / Zarar'**
  String get netProfitLossTitle;

  /// No description provided for @totalWinningsLabel.
  ///
  /// In tr, this message translates to:
  /// **'Toplam Kazanç'**
  String get totalWinningsLabel;

  /// No description provided for @totalLossLabel.
  ///
  /// In tr, this message translates to:
  /// **'Toplam Kayıp'**
  String get totalLossLabel;

  /// No description provided for @netLabel.
  ///
  /// In tr, this message translates to:
  /// **'Net'**
  String get netLabel;

  /// No description provided for @siteBasedTitle.
  ///
  /// In tr, this message translates to:
  /// **'Site Bazlı'**
  String get siteBasedTitle;

  /// No description provided for @couponCountSuffix.
  ///
  /// In tr, this message translates to:
  /// **'{count} kupon'**
  String couponCountSuffix(int count);

  /// No description provided for @recentPerformanceTitle.
  ///
  /// In tr, this message translates to:
  /// **'SON PERFORMANS'**
  String get recentPerformanceTitle;

  /// No description provided for @noStatsYetTitle.
  ///
  /// In tr, this message translates to:
  /// **'Henüz istatistik yok'**
  String get noStatsYetTitle;

  /// No description provided for @noStatsYetSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Kupon ekledikçe burada görünecek.'**
  String get noStatsYetSubtitle;

  /// No description provided for @dailyHistoryTitle.
  ///
  /// In tr, this message translates to:
  /// **'GÜNLÜK GEÇMİŞ'**
  String get dailyHistoryTitle;

  /// No description provided for @lastNDays.
  ///
  /// In tr, this message translates to:
  /// **'Son {count} gün'**
  String lastNDays(int count);

  /// No description provided for @viewAllHistory.
  ///
  /// In tr, this message translates to:
  /// **'Tüm geçmişi gör →'**
  String get viewAllHistory;

  /// No description provided for @noHistoryYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz geçmiş yok'**
  String get noHistoryYet;

  /// No description provided for @dailyHistoryPageTitle.
  ///
  /// In tr, this message translates to:
  /// **'Günlük Geçmiş'**
  String get dailyHistoryPageTitle;

  /// No description provided for @wonCountSuffix.
  ///
  /// In tr, this message translates to:
  /// **'{count} tuttu'**
  String wonCountSuffix(int count);

  /// No description provided for @lostCountSuffix.
  ///
  /// In tr, this message translates to:
  /// **'{count} yattı'**
  String lostCountSuffix(int count);

  /// No description provided for @investmentAndProfit.
  ///
  /// In tr, this message translates to:
  /// **'{investment} yatırım · {profit} kazanç'**
  String investmentAndProfit(String investment, String profit);

  /// No description provided for @couponCountActive.
  ///
  /// In tr, this message translates to:
  /// **'{count} kupon · {active} aktif'**
  String couponCountActive(int count, int active);

  /// No description provided for @heroTotalPotential.
  ///
  /// In tr, this message translates to:
  /// **'TOPLAM BEKLENTİ'**
  String get heroTotalPotential;

  /// No description provided for @activeStatLabel.
  ///
  /// In tr, this message translates to:
  /// **'aktif'**
  String get activeStatLabel;

  /// No description provided for @successStatLabel.
  ///
  /// In tr, this message translates to:
  /// **'başarı'**
  String get successStatLabel;

  /// No description provided for @netStatLabel.
  ///
  /// In tr, this message translates to:
  /// **'net'**
  String get netStatLabel;

  /// No description provided for @todayLabel.
  ///
  /// In tr, this message translates to:
  /// **'Bugün'**
  String get todayLabel;

  /// No description provided for @yesterdayLabel.
  ///
  /// In tr, this message translates to:
  /// **'Dün'**
  String get yesterdayLabel;

  /// No description provided for @investmentLabel.
  ///
  /// In tr, this message translates to:
  /// **'Yatırım'**
  String get investmentLabel;

  /// No description provided for @profitLossLabel.
  ///
  /// In tr, this message translates to:
  /// **'Kar/Zarar'**
  String get profitLossLabel;

  /// No description provided for @searchHint.
  ///
  /// In tr, this message translates to:
  /// **'Kupon ara...'**
  String get searchHint;

  /// No description provided for @filtersTitle.
  ///
  /// In tr, this message translates to:
  /// **'Filtreler'**
  String get filtersTitle;

  /// No description provided for @resetLabel.
  ///
  /// In tr, this message translates to:
  /// **'Sıfırla'**
  String get resetLabel;

  /// No description provided for @filterSiteLabel.
  ///
  /// In tr, this message translates to:
  /// **'SİTE'**
  String get filterSiteLabel;

  /// No description provided for @filterLeagueLabel.
  ///
  /// In tr, this message translates to:
  /// **'LİG'**
  String get filterLeagueLabel;

  /// No description provided for @deleteCouponTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kuponu Sil'**
  String get deleteCouponTitle;

  /// No description provided for @deleteCouponBody.
  ///
  /// In tr, this message translates to:
  /// **'Bu kupon kalıcı olarak silinecek.'**
  String get deleteCouponBody;

  /// No description provided for @deleteLabel.
  ///
  /// In tr, this message translates to:
  /// **'Sil'**
  String get deleteLabel;

  /// No description provided for @sharedToFeedMessage.
  ///
  /// In tr, this message translates to:
  /// **'✅ Akışta paylaşıldı'**
  String get sharedToFeedMessage;

  /// No description provided for @removedFromFeedMessage.
  ///
  /// In tr, this message translates to:
  /// **'🔒 Akıştan kaldırıldı'**
  String get removedFromFeedMessage;

  /// No description provided for @searchNoResults.
  ///
  /// In tr, this message translates to:
  /// **'Arama sonucu bulunamadı'**
  String get searchNoResults;

  /// No description provided for @noCouponsYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz kupon eklenmedi'**
  String get noCouponsYet;

  /// No description provided for @noActiveCoupons.
  ///
  /// In tr, this message translates to:
  /// **'Aktif kupon bulunamadı'**
  String get noActiveCoupons;

  /// No description provided for @noWinningCoupons.
  ///
  /// In tr, this message translates to:
  /// **'Kazanan kupon bulunamadı'**
  String get noWinningCoupons;

  /// No description provided for @noLosingCoupons.
  ///
  /// In tr, this message translates to:
  /// **'Kaybeden kupon bulunamadı'**
  String get noLosingCoupons;

  /// No description provided for @emptyStateHint.
  ///
  /// In tr, this message translates to:
  /// **'Kuponlarını takip etmek için + butonuna dokun.'**
  String get emptyStateHint;

  /// No description provided for @tabAll.
  ///
  /// In tr, this message translates to:
  /// **'Tümü'**
  String get tabAll;

  /// No description provided for @winningStatusLabel.
  ///
  /// In tr, this message translates to:
  /// **'Kazanıyor'**
  String get winningStatusLabel;

  /// No description provided for @voidStatusLabel.
  ///
  /// In tr, this message translates to:
  /// **'Geçersiz'**
  String get voidStatusLabel;

  /// No description provided for @progressCompletedLabel.
  ///
  /// In tr, this message translates to:
  /// **'tamamlandı'**
  String get progressCompletedLabel;

  /// No description provided for @navMyCoupons.
  ///
  /// In tr, this message translates to:
  /// **'Kuponlarım'**
  String get navMyCoupons;

  /// No description provided for @navFeed.
  ///
  /// In tr, this message translates to:
  /// **'Akış'**
  String get navFeed;

  /// No description provided for @navStatsLabel.
  ///
  /// In tr, this message translates to:
  /// **'İstatistik'**
  String get navStatsLabel;

  /// No description provided for @noNotificationsYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz bildirim yok'**
  String get noNotificationsYet;

  /// No description provided for @footerStakeLabel.
  ///
  /// In tr, this message translates to:
  /// **'BAHİS'**
  String get footerStakeLabel;

  /// No description provided for @oranLabel.
  ///
  /// In tr, this message translates to:
  /// **'ORAN'**
  String get oranLabel;

  /// No description provided for @beklentiLabel.
  ///
  /// In tr, this message translates to:
  /// **'BEKLENTİ'**
  String get beklentiLabel;

  /// No description provided for @addCouponTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kupon Ekle'**
  String get addCouponTitle;

  /// No description provided for @aiAddButton.
  ///
  /// In tr, this message translates to:
  /// **'AI ile Ekle'**
  String get aiAddButton;

  /// No description provided for @addCouponSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Seçimlerini ekle ve kaydet'**
  String get addCouponSubtitle;

  /// No description provided for @couponNameLabel.
  ///
  /// In tr, this message translates to:
  /// **'Kupon adı'**
  String get couponNameLabel;

  /// No description provided for @couponNameHint.
  ///
  /// In tr, this message translates to:
  /// **'Akşam Kuponu'**
  String get couponNameHint;

  /// No description provided for @stakeAmountLabel.
  ///
  /// In tr, this message translates to:
  /// **'Bahis Miktarı'**
  String get stakeAmountLabel;

  /// No description provided for @oddsFieldLabel.
  ///
  /// In tr, this message translates to:
  /// **'Oran'**
  String get oddsFieldLabel;

  /// No description provided for @selectionsCountLabel.
  ///
  /// In tr, this message translates to:
  /// **'{count} Seçim'**
  String selectionsCountLabel(int count);

  /// No description provided for @clearAllSelections.
  ///
  /// In tr, this message translates to:
  /// **'Tüm Seçimleri Sil'**
  String get clearAllSelections;

  /// No description provided for @addSelectionButton.
  ///
  /// In tr, this message translates to:
  /// **'+ Seçim Ekle'**
  String get addSelectionButton;

  /// No description provided for @noSelectionYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz seçim eklenmedi'**
  String get noSelectionYet;

  /// No description provided for @duplicateSelectionToast.
  ///
  /// In tr, this message translates to:
  /// **'Bu seçim zaten eklendi'**
  String get duplicateSelectionToast;

  /// No description provided for @couponSummaryTitle.
  ///
  /// In tr, this message translates to:
  /// **'KUPON ÖZETİ'**
  String get couponSummaryTitle;

  /// No description provided for @selectionsCountChip.
  ///
  /// In tr, this message translates to:
  /// **'{count} seçim'**
  String selectionsCountChip(int count);

  /// No description provided for @clearSelectionsDialogTitle.
  ///
  /// In tr, this message translates to:
  /// **'Seçimleri Temizle'**
  String get clearSelectionsDialogTitle;

  /// No description provided for @clearSelectionsDialogBody.
  ///
  /// In tr, this message translates to:
  /// **'Tüm seçimler silinecek. Devam etmek istiyor musun?'**
  String get clearSelectionsDialogBody;

  /// No description provided for @giveUpLabel.
  ///
  /// In tr, this message translates to:
  /// **'Vazgeç'**
  String get giveUpLabel;

  /// No description provided for @couponReadFailedToast.
  ///
  /// In tr, this message translates to:
  /// **'Kupon okunamadı, tekrar deneyin'**
  String get couponReadFailedToast;

  /// No description provided for @notFoundToast.
  ///
  /// In tr, this message translates to:
  /// **'Bulunamadı: {names}'**
  String notFoundToast(String names);

  /// No description provided for @noMatchMatchedToast.
  ///
  /// In tr, this message translates to:
  /// **'Hiçbir maç eşleştirilemedi, manuel ekleyin'**
  String get noMatchMatchedToast;

  /// No description provided for @genericErrorToast.
  ///
  /// In tr, this message translates to:
  /// **'Hata: {error}'**
  String genericErrorToast(String error);

  /// No description provided for @addAtLeastOneSelection.
  ///
  /// In tr, this message translates to:
  /// **'En az bir maç seçimi ekleyin'**
  String get addAtLeastOneSelection;

  /// No description provided for @enterValidOdds.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen geçerli bir oran girin'**
  String get enterValidOdds;

  /// No description provided for @enterStakeAmount.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen bahis miktarı girin'**
  String get enterStakeAmount;

  /// No description provided for @searchTeamOrLeagueHint.
  ///
  /// In tr, this message translates to:
  /// **'Takım veya lig ara'**
  String get searchTeamOrLeagueHint;

  /// No description provided for @noMatchFound.
  ///
  /// In tr, this message translates to:
  /// **'Maç bulunamadı.'**
  String get noMatchFound;

  /// No description provided for @noResultFound.
  ///
  /// In tr, this message translates to:
  /// **'Sonuç bulunamadı.'**
  String get noResultFound;

  /// No description provided for @selectMatchTitle.
  ///
  /// In tr, this message translates to:
  /// **'Maç Seç'**
  String get selectMatchTitle;

  /// No description provided for @editMarketTitle.
  ///
  /// In tr, this message translates to:
  /// **'Düzenle · Market'**
  String get editMarketTitle;

  /// No description provided for @editTimeTitle.
  ///
  /// In tr, this message translates to:
  /// **'Düzenle · Zaman'**
  String get editTimeTitle;

  /// No description provided for @editLineTitle.
  ///
  /// In tr, this message translates to:
  /// **'Düzenle · Hat Seç'**
  String get editLineTitle;

  /// No description provided for @editOptionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Düzenle · Seçenek'**
  String get editOptionTitle;

  /// No description provided for @marketTitle.
  ///
  /// In tr, this message translates to:
  /// **'Market'**
  String get marketTitle;

  /// No description provided for @timeTitle.
  ///
  /// In tr, this message translates to:
  /// **'Zaman'**
  String get timeTitle;

  /// No description provided for @lineTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hat Seç'**
  String get lineTitle;

  /// No description provided for @optionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Seçenek'**
  String get optionTitle;

  /// No description provided for @matchEndLabel.
  ///
  /// In tr, this message translates to:
  /// **'Maç sonu'**
  String get matchEndLabel;

  /// No description provided for @firstHalfLabel.
  ///
  /// In tr, this message translates to:
  /// **'İlk yarı'**
  String get firstHalfLabel;

  /// No description provided for @leagueSelectTitle.
  ///
  /// In tr, this message translates to:
  /// **'Lig Seç'**
  String get leagueSelectTitle;

  /// No description provided for @leagueSearchHint.
  ///
  /// In tr, this message translates to:
  /// **'Lig ara...'**
  String get leagueSearchHint;

  /// No description provided for @leagueNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Lig bulunamadı'**
  String get leagueNotFound;

  /// No description provided for @selectLeaguePlaceholder.
  ///
  /// In tr, this message translates to:
  /// **'Lig seç'**
  String get selectLeaguePlaceholder;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
