class Translation {
  static final Translation _instance = Translation._();

  bool _isEnglish = true;
  bool get isEnglish => _isEnglish;

  Translation._();

  factory Translation() {
    return _instance;
  }

  setLanguage(bool isEnglish) {
    _isEnglish = isEnglish;
  }

  String getString(String key) {
    switch (key) {
      case "unknown":
        // could not find a relationship
        return isEnglish ? "unknown" : "desconocido";

      case "Who are you?":
        // self identification prompt
        return isEnglish ? "Who are you?" : "¿Quién eres tú?";

      case "language":
        // language selection toggle
        return isEnglish ? "Spanish" : "Inglés";

      case "mendoza_family_book":
        // main title
        return isEnglish ? "Mendoza Family Book" : "Libro de Familia Mendoza";

      case "see_relationship_tree":
        // button to view relationship tree
        return isEnglish ? "See Relationship Tree" : "Ver árbol de relaciones";

      case "see_full_tree":
        // button to view full family tree
        return isEnglish
            ? "See Full Family Tree"
            : "Ver Árbol Genealógico Completo";

      case "people_picker_title":
        // title of people search page
        return isEnglish ? "Person Search" : "Búsqueda de Persona";

      case "people_picker_instruction":
        // instructions for search page
        return isEnglish
            ? "Enter Name or Family Id"
            : "Ingrese el nombre o identificación de la familia";

      case "horizontal":
        // could not find a relationship
        return isEnglish ? "Horizontal" : "Horizontal";

      case "vertical":
        // could not find a relationship
        return isEnglish ? "Vertical" : "Vertical";

      case "reset_view":
        // could not find a relationship
        return isEnglish ? "Reset View" : "Reestablecer vista";

      case "toggle_node_size":
        // could not find a relationship
        return isEnglish ? "Toggle Node Size" : "Alternar tamaño de nodo";

      case "family_tree":
        // could not find a relationship
        return isEnglish ? "Family Tree" : "Árbol de familia";

      case "cancel":
        // could not find a relationship
        return isEnglish ? "Cancel" : "Cancelar";

      case "confirm":
        // could not find a relationship
        return isEnglish ? "Confirm" : "Confirmar";

      case "confirm_selection":
        // could not find a relationship
        return isEnglish ? "Confirm Selection" : "Confirmar selección";

      case "you_sure":
        // could not find a relationship
        return isEnglish ? "Are You Sure?" : "¿Estas seguro?";

      case "filter_by_group":
        // could not find a relationship
        return isEnglish
            ? "Filter by Family Group:"
            : "Filtrar por Grupo Familiar:";
      case "select":
        // could not find a relationship
        return isEnglish ? "Select" : "Seleccione";
      case "child":
        // could not find a relationship
        return isEnglish ? "child" : "hijo / hija";
      case "parent":
        // could not find a relationship
        return isEnglish ? "parents" : "madre / padre";
      case "sibling":
        // could not find a relationship
        return isEnglish ? "sibling" : "hermano / hermana";
      case "nibling":
        // could not find a relationship
        return isEnglish ? "Niece / Nephew" : "Sobrino / Sobrina";
      case "titi":
        // could not find a relationship
        return isEnglish ? "Aunt / Uncle" : "Tío / tía";
      case "cousin":
        // could not find a relationship
        return isEnglish ? " cousin " : " prima / primo ";
      case "once_removed":
        // could not find a relationship
        return isEnglish ? "once removed" : " una vez eliminado ";
      case "twice_removed":
        // could not find a relationship
        return isEnglish ? "twice removed" : "eliminado dos veces";
      case "thrice_removed":
        // could not find a relationship
        return isEnglish ? "thrice removed " : "Tres veces eliminada";
      case "four":
        // could not find a relationship
        return isEnglish ? "four" : "cuatro";
      case "five":
        // could not find a relationship
        return isEnglish ? "five" : "cinco";
      case "six":
        // could not find a relationship
        return isEnglish ? "six" : "seis";
      case "seven":
        // could not find a relationship
        return isEnglish ? "seven" : "siete";
      case "eight":
        // could not find a relationship
        return isEnglish ? "eight" : "ocho";
      case "nine":
        // could not find a relationship
        return isEnglish ? "nine" : "nueve";

      case "ten":
        // could not find a relationship
        return isEnglish ? "ten" : "diez";
      case "removed":
        // could not find a relationship
        return isEnglish ? "removed" : " prima / primo ";

      default:
        return "<STRING UNTRANSLATED>";
    }
  }
}
