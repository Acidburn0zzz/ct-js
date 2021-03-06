type-editor.panel.view.flexrow
    .c3.tall.flexfix
        .flexfix-header
            #typetexture.panel(onclick="{changeSprite}")
                img.ohchangeme(src="{type.texture === -1? '/data/img/notexture.png' : (glob.texturemap[type.texture].src.split('?')[0] + '_prev@2.png?' + getTypeTextureRevision(type)) + getTypeTextureRevision(type)}")
                div {voc.change}
            b {voc.name}
            input#typename.wide(type="text" onchange="{wire('this.type.name')}" value="{type.name}")
            .anErrorNotice(if="{nameTaken}") {vocGlob.nametaken}
            br
            b {voc.depth}
            input#typedepth.wide(type="number" onchange="{wire('this.type.depth')}" value="{type.depth}")
        .flexfix-body
            virtual(each="{extend in libExtends}")
                label.block
                    input.wide(
                        type="checkbox"
                        value="{type.extends[extend.key] || extend.default}"
                        onchange="{wire('this.type.extends.'+ extend.key)}"
                        if="{extend.type === 'checkbox'}"
                    )
                    b {extend.name}
                    span(if="{extend.type !== 'checkbox'}") :
                    input.wide(
                        type="text"
                        value="{type.extends[extend.key] || extend.default}"
                        onchange="{wire('this.type.extends.'+ extend.key)}"
                        if="{extend.type === 'text'}"
                    )
                    input.wide(
                        type="number"
                        value="{type.extends[extend.key] || extend.default}"
                        onchange="{wire('this.type.extends.'+ extend.key)}"
                        if="{extend.type === 'number'}"
                    )
                    .dim(if="{extend.help}") {extend.help}
            br
            docs-shortcut(path="/ct.types.html" button="true" wide="true" title="{voc.learnAboutTypes}")
        .flexfix-footer
            button#typedone.wide(onclick="{typeSave}")
                i.icon.icon-confirm
                span {voc.done}
    .c9.tall.borderleft
        .tabwrap.tall(style="position: relative")
            ul.tabs.nav.nogrow.noshrink
                li(onclick="{changeTab('typeoncreate')}" class="{active: tab === 'typeoncreate'}" title="{voc.create}")
                    i.icon.icon-sun
                    span {voc.create}
                li(onclick="{changeTab('typeonstep')}" class="{active: tab === 'typeonstep'}" title="{voc.step}")
                    i.icon.icon-next
                    span {voc.step}
                li(onclick="{changeTab('typeondraw')}" class="{active: tab === 'typeondraw'}" title="{voc.draw}")
                    i.icon.icon-edit-2
                    span {voc.draw}
                li(onclick="{changeTab('typeondestroy')}" class="{active: tab === 'typeondestroy'}" title="{voc.destroy}")
                    i.icon.icon-trash
                    span {voc.destroy}
            div
                #typeoncreate.tabbed(show="{tab === 'typeoncreate'}")
                    .acer(ref="typeoncreate")
                #typeonstep.tabbed(show="{tab === 'typeonstep'}")
                    .acer(ref="typeonstep")
                #typeondraw.tabbed(show="{tab === 'typeondraw'}")
                    .acer(ref="typeondraw")
                #typeondestroy.tabbed(show="{tab === 'typeondestroy'}")
                    .acer(ref="typeondestroy")
    texture-selector(if="{selectingTexture}" onselected="{applyTexture}" oncancelled="{cancelTexture}" ref="textureselector" showempty="sure")
    script.
        const glob = require('./data/node_requires/glob');
        this.glob = glob;
        this.namespace = 'typeview';
        this.mixin(window.riotVoc);
        this.mixin(window.riotWired);

        this.getTypeTextureRevision = type => glob.texturemap[type.texture].g.lastmod;

        const libsDir = './data/ct.libs';
        const fs = require('fs-extra'),
              path = require('path');
        this.libExtends = [];
        this.refreshExtends = () => {
            this.libExtends = [];
            for (const lib in currentProject.libs) {
                fs.readJSON(path.join(libsDir, lib, 'module.json'), (err, data) => {
                    if (err) {
                        return;
                    }
                    if (data.typeExtends) {
                        this.libExtends.push(...data.typeExtends);
                    }
                    this.update();
                });
            }
        };
        window.signals.on('modulesChanged', this.refreshExtends);
        this.on('unmount', () => {
            window.signals.off('modulesChanged', this.refreshExtends);
        });
        this.refreshExtends();

        this.type = this.opts.type;
        this.tab = 'typeoncreate';
        this.changeTab = tab => e => {
            this.tab = tab;
            var editor;
            if (this.tab === 'typeonstep') {
                editor = this.typeonstep;
            } else if (this.tab === 'typeondraw') {
                editor = this.typeondraw;
            } else if (this.tab === 'typeondestroy') {
                editor = this.typeondestroy;
            } else if (this.tab === 'typeoncreate') {
                editor = this.typeoncreate;
            }
            editor.moveCursorTo(0,0);
            editor.clearSelection();
            this.focusEditor();
        };
        this.focusEditor = () => {
            if (this.tab === 'typeonstep') {
                this.typeonstep.focus();
            } else if (this.tab === 'typeondraw') {
                this.typeondraw.focus();
            } else if (this.tab === 'typeondestroy') {
                this.typeondestroy.focus();
            } else if (this.tab === 'typeoncreate') {
                this.typeoncreate.focus();
            }
        };
        window.signals.on('typesFocus', this.focusEditor);
        this.on('unmount', () => {
            window.signals.off('typesFocus', this.focusEditor);
        });

        this.on('mount', () => {
            var editorOptions = {
                mode: 'javascript'
            };
            setTimeout(() => {
                this.typeoncreate = window.setupAceEditor(this.refs.typeoncreate, editorOptions);
                this.typeonstep = window.setupAceEditor(this.refs.typeonstep, editorOptions);
                this.typeondraw = window.setupAceEditor(this.refs.typeondraw, editorOptions);
                this.typeondestroy = window.setupAceEditor(this.refs.typeondestroy, editorOptions);

                this.typeoncreate.setValue(this.type.oncreate);
                this.typeonstep.setValue(this.type.onstep);
                this.typeondraw.setValue(this.type.ondraw);
                this.typeondestroy.setValue(this.type.ondestroy);

                this.typeoncreate.getSession().on('change', (e) => {
                    this.type.oncreate = this.typeoncreate.getValue();
                });
                this.typeonstep.getSession().on('change', (e) => {
                    this.type.onstep = this.typeonstep.getValue();
                });
                this.typeondraw.getSession().on('change', (e) => {
                    this.type.ondraw = this.typeondraw.getValue();
                });
                this.typeondestroy.getSession().on('change', (e) => {
                    this.type.ondestroy = this.typeondestroy.getValue();
                });
                this.typeoncreate.moveCursorTo(0,0);
                this.typeoncreate.clearSelection();
                this.typeoncreate.focus();
            }, 0);
        });
        this.on('update', () => {
            if (window.currentProject.types.find(type =>
                this.type.name === type.name && this.type !== type
            )) {
                this.nameTaken = true;
            } else {
                this.nameTaken = false;
            }
        })
        this.changeSprite = e => {
            this.selectingTexture = true;
        };
        this.applyTexture = texture => e => {
            if (texture === -1) {
                this.type.texture = -1;
            } else {
                this.type.texture = texture.uid;
            }
            this.selectingTexture = false;
            this.parent.fillTypeMap();
            this.update();
        };
        this.cancelTexture = e => {
            this.selectingTexture = false;
            this.update();
        };
        this.typeSave = e => {
            glob.modified = true;
            this.type.lastmod = +(new Date());
            this.parent.editingType = false;
            this.parent.fillTypeMap();
            this.parent.update();
            window.signals.trigger('typesChanged');
        };
