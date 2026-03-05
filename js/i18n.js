/**
 * Memorio i18n (Internationalization) System
 * Supports English (default) and Spanish
 * 
 * Usage:
 * 1. Include this script in your HTML: <script src="/js/i18n.js"></script>
 * 2. Call i18n.init() when DOM is ready
 * 3. Mark translatable elements with data-i18n="key"
 * 4. Use i18n.t('key') to get translations in JavaScript
 */

const i18n = {
  // Current language (default: English)
  currentLang: 'en',
  
  // Flag to track if i18n has been initialized
  _initialized: false,
  
  // Translation dictionary
  translations: {
    en: {
      // Common
      'common.loading': 'Loading...',
      'common.save': 'Save',
      'common.cancel': 'Cancel',
      'common.delete': 'Delete',
      'common.edit': 'Edit',
      'common.submit': 'Submit',
      'common.close': 'Close',
      'common.confirm': 'Confirm',
      'common.yes': 'Yes',
      'common.no': 'No',
      'common.logout': 'Logout',
      'common.search': 'Search',
      'common.filter': 'Filter',
      'common.copy': 'Copy',
      'common.download': 'Download',
      'common.upload': 'Upload',
      'common.error': 'Error',
      'common.success': 'Success',
      'common.emailAddress': 'Email Address',
      'common.password': 'Password',
      'common.enterEmail': 'Enter your email',
      'common.enterPassword': 'Enter your password',
      'common.rateLimitExceeded': 'Too many failed attempts. Please try again in {minutes} minute(s).',
      'common.loginFailed': 'Failed to sign in. Please check your credentials.',
      'common.unexpectedError': 'An unexpected error occurred. Please try again.',
      
      // Navigation (shared across pages)
      'nav.home': 'Home',
      'nav.features': 'Features',
      'nav.howItWorks': 'How It Works',
      'nav.benefits': 'Benefits',
      'nav.faq': 'FAQ',
      'nav.services': 'Services',
      'nav.familyLogin': 'Family Login',
      
      // Main Website
      'website.nav.features': 'Features',
      'website.nav.howItWorks': 'How It Works',
      'website.nav.benefits': 'Benefits',
      'website.nav.faq': 'FAQ',
      'website.nav.services': 'Services',
      'website.nav.familyLogin': 'Family Login',
      'website.hero.title': 'A Beautiful Way To Remember Someone You Love',
      'website.hero.subtitle1': 'When words are hard and time is short, Memorio helps families and funeral homes create meaningful video tributes and obituaries with care, dignity, and professional support.',
      'website.hero.subtitle2': 'Families receive a simple guided experience. Funeral homes receive finished memorial assets within 48 hours.',
      'website.hero.getStarted': 'Start Your Tribute',
      'website.hero.learnMore': 'For Funeral Homes →',
      
      // Mission Section
      'website.mission.title': 'Why Memorio Exists',
      'website.mission.problem': 'The Problem',
      'website.mission.problemDesc': 'Funeral professionals spend valuable time editing videos and formatting obituaries instead of being with families.',
      'website.mission.solution': 'Our Solution',
      'website.mission.solutionDesc': 'Memorio removes memorial production from your workflow, allowing you to focus on care, guidance, and families.',
      
      'website.features.title': 'Everything You Need to Honor a Life',
      'website.features.subtitle': 'Memorio provides a complete solution for creating meaningful memorial tributes',
      'website.features.realSupport': 'Real, Compassionate Support',
      'website.features.realSupportDesc': 'If you need help or guidance, support is available every step of the way.',
      'website.howItWorks.title': 'How It Works',
      'website.howItWorks.subtitle': 'Creating a meaningful tribute doesn\'t have to be complicated.',
      'website.howItWorks.step1': 'Family Shares Memories',
      'website.howItWorks.step1Desc': 'Families answer guided questions and upload photos through a secure portal.',
      'website.howItWorks.step2': 'Memorio Produces the Tribute',
      'website.howItWorks.step2Desc': 'Memorio generates the obituary using advanced AI and assembles the tribute video with music, pacing, and professional editing. Each tribute is reviewed to ensure quality before delivery.',
      'website.howItWorks.step3': 'Delivered to Family and Funeral Home',
      'website.howItWorks.step3Desc': 'Once approved, the final obituary and tribute video are delivered simultaneously to both the family and the funeral home within 48 hours of submission, ready for services or online sharing.',
      'website.faq.title': 'Frequently Asked Questions',
      'website.faq.subtitle': 'Everything you need to know about using Memorio.',
      'website.faq.q1': 'Is my family\'s information safe?',
      'website.faq.a1': 'Yes. We use strong security measures and strict access controls to protect your memories and personal information.',
      'website.faq.q2': 'How long does it take to receive everything?',
      'website.faq.a2': 'Your obituary is generated immediately after you finish our guided form. Your tribute video is delivered within 48 hours.',
      'website.faq.q3': 'Will this be difficult for my family to use?',
      'website.faq.a3': 'No. The process is simple, guided, and designed for people who may not be comfortable with technology.',
      'website.faq.q4': 'Will our loved one\'s tribute be handled with care and respect?',
      'website.faq.a4': 'Absolutely. This is not "content" to us. It is someone\'s life story, and it is treated with the dignity it deserves.',
      'website.faq.q5': 'Who creates the tribute video?',
      'website.faq.a5': 'Memorio generates the obituary using advanced AI based on the information provided by the family. The tribute video is assembled using the photos, music preferences, and memories submitted through the family portal. Each tribute passes through quality control before final delivery.',
      'website.faq.q6': 'Do I need technical skills to use Memorio?',
      'website.faq.a6': 'No technical experience is required. The process is guided step-by-step to make it simple during a difficult time.',
      'website.cta.title': 'Ready to Begin Creating a Tribute?',
      'website.cta.subtitle': 'If your funeral home uses Memorio, your funeral director will provide secure login credentials for the family portal.',
      'website.cta.button': 'Access Family Portal',
      'website.footer.about': 'About Memorio',
      'website.footer.aboutDesc': 'Memorio works alongside funeral homes to produce obituaries and video tributes that honor loved ones with dignity while simplifying the memorial process for families.',
      'website.footer.quickLinks': 'Quick Links',
      'website.footer.login': 'Login',
      'website.footer.support': 'Support',
      'website.footer.familyPortal': 'Family Portal',
      'website.footer.directorPortal': 'Director Portal',
      'website.footer.privacyPolicy': 'Privacy Policy',
      'website.footer.termsOfService': 'Terms of Service',
      'website.footer.copyright': '© 2026 Memorio. All rights reserved. Honoring life, one story at a time.',
      'website.features.whyChoose': 'Why Choose Memorio',
      'website.features.whyChooseDesc': 'Memorio simplifies the memorial process for families while ensuring funeral homes receive professionally prepared tributes ready for service.',
      'website.features.guidedProcess': 'Simple for Families',
      'website.features.guidedProcessDesc': 'Families answer guided questions and upload photos through a calm step-by-step experience designed for a difficult time.',
      'website.features.privateSecure': 'Private & Secure',
      'website.features.privateSecureDesc': 'Family memories and personal information are protected with strong security and strict access controls.',
      'website.features.beautifullyCrafted': 'Thoughtfully Produced',
      'website.features.beautifullyCraftedDesc': 'Each tribute is assembled with care, combining photos, music, and pacing that honors your loved one with dignity.',
      'website.features.readyWhenNeeded': 'Delivered Within 48 Hours',
      'website.features.readyWhenNeededDesc': 'Memorial tributes and obituaries are completed quickly and carefully so families and funeral homes have everything ready when it matters most.',
      'website.features.everythingInOnePlace': 'Organized in One Place',
      'website.features.everythingInOnePlaceDesc': 'Photos, memories, and tribute materials are collected in a single secure location to simplify the entire process.',
      'website.howItWorks.step1': 'Family Completes Form',
      'website.howItWorks.step1Desc': 'Families answer guided questions and upload photos through a simple, compassionate interface.',
      'website.howItWorks.step2': 'Professional Editing',
      'website.howItWorks.step2Desc': 'Our team crafts a beautiful video tribute, carefully selecting music and transitions.',
      'website.howItWorks.step3': 'Review & Approve',
      'website.howItWorks.step3Desc': 'Families review the video and can request revisions to ensure it\'s perfect.',
      'website.howItWorks.step4': 'Deliver & Share',
      'website.howItWorks.step4Desc': 'Final video is delivered digitally, ready to share at services or online.',
      
      // Director Portal
      'director.dashboard': 'Director Dashboard',
      'director.createCase': 'Create New Case',
      'director.createCaseDesc': 'Start a new memorial tribute case by providing the loved one\'s information.',
      'director.inviteFamily': 'Invite Family',
      'director.inviteFamilyTitle': 'Invite Family Member',
      'director.inviteFamilyDesc': 'Send a secure invitation to a family member to complete the tribute form for their case.',
      'director.familyMemberDetails': 'Family Member Details',
      'director.familyMemberDetailsDesc': 'Provide contact information and associate with a case ID',
      'director.emailAddress': 'Email Address',
      'director.fullName': 'Full Name',
      'director.phoneNumber': 'Phone Number (Optional)',
      'director.caseID': 'Case ID',
      'director.sendInvitation': 'SEND INVITATION',
      'director.myCases': 'My Cases',
      'director.myCasesDesc': 'View and manage all your memorial tribute cases',
      'director.searchCases': 'Search cases by name or ID...',
      'director.caseDetails': 'Case Details',
      'director.caseInformation': 'Case Information',
      'director.status': 'Status',
      'director.created': 'Created',
      'director.lovedOneName': 'Full Name of Loved One',
      'director.gender': 'Gender',
      'director.gender.select': 'Select Gender',
      'director.gender.male': 'Male',
      'director.gender.female': 'Female',
      'director.gender.other': 'Other',
      'director.gender.specify': 'Please Specify Gender/Pronouns',
      'director.gender.specifyHelper': 'This will be used in the memorial tribute',
      'director.dateOfBirth': 'Date of Birth',
      'director.dateOfPassing': 'Date of Passing',
      'director.cityOfBirth': 'City of Birth',
      'director.stateOfBirth': 'State/Province of Birth',
      'director.countryOfBirth': 'Country of Birth',
      'director.cityOfDeath': 'City of Passing',
      'director.stateOfDeath': 'State/Province of Passing',
      'director.countryOfDeath': 'Country of Passing',
      'director.createCaseBtn': 'CREATE CASE',
      'director.changePassword': 'Change Your Password',
      'director.changePasswordDesc': 'For security reasons, you must change your temporary password before accessing the dashboard.',
      'director.newPassword': 'New Password',
      'director.confirmPassword': 'Confirm New Password',
      'director.passwordMinLength': 'Must be at least 8 characters',
      'director.changePasswordBtn': 'CHANGE PASSWORD',
      'director.noCases': 'No cases found',
      'director.noCasesDesc': 'Create your first case to get started!',
      'director.caseCreatedSuccess': 'Case Created Successfully!',
      'director.caseCreatedDesc': 'Case ID has been generated. You can now invite the family to complete the tribute form.',
      'director.familyInvitationSuccess': 'Family Invitation Sent!',
      'director.copyBtn': 'Copy',

      // Director — new keys for full translation coverage
      'director.lovedOnesInfo': "Loved One's Information",
      'director.allFieldsRequired': 'All fields are required to ensure complete obituary generation',
      'director.fullNamePlaceholder': 'John Michael Doe',
      'director.genderSpecifyPlaceholder': 'e.g., Non-binary, They/Them, etc.',
      'director.optional': '(optional)',
      'director.stateOptionalPlaceholder': 'e.g. New York, Greater Manchester (leave blank if N/A)',
      'director.serviceDate': 'Service Date',
      'director.familyInvitedSuccess': 'Family Member Invited Successfully!',
      'director.familyInvitedDesc': 'Share these credentials with the family member. They will need them to access the tribute form.',
      'director.emailAddress': 'Email Address',
      'director.tempPassword': 'Temporary Password',
      'director.copy': 'Copy',
      'director.caseInfo': 'Case Information',
      'director.caseId': 'Case ID',
      'director.copyFullId': 'Copy Full ID',
      'director.statusLabel': 'Status',
      'director.createdLabel': 'Created',
      'director.lastUpdated': 'Last Updated',
      'director.familyInfo': 'Family Information',
      'director.familyMember': 'Family Member',
      'director.emailLabel': 'Email',
      'director.familyLoginCredentials': 'Family Login Credentials',
      'director.reveal': 'Reveal',
      'director.passwordLabel': 'Password',
      'director.clickReveal': 'Click Reveal',
      'director.formStatusTitle': 'Form Status',
      'director.formStatusLabel': 'Form Status',
      'director.submittedAt': 'Submitted At',
      'director.obituaryDraft': 'Obituary Draft',
      'director.lastUpdatedLabel': 'Last updated:',
      'director.photosAssets': 'Photos & Assets',
      'director.uploadPhotos': 'Upload Photos',
      'director.uploadPhotosHint': 'Click to select photos (JPEG, PNG, GIF)',
      'director.noPhotos': 'No photos uploaded yet',
      'director.memorialComplete': 'Memorial Complete',
      'director.memorialDelivered': 'The obituary and video have been delivered to the family',
      'director.downloads': 'Downloads',
      'director.downloadVideo': 'Download Memorial Video',
      'director.downloadObituaryPdf': 'Download Obituary PDF',
      'director.close': 'Close',
      'director.deleteCase': 'Delete Case',
      'director.cancel': 'Cancel',
      'director.newPasswordPlaceholder': 'Enter new password',
      'director.confirmPasswordPlaceholder': 'Confirm new password',

      // Services page
      'services.heroTitle': 'Built For Funeral Homes',
      'services.heroSubtitle': 'Streamline your operations, reduce administrative burden, and deliver consistent, professional tributes that honor every life with dignity.',
      'services.whyTitle': 'Why Funeral Homes Choose Memorio',
      'services.whySubtitle': 'Consistent quality, faster turnaround, and less work for your staff, without adding complexity to your operation.',
      'services.feat1Title': 'Consistent, Professional Results',
      'services.feat1Desc': 'Every family receives a polished, well-written obituary and tribute video that meets the same standard every time, regardless of staff workload or schedule.',
      'services.feat2Title': '48-Hour Video Turnaround',
      'services.feat2Desc': 'Tribute videos are delivered within 48 hours of submission, helping you move cases forward without delays or bottlenecks.',
      'services.feat3Title': 'Less Work for Your Staff',
      'services.feat3Desc': 'Your staff no longer needs to chase photos, write obituaries, or build videos. Memorio handles the most time-consuming parts so your team can focus on families and core services.',
      'services.feat4Title': 'A Reliable, Repeatable Process',
      'services.feat4Desc': 'Each case follows the same clear process from start to finish, helping ensure nothing gets missed and nothing falls through the cracks.',
      'services.feat5Title': 'Better Family Experience',
      'services.feat5Desc': 'Families get a simple, guided way to provide information and receive a finished memorial without confusion or back-and-forth.',
      'services.feat6Title': 'Built-In Quality Control',
      'services.feat6Desc': 'Every obituary and video is checked before delivery to ensure it meets professional standards and is ready to use.',
      'services.opsTitle': 'Operational Benefits',
      'services.opsSubtitle': 'What Memorio replaces or simplifies in your daily operations',
      'services.ops1Title': 'Reduced Admin',
      'services.ops1Desc': 'Automate case management, family communications, and status tracking. No more spreadsheets or manual follow-ups.',
      'services.ops2Title': 'Fewer Follow-ups',
      'services.ops2Desc': 'Families receive automated reminders and clear instructions. The system tracks progress so you know exactly where each case stands.',
      'services.ops3Title': 'Predictable Turnaround',
      'services.ops3Desc': 'Standardized workflow means consistent delivery times. Set expectations with families and meet them every time.',
      'services.ops4Title': 'Professional Standards',
      'services.ops4Desc': 'Every tribute meets the same high-quality standards. No more worrying about inconsistent results or rushed work.',
      'services.secTitle': 'Security & Compliance',
      'services.secSubtitle': 'Enterprise-grade security designed for sensitive data and regulatory compliance',
      'services.sec1Title': 'Strict Access Control',
      'services.sec1Desc': 'Only the right people can see each case. Family information is never exposed, shared, or mixed between accounts.',
      'services.sec2Title': 'Secure Storage',
      'services.sec2Desc': 'All photos, information, and memorial materials are stored and transmitted using modern security practices.',
      'services.sec3Title': 'Privacy-First by Design',
      'services.sec3Desc': 'Memorio is built from the ground up for sensitive situations, not for marketing data or advertising.',
      'services.ctaTitle': 'Ready to Simplify Your Operations?',
      'services.ctaSubtitle': 'See how Memorio can reduce your administrative burden and help you deliver exceptional tributes consistently.',
      'services.ctaBook': 'Book a Demo',
      'services.ctaTalk': 'Talk to Us',
      
      // Footer
      'footer.aboutTitle': 'About Memorio',
      'footer.aboutDesc': 'Memorio helps funeral homes create beautiful, personalized video tributes & personalised obituaries that honor and celebrate the lives of loved ones with dignity and care.',
      'footer.quickLinks': 'Quick Links',
      'footer.support': 'Support',
      'footer.privacy': 'Privacy Policy',
      'footer.terms': 'Terms of Service',
      'footer.copyright': '© 2026 Memorio. All rights reserved. Honoring life, one story at a time.',
      
      // Family Portal
      'family.dashboard': 'Family Dashboard',
      'family.welcomeBack': 'Welcome Back',
      'family.formIncomplete': 'Obituary Form Incomplete',
      'family.completeForm': 'Complete Obituary Form',
      'family.requestRevision': 'Request Revision',
      'family.revisionRequest': 'Request Video Revision',
      'family.revisionNotes': 'What changes would you like to see?',
      'family.revisionCharCount': 'characters',
      'family.revisionMinimum': '(minimum 25 characters)',
      'family.submitRevision': 'Submit Revision Request',
      'family.approveVideo': 'Approve Video',
      'family.videoApproved': 'Video Approved!',
      'family.revisionComplete': 'Your revision is complete',
      'family.downloadVideo': 'Download Video',
      'family.downloadObituary': 'Download Obituary',
      'family.loginTitle': 'Family Portal',
      'family.loginSubtitle': 'Sign in to complete your obituary form',
      'family.signIn': 'Sign In',
      'family.signingIn': 'Signing in...',
      'family.noCredentials': 'Don\'t have login credentials?',
      'family.contactDirector': 'Contact your funeral director for access.',
      'family.loginSuccess': 'Login successful! Redirecting...',
      'family.myCase': 'My Case',
      'family.caseStatus': 'Case Status',
      'family.obituaryDraft': 'Obituary Draft',
      'family.completedObituary': 'Completed Obituary',
      'family.memorialVideo': 'Memorial Video',
      'family.memorialComplete': 'Your Memorial is Complete',
      'family.memorialCompleteDesc': 'The obituary and video have been delivered to the family',
      'family.revisionAlertMin': 'Please provide at least 25 characters describing the changes you\'d like.',
      'family.revisionSubmitSuccess': 'Revision request submitted successfully! Our team will review your feedback and make the necessary changes.',
      'family.revisionSubmitError': 'Failed to submit revision request. Please try again.',
      'family.caseID': 'Case ID',
      'family.created': 'Created',
      'family.lastUpdated': 'Last Updated',
      'family.loading': 'Loading...',
      'family.loadingCase': 'Loading your case...',
      'family.loadingObituary': 'Loading obituary...',
      'family.obituarySection': 'Obituary',
      'family.editObituary': 'Edit Obituary',
      'family.downloadPDF': 'Download PDF',
      'family.downloadObituaryPDF': 'Download Obituary PDF',
      'family.completeObituaryForm': 'Complete Obituary Form',
      'family.downloadFinalObituary': 'Download Final Obituary',
      'family.caseCreated': 'Case Created',
      'family.formSubmitted': 'Obituary Form Submitted',
      'family.notifications': 'Notifications',
      'family.loadingNotifications': 'Loading notifications...',
      'family.pleaseWait': 'Please wait while we load your case updates.',
      'family.obituaryUpdated': 'Obituary updated successfully!',
      'family.editObituaryTitle': 'Edit Obituary',
      'family.obituaryTitle': 'Obituary Title',
      'family.obituaryContent': 'Obituary Content',
      'family.saveChanges': 'Save Changes',
      'family.cancel': 'Cancel',
      'family.obituaryPDFDownloaded': 'Obituary PDF downloaded!',
      'family.createdWithCare': 'Created with care by Memorio',

      // Family Dashboard — additional UI strings
      'family.photosSection': 'Photos',
      'family.uploadPhotos': 'Click to upload photos',
      'family.memorialTributeVideo': 'Memorial Tribute Video',
      'family.timelineUpdates': 'Timeline & Updates',
      'family.makeChanges': 'Make Changes',
      'family.noObituaryYet': 'No obituary submitted yet.',
      'family.noCaseFound': 'No Case Found',
      'family.noCaseAssigned': 'No case has been assigned to your account yet. Please contact your funeral director for assistance.',
      'family.formSubmittedAwaiting': 'Form Submitted — Awaiting Processing',

      // Family Dashboard — revision modal
      'family.revisionOnlyOne': 'This is your only revision request',
      'family.revisionPleaseSpecific': 'Please be specific about the changes you need. Your editor will review your feedback and make the necessary adjustments.',
      'family.revisionWhatChanges': 'What changes would you like made to your memorial video?',
      'family.revisionPlaceholder': 'Please describe the changes you\'d like to see in your memorial video.\n\nFor example:\n• Add or remove specific photos\n• Adjust the music selection\n• Change the timing or pacing\n• Correct any information\n\nBe as specific as possible so our editor can make the right changes.',
      'family.confirmRevisionTitle': 'Confirm Revision Request',
      'family.revisionConfirmText': 'Are you sure you want to submit this revision request? Once submitted, you won\'t be able to request another revision.',
      'family.yesSubmitRevision': 'Yes, Submit Revision',

      // Family Dashboard — case status labels
      'family.status.created': 'Created',
      'family.status.waitingOnFamily': 'Waiting on Form',
      'family.status.intakeInProgress': 'Form In Progress',
      'family.status.submitted': 'Form Submitted',
      'family.status.inProduction': 'In Production',
      'family.status.awaitingReview': 'Awaiting Review',
      'family.status.delivered': 'Delivered',
      'family.status.closed': 'Closed',

      // Family Dashboard — dashboard title
      'family.title.tributeReady': 'Your tribute is ready, {name}',
      'family.title.thankYou': 'Thank you {name}. We\'ll take it from here.',

      // Family Dashboard — timeline
      'family.timeline.caseCreated': 'Case Created',
      'family.timeline.caseCreatedDesc': 'Case created for {name}',
      'family.timeline.formSubmitted': 'Obituary Form Submitted',
      'family.timeline.formSubmittedDesc': 'Family completed and submitted the obituary form',
      'family.timeline.awaitingProcessing': 'Awaiting Processing',
      'family.timeline.awaitingProcessingDesc': 'Your obituary is being processed by our team',
      'family.timeline.inProduction': 'In Production',
      'family.timeline.inProductionDesc': 'Your memorial video is being created',
      'family.timeline.delivered': 'Delivered',
      'family.timeline.deliveredDesc': 'Your memorial video is ready for download',
      'family.timeline.current': 'Current',

      // Family Dashboard — notifications
      'family.notif.actionRequired': 'Action Required',
      'family.notif.actionRequiredText': 'Please complete the obituary form to proceed with your memorial video.',
      'family.notif.formReceived': 'Form Received',
      'family.notif.formReceivedText': 'Thank you! We have received your obituary form and will begin processing soon.',
      'family.notif.inProgress': 'In Progress',
      'family.notif.inProgressText': 'Your memorial video is currently being created. We will notify you when it\'s ready.',
      'family.notif.noNotifications': 'No new notifications',
      'family.notif.allCaughtUp': 'You\'re all caught up!',
      'family.notif.now': 'Now',
      'family.notif.recent': 'Recent',

      // Family Dashboard — obituary editor modal
      'family.editor.title': 'Edit Obituary',
      'family.editor.titleLabel': 'Obituary Title',
      'family.editor.contentLabel': 'Obituary Content',
      'family.editor.hint': 'Feel free to make any changes to honor your loved one\'s memory.',
      'family.editor.saveChanges': 'Save Changes',
      'family.editor.cancel': 'Cancel',
      'family.revisionInProgress': 'Revision in Progress',
      'family.editorWorkingOnChanges': 'Our editor is working on the changes',

      // Family Dashboard — upload window timer
      'family.upload.windowActive': 'Upload Window Active',
      'family.upload.windowActiveDesc': 'Time remaining to upload additional photos. After this window closes, our editors will begin creating your memorial video.',
      'family.upload.windowClosed': 'Upload Window Closed',
      'family.upload.windowClosedDesc': 'The 12-hour upload window has ended. You can still view all your uploaded photos below.',
      'family.upload.windowExpiredAlert': 'The 12-hour upload window has closed. You can no longer add photos to this case.',

      // Family Form — Password Change Modal
      'family.changePasswordTitle': '🔒 Change Your Password',
      'family.changePasswordDesc': 'For security reasons, you must change your temporary password before accessing your account.',
      'family.newPassword': 'New Password*',
      'family.enterNewPassword': 'Enter new password',
      'family.passwordMinLength': 'Must be at least 8 characters',
      'family.confirmNewPassword': 'Confirm New Password*',
      'family.confirmNewPasswordPlaceholder': 'Confirm new password',
      'family.changePasswordBtn': 'CHANGE PASSWORD',
      'family.passwordUpdated': 'Password Updated!',
      'family.passwordUpdatedDesc': 'Your password has been successfully changed. You can now proceed with the form.',
      'family.proceed': 'Proceed',

      // Family Form
      'form.title': 'Memorial Tribute Form',
      'form.subtitle': 'Help us create a meaningful tribute',
      'form.basicInfo': 'Basic Information',
      'form.lifeStory': 'Life Story',
      'form.familyMembers': 'Family Members',
      'form.photoUpload': 'Photo Upload',
      'form.musicPreferences': 'Music Preferences',
      'form.additionalNotes': 'Additional Notes',
      'form.nextStep': 'Next Step',
      'form.previousStep': 'Previous Step',
      'form.submitForm': 'Submit Form',
      'form.saving': 'Saving...',
      'form.saved': 'Saved',

      // Family Form — inline content
      'form.header': 'Memorios Obituary Writer',
      'form.letsBegin': 'Lets begin!',
      'form.intro': "Take your time, each question helps us gently piece together a heartfelt memory. There's no rush.",
      'form.otherNamesPrefix': "Any other names you'd like to include for ",
      'form.otherNamesSuffix': '?',
      'form.salutationPlaceholder': 'Salutation',
      'form.middleNamePlaceholder': 'Middle Name',
      'form.nicknamePlaceholder': 'Nickname',
      'form.maidenNamePlaceholder': 'Maiden Name',
      'form.suffixOption': 'Suffix (Jr, Sr, etc.)',
      'form.requiredFields': '*Required Fields',
      'form.nextBtn': 'NEXT',
      'form.backBtn': 'BACK',
      'form.submitBtn': 'SUBMIT',
      'form.signOut': 'Sign Out',
      'form.photoIntro': "Every life is a collection of beautiful moments. Upload photos to help us honor your loved one's journey.",
      'form.selectPhotos': 'Select Photos',
      'form.musicQuestion': 'What music would you like for the tribute video?',
      'form.pianoOption': 'Piano',
      'form.guitarOption': 'Guitar',
      'form.tributeQuoteQuestion': "Is there a favorite quote, verse, or saying you'd like us to include in the tribute video?",
      'form.tributeQuotePlaceholder': 'Something they always said or something that reminds you of them and captures their spirit.',
      'form.specialDetails': 'Would You Like to Add Any Special Details?',
      'form.almostDone': 'Almost done, just review the information and add any final details of your choice. Once you submit your obituary will be created.',
      'form.anythingElse': 'Is there anything else you want to include in the Obituary?',
      'form.serviceInfo': 'Would you like to include any service or event information?',
      'form.serviceInfoPlaceholder': 'Add info about upcoming services: time, place, dress code, or anything guests should know.',
      'form.formError': 'Oops! Something went wrong while submitting the form.',

      // Family Form — obituary generation screen
      'form.craftingStory': 'Crafting {name} story...',
      'form.tributeCrafted': 'Thank you for sharing about {name}. Here\'s the tribute we\'ve crafted based on the memories you provided.',
      'form.updatedObituaryTitle': 'Here\'s your obituary',
      'form.obituaryTitleFor': 'for',
      'form.editHint': 'You can always make changes in the dashboard',
      'form.accessDashboard': 'Access Dashboard',

      'form.accordion.familyMembers': 'Family Members',
      'form.accordion.personalDetails': 'Personal Details',
      'form.accordion.education': 'Education',
      'form.accordion.hobbies': 'Hobbies / Interests',
      'form.accordion.career': 'Career Highlights',
      'form.accordion.religion': 'Religion / Spirituality',
      'form.accordion.military': 'Military Service',
      'form.accordion.save': 'Save',
      'form.accordion.add': 'Add',
      'form.accordion.familyMembersLabel': 'Who were the important people in their life?',
      'form.accordion.familyMembersPlaceholder': 'Please share the names of parents, siblings, children, close relatives, or dear friends who were important in their life.',
      'form.accordion.personalDetailsLabel': 'Describe them as a person',
      'form.accordion.personalDetailsPlaceholder': 'What were they known for by loved ones?',
      'form.accordion.educationLabel': 'What were their achievements?',
      'form.accordion.educationPlaceholder': 'List the name and location of schools they attended. Include degrees, certificates, or special honors they received.',
      'form.accordion.hobbiesLabel': 'What stood out to them?',
      'form.accordion.hobbiesPlaceholder': 'List activities that or interests that were important to your loved one.',
      'form.accordion.careerLabel': 'Tell us about their career highlights',
      'form.accordion.careerPlaceholder': 'List work experience and any related accomplishments. Feel free to include dates and proud moments.',
      'form.accordion.religionLabel': 'What role did religion or spirituality have in their life?',
      'form.accordion.religionPlaceholder': 'List places of worship, acts of service, faith related travel, or important values your loved one held.',
      'form.accordion.militaryLabel': 'Tell us about their military service',
      'form.accordion.militaryPlaceholder': 'If they were a veteran, list the branch, rank, and time served, along with location.',

      // Editor Portal
      'editor.dashboard': 'Editor Dashboard',
      'editor.myAssignments': 'My Assignments',
      'editor.noAssignments': 'No assignments available',
      'editor.uploadVideo': 'Upload Video',
      'editor.submitForReview': 'Submit for QC Review',
      'editor.uploading': 'Uploading...',
      'editor.processing': 'Processing...',
      'editor.checkWorkload': 'Check Workload',
      'editor.editHistory': 'Edit History',
      'editor.completedCases': 'Completed Cases',
      'editor.videosEdited': 'Videos Edited',
      'editor.loginTitle': 'Video Editor Portal',
      'editor.loginSubtitle': 'Sign in to create memorial tribute videos',
      'editor.signIn': 'Sign In',
      'editor.signingIn': 'Signing in...',
      'editor.noCredentials': 'Don\'t have login credentials?',
      'editor.contactAdmin': 'Contact your admin for access.',
      'editor.loginSuccess': 'Login successful! Redirecting...',
      'editor.totalCompleted': 'Total Completed',
      'editor.approved': 'Approved',
      'editor.revisionsRequested': 'Revisions Requested',
      'editor.noCasesYet': 'No completed cases yet.',
      'editor.submittedVideos': 'Your submitted videos will appear here.',
      'editor.uploadLocked': 'Locked - Family Upload Window Active',
      'editor.uploadLockedMsg': 'Video uploads are disabled during the family photo upload window (12 hours after form submission).',
      'editor.submittedForReview': 'Submitted for Review',
      'editor.workloadRefreshed': 'Workload refreshed!',
      'editor.caseDetails': 'Case Details',
      'editor.deceasedInfo': 'Deceased Information',
      'editor.caseMetadata': 'Case Metadata',
      'editor.photosSection': 'Photos',
      'editor.photoTimerLocked': 'Photos Locked - Family Still Uploading',
      'editor.photoTimerExpired': 'Waiting for Family Submission',
      'editor.photoTimerMessage': 'The family has a 12-hour window to upload additional photos after submitting their form. Photos will be available for download once this window expires to ensure you have all the photos before starting your work.',
      'editor.videoUploadsDisabled': 'Video uploads are also disabled during this period.',
      'editor.downloadAll': 'Download All Photos',
      'editor.videoUploadSection': 'Video Upload',
      'editor.selectVideo': 'Select Video File',
      'editor.editorNotes': 'Editor Notes',
      'editor.editorNotesPlaceholder': 'Add any notes about your edits, music choices, or special considerations...',
      'editor.submitVideo': 'Submit Video for QC Review',
      'editor.submissionStatus': 'Submission Status',
      'editor.viewCase': 'View Case',
      'editor.noAssignmentsDesc': 'You currently have no cases assigned. Check back later or contact your admin.',
      'editor.photosLockedMsg': 'Photos are locked - family still uploading. Please wait for the upload window to expire.',
      'editor.cannotUploadDuringWindow': 'Cannot upload video during the 12-hour family upload window. Please wait for the window to expire before submitting your video.',
      'editor.videoTooLarge': 'Video file is too large. Maximum size is 1.5GB',
      'editor.videoUploadSuccess': 'Video uploaded successfully! Submitting to QC...',
      'editor.videoSubmissionSuccess': 'Video submitted for QC review successfully!',
      
      // QC Portal
      'qc.dashboard': 'QC Dashboard',
      'qc.pendingReview': 'Pending QC Review',
      'qc.approve': 'Approve',
      'qc.requestRevision': 'Request Revision',
      'qc.approved': 'Approved',
      'qc.rejected': 'Rejected',
      'qc.passRate': 'Pass Rate',
      'qc.loginTitle': 'Quality Control Portal',
      'qc.loginSubtitle': 'Sign in to review memorial tributes',
      'qc.signIn': 'Sign In',
      'qc.signingIn': 'Signing in...',
      'qc.noCredentials': 'Don\'t have login credentials?',
      'qc.contactAdmin': 'Contact your admin for access.',
      'qc.loginSuccess': 'Login successful! Redirecting...',
      
      // Admin Portal
      'admin.dashboard': 'Admin Dashboard',
      'admin.createOrg': 'Create Organization',
      'admin.inviteDirector': 'Invite Director',
      'admin.inviteEditor': 'Invite Editor',
      'admin.inviteQC': 'Invite QC User',
      'admin.allAccounts': 'All Accounts',
      'admin.analytics': 'Analytics',
      'admin.orgDetails': 'Organization Details',
      'admin.orgName': 'Organization Name',
      'admin.orgEmail': 'Contact Email',
      'admin.orgPhone': 'Contact Phone',
      'admin.orgRegion': 'Region',
      'admin.createOrgBtn': 'CREATE ORGANIZATION',
      'admin.orgCreatedSuccess': 'Organization Created Successfully!',
      
      // Case Status
      'status.waitingOnFamily': 'Waiting on Family',
      'status.inProgress': 'In Progress',
      'status.awaitingReview': 'Awaiting Review',
      'status.complete': 'Complete',
      'status.delivered': 'Delivered',
      'status.revisionRequested': 'Revision Requested',
      
      // Timeline Events
      'timeline.caseCreated': 'Case Created',
      'timeline.familyInvited': 'Family Invited',
      'timeline.formSubmitted': 'Form Submitted',
      'timeline.editorAssigned': 'Editor Assigned',
      'timeline.videoSubmitted': 'Video Submitted',
      'timeline.qcApproved': 'QC Approved',
      'timeline.delivered': 'Delivered to Family',
      
      // Errors & Validation
      'error.required': 'This field is required',
      'error.invalidEmail': 'Please enter a valid email',
      'error.passwordMismatch': 'Passwords do not match',
      'error.uploadFailed': 'Upload failed',
      'error.networkError': 'Network error. Please try again.',
      
      // Success Messages
      'success.saved': 'Saved successfully',
      'success.uploaded': 'Uploaded successfully',
      'success.submitted': 'Submitted successfully',
      'success.deleted': 'Deleted successfully',
    },
    
    es: {
      // Common
      'common.loading': 'Cargando...',
      'common.save': 'Guardar',
      'common.cancel': 'Cancelar',
      'common.delete': 'Eliminar',
      'common.edit': 'Editar',
      'common.submit': 'Enviar',
      'common.close': 'Cerrar',
      'common.confirm': 'Confirmar',
      'common.yes': 'Sí',
      'common.no': 'No',
      'common.logout': 'Cerrar Sesión',
      'common.search': 'Buscar',
      'common.filter': 'Filtrar',
      'common.copy': 'Copiar',
      'common.download': 'Descargar',
      'common.upload': 'Subir',
      'common.error': 'Error',
      'common.success': 'Éxito',
      'common.emailAddress': 'Dirección de Correo Electrónico',
      'common.password': 'Contraseña',
      'common.enterEmail': 'Ingrese su correo electrónico',
      'common.enterPassword': 'Ingrese su contraseña',
      'common.rateLimitExceeded': 'Demasiados intentos fallidos. Por favor, inténtelo de nuevo en {minutes} minuto(s).',
      'common.loginFailed': 'Error al iniciar sesión. Por favor, verifique sus credenciales.',
      'common.unexpectedError': 'Ocurrió un error inesperado. Por favor, inténtelo de nuevo.',
      
      // Navigation (shared across pages)
      'nav.home': 'Inicio',
      'nav.features': 'Características',
      'nav.howItWorks': 'Cómo Funciona',
      'nav.benefits': 'Beneficios',
      'nav.faq': 'Preguntas Frecuentes',
      'nav.services': 'Servicios',
      'nav.familyLogin': 'Acceso Familiar',
      
      // Main Website
      'website.nav.features': 'Características',
      'website.nav.howItWorks': 'Cómo Funciona',
      'website.nav.benefits': 'Beneficios',
      'website.nav.faq': 'Preguntas Frecuentes',
      'website.nav.services': 'Servicios',
      'website.nav.familyLogin': 'Acceso Familiar',
      'website.hero.title': 'Una Hermosa Forma de Recordar a Alguien que Amas',
      'website.hero.subtitle1': 'Cuando las palabras son difíciles y el tiempo es corto, Memorio ayuda a las familias y funerarias a crear tributos en video significativos y obituarios con cuidado, dignidad y apoyo profesional.',
      'website.hero.subtitle2': 'Las familias reciben una experiencia guiada simple. Las funerarias reciben los activos memoriales terminados en 48 horas.',
      'website.hero.getStarted': 'Comience Su Tributo',
      'website.hero.learnMore': 'Para Funerarias →',
      
      // Mission Section
      'website.mission.title': 'Por Qué Existe Memorio',
      'website.mission.problem': 'El Problema',
      'website.mission.problemDesc': 'Los profesionales funerarios pasan un tiempo valioso editando videos y formateando obituarios en lugar de estar con las familias.',
      'website.mission.solution': 'Nuestra Solución',
      'website.mission.solutionDesc': 'Memorio elimina la producción memorial de su flujo de trabajo, permitiéndole concentrarse en el cuidado, la orientación y las familias.',
      
      'website.features.title': 'Todo Lo Que Necesitas Para Honrar Una Vida',
      'website.features.subtitle': 'Memorio proporciona una solución completa para crear tributos conmemorativos significativos',
      'website.features.realSupport': 'Apoyo Real y Compasivo',
      'website.features.realSupportDesc': 'Si necesita ayuda u orientación, el soporte está disponible en cada paso del camino.',
      'website.howItWorks.title': 'Cómo Funciona',
      'website.howItWorks.subtitle': 'Crear un tributo significativo no tiene que ser complicado.',
      'website.howItWorks.step1': 'Su Funeraria Lo Inicia',
      'website.howItWorks.step1Desc': 'Su director de funeraria proporcionará un enlace seguro para que su familia comience el proceso.',
      'website.howItWorks.step2': 'Comparta Fotos y Recuerdos',
      'website.howItWorks.step2Desc': 'Suba fotos y responda algunas preguntas suaves y guiadas sobre la vida de su ser querido.',
      'website.howItWorks.step3': 'Creamos el Tributo',
      'website.howItWorks.step3Desc': 'Sus recuerdos se transforman cuidadosamente en un obituario bellamente escrito y un video de tributo.',
      'website.howItWorks.step4': 'Su Tributo es Entregado',
      'website.howItWorks.step4Desc': 'Una vez completo, el tributo terminado se entrega al portal privado de su familia.',
      'website.faq.title': 'Preguntas Frecuentes',
      'website.faq.subtitle': 'Todo lo que necesita saber sobre el uso de Memorio.',
      'website.faq.q1': '¿Es segura la información de mi familia?',
      'website.faq.a1': 'Sí. Utilizamos medidas de seguridad sólidas y controles de acceso estrictos para proteger sus recuerdos e información personal.',
      'website.faq.q2': '¿Cuánto tiempo tarda en recibir todo?',
      'website.faq.a2': 'Su obituario se genera inmediatamente después de que termine nuestro formulario guiado. Su video de tributo se entrega dentro de 48 horas.',
      'website.faq.q3': '¿Será difícil de usar para mi familia?',
      'website.faq.a3': 'No. El proceso es simple, guiado y diseñado para personas que pueden no sentirse cómodas con la tecnología.',
      'website.faq.q4': '¿Se manejará el tributo de nuestro ser querido con cuidado y respeto?',
      'website.faq.a4': 'Absolutamente. Esto no es "contenido" para nosotros. Es la historia de vida de alguien y se trata con la dignidad que merece.',
      'website.faq.q5': '¿Quién crea el video tributo?',
      'website.faq.a5': 'Memorio genera el obituario usando IA avanzada basada en la información proporcionada por la familia. El video tributo se ensambla usando las fotos, preferencias musicales y recuerdos enviados a través del portal familiar. Cada tributo pasa por control de calidad antes de la entrega final.',
      'website.faq.q6': '¿Necesito habilidades técnicas para usar Memorio?',
      'website.faq.a6': 'No se requiere experiencia técnica. El proceso está guiado paso a paso para hacerlo simple durante un momento difícil.',
      'website.cta.title': '¿Listo Para Comenzar a Crear un Tributo?',
      'website.cta.subtitle': 'Si su funeraria usa Memorio, su director funerario proporcionará credenciales de inicio de sesión seguras para el portal familiar.',
      'website.cta.button': 'Acceder al Portal Familiar',
      'website.footer.about': 'Acerca de Memorio',
      'website.footer.aboutDesc': 'Memorio trabaja junto con las funerarias para producir obituarios y tributos en video que honran a los seres queridos con dignidad mientras simplifica el proceso memorial para las familias.',
      'website.footer.quickLinks': 'Enlaces Rápidos',
      'website.footer.login': 'Iniciar Sesión',
      'website.footer.support': 'Soporte',
      'website.footer.familyPortal': 'Portal Familiar',
      'website.footer.directorPortal': 'Portal del Director',
      'website.footer.privacyPolicy': 'Política de Privacidad',
      'website.footer.termsOfService': 'Términos de Servicio',
      'website.footer.copyright': '© 2026 Memorio. Todos los derechos reservados. Honrando la vida, una historia a la vez.',
      'website.features.whyChoose': 'Por Qué Elegir Memorio',
      'website.features.whyChooseDesc': 'Memorio simplifica el proceso memorial para las familias mientras garantiza que las funerarias reciban tributos preparados profesionalmente listos para el servicio.',
      'website.features.guidedProcess': 'Simple para las Familias',
      'website.features.guidedProcessDesc': 'Las familias responden preguntas guiadas y suben fotos a través de una experiencia tranquila paso a paso diseñada para un momento difícil.',
      'website.features.privateSecure': 'Privado y Seguro',
      'website.features.privateSecureDesc': 'Los recuerdos familiares y la información personal están protegidos con seguridad sólida y controles de acceso estrictos.',
      'website.features.beautifullyCrafted': 'Producido con Cuidado',
      'website.features.beautifullyCraftedDesc': 'Cada tributo se ensambla con cuidado, combinando fotos, música y ritmo que honran a su ser querido con dignidad.',
      'website.features.readyWhenNeeded': 'Entregado en 48 Horas',
      'website.features.readyWhenNeededDesc': 'Los tributos memoriales y obituarios se completan rápida y cuidadosamente para que las familias y funerarias tengan todo listo cuando más importa.',
      'website.features.everythingInOnePlace': 'Organizado en Un Solo Lugar',
      'website.features.everythingInOnePlaceDesc': 'Fotos, recuerdos y materiales de tributo se recopilan en una sola ubicación segura para simplificar todo el proceso.',
      'website.howItWorks.subtitle': 'Crear un tributo significativo no tiene que ser complicado.',
      'website.howItWorks.step1': 'La Familia Comparte Recuerdos',
      'website.howItWorks.step1Desc': 'Las familias responden preguntas guiadas y suben fotos a través de un portal seguro.',
      'website.howItWorks.step2': 'Memorio Produce el Tributo',
      'website.howItWorks.step2Desc': 'Memorio genera el obituario usando IA avanzada y ensambla el video tributo con música, ritmo y edición profesional. Cada tributo se revisa para garantizar la calidad antes de la entrega.',
      'website.howItWorks.step3': 'Entregado a la Familia y Funeraria',
      'website.howItWorks.step3Desc': 'Una vez aprobado, el obituario final y el video tributo se entregan simultáneamente tanto a la familia como a la funeraria dentro de 48 horas de la presentación, listos para servicios o para compartir en línea.',
      
      // Director Portal
      'director.dashboard': 'Panel del Director',
      'director.createCase': 'Crear Nuevo Caso',
      'director.createCaseDesc': 'Comience un nuevo caso de tributo conmemorativo proporcionando la información del ser querido.',
      'director.inviteFamily': 'Invitar Familia',
      'director.myCases': 'Mis Casos',
      'director.caseDetails': 'Detalles del Caso',
      'director.lovedOneName': 'Nombre Completo del Ser Querido',
      'director.gender': 'Género',
      'director.gender.select': 'Seleccionar Género',
      'director.gender.male': 'Masculino',
      'director.gender.female': 'Femenino',
      'director.gender.other': 'Otro',
      'director.gender.specify': 'Por Favor Especifique Género/Pronombres',
      'director.gender.specifyHelper': 'Esto se utilizará en el tributo conmemorativo',
      'director.dateOfBirth': 'Fecha de Nacimiento',
      'director.dateOfPassing': 'Fecha de Fallecimiento',
      'director.cityOfBirth': 'Ciudad de Nacimiento',
      'director.stateOfBirth': 'Estado/Provincia de Nacimiento',
      'director.countryOfBirth': 'País de Nacimiento',
      'director.cityOfDeath': 'Ciudad de Fallecimiento',
      'director.stateOfDeath': 'Estado/Provincia de Fallecimiento',
      'director.countryOfDeath': 'País de Fallecimiento',
      'director.createCaseBtn': 'CREAR CASO',
      'director.changePassword': 'Cambie Su Contraseña',
      'director.changePasswordDesc': 'Por razones de seguridad, debe cambiar su contraseña temporal antes de acceder al panel.',
      'director.newPassword': 'Nueva Contraseña',
      'director.confirmPassword': 'Confirmar Nueva Contraseña',
      'director.passwordMinLength': 'Debe tener al menos 8 caracteres',
      'director.changePasswordBtn': 'CAMBIAR CONTRASEÑA',
      'director.noCases': 'No se encontraron casos',
      'director.noCasesDesc': '¡Cree su primer caso para comenzar!',
      'director.caseCreatedSuccess': '¡Caso Creado Con Éxito!',
      'director.caseCreatedDesc': 'Se ha generado el ID del caso. Ahora puede invitar a la familia a completar el formulario de homenaje.',
      'director.familyInvitationSuccess': '¡Invitación Familiar Enviada!',
      'director.copyBtn': 'Copiar',
      'director.inviteFamilyTitle': 'Invitar Miembro de la Familia',
      'director.inviteFamilyDesc': 'Envíe una invitación segura a un miembro de la familia para completar el formulario de homenaje para su caso.',
      'director.familyMemberDetails': 'Detalles del Miembro de la Familia',
      'director.familyMemberDetailsDesc': 'Proporcione información de contacto y asocie con un ID de caso',
      'director.emailAddress': 'Dirección de Correo Electrónico',
      'director.fullName': 'Nombre Completo',
      'director.phoneNumber': 'Número de Teléfono (Opcional)',
      'director.caseID': 'ID del Caso',
      'director.sendInvitation': 'ENVIAR INVITACIÓN',
      'director.myCasesDesc': 'Ver y gestionar todos sus casos de homenaje conmemorativo',
      'director.searchCases': 'Buscar casos por nombre o ID...',
      'director.caseInformation': 'Información del Caso',
      'director.status': 'Estado',
      'director.created': 'Creado',

      // Director — new Spanish keys
      'director.lovedOnesInfo': 'Información del Ser Querido',
      'director.allFieldsRequired': 'Todos los campos son necesarios para generar el obituario completo',
      'director.fullNamePlaceholder': 'Juan Miguel García',
      'director.genderSpecifyPlaceholder': 'Ej.: No binario, Él/Ella, etc.',
      'director.optional': '(opcional)',
      'director.stateOptionalPlaceholder': 'Ej.: Nueva York, Greater Manchester (dejar en blanco si no aplica)',
      'director.serviceDate': 'Fecha del Servicio',
      'director.familyInvitedSuccess': '¡Familiar Invitado con Éxito!',
      'director.familyInvitedDesc': 'Comparta estas credenciales con el familiar. Las necesitarán para acceder al formulario de tributo.',
      'director.tempPassword': 'Contraseña Temporal',
      'director.copy': 'Copiar',
      'director.caseInfo': 'Información del Caso',
      'director.caseId': 'ID del Caso',
      'director.copyFullId': 'Copiar ID Completo',
      'director.statusLabel': 'Estado',
      'director.createdLabel': 'Creado',
      'director.lastUpdated': 'Última Actualización',
      'director.familyInfo': 'Información Familiar',
      'director.familyMember': 'Familiar',
      'director.emailLabel': 'Correo Electrónico',
      'director.familyLoginCredentials': 'Credenciales de Acceso Familiar',
      'director.reveal': 'Revelar',
      'director.passwordLabel': 'Contraseña',
      'director.clickReveal': 'Haz clic en Revelar',
      'director.formStatusTitle': 'Estado del Formulario',
      'director.formStatusLabel': 'Estado del Formulario',
      'director.submittedAt': 'Enviado el',
      'director.obituaryDraft': 'Borrador del Obituario',
      'director.lastUpdatedLabel': 'Última actualización:',
      'director.photosAssets': 'Fotos y Archivos',
      'director.uploadPhotos': 'Subir Fotos',
      'director.uploadPhotosHint': 'Haz clic para seleccionar fotos (JPEG, PNG, GIF)',
      'director.noPhotos': 'Aún no se han subido fotos',
      'director.memorialComplete': 'Memorial Completo',
      'director.memorialDelivered': 'El obituario y el video han sido entregados a la familia',
      'director.downloads': 'Descargas',
      'director.downloadVideo': 'Descargar Video Memorial',
      'director.downloadObituaryPdf': 'Descargar PDF del Obituario',
      'director.close': 'Cerrar',
      'director.deleteCase': 'Eliminar Caso',
      'director.cancel': 'Cancelar',
      'director.newPasswordPlaceholder': 'Ingresa nueva contraseña',
      'director.confirmPasswordPlaceholder': 'Confirma nueva contraseña',

      // Services page — Spanish
      'services.heroTitle': 'Diseñado Para Funerarias',
      'services.heroSubtitle': 'Optimice sus operaciones, reduzca la carga administrativa y entregue tributos consistentes y profesionales que honren cada vida con dignidad.',
      'services.whyTitle': 'Por Qué las Funerarias Eligen Memorio',
      'services.whySubtitle': 'Calidad constante, entregas más rápidas y menos trabajo para su equipo, sin añadir complejidad a su operación.',
      'services.feat1Title': 'Resultados Consistentes y Profesionales',
      'services.feat1Desc': 'Cada familia recibe un obituario bien escrito y un video tributo que cumple el mismo estándar cada vez, independientemente de la carga de trabajo del personal.',
      'services.feat2Title': 'Video en 48 Horas',
      'services.feat2Desc': 'Los videos de tributo se entregan en un plazo de 48 horas tras la presentación, ayudándole a avanzar en los casos sin demoras.',
      'services.feat3Title': 'Menos Trabajo para Su Equipo',
      'services.feat3Desc': 'Su personal ya no necesita buscar fotos, redactar obituarios ni crear videos. Memorio gestiona las partes más laboriosas para que su equipo pueda centrarse en las familias.',
      'services.feat4Title': 'Un Proceso Fiable y Repetible',
      'services.feat4Desc': 'Cada caso sigue el mismo proceso claro de principio a fin, asegurando que nada se pase por alto.',
      'services.feat5Title': 'Mejor Experiencia para la Familia',
      'services.feat5Desc': 'Las familias tienen una forma sencilla y guiada de proporcionar información y recibir un memorial terminado sin confusión.',
      'services.feat6Title': 'Control de Calidad Integrado',
      'services.feat6Desc': 'Cada obituario y video se verifica antes de la entrega para garantizar que cumple los estándares profesionales.',
      'services.opsTitle': 'Beneficios Operacionales',
      'services.opsSubtitle': 'Lo que Memorio reemplaza o simplifica en sus operaciones diarias',
      'services.ops1Title': 'Administración Reducida',
      'services.ops1Desc': 'Automatice la gestión de casos, comunicaciones familiares y seguimiento del estado. Sin más hojas de cálculo ni seguimientos manuales.',
      'services.ops2Title': 'Menos Seguimientos',
      'services.ops2Desc': 'Las familias reciben recordatorios automáticos e instrucciones claras. El sistema rastrea el progreso para que sepa exactamente dónde se encuentra cada caso.',
      'services.ops3Title': 'Tiempos de Entrega Predecibles',
      'services.ops3Desc': 'El flujo de trabajo estandarizado garantiza tiempos de entrega consistentes. Establezca expectativas con las familias y cúmplalas siempre.',
      'services.ops4Title': 'Estándares Profesionales',
      'services.ops4Desc': 'Cada tributo cumple los mismos estándares de alta calidad. Sin preocupaciones por resultados inconsistentes.',
      'services.secTitle': 'Seguridad y Cumplimiento',
      'services.secSubtitle': 'Seguridad de nivel empresarial diseñada para datos sensibles y cumplimiento normativo',
      'services.sec1Title': 'Control de Acceso Estricto',
      'services.sec1Desc': 'Solo las personas correctas pueden ver cada caso. La información familiar nunca se expone, comparte ni mezcla entre cuentas.',
      'services.sec2Title': 'Almacenamiento Seguro',
      'services.sec2Desc': 'Todas las fotos, información y materiales memoriales se almacenan y transmiten utilizando prácticas de seguridad modernas.',
      'services.sec3Title': 'Privacidad por Diseño',
      'services.sec3Desc': 'Memorio está construido desde cero para situaciones sensibles, no para datos de marketing ni publicidad.',
      'services.ctaTitle': '¿Listo para Simplificar Sus Operaciones?',
      'services.ctaSubtitle': 'Vea cómo Memorio puede reducir su carga administrativa y ayudarle a entregar tributos excepcionales de manera consistente.',
      'services.ctaBook': 'Reservar una Demo',
      'services.ctaTalk': 'Contáctenos',

      // Footer — Spanish
      'footer.aboutTitle': 'Sobre Memorio',
      'footer.aboutDesc': 'Memorio ayuda a las funerarias a crear hermosos tributos de video personalizados y obituarios personalizados que honran y celebran la vida de los seres queridos con dignidad y cuidado.',
      'footer.quickLinks': 'Enlaces Rápidos',
      'footer.support': 'Soporte',
      'footer.privacy': 'Política de Privacidad',
      'footer.terms': 'Términos de Servicio',
      'footer.copyright': '© 2026 Memorio. Todos los derechos reservados. Honrando la vida, una historia a la vez.',
      
      // Family Portal
      'family.dashboard': 'Panel Familiar',
      'family.welcomeBack': 'Bienvenido de Nuevo',
      'family.formIncomplete': 'Formulario de Obituario Incompleto',
      'family.completeForm': 'Completar Formulario de Obituario',
      'family.requestRevision': 'Solicitar Revisión',
      'family.revisionRequest': 'Solicitar Revisión del Video',
      'family.revisionNotes': '¿Qué cambios le gustaría ver?',
      'family.revisionCharCount': 'caracteres',
      'family.revisionMinimum': '(mínimo 25 caracteres)',
      'family.submitRevision': 'Enviar Solicitud de Revisión',
      'family.approveVideo': 'Aprobar Video',
      'family.videoApproved': '¡Video Aprobado!',
      'family.revisionComplete': 'Su revisión está completa',
      'family.downloadVideo': 'Descargar Video',
      'family.downloadObituary': 'Descargar Obituario',
      'family.loginTitle': 'Portal Familiar',
      'family.loginSubtitle': 'Inicie sesión para completar su formulario de obituario',
      'family.signIn': 'Iniciar Sesión',
      'family.signingIn': 'Iniciando sesión...',
      'family.noCredentials': '¿No tiene credenciales de inicio de sesión?',
      'family.contactDirector': 'Póngase en contacto con su director de funeraria para obtener acceso.',
      'family.loginSuccess': '¡Inicio de sesión exitoso! Redirigiendo...',
      'family.myCase': 'Mi Caso',
      'family.caseStatus': 'Estado del Caso',
      'family.obituaryDraft': 'Borrador de Obituario',
      'family.completedObituary': 'Obituario Completado',
      'family.memorialVideo': 'Video Conmemorativo',
      'family.memorialComplete': 'Su Memorial Está Completo',
      'family.memorialCompleteDesc': 'El obituario y el video han sido entregados a la familia',
      'family.revisionAlertMin': 'Por favor proporcione al menos 25 caracteres describiendo los cambios que le gustaría ver.',
      'family.revisionSubmitSuccess': '¡Solicitud de revisión enviada exitosamente! Nuestro equipo revisará sus comentarios y realizará los cambios necesarios.',
      'family.revisionSubmitError': 'Error al enviar la solicitud de revisión. Por favor, inténtelo de nuevo.',
      'family.caseID': 'ID del Caso',
      'family.created': 'Creado',
      'family.lastUpdated': 'Última Actualización',
      'family.loading': 'Cargando...',
      'family.loadingCase': 'Cargando su caso...',
      'family.loadingObituary': 'Cargando obituario...',
      'family.obituarySection': 'Obituario',
      'family.editObituary': 'Editar Obituario',
      'family.downloadPDF': 'Descargar PDF',
      'family.downloadObituaryPDF': 'Descargar PDF de Obituario',
      'family.completeObituaryForm': 'Completar Formulario de Obituario',
      'family.downloadFinalObituary': 'Descargar Obituario Final',
      'family.caseCreated': 'Caso Creado',
      'family.formSubmitted': 'Formulario de Obituario Enviado',
      'family.notifications': 'Notificaciones',
      'family.loadingNotifications': 'Cargando notificaciones...',
      'family.pleaseWait': 'Por favor espere mientras cargamos las actualizaciones de su caso.',
      'family.obituaryUpdated': '¡Obituario actualizado exitosamente!',
      'family.editObituaryTitle': 'Editar Obituario',
      'family.obituaryTitle': 'Título del Obituario',
      'family.obituaryContent': 'Contenido del Obituario',
      'family.saveChanges': 'Guardar Cambios',
      'family.cancel': 'Cancelar',
      'family.obituaryPDFDownloaded': '¡PDF de obituario descargado!',
      'family.createdWithCare': 'Creado con cuidado por Memorio',

      // Family Dashboard — additional UI strings (Spanish)
      'family.photosSection': 'Fotos',
      'family.uploadPhotos': 'Haga clic para subir fotos',
      'family.memorialTributeVideo': 'Video Tributo Conmemorativo',
      'family.timelineUpdates': 'Cronología y Actualizaciones',
      'family.makeChanges': 'Hacer Cambios',
      'family.noObituaryYet': 'Aún no se ha enviado ningún obituario.',
      'family.noCaseFound': 'No Se Encontró Caso',
      'family.noCaseAssigned': 'Aún no se ha asignado ningún caso a su cuenta. Por favor contacte a su director de funeraria para obtener asistencia.',
      'family.formSubmittedAwaiting': 'Formulario Enviado — En Espera de Procesamiento',

      // Family Dashboard — revision modal (Spanish)
      'family.revisionOnlyOne': 'Esta es su única solicitud de revisión',
      'family.revisionPleaseSpecific': 'Por favor sea específico sobre los cambios que necesita. Su editor revisará sus comentarios y realizará los ajustes necesarios.',
      'family.revisionWhatChanges': '¿Qué cambios le gustaría hacer a su video conmemorativo?',
      'family.revisionPlaceholder': 'Por favor describa los cambios que desea ver en su video conmemorativo.\n\nPor ejemplo:\n• Agregar o eliminar fotos específicas\n• Ajustar la selección musical\n• Cambiar el ritmo o la cadencia\n• Corregir cualquier información\n\nSea lo más específico posible para que nuestro editor pueda hacer los cambios correctos.',
      'family.confirmRevisionTitle': 'Confirmar Solicitud de Revisión',
      'family.revisionConfirmText': '¿Está seguro de que desea enviar esta solicitud de revisión? Una vez enviada, no podrá solicitar otra revisión.',
      'family.yesSubmitRevision': 'Sí, Enviar Revisión',

      // Family Dashboard — case status labels (Spanish)
      'family.status.created': 'Creado',
      'family.status.waitingOnFamily': 'Esperando Formulario',
      'family.status.intakeInProgress': 'Formulario en Progreso',
      'family.status.submitted': 'Formulario Enviado',
      'family.status.inProduction': 'En Producción',
      'family.status.awaitingReview': 'En Espera de Revisión',
      'family.status.delivered': 'Entregado',
      'family.status.closed': 'Cerrado',

      // Family Dashboard — dashboard title (Spanish)
      'family.title.tributeReady': 'Su tributo está listo, {name}',
      'family.title.thankYou': 'Gracias {name}. Nosotros nos encargamos a partir de aquí.',

      // Family Dashboard — timeline (Spanish)
      'family.timeline.caseCreated': 'Caso Creado',
      'family.timeline.caseCreatedDesc': 'Caso creado para {name}',
      'family.timeline.formSubmitted': 'Formulario de Obituario Enviado',
      'family.timeline.formSubmittedDesc': 'La familia completó y envió el formulario de obituario',
      'family.timeline.awaitingProcessing': 'En Espera de Procesamiento',
      'family.timeline.awaitingProcessingDesc': 'Su obituario está siendo procesado por nuestro equipo',
      'family.timeline.inProduction': 'En Producción',
      'family.timeline.inProductionDesc': 'Su video conmemorativo está siendo creado',
      'family.timeline.delivered': 'Entregado',
      'family.timeline.deliveredDesc': 'Su video conmemorativo está listo para descargar',
      'family.timeline.current': 'Actual',

      // Family Dashboard — notifications (Spanish)
      'family.notif.actionRequired': 'Acción Requerida',
      'family.notif.actionRequiredText': 'Por favor complete el formulario de obituario para continuar con su video conmemorativo.',
      'family.notif.formReceived': 'Formulario Recibido',
      'family.notif.formReceivedText': '¡Gracias! Hemos recibido su formulario de obituario y comenzaremos a procesarlo pronto.',
      'family.notif.inProgress': 'En Progreso',
      'family.notif.inProgressText': 'Su video conmemorativo está siendo creado. Le notificaremos cuando esté listo.',
      'family.notif.noNotifications': 'Sin nuevas notificaciones',
      'family.notif.allCaughtUp': '¡Está al día!',
      'family.notif.now': 'Ahora',
      'family.notif.recent': 'Reciente',

      // Family Dashboard — obituary editor modal (Spanish)
      'family.editor.title': 'Editar Obituario',
      'family.editor.titleLabel': 'Título del Obituario',
      'family.editor.contentLabel': 'Contenido del Obituario',
      'family.editor.hint': 'Siéntase libre de hacer cualquier cambio para honrar la memoria de su ser querido.',
      'family.editor.saveChanges': 'Guardar Cambios',
      'family.editor.cancel': 'Cancelar',
      'family.revisionInProgress': 'Revisión en Progreso',
      'family.editorWorkingOnChanges': 'Nuestro editor está trabajando en los cambios',

      // Family Dashboard — upload window timer (Spanish)
      'family.upload.windowActive': 'Ventana de Carga Activa',
      'family.upload.windowActiveDesc': 'Tiempo restante para subir fotos adicionales. Después de que esta ventana se cierre, nuestros editores comenzarán a crear su video conmemorativo.',
      'family.upload.windowClosed': 'Ventana de Carga Cerrada',
      'family.upload.windowClosedDesc': 'La ventana de carga de 12 horas ha terminado. Aún puede ver todas las fotos subidas a continuación.',
      'family.upload.windowExpiredAlert': 'La ventana de carga de 12 horas se ha cerrado. Ya no puede agregar fotos a este caso.',

      // Family Form — Password Change Modal
      'family.changePasswordTitle': '🔒 Cambia Tu Contraseña',
      'family.changePasswordDesc': 'Por razones de seguridad, debes cambiar tu contraseña temporal antes de acceder a tu cuenta.',
      'family.newPassword': 'Nueva Contraseña*',
      'family.enterNewPassword': 'Ingresa la nueva contraseña',
      'family.passwordMinLength': 'Debe tener al menos 8 caracteres',
      'family.confirmNewPassword': 'Confirmar Nueva Contraseña*',
      'family.confirmNewPasswordPlaceholder': 'Confirma la nueva contraseña',
      'family.changePasswordBtn': 'CAMBIAR CONTRASEÑA',
      'family.passwordUpdated': '¡Contraseña Actualizada!',
      'family.passwordUpdatedDesc': 'Tu contraseña ha sido cambiada exitosamente. Ahora puedes continuar con el formulario.',
      'family.proceed': 'Continuar',

      // Family Form
      'form.title': 'Formulario de Tributo Conmemorativo',
      'form.subtitle': 'Ayúdenos a crear un tributo significativo',
      'form.basicInfo': 'Información Básica',
      'form.lifeStory': 'Historia de Vida',

      // Family Form — inline content (Spanish)
      'form.header': 'Escritor de Obituarios de Memorio',
      'form.letsBegin': '¡Comencemos!',
      'form.intro': 'Tómate tu tiempo, cada pregunta nos ayuda a construir un recuerdo emotivo. No hay prisa.',
      'form.otherNamesPrefix': '¿Algún otro nombre que desearía incluir para ',
      'form.otherNamesSuffix': '?',
      'form.salutationPlaceholder': 'Saludo',
      'form.middleNamePlaceholder': 'Segundo Nombre',
      'form.nicknamePlaceholder': 'Apodo',
      'form.maidenNamePlaceholder': 'Apellido de Soltera',
      'form.suffixOption': 'Sufijo (Jr, Sr, etc.)',
      'form.requiredFields': '*Campos Requeridos',
      'form.nextBtn': 'SIGUIENTE',
      'form.backBtn': 'ATRÁS',
      'form.submitBtn': 'ENVIAR',
      'form.signOut': 'Cerrar Sesión',
      'form.photoIntro': 'Cada vida es una colección de momentos hermosos. Sube fotos para ayudarnos a honrar el camino de tu ser querido.',
      'form.selectPhotos': 'Seleccionar Fotos',
      'form.musicQuestion': '¿Qué música te gustaría para el video tributo?',
      'form.pianoOption': 'Piano',
      'form.guitarOption': 'Guitarra',
      'form.tributeQuoteQuestion': '¿Hay una cita, versículo o frase favorita que te gustaría incluir en el video tributo?',
      'form.tributeQuotePlaceholder': 'Algo que siempre decía o algo que te lo recuerda y captura su espíritu.',
      'form.specialDetails': '¿Te Gustaría Agregar Detalles Especiales?',
      'form.almostDone': 'Casi listo. Revisa la información y agrega cualquier detalle final. Una vez que envíes, se creará tu obituario.',
      'form.anythingElse': '¿Hay algo más que desees incluir en el Obituario?',
      'form.serviceInfo': '¿Te gustaría incluir información sobre el servicio o evento?',
      'form.serviceInfoPlaceholder': 'Agrega información sobre los servicios: hora, lugar, código de vestimenta o cualquier cosa que los asistentes deban saber.',
      'form.formError': '¡Ups! Algo salió mal al enviar el formulario.',

      // Family Form — obituary generation screen (Spanish)
      'form.craftingStory': 'Escribiendo la historia de {name}...',
      'form.tributeCrafted': 'Gracias por compartir sobre {name}. Aquí está el tributo que hemos creado basado en los recuerdos que nos proporcionaste.',
      'form.updatedObituaryTitle': 'Aquí está su obituario',
      'form.obituaryTitleFor': 'para',
      'form.editHint': 'Siempre puede hacer cambios en el panel',
      'form.accessDashboard': 'Acceder al Panel',

      'form.accordion.familyMembers': 'Miembros de la Familia',
      'form.accordion.personalDetails': 'Detalles Personales',
      'form.accordion.education': 'Educación',
      'form.accordion.hobbies': 'Pasatiempos / Intereses',
      'form.accordion.career': 'Logros Profesionales',
      'form.accordion.religion': 'Religión / Espiritualidad',
      'form.accordion.military': 'Servicio Militar',
      'form.accordion.save': 'Guardar',
      'form.accordion.add': 'Agregar',
      'form.accordion.familyMembersLabel': '¿Quiénes fueron las personas importantes en su vida?',
      'form.accordion.familyMembersPlaceholder': 'Por favor comparte los nombres de padres, hermanos, hijos, parientes cercanos o amigos queridos que fueron importantes en su vida.',
      'form.accordion.personalDetailsLabel': 'Descríbalo como persona',
      'form.accordion.personalDetailsPlaceholder': '¿Por qué era conocido por sus seres queridos?',
      'form.accordion.educationLabel': '¿Cuáles fueron sus logros?',
      'form.accordion.educationPlaceholder': 'Indica el nombre y la ubicación de las escuelas que asistió. Incluye títulos, certificados o reconocimientos especiales.',
      'form.accordion.hobbiesLabel': '¿Qué les apasionaba?',
      'form.accordion.hobbiesPlaceholder': 'Indica las actividades e intereses que eran importantes para tu ser querido.',
      'form.accordion.careerLabel': 'Cuéntanos sobre sus logros profesionales',
      'form.accordion.careerPlaceholder': 'Indica experiencia laboral y logros relacionados. Incluye fechas y momentos de orgullo.',
      'form.accordion.religionLabel': '¿Qué papel tuvo la religión o espiritualidad en su vida?',
      'form.accordion.religionPlaceholder': 'Indica lugares de culto, actos de servicio, viajes de fe o valores importantes que tenía tu ser querido.',
      'form.accordion.militaryLabel': 'Cuéntanos sobre su servicio militar',
      'form.accordion.militaryPlaceholder': 'Si fue veterano, indica la rama, rango y tiempo de servicio, junto con la ubicación.',
      'form.familyMembers': 'Miembros de la Familia',
      'form.photoUpload': 'Subir Fotos',
      'form.musicPreferences': 'Preferencias Musicales',
      'form.additionalNotes': 'Notas Adicionales',
      'form.nextStep': 'Siguiente Paso',
      'form.previousStep': 'Paso Anterior',
      'form.submitForm': 'Enviar Formulario',
      'form.saving': 'Guardando...',
      'form.saved': 'Guardado',
      
      // Editor Portal
      'editor.dashboard': 'Panel del Editor',
      'editor.myAssignments': 'Mis Asignaciones',
      'editor.noAssignments': 'No hay asignaciones disponibles',
      'editor.uploadVideo': 'Subir Video',
      'editor.submitForReview': 'Enviar para Revisión de QC',
      'editor.uploading': 'Subiendo...',
      'editor.processing': 'Procesando...',
      'editor.checkWorkload': 'Verificar Carga de Trabajo',
      'editor.editHistory': 'Historial de Ediciones',
      'editor.completedCases': 'Casos Completados',
      'editor.videosEdited': 'Videos Editados',
      'editor.loginTitle': 'Portal del Editor de Video',
      'editor.loginSubtitle': 'Inicie sesión para crear videos de tributo conmemorativo',
      'editor.signIn': 'Iniciar Sesión',
      'editor.signingIn': 'Iniciando sesión...',
      'editor.noCredentials': '¿No tiene credenciales de inicio de sesión?',
      'editor.contactAdmin': 'Póngase en contacto con su administrador para obtener acceso.',
      'editor.loginSuccess': '¡Inicio de sesión exitoso! Redirigiendo...',
      'editor.totalCompleted': 'Total Completado',
      'editor.approved': 'Aprobado',
      'editor.revisionsRequested': 'Revisiones Solicitadas',
      'editor.noCasesYet': 'Aún no hay casos completados.',
      'editor.submittedVideos': 'Sus videos enviados aparecerán aquí.',
      'editor.uploadLocked': 'Bloqueado - Ventana de Carga Familiar Activa',
      'editor.uploadLockedMsg': 'Las cargas de video están deshabilitadas durante la ventana de carga de fotos familiares (12 horas después del envío del formulario).',
      'editor.submittedForReview': 'Enviado para Revisión',
      'editor.workloadRefreshed': '¡Carga de trabajo actualizada!',
      'editor.caseDetails': 'Detalles del Caso',
      'editor.deceasedInfo': 'Información del Fallecido',
      'editor.caseMetadata': 'Metadatos del Caso',
      'editor.photosSection': 'Fotos',
      'editor.photoTimerLocked': 'Fotos Bloqueadas - La Familia Aún Está Subiendo',
      'editor.photoTimerExpired': 'Esperando Envío de la Familia',
      'editor.photoTimerMessage': 'La familia tiene una ventana de 12 horas para subir fotos adicionales después de enviar su formulario. Las fotos estarán disponibles para descargar una vez que expire esta ventana para asegurarse de que tenga todas las fotos antes de comenzar su trabajo.',
      'editor.videoUploadsDisabled': 'Las cargas de video también están deshabilitadas durante este período.',
      'editor.downloadAll': 'Descargar Todas las Fotos',
      'editor.videoUploadSection': 'Carga de Video',
      'editor.selectVideo': 'Seleccionar Archivo de Video',
      'editor.editorNotes': 'Notas del Editor',
      'editor.editorNotesPlaceholder': 'Agregue notas sobre sus ediciones, elecciones musicales o consideraciones especiales...',
      'editor.submitVideo': 'Enviar Video para Revisión de QC',
      'editor.submissionStatus': 'Estado del Envío',
      'editor.viewCase': 'Ver Caso',
      'editor.noAssignmentsDesc': 'Actualmente no tiene casos asignados. Vuelva más tarde o póngase en contacto con su administrador.',
      'editor.photosLockedMsg': 'Las fotos están bloqueadas - la familia aún está subiendo. Espere a que expire la ventana de carga.',
      'editor.cannotUploadDuringWindow': 'No se puede cargar video durante la ventana de carga familiar de 12 horas. Espere a que expire la ventana antes de enviar su video.',
      'editor.videoTooLarge': 'El archivo de video es demasiado grande. El tamaño máximo es 1.5GB',
      'editor.videoUploadSuccess': '¡Video cargado exitosamente! Enviando a QC...',
      'editor.videoSubmissionSuccess': '¡Video enviado para revisión de QC exitosamente!',
      
      // QC Portal
      'qc.dashboard': 'Panel de QC',
      'qc.pendingReview': 'Pendiente de Revisión QC',
      'qc.approve': 'Aprobar',
      'qc.requestRevision': 'Solicitar Revisión',
      'qc.approved': 'Aprobado',
      'qc.rejected': 'Rechazado',
      'qc.passRate': 'Tasa de Aprobación',
      'qc.loginTitle': 'Portal de Control de Calidad',
      'qc.loginSubtitle': 'Inicie sesión para revisar tributos conmemorativos',
      'qc.signIn': 'Iniciar Sesión',
      'qc.signingIn': 'Iniciando sesión...',
      'qc.noCredentials': '¿No tiene credenciales de inicio de sesión?',
      'qc.contactAdmin': 'Póngase en contacto con su administrador para obtener acceso.',
      'qc.loginSuccess': '¡Inicio de sesión exitoso! Redirigiendo...',
      
      // Admin Portal
      'admin.dashboard': 'Panel de Administración',
      'admin.createOrg': 'Crear Organización',
      'admin.inviteDirector': 'Invitar Director',
      'admin.inviteEditor': 'Invitar Editor',
      'admin.inviteQC': 'Invitar Usuario de QC',
      'admin.allAccounts': 'Todas las Cuentas',
      'admin.analytics': 'Análisis',
      'admin.orgDetails': 'Detalles de la Organización',
      'admin.orgName': 'Nombre de la Organización',
      'admin.orgEmail': 'Correo Electrónico de Contacto',
      'admin.orgPhone': 'Teléfono de Contacto',
      'admin.orgRegion': 'Región',
      'admin.createOrgBtn': 'CREAR ORGANIZACIÓN',
      'admin.orgCreatedSuccess': '¡Organización Creada Exitosamente!',
      
      // Case Status
      'status.waitingOnFamily': 'Esperando a la Familia',
      'status.inProgress': 'En Progreso',
      'status.awaitingReview': 'Esperando Revisión',
      'status.complete': 'Completo',
      'status.delivered': 'Entregado',
      'status.revisionRequested': 'Revisión Solicitada',
      
      // Timeline Events
      'timeline.caseCreated': 'Caso Creado',
      'timeline.familyInvited': 'Familia Invitada',
      'timeline.formSubmitted': 'Formulario Enviado',
      'timeline.editorAssigned': 'Editor Asignado',
      'timeline.videoSubmitted': 'Video Enviado',
      'timeline.qcApproved': 'QC Aprobado',
      'timeline.delivered': 'Entregado a la Familia',
      
      // Errors & Validation
      'error.required': 'Este campo es obligatorio',
      'error.invalidEmail': 'Por favor ingrese un correo electrónico válido',
      'error.passwordMismatch': 'Las contraseñas no coinciden',
      'error.uploadFailed': 'Falló la carga',
      'error.networkError': 'Error de red. Por favor, inténtelo de nuevo.',
      
      // Success Messages
      'success.saved': 'Guardado exitosamente',
      'success.uploaded': 'Subido exitosamente',
      'success.submitted': 'Enviado exitosamente',
      'success.deleted': 'Eliminado exitosamente',
    }
  },
  
  /**
   * Initialize i18n system
   * - Loads saved language from localStorage
   * - Translates all elements with data-i18n attribute
   * - Sets up language toggle if it exists
   */
  init() {
    // Prevent double initialization
    if (i18n._initialized) {
      console.warn('i18n already initialized');
      return;
    }
    
    // Load saved language preference
    const savedLang = localStorage.getItem('memorio_language') || 'en';
    i18n.setLanguage(savedLang);
    
    // Set up legacy toggle buttons
    i18n.setupToggle();
    
    // Mark as initialized
    i18n._initialized = true;
  },
  
  /**
   * Get translation for a key
   */
  t(key, fallback = key) {
    // Auto-initialize if not yet initialized
    if (!i18n._initialized) {
      console.warn('i18n.t() called before init(), auto-initializing...');
      const savedLang = localStorage.getItem('memorio_language') || 'en';
      i18n.currentLang = savedLang;
    }
    
    // Ensure currentLang is always valid
    if (!i18n.currentLang || !i18n.translations[i18n.currentLang]) {
      console.warn('Invalid currentLang detected, resetting to localStorage or en');
      i18n.currentLang = localStorage.getItem('memorio_language') || 'en';
    }
    
    // Get translation, with fallback chain
    const translation = i18n.translations[i18n.currentLang]?.[key];
    
    // If translation not found in current language, try English as fallback
    if (!translation && i18n.currentLang !== 'en') {
      const englishTranslation = i18n.translations['en']?.[key];
      if (englishTranslation) {
        console.warn(`Translation missing for key '${key}' in '${i18n.currentLang}', using English fallback`);
        return englishTranslation;
      }
    }
    
    // If still no translation, return fallback (default is the key itself)
    if (!translation) {
      console.warn(`Translation missing for key '${key}' in all languages`);
    }
    
    return translation || fallback;
  },
  
  /**
   * Set current language
   */
  setLanguage(lang) {
    if (!i18n.translations[lang]) {
      console.warn(`Language '${lang}' not supported. Falling back to 'en'.`);
      lang = 'en';
    }
    
    i18n.currentLang = lang;
    localStorage.setItem('memorio_language', lang);
    
    // Update HTML lang attribute
    document.documentElement.lang = lang;
    
    // Update legacy two-button toggle states
    document.querySelectorAll('[data-lang-btn]').forEach(btn => {
      if (btn.dataset.langBtn === lang) {
        btn.classList.add('active');
      } else {
        btn.classList.remove('active');
      }
    });

    // Update single-toggle button label + tooltip
    document.querySelectorAll('[data-i18n-toggle]').forEach(btn => {
      const label = btn.querySelector('.lang-label');
      if (label) label.textContent = lang.toUpperCase();
      btn.title = lang === 'en' ? 'Switch to Español' : 'Switch to English';
    });
    
    // Translate the page
    i18n.translatePage();
  },
  
  /**
   * Translate all elements with data-i18n attribute
   */
  translatePage() {
    // Translate text content
    document.querySelectorAll('[data-i18n]').forEach(element => {
      const key = element.dataset.i18n;
      const translation = i18n.t(key);
      
      // Handle different element types
      if (element.tagName === 'INPUT' || element.tagName === 'TEXTAREA') {
        // For input/textarea, update placeholder if it has one
        if (element.hasAttribute('placeholder')) {
          element.placeholder = translation;
        }
      } else if (element.tagName === 'OPTION') {
        // For option elements, update the text
        element.textContent = translation;
      } else {
        // For all other elements, update text content
        element.textContent = translation;
      }
    });
    
    // Translate placeholders specifically marked with data-i18n-placeholder
    document.querySelectorAll('[data-i18n-placeholder]').forEach(element => {
      const key = element.dataset.i18nPlaceholder;
      const translation = i18n.t(key);
      element.placeholder = translation;
    });
    
    // Also translate select dropdowns that have options with data-i18n
    document.querySelectorAll('select').forEach(select => {
      select.querySelectorAll('option[data-i18n]').forEach(option => {
        const key = option.dataset.i18n;
        option.textContent = i18n.t(key);
      });
    });
  },
  
  /**
   * Toggle between EN and ES — called directly via onclick="i18n.toggle()"
   */
  toggle() {
    const newLang = i18n.currentLang === 'en' ? 'es' : 'en';
    i18n.setLanguage(newLang);
    // Re-apply form-specific translations if family form is loaded
    if (typeof window.translateFormContent === 'function') {
      window.translateFormContent();
    }
    // Re-render dynamic dashboard content if family dashboard is loaded
    if (typeof window.translateDashboardContent === 'function') {
      window.translateDashboardContent();
    }
  },

  /**
   * Set up language toggle buttons (legacy addEventListener approach)
   */
  setupToggle() {
    // Legacy two-button system
    document.querySelectorAll('[data-lang-btn]').forEach(btn => {
      btn.addEventListener('click', (e) => {
        e.preventDefault();
        const lang = btn.dataset.langBtn;
        i18n.setLanguage(lang);
      });
    });
  }
};

// Auto-initialize when DOM is ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => i18n.init());
} else {
  i18n.init();
}

// Add global error handler to catch translation issues
window.addEventListener('error', (event) => {
  if (event.message && event.message.includes('i18n')) {
    console.error('i18n error detected:', event);
    console.error('Current i18n state:', {
      currentLang: i18n.currentLang,
      initialized: i18n._initialized,
      localStorage: localStorage.getItem('memorio_language')
    });
  }
});
