import Foundation

/// All user-facing strings, in English and Portuguese.
enum L {
    case capture, settings, quit
    case appearance, language, general, launchAtLogin, launchAtLoginFailed, themeSystem, themeLight, themeDark
    case shortcuts, shortcutCapture, shortcutCopy, shortcutSave, shortcutUndo, shortcutCancel, shortcutThickness
    case scrollWheel, offlineNote
    case toolSelect, toolPencil, toolLine, toolArrow, toolRectangle, toolFilledRectangle
    case toolEllipse, toolMarker, toolText, toolCounter, toolPixelate
    case undo, redo, copy, save, pin, close, thickness, thinner, thicker, colorAndThickness
    case hint
    case permissionTitle, permissionMessage, openSystemSettings, cancel, ok
    case captureFailed, saveFailed
    case copyShort, saveShort, closeShort, hotKeyUnavailable
    case installTitle, installMessage, install, notNow, installFailed

    var pair: (en: String, pt: String) {
        switch self {
        case .capture: return ("Take Screenshot", "Capturar Tela")
        case .settings: return ("Settings…", "Ajustes…")
        case .quit: return ("Quit EasierShot", "Encerrar EasierShot")
        case .appearance: return ("Appearance", "Aparência")
        case .language: return ("Language", "Idioma")
        case .general: return ("General", "Geral")
        case .launchAtLogin: return ("Open EasierShot at login", "Abrir o EasierShot ao iniciar o sistema")
        case .launchAtLoginFailed: return ("Could not update login item", "Não foi possível atualizar a inicialização do sistema")
        case .themeSystem: return ("System", "Sistema")
        case .themeLight: return ("Light", "Claro")
        case .themeDark: return ("Dark", "Escuro")
        case .shortcuts: return ("Shortcuts", "Atalhos")
        case .shortcutCapture: return ("Take screenshot", "Capturar tela")
        case .shortcutCopy: return ("Copy to clipboard", "Copiar para a área de transferência")
        case .shortcutSave: return ("Save to file", "Salvar em arquivo")
        case .shortcutUndo: return ("Undo / Redo", "Desfazer / Refazer")
        case .shortcutCancel: return ("Cancel capture", "Cancelar captura")
        case .shortcutThickness: return ("Change thickness", "Alterar espessura")
        case .scrollWheel: return ("Scroll", "Rolagem")
        case .offlineNote:
            return ("EasierShot works 100% offline. Your screenshots never leave this Mac.",
                    "O EasierShot funciona 100% offline. Suas capturas nunca saem deste Mac.")
        case .toolSelect: return ("Move / resize selection", "Mover / redimensionar seleção")
        case .toolPencil: return ("Pencil", "Lápis")
        case .toolLine: return ("Line", "Linha")
        case .toolArrow: return ("Arrow", "Seta")
        case .toolRectangle: return ("Rectangle", "Retângulo")
        case .toolFilledRectangle: return ("Filled rectangle", "Retângulo preenchido")
        case .toolEllipse: return ("Ellipse", "Elipse")
        case .toolMarker: return ("Marker", "Marca-texto")
        case .toolText: return ("Text", "Texto")
        case .toolCounter: return ("Counter bubble", "Contador numerado")
        case .toolPixelate: return ("Pixelate", "Pixelizar")
        case .undo: return ("Undo (⌘Z)", "Desfazer (⌘Z)")
        case .redo: return ("Redo (⇧⌘Z)", "Refazer (⇧⌘Z)")
        case .copy: return ("Copy to clipboard (⌘C or Enter)", "Copiar para a área de transferência (⌘C ou Enter)")
        case .save: return ("Save… (⌘S)", "Salvar… (⌘S)")
        case .pin: return ("Pin on screen", "Fixar na tela")
        case .close: return ("Close (Esc)", "Fechar (Esc)")
        case .thickness: return ("Thickness", "Espessura")
        case .colorAndThickness: return ("Color and thickness", "Cor e espessura")
        case .thinner: return ("Thinner", "Mais fino")
        case .thicker: return ("Thicker", "Mais grosso")
        case .hint:
            return ("Click and drag to select an area  ·  Enter copies the full screen  ·  Esc cancels",
                    "Clique e arraste para selecionar uma área  ·  Enter copia a tela inteira  ·  Esc cancela")
        case .permissionTitle:
            return ("Screen Recording permission required", "Permissão de Gravação de Tela necessária")
        case .permissionMessage:
            return ("To take screenshots, allow EasierShot under System Settings › Privacy & Security › Screen & System Audio Recording, then reopen the app.",
                    "Para capturar a tela, autorize o EasierShot em Ajustes do Sistema › Privacidade e Segurança › Gravação de Tela e Áudio do Sistema e depois reabra o app.")
        case .openSystemSettings: return ("Open System Settings", "Abrir Ajustes do Sistema")
        case .cancel: return ("Cancel", "Cancelar")
        case .ok: return ("OK", "OK")
        case .captureFailed: return ("Could not capture the screen", "Não foi possível capturar a tela")
        case .saveFailed: return ("Could not save the image", "Não foi possível salvar a imagem")
        case .copyShort: return ("Copy", "Copiar")
        case .saveShort: return ("Save…", "Salvar…")
        case .closeShort: return ("Close", "Fechar")
        case .hotKeyUnavailable:
            return ("The ⇧⌘2 shortcut is in use by another app. Use the menu bar icon to capture.",
                    "O atalho ⇧⌘2 está em uso por outro app. Use o ícone da barra de menus para capturar.")
        case .installTitle: return ("Install EasierShot?", "Instalar o EasierShot?")
        case .installMessage:
            return ("EasierShot will be copied to the Applications folder, reopened from there, and the installer disk will be ejected.",
                    "O EasierShot será copiado para a pasta Aplicativos, reaberto a partir dela, e o disco do instalador será ejetado.")
        case .install: return ("Install", "Instalar")
        case .notNow: return ("Not Now", "Agora Não")
        case .installFailed: return ("Could not install EasierShot", "Não foi possível instalar o EasierShot")
        }
    }
}
