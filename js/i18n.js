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
      
      // Director Portal
      'director.dashboard': 'Director Dashboard',
      'director.createCase': 'Create New Case',
      'director.inviteFamily': 'Invite Family',
      'director.myCases': 'My Cases',
      'director.caseDetails': 'Case Details',
      'director.deceasedName': 'Deceased Name',
      'director.gender': 'Gender',
      'director.gender.male': 'Male',
      'director.gender.female': 'Female',
      'director.gender.other': 'Other',
      'director.gender.specify': 'Please Specify Gender/Pronouns',
      'director.dateOfBirth': 'Date of Birth',
      'director.dateOfPassing': 'Date of Passing',
      'director.cityOfBirth': 'City of Birth',
      'director.stateOfBirth': 'State/Province of Birth',
      'director.countryOfBirth': 'Country of Birth',
      'director.cityOfDeath': 'City of Passing',
      'director.stateOfDeath': 'State/Province of Passing',
      'director.countryOfDeath': 'Country of Passing',
      'director.createCaseBtn': 'Create Case',
      'director.changePassword': 'Change Your Password',
      'director.changePasswordDesc': 'For security reasons, you must change your temporary password before accessing the dashboard.',
      'director.newPassword': 'New Password',
      'director.confirmPassword': 'Confirm New Password',
      'director.passwordMinLength': 'Must be at least 8 characters',
      'director.changePasswordBtn': 'CHANGE PASSWORD',
      
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
      
      // Director Portal
      'director.dashboard': 'Panel del Director',
      'director.createCase': 'Crear Nuevo Caso',
      'director.inviteFamily': 'Invitar Familia',
      'director.myCases': 'Mis Casos',
      'director.caseDetails': 'Detalles del Caso',
      'director.deceasedName': 'Nombre del Difunto',
      'director.gender': 'Género',
      'director.gender.male': 'Masculino',
      'director.gender.female': 'Femenino',
      'director.gender.other': 'Otro',
      'director.gender.specify': 'Por Favor Especifique Género/Pronombres',
      'director.dateOfBirth': 'Fecha de Nacimiento',
      'director.dateOfPassing': 'Fecha de Fallecimiento',
      'director.cityOfBirth': 'Ciudad de Nacimiento',
      'director.stateOfBirth': 'Estado/Provincia de Nacimiento',
      'director.countryOfBirth': 'País de Nacimiento',
      'director.cityOfDeath': 'Ciudad de Fallecimiento',
      'director.stateOfDeath': 'Estado/Provincia de Fallecimiento',
      'director.countryOfDeath': 'País de Fallecimiento',
      'director.createCaseBtn': 'Crear Caso',
      'director.changePassword': 'Cambie Su Contraseña',
      'director.changePasswordDesc': 'Por razones de seguridad, debe cambiar su contraseña temporal antes de acceder al panel.',
      'director.newPassword': 'Nueva Contraseña',
      'director.confirmPassword': 'Confirmar Nueva Contraseña',
      'director.passwordMinLength': 'Debe tener al menos 8 caracteres',
      'director.changePasswordBtn': 'CAMBIAR CONTRASEÑA',
      
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
      
      // Check if we should translate placeholder or text content
      if (element.hasAttribute('placeholder')) {
        element.placeholder = translation;
      } else {
        element.textContent = translation;
      }
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
