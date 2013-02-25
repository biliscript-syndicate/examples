//// Begin package code
manifest = {
    namespace: 'nekofs.bde',
    name: 'Biliscript弹幕脚本开发环境',
    description: 'trace("hehe");',
    revision: 122,
    version: '',
    release_name: '0.9 (20121114)',
    release_note: '',
    homepage: '问题意见：http://9ch.co/t53269,1-1.html',
    help: '帮助：F1 返回：Esc\n 查找：Ctrl-F Ctrl-Shift-F F3\n 导入：Ctrl-O 导出：Ctrl-S\n 最大化编辑窗口：Ctrl-U\n 字号放缩：Ctrl-[+/-] Ctrl-0\n 预览：Ctrl-Alt-Enter',
    permissions: ['$', '$G', 'Player'],
    dependencies: []
};

create = $.root.loaderInfo.content.create;
define = $.root.loaderInfo.content.getDefinitionByName;
commentConfig = (define('org.lala.utils.CommentConfig')).getInstance();
ExternalInterface = define('flash.external.ExternalInterface');
BindingUtils = define('mx.binding.utils.BindingUtils');
Keyboard = define('flash.ui.Keyboard');
Font = define('flash.text.Font');
SharedObject = define('flash.net.SharedObject');
ApplicationConstants = define('org.lala.utils.ApplicationConstants');
String = define('String');
Capabilities = define('flash.system.Capabilities');
TextEvent = define('flash.events.TextEvent');

OS = Capabilities.version.substr(0, 3);
Mukio = $.root.loaderInfo.content.document;
editor = Mukio.scriptCommentInput.srcText;
tabPanel = Mukio.tabPanel;

function createListenerHelper() {
    var self = {};
    self.add = function(dispatcher, types, listener, useCapture, priority) {
        useCapture = useCapture || false;
        priority = priority || 0;
        if (typeof(types) == 'string') types = [types];
        if (!self.listeners) self.listeners = [];
        types.forEach(function(type) {
            self.listeners.push({
                dispatcher: dispatcher,
                type: type,
                listener: listener,
                useCapture: useCapture
            });
            dispatcher.addEventListener(type, listener, useCapture, priority);
        });
    };
    self.clear = function() {
        if (!self.listeners) return;
        self.listeners.forEach(function(e) {
            e.dispatcher.removeEventListener(e.type, e.listener, e.useCapture);
        });
        self.listeners = undefined;
    };
    return self;
}
ListenerHelper = createListenerHelper();

function testGlyphWidth(font, size) {
    var tf = create('flash.text.TextField');
    var width = function(tf) {
        return (tf.getLineMetrics(0)).width;
    };
    var dtf = tf.defaultTextFormat;
    dtf.font = font;
    dtf.size = size;
    tf.defaultTextFormat = dtf;
    tf.text = 'M';
    var em = width(tf);
    for (var c = 32; c < 127; c++) {
        tf.text += String.fromCharCode(c);
        if (width(tf) != tf.text.length * em) return undefined;
    }
    return em;
}

function setTabSize(target, tabSize) {
    var tabStops = [];
    var em = testGlyphWidth(target.getStyle('fontFamily'), target.getStyle('fontSize'));
    for (var i = 1; i < 40; i++) tabStops.push(em * tabSize * i);
    target.setStyle('tabStops', tabStops.join(' '));
}

function getMonospaceFonts() {
    var fonts = Font.enumerateFonts(true);
    fonts.sortOn('fontName', 1);
    return (fonts.map(function(e) {
        return e.fontName;
    })).filter(function(e) {
        return testGlyphWidth(e, 12) !== undefined;
    });
}

function pickOneFont(fonts) {
    var preference = {
        'LNX': ['DejaVu Sans Mono', 'Liberation Mono', 'Inconsolata', 'Droid Sans Mono', 'Andale Mono'],
        'WIN': ['Consolas', 'Inconsolata', 'Lucida Console'],
        'MAC': ['Monaco', 'Inconsolata', 'Andale Mono']
    };
    var preferredFonts = preference[OS].filter(function(e) {
        return fonts.indexOf(e) != -1;
    });
    preferredFonts.push('Courier New');
    return preferredFonts[0];
}

function createLabel(text, toolTip, onclick) {
    var self = create('spark.components.Label');
    self.text = text;
    if (toolTip) self.toolTip = toolTip;
    if (onclick) {
        self.buttonMode = true;
        self.setStyle('color', 255);
        ListenerHelper.add(self, 'click', onclick);
    }
    return self;
}

function openLocalFile() {
    var ref = create('flash.net.FileReference');
    ref.addEventListener('complete', function() {
        editor.selectAll();
        editor.textFlow.interactionManager.insertText(ref.data.readUTFBytes(ref.data.length));
        //editor.text = ref.data.readUTFBytes(ref.data.length);//This destroys the undo history
    });
    ref.addEventListener('select', function() {
        ref.load();
    });
    ref.browse();
};

function saveLocalFile() {
    var ref = create('flash.net.FileReference');
    var access = Mukio.infoHeader.accessConfig; //Don't kill me I just want some helping info
    var timestr = '' + (Player.time % 1000);
    while (timestr.length < 3)
        timestr = '0' + timestr;
    timestr = (Player.time / 1000 ^ 0) + '.' + timestr;
    while (timestr.length < 7)
        timestr = '0' + timestr;
    ref.save(editor.text, 'av' + access.aid + '-cid' + access.chatId + '-' + timestr + '.txt');
};

function unload() {
    var self = $G._get('app-global:' + manifest.namespace);
    self.ListenerHelper.clear();
    if (self.enabled) self.restore();
    $G._set('app-global:' + manifest.namespace, undefined);
}

function getChildren(path, node) {
    if (!node.hasOwnProperty('numChildren')) return;
    for(var i = 0; i < node.numChildren; i++) {
        var child = node.getChildAt(i);
        var cpath = path.slice();
        cpath.push(i);
        trace('[' + cpath + '] ' + child);
        getChildren(cpath, child);
    }
}

function load_actual(HighlightRenderer) {
    //TODO [QA]: font family, size config (Ctrl-[+|-|0])
    //TODO [QA]: line wrap
    //TODO [QA]: tabstop - press tab, tab is inserted, not space, and tab conforms user config
    //TODO [QA]: toggle editor maximization (Ctrl-U, Esc)
    //TODO [QA]: general keyboard shortcuts: run (Ctrl-Alt-Enter), help (F1)
    //TODO [QA]: saving backup / crash recovery
    //TODO [QA]: local save/load (Ctrl-O Ctrl-S)
    //TODO [QA]: find (Ctrl-F Ctrl-Shift-F)
    //TODO [QA]: (skinning) search results highlighting
    //TODO [QA]: (skinning) highlight search results
    //TODO [QA]: automatic indentation
    //TODO [QA]: importing preserves undo history
    //TODO [QA]: save cursor state
    //TODO: optimize response performance
    //TODO: clear style in copy-paste content -- user takes the duty, ok?
    //TODO: reverse searching (Shift-Enter/Shift-F3) -- hard, must maintain a data structure of search results
    //TODO: replace (Ctrl-H Ctrl-Shift-H) -- hard to manage and QA
    //TODO: (skinning) highlight current line -- CodeEditor skin not customizable
    //TODO: proper line wrapping -- CodeEditor skin bug blocks
    //TODO: highlight matching brackets -- hard, more performance penalty
    //TODO: debugging help, API explorer -- hard
    //BUG: why are mouseEvents so slow? smoothScrolling?
    //BUG: undo of copy-paste create empty lines
    //TODO: load from comment list (context menu)
    //BUG: scroll bar has residue space
    //BUG: weird navigation bugs
    //----
    //BUG [CANTFIX]: take the focus when starting after the user changes player size
    //     Mukio doesn't get keyboard event from browser without the user clicking
    //     http://helpx.adobe.com/flash/kb/give-keyboard-focus-embedded-movie.html
    //     http://crbug.com/27868

    var self = $G._get('app-global:' + manifest.namespace);
    if (self) self.unload();
    self = {unload: unload, enabled: false, maximized: false, ListenerHelper: ListenerHelper};
    $G._set('app-global:' + manifest.namespace, self);

    var hash = ExternalInterface.call('eval', "window.location.hash");
    if (hash.indexOf('#editor') == 0) commentConfig.debugEnabled = true;

    var lso = SharedObject.getLocal(ApplicationConstants.SharedObjectName, '/');
    if (!lso.data.EditorConfig) lso.data.EditorConfig = {};
    var config = lso.data.EditorConfig;

    self.renderer = HighlightRenderer.create(trace);
    self.renderer.highlightEnabled = (config.highlightEnabled === undefined ? true : config.highlightEnabled);
 

/**** Fix bugs ****/
    
    //org.lala.components.ScriptCommentInput tried to manage tab insertion with event listener.
    //This destroyed undo stack.
    //editor.removeEventListener('keyFocusChange', Mukio.scriptCommentInput.__srcText_keyFocusChange); //double remove is ok
    //FIXED officially on 20121102 (tab size not configurable yet)
    ListenerHelper.add(editor, 'keyFocusChange', function(e) {
        if (e.target===self.searchInput.skin.textDisplay) editor.setFocus();
        e.preventDefault();
        e.stopImmediatePropagation();
    }, true);
    editor.textFlow.configuration.manageTabKey = true;

    //org.lala.components.ScriptCommentInput code highlighting currently frobs editor.text and destroys undo stack.
    //I'll try to port the syntax highlighting code into a skin.
    commentConfig.codeHighlightEnabled = false;
    editor.codeHighlightEnabled = false;

    //TODO: how about low latency typewriting instead of batch something?
    //Don't delay key strokes. The user wants realtime experience.
    //XXX What's the version? flashx.textLayout.edit.EditManager doesn't have allowDelayedOperations
    //editor.textFlow.interactionManager.allowDelayedOperations = false;
        
    //Let mouse wheel scroll faster than the default.
    //XXX Why this no work? editor.textFlow.interactionManager.configuration.scrollMouseWheelMultiplier *= 8;
    ListenerHelper.add(editor, 'mouseWheel', function(e) {
        e.delta *= 8;
    }, true);

    /*
    flashx/textLayout/edit/SelectionManager.as:
    
        // Ignore the next text input event. This is needed because the player may send a text input event
        // following by a key down event when ctrl+key is entered. 
        protected var ignoreNextTextEvent:Boolean = false;

    flashx/textLayout/edit/EditManager.as:
    
        switch (event.charCode) {
        case 122: // small z
            // pre-Argo and on the mac then ignoreNextTextEvent
            if (!Configuration.versionIsAtLeast(10,1) && (Capabilities.os.search("Mac OS") > -1))
                ignoreNextTextEvent = true;
            undo();
            event.preventDefault();
            break;
        case 121: // small y
            ignoreNextTextEvent = true;
            redo();
            event.preventDefault();
            break;
    
    The situation is, Chromium and Iceweasel on Linux are sending a next textInput event for ^Z, and send two(?!) textInput events for ^Y.
    Non-IE browsers on Windows do not send a next textInput event for ^Z and ^Y.
    
    Now ^Y works ok for Chromium and Iceweasel on Linux. ^Z destroys their usability.
    ^Z works ok for Non-IE browsers on Windows. ^Y eats the next textInput event.
    */
    ListenerHelper.add(editor, ['keyDown', 'keyUp'], function(e) {
        //Iceweasel bug: after player_fullwin(true), {shift,ctrl,alt}Key == false
        if (OS == 'LNX') {
            var keyDown = (e.type == 'keyDown');
            if (e.keyCode == Keyboard.SHIFT) self.shiftPressed = keyDown;
            if (e.keyCode == Keyboard.CONTROL) self.ctrlPressed = keyDown;
            if (e.keyCode == Keyboard.ALTERNATE) self.altPressed = keyDown;
            e.shiftKey = e.shiftKey || self.shiftPressed;
            e.ctrlKey = e.ctrlKey || self.ctrlPressed;
            e.altKey = e.altKey || self.altPressed;
        }
        //IE ActiveX bug: ^Z keyDown is robbed. ^Z keyUp is annoying for the user but better than nothing.
        if (e.charCode == 122 && e.ctrlKey) {
            if (e.type == 'keyDown') self.ctrlZKeyDownHappens = true;
            if (!self.ctrlZKeyDownHappens) editor.textFlow.interactionManager.keyDownHandler(e);
        }
        //Undo operation merge should break when the user type ^Y
        if (e.charCode == 121 && e.ctrlKey) e.keyCode = Keyboard.ESCAPE; //no side-effect
    }, true);
    //kill erroneous textInput events (Linux browsers)
    ListenerHelper.add(editor, 'textInput', function(e) {
        if (!e.text || self.ctrlPressed) e.stopImmediatePropagation();
    }, true);
    //EditManager ignoreNextTextEvent for everyone after a ^Y. Feed it.
    var textEventInstance = HighlightRenderer.createDummyTextEvent();
    ListenerHelper.add(editor, 'keyUp', function(e) {
        if (e.charCode == 121 && e.ctrlKey) editor.textFlow.interactionManager.textInputHandler(textEventInstance);
    });
    
   
/**** UI tweaks ****/
    
    //compact when the editor is fullscreen.
    editor.top = 0;
    editor.left = 0;
    
    //save some padding space for compact
    Mukio.scriptCommentInput.layout.paddingTop = 4;
    Mukio.scriptCommentInput.layout.paddingBottom = 2;
    Mukio.scriptCommentInput.layout.paddingLeft = 2;
    Mukio.scriptCommentInput.layout.paddingRight = 2;
    Mukio.scriptCommentInput.layout.gap = 2;
    //XXX why cjk labels gets shifted upwards for about one pixel?
    //(see it with setStyle('backgroundColor', 0xaaaaaa))
    (Mukio.scriptCommentInput.getElementAt(0)).setStyle('baselineShift', -1);
    (Mukio.scriptCommentInput.getElementAt(2)).setStyle('baselineShift', -1);

    //choose the default font
    var fonts = getMonospaceFonts();
    var preferredFont = pickOneFont(fonts);

    //editor default styling
    editor.setStyle('fontFamily', config.fontFamily || preferredFont);
    editor.setStyle('fontSize', config.fontSize || 12);
    editor.setStyle('color', 0);
    editor.setStyle('lineBreak', config.lineWrap === true ? 'toFit' : 'explicit');
    setTabSize(editor, config.tabSize || 4);


/**** Load saved text ****/

    if (config.cachedText && !editor.text)
        editor.text = config.cachedText;
    BindingUtils.bindProperty(config, 'cachedText', editor, 'text');
    if (config.cachedSelectionPosition) {
        editor.selectRange(config.cachedSelectionPosition, config.cachedSelectionPosition);
        editor.scrollToRange(config.cachedSelectionPosition, config.cachedSelectionPosition);
    }
    BindingUtils.bindProperty(config, 'cachedSelectionPosition', editor, 'selectionActivePosition');

/**** Construct the config panel (font family, size, line wrap, tab size) ****/
    
    self.configPanel = create('spark.components.HGroup');
    self.configPanel.horizontalAlign = 'left';
    self.configPanel.verticalAlign = 'middle';
    self.configPanel.gap = 4;

    //font family
    var fontSelection = create('spark.components.DropDownList');
    var fontList = create('mx.collections.ArrayCollection');
    fontList.source = fonts;
    fontSelection.dataProvider = fontList;
    fontSelection.selectedItem = editor.getStyle('fontFamily');
    ListenerHelper.add(fontSelection, 'mouseWheel', function(e) {
        fontSelection.selectedIndex -= (e.delta > 0 ? 1 : -1) * !(fontSelection.selectedIndex == 0 && e.delta > 0);
    });
    BindingUtils.bindProperty(config, 'fontFamily', fontSelection, 'selectedItem');
    BindingUtils.bindSetter(function(v) {
        editor.setStyle('fontFamily', v);
    }, fontSelection, 'selectedItem');

    //font size
    var fontSize = create('spark.components.NumericStepper');
    fontSize.minimum = 8;
    fontSize.maximum = 16;
    fontSize.value = editor.getStyle('fontSize');
    fontSize.height = 21;
    fontSize.width = 40;
    fontSize.maxChars = 2;
    BindingUtils.bindProperty(config, 'fontSize', fontSize, 'value');
    BindingUtils.bindSetter(function(v) {
        editor.setStyle('fontSize', v);
        setTabSize(editor, config.tabSize || 4);
    }, fontSize, 'value');

    //line wrap
    var lineWrap = create('spark.components.CheckBox');
    lineWrap.enabled = false;
    BindingUtils.bindProperty(config, 'lineBreak', lineWrap, 'selected');
    BindingUtils.bindSetter(function(v) {
        editor.setStyle('lineBreak', v ? 'toFit' : 'explicit');
    }, lineWrap, 'selected');

    //line wrap
    var highlightEnabled = create('spark.components.CheckBox');
    highlightEnabled.selected = (config.highlightEnabled === undefined ? true : config.highlightEnabled);
    BindingUtils.bindProperty(config, 'highlightEnabled', highlightEnabled, 'selected');
    BindingUtils.bindProperty(self.renderer, 'highlightEnabled', highlightEnabled, 'selected');

    //tab stop size
    var tabSize = create('spark.components.NumericStepper');
    tabSize.minimum = 1;
    tabSize.maximum = 8;
    tabSize.value = config.tabSize || 4;
    tabSize.height = 21;
    tabSize.width = 32;
    tabSize.maxChars = 1;
    BindingUtils.bindProperty(config, 'tabSize', tabSize, 'value');
    BindingUtils.bindSetter(function(v) {
        setTabSize(editor, v);
    }, tabSize, 'value');

    //a button to exit
    var button = create('spark.components.Button');
    button.label = '确定';
    button.width = 50;
    ListenerHelper.add(button, 'click', function(e) {
        Mukio.scriptCommentInput.removeElement(self.configPanel);
        Mukio.scriptCommentInput.addElementAt(self.configPanelOld, 0);
    });
    self.configPanel.mxmlContent = [createLabel('字体', '限定等宽字体'), fontSelection,
                createLabel('字号', '快捷键：Ctrl-[+/-] Ctrl-0'), fontSize,
                createLabel('Tab宽度'), tabSize,
                createLabel('换行'), lineWrap,
                createLabel('高亮'), highlightEnabled, button];

    //XXX why without doing this, NumericStepper fontSize binding doesn't work?
    self.configPanel.visible = false;
    Mukio.scriptCommentInput.addElement(self.configPanel);
    Mukio.scriptCommentInput.removeElement(self.configPanel);
    self.configPanel.visible = true;


/**** Interface mode switching *****/
    
    self.toggleEditor = function() {
        if (!self.maximized) {
            Mukio.scriptCommentInput.removeElement(editor);
            Mukio.mxmlContent = [editor];
        } else {
            Mukio.mxmlContent = [Mukio._MukioPlayerPlus_Group1];
            Mukio.scriptCommentInput.addElementAt(editor, 1);
        }
        editor.setFocus();
        self.maximized = !self.maximized;
    };
    self.enlarge = function() {
        //enable fullscreen
        ExternalInterface.call('player_fullwin', true);
        Mukio.percentWidth = 100;
        Mukio.percentHeight = 100;
        Mukio._MukioPlayerPlus_Group1.percentWidth = 100;
        Mukio._MukioPlayerPlus_Group1.percentHeight = 100;
        Mukio.sidePanel.percentHeight = 100;
        Mukio._MukioPlayerPlus_VGroup1.percentHeight = 100;

        //move the debug console to below the player container
        var vg = create('spark.components.VGroup');
        vg.percentHeight = 100;
        vg.percentWidth = 100;
        vg.horizontalAlign = 'center';
        vg.paddingTop = 4;
        vg.paddingBottom = 2;
        vg.paddingLeft = 2;
        vg.paddingRight = 2;
        vg.gap = 2;
        Mukio.scriptCommentInput.removeElement(Mukio.scriptCommentInput.outText);
        Mukio.scriptCommentInput.outText.percentHeight = 100;
        vg.mxmlContent = [Mukio.scriptCommentInput.removeElementAt(0), Mukio.scriptCommentInput.outText];
        if (!vg.document) vg.document = Mukio;
        Mukio._MukioPlayerPlus_VGroup1.addElement(vg);

        //add custom buttons to a script input panel
        var hg = Mukio.scriptCommentInput.getElementAt(0);
        hg.gap = 4;
        hg.addElement(self.importButton);
        hg.addElement(self.exportButton);
        hg.addElement(self.toggleEditorButton);
        hg.addElement(self.toggleConfigButton);
        hg.addElement(self.helpButton);
        
        //add custom items to the context menu of comment table
        //var items = Mukio.cmtTable.contextMenu.customItems;
        //var item = items[1].clone();
        //items[0].separatorBefore = true;
        //item.caption = '导入编辑器';
        //ListenerHelper.add(item, 'menuItemSelect', function(e) {
        //    trace(e);
        //});
        //items.unshift(item);
        
        editor.skin.addElement(self.searchPanelContainer);

        self.renderer.attach(editor);
        
        self.enabled = true;
    };
    self.restore = function() {
        self.enabled = false;

        self.renderer.detach();

        editor.skin.removeElement(self.searchPanelContainer);

        //remove custom items from context menu of comment table 
        //var items = Mukio.cmtTable.contextMenu.customItems;
        //items.shift();
        //items[0].separatorBefore = false;
        
        //remove custom buttons from the script input area
        var hg = Mukio.scriptCommentInput.getElementAt(0);
        if (hg === self.configPanel) {
            Mukio.scriptCommentInput.removeElement(hg);
            hg = Mukio.scriptCommentInput.addElementAt(self.configPanelOld, 0);
        }
        hg.removeElement(self.toggleConfigButton);
        hg.removeElement(self.toggleEditorButton);
        hg.removeElement(self.exportButton);
        hg.removeElement(self.importButton);
        hg.removeElement(self.helpButton);
        
        //move the debug console back to the script input area
        var vg = Mukio._MukioPlayerPlus_VGroup1.removeElementAt(2);
        Mukio.scriptCommentInput.addElementAt(vg.removeElementAt(0), 0);
        Mukio.scriptCommentInput.addElementAt(vg.removeElementAt(0), 1);
        Mukio.scriptCommentInput.outText.height = 100;
        Mukio.scriptCommentInput.outText.percentHeight = NaN;
        
        //disable fullscreen
        ExternalInterface.call('player_fullwin', false);
    };

    //trying to fool CodeEditor.codeHightlightEnabled
    //var codeHighlightWasEnabled = commentConfig.codeHighlightEnabled;
    //commentConfig.codeHighlightEnabled = false;
    //editor.codeHighlightEnabled = false;

    //the particular checkbox might not exist at this time
    //FIXME I should add a complete listener to tabPanel
    ListenerHelper.add(tabPanel, 'propertyChange', function(e) {
        if (e.source.id == 'debugEnabledCb' && e.property == 'selected' && e.kind == 'update') {
            if (e.oldValue == false && e.newValue == true && !self.enabled) self.enlarge();
            if (e.oldValue == true && e.newValue == false && self.enabled) self.restore();
        }
        if (e.source.id == 'codeHighlightEnabledCb' && e.property == 'selected' && e.kind == 'update') {
            e.source.enabled = false;
            e.source.selected = false;
            e.source.label += ' (见编辑器栏设置)';
            e.preventDefault();
            e.stopImmediatePropagation();
        }
    }, true, 1);
    //commentConfig.codeHighlightEnabled = codeHighlightWasEnabled;
    ListenerHelper.add(tabPanel, 'change', function(e) {
        if (e.newIndex == 2 && commentConfig.debugEnabled && !self.enabled) self.enlarge();
    });

    
/**** Add buttons to the top panel ****/
    
    self.toggleConfigButton = createLabel('设置', '编辑器配置', function(e) {
        self.configPanelOld = Mukio.scriptCommentInput.removeElementAt(0);
        Mukio.scriptCommentInput.addElementAt(self.configPanel, 0);
    });

    self.toggleEditorButton = createLabel('最大化', '快捷键：Ctrl-U', function(e) {
        if (self.enabled) self.toggleEditor();
    });

    self.importButton = createLabel('导入', '快捷键：Ctrl-O', openLocalFile);

    self.exportButton = createLabel('导出', '快捷键：Ctrl-S', saveLocalFile);

    self.helpButton = createLabel('帮助', manifest.help, function(e) {
        trace(manifest.help);
    });

    
/**** search panel ****/

    self.searchPanelContainer = create('spark.components.BorderContainer');
    self.searchPanelContainer.top = 0;
    self.searchPanelContainer.right = 32;
    self.searchPanelContainer.height = 32;
    
    var searchPanel = create('spark.components.HGroup');
    //self.searchPanel.horizontalAlign = 'left';
    searchPanel.top = 0;
    searchPanel.left = 0;
    searchPanel.verticalAlign = 'middle';
    searchPanel.gap = 6;
    searchPanel.height = 32;
    searchPanel.paddingLeft = 8;
    searchPanel.paddingRight = 8;
    searchPanel.paddingBottom = 2;
    //searchPanel.paddingTop = 2;
    searchPanel.setStyle('fontFamily', commentConfig.font);//need to display CJK
    
    var searchLabel = createLabel('查找', '快捷键：Ctrl-F');
    
    var searchInput = create('spark.components.TextInput');
    ListenerHelper.add(searchInput, 'creationComplete', function(e) {
        searchInput.textDisplay.textFlow.configuration.manageTabKey = false;
    });
    searchInput.widthInChars = 16;
    searchInput.height = 24;
    self.searchInput = searchInput;
    var regexLabel = createLabel('正则', '快捷键：Ctrl-Shift-F', function() {
        var req = create('flash.net.URLRequest');
        req.url = 'http://help.adobe.com/zh_CN/as3/dev/WS5b3ccc516d4fbf351e63e3d118a9b90204-7ea9.html';
        var navigateToURL = define('flash.net.navigateToURL');
        navigateToURL(req, '_blank');
    });
    var regex = create('spark.components.CheckBox');

    //var prevButton = createLabel('↑', '快捷键：Shift-Enter/Shift-F3');
    //ListenerHelper.add(prevButton, 'click', self.searchPrevious);

    //var nextButton = createLabel('↓', '快捷键：Enter/F3');
    //ListenerHelper.add(nextButton, 'click', self.searchNext);

    var searchNext = function() {
        if (!searchInput.text) return;
        if (regex.selected)
            self.renderer.renderRegexSearch(searchInput.text, editor.selectionActivePosition, self.lastSearch === searchInput.text);
        else
            self.renderer.renderPlainSearch(searchInput.text, editor.selectionActivePosition, self.lastSearch === searchInput.text);
        self.lastSearch = searchInput.text;
    };
    var closeSearch = function() {
        self.searchPanelContainer.visible = false;
        self.renderer.clearSearch();
        self.lastSearch = null;
        editor.setFocus();
    };
    
    var closeButton = createLabel('×', '快捷键：Esc', closeSearch);
    
    searchPanel.mxmlContent = [searchLabel, searchInput, regexLabel, regex, /*prevButton, nextButton, */closeButton];
    self.searchPanelContainer.mxmlContent = [searchPanel];
    self.searchPanelContainer.visible = false;
    ListenerHelper.add(searchInput, 'enter', searchNext);
    ListenerHelper.add(searchInput, 'keyDown', function(e){
        if (e.keyCode == Keyboard.ESCAPE && e.charCode != 121) {
            closeSearch();
            e.stopImmediatePropagation();
        }
    });
    
    //self.searchInput.height = 12;
    

        
/**** Keyboard shortcuts ****/
    
    ListenerHelper.add(Mukio, 'keyDown', function(e) {
        if (!self.enabled) return;
        if (e.keyCode == Keyboard.ESCAPE && e.charCode != 121) {
            if (self.maximized) {
                self.toggleEditor();
            } else {
                tabPanel.selectedIndex = 0;
                self.restore();
            }
            return;
        }
        if (e.keyCode == Keyboard.F1) {
            trace(manifest.help);
            return;
        }
        if (e.ctrlKey) {
            if (e.keyCode == Keyboard.EQUAL) fontSize.value++;
            if (e.keyCode == Keyboard.MINUS) fontSize.value--;
            if (e.keyCode == Keyboard.NUMBER_0) fontSize.value = 12;
            if (e.keyCode == Keyboard.U) self.toggleEditor();
            if (e.keyCode == Keyboard.S) saveLocalFile();
            if (e.keyCode == Keyboard.O) openLocalFile();
            if (e.keyCode == Keyboard.F) {
                regex.selected = e.shiftKey;
                self.searchPanelContainer.visible = true;
                self.searchInput.setFocus();
                searchNext();
            }
        }
        if (e.keyCode == Keyboard.F3) {
            self.searchPanelContainer.visible = true;
            searchNext();
        }
        if (e.keyCode == Keyboard.ENTER && !e.shiftKey) {
            var pi = editor.textFlow.findChildIndexAtPosition(editor.selectionActivePosition);
            if (pi >= 1) {
                var p = editor.textFlow.getChildAt(pi - 1);
                var str = p.getText();
                while (str.charCodeAt(0) == 9 || str.charCodeAt(0) == 32) {
                    //var c = e.clone();
                    //c.keyCode = c.charCode = Keyboard.TAB;
                    //editor.textFlow.interactionManager.keyDownHandler(c);
                    editor.textFlow.interactionManager.insertText(str.charAt(0));
                    str = str.substr(1);
                }
            }
        }
    });
    //previewBt tooltip
    Mukio.scriptCommentInput.previewBt.toolTip = '快捷键：Ctrl-Alt-Enter';
    ListenerHelper.add(Mukio, 'keyDown', function(e) {
        if (e.ctrlKey && e.altKey && e.keyCode == Keyboard.ENTER) {
            e.stopImmediatePropagation();
            Mukio.scriptCommentInput.__previewBt_click(null);
        }
    }, true);


/**** Enable on startup ****/

    if (tabPanel.selectedIndex == 2 && commentConfig.debugEnabled && !self.enabled) {
        self.enlarge();
        Player.seek(0);
        Player.pause();
    }
}

var SWF_HighlightRenderer = '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
';

var SWF_make = 'Q1dTCbICAAB42pWSzWoUQRSFz63qrp/MJMYJ6CKgA+lNJhqyzEI0DgkGEQV/lrPoNNWdjj3dQ3UNOAs3Ln0Bd4Jrl76CD2CXyDyGr2AlIIgoxloUdb/zndUtAITDqwrAvcE7BqxjFwxE6xBPTs5M5uL71qYL8dQUR69m/TtbZe2MrdNqeFf9fOrH6dS0szQzYjY/qcosmqYvjXjmbFkXvbxK29PduSurdqMw7tDkZV26sqnHi/OeqExduNP4yNrG3nBNM5ym9WKYNXXr7DxzjR2mtphPTe3a+BpdjxWpHmecEV+VxCRxSZFkQnIpmZJc6xWSUV+v0ibTa8QI0BEuDhGPBGKmRLi5kueMYSOkb3k3Ubn6NFgDJrp7pGm0fPPtq+LbPl+5TR9G7Wj5MYw7g+eEzRcEvQXsAPvAQyAFXgPvgc/Ad+AmoRtjGfTjzifIe2P6ZfAJBcJ+Jz5hAfM/Yp/wkEV/z3wSBSH+h+CTOFjiMpZPRFDlpVWfyOCr//N9okJJX5S2J/28f+vKmPiDsCcWfmDvy95EHiCV3XFAB/gBflmuyw==';

function load() {
    var b64dec = create('mx.utils.Base64Decoder');
    var loader = create('flash.display.Loader');
    loader.contentLoaderInfo.addEventListener('complete', function(e) {
        load_actual(e.target.applicationDomain.getDefinition('HighlightRenderer'));
    });
    b64dec.decode(SWF_HighlightRenderer);
    loader.loadBytes(b64dec.toByteArray());
}

////End package code


load();

/*
//Biliscript App Packaging Format:
// ";/*" PACKAGE-NAME "," SHA256SUM "," BASE64
// ";/*" PACKAGE-NAME "," SHA256SUM ", " VERBATIM

function loadAppNoSecurity(name, cid, uid) {
    var sm = $.root.loaderInfo.content;
    var provider = sm.create('org.lala.net.CommentProvider');
    provider.addEventListener('8', function(e) {
        var fields = e.data.text.split(',');
        if (e.data.userId == uid && fields[0] == ';/*' + name) {
            var b64dec = sm.create('mx.utils.Base64Decoder');
            b64dec.decode(fields[2]);
            var bytes = b64dec.toByteArray();
            ((sm.getDefinitionByName('tv.bilibili.script.CommentScriptFactory')).getInstance()).exec(
                bytes.readUTFBytes(bytes.bytesAvailable) +
                "trace(manifest.name + ' ' + manifest.release_name + '\n ' + manifest.release_note + '\n ' + manifest.homepage);load();", false);
        }
    });
    provider.load('http://comment.bilibili.tv/' + cid + '.xml');
}
loadAppNoSecurity('nekofs.bde', 11062, '7af91ae6');
