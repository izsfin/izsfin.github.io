const ExplorerEngine = {
    render() {
        const root = document.getElementById('explorer-root');
        if (!root) return;
        root.innerHTML = '';

        const build = (pid, depth) => {
            const children = Object.keys(App.objects).filter(k => App.objects[k].parent === pid);
            
            children.forEach(id => {
                const obj = App.objects[id];
                const item = document.createElement('div');
                item.className = `explorer-item ${App.activeId === id ? 'selected' : ''}`;
                item.setAttribute('data-id', id);
                item.setAttribute('data-parent', pid || 'null');
                item.setAttribute('data-depth', depth);
                
                const paddingLeft = 8 + (depth * 16);
                item.style.padding = "6px 8px";
                item.style.paddingLeft = paddingLeft + "px";
                item.style.cursor = "pointer";
                item.style.display = "flex";
                item.style.alignItems = "center";
                item.style.justifyContent = "space-between";
                item.style.borderBottom = "1px solid #2a2a2a";
                item.style.backgroundColor = App.activeId === id ? "#1a3a5a" : "transparent";
                
                // Drag & Drop опционально (можно добавить позже)
                
                let branchIcon = '';
                if (depth > 0) {
                    branchIcon = '└─ ';
                }
                
                const icon = this.getIcon(obj.type);
                const nameSpan = document.createElement('span');
                nameSpan.id = `exp-name-${id}`;
                nameSpan.innerHTML = `${branchIcon}${icon} ${obj.name}`;
                nameSpan.style.flex = "1";
                nameSpan.style.fontSize = "12px";
                nameSpan.style.overflow = "hidden";
                nameSpan.style.textOverflow = "ellipsis";
                nameSpan.style.whiteSpace = "nowrap";
                item.appendChild(nameSpan);

                const isContainer = !obj.isEffect && (obj.type === 'ScreenGui' || !['UICorner', 'UIStroke', 'UIGradient'].includes(obj.type));
                
                if (isContainer) {
                    const s = document.createElement('select');
                    s.className = 'add-btn';
                    s.style.marginLeft = "8px";
                    s.style.background = "#3a3a3a";
                    s.style.border = "1px solid #555";
                    s.style.color = "#fff";
                    s.style.borderRadius = "3px";
                    s.style.fontSize = "10px";
                    s.style.padding = "2px 6px";
                    s.style.cursor = "pointer";
                    s.style.flexShrink = "0";
                    
                    let options = '<option value="">+</option>';
                    
                    if (window.Registry && Object.keys(window.Registry).length > 0) {
                        options += '<optgroup label="Elements">';
                        Object.keys(window.Registry).forEach(type => {
                            options += `<option value="UIE:${type}">${type}</option>`;
                        });
                        options += '</optgroup>';
                    }
                    
                    if (window.RegistryP && Object.keys(window.RegistryP).length > 0) {
                        options += '<optgroup label="Modifiers">';
                        Object.keys(window.RegistryP).forEach(type => {
                            options += `<option value="UIP:${type}">${type}</option>`;
                        });
                        options += '</optgroup>';
                    }
                    
                    s.innerHTML = options;
                    
                    s.onchange = (e) => {
                        const val = e.target.value;
                        if (!val) return;
                        const [category, type] = val.split(':');
                        if (category === 'UIE' && window.UIElements) {
                            window.UIElements.create(type, id);
                        } else if (category === 'UIP' && typeof window.addEffect === 'function') {
                            window.App.activeId = id; 
                            window.addEffect(type);
                        }
                        e.target.value = '';
                    };
                    item.appendChild(s);
                }

                item.onclick = (e) => {
                    e.stopPropagation();
                    this.select(id);
                };
                item.ondblclick = () => this.renamePrompt(id);
                root.appendChild(item);
                build(id, depth + 1);
            });
        };
        
        build(null, 0);
    },

    select(id) {
        if (window.App.activeId === id) return; // Если тот же объект - не делаем ничего
        
        window.App.activeId = id;
        console.log("Explorer: Selected", id);
        
        // Визуальное выделение
        document.querySelectorAll('.rbx-obj').forEach(el => {
            el.classList.remove('selected-visual');
        });
        
        const selectedObj = window.App.objects[id];
        if (selectedObj && selectedObj.dom && id !== 'screen-gui') {
            selectedObj.dom.classList.add('selected-visual');
        }
        
        this.render(); // Перерисовываем только при смене выбора
        
        if (window.PropertiesEngine) {
            window.PropertiesEngine.render(); // Обновляем Properties только при смене выбора
        }
    },

    renamePrompt(id) {
        const span = document.getElementById(`exp-name-${id}`);
        if (!span) return;
        
        const originalText = span.innerHTML;
        const match = originalText.match(/^([^a-zA-Zа-яА-Я0-9]*[─└─ ]*[📦📝🔘🖼️📜🖥️⭕✏️🎨📄]*\s*)/);
        const prefix = match ? match[0] : '';
        const oldName = App.objects[id].name;
        
        const input = document.createElement('input');
        input.type = 'text';
        input.value = oldName;
        input.className = 'explorer-rename-input';
        input.style.background = '#333';
        input.style.border = '1px solid #00a2ff';
        input.style.color = '#fff';
        input.style.padding = '2px 6px';
        input.style.borderRadius = '3px';
        input.style.fontSize = '12px';
        input.style.width = '120px';
        
        span.innerHTML = '';
        span.appendChild(input);
        input.focus();
        input.select();
        
        const save = () => {
            const newName = input.value.trim() || App.objects[id].type;
            App.objects[id].name = newName;
            this.render();
        };

        input.onblur = save;
        input.onkeydown = (e) => { 
            if (e.key === 'Enter') save();
            if (e.key === 'Escape') this.render();
        };
    },

    getIcon(type) {
        const icons = {
            'ScreenGui': '🖥️',
            'Frame': '📦',
            'TextLabel': '📝',
            'TextButton': '🔘',
            'ImageLabel': '🖼️',
            'ScrollingFrame': '📜',
            'UICorner': '⭕',
            'UIStroke': '✏️',
            'UIGradient': '🎨'
        };
        return icons[type] || '📄';
    }
};

window.ExplorerEngine = ExplorerEngine;