import 'dart:collection';

import 'common_util.dart';

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
        break;
      case "Who are you?":
        // self identification prompt
        return isEnglish ? "Who are you?" : "¿Quién eres tú?";
        break;
      case "language":
        // language selection toggle
        return isEnglish ? "Spanish" : "Inglés";
        break;
      case "mendoza_family_book":
        // main title
        return isEnglish ? "Mendoza Family Book" : "Libro de Familia Mendoza";
        break;
      case "see_relationship_tree":
        // button to view relationship tree
        return isEnglish ? "See Relationship Tree" : "Ver árbol de relaciones";
        break;
      case "see_full_tree":
        // button to view full family tree
        return isEnglish
            ? "See Full Family Tree"
            : "Ver Árbol Genealógico Completo";
        break;
      case "people_picker_title":
        // title of people search page
        return isEnglish ? "Find Person" : "Buscar Persona";
        break;
      case "":
        // could not find a relationship
        return isEnglish ? "" : "";
        break;
      case "":
        // could not find a relationship
        return isEnglish ? "" : "";
        break;

      default:
    }
    return "<STRING UNTRANSLATED>";
  }
}
