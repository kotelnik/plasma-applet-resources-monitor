import QtQuick 2.2
import QtQuick.Controls 1.3
import QtQuick.Layouts 1.1

Item {
    
    property alias cfg_networkSensorDownload: networkSensorDownload.text
    property alias cfg_downloadMaxKBs: downloadMaxKBs.value
    property alias cfg_networkSensorUpload: networkSensorUpload.text
    property alias cfg_uploadMaxKBs: uploadMaxKBs.value

    GridLayout {
        Layout.fillWidth: true
        columns: 2
        
        Label {
            text: i18n('Network download sensor')
            Layout.alignment: Qt.AlignRight
        }
        TextField {
            id: networkSensorDownload
            placeholderText: 'network/interfaces/enp4s0/receiver/data'
            Layout.preferredWidth: 500
            onTextChanged: cfg_networkSensorDownload = text
        }
        
        Label {
            text: i18n('Max download speed:')
            Layout.alignment: Qt.AlignRight
        }
        SpinBox {
            id: downloadMaxKBs
            decimals: 0
            stepSize: 10
            minimumValue: 10
            maximumValue: 100000
            value: cfg_downloadMaxKBs
            suffix: i18nc('Abbreviation for KB/s', ' KB/s')
        }
        
        Label {
            text: i18n('Network upload sensor')
            Layout.alignment: Qt.AlignRight
        }
        TextField {
            id: networkSensorUpload
            placeholderText: 'network/interfaces/enp4s0/transmitter/data'
            Layout.preferredWidth: 500
            onTextChanged: cfg_networkSensorUpload = text
        }
        
        Label {
            text: i18n('Max upload speed:')
            Layout.alignment: Qt.AlignRight
        }
        SpinBox {
            id: uploadMaxKBs
            decimals: 0
            stepSize: 10
            minimumValue: 10
            maximumValue: 100000
            value: cfg_uploadMaxKBs
            suffix: i18nc('Abbreviation for KB/s', ' KB/s')
        }        
        
    }
    
}
