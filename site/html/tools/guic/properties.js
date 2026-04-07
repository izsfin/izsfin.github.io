const PropertiesEngine = {
    render() {
        console.log("🔧 PropertiesEngine.render() ВЫЗВАН");
        
        const panel = document.getElementById('props-panel');
        if (!panel) return;

        const activeId = window.App.activeId;
        const obj = window.App.objects[activeId];

        if (!obj) {
            panel.innerHTML = `<div style="padding:20px; color:#888; text-align:center;">📁 Объект не найден</div>`;
            return;
        }

        // Если это эффект (модификатор) - показываем его свойства
        if (obj.isEffect) {
            this.renderEffectProperties(obj, panel);
            return;
        }

        if (activeId === 'screen-gui') {
            panel.innerHTML = `<div style="padding:20px; color:#888; text-align:center;">📁 Выберите объект в проводнике</div>`;
            return;
        }

        const dom = obj.dom;
        if (!dom) {
            panel.innerHTML = `<div style="padding:20px; color:#ff6666; text-align:center;">❌ DOM элемент не найден<br><span style="font-size:10px;">Объект: ${obj.type}</span></div>`;
            return;
        }

        // Получаем значения
        const posX = parseInt(dom.style.left) || 0;
        const posY = parseInt(dom.style.top) || 0;
        const sizeX = parseInt(dom.style.width) || 100;
        const sizeY = parseInt(dom.style.height) || 100;
        
        let color = dom.style.backgroundColor;
        if (!color || color === '' || color === 'rgba(0, 0, 0, 0)') {
            color = '#ffffff';
        }
        if (color && color.includes('rgb')) {
            const rgb = color.match(/\d+/g);
            if (rgb) {
                color = '#' + rgb.slice(0,3).map(x => parseInt(x).toString(16).padStart(2,'0')).join('');
            }
        }
        
        const bgTransparency = obj.props?.BackgroundTransparency !== undefined ? 
            obj.props.BackgroundTransparency : 0;
        const clipsDescendants = obj.props?.ClipsDescendants || false;

        panel.innerHTML = `
            <div style="background:#2a2a2a; padding:10px; border-bottom:2px solid #00a2ff;">
                <div style="color:#00a2ff; font-weight:bold; font-size:14px;">${obj.type}</div>
                <div style="color:#888; font-size:11px; margin-top:4px;">${obj.name}</div>
            </div>
            <div style="padding:12px;">
                <!-- NAME -->
                <div style="margin-bottom:12px;">
                    <label style="display:block; color:#aaa; font-size:10px; margin-bottom:4px;">NAME</label>
                    <input type="text" value="${obj.name}" 
                           style="width:100%; background:#333; border:1px solid #555; color:#fff; padding:6px; border-radius:4px; box-sizing:border-box;"
                           onchange="PropertiesEngine.updateName(this.value)">
                </div>

                <!-- POSITION (X, Y) -->
                <div style="margin-bottom:12px;">
                    <label style="display:block; color:#aaa; font-size:10px; margin-bottom:4px;">POSITION (X, Y)</label>
                    <div style="display:flex; gap:8px;">
                        <input type="number" value="${posX}" placeholder="X"
                               style="flex:1; background:#333; border:1px solid #555; color:#fff; padding:6px; border-radius:4px;"
                               onchange="PropertiesEngine.updatePosition('left', this.value)">
                        <span style="color:#555; align-self:center;">,</span>
                        <input type="number" value="${posY}" placeholder="Y"
                               style="flex:1; background:#333; border:1px solid #555; color:#fff; padding:6px; border-radius:4px;"
                               onchange="PropertiesEngine.updatePosition('top', this.value)">
                    </div>
                </div>

                <!-- SIZE (X, Y) -->
                <div style="margin-bottom:12px;">
                    <label style="display:block; color:#aaa; font-size:10px; margin-bottom:4px;">SIZE (X, Y)</label>
                    <div style="display:flex; gap:8px;">
                        <input type="number" value="${sizeX}" placeholder="Width"
                               style="flex:1; background:#333; border:1px solid #555; color:#fff; padding:6px; border-radius:4px;"
                               onchange="PropertiesEngine.updateSize('width', this.value)">
                        <span style="color:#555; align-self:center;">,</span>
                        <input type="number" value="${sizeY}" placeholder="Height"
                               style="flex:1; background:#333; border:1px solid #555; color:#fff; padding:6px; border-radius:4px;"
                               onchange="PropertiesEngine.updateSize('height', this.value)">
                    </div>
                </div>

                <!-- COLOR -->
                <div style="margin-bottom:12px;">
                    <label style="display:block; color:#aaa; font-size:10px; margin-bottom:4px;">COLOR</label>
                    <input type="color" value="${color}" 
                           style="width:100%; background:#333; border:1px solid #555; border-radius:4px; height:36px; cursor:pointer;"
                           onchange="PropertiesEngine.updateColor(this.value)">
                </div>

                <!-- BACKGROUND TRANSPARENCY -->
                <div style="margin-bottom:12px;">
                    <label style="display:block; color:#aaa; font-size:10px; margin-bottom:4px;">BACKGROUND TRANSPARENCY (${bgTransparency})</label>
                    <input type="range" min="0" max="1" step="0.01" value="${bgTransparency}" 
                           style="width:100%; cursor:pointer;"
                           oninput="PropertiesEngine.updateBackgroundTransparency(this.value); this.previousElementSibling.innerText = 'BACKGROUND TRANSPARENCY (' + this.value + ')'">
                </div>

                <!-- CLIPS DESCENDANTS -->
                <div style="margin-bottom:12px;">
                    <label style="display:flex; align-items:center; cursor:pointer;">
                        <input type="checkbox" ${clipsDescendants ? 'checked' : ''} 
                               style="margin-right:8px; width:16px; height:16px; cursor:pointer;"
                               onchange="PropertiesEngine.updateClipsDescendants(this.checked)">
                        <span style="color:#aaa; font-size:11px;">CLIPS DESCENDANTS</span>
                    </label>
                </div>
            </div>
        `;
    },

    // Рендер свойств для модификаторов (эффектов)
    renderEffectProperties(obj, panel) {
        const props = obj.props || {};
        const parentObj = window.App.objects[obj.parent];
        
        let html = `
            <div style="background:#2a2a2a; padding:10px; border-bottom:2px solid #ff9900;">
                <div style="color:#ff9900; font-weight:bold; font-size:14px;">✨ ${obj.type} (Модификатор)</div>
                <div style="color:#888; font-size:11px; margin-top:4px;">${obj.name}</div>
                <div style="color:#666; font-size:10px; margin-top:4px;">Применён к: ${parentObj?.name || obj.parent}</div>
            </div>
            <div style="padding:12px;">
                <!-- NAME -->
                <div style="margin-bottom:12px;">
                    <label style="display:block; color:#aaa; font-size:10px; margin-bottom:4px;">NAME</label>
                    <input type="text" value="${obj.name}" 
                           style="width:100%; background:#333; border:1px solid #555; color:#fff; padding:6px; border-radius:4px; box-sizing:border-box;"
                           onchange="PropertiesEngine.updateEffectName('${obj.id}', this.value)">
                </div>
        `;

        // Свойства для UICorner
        if (obj.type === 'UICorner') {
            const radius = props.CornerRadius || 8;
            html += `
                <div style="margin-bottom:12px;">
                    <label style="display:block; color:#aaa; font-size:10px; margin-bottom:4px;">CORNER RADIUS (${radius}px)</label>
                    <input type="range" min="0" max="50" step="1" value="${radius}" 
                           style="width:100%; cursor:pointer;"
                           oninput="PropertiesEngine.updateEffectProp('${obj.id}', 'CornerRadius', this.value, 'range'); this.previousElementSibling.innerText = 'CORNER RADIUS (' + this.value + 'px)'">
                    <div style="display:flex; gap:8px; margin-top:8px;">
                        <input type="number" value="${radius}" min="0" max="50"
                               style="flex:1; background:#333; border:1px solid #555; color:#fff; padding:6px; border-radius:4px;"
                               onchange="PropertiesEngine.updateEffectProp('${obj.id}', 'CornerRadius', this.value, 'number')">
                        <span style="color:#888; font-size:11px;">px</span>
                    </div>
                </div>
            `;
        }

        // Свойства для UIStroke
        if (obj.type === 'UIStroke') {
            const thickness = props.Thickness || 2;
            const color = props.Color || '#ffffff';
            html += `
                <div style="margin-bottom:12px;">
                    <label style="display:block; color:#aaa; font-size:10px; margin-bottom:4px;">THICKNESS (${thickness}px)</label>
                    <input type="range" min="0" max="20" step="1" value="${thickness}" 
                           style="width:100%; cursor:pointer;"
                           oninput="PropertiesEngine.updateEffectProp('${obj.id}', 'Thickness', this.value, 'range'); this.previousElementSibling.innerText = 'THICKNESS (' + this.value + 'px)'">
                    <div style="margin-top:8px;">
                        <input type="number" value="${thickness}" min="0" max="20"
                               style="width:100%; background:#333; border:1px solid #555; color:#fff; padding:6px; border-radius:4px;"
                               onchange="PropertiesEngine.updateEffectProp('${obj.id}', 'Thickness', this.value, 'number')">
                    </div>
                </div>
                <div style="margin-bottom:12px;">
                    <label style="display:block; color:#aaa; font-size:10px; margin-bottom:4px;">STROKE COLOR</label>
                    <input type="color" value="${color}" 
                           style="width:100%; background:#333; border:1px solid #555; border-radius:4px; height:36px; cursor:pointer;"
                           onchange="PropertiesEngine.updateEffectProp('${obj.id}', 'Color', this.value, 'color')">
                </div>
            `;
        }

        // Свойства для UIGradient
if (obj.type === 'UIGradient') {
    const rotation = props.Rotation || 0;
    const colors = props.Colors || ['#ff0000', '#0000ff'];
    
    html += `
        <div style="margin-bottom:12px;">
            <label style="display:block; color:#aaa; font-size:10px; margin-bottom:4px;">ROTATION (${rotation}°)</label>
            <input type="range" min="0" max="360" step="1" value="${rotation}" 
                   style="width:100%; cursor:pointer;"
                   oninput="PropertiesEngine.updateEffectProp('${obj.id}', 'Rotation', this.value, 'range'); this.previousElementSibling.innerText = 'ROTATION (' + this.value + '°)'">
            <div style="margin-top:8px;">
                <input type="number" value="${rotation}" min="0" max="360"
                       style="width:100%; background:#333; border:1px solid #555; color:#fff; padding:6px; border-radius:4px;"
                       onchange="PropertiesEngine.updateEffectProp('${obj.id}', 'Rotation', this.value, 'number')">
            </div>
        </div>
        <div style="margin-bottom:12px;">
            <label style="display:block; color:#aaa; font-size:10px; margin-bottom:8px;">COLORS</label>
            <div id="gradient-colors-${obj.id}">
    `;
    
    colors.forEach((color, idx) => {
        html += `
            <div style="display:flex; gap:8px; margin-bottom:8px;">
                <input type="color" value="${color}" 
                       style="flex:1; background:#333; border:1px solid #555; border-radius:4px; height:36px; cursor:pointer;"
                       onchange="PropertiesEngine.updateGradientColor('${obj.id}', ${idx}, this.value)">
                <button style="background:#ff4444; border:none; color:white; width:36px; border-radius:4px; cursor:pointer; font-size:16px;"
                        onclick="PropertiesEngine.removeGradientColor('${obj.id}', ${idx})">−</button>
            </div>
        `;
    });
    
    html += `
            </div>
            <button style="width:100%; background:#3a3a3a; border:1px solid #555; color:#fff; padding:6px; border-radius:4px; cursor:pointer; margin-top:8px;"
                    onclick="PropertiesEngine.addGradientColor('${obj.id}')">+ Add Color</button>
        </div>
    `;
}

html += `</div>`;
panel.innerHTML = html;
    },

    // Добавьте эти методы после renderEffectProperties

addGradientColor(effectId) {
    const effect = window.App.objects[effectId];
    if (effect && effect.props) {
        if (!effect.props.Colors) {
            effect.props.Colors = ['#ff0000', '#0000ff'];
        }
        effect.props.Colors.push('#888888');
        this.updateEffectProp(effectId, 'Colors', effect.props.Colors, 'colors');
        this.render();
    }
},

removeGradientColor(effectId, index) {
    const effect = window.App.objects[effectId];
    if (effect && effect.props && effect.props.Colors && effect.props.Colors.length > 2) {
        effect.props.Colors.splice(index, 1);
        this.updateEffectProp(effectId, 'Colors', effect.props.Colors, 'colors');
        this.render();
    } else {
        alert("❌ Должно быть минимум 2 цвета!");
    }
},

updateGradientColor(effectId, index, color) {
    const effect = window.App.objects[effectId];
    if (effect && effect.props && effect.props.Colors) {
        effect.props.Colors[index] = color;
        this.updateEffectProp(effectId, 'Colors', effect.props.Colors, 'colors');
    }
},
    updateEffectName(effectId, newName) {
        const effect = window.App.objects[effectId];
        if (effect) {
            effect.name = newName;
            if (window.ExplorerEngine) window.ExplorerEngine.render();
            this.render();
        }
    },

    updateEffectProp(effectId, prop, value, type) {
    const effect = window.App.objects[effectId];
    if (!effect) return;
    
    let newValue = value;
    if (type === 'number' || type === 'range') {
        newValue = parseInt(value);
    }
    if (type === 'colors') {
        newValue = value; // Массив цветов
    }
    
    effect.props[prop] = newValue;
    
    // Применяем эффект к родительскому DOM
    const parentObj = window.App.objects[effect.parent];
    if (parentObj && parentObj.dom) {
        const moduleData = window.RegistryP ? window.RegistryP[effect.type] : null;
        if (moduleData && moduleData.Apply) {
            moduleData.Apply(parentObj.dom, effect.props);
        }
    }
    
    console.log(`✨ ${effect.type} ${prop} =`, newValue);
},

    updateName(val) {
        const obj = window.App.objects[window.App.activeId];
        if (obj && !obj.isEffect) {
            obj.name = val;
            if (window.ExplorerEngine) window.ExplorerEngine.render();
            this.render();
        }
    },

    updatePosition(prop, val) {
        const obj = window.App.objects[window.App.activeId];
        if (obj && obj.dom && !obj.isEffect) {
            obj.dom.style[prop] = val + 'px';
            if (!obj.props.Position) obj.props.Position = {};
            if (prop === 'left') {
                obj.props.Position.X = parseInt(val);
            } else if (prop === 'top') {
                obj.props.Position.Y = parseInt(val);
            }
        }
    },

    updateSize(prop, val) {
        const obj = window.App.objects[window.App.activeId];
        if (obj && obj.dom && !obj.isEffect) {
            obj.dom.style[prop] = val + 'px';
            if (!obj.props.Size) obj.props.Size = {};
            if (prop === 'width') {
                obj.props.Size.X = parseInt(val);
            } else if (prop === 'height') {
                obj.props.Size.Y = parseInt(val);
            }
        }
    },

    updateColor(val) {
        const obj = window.App.objects[window.App.activeId];
        if (obj && obj.dom && !obj.isEffect) {
            if (!obj.props) obj.props = {};
            obj.props.BackgroundColor3 = val;
            const r = parseInt(val.slice(1,3), 16);
            const g = parseInt(val.slice(3,5), 16);
            const b = parseInt(val.slice(5,7), 16);
            const transparency = obj.props.BackgroundTransparency || 0;
            obj.dom.style.backgroundColor = `rgba(${r}, ${g}, ${b}, ${1 - transparency})`;
        }
    },

    updateBackgroundTransparency(val) {
        const obj = window.App.objects[window.App.activeId];
        if (obj && obj.dom && !obj.isEffect) {
            const floatVal = parseFloat(val);
            if (!obj.props) obj.props = {};
            obj.props.BackgroundTransparency = floatVal;
            
            const color = obj.props.BackgroundColor3 || '#ffffff';
            const r = parseInt(color.slice(1,3), 16);
            const g = parseInt(color.slice(3,5), 16);
            const b = parseInt(color.slice(5,7), 16);
            obj.dom.style.backgroundColor = `rgba(${r}, ${g}, ${b}, ${1 - floatVal})`;
        }
    },

    updateClipsDescendants(val) {
        const obj = window.App.objects[window.App.activeId];
        if (obj && obj.dom && !obj.isEffect) {
            if (!obj.props) obj.props = {};
            obj.props.ClipsDescendants = val;
            obj.dom.style.overflow = val ? 'hidden' : 'visible';
        }
    }
};

window.PropertiesEngine = PropertiesEngine;