/*
 * Copyright 2015  Martin Kotelnik <clearmartin@seznam.cz>
 * Copyright 2020  Frieder Reinhold <reinhold@trigon-media.com>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http: //www.gnu.org/licenses/>.
 */
import QtQuick 2.2
import QtQuick.Layouts 1.1
import QtGraphicalEffects 1.0
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.kio 1.0 as Kio

Item {
    id: main
    
    property bool vertical: (plasmoid.formFactor == PlasmaCore.Types.Vertical)
    
    property bool verticalLayout: plasmoid.configuration.verticalLayout
    property bool showCpuMonitor: plasmoid.configuration.showCpuMonitor
    property bool showClock: plasmoid.configuration.showClock
    property bool showRamMonitor: plasmoid.configuration.showRamMonitor
    property bool showNetMonitor: plasmoid.configuration.showNetMonitor
    property bool memoryInPercent: plasmoid.configuration.memoryInPercent
    property bool enableHints: plasmoid.configuration.enableHints
    property bool enableShadows: plasmoid.configuration.enableShadows
    property bool showMemoryInPercent: memoryInPercent
    property int downloadMaxKBs: plasmoid.configuration.downloadMaxKBs
    property int uploadMaxKBs: plasmoid.configuration.uploadMaxKBs
    property color networkUploadDiagramColor: plasmoid.configuration.networkUploadDiagramColor
    property color networkDownloadDiagramColor: plasmoid.configuration.networkDownloadDiagramColor
    
    property int containerCount: (showCpuMonitor?1:0) + (showRamMonitor?1:0) + (showNetMonitor?1:0)
    property int itemMargin: 5
    property double parentWidth: parent === null ? 0 : parent.width
    property double parentHeight: parent === null ? 0 : parent.height
    property double itemWidth:  vertical ? ( verticalLayout ? parentWidth : (parentWidth - itemMargin) / 2 ) : ( verticalLayout ? (parentHeight - itemMargin) / 2 : parentHeight )
    property double itemHeight: itemWidth
    property double fontPixelSize: itemHeight * 0.26
    property int graphGranularity: 20
    
    property color warningColor: Qt.tint(theme.textColor, '#60FF0000')
    property string textFontFamily: theme.defaultFont.family

    property double widgetWidth: !verticalLayout ? (itemWidth*containerCount + itemMargin*(containerCount)*2) : itemWidth
    property double widgetHeight: verticalLayout ? (itemWidth*containerCount + itemMargin*(containerCount)*2) : itemWidth

    Layout.preferredWidth:  widgetWidth
    Layout.maximumWidth: widgetWidth
    Layout.preferredHeight: widgetHeight
    Layout.maximumHeight: widgetHeight
    
    Plasmoid.preferredRepresentation: Plasmoid.fullRepresentation
    
    anchors.fill: parent
    
    onShowMemoryInPercentChanged: {
        allUsageProportionChanged()
    }
    
    Kio.KRun {
        id: kRun
    }
    
    // We need to get the full path to KSysguard to be able to run it
    PlasmaCore.DataSource {
        id: apps
        engine: 'apps'
        property string ksysguardSource: 'org.kde.ksysguard.desktop'
        connectedSources: [ ksysguardSource ]
    }

    PlasmaCore.DataSource {
        id: dataSource
        engine: "systemmonitor"

        property string cpuSystem: "cpu/system/"
        property string averageClock: cpuSystem + "AverageClock"
        property string totalLoad: cpuSystem + "TotalLoad"
        property string memPhysical: "mem/physical/"
        property string memFree: memPhysical + "free"
        property string memApplication: memPhysical + "application"
        property string memUsed: memPhysical + "used"
        property string swap: "mem/swap/"
        property string swapUsed: swap + "used"
        property string swapFree: swap + "free"
        property string downloadTotal: plasmoid.configuration.networkSensorDownload
        property string uploadTotal: plasmoid.configuration.networkSensorUpload

        property double totalCpuLoad: .0
        property int averageCpuClock: 0
        property int ramUsedBytes: 0
        property double ramUsedProportion: 0
        property int swapUsedBytes: 0
        property double swapUsedProportion: 0
        property double downloadKBs: 0
        property double uploadKBs: 0
        property double downloadProportion: 0
        property double uploadProportion: 0

        connectedSources: [memFree, memUsed, memApplication, swapUsed, swapFree, averageClock, totalLoad, downloadTotal, uploadTotal ]
        
        onNewData: {
            if (data.value === undefined) {
                return
            }
            if (sourceName == memApplication) {
                ramUsedBytes = parseInt(data.value)
                ramUsedProportion = fitMemoryUsage(data.value)
            }
            else if (sourceName == swapUsed) {
                swapUsedBytes = parseInt(data.value)
                swapUsedProportion = fitSwapUsage(data.value)
            }
            else if (sourceName == totalLoad) {
                totalCpuLoad = data.value / 100
            }
            else if (sourceName == averageClock) {
                averageCpuClock = parseInt(data.value)
                allUsageProportionChanged()
            }
            else if (sourceName == downloadTotal) {
                downloadKBs = parseFloat(data.value)
                downloadProportion = fitDownloadRate(data.value)
            }
             else if (sourceName == uploadTotal) {
                uploadKBs = parseFloat(data.value)
                uploadProportion = fitUploadRate(data.value)
            }
        }
        interval: 1000 * plasmoid.configuration.updateInterval
    }
    
    function fitMemoryUsage(usage) {
        var memFree = dataSource.data[dataSource.memFree]
        var memUsed = dataSource.data[dataSource.memUsed]
        if (!memFree || !memUsed) {
            return 0
        }
        return (usage / (parseFloat(memFree.value) +
                         parseFloat(memUsed.value)))
    }

    function fitSwapUsage(usage) {
        var swapFree = dataSource.data[dataSource.swapFree]
        if (!swapFree) {
            return 0
        }
        return (usage / (parseFloat(usage) + parseFloat(swapFree.value)))
    }

    function fitDownloadRate(rate) {
        if (!downloadMaxKBs) {
            return 0
        }
        return (rate / downloadMaxKBs)
    }

    function fitUploadRate(rate) {
        if (!uploadMaxKBs) {
            return 0
        }
        return (rate / uploadMaxKBs)
    }

    ListModel {
        id: cpuGraphModel
    }
    
    ListModel {
        id: ramGraphModel
    }
    
    ListModel {
        id: swapGraphModel
    }

    ListModel {
        id: uploadGraphModel
    }

    ListModel {
        id: downloadGraphModel
    }
    
    function getHumanReadableMemory(memBytes) {
        var megaBytes = memBytes / 1024
        if (megaBytes <= 1024) {
            return Math.round(megaBytes) + 'M'
        }
        return Math.round(megaBytes / 1024 * 100) / 100 + 'G'
    }
    
    function getHumanReadableClock(clockMhz) {
        var clockNumber = clockMhz
        if (clockNumber < 1000) {
            return clockNumber + 'MHz'
        }
        clockNumber = clockNumber / 1000
        var floatingPointCount = 100
        if (clockNumber >= 10) {
            floatingPointCount = 10
        }
        return Math.round(clockNumber * floatingPointCount) / floatingPointCount + 'GHz'
    }
    
    function getHumanReadableNetRate(rateKiBs){
        if(rateKiBs <= 1024){
            return rateKiBs + 'K'
        }
        return Math.round(rateKiBs / 1024 * 100) / 100 + 'M'
    }

    function allUsageProportionChanged() {
        
        var totalCpuProportion = dataSource.totalCpuLoad
        var totalRamProportion = dataSource.ramUsedProportion
        var totalSwapProportion = dataSource.swapUsedProportion
        var totalDownloadProportion = dataSource.downloadProportion
        var totalUploadProportion = dataSource.uploadProportion
        
        cpuPercentText.text = Math.round(totalCpuProportion * 100) + '%'
        cpuPercentText.color = totalCpuProportion > 0.9 ? warningColor : theme.textColor
        averageClockText.text = getHumanReadableClock(dataSource.averageCpuClock)
        
        ramPercentText.text = showMemoryInPercent ? Math.round(totalRamProportion * 100) + '%' : getHumanReadableMemory(dataSource.ramUsedBytes)
        ramPercentText.color = totalRamProportion > 0.9 ? warningColor : theme.textColor
        swapPercentText.text = showMemoryInPercent ? Math.round(totalSwapProportion * 100) + '%' : getHumanReadableMemory(dataSource.swapUsedBytes)
        swapPercentText.color = totalSwapProportion > 0.9 ? warningColor : theme.textColor
        swapPercentText.visible = !swapInfoText.visible && totalSwapProportion > 0
        
        if (showCpuMonitor) {
            addGraphData(cpuGraphModel, totalCpuProportion, graphGranularity)
        }
        if (showRamMonitor) {
            addGraphData(ramGraphModel, totalRamProportion, graphGranularity)
            addGraphData(swapGraphModel, totalSwapProportion, graphGranularity)
        }
        if(showNetMonitor){
            addGraphData(uploadGraphModel, totalUploadProportion * itemHeight, graphGranularity)
            addGraphData(downloadGraphModel, totalDownloadProportion * itemHeight, graphGranularity)
        }

        netUploadKiBsText.text = getHumanReadableNetRate(dataSource.uploadKBs)
        netDownloadKiBsText.text = getHumanReadableNetRate(dataSource.downloadKBs)
    }
    
    function addGraphData(model, graphItemPercent, graphGranularity) {
        
        // initial fill up
        while (model.count < graphGranularity) {
            model.append({
                'graphItemPercent': 0
            })
        }
        
        var newItem = {
            'graphItemPercent': graphItemPercent
        }
        
        model.append(newItem)
        model.remove(0)
    }
    
    onShowClockChanged: {
        averageClockText.visible = showClock
    }
    
    Item {
        id: cpuMonitor
        width: itemWidth
        height: itemHeight
        
        visible: showCpuMonitor
        
        HistoryGraph {
            anchors.fill: parent
            listViewModel: cpuGraphModel
            barColor: theme.highlightColor
        }
        
        Item {
            id: cpuTextContainer
            anchors.fill: parent
            
            PlasmaComponents.Label {
                id: cpuInfoText
                anchors.right: parent.right
                verticalAlignment: Text.AlignTop
                text: 'CPU'
                color: theme.highlightColor
                font.pixelSize: fontPixelSize
                font.pointSize: -1
                visible: false
            }
            
            PlasmaComponents.Label {
                id: cpuPercentText
                anchors.right: parent.right
                verticalAlignment: Text.AlignTop
                text: '...'
                font.pixelSize: fontPixelSize
                font.pointSize: -1
            }
            
            PlasmaComponents.Label {
                id: averageClockText
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                font.pixelSize: fontPixelSize
                font.pointSize: -1
                visible: showClock
            }
            
            PlasmaComponents.Label {
                id: averageClockInfoText
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                font.pixelSize: fontPixelSize
                font.pointSize: -1
                text: 'Clock'
                visible: false
            }
        
        }
        
        DropShadow {
        	visible: enableShadows
            anchors.fill: cpuTextContainer
            radius: 3
            samples: 8
            spread: 0.8
            fast: true
            color: theme.backgroundColor
            source: cpuTextContainer
        }
        
        MouseArea {
            anchors.fill: parent
            hoverEnabled: enableHints
            
            onEntered: {
                cpuInfoText.visible = true
                cpuPercentText.visible = false
                averageClockInfoText.visible = showClock && true
                averageClockText.visible = false
            }
            
            onExited: {
                cpuInfoText.visible = false
                cpuPercentText.visible = true
                averageClockInfoText.visible = false
                averageClockText.visible = showClock && true
            }
        }
    }
    
    Item {
        id: ramMonitor
        width: itemWidth
        height: itemHeight
        anchors.left: parent.left
        anchors.leftMargin: showCpuMonitor && !verticalLayout ? itemWidth + itemMargin : 0
        anchors.top: parent.top
        anchors.topMargin: showCpuMonitor && verticalLayout ? itemWidth + itemMargin : 0
        
        visible: showRamMonitor
        
        HistoryGraph {
            listViewModel: ramGraphModel
            barColor: theme.highlightColor
        }
        
        HistoryGraph {
            listViewModel: swapGraphModel
            barColor: '#FF0000'
        }
        
        Item {
            id: ramTextContainer
            anchors.fill: parent
            
            PlasmaComponents.Label {
                id: ramInfoText
                text: 'RAM'
                color: theme.highlightColor
                font.pixelSize: fontPixelSize
                font.pointSize: -1
                anchors.right: parent.right
                verticalAlignment: Text.AlignTop
                visible: false
            }
            
            PlasmaComponents.Label {
                id: ramPercentText
                anchors.right: parent.right
                verticalAlignment: Text.AlignTop
                text: '...'
                font.pixelSize: fontPixelSize
                font.pointSize: -1
            }
            
            PlasmaComponents.Label {
                id: swapPercentText
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                font.pixelSize: fontPixelSize
                font.pointSize: -1
            }
            
            PlasmaComponents.Label {
                id: swapInfoText
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                color: '#FF0000'
                font.pixelSize: fontPixelSize
                font.pointSize: -1
                text: 'Swap'
                visible: false
            }
            
        }
        
        DropShadow {
            visible: enableShadows
            anchors.fill: ramTextContainer
            radius: 3
            samples: 8
            spread: 0.8
            fast: true
            color: theme.backgroundColor
            source: ramTextContainer
        }
        
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            
            onEntered: {
                if (enableHints) {
                    ramInfoText.visible = true
                    ramPercentText.visible = false
                    swapInfoText.visible = true
                    swapPercentText.visible = false
                } else {
                    showMemoryInPercent = !memoryInPercent
                }
            }
            
            onExited: {
                ramInfoText.visible = false
                ramPercentText.visible = true
                swapInfoText.visible = false
                swapPercentText.visible = true
                
                showMemoryInPercent = memoryInPercent
            }
        }
    }
    
     Item {
        id: netMonitor
        width: itemWidth
        height: itemHeight
        anchors.left: parent.left
        anchors.leftMargin: (showCpuMonitor && !verticalLayout ? itemWidth + itemMargin: 0) + (showRamMonitor && !verticalLayout ? itemWidth + itemMargin : 0)
        anchors.top: parent.top
        anchors.topMargin: (showCpuMonitor && verticalLayout ? itemWidth + itemMargin: 0) + (showRamMonitor && verticalLayout ? itemWidth + itemMargin : 0)

        visible: showNetMonitor

        HistoryGraph {
            listViewModel: uploadGraphModel
            barColor: networkUploadDiagramColor
        }

        HistoryGraph {
            listViewModel: downloadGraphModel
            barColor: networkDownloadDiagramColor
        }

        Item {
            id: netMonitorTextContainer
            anchors.fill: parent

            PlasmaComponents.Label {
                id: netUploadInfoText
                text: 'Up'
                color: '#FF0000'
                font.pixelSize: fontPixelSize
                font.pointSize: -1
                anchors.right: parent.right
                verticalAlignment: Text.AlignTop
                visible: false
            }

            PlasmaComponents.Label {
                id: netUploadKiBsText
                anchors.right: parent.right
                verticalAlignment: Text.AlignTop
                text: '...'
                font.pixelSize: fontPixelSize
                font.pointSize: -1
            }

            PlasmaComponents.Label {
                id: netDownloadKiBsText
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                font.pixelSize: fontPixelSize
                font.pointSize: -1
            }

            PlasmaComponents.Label {
                id: netDownloadInfoText
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                color: '#00FF00'
                font.pixelSize: fontPixelSize
                font.pointSize: -1
                text: 'Down'
                visible: false
            }
        }

        DropShadow {
            visible: enableShadows
            anchors.fill: netMonitorTextContainer
            radius: 3
            samples: 8
            spread: 0.8
            fast: true
            color: theme.backgroundColor
            source: netMonitorTextContainer
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: enableHints

            onEntered: {
                netUploadInfoText.visible = true
                netUploadKiBsText.visible = false
                netDownloadInfoText.visible = true
                netDownloadKiBsText.visible = false
            }

            onExited: {
                netUploadInfoText.visible = false
                netUploadKiBsText.visible = true
                netDownloadInfoText.visible = false
                netDownloadKiBsText.visible = true
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        onClicked: {
            kRun.openUrl(apps.data[apps.ksysguardSource].entryPath)
        }
    }
    
}
