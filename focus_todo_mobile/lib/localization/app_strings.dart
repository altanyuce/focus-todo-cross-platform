import 'package:flutter/widgets.dart';

import '../features/settings/presentation/state/app_preferences_state.dart';
import '../features/tasks/presentation/state/tasks_ui_state.dart';
import '../shared/models/task.dart';

class AppStrings {
  AppStrings._(this._languageCode);

  final String _languageCode;

  static AppStrings of(BuildContext context) {
    return AppStrings._(Localizations.localeOf(context).languageCode);
  }

  static const Map<String, Map<String, String>>
  _values = <String, Map<String, String>>{
    'en': <String, String>{
      'today': 'Today',
      'upcoming': 'Upcoming',
      'completed': 'Completed',
      'todaySubtitle': 'What needs attention now, including undated tasks.',
      'upcomingSubtitle': 'Scheduled work with a future due date.',
      'completedSubtitle': 'A quieter archive of finished work.',
      'searchTasks': 'Search tasks',
      'filter': 'Filter',
      'settings': 'Settings',
      'filtersSort': 'Filters & Sort',
      'filtersHelp':
          'Adjust the existing desktop filters without changing task logic.',
      'reset': 'Reset',
      'status': 'Status',
      'priority': 'Priority',
      'list': 'List',
      'sort': 'Sort',
      'all': 'All',
      'active': 'Active',
      'done': 'Done',
      'any': 'Any',
      'allLists': 'All lists',
      'defaultSort': 'Default',
      'dueDateDesc': 'Newest due date first',
      'dueDateAsc': 'Oldest due date first',
      'priorityDesc': 'Priority: High to Low',
      'priorityAsc': 'Priority: Low to High',
      'titleAsc': 'Alphabetical: A to Z',
      'titleDesc': 'Alphabetical: Z to A',
      'createdDesc': 'Recently created',
      'createdAsc': 'Oldest created',
      'low': 'Low',
      'medium': 'Medium',
      'high': 'High',
      'personal': 'Personal',
      'work': 'Work',
      'study': 'Study',
      'noDate': 'No date',
      'noToday': 'Nothing for Today',
      'noUpcoming': 'Nothing upcoming',
      'noCompleted': 'No completed tasks yet',
      'emptyPrompt': 'Start by adding a task.',
      'todayEmptyPrompt':
          'Start by adding something that needs attention today.',
      'upcomingEmptyPrompt': 'Add a task with a future date to plan ahead.',
      'completedEmptyPrompt':
          'Completed tasks will appear here once you finish one.',
      'addTask': 'Add task',
      'quickCapture': 'Capture a task',
      'quickCaptureHint': 'Open the full editor only when details are needed.',
      'editTask': 'Edit task',
      'title': 'Title',
      'note': 'Note',
      'dueDate': 'Due date',
      'save': 'Save',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'pickDate': 'Pick date',
      'clearDate': 'Clear date',
      'theme': 'Theme',
      'language': 'Language',
      'light': 'Light',
      'dark': 'Dark',
      'auto': 'Auto',
      'english': 'English',
      'turkish': 'Turkish',
      'german': 'German',
      'spanish': 'Spanish',
      'italian': 'Italian',
      'taskDetails': 'Task details',
      'sync': 'Sync',
      'manualSyncHelp':
          'Push local changes and pull the latest todos from Supabase on demand.',
      'syncNow': 'Sync now',
      'syncing': 'Syncing...',
      'syncSucceeded': 'Sync completed',
      'syncFailed': 'Sync failed',
      'syncUnavailable':
          'Set SUPABASE_URL and SUPABASE_ANON_KEY to enable sync.',
    },
    'tr': <String, String>{
      'today': 'Bugün',
      'upcoming': 'Yaklaşan',
      'completed': 'Tamamlanan',
      'todaySubtitle': 'Şu an dikkat isteyenler, tarihsiz görevler dahil.',
      'upcomingSubtitle': 'Gelecek tarihe sahip planlı işler.',
      'completedSubtitle': 'Tamamlanan işlerin daha sakin arşivi.',
      'searchTasks': 'Görevlerde ara',
      'filter': 'Filtre',
      'settings': 'Ayarlar',
      'filtersSort': 'Filtreler ve Sıralama',
      'filtersHelp':
          'Masaüstü mantığını değiştirmeden mevcut filtreleri ayarla.',
      'reset': 'Sıfırla',
      'status': 'Durum',
      'priority': 'Öncelik',
      'list': 'Liste',
      'sort': 'Sırala',
      'all': 'Tümü',
      'active': 'Aktif',
      'done': 'Tamamlanan',
      'any': 'Fark etmez',
      'allLists': 'Tüm listeler',
      'defaultSort': 'Varsayılan',
      'dueDateDesc': 'En yeni bitiş tarihi önce',
      'dueDateAsc': 'En eski bitiş tarihi önce',
      'priorityDesc': 'Öncelik: Yüksekten düşüğe',
      'priorityAsc': 'Öncelik: Düşükten yükseğe',
      'titleAsc': 'Alfabetik: A-Z',
      'titleDesc': 'Alfabetik: Z-A',
      'createdDesc': 'Yeni eklenenler',
      'createdAsc': 'En eski eklenenler',
      'low': 'Düşük',
      'medium': 'Orta',
      'high': 'Yüksek',
      'personal': 'Kişisel',
      'work': 'İş',
      'study': 'Çalışma',
      'noDate': 'Tarih yok',
      'noToday': 'Bugün için görev yok',
      'noUpcoming': 'Yaklaşan görev yok',
      'noCompleted': 'Henüz tamamlanan görev yok',
      'emptyPrompt': 'Yeni bir görev ekleyerek başlayın.',
      'todayEmptyPrompt': 'Yeni bir görev ekleyerek başlayın.',
      'upcomingEmptyPrompt': 'İleri tarihli bir görev ekleyerek plan yapın.',
      'completedEmptyPrompt': 'Bir görevi tamamladığınızda burada görünecek.',
      'addTask': 'Görev ekle',
      'quickCapture': 'Görev yakala',
      'quickCaptureHint': 'Gerektiğinde ayrıntılar için düzenleyiciyi açın.',
      'editTask': 'Görevi düzenle',
      'title': 'Başlık',
      'note': 'Not',
      'dueDate': 'Bitiş tarihi',
      'save': 'Kaydet',
      'cancel': 'İptal',
      'delete': 'Sil',
      'pickDate': 'Tarih seç',
      'clearDate': 'Tarihi temizle',
      'theme': 'Tema',
      'language': 'Dil',
      'light': 'Açık',
      'dark': 'Koyu',
      'auto': 'Otomatik',
      'english': 'İngilizce',
      'turkish': 'Türkçe',
      'german': 'Almanca',
      'spanish': 'İspanyolca',
      'italian': 'İtalyanca',
      'taskDetails': 'Görev ayrıntısı',
      'sync': 'Senkronizasyon',
      'manualSyncHelp':
          'Yerel değişiklikleri gönderin ve en son görevleri ihtiyaç halinde Supabase\'den çekin.',
      'syncNow': 'Şimdi senkronize et',
      'syncing': 'Senkronize ediliyor...',
      'syncSucceeded': 'Senkronizasyon tamamlandı',
      'syncFailed': 'Senkronizasyon başarısız',
      'syncUnavailable':
          'Senkronizasyonu etkinleştirmek için SUPABASE_URL ve SUPABASE_ANON_KEY ayarlayın.',
    },
    'de': <String, String>{
      'today': 'Heute',
      'upcoming': 'Demnächst',
      'completed': 'Erledigt',
      'todaySubtitle':
          'Was jetzt Aufmerksamkeit braucht, inklusive Aufgaben ohne Datum.',
      'upcomingSubtitle': 'Geplante Arbeit mit einem zukünftigen Termin.',
      'completedSubtitle': 'Ein ruhigeres Archiv fertiger Aufgaben.',
      'searchTasks': 'Aufgaben suchen',
      'filter': 'Filter',
      'settings': 'Einstellungen',
      'filtersSort': 'Filter und Sortierung',
      'filtersHelp':
          'Passe die vorhandenen Desktop-Filter an, ohne die Logik zu ändern.',
      'reset': 'Zurücksetzen',
      'status': 'Status',
      'priority': 'Priorität',
      'list': 'Liste',
      'sort': 'Sortieren',
      'all': 'Alle',
      'active': 'Aktiv',
      'done': 'Erledigt',
      'any': 'Beliebig',
      'allLists': 'Alle Listen',
      'defaultSort': 'Standard',
      'dueDateDesc': 'Neuester Termin zuerst',
      'dueDateAsc': 'Ältester Termin zuerst',
      'priorityDesc': 'Priorität: Hoch nach Niedrig',
      'priorityAsc': 'Priorität: Niedrig nach Hoch',
      'titleAsc': 'Alphabetisch: A-Z',
      'titleDesc': 'Alphabetisch: Z-A',
      'createdDesc': 'Zuletzt erstellt',
      'createdAsc': 'Am ältesten',
      'low': 'Niedrig',
      'medium': 'Mittel',
      'high': 'Hoch',
      'personal': 'Privat',
      'work': 'Arbeit',
      'study': 'Lernen',
      'noDate': 'Kein Datum',
      'noToday': 'Nichts für Heute',
      'noUpcoming': 'Nichts demnächst',
      'noCompleted': 'Noch keine erledigten Aufgaben',
      'emptyPrompt': 'Beginnen Sie mit einer neuen Aufgabe.',
      'todayEmptyPrompt': 'Beginnen Sie mit einer Aufgabe für heute.',
      'upcomingEmptyPrompt':
          'Fügen Sie eine Aufgabe mit künftigem Datum hinzu.',
      'completedEmptyPrompt':
          'Erledigte Aufgaben erscheinen hier, sobald Sie eine abschließen.',
      'addTask': 'Aufgabe hinzufügen',
      'quickCapture': 'Aufgabe erfassen',
      'quickCaptureHint': 'Öffnen Sie den vollständigen Editor nur bei Bedarf.',
      'editTask': 'Aufgabe bearbeiten',
      'title': 'Titel',
      'note': 'Notiz',
      'dueDate': 'Fälligkeitsdatum',
      'save': 'Speichern',
      'cancel': 'Abbrechen',
      'delete': 'Löschen',
      'pickDate': 'Datum wählen',
      'clearDate': 'Datum entfernen',
      'theme': 'Design',
      'language': 'Sprache',
      'light': 'Hell',
      'dark': 'Dunkel',
      'auto': 'Auto',
      'english': 'Englisch',
      'turkish': 'Türkisch',
      'german': 'Deutsch',
      'spanish': 'Spanisch',
      'italian': 'Italienisch',
      'taskDetails': 'Aufgabendetails',
      'sync': 'Synchronisierung',
      'manualSyncHelp':
          'Lokale Änderungen senden und die neuesten Todos bei Bedarf aus Supabase laden.',
      'syncNow': 'Jetzt synchronisieren',
      'syncing': 'Synchronisierung läuft...',
      'syncSucceeded': 'Synchronisierung abgeschlossen',
      'syncFailed': 'Synchronisierung fehlgeschlagen',
      'syncUnavailable':
          'Setzen Sie SUPABASE_URL und SUPABASE_ANON_KEY, um die Synchronisierung zu aktivieren.',
    },
    'es': <String, String>{
      'today': 'Hoy',
      'upcoming': 'Próximas',
      'completed': 'Completadas',
      'todaySubtitle':
          'Lo que necesita atención ahora, incluidas las tareas sin fecha.',
      'upcomingSubtitle': 'Trabajo programado con una fecha futura.',
      'completedSubtitle': 'Un archivo más discreto del trabajo terminado.',
      'searchTasks': 'Buscar tareas',
      'filter': 'Filtro',
      'settings': 'Ajustes',
      'filtersSort': 'Filtros y orden',
      'filtersHelp': 'Ajusta los filtros existentes sin cambiar la lógica.',
      'reset': 'Restablecer',
      'status': 'Estado',
      'priority': 'Prioridad',
      'list': 'Lista',
      'sort': 'Ordenar',
      'all': 'Todas',
      'active': 'Activas',
      'done': 'Hechas',
      'any': 'Cualquiera',
      'allLists': 'Todas las listas',
      'defaultSort': 'Predeterminado',
      'dueDateDesc': 'Fecha más reciente primero',
      'dueDateAsc': 'Fecha más antigua primero',
      'priorityDesc': 'Prioridad: Alta a baja',
      'priorityAsc': 'Prioridad: Baja a alta',
      'titleAsc': 'Alfabético: A-Z',
      'titleDesc': 'Alfabético: Z-A',
      'createdDesc': 'Creadas recientemente',
      'createdAsc': 'Más antiguas',
      'low': 'Baja',
      'medium': 'Media',
      'high': 'Alta',
      'personal': 'Personal',
      'work': 'Trabajo',
      'study': 'Estudio',
      'noDate': 'Sin fecha',
      'noToday': 'Nada para hoy',
      'noUpcoming': 'Nada próximo',
      'noCompleted': 'Aún no hay tareas completadas',
      'emptyPrompt': 'Empieza agregando una tarea.',
      'todayEmptyPrompt': 'Empieza agregando algo para hoy.',
      'upcomingEmptyPrompt':
          'Agrega una tarea con fecha futura para planificar.',
      'completedEmptyPrompt':
          'Las tareas completadas aparecerán aquí cuando termines una.',
      'addTask': 'Agregar tarea',
      'quickCapture': 'Capturar tarea',
      'quickCaptureHint':
          'Abre el editor completo solo cuando necesites más detalle.',
      'editTask': 'Editar tarea',
      'title': 'Título',
      'note': 'Nota',
      'dueDate': 'Fecha límite',
      'save': 'Guardar',
      'cancel': 'Cancelar',
      'delete': 'Eliminar',
      'pickDate': 'Elegir fecha',
      'clearDate': 'Quitar fecha',
      'theme': 'Tema',
      'language': 'Idioma',
      'light': 'Claro',
      'dark': 'Oscuro',
      'auto': 'Auto',
      'english': 'Inglés',
      'turkish': 'Turco',
      'german': 'Alemán',
      'spanish': 'Español',
      'italian': 'Italiano',
      'taskDetails': 'Detalle de tarea',
      'sync': 'Sincronización',
      'manualSyncHelp':
          'Envía cambios locales y trae las tareas más recientes desde Supabase cuando lo necesites.',
      'syncNow': 'Sincronizar ahora',
      'syncing': 'Sincronizando...',
      'syncSucceeded': 'Sincronización completada',
      'syncFailed': 'La sincronización falló',
      'syncUnavailable':
          'Configura SUPABASE_URL y SUPABASE_ANON_KEY para habilitar la sincronización.',
    },
    'it': <String, String>{
      'today': 'Oggi',
      'upcoming': 'In arrivo',
      'completed': 'Completate',
      'todaySubtitle':
          'Ciò che richiede attenzione adesso, incluse le attività senza data.',
      'upcomingSubtitle': 'Lavoro pianificato con una data futura.',
      'completedSubtitle': 'Un archivio più discreto del lavoro completato.',
      'searchTasks': 'Cerca attività',
      'filter': 'Filtro',
      'settings': 'Impostazioni',
      'filtersSort': 'Filtri e ordinamento',
      'filtersHelp': 'Regola i filtri esistenti senza cambiare la logica.',
      'reset': 'Reimposta',
      'status': 'Stato',
      'priority': 'Priorità',
      'list': 'Lista',
      'sort': 'Ordina',
      'all': 'Tutte',
      'active': 'Attive',
      'done': 'Fatte',
      'any': 'Qualsiasi',
      'allLists': 'Tutte le liste',
      'defaultSort': 'Predefinito',
      'dueDateDesc': 'Scadenza più recente prima',
      'dueDateAsc': 'Scadenza più vecchia prima',
      'priorityDesc': 'Priorità: Da alta a bassa',
      'priorityAsc': 'Priorità: Da bassa ad alta',
      'titleAsc': 'Alfabetico: A-Z',
      'titleDesc': 'Alfabetico: Z-A',
      'createdDesc': 'Create di recente',
      'createdAsc': 'Più vecchie',
      'low': 'Bassa',
      'medium': 'Media',
      'high': 'Alta',
      'personal': 'Personale',
      'work': 'Lavoro',
      'study': 'Studio',
      'noDate': 'Nessuna data',
      'noToday': 'Niente per oggi',
      'noUpcoming': 'Niente in arrivo',
      'noCompleted': 'Nessuna attività completata finora',
      'emptyPrompt': 'Inizia aggiungendo un’attività.',
      'todayEmptyPrompt': 'Inizia aggiungendo qualcosa per oggi.',
      'upcomingEmptyPrompt':
          'Aggiungi un’attività con una data futura per pianificare.',
      'completedEmptyPrompt':
          'Le attività completate appariranno qui quando ne chiudi una.',
      'addTask': 'Aggiungi attività',
      'quickCapture': 'Cattura attività',
      'quickCaptureHint':
          'Apri l’editor completo solo quando servono dettagli.',
      'editTask': 'Modifica attività',
      'title': 'Titolo',
      'note': 'Nota',
      'dueDate': 'Scadenza',
      'save': 'Salva',
      'cancel': 'Annulla',
      'delete': 'Elimina',
      'pickDate': 'Scegli data',
      'clearDate': 'Rimuovi data',
      'theme': 'Tema',
      'language': 'Lingua',
      'light': 'Chiaro',
      'dark': 'Scuro',
      'auto': 'Auto',
      'english': 'Inglese',
      'turkish': 'Turco',
      'german': 'Tedesco',
      'spanish': 'Spagnolo',
      'italian': 'Italiano',
      'taskDetails': 'Dettagli attività',
      'sync': 'Sincronizzazione',
      'manualSyncHelp':
          'Invia le modifiche locali e recupera le attività più recenti da Supabase quando serve.',
      'syncNow': 'Sincronizza ora',
      'syncing': 'Sincronizzazione in corso...',
      'syncSucceeded': 'Sincronizzazione completata',
      'syncFailed': 'Sincronizzazione non riuscita',
      'syncUnavailable':
          'Imposta SUPABASE_URL e SUPABASE_ANON_KEY per abilitare la sincronizzazione.',
    },
  };

  String _text(String key) {
    return _values[_languageCode]?[key] ?? _values['en']![key]!;
  }

  String get searchTasks => _text('searchTasks');
  String get filter => _text('filter');
  String get settings => _text('settings');
  String get filtersSort => _text('filtersSort');
  String get filtersHelp => _text('filtersHelp');
  String get reset => _text('reset');
  String get status => _text('status');
  String get priority => _text('priority');
  String get list => _text('list');
  String get sort => _text('sort');
  String get all => _text('all');
  String get active => _text('active');
  String get done => _text('done');
  String get any => _text('any');
  String get allLists => _text('allLists');
  String get noDate => _text('noDate');
  String get emptyPrompt => _text('emptyPrompt');
  String get addTask => _text('addTask');
  String get quickCapture => _text('quickCapture');
  String get quickCaptureHint => _text('quickCaptureHint');
  String get editTask => _text('editTask');
  String get title => _text('title');
  String get note => _text('note');
  String get dueDate => _text('dueDate');
  String get save => _text('save');
  String get cancel => _text('cancel');
  String get delete => _text('delete');
  String get pickDate => _text('pickDate');
  String get clearDate => _text('clearDate');
  String get theme => _text('theme');
  String get language => _text('language');
  String get taskDetails => _text('taskDetails');
  String get sync => _text('sync');
  String get manualSyncHelp => _text('manualSyncHelp');
  String get syncNow => _text('syncNow');
  String get syncing => _text('syncing');
  String get syncSucceeded => _text('syncSucceeded');
  String get syncFailed => _text('syncFailed');
  String get syncUnavailable => _text('syncUnavailable');

  String sectionLabel(Section section) {
    switch (section) {
      case Section.today:
        return _text('today');
      case Section.upcoming:
        return _text('upcoming');
      case Section.completed:
        return _text('completed');
    }
  }

  String sectionSubtitle(Section section) {
    switch (section) {
      case Section.today:
        return _text('todaySubtitle');
      case Section.upcoming:
        return _text('upcomingSubtitle');
      case Section.completed:
        return _text('completedSubtitle');
    }
  }

  String emptySectionLabel(Section section) {
    switch (section) {
      case Section.today:
        return _text('noToday');
      case Section.upcoming:
        return _text('noUpcoming');
      case Section.completed:
        return _text('noCompleted');
    }
  }

  String emptySectionPrompt(Section section) {
    switch (section) {
      case Section.today:
        return _text('todayEmptyPrompt');
      case Section.upcoming:
        return _text('upcomingEmptyPrompt');
      case Section.completed:
        return _text('completedEmptyPrompt');
    }
  }

  String filterCountLabel(int count) {
    return count == 0 ? filter : '$filter ($count)';
  }

  String priorityLabel(Priority priority) {
    switch (priority) {
      case Priority.low:
        return _text('low');
      case Priority.medium:
        return _text('medium');
      case Priority.high:
        return _text('high');
    }
  }

  String categoryLabel(Category category) {
    switch (category) {
      case Category.personal:
        return _text('personal');
      case Category.work:
        return _text('work');
      case Category.study:
        return _text('study');
    }
  }

  String sortLabel(SortOrder sortOrder) {
    switch (sortOrder) {
      case SortOrder.defaultOrder:
        return _text('defaultSort');
      case SortOrder.dueDateDesc:
        return _text('dueDateDesc');
      case SortOrder.dueDateAsc:
        return _text('dueDateAsc');
      case SortOrder.priorityDesc:
        return _text('priorityDesc');
      case SortOrder.priorityAsc:
        return _text('priorityAsc');
      case SortOrder.titleAsc:
        return _text('titleAsc');
      case SortOrder.titleDesc:
        return _text('titleDesc');
      case SortOrder.createdDesc:
        return _text('createdDesc');
      case SortOrder.createdAsc:
        return _text('createdAsc');
    }
  }

  String themeLabel(AppThemePreference preference) {
    switch (preference) {
      case AppThemePreference.light:
        return _text('light');
      case AppThemePreference.dark:
        return _text('dark');
      case AppThemePreference.system:
        return _text('auto');
    }
  }

  String languageLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.en:
        return _text('english');
      case AppLanguage.tr:
        return _text('turkish');
      case AppLanguage.de:
        return _text('german');
      case AppLanguage.es:
        return _text('spanish');
      case AppLanguage.it:
        return _text('italian');
    }
  }
}
