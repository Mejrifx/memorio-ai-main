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
      'website.howItWorks.title': 'How It Works',
      'website.howItWorks.subtitle': 'A simple, guided process from start to finish',
      'website.faq.title': 'Frequently Asked Questions',
      'website.cta.title': 'Ready to Create a Beautiful Tribute?',
      'website.cta.subtitle': 'Join funeral homes across the country in creating meaningful memories',
      'website.cta.button': 'Get Started Today',
      'website.footer.tagline': 'Honoring Life Through Digital Tributes',
      'website.footer.copyright': '© 2024 Memorio. All rights reserved.',
      'website.footer.privacy': 'Privacy Policy',
      'website.footer.terms': 'Terms of Service',
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
      
      // QC Portal
      'qc.dashboard': 'QC Dashboard',
      'qc.pendingReview': 'Pending QC Review',
      'qc.approve': 'Approve',
      'qc.requestRevision': 'Request Revision',
      'qc.approved': 'Approved',
      'qc.rejected': 'Rejected',
      'qc.passRate': 'Pass Rate',
      
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
      'website.howItWorks.title': 'Cómo Funciona',
      'website.howItWorks.subtitle': 'Un proceso simple y guiado de principio a fin',
      'website.faq.title': 'Preguntas Frecuentes',
      'website.cta.title': '¿Listo Para Crear Un Hermoso Tributo?',
      'website.cta.subtitle': 'Únase a las funerarias de todo el país en la creación de recuerdos significativos',
      'website.cta.button': 'Comience Hoy',
      'website.footer.tagline': 'Honrando la Vida a Través de Tributos Digitales',
      'website.footer.copyright': '© 2024 Memorio. Todos los derechos reservados.',
      'website.footer.privacy': 'Política de Privacidad',
      'website.footer.terms': 'Términos de Servicio',
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
      
      // QC Portal
      'qc.dashboard': 'Panel de QC',
      'qc.pendingReview': 'Pendiente de Revisión QC',
      'qc.approve': 'Aprobar',
      'qc.requestRevision': 'Solicitar Revisión',
      'qc.approved': 'Aprobado',
      'qc.rejected': 'Rechazado',
      'qc.passRate': 'Tasa de Aprobación',
      
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
    this.setLanguage(savedLang);
    
    // Translate all elements
    this.translatePage();
    
    // Set up language toggle buttons
    this.setupToggle();
  },
  
  /**
   * Get translation for a key
   */
  t(key, fallback = key) {
    const translation = this.translations[this.currentLang]?.[key];
    return translation || fallback;
  },
  
  /**
   * Set current language
   */
  setLanguage(lang) {
    if (!this.translations[lang]) {
      console.warn(`Language '${lang}' not supported. Falling back to 'en'.`);
      lang = 'en';
    }
    
    this.currentLang = lang;
    localStorage.setItem('memorio_language', lang);
    
    // Update HTML lang attribute
    document.documentElement.lang = lang;
    
    // Update toggle button states
    document.querySelectorAll('[data-lang-btn]').forEach(btn => {
      if (btn.dataset.langBtn === lang) {
        btn.classList.add('active');
      } else {
        btn.classList.remove('active');
      }
    });
    
    // Translate the page
    this.translatePage();
  },
  
  /**
   * Translate all elements with data-i18n attribute
   */
  translatePage() {
    document.querySelectorAll('[data-i18n]').forEach(element => {
      const key = element.dataset.i18n;
      const translation = this.t(key);
      
      // Handle different element types
      if (element.tagName === 'INPUT' || element.tagName === 'TEXTAREA') {
        // For input/textarea, update placeholder
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
    
    // Also translate select dropdowns that have options with data-i18n
    document.querySelectorAll('select').forEach(select => {
      select.querySelectorAll('option[data-i18n]').forEach(option => {
        const key = option.dataset.i18n;
        option.textContent = this.t(key);
      });
    });
  },
  
  /**
   * Set up language toggle buttons
   */
  setupToggle() {
    document.querySelectorAll('[data-lang-btn]').forEach(btn => {
      btn.addEventListener('click', (e) => {
        e.preventDefault();
        const lang = btn.dataset.langBtn;
        this.setLanguage(lang);
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
