// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Matchly';

  @override
  String get signIn => 'Sign in';

  @override
  String get signUp => 'Create account';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get username => 'Username';

  @override
  String get error => 'An error occurred';

  @override
  String get loading => 'Loading...';

  @override
  String get active => 'Active';

  @override
  String get won => 'Won';

  @override
  String get lost => 'Lost';

  @override
  String get pending => 'Pending';

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get logout => 'Sign out';

  @override
  String get darkMode => 'Dark mode';

  @override
  String get lightMode => 'Light mode';

  @override
  String get language => 'Language';

  @override
  String get notifications => 'Notifications';

  @override
  String get statistics => 'Statistics';

  @override
  String get coupons => 'Coupons';

  @override
  String get activeCoupons => 'Active coupons';

  @override
  String get totalStake => 'Total stake';

  @override
  String get totalPotential => 'Total potential';

  @override
  String get authTagline => 'Save your coupons to your account.';

  @override
  String get usernameRequiredError => 'Username is required';

  @override
  String get emailPasswordRequiredError => 'Email and password are required';

  @override
  String get passwordMinLengthError => 'Password must be at least 8 characters';

  @override
  String get passwordNeedsDigitError =>
      'Password must contain at least one digit';

  @override
  String get passwordsDontMatchError => 'Passwords don\'t match';

  @override
  String get passwordConfirmHint => 'Confirm password';

  @override
  String get orDivider => 'or';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get noAccountSignUp => 'Don\'t have an account? Sign up';

  @override
  String get haveAccountSignIn => 'Already have an account? Sign in';

  @override
  String get chooseUsernameTitle => 'Choose a username';

  @override
  String get chooseUsernameSubtitle => 'This name will show on your profile.';

  @override
  String get usernameHintPlaceholder => 'username';

  @override
  String get continueButton => 'Continue';

  @override
  String get usernameMinLengthError => 'Must be at least 3 characters';

  @override
  String get ayarlarSubtitle => 'App preferences';

  @override
  String get sectionAccount => 'ACCOUNT';

  @override
  String get sectionHistory => 'HISTORY';

  @override
  String get sectionGeneral => 'GENERAL';

  @override
  String get sectionCoupons => 'COUPONS';

  @override
  String get sectionData => 'DATA';

  @override
  String get sectionAbout => 'ABOUT';

  @override
  String get changeUsername => 'Change Username';

  @override
  String get changePassword => 'Change Password';

  @override
  String get couponHistory => 'Coupon History';

  @override
  String get couponHistorySubtitle => 'View completed coupons';

  @override
  String get notificationsSubtitle => 'Coupon updates';

  @override
  String get darkThemeLabel => 'Dark Theme';

  @override
  String get darkThemeSubtitle => 'App appearance';

  @override
  String get autoUpdateLabel => 'Auto Update';

  @override
  String get autoUpdateSubtitle => 'Refresh data in background';

  @override
  String get dailyReportLabel => 'End-of-Day Report';

  @override
  String get pickReportTimeHelp => 'Pick report time';

  @override
  String get defaultStakeLabel => 'Default Stake';

  @override
  String get defaultSiteLabel => 'Default Site';

  @override
  String get clearDataLabel => 'Clear Data';

  @override
  String get clearDataSubtitle => 'Delete all coupons';

  @override
  String get signOutLabel => 'Sign Out';

  @override
  String get signOutSubtitle => 'Sign out of your account';

  @override
  String get signOutConfirmBody => 'Are you sure you want to sign out?';

  @override
  String get cancelLabel => 'Cancel';

  @override
  String get saveLabel => 'Save';

  @override
  String get okLabel => 'OK';

  @override
  String get legalInfoTitle => 'Legal Information';

  @override
  String get legalInfoBody =>
      'Matchly is not a betting operator. It does not accept bets, offer odds, handle money or balances, and is not connected to any real betting account. All coupon information in the app consists of personal notes entered manually by the user. Matchly is not affiliated with any sports league, team, or betting company.';

  @override
  String get versionLabel => 'Version';

  @override
  String get comingSoonMessage => 'This feature is coming soon';

  @override
  String get comingSoonBadge => 'Soon';

  @override
  String get newUsernameHint => 'New username';

  @override
  String get currentPasswordHint => 'Current password';

  @override
  String get newPasswordHint =>
      'New password (min 8 characters, must include a digit)';

  @override
  String get currentPasswordRequiredError => 'Current password is required';

  @override
  String get newPasswordMinLengthError => 'Must be at least 8 characters';

  @override
  String get newPasswordNeedsDigitError => 'Must contain at least one digit';

  @override
  String get passwordUpdatedMessage => 'Password updated ✓';

  @override
  String get currentPasswordWrongError => 'Current password is incorrect';

  @override
  String get defaultUserFallback => 'User';

  @override
  String get languageSubtitle => 'App language';

  @override
  String get turkishLabel => 'Türkçe';

  @override
  String get englishLabel => 'English';

  @override
  String get statsPageSubtitle => 'Coupon performance summary';

  @override
  String get totalLabel => 'Total';

  @override
  String get wonLabel => 'Won';

  @override
  String get lostLabel => 'Lost';

  @override
  String get successRateLabel => 'Success';

  @override
  String get statusDistributionTitle => 'STATUS BREAKDOWN';

  @override
  String get cancelledLabel => 'Cancelled';

  @override
  String get netProfitLossTitle => 'Net Profit / Loss';

  @override
  String get totalWinningsLabel => 'Total Winnings';

  @override
  String get totalLossLabel => 'Total Loss';

  @override
  String get netLabel => 'Net';

  @override
  String get siteBasedTitle => 'By Site';

  @override
  String couponCountSuffix(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count coupons',
      one: '$count coupon',
    );
    return '$_temp0';
  }

  @override
  String get recentPerformanceTitle => 'RECENT PERFORMANCE';

  @override
  String get noStatsYetTitle => 'No statistics yet';

  @override
  String get noStatsYetSubtitle => 'This will fill up as you add coupons.';

  @override
  String get dailyHistoryTitle => 'DAILY HISTORY';

  @override
  String lastNDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '$count day',
    );
    return 'Last $_temp0';
  }

  @override
  String get viewAllHistory => 'View all history →';

  @override
  String get noHistoryYet => 'No history yet';

  @override
  String get dailyHistoryPageTitle => 'Daily History';

  @override
  String wonCountSuffix(int count) {
    return '$count won';
  }

  @override
  String lostCountSuffix(int count) {
    return '$count lost';
  }

  @override
  String investmentAndProfit(String investment, String profit) {
    return '$investment staked · $profit won';
  }

  @override
  String couponCountActive(int count, int active) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count coupons',
      one: '$count coupon',
    );
    return '$_temp0 · $active active';
  }

  @override
  String get heroTotalPotential => 'TOTAL POTENTIAL';

  @override
  String get activeStatLabel => 'active';

  @override
  String get successStatLabel => 'success';

  @override
  String get netStatLabel => 'net';

  @override
  String get todayLabel => 'Today';

  @override
  String get yesterdayLabel => 'Yesterday';

  @override
  String get investmentLabel => 'Stake';

  @override
  String get profitLossLabel => 'Profit/Loss';

  @override
  String get searchHint => 'Search coupons...';

  @override
  String get filtersTitle => 'Filters';

  @override
  String get resetLabel => 'Reset';

  @override
  String get filterSiteLabel => 'SITE';

  @override
  String get filterLeagueLabel => 'LEAGUE';

  @override
  String get deleteCouponTitle => 'Delete Coupon';

  @override
  String get deleteCouponBody => 'This coupon will be permanently deleted.';

  @override
  String get deleteLabel => 'Delete';

  @override
  String get sharedToFeedMessage => '✅ Shared to feed';

  @override
  String get removedFromFeedMessage => '🔒 Removed from feed';

  @override
  String get searchNoResults => 'No search results found';

  @override
  String get noCouponsYet => 'No coupons added yet';

  @override
  String get noActiveCoupons => 'No active coupons found';

  @override
  String get noWinningCoupons => 'No winning coupons found';

  @override
  String get noLosingCoupons => 'No losing coupons found';

  @override
  String get emptyStateHint => 'Tap + to start tracking your coupons.';

  @override
  String get tabAll => 'All';

  @override
  String get winningStatusLabel => 'Winning';

  @override
  String get voidStatusLabel => 'Void';

  @override
  String get progressCompletedLabel => 'completed';

  @override
  String get navMyCoupons => 'My Coupons';

  @override
  String get navFeed => 'Feed';

  @override
  String get navStatsLabel => 'Stats';

  @override
  String get noNotificationsYet => 'No notifications yet';

  @override
  String get footerStakeLabel => 'STAKE';

  @override
  String get oranLabel => 'ODDS';

  @override
  String get beklentiLabel => 'POTENTIAL';

  @override
  String get addCouponTitle => 'Add Coupon';

  @override
  String get aiAddButton => 'Add with AI';

  @override
  String get addCouponSubtitle => 'Add your selections and save';

  @override
  String get couponNameLabel => 'Coupon name';

  @override
  String get couponNameHint => 'Evening Coupon';

  @override
  String get stakeAmountLabel => 'Stake Amount';

  @override
  String get oddsFieldLabel => 'Odds';

  @override
  String selectionsCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Selections',
      one: '$count Selection',
    );
    return '$_temp0';
  }

  @override
  String get clearAllSelections => 'Clear All Selections';

  @override
  String get addSelectionButton => '+ Add Selection';

  @override
  String get noSelectionYet => 'No selections added yet';

  @override
  String get duplicateSelectionToast => 'This selection is already added';

  @override
  String get couponSummaryTitle => 'COUPON SUMMARY';

  @override
  String selectionsCountChip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selections',
      one: '$count selection',
    );
    return '$_temp0';
  }

  @override
  String get clearSelectionsDialogTitle => 'Clear Selections';

  @override
  String get clearSelectionsDialogBody =>
      'All selections will be deleted. Do you want to continue?';

  @override
  String get giveUpLabel => 'Cancel';

  @override
  String get couponReadFailedToast =>
      'Couldn\'t read the coupon, please try again';

  @override
  String notFoundToast(String names) {
    return 'Not found: $names';
  }

  @override
  String get noMatchMatchedToast => 'No matches could be matched, add manually';

  @override
  String genericErrorToast(String error) {
    return 'Error: $error';
  }

  @override
  String get addAtLeastOneSelection => 'Add at least one match selection';

  @override
  String get enterValidOdds => 'Please enter valid odds';

  @override
  String get enterStakeAmount => 'Please enter a stake amount';

  @override
  String get searchTeamOrLeagueHint => 'Search team or league';

  @override
  String get noMatchFound => 'No match found.';

  @override
  String get noResultFound => 'No result found.';

  @override
  String get selectMatchTitle => 'Select Match';

  @override
  String get editMarketTitle => 'Edit · Market';

  @override
  String get editTimeTitle => 'Edit · Time';

  @override
  String get editLineTitle => 'Edit · Select Line';

  @override
  String get editOptionTitle => 'Edit · Option';

  @override
  String get marketTitle => 'Market';

  @override
  String get timeTitle => 'Time';

  @override
  String get lineTitle => 'Select Line';

  @override
  String get optionTitle => 'Option';

  @override
  String get matchEndLabel => 'Full time';

  @override
  String get firstHalfLabel => 'First half';

  @override
  String get leagueSelectTitle => 'Select League';

  @override
  String get leagueSearchHint => 'Search league...';

  @override
  String get leagueNotFound => 'League not found';

  @override
  String get selectLeaguePlaceholder => 'Select league';
}
