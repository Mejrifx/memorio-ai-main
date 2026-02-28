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
      
      // Main Website
      'website.nav.features': 'Features',
      'website.nav.howItWorks': 'How It Works',
      'website.nav.faq': 'FAQ',
      'website.nav.services': 'Services',
      'website.nav.familyLogin': 'Family Login',
      'website.hero.title': 'A Beautiful Way To Remember Someone You Love',
      'website.hero.subtitle': 'When words are hard and time is short, Memorio helps families and funeral homes create meaningful video tributes and obituaries with care, dignity, and guidance every step of the way.',
      'website.hero.getStarted': 'Get Started',
      'website.hero.learnMore': 'Learn More',
      'website.features.title': 'Everything You Need to Honor a Life',
      'website.features.subtitle': 'Memorio provides a complete solution for creating meaningful memorial tributes',
      'website.features.realSupport': 'Real, Compassionate Support',
      'website.features.realSupportDesc': 'If you need help or guidance, support is available every step of the way.',
      'website.howItWorks.title': 'How It Works',
      'website.howItWorks.subtitle': 'Creating a meaningful tribute doesn\'t have to be complicated.',
      'website.howItWorks.step1': 'Your Funeral Home Gets You Started',
      'website.howItWorks.step1Desc': 'Your funeral director will provide a secure link for your family to begin the process.',
      'website.howItWorks.step2': 'Share Photos and Memories',
      'website.howItWorks.step2Desc': 'Upload photos and answer a few gentle, guided questions about your loved one\'s life.',
      'website.howItWorks.step3': 'We Create the Tribute',
      'website.howItWorks.step3Desc': 'Your memories are carefully transformed into a beautifully written obituary and tribute video.',
      'website.howItWorks.step4': 'Your Tribute Is Delivered',
      'website.howItWorks.step4Desc': 'Once complete, the finished tribute is delivered to your family\'s private portal.',
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
      'website.cta.title': 'Ready to Get Started?',
      'website.cta.subtitle': 'If you\'ve received login credentials from your funeral director, sign in now to begin creating your tribute.',
      'website.cta.button': 'Access Family Portal',
      'website.footer.about': 'About Memorio',
      'website.footer.aboutDesc': 'Memorio helps funeral homes create beautiful, personalized video tributes & personalised obituaries that honor and celebrate the lives of loved ones with dignity and care.',
      'website.footer.quickLinks': 'Quick Links',
      'website.footer.login': 'Login',
      'website.footer.support': 'Support',
      'website.footer.familyPortal': 'Family Portal',
      'website.footer.directorPortal': 'Director Portal',
      'website.footer.privacyPolicy': 'Privacy Policy',
      'website.footer.termsOfService': 'Terms of Service',
      'website.footer.copyright': '© 2026 Memorio. All rights reserved. Honoring life, one story at a time.',
      'website.features.whyChoose': 'Why Choose Memorio',
      'website.features.whyChooseDesc': 'We provide funeral homes with a seamless platform to create personalized video tributes that honor each unique life story.',
      'website.features.guidedProcess': 'Gentle, Guided Process',
      'website.features.guidedProcessDesc': 'A simple, step-by-step experience designed for families during a difficult time. No technical skills required.',
      'website.features.privateSecure': 'Private and Secure',
      'website.features.privateSecureDesc': 'Your family\'s memories and personal information are protected with strong security and strict access controls.',
      'website.features.beautifullyCrafted': 'Beautifully Crafted',
      'website.features.beautifullyCraftedDesc': 'Each tribute is thoughtfully assembled with music, photos, and pacing that honors your loved one with dignity.',
      'website.features.readyWhenNeeded': 'Ready When You Need It',
      'website.features.readyWhenNeededDesc': 'Tributes are completed quickly and carefully, without sacrificing quality or attention to detail.',
      'website.features.everythingInOnePlace': 'Everything in One Place',
      'website.features.everythingInOnePlaceDesc': 'All photos and memories are collected in one simple, organized place, making it easier to create a complete and meaningful tribute.',
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
      
      // Main Website
      'website.nav.features': 'Características',
      'website.nav.howItWorks': 'Cómo Funciona',
      'website.nav.faq': 'Preguntas Frecuentes',
      'website.nav.services': 'Servicios',
      'website.nav.familyLogin': 'Acceso Familiar',
      'website.hero.title': 'Una Hermosa Forma de Recordar a Alguien que Amas',
      'website.hero.subtitle': 'Cuando las palabras son difíciles y el tiempo es corto, Memorio ayuda a las familias y funerarias a crear tributos en video y obituarios significativos con cuidado, dignidad y orientación en cada paso del camino.',
      'website.hero.getStarted': 'Comenzar',
      'website.hero.learnMore': 'Más Información',
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
      'website.cta.title': '¿Listo Para Comenzar?',
      'website.cta.subtitle': 'Si ha recibido credenciales de inicio de sesión de su director de funeraria, inicie sesión ahora para comenzar a crear su tributo.',
      'website.cta.button': 'Acceder al Portal Familiar',
      'website.footer.about': 'Acerca de Memorio',
      'website.footer.aboutDesc': 'Memorio ayuda a las funerarias a crear hermosos tributos en video personalizados y obituarios personalizados que honran y celebran las vidas de los seres queridos con dignidad y cuidado.',
      'website.footer.quickLinks': 'Enlaces Rápidos',
      'website.footer.login': 'Iniciar Sesión',
      'website.footer.support': 'Soporte',
      'website.footer.familyPortal': 'Portal Familiar',
      'website.footer.directorPortal': 'Portal del Director',
      'website.footer.privacyPolicy': 'Política de Privacidad',
      'website.footer.termsOfService': 'Términos de Servicio',
      'website.footer.copyright': '© 2026 Memorio. Todos los derechos reservados. Honrando la vida, una historia a la vez.',
      'website.features.whyChoose': 'Por Qué Elegir Memorio',
      'website.features.whyChooseDesc': 'Proporcionamos a las funerarias una plataforma perfecta para crear tributos en video personalizados que honran cada historia de vida única.',
      'website.features.guidedProcess': 'Proceso Suave y Guiado',
      'website.features.guidedProcessDesc': 'Una experiencia simple, paso a paso, diseñada para familias durante un momento difícil. No se requieren habilidades técnicas.',
      'website.features.privateSecure': 'Privado y Seguro',
      'website.features.privateSecureDesc': 'Los recuerdos y la información personal de su familia están protegidos con seguridad sólida y controles de acceso estrictos.',
      'website.features.beautifullyCrafted': 'Hermosamente Elaborado',
      'website.features.beautifullyCraftedDesc': 'Cada tributo se ensambla cuidadosamente con música, fotos y ritmo que honran a su ser querido con dignidad.',
      'website.features.readyWhenNeeded': 'Listo Cuando Lo Necesite',
      'website.features.readyWhenNeededDesc': 'Los tributos se completan rápida y cuidadosamente, sin sacrificar la calidad o la atención al detalle.',
      'website.features.everythingInOnePlace': 'Todo en Un Solo Lugar',
      'website.features.everythingInOnePlaceDesc': 'Todas las fotos y recuerdos se recopilan en un lugar simple y organizado, lo que facilita crear un tributo completo y significativo.',
      'website.howItWorks.step1': 'La Familia Completa el Formulario',
      'website.howItWorks.step1Desc': 'Las familias responden preguntas guiadas y suben fotos a través de una interfaz simple y compasiva.',
      'website.howItWorks.step2': 'Edición Profesional',
      'website.howItWorks.step2Desc': 'Nuestro equipo crea un hermoso tributo en video, seleccionando cuidadosamente música y transiciones.',
      'website.howItWorks.step3': 'Revisar y Aprobar',
      'website.howItWorks.step3Desc': 'Las familias revisan el video y pueden solicitar revisiones para asegurarse de que sea perfecto.',
      'website.howItWorks.step4': 'Entregar y Compartir',
      'website.howItWorks.step4Desc': 'El video final se entrega digitalmente, listo para compartir en servicios o en línea.',
      
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
      
      // Family Form
      'form.title': 'Formulario de Tributo Conmemorativo',
      'form.subtitle': 'Ayúdenos a crear un tributo significativo',
      'form.basicInfo': 'Información Básica',
      'form.lifeStory': 'Historia de Vida',
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
    // Load saved language preference
    const savedLang = localStorage.getItem('memorio_language') || 'en';
    i18n.setLanguage(savedLang);
    
    // Set up legacy toggle buttons
    i18n.setupToggle();
  },
  
  /**
   * Get translation for a key
   */
  t(key, fallback = key) {
    const translation = i18n.translations[i18n.currentLang]?.[key];
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
