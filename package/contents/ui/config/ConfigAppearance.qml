import QtQuick 2.2
import QtQuick.Controls 1.3
import QtQuick.Layouts 1.1

import org.kde.kirigami 2.3 as Kirigami
import org.kde.kquickcontrols 2.0 as KQuickControls

Item {
    
    property alias cfg_networkDownloadDiagramColor: networkDownloadDiagramColor.color
    property alias cfg_networkUploadDiagramColor: networkUploadDiagramColor.color

    Kirigami.FormLayout {

        KQuickControls.ColorButton {
            id: networkUploadDiagramColor
            showAlphaChannel:true
            Kirigami.FormData.label: i18n('Network upload diagram color')
        }

        KQuickControls.ColorButton {
            id: networkDownloadDiagramColor
            showAlphaChannel:true
            Kirigami.FormData.label: i18n('Network download diagram color')
        }
    }
}
