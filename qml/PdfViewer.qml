/**
*   @ProjectName:       QMLPdfReader
*   @Brief：
*   @Author:            linjianpeng(lindyer)
*   @Date:              2018-11-16
*   @Note:              Copyright Reserved, Github: https://github.com/lindyer/
*/

import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Dialogs 1.2
import QtGraphicalEffects 1.0

Rectangle {
    id: _container
    clip: true

    Rectangle {
            id: _root
            width: parent.width/2-5
            height: parent.height
            anchors.left: parent.left
            anchors.top: parent.top
            color: "gray"
            //property string fileName: "C:/Users/C24/Desktop/1.pdf"
            signal updateImageNotify(string path)
            clip: true
            property string fnOpen: "open"
            property string fnUndo: "undo"
            property string fnPreviousPage: "previousPage"
            property string fnNextPage: "nextPage"
            property string fnZoomIn: "zoomIn"
            property string fnZoomReset: "zoomReset"
            property string fnZoomOut: "zoomOut"
            property string fnRotationLeft: "rotationLeft"
            property string fnRotationRight: "rotationRight"
            property string fnAddText: "addText"
            property string fnAddLine: "addLine"
            property string fnSwitchEncrypt: "switchEncrypt"
            property var hiddenActionIndex: []
            property alias fileTitleListView: _fileTitleListView
            property bool editStatus: false
            property bool iteractive: true
            signal exitEdit

            Keys.onEscapePressed: {
                _root.editStatus = false
                if(_pdfReaderContainer.count == 0){
                    return
                }
                _pdfReaderContainer.currentItem.editType = "NONE"
                if(!Array.isArray(_pdfReaderContainer.currentItem.editControl) && _pdfReaderContainer.currentItem.editControl !== null) { //非数组形式
                    _pdfReaderContainer.currentItem.editControl.destroy()
                }
                _pdfReaderContainer.currentItem.editControl = null
                emit: exitEdit()
            }

            FileDialog {
                id: _fileDialog
                title: "Please select your PDF document"
                folder: shortcuts.home
                nameFilters: ["PDFfile (*.pdf)"]
                selectMultiple: false
                onAccepted: {
                    _root.loadFiles(_fileDialog.fileUrls,true)
                }
            }

            Component.onCompleted: {
        //        print("#2")
        //        loadFiles(["file:///C:/Users/C24/Desktop/pdf/1.pdf"],false,true)
            }

            function loadFile(fileUrl,pathVisible,showRecords){
                var path,basename
                pathVisible = pathVisible || true
                path = global.urlPath(fileUrl)
                if(existOpenedPath(path)){
                    pdfUtil.setShowRecords(path,showRecords)
                    emit: updateImageNotify(path)
                    return
                }
                basename = global.urlBaseName(fileUrl)
                if(pathVisible){
                    _fileTitleListView.model.append({"basename":basename,"path": path })
                }else{
                    _fileTitleListView.model.append({"basename":basename,"path": "Preview the file, the path is not visible" })
                }
                _pdfReader.createObject(_pdfReaderContainer,{ path: path,showRecords: showRecords })
                _fileTitleListView.currentIndex = _fileTitleListView.count - 1
                _pdfReaderContainer.setCurrentIndex(_fileTitleListView.currentIndex)
            }

            function loadFiles(fileUrls,pathVisible,showRecords) {
                for(var i = 0; i < _fileTitleListView.model.count; i++){
                    _root.removeFileByIndex(i)
                }

                var url,path,basename
                pathVisible = pathVisible || true
                for(var i = 0;i < fileUrls.length; i++){
                    url = fileUrls[i]
                    path = global.urlPath(url)
                    if(existOpenedPath(path)){
                        pdfUtil.setShowRecords(path,showRecords)
                        emit: updateImageNotify(path)
                        continue
                    }
                    basename = global.urlBaseName(url)
                    if(pathVisible){
                        _fileTitleListView.model.append({"basename":basename,"path": path })
                    }else{
                        _fileTitleListView.model.append({"basename":basename,"path": "Preview the file, the path is not visible" })
                    }
                    _pdfReader.createObject(_pdfReaderContainer,{ path: path,showRecords: showRecords })
                }
                _fileTitleListView.currentIndex = _fileTitleListView.count - 1
                _pdfReaderContainer.setCurrentIndex(_fileTitleListView.currentIndex)
            }

            Connections {
                target: pdfUtil
                onEnterPasswordNotify: {
                    showTipLayer("VerifyPassword","Restriction of visit")
                }
                onChangeCountChanged: {
                    if(path === _pdfReaderContainer.currentItem.path){
                        if(count > 0){
                            _root.setToolbarEnableItems([_root.fnUndo])
                        }else{
                            _root.setToolbarDisableItems([_root.fnUndo])
                        }
                    }
                }
            }

            function showTipLayer(type,title){
                _pdfReaderContainer.currentItem.tipLayer.visible = true
                _pdfReaderContainer.currentItem.tipLayer.tipType = type
                _pdfReaderContainer.currentItem.tipLayer.tipTitle = title
            }

            function existOpenedPath(path){
                for(var i = 0;i < _fileTitleListView.model.count; i++){
                    if(_fileTitleListView.model.get(i)["path"] === path){
                        return true
                    }
                }
                return false
            }

            function open() {
                _fileDialog.open()
            }

            function close() {
                removeFileByIndex(_fileTitleListView.currentIndex)
            }

            function save() {
                if(_pdfReaderContainer.count == 0){
                    return
                }
                console.log("PATH:", _pdfReaderContainer.currentItem.path)
                pdfUtil.saveChange(_pdfReaderContainer.currentItem.path)
            }

            function currentPdfView() {
                return _pdfReaderContainer.currentItem["listView"]
            }

            function previousPage() {
                if(_pdfReaderContainer.count == 0){
                    return
                }
                currentPdfView()["currentIndex"]--
            }

            function nextPage() {
                if(_pdfReaderContainer.count == 0){
                    return
                }

                currentPdfView()["currentIndex"]++
            }

            function zoomIn() {
                if(_pdfReaderContainer.count == 0){
                    return
                }
                _pdfReaderContainer.currentItem.zoomRatio += 0.1
                pdfUtil.setZoomRatio(_pdfReaderContainer.currentItem.path,_pdfReaderContainer.currentItem.zoomRatio)
                updateImageNotify(_pdfReaderContainer.currentItem.path)
            }

            function zoomReset() {
                if(_pdfReaderContainer.count == 0){
                    return
                }
                _pdfReaderContainer.currentItem.zoomRatio = 1
                pdfUtil.setZoomRatio(_pdfReaderContainer.currentItem.path,_pdfReaderContainer.currentItem.zoomRatio)
                updateImageNotify(_pdfReaderContainer.currentItem.path)
            }

            function zoomOut() {
                if(_pdfReaderContainer.count == 0){
                    return
                }
                _pdfReaderContainer.currentItem.zoomRatio -= 0.1
                pdfUtil.setZoomRatio(_pdfReaderContainer.currentItem.path,_pdfReaderContainer.currentItem.zoomRatio)
                updateImageNotify(_pdfReaderContainer.currentItem.path)
            }

            function rotationLeft() {
                if(_pdfReaderContainer.count == 0){
                    return
                }
                pdfUtil.rotation(_pdfReaderContainer.currentItem.path,false)
                updateImageNotify(_pdfReaderContainer.currentItem.path)
            }

            function rotationRight() {
                if(_pdfReaderContainer.count == 0){
                    return
                }
                pdfUtil.rotation(_pdfReaderContainer.currentItem.path,true)
                updateImageNotify(_pdfReaderContainer.currentItem.path)
            }

            function undo() {
                if(_pdfReaderContainer.count == 0){
                    return
                }
                pdfUtil.undo(_pdfReaderContainer.currentItem.path)
            }

            function addText() {
                if(_pdfReaderContainer.count == 0){
                    return
                }
                if(_pdfReaderContainer.currentItem.editType === "TEXT"){
                    _root.editStatus = false
                    _root.iteractive = true
                    _pdfReaderContainer.currentItem.editType = "NONE"
                    if(!Array.isArray(_pdfReaderContainer.currentItem.editControl) && _pdfReaderContainer.currentItem.editControl !== null){
                        _pdfReaderContainer.currentItem.editControl.destroy()
                    }
                    _pdfReaderContainer.currentItem.editControl = null
                } else {
                    _root.editStatus = true
                    _root.iteractive = true
                    _pdfReaderContainer.currentItem.editType = "TEXT"
                    if(_pdfReaderContainer.currentItem.editControl !== null){
                        _pdfReaderContainer.currentItem.editControl = null
                    }
                }
            }

            function addImage() {
                if(_pdfReaderContainer.count == 0){
                    return
                }
                if(_pdfReaderContainer.currentItem.editType === "IMAGE"){
                    _root.editStatus = false
                    _pdfReaderContainer.currentItem.editType = "NONE"
                    _pdfReaderContainer.currentItem.editControl = null
                } else {
                    _root.editStatus = true
                    _pdfReaderContainer.currentItem.editType = "IMAGE"
                    if(!_pdfReaderContainer.currentItem.editControl){
                        _pdfReaderContainer.currentItem.editControl = null
                    }
                }
            }

            function addLine() {
                if(_pdfReaderContainer.count == 0){
                    return
                }
                if(_pdfReaderContainer.currentItem.editType === "LINE"){
                    _root.editStatus = false
                    _root.iteractive = true
                    _pdfReaderContainer.currentItem.editType = "NONE"
                    _pdfReaderContainer.currentItem.editControl = null
                } else {
                    _root.editStatus = true
                    _root.iteractive = true
                    _pdfReaderContainer.currentItem.editType = "LINE"
                    if(!_pdfReaderContainer.currentItem.editControl){
                        _pdfReaderContainer.currentItem.editControl = null
                    }
                }
                //pdfUtil.addLine(_pdfReaderContainer.currentItem.path,_pdfReaderContainer.currentItem.editPageIndex,Qt.point(50,50),Qt.point(200,200))
            }

            function selectText() {
                if(_pdfReaderContainer.count == 0){
                    return
                }
                if(_pdfReaderContainer.currentItem.editType === "SELECT"){
                    _root.iteractive = true
                    _pdfReaderContainer.currentItem.editType = "NONE"
                    _pdfReaderContainer.currentItem.editControl = null
                } else {
                    _root.iteractive = false
                    _pdfReaderContainer.currentItem.editType = "SELECT"
                    if(!_pdfReaderContainer.currentItem.editControl){
                        _pdfReaderContainer.currentItem.editControl = null
                    }
                }
            }

            function drawPencil() {
                if(_pdfReaderContainer.count == 0){
                    return
                }
                if(_pdfReaderContainer.currentItem.editType === "PENCIL"){
                    _root.iteractive = true
                    _pdfReaderContainer.currentItem.editType = "NONE"
                    _pdfReaderContainer.currentItem.editControl = null
                } else {
                    _root.iteractive = false
                    _pdfReaderContainer.currentItem.editType = "PENCIL"
                    if(!_pdfReaderContainer.currentItem.editControl){
                        _pdfReaderContainer.currentItem.editControl = null
                    }
                }
            }

            function switchEncrypt() {
                if(_pdfReaderContainer.count == 0){
                    return
                }
                var havePassword = pdfUtil.havePassword(_pdfReaderContainer.currentItem.path)
                if(_pdfReaderContainer.currentItem.tipLayer.tipType === "None"){
                    if(!havePassword){
                        showTipLayer("NewPassword","New password")
                    }else{
                        pdfUtil.cancelPassword(_pdfReaderContainer.currentItem.path)
                        updateEncryptState()
                    }
                } else if(_pdfReaderContainer.currentItem.tipLayer.tipType === "NewPassword"){
                    _pdfReaderContainer.currentItem.tipLayer.visible = false
                    _pdfReaderContainer.currentItem.tipLayer.tipType = "None"
                }
            }

            function removeFileByIndex(index){
                pdfUtil.deleteFile(_fileTitleListView.currentItem.path)
                _fileTitleListView.model.remove(index)
                var item = _pdfReaderContainer.itemAt(index)
                _pdfReaderContainer.removeItem(index)
                if(_fileTitleListView.count > 0) {
                    if(index === 0){
                        _fileTitleListView.currentIndex = 0
                    }else{
                        _fileTitleListView.currentIndex = index - 1
                    }
                    _pdfReaderContainer.currentIndex = _fileTitleListView.currentIndex
                    //            _pdfReaderContainer.setCurrentIndex(_fileTitleListView.currentIndex)
                } else {
                    _fileTitleListView.currentIndex = -1
                    setToolbarDisableExceptItems([0])
                }
                item.destroy()
        //        print(_fileTitleListView.currentIndex,_pdfReaderContainer.count)
            }

            function updateEncryptState() {
                if(_pdfReaderContainer.count == 0){
                    return
                }
                var havePassword = pdfUtil.havePassword(_pdfReaderContainer.currentItem.path)
                for(var i = 0;i < _toolRepeater.model.count; i++) {
                    if(_toolRepeater.model.get(i)["fn"] === "switchEncrypt"){
                        if(havePassword ){
                            if(_pdfReaderContainer.currentItem.tipLayer.tipType === "VerifyPassword"){
                                _toolRepeater.model.get(i)["tip"] = "Encrypted, please verify the password"
                            }else if(_pdfReaderContainer.currentItem.tipLayer.tipType === "NewPassword"){
                                _toolRepeater.model.get(i)["tip"] = "Exit password setting"
                            }else {
                                _toolRepeater.model.get(i)["tip"] = "Encrypted, click to cancel encryption"
                            }
                        } else {
                            _toolRepeater.model.get(i)["tip"] = "Not encrypted, click to encrypt"
                        }
                        break;
                    }
                }
            }

            //Set multiple items on the toolbar to enable, compare attributes to fn, and other unchanged
            function setToolbarEnableItems(enableItems){
                for(var i = 0;i < _toolRepeater.model.count; i++){
                    for(var j = 0;j < enableItems.length; j++){
                        if(_toolRepeater.model.get(i)["fn"] === enableItems[j]){
                            _toolRepeater.model.get(i)["disable"] = false
                            break
                        }
                    }
                }
            }

            //Set multiple items on the toolbar to disable, the comparison attribute to fn, and others unchanged
            function setToolbarDisableItems(disableItems){
                for(var i = 0;i < _toolRepeater.model.count; i++){
                    for(var j = 0;j < disableItems.length; j++){
                        if(_toolRepeater.model.get(i)["fn"] === disableItems[j]){
                            _toolRepeater.model.get(i)["disable"] = true
                            break
                        }
                    }
                }
            }

            //Set the toolbar to disable except for exceptItems enable
            function setToolbarEnableExceptItems(exceptItems) {
                for(var i = 0;i < _toolRepeater.model.count; i++){
                    var exist = false
                    for(var j = 0;j < exceptItems.length; j++){
                        if(_toolRepeater.model.get(i)["fn"] === exceptItems[j]){
                            exist = true
                            break
                        }
                    }
                    _toolRepeater.model.get(i)["disable"] = exist
                }
                _toolRepeater.model.get(0)["disable"] = false
            }

            function setToolbarDisableExceptItems(exceptItems) {
                for(var i = 0;i < _toolRepeater.model.count; i++){
                    var exist = true
                    for(var j = 0;j < exceptItems.length; j++){
                        if(_toolRepeater.model.get(i)["fn"] === exceptItems[j]){
                            exist = false
                            break
                        }
                    }
                    _toolRepeater.model.get(i)["disable"] = exist
                }
                _toolRepeater.model.get(0)["disable"] = false
            }

            Rectangle {
                id: _toolbar
                height: rh(30)
                width: parent.width
                Row {
                    Repeater {
                        id: _toolRepeater
                        model: ListModel {
                            ListElement {
                                icon: "qrc:/images/open.ico"
                                fn: "open"
                                tip: "Open new document"
                                disable: false
                            }
                            //                    ListElement {
                            //                        icon: "qrc:/images/close.ico"
                            //                        fn: "close"
                            //                        tip: "关闭当前文档"
                            //                    }
                            ListElement {
                                icon: "qrc:/images/save.png"
                                fn: "save"
                                tip: "Save the document"
                                disable: true
                            }
                            ListElement {
                                icon: "qrc:/images/undo.png"
                                fn: "undo"
                                tip: "Revoke"
                                disable: true
                            }

                            ListElement {
                                icon: "qrc:/images/previouspage.ico"
                                fn: "previousPage"
                                tip: "Previous page"
                                disable: true
                            }
                            ListElement {
                                icon: "qrc:/images/nextpage.ico"
                                fn: "nextPage"
                                tip: "Next page"
                                disable: true
                            }
                            ListElement {
                                icon: "qrc:/images/rotationleft.png"
                                fn: "rotationLeft"
                                tip: "Rotate the view counterclockwise\nNote: This function is for viewing the page and does not modify the document"
                                disable: true
                            }
                            ListElement {
                                icon: "qrc:/images/rotationright.png"
                                fn: "rotationRight"
                                tip: "Rotate the view clockwise\nNote: This function is for viewing the page and does not modify the document"
                                disable: true
                            }
                            ListElement {
                                icon: "qrc:/images/zoom_in.ico"
                                fn: "zoomIn"
                                tip: "ZoomIn"
                                disable: true
                            }
                            ListElement {
                                icon: "qrc:/images/zoom_reset.ico"
                                fn: "zoomReset"
                                tip: "zoomReset"
                                disable: true
                            }
                            ListElement {
                                icon: "qrc:/images/zoom_out.ico"
                                fn: "zoomOut"
                                tip: "zoomOut"
                                disable: true
                            }
                            ListElement {
                                icon: "qrc:/images/text.png"
                                fn: "addText"
                                tip: "AddText"
                                disable: true
                            }
                            //                    ListElement {
                            //                        icon: "qrc:/images/image.png"
                            //                        fn: "addimage"
                            //                        tip: "添加图片"
                            //                    }
                            ListElement {
                                icon: "qrc:/images/line.png"
                                fn: "addLine"
                                tip: "Add Line"
                                disable: true
                            }
                            ListElement {
                                icon: "qrc:/images/cursor-mouse.png"
                                fn: "selectText"
                                tip: "Select Text"
                                disable: true
                            }
                            ListElement {
                                icon: "qrc:/images/pencil.png"
                                fn: "drawPencil"
                                tip: "Hand Writting"
                                disable: true
                            }
        //                    ListElement {
        //                        icon: "qrc:/images/docencrypt.png"
        //                        fn: "switchEncrypt"
        //                        tip: "切换加密状态" // 加密状态 <-> 公开状态
        //                        disable: true
        //                    }
                        }
                        delegate: Button {
                            id: _buttonDelegate
                            width: _toolbar.height * 6 / 5
                            height: _toolbar.height
                            enabled: !disable
                            function hidden(){
                                for(var i = 0;i < _root.hiddenActionIndex.length; i++){
                                    if(_root.hiddenActionIndex[i] === index){
                                        return true
                                    }
                                }
                                return false
                            }
                            visible: !hidden()

                            background: Item {
                                id: _iconContainer
                                anchors.fill: parent
                                enabled: disable
                                property var colorObj: null
                                property var disableFlag: disable
                                onDisableFlagChanged: {
                                    if(disable) {
                                        colorObj = _colorOverlay.createObject(_iconContainer,{"anchors.fill":_iconImage,"source":_iconImage})
                                        _iconImage.visible = false
                                    }else{
                                        if(colorObj !== null){
                                            colorObj.destroy()
                                            colorObj = null
                                        }
                                        _iconImage.visible = true
                                    }
                                }

                                onEnabledChanged: {

                                }
                                Image {
                                    id: _iconImage
                                    anchors.centerIn: parent
                                    sourceSize: Qt.size(parent.width * 0.7,parent.height * 0.7)
                                    source: icon
                                    smooth: true
                                }
                                Component {
                                    id: _colorOverlay
                                    ColorOverlay {
                                        enabled: index == 0 || _fileTitleListView.model.count > 0
                                        color: "#909090"
                                    }
                                }
                            }
                            ToolTip.text: tip
                            ToolTip.visible: hovered
                            onClicked: {
                                _root[fn]()
                            }
                        }
                    }
                }
            }

            Rectangle {
                id: _fileTitleBottomLayer
                anchors.top: _toolbar.bottom
                width: parent.width
                height: (_fileTitleListView.count == 0 || !_fileTitleListView.visible) ? 0 : rh(26)
            }

            ListView {
                id: _fileTitleListView
                anchors {
                    top: _toolbar.bottom
                }
                onCountChanged: {
                    if(count > 0) {
                        _root.setToolbarEnableExceptItems([_root.fnUndo])
                    }else{
                        _root.setToolbarEnableExceptItems([_root.fnUndo])
                    }
                }

                width: parent.width
                height: count == 0 ? 0 : rh(26)
                model: ListModel {
                }
                orientation: ListView.Horizontal
                delegate: Rectangle {
                    width: rw(120)
                    height: rh(26)
                    clip: true
                    color: index == _fileTitleListView.currentIndex ? "#B0BEC5" : "white"
                    MouseArea {
                        id: _mouseArea
                        hoverEnabled: true
                        anchors.fill: parent
                        onClicked: {
                            _fileTitleListView.currentIndex = index
                            _pdfReaderContainer.setCurrentIndex(index)
                        }
                    }

                    Rectangle {
                        id: _tagRect
                        width: rw(3)
                        height: parent.height
                        color: index == _fileTitleListView.currentIndex ? "#009688" : "#EEEEEE"
                    }

                    Text {
                        anchors {
                            left: parent.left
                            leftMargin: rw(6)
                            verticalCenter: parent.verticalCenter
                            right: parent.right
                            rightMargin: rw(20)
                        }
                        text: basename
                    }
                    Button {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: rw(20)
                        height: parent.height
                        background: Image {
                            source: "qrc:/images/close.png"
                            scale: 0.5
                        }
                        ToolTip.text: "Close"
                        ToolTip.visible: hovered
                        ToolTip.delay: 250
                        onClicked: {
                            _root.removeFileByIndex(index)
                        }
                    }
                    ToolTip.visible: _mouseArea.containsMouse
                    ToolTip.text: path
                    ToolTip.delay: 500
                }
            }

            SwipeView {
                id: _pdfReaderContainer
                anchors.fill: parent
                visible: true
                anchors.topMargin: _toolbar.height + _fileTitleBottomLayer.height
                onCurrentItemChanged: {
                    _updateDelayer.run(400)
                }
                Delayer {
                    id: _updateDelayer
                    callback: function() {
                        if(_pdfReaderContainer.count > 0){
                            _root.updateEncryptState()
                        }
                        if(_pdfReaderContainer.currentIndex != -1 && pdfUtil.existChangeItem(_pdfReaderContainer.currentItem.path)){
                            _root.setToolbarEnableItems([_root.fnUndo])
                        }else{
                            _root.setToolbarDisableItems([_root.fnUndo])
                        }
                    }
                }
            }

            Component {
                id: _colorComponent
                FocusScope {
                    focus: true
                    ColorDialog {
                        id: colorDialog
                        objectName: "NewTextField"
                        title: "Please choose a color"
                        currentColor: "#f4d30d"
                        onAccepted: {
                            pdfUtil.selectedText(_pdfReaderContainer.currentItem.path,_pdfReaderContainer.currentItem.editPageIndex,_pdfReaderContainer.currentItem.startPoint,_pdfReaderContainer.currentItem.endPoint,colorDialog.color)
                            _pdfReaderContainer.currentItem.editControl = null
                            timer.running = true
                        }
                        onRejected: {
                            pdfUtil.selectedText(_pdfReaderContainer.currentItem.path,_pdfReaderContainer.currentItem.editPageIndex,_pdfReaderContainer.currentItem.startPoint,_pdfReaderContainer.currentItem.endPoint,"#f4d30d")
                            _pdfReaderContainer.currentItem.editControl = null
                            timer.running = true
                        }
                        Component.onCompleted: visible = true
//                        onEditingFinished: {
//                            pdfUtil.addText(_pdfReaderContainer.currentItem.path,_pdfReaderContainer.currentItem.editPageIndex,_pdfReaderContainer.currentItem.editPosition,text)
//                            _pdfReaderContainer.currentItem.editControl.destroy()
//                            _pdfReaderContainer.currentItem.editControl = null
//                        }
                    }
                }
            }

            Component {
                id: _textComponent
                FocusScope {
                    focus: true
                    TextField {
                        id: _textField
                        objectName: "NewTextField"
                        width: rw(160)
                        height: rh(35)
                        selectByMouse: true
                        font.pixelSize: rfs(16)
                        focus: true
                        focusReason: Qt.OtherFocusReason
                        background: Rectangle {
                            radius: rw(3)
                            border.width: rw(1)
                            border.color: "black"
                        }
                        onEditingFinished: {
                            pdfUtil.addText(_pdfReaderContainer.currentItem.path,_pdfReaderContainer.currentItem.editPageIndex,_pdfReaderContainer.currentItem.editPosition,text)
                            _pdfReaderContainer.currentItem.editControl.destroy()
                            _pdfReaderContainer.currentItem.editControl = null
                        }
                    }
                }
            }


            Component {
                id: _pdfReader
                Rectangle {
                    id: _listViewContainer
                    color: "gray"
                    clip: true
                    property string path
                    property bool showRecords: true
                    property real zoomRatio: 1.0  //Zoom factor
                    property int maxPageWidth
                    property string editType: "NONE"  //NONE、TEXT、IMAGE、SELECT
                    property var editControl //Array form or control
                    property var colorPicker //Color Picker Component
                    property int editPageIndex
                    property point editPosition
                    property point startPoint
                    property point endPoint
                    property alias listView: _listView
                    property alias tipLayer: _tipLayer
                    property var points: []
                    Connections{
                        target: pdfUtil
                        onMaxPageWidthChangedNotify: {
                            //print("onMaxPageWidthChangedNotify" ,_listViewContainer.path, path,width , _root.width)
                            if(_listViewContainer.path == path){
                                _listViewContainer.maxPageWidth = width
                                if(width < _root.width){
                                    _horizontalBar.policy = ScrollBar.AlwaysOff
                                }else{
                                    _horizontalBar.policy = ScrollBar.AlwaysOn
                                }
                            }
                        }
                    }
                    ListView {
                        id: _listView
                        interactive: _root.iteractive
                        anchors.fill: parent
                        model: ListModel{}
                        spacing: rh(8)
                        clip: true
                        focus: true
                        Component.onCompleted: {
                            pdfUtil.addFile(_listViewContainer.path,_listViewContainer.showRecords)
                        }

                        Connections {
                            target: pdfUtil
                            onLoadFinishNotify: {
                                if(path == _listViewContainer.path){
                                    for(var i = 0;i < pageCount;i++){
                                        var url = "image://PdfScreenshot/"+path+"#"+i
                                        _listView.model.append({"imgUrl": url })
                                    }
                                }
                            }
                        }
                        delegate: Item {
                            id: _delegateRect
                            height: _image.sourceSize.height
                            focus: true

                            MouseArea {
                                anchors.fill: parent
                                onWheel: {
                                    if (wheel.modifiers & Qt.ControlModifier) {
                                        if( wheel.angleDelta.y > 0 ){
                                            zoomIn()
                                        }else{
                                            zoomOut()
                                        }
                                        wheel.accepted = true
                                        return
                                    }
                                    wheel.accepted = false
                                }

                                onClicked: {
                                    _listView.currentIndex = index
                                }
                            }
                            width: {
                                var zoomWidth = _image.sourceSize.width
                                if(zoomWidth < _root.width){
                                    _image.anchors.horizontalCenter = _delegateRect.horizontalCenter
                                    return _root.width
                                }else{
                                    _image.anchors.horizontalCenter = undefined
                                    return zoomWidth
                                }
                            }
                            //rotation: pageRotation
                            Image {
                                id: _image
                                source: imgUrl
                                height: _image.sourceSize.height
                                width: _image.sourceSize.width
                                x: -_horizontalBar.position * width
                                cache: false

                                //自绘层
                                Canvas {
                                    id: _canvas
                                    anchors.fill: parent
                                    antialiasing: true
                                    smooth: true
                                    property point tempPoint: Qt.point(-1,-1)
                                    property point startPoint: Qt.point(-1, -1)
                                    property bool isReleased: false
                                    visible: true
                                    onPaint: {
                                        if(_listViewContainer.editType == "LINE"){
                                            var ctx = getContext("2d")
                                            ctx.reset()
                                            ctx.lineWidth = 3
                                            ctx.strokeStyle = "#ff0000"
                                            if(Array.isArray(_listViewContainer.editControl) && tempPoint.x !== -1){
                                                if(_listViewContainer.editControl.length === 1){
                                                    var startPos = _listViewContainer.editControl[0]
                                                    ctx.moveTo(startPos.x,startPos.y)
                                                    //修正横线
                                                    if(Math.abs(startPos.x - tempPoint.x) <= 5){
                                                        tempPoint.x = startPos.x;
                                                    }
                                                    if(Math.abs(startPos.y - tempPoint.y) <= 5){
                                                        tempPoint.y = startPos.y
                                                    }
                                                    ctx.lineTo(tempPoint.x,tempPoint.y)
                                                    ctx.stroke()
                                                }
                                            }
                                            tempPoint.x = -1
                                        } else if(_listViewContainer.editType == "SELECT"){
                                            var ctx = getContext("2d")
                                            ctx.reset()
                                            if(startPoint.x == -2)
                                                return
                                            ctx.lineWidth = 2
                                            ctx.globalAlpha = 0.5
                                            ctx.fillStyle = "#3CBBF9"
                                            ctx.fillRect(startPoint.x, startPoint.y, tempPoint.x - startPoint.x, tempPoint.y - startPoint.y)
                                            tempPoint.x = -1
                                        } else if(_listViewContainer.editType == "PENCIL"){
                                            var ctx = getContext('2d')
                                            if(isReleased == true)
                                                ctx.reset()
                                            ctx.lineWidth = 3
                                            ctx.strokeStyle = "#3CBBF9"
                                            ctx.beginPath()
                                            ctx.moveTo(startPoint.x, startPoint.y)
                                            startPoint.x = tempPoint.x
                                            startPoint.y = tempPoint.y
                                            ctx.lineTo(startPoint.x, startPoint.y)
                                            ctx.stroke()
                                        }
                                        else {
                                            ctx = getContext("2d")
                                            ctx.clearRect(0,0,width,height)

                                        }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: false
                                    enabled: _listViewContainer.editType != "NONE"
                                    cursorShape: _listViewContainer.editType != "NONE" ? Qt.IBeamCursor : Qt.OpenHandCursor
                                    onPressed: {
                                        _canvas.startPoint = Qt.point(mouseX,mouseY)
                                        _listViewContainer.startPoint = Qt.point(mouseX,mouseY)
                                        _canvas.isReleased = false
                                    }
                                    onClicked: {
                                        _listViewContainer.editPageIndex = index
                                        if(!_listViewContainer.editControl && _listViewContainer.editType == "TEXT"){
                                            _listViewContainer.editControl = _textComponent.createObject(_image)
                                            Qt.callLater(function(){
                                                _listViewContainer.editControl.focus = true
                                            })
                                            _listViewContainer.editPosition = Qt.point(mouseX,mouseY)
                                            if(_listViewContainer.editControl){
                                                _listViewContainer.editControl.x = mouseX
                                                _listViewContainer.editControl.y = mouseY
                                            }
                                        }else if(_listViewContainer.editType == "IMAGE"){
                                            // pdfUtil.addImage(_listViewContainer.path,index,Qt.point(mouseX,mouseY))
                                        } else if(_listViewContainer.editType == "LINE") {
                                            if(!Array.isArray(_listViewContainer.editControl) || _listViewContainer.editControl.length === 2) {
                                                _listViewContainer.editControl = [Qt.point(mouseX,mouseY)]
                                                hoverEnabled = true   //起始点启用
                                            }else if(_listViewContainer.editControl.length === 1){
                                                _listViewContainer.editControl.push(Qt.point(mouseX,mouseY))
                                                pdfUtil.addLine(_listViewContainer.path,index,_listViewContainer.editControl[0],Qt.point(mouseX,mouseY))
                                                hoverEnabled = false  //已经获得第二个点，不需要了
                                            }
                                            _canvas.requestPaint()
                                        }
                                    }
                                    onPositionChanged: {
                                        if(_listViewContainer.editType == "LINE" || _listViewContainer.editType == "SELECT" || _listViewContainer.editType == "PENCIL") {
                                            _canvas.tempPoint = Qt.point(mouseX,mouseY)
                                            _listViewContainer.points.push(Qt.point(mouseX,mouseY))
                                            _canvas.requestPaint()
                                        }
                                    }
                                    onReleased: {
                                        if(_listViewContainer.editType == "SELECT") {
                                            //pdfUtil.selectedText(_listViewContainer.path,index,_canvas.startPoint,Qt.point(mouseX,mouseY))
                                            _canvas.startPoint.x = -2
                                            //_canvas.requestPaint()
                                            if(_listViewContainer.editControl == null){
                                                _listViewContainer.editControl = _colorComponent.createObject(_image)
                                                _listViewContainer.endPoint = Qt.point(mouseX,mouseY)
                                                if(_listViewContainer.editControl){
                                                    _listViewContainer.editControl.x = mouseX
                                                    _listViewContainer.editControl.y = mouseY
                                                    if( _listViewContainer.editControl.visible == false)
                                                        _listViewContainer.editControl.visible = true
                                                }
                                            }
                                            //timer.running = true;
                                        }
                                        else if(_listViewContainer.editType == "PENCIL") {
                                            //pdfUtil.selectedText(_listViewContainer.path,index,_canvas.startPoint,Qt.point(mouseX,mouseY))
                                             _canvas.isReleased = true
                                            _canvas.requestPaint()
                                            if(_listViewContainer.points.length > 1){
                                                console.log(_listViewContainer.points)
                                                pdfUtil.addPencil(_listViewContainer.path,index,_listViewContainer.startPoint,_listViewContainer.points)
                                                _listViewContainer.points = []
                                            }

                                            //timer.running = true;
                                        }
                                    }
                                }
                            }

                            function updateImage() { //requestImage
                                var tmp = imgUrl
                                imgUrl = ""
                                imgUrl = tmp
                            }

                            Connections {
                                target: _root
                                onUpdateImageNotify: {
                                    if(path === _listViewContainer.path) {
                                        _delegateRect.updateImage()
                                    }
                                }
                                onExitEdit: {
                                    _listViewContainer.editType = "NONE"
                                    _listViewContainer.editControl = null
                                    _canvas.requestPaint()
                                }
                            }

                            Connections {
                                target: pdfUtil
                                onUpdatePage: {
                                    if(path === _listViewContainer.path && pageNum === index){
                                        _delegateRect.updateImage()
                                    }
                                }
                            }
                        }

                        ScrollBar.vertical: ScrollBar {
                            id: bar
                            policy: ScrollBar.AlwaysOn
                            contentItem: Rectangle {
                                        id: thisWillBeAutomaticallyResizedNoMatterWhatYouDo
                                        implicitWidth: 6
                                        radius: width / 2
                                        color: 'blue'

//                                        Rectangle {
//                                            id: thisWillChangeTheSizeWithTheIndicator
//                                            color: 'yellow'
//                                            opacity: 0.7
//                                            width: 10
//                                            height: 40
//                                            radius: 5
//                                            anchors.centerIn: parent
//                                        }

                                        Rectangle {
                                            id: thisCouldBeYourImage
                                            width: 10
                                            height: 30
                                            radius: 5
                                            anchors.centerIn: parent
                                            color: 'black'
                                        }
                                    }
                        }

                        ScrollBar {
                            id: _horizontalBar
                            hoverEnabled: true
                            active: hovered || pressed
                            orientation: Qt.Horizontal
                            size: _root.width / maxPageWidth
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                        }
                    }

                    Rectangle {
                        id: _tipLayer
                        color: "#eee"
                        anchors.fill: parent
                        visible: false
                        property string tipType: "None"  // None / VerifyPassword / NewPassword
                        property alias tipTitle: _tipTitle.text
                        Image {
                            id: _limitAccessImage
                            anchors.centerIn: parent
                            anchors.verticalCenterOffset: -rh(50)
                            width: rw(128)
                            height: rh(128)
                            source: "qrc:/images/limitaccess.png"
                        }

                        Text {
                            id: _tipTitle
                            anchors.top: _limitAccessImage.bottom
                            anchors.topMargin: rh(15)
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Restriction of visit"
                            color: "#707070"
                            font.pixelSize: rfs(30)
                        }

                        Delayer {
                            id: _delayer
                        }

                        TextField {
                            id: _passwordInput
                            anchors {
                                top: _tipTitle.bottom
                                topMargin: rh(15)
                                horizontalCenter: parent.horizontalCenter
                            }
                            placeholderText: "Please enter your password"
                            selectByMouse: true

                            background: Rectangle {
                                id: _passwordBg
                                implicitWidth: 160
                                implicitHeight: 30
                                color: "transparent"
                                border.color: _passwordInput.enabled ? "#707070" : "transparent"
                                radius: rw(4)
                            }

                            Keys.onReturnPressed: {
                                if(_tipLayer.tipType == "VerifyPassword"){
                                    if(pdfUtil.matchPassword(_listViewContainer.path,text)) {
                                        _tipTitle.text = "Match successfully"
                                        _delayer.callback = function() {
                                            _tipLayer.visible = false
                                            _tipLayer.tipType = "None"
                                            updateEncryptState()
                                        }
                                        _delayer.run(1500)
                                    }else{
                                        _passwordBg.border.color = "red"
                                    }
                                }else if(_tipLayer.tipType == "NewPassword"){
                                    if(pdfUtil.setPassword(_listViewContainer.path,text)) {
                                        _tipTitle.text = "Set successfully"
                                        _delayer.callback = function() {
                                            _tipLayer.visible = false
                                            _tipLayer.tipType = "None"
                                            updateEncryptState()
                                        }
                                        _delayer.run(1500)
                                    }else{
                                        _tipTitle.text = "Setup failed"
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

    Rectangle {
            id: _root1
            width: parent.width/2 - 5
            height: parent.height
            anchors.right: parent.right
            anchors.top: parent.top
            color: "gray"
            //property string fileName: "C:/Users/C24/Desktop/1.pdf"
            signal updateImageNotify(string path)
            clip: true
            property string fnOpen: "open"
            property string fnUndo: "undo"
            property string fnPreviousPage: "previousPage"
            property string fnNextPage: "nextPage"
            property string fnZoomIn: "zoomIn"
            property string fnZoomReset: "zoomReset"
            property string fnZoomOut: "zoomOut"
            property string fnRotationLeft: "rotationLeft"
            property string fnRotationRight: "rotationRight"
            property string fnAddText: "addText"
            property string fnAddLine: "addLine"
            property string fnSwitchEncrypt: "switchEncrypt"
            property var hiddenActionIndex: []
            property alias fileTitleListView: _fileTitleListView1
            property bool editStatus: false
            property bool iteractive: true
            signal exitEdit
            Timer {
                    id: timer
                    interval: 500; running: false; repeat: false
                    onTriggered: {
                        if(_pdfReaderContainer1.count == 0){
                            return
                        }
                        _root1.updateImageNotify(_pdfReaderContainer1.currentItem.path)
                    }
                }
            Keys.onEscapePressed: {
                editStatus = false
                if(_pdfReaderContainer1.count == 0){
                    return
                }
                _pdfReaderContainer1.currentItem.editType = "NONE"
                if(!Array.isArray(_pdfReaderContainer1.currentItem.editControl) && _pdfReaderContainer1.currentItem.editControl !== null) { //非数组形式
                    _pdfReaderContainer1.currentItem.editControl.destroy()
                }
                _pdfReaderContainer1.currentItem.editControl = null
                emit: exitEdit()
            }

            FileDialog {
                id: _fileDialog1
                title: "Please select your PDF document"
                folder: shortcuts.home
                nameFilters: ["PDFfile (*.pdf)"]
                selectMultiple: true
                onAccepted: {
                    _root1.loadFiles(_fileDialog1.fileUrls,true)
                }
            }

            Component.onCompleted: {
        //        print("#2")
        //        loadFiles(["file:///C:/Users/C24/Desktop/pdf/1.pdf"],false,true)
            }

            function loadFile(fileUrl,pathVisible,showRecords){
                var path,basename
                pathVisible = pathVisible || true
                path = global.urlPath(fileUrl)
                if(existOpenedPath(path)){
                    pdfUtil1.setShowRecords(path,showRecords)
                    emit: _root1.updateImageNotify(path)
                    return
                }
                basename = global.urlBaseName(fileUrl)
                if(pathVisible){
                    _root1._fileTitleListView1.model.append({"basename":basename,"path": path })
                }else{
                    _root1._fileTitleListView1.model.append({"basename":basename,"path": "Preview the file, the path is not visible" })
                }
               _root1. _pdfReader1.createObject(_root1._pdfReaderContainer1,{ path: path,showRecords: showRecords })
                _root1._fileTitleListView1.currentIndex = _fileTitleListView1.count - 1
                _root1._pdfReaderContainer1.setCurrentIndex(_fileTitleListView1.currentIndex)
            }

            function loadFiles(fileUrls,pathVisible,showRecords) {
                for(var i = 0; i < _fileTitleListView1.model.count; i++){
                    _root1.removeFileByIndex(i)
                }
                var url,path,basename
                pathVisible = pathVisible || true
                for(var i = 0;i < fileUrls.length; i++){
                    url = fileUrls[i]
                    path = global.urlPath(url)
                    if(existOpenedPath(path)){
                        pdfUtil1.setShowRecords(path,showRecords)
                        emit: _root1.updateImageNotify(path)
                        continue
                    }
                    basename = global.urlBaseName(url)
                    if(pathVisible){
                        _fileTitleListView1.model.append({"basename":basename,"path": path })
                    }else{
                        _fileTitleListView1.model.append({"basename":basename,"path": "Preview the file, the path is not visible" })
                    }
                    _pdfReader1.createObject(_pdfReaderContainer1,{ path: path,showRecords: showRecords })
                }
                _fileTitleListView1.currentIndex = _fileTitleListView1.count - 1
                _pdfReaderContainer1.setCurrentIndex(_fileTitleListView1.currentIndex)
            }

            Connections {
                target: pdfUtil1
                onEnterPasswordNotify: {
                    showTipLayer("VerifyPassword","Restriction of visit")
                }
                onChangeCountChanged: {
                    if(path === _pdfReaderContainer1.currentItem.path){
                        if(count > 0){
                            _root1.setToolbarEnableItems([_root1.fnUndo])
                        }else{
                            _root1.setToolbarDisableItems([_root1.fnUndo])
                        }
                    }
                }
            }

            function showTipLayer(type,title){
                _root1._pdfReaderContainer1.currentItem.tipLayer.visible = true
                _root1._pdfReaderContainer1.currentItem.tipLayer.tipType = type
                _root1._pdfReaderContainer1.currentItem.tipLayer.tipTitle = title
            }

            function existOpenedPath(path){
                for(var i = 0;i < _fileTitleListView1.model.count; i++){
                    if(_fileTitleListView1.model.get(i)["path"] === path){
                        return true
                    }
                }
                return false
            }

            function open() {
                _fileDialog1.open()
            }

            function close() {
                _root1.removeFileByIndex(_fileTitleListView1.currentIndex)
            }

            function save() {
                if(_pdfReaderContainer1.count == 0){
                    return
                }
                console.log("PATH:", _pdfReaderContainer1.currentItem.path)
                pdfUtil1.saveChange(_pdfReaderContainer1.currentItem.path)
            }

            function currentPdfView() {
                return _pdfReaderContainer1.currentItem["listView"]
            }

            function previousPage() {
                if(_pdfReaderContainer1.count == 0){
                    return
                }
                _root1.currentPdfView()["currentIndex"]--
            }

            function nextPage() {
                if(_pdfReaderContainer1.count == 0){
                    return
                }

                _root1.currentPdfView()["currentIndex"]++
            }

            function zoomIn() {
                if(_pdfReaderContainer1.count == 0){
                    return
                }
                _pdfReaderContainer1.currentItem.zoomRatio += 0.1
                pdfUtil1.setZoomRatio(_pdfReaderContainer1.currentItem.path,_pdfReaderContainer1.currentItem.zoomRatio)
                _root1.updateImageNotify(_pdfReaderContainer1.currentItem.path)
            }

            function zoomReset() {
                if(_pdfReaderContainer1.count == 0){
                    return
                }
                _pdfReaderContainer1.currentItem.zoomRatio = 1
                pdfUtil1.setZoomRatio(_pdfReaderContainer1.currentItem.path,_pdfReaderContainer1.currentItem.zoomRatio)
                _root1.updateImageNotify(_pdfReaderContainer1.currentItem.path)
            }

            function zoomOut() {
                if(_pdfReaderContainer1.count == 0){
                    return
                }
                _pdfReaderContainer1.currentItem.zoomRatio -= 0.1
                pdfUtil1.setZoomRatio(_pdfReaderContainer1.currentItem.path,_pdfReaderContainer1.currentItem.zoomRatio)
                _root1.updateImageNotify(_pdfReaderContainer1.currentItem.path)
            }

            function rotationLeft() {
                if(_pdfReaderContainer1.count == 0){
                    return
                }
                pdfUtil1.rotation(_pdfReaderContainer1.currentItem.path,false)
                _root1.updateImageNotify(_pdfReaderContainer1.currentItem.path)
            }

            function rotationRight() {
                if(_pdfReaderContainer1.count == 0){
                    return
                }
                pdfUtil1.rotation(_pdfReaderContainer1.currentItem.path,true)
                _root1.updateImageNotify(_pdfReaderContainer1.currentItem.path)
            }

            function undo() {
                if(_pdfReaderContainer1.count == 0){
                    return
                }
                pdfUtil1.undo(_pdfReaderContainer1.currentItem.path)
            }

            function addText() {
                if(_pdfReaderContainer1.count == 0){
                    return
                }
                if(_pdfReaderContainer1.currentItem.editType === "TEXT"){
                    editStatus = false
                    iteractive = true
                    _pdfReaderContainer1.currentItem.editType = "NONE"
                    if(!Array.isArray(_pdfReaderContainer1.currentItem.editControl) && _pdfReaderContainer1.currentItem.editControl !== null){
                        _pdfReaderContainer1.currentItem.editControl.destroy()
                    }
                    _pdfReaderContainer1.currentItem.editControl = null
                } else {
                    editStatus = true
                    iteractive = true
                    _pdfReaderContainer1.currentItem.editType = "TEXT"
                    if(_pdfReaderContainer1.currentItem.editControl !== null){
                        _pdfReaderContainer1.currentItem.editControl = null
                    }
                }
            }

            function addImage() {
                if(_pdfReaderContainer1.count == 0){
                    return
                }
                if(_pdfReaderContainer1.currentItem.editType === "IMAGE"){
                    editStatus = false
                    _pdfReaderContainer1.currentItem.editType = "NONE"
                    _pdfReaderContainer1.currentItem.editControl = null
                } else {
                    editStatus = true
                    _pdfReaderContainer1.currentItem.editType = "IMAGE"
                    if(!_pdfReaderContainer1.currentItem.editControl){
                        _pdfReaderContainer1.currentItem.editControl = null
                    }
                }
            }

            function addLine() {
                if(_pdfReaderContainer1.count == 0){
                    return
                }
                if(_pdfReaderContainer1.currentItem.editType === "LINE"){
                   _root1.editStatus = false
                    _root1.iteractive = true
                    _pdfReaderContainer1.currentItem.editType = "NONE"
                    _pdfReaderContainer1.currentItem.editControl = null
                } else {
                    _root1.editStatus = true
                    _root1.iteractive = true
                    _pdfReaderContainer1.currentItem.editType = "LINE"
                    if(!_pdfReaderContainer1.currentItem.editControl){
                        _pdfReaderContainer1.currentItem.editControl = null
                    }
                }
                //pdfUtil1.addLine(_pdfReaderContainer1.currentItem.path,_pdfReaderContainer1.currentItem.editPageIndex,Qt.point(50,50),Qt.point(200,200))
            }

            function selectText() {
                if(_pdfReaderContainer1.count == 0){
                    return
                }
                if(_pdfReaderContainer1.currentItem.editType === "SELECT"){
                    _root1.iteractive = true
                    _pdfReaderContainer1.currentItem.editType = "NONE"
                    _pdfReaderContainer1.currentItem.editControl = null
                } else {
                    _root1.iteractive = false
                    _pdfReaderContainer1.currentItem.editType = "SELECT"
                    if(!_pdfReaderContainer1.currentItem.editControl){
                        _pdfReaderContainer1.currentItem.editControl = null
                    }
                }
            }

            function switchEncrypt() {
                if(_pdfReaderContainer1.count == 0){
                    return
                }
                var havePassword = pdfUtil1.havePassword(_pdfReaderContainer1.currentItem.path)
                if(_pdfReaderContainer1.currentItem.tipLayer.tipType === "None"){
                    if(!havePassword){
                        showTipLayer("NewPassword","New password")
                    }else{
                        pdfUtil1.cancelPassword(_pdfReaderContainer1.currentItem.path)
                        updateEncryptState()
                    }
                } else if(_pdfReaderContainer1.currentItem.tipLayer.tipType === "NewPassword"){
                    _pdfReaderContainer1.currentItem.tipLayer.visible = false
                    _pdfReaderContainer1.currentItem.tipLayer.tipType = "None"
                }
            }

            function removeFileByIndex(index){
                pdfUtil1.deleteFile(_fileTitleListView1.currentItem.path)
                _fileTitleListView1.model.remove(index)
                var item = _pdfReaderContainer1.itemAt(index)
                _pdfReaderContainer1.removeItem(index)
                if(_fileTitleListView1.count > 0) {
                    if(index === 0){
                        _fileTitleListView1.currentIndex = 0
                    }else{
                        _fileTitleListView1.currentIndex = index - 1
                    }
                    _pdfReaderContainer1.currentIndex = _fileTitleListView1.currentIndex
                    //            _pdfReaderContainer1.setCurrentIndex(_fileTitleListView1.currentIndex)
                } else {
                    _fileTitleListView1.currentIndex = -1
                    setToolbarDisableExceptItems([0])
                }
                item.destroy()
        //        print(_fileTitleListView1.currentIndex,_pdfReaderContainer1.count)
            }

            function updateEncryptState() {
                if(_pdfReaderContainer1.count == 0){
                    return
                }
                var havePassword = pdfUtil1.havePassword(_pdfReaderContainer1.currentItem.path)
                for(var i = 0;i < _toolRepeater1.model.count; i++) {
                    if(_toolRepeater1.model.get(i)["fn"] === "switchEncrypt"){
                        if(havePassword ){
                            if(_pdfReaderContainer1.currentItem.tipLayer.tipType === "VerifyPassword"){
                                _toolRepeater1.model.get(i)["tip"] = "Encrypted, please verify the password"
                            }else if(_pdfReaderContainer1.currentItem.tipLayer.tipType === "NewPassword"){
                                _toolRepeater1.model.get(i)["tip"] = "Exit password setting"
                            }else {
                                _toolRepeater1.model.get(i)["tip"] = "Encrypted, click to cancel encryption"
                            }
                        } else {
                            _toolRepeater1.model.get(i)["tip"] = "Not encrypted, click to encrypt"
                        }
                        break;
                    }
                }
            }

            //Set multiple items on the toolbar to enable, compare attributes to fn, and other unchanged
            function setToolbarEnableItems(enableItems){
                for(var i = 0;i < _toolRepeater1.model.count; i++){
                    for(var j = 0;j < enableItems.length; j++){
                        if(_toolRepeater1.model.get(i)["fn"] === enableItems[j]){
                            _toolRepeater1.model.get(i)["disable"] = false
                            break
                        }
                    }
                }
            }

            //设置工具栏上多个item为disable，比较属性为fn，其他不变
            function setToolbarDisableItems(disableItems){
                for(var i = 0;i < _toolRepeater1.model.count; i++){
                    for(var j = 0;j < disableItems.length; j++){
                        if(_toolRepeater1.model.get(i)["fn"] === disableItems[j]){
                            _toolRepeater1.model.get(i)["disable"] = true
                            break
                        }
                    }
                }
            }

            //设置工具栏除了exceptItems使能，其他为disable
            function setToolbarEnableExceptItems(exceptItems) {
                for(var i = 0;i < _toolRepeater1.model.count; i++){
                    var exist = false
                    for(var j = 0;j < exceptItems.length; j++){
                        if(_toolRepeater1.model.get(i)["fn"] === exceptItems[j]){
                            exist = true
                            break
                        }
                    }
                    _toolRepeater1.model.get(i)["disable"] = exist
                }
                _toolRepeater1.model.get(0)["disable"] = false
            }

            function setToolbarDisableExceptItems(exceptItems) {
                for(var i = 0;i < _toolRepeater1.model.count; i++){
                    var exist = true
                    for(var j = 0;j < exceptItems.length; j++){
                        if(_toolRepeater1.model.get(i)["fn"] === exceptItems[j]){
                            exist = false
                            break
                        }
                    }
                    _toolRepeater1.model.get(i)["disable"] = exist
                }
                _toolRepeater1.model.get(0)["disable"] = false
            }

            Rectangle {
                id: _toolbar1
                height: rh(30)
                width: parent.width
                Row {
                    Repeater {
                        id: _toolRepeater1
                        model: ListModel {
                            ListElement {
                                icon: "qrc:/images/open.ico"
                                fn: "open"
                                tip: "Open new document"
                                disable: false
                            }
                            //                    ListElement {
                            //                        icon: "qrc:/images/close.ico"
                            //                        fn: "close"
                            //                        tip: "关闭当前文档"
                            //                    }
                            ListElement {
                                icon: "qrc:/images/save.png"
                                fn: "save"
                                tip: "Save the document"
                                disable: true
                            }
                            ListElement {
                                icon: "qrc:/images/undo.png"
                                fn: "undo"
                                tip: "Revoke"
                                disable: true
                            }

                            ListElement {
                                icon: "qrc:/images/previouspage.ico"
                                fn: "previousPage"
                                tip: "Previous page"
                                disable: true
                            }
                            ListElement {
                                icon: "qrc:/images/nextpage.ico"
                                fn: "nextPage"
                                tip: "Next page"
                                disable: true
                            }
                            ListElement {
                                icon: "qrc:/images/rotationleft.png"
                                fn: "rotationLeft"
                                tip: "Rotate the view counterclockwise\nNote: This function is for viewing the page and does not modify the document"
                                disable: true
                            }
                            ListElement {
                                icon: "qrc:/images/rotationright.png"
                                fn: "rotationRight"
                                tip: "Rotate the view clockwise\nNote: This function is for viewing the page and does not modify the document"
                                disable: true
                            }
                            ListElement {
                                icon: "qrc:/images/zoom_in.ico"
                                fn: "zoomIn"
                                tip: "ZoomIn"
                                disable: true
                            }
                            ListElement {
                                icon: "qrc:/images/zoom_reset.ico"
                                fn: "zoomReset"
                                tip: "zoomReset"
                                disable: true
                            }
                            ListElement {
                                icon: "qrc:/images/zoom_out.ico"
                                fn: "zoomOut"
                                tip: "zoomOut"
                                disable: true
                            }
                            ListElement {
                                icon: "qrc:/images/text.png"
                                fn: "addText"
                                tip: "AddText"
                                disable: true
                            }
                            //                    ListElement {
                            //                        icon: "qrc:/images/image.png"
                            //                        fn: "addimage"
                            //                        tip: "添加图片"
                            //                    }
                            ListElement {
                                icon: "qrc:/images/line.png"
                                fn: "addLine"
                                tip: "Add Line"
                                disable: true
                            }
                            ListElement {
                                icon: "qrc:/images/cursor-mouse.png"
                                fn: "selectText"
                                tip: "Select Text"
                                disable: true
                            }
                            ListElement {
                                icon: "qrc:/images/cursor-mouse.png"
                                fn: "selectText"
                                tip: "Select Text"
                                disable: true
                            }

        //                    ListElement {
        //                        icon: "qrc:/images/docencrypt.png"
        //                        fn: "switchEncrypt"
        //                        tip: "切换加密状态" // 加密状态 <-> 公开状态
        //                        disable: true
        //                    }
                        }
                        delegate: Button {
                            id: _buttonDelegate1
                            width: _toolbar1.height * 6 / 5
                            height: _toolbar1.height
                            enabled: !disable
                            function hidden(){
                                for(var i = 0;i < _root1.hiddenActionIndex.length; i++){
                                    if(_root1.hiddenActionIndex[i] === index){
                                        return true
                                    }
                                }
                                return false
                            }
                            visible: !hidden()

                            background: Item {
                                id: _iconContainer1
                                anchors.fill: parent
                                enabled: disable
                                property var colorObj: null
                                property var disableFlag: disable
                                onDisableFlagChanged: {
                                    if(disable) {
                                        colorObj = _colorOverlay1.createObject(_iconContainer1,{"anchors.fill":_iconImage1,"source":_iconImage1})
                                        _iconImage1.visible = false
                                    }else{
                                        if(colorObj !== null){
                                            colorObj.destroy()
                                            colorObj = null
                                        }
                                        _iconImage1.visible = true
                                    }
                                }

                                onEnabledChanged: {

                                }
                                Image {
                                    id: _iconImage1
                                    anchors.centerIn: parent
                                    sourceSize: Qt.size(parent.width * 0.7,parent.height * 0.7)
                                    source: icon
                                    smooth: true
                                }
                                Component {
                                    id: _colorOverlay1
                                    ColorOverlay {
                                        enabled: index == 0 || _fileTitleListView1.model.count > 0
                                        color: "#909090"
                                    }
                                }
                            }
                            ToolTip.text: tip
                            ToolTip.visible: hovered
                            onClicked: {
                                _root1[fn]()
                            }
                        }
                    }
                }
            }

            Rectangle {
                id: _fileTitleBottomLayer1
                anchors.top: _toolbar1.bottom
                width: parent.width
                height: (_fileTitleListView1.count == 0 || !_fileTitleListView1.visible) ? 0 : rh(26)
            }

            ListView {
                id: _fileTitleListView1
                anchors {
                    top: _toolbar1.bottom
                }
                onCountChanged: {
                    if(count > 0) {
                        _root1.setToolbarEnableExceptItems([_root1.fnUndo])
                    }else{
                        _root1.setToolbarEnableExceptItems([_root1.fnUndo])
                    }
                }

                width: parent.width
                height: count == 0 ? 0 : rh(26)
                model: ListModel {
                }
                orientation: ListView.Horizontal
                delegate: Rectangle {
                    width: rw(120)
                    height: rh(26)
                    clip: true
                    color: index == _fileTitleListView1.currentIndex ? "#B0BEC5" : "white"
                    MouseArea {
                        id: _mouseArea1
                        hoverEnabled: true
                        anchors.fill: parent
                        onClicked: {
                            _fileTitleListView1.currentIndex = index
                            _pdfReaderContainer1.setCurrentIndex(index)
                        }
                    }

                    Rectangle {
                        id: _tagRect1
                        width: rw(3)
                        height: parent.height
                        color: index == _fileTitleListView1.currentIndex ? "#009688" : "#EEEEEE"
                    }

                    Text {
                        anchors {
                            left: parent.left
                            leftMargin: rw(6)
                            verticalCenter: parent.verticalCenter
                            right: parent.right
                            rightMargin: rw(20)
                        }
                        text: basename
                    }
                    Button {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: rw(20)
                        height: parent.height
                        background: Image {
                            source: "qrc:/images/close.png"
                            scale: 0.5
                        }
                        ToolTip.text: "关闭"
                        ToolTip.visible: hovered
                        ToolTip.delay: 250
                        onClicked: {
                            _root1.removeFileByIndex(index)
                        }
                    }
                    ToolTip.visible: _mouseArea1.containsMouse
                    ToolTip.text: path
                    ToolTip.delay: 500
                }
            }

            SwipeView {
                id: _pdfReaderContainer1
                anchors.fill: parent
                visible: true
                anchors.topMargin: _toolbar1.height + _fileTitleBottomLayer1.height
                onCurrentItemChanged: {
                    _updateDelayer1.run(400)
                }
                Delayer {
                    id: _updateDelayer1
                    callback: function() {
                        if(_pdfReaderContainer1.count > 0){
                            _root1.updateEncryptState()
                        }
                        if(_pdfReaderContainer1.currentIndex != -1 && pdfUtil1.existChangeItem(_pdfReaderContainer1.currentItem.path)){
                            _root1.setToolbarEnableItems([_root1.fnUndo])
                        }else{
                            _root1.setToolbarDisableItems([_root1.fnUndo])
                        }
                    }
                }
            }

            Component {
                id: _textComponent1
                FocusScope {
                    focus: true
                    TextField {
                        id: _textField1
                        objectName: "NewTextField"
                        width: rw(160)
                        height: rh(35)
                        selectByMouse: true
                        font.pixelSize: rfs(16)
                        focus: true
                        focusReason: Qt.OtherFocusReason
                        background: Rectangle {
                            radius: rw(3)
                            border.width: rw(1)
                            border.color: "black"
                        }
                        onEditingFinished: {
                            pdfUtil1.addText(_pdfReaderContainer1.currentItem.path,_pdfReaderContainer1.currentItem.editPageIndex,_pdfReaderContainer1.currentItem.editPosition,text)
                            _pdfReaderContainer1.currentItem.editControl.destroy()
                            _pdfReaderContainer1.currentItem.editControl = null
                        }
                    }
                }
            }


            Component {
                id: _pdfReader1
                Rectangle {
                    id: _listView1Container1
                    color: "gray"
                    clip: true
                    property string path
                    property bool showRecords: true
                    property real zoomRatio: 1.0  //Zoom factor
                    property int maxPageWidth
                    property string editType: "NONE"  //NONE、TEXT、IMAGE、SELECT
                    property var editControl //Array form or control
                    property int editPageIndex
                    property point editPosition
                    property alias listView: _listView1
                    property alias tipLayer: _tipLayer1
                    Connections{
                        target: pdfUtil1
                        onMaxPageWidthChangedNotify: {
                            //print("onMaxPageWidthChangedNotify" ,_listView1Container1.path, path,width , _root1.width)
                            if(_listView1Container1.path == path){
                                _listView1Container1.maxPageWidth = width
                                if(width < _root1.width){
                                    _horizontalBar1.policy = ScrollBar.AlwaysOff
                                }else{
                                    _horizontalBar1.policy = ScrollBar.AlwaysOn
                                }
                            }
                        }
                    }
                    ListView {
                        id: _listView1
                        interactive: _root1.iteractive
                        anchors.fill: parent
                        model: ListModel{}
                        spacing: rh(8)
                        clip: true
                        focus: true
                        Component.onCompleted: {
                            pdfUtil1.addFile(_listView1Container1.path,_listView1Container1.showRecords)
                        }

                        Connections {
                            target: pdfUtil1
                            onLoadFinishNotify: {
                                if(path == _listView1Container1.path){
                                    for(var i = 0;i < pageCount;i++){
                                        var url = "image://PdfScreenshot1/"+path+"#"+i
                                        _listView1.model.append({"imgUrl": url })
                                    }
                                }
                            }
                        }
                        delegate: Item {
                            id: _delegateRect1
                            height: _image1.sourceSize.height
                            focus: true

                            MouseArea {
                                anchors.fill: parent
                                onWheel: {
                                    if (wheel.modifiers & Qt.ControlModifier) {
                                        if( wheel.angleDelta.y > 0 ){
                                            zoomIn()
                                        }else{
                                            zoomOut()
                                        }
                                        wheel.accepted = true
                                        return
                                    }
                                    wheel.accepted = false
                                }

                                onClicked: {
                                    _listView1.currentIndex = index
                                }
                            }
                            width: {
                                var zoomWidth = _image1.sourceSize.width
                                if(zoomWidth < _root1.width){
                                    _image1.anchors.horizontalCenter = _delegateRect1.horizontalCenter
                                    return _root1.width
                                }else{
                                    _image1.anchors.horizontalCenter = undefined
                                    return zoomWidth
                                }
                            }
                            //rotation: pageRotation
                            Image {
                                id: _image1
                                source: imgUrl
                                height: _image1.sourceSize.height
                                width: _image1.sourceSize.width
                                x: -_horizontalBar1.position * width
                                cache: false

                                //自绘层
                                Canvas {
                                    id: _canvas1
                                    anchors.fill: parent
                                    antialiasing: true
                                    smooth: true
                                    property point tempPoint: Qt.point(-1,-1)
                                    property point startPoint: Qt.point(-1, -1)
                                    visible: true
                                    onPaint: {
                                        if(_listView1Container1.editType == "LINE"){
                                            var ctx = getContext("2d")
                                            ctx.reset()
                                            ctx.lineWidth = 3
                                            ctx.strokeStyle = "#ff0000"
                                            if(Array.isArray(_listView1Container1.editControl) && tempPoint.x !== -1){
                                                if(_listView1Container1.editControl.length === 1){
                                                    var startPos = _listView1Container1.editControl[0]
                                                    ctx.moveTo(startPos.x,startPos.y)
                                                    //修正横线
                                                    if(Math.abs(startPos.x - tempPoint.x) <= 5){
                                                        tempPoint.x = startPos.x;
                                                    }
                                                    if(Math.abs(startPos.y - tempPoint.y) <= 5){
                                                        tempPoint.y = startPos.y
                                                    }
                                                    ctx.lineTo(tempPoint.x,tempPoint.y)
                                                    ctx.stroke()
                                                }
                                            }
                                            tempPoint.x = -1
                                        } else if(_listView1Container1.editType == "SELECT"){
                                            var ctx = getContext("2d")
                                            ctx.reset()
                                            if(startPoint.x == -2)
                                                return
                                            ctx.lineWidth = 2
                                            ctx.globalAlpha = 0.5
                                            ctx.fillStyle = "#3CBBF9"
                                            ctx.fillRect(startPoint.x, startPoint.y, tempPoint.x - startPoint.x, tempPoint.y - startPoint.y)
                                            tempPoint.x = -1
                                        }else {
                                            ctx = getContext("2d")
                                            ctx.clearRect(0,0,width,height)
                                        }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: false
                                    enabled: _listView1Container1.editType != "NONE"
                                    cursorShape: _listView1Container1.editType != "NONE" ? Qt.IBeamCursor : Qt.OpenHandCursor
                                    onPressed: {
                                        _canvas1.startPoint = Qt.point(mouseX,mouseY)
                                    }
                                    onClicked: {
                                        _listView1Container1.editPageIndex = index
                                        if(!_listView1Container1.editControl && _listView1Container1.editType == "TEXT"){
                                            _listView1Container1.editControl = _textComponent1.createObject(_image1)
                                            Qt.callLater(function(){
                                                _listView1Container1.editControl.focus = true
                                            })
                                            _listView1Container1.editPosition = Qt.point(mouseX,mouseY)
                                            if(_listView1Container1.editControl){
                                                _listView1Container1.editControl.x = mouseX
                                                _listView1Container1.editControl.y = mouseY
                                            }
                                        }else if(_listView1Container1.editType == "IMAGE"){
                                            // pdfUtil1.addImage(_listView1Container1.path,index,Qt.point(mouseX,mouseY))
                                        } else if(_listView1Container1.editType == "LINE") {
                                            if(!Array.isArray(_listView1Container1.editControl) || _listView1Container1.editControl.length === 2) {
                                                _listView1Container1.editControl = [Qt.point(mouseX,mouseY)]
                                                hoverEnabled = true   //起始点启用
                                            }else if(_listView1Container1.editControl.length === 1){
                                                _listView1Container1.editControl.push(Qt.point(mouseX,mouseY))
                                                pdfUtil1.addLine(_listView1Container1.path,index,_listView1Container1.editControl[0],Qt.point(mouseX,mouseY))
                                                hoverEnabled = false  //已经获得第二个点，不需要了
                                            }
                                            _canvas1.requestPaint()
                                        }
                                    }
                                    onPositionChanged: {
                                        if(_listView1Container1.editType == "LINE" || _listView1Container1.editType == "SELECT") {
                                            _canvas1.tempPoint = Qt.point(mouseX,mouseY)
                                            _canvas1.requestPaint()
                                        }
                                    }
                                    onReleased: {
                                        if(_listView1Container1.editType == "SELECT") {
                                            pdfUtil1.selectedText(_listView1Container1.path,index,_canvas1.startPoint,Qt.point(mouseX,mouseY))
                                            _canvas1.startPoint.x = -2
                                            _canvas1.requestPaint()

                                        }
                                    }
                                }
                            }

                            function updateImage() { //requestImage
                                var tmp = imgUrl
                                imgUrl = ""
                                imgUrl = tmp
                            }

                            Connections {
                                target: _root1
                                onUpdateImageNotify: {
                                    if(path === _listView1Container1.path) {
                                        _delegateRect1.updateImage()
                                    }
                                }
                                onExitEdit: {
                                    _listView1Container1.editType = "NONE"
                                    _listView1Container1.editControl = null
                                    _canvas1.requestPaint()
                                }
                            }

                            Connections {
                                target: pdfUtil1
                                onUpdatePage: {
                                    if(path === _listView1Container1.path && pageNum === index){
                                        _delegateRect1.updateImage()
                                    }
                                }
                            }
                        }

                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AlwaysOn
                            contentItem: Rectangle {
                                        id: thisWillBeAutomaticallyResizedNoMatterWhatYouDo
                                        implicitWidth: 6
                                        radius: width / 2
                                        color: 'blue'

//                                        Rectangle {
//                                            id: thisWillChangeTheSizeWithTheIndicator
//                                            color: 'yellow'
//                                            opacity: 0.7
//                                            width: 10
//                                            height: 40
//                                            radius: 5
//                                            anchors.centerIn: parent
//                                        }

                                        Rectangle {
                                            id: thisCouldBeYourImage
                                            width: 10
                                            height: 30
                                            radius: 5
                                            anchors.centerIn: parent
                                            color: 'black'
                                        }
                                    }
                        }

                        ScrollBar {
                            id: _horizontalBar1
                            hoverEnabled: true
                            active: hovered || pressed
                            orientation: Qt.Horizontal
                            size: _root1.width / maxPageWidth
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                        }
                    }

                    Rectangle {
                        id: _tipLayer1
                        color: "#eee"
                        anchors.fill: parent
                        visible: false
                        property string tipType: "None"  // None / VerifyPassword / NewPassword
                        property alias tipTitle: _tipTitle1.text
                        Image {
                            id: _limitAccessImage1
                            anchors.centerIn: parent
                            anchors.verticalCenterOffset: -rh(50)
                            width: rw(128)
                            height: rh(128)
                            source: "qrc:/images/limitaccess.png"
                        }

                        Text {
                            id: _tipTitle1
                            anchors.top: _limitAccessImage1.bottom
                            anchors.topMargin: rh(15)
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Restriction of visit"
                            color: "#707070"
                            font.pixelSize: rfs(30)
                        }

                        Delayer {
                            id: _delayer1
                        }

                        TextField {
                            id: _passwordInput1
                            anchors {
                                top: _tipTitle1.bottom
                                topMargin: rh(15)
                                horizontalCenter: parent.horizontalCenter
                            }
                            placeholderText: "Please enter your password"
                            selectByMouse: true

                            background: Rectangle {
                                id: _passwordBg1
                                implicitWidth: 160
                                implicitHeight: 30
                                color: "transparent"
                                border.color: _passwordInput1.enabled ? "#707070" : "transparent"
                                radius: rw(4)
                            }

                            Keys.onReturnPressed: {
                                if(_tipLayer1.tipType == "VerifyPassword"){
                                    if(pdfUtil1.matchPassword(_listView1Container1.path,text)) {
                                        _tipTitle1.text = "Match successfully"
                                        _delayer1.callback = function() {
                                            _tipLayer1.visible = false
                                            _tipLayer1.tipType = "None"
                                            updateEncryptState()
                                        }
                                        _delayer1.run(1500)
                                    }else{
                                        _passwordBg1.border.color = "red"
                                    }
                                }else if(_tipLayer1.tipType == "NewPassword"){
                                    if(pdfUtil1.setPassword(_listView1Container1.path,text)) {
                                        _tipTitle1.text = "Set successfully"
                                        _delayer1.callback = function() {
                                            _tipLayer1.visible = false
                                            _tipLayer1.tipType = "None"
                                            updateEncryptState()
                                        }
                                        _delayer1.run(1500)
                                    }else{
                                        _tipTitle1.text = "Setup failed"
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
}


