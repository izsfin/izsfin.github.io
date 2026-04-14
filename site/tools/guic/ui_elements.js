const UIElements = {
    create(type, parentId = App.activeId) {
        App.objCount++;
        const id = 'obj-' + App.objCount;
        
        const moduleData = window.Registry ? window.Registry[type] : null;
        const isMod = (type === 'UICorner' || type === 'UIStroke' || type === 'UIGradient');
        
        let el = null;
        
        let defaultProps = {
            Size: { X: 100, Y: 100 },
            Position: { X: 50, Y: 50 },
            BackgroundColor3: '#ffffff',
            BackgroundTransparency: 0,
            ClipsDescendants: false
        };

        if (moduleData && moduleData.ElementProperties) {
            defaultProps = JSON.parse(JSON.stringify(moduleData.ElementProperties));
        }

        if (!isMod) {
            el = document.createElement('div');
            el.id = id;
            el.className = 'rbx-obj';
            
            el.style.position = 'absolute';
            el.style.width = defaultProps.Size.X + 'px';
            el.style.height = defaultProps.Size.Y + 'px';
            el.style.left = defaultProps.Position.X + 'px';
            el.style.top = defaultProps.Position.Y + 'px';
            el.style.cursor = 'pointer';
            el.style.boxSizing = 'border-box';
            el.style.overflow = defaultProps.ClipsDescendants ? 'hidden' : 'visible';
            
            const color = defaultProps.BackgroundColor3 || '#ffffff';
            const r = parseInt(color.slice(1,3), 16);
            const g = parseInt(color.slice(3,5), 16);
            const b = parseInt(color.slice(5,7), 16);
            el.style.backgroundColor = `rgba(${r}, ${g}, ${b}, ${1 - (defaultProps.BackgroundTransparency || 0)})`;
            
            if (type === 'Frame') {
                el.style.border = `${defaultProps.BorderSizePixel || 1}px solid #000000`;
            }

            const parentObj = App.objects[parentId];
            const parentDom = parentObj?.dom || document.getElementById('screen-gui');
            parentDom.appendChild(el);

            el.onmousedown = (e) => {
                e.stopPropagation();
                e.preventDefault();
                ExplorerEngine.select(id);
                if (window.SnappingEngine) {
                    window.SnappingEngine.startDrag(e, id);
                }
            };
        }

        App.objects[id] = {
            type: type,
            name: `${type}_${App.objCount}`,
            parent: parentId,
            dom: el,
            props: defaultProps,
            effects: []
        };

        if (moduleData && moduleData.Init) { moduleData.Init(el, App.objects[id].props); }
        if (isMod && moduleData.Apply) {
         const parentObj = App.objects[parentId];
         if (parentObj && parentObj.dom) { moduleData.Apply(parentObj.dom, App.objects[id].props); } }
             

        if (window.ExplorerEngine) {
            window.ExplorerEngine.render();
            window.ExplorerEngine.select(id);
        }

    },

    delete(id) {
        if (id === 'screen-gui' || !App.objects[id]) return;

        const obj = App.objects[id];

        // Если это эффект — сбрасываем CSS на родителе
        if (obj.isEffect) {
            const parentObj = App.objects[obj.parent];
            if (parentObj && parentObj.dom) {
                if (obj.type === 'UICorner') {
                    parentObj.dom.style.borderRadius = '';
                } else if (obj.type === 'UIStroke') {
                    parentObj.dom.style.outline = '';
                    parentObj.dom.style.outlineOffset = '';
                } else if (obj.type === 'UIGradient') {
                    const bg = parentObj.props?.BackgroundColor3 || '#ffffff';
                    const t = parentObj.props?.BackgroundTransparency || 0;
                    const r = parseInt(bg.slice(1,3), 16);
                    const g = parseInt(bg.slice(3,5), 16);
                    const b = parseInt(bg.slice(5,7), 16);
                    parentObj.dom.style.background = '';
                    parentObj.dom.style.backgroundColor = `rgba(${r}, ${g}, ${b}, ${1 - t})`;
                }
                if (parentObj.effects) {
                    parentObj.effects = parentObj.effects.filter(e => e.id !== id);
                }
            }
        }

        if (obj.dom) {
            obj.dom.remove();
        }

        Object.keys(App.objects).forEach(key => {
            if (App.objects[key].parent === id) {
                this.delete(key);
            }
        });

        delete App.objects[id];
        App.activeId = 'screen-gui';
        
        if (window.ExplorerEngine) {
            window.ExplorerEngine.render();
            window.ExplorerEngine.select('screen-gui');
        }
        if (window.PropertiesEngine) window.PropertiesEngine.render();
    }
};

window.UIElements = UIElements;