const PropertiesEngine = {
    render() {
        const panel = document.getElementById('props-panel');
        if (!panel) return;

        const activeId = window.App.activeId;
        const obj = window.App.objects[activeId];

        if (!obj) {
            panel.innerHTML = `<div style="padding:20px; color:#888; text-align:center;">Объект не найден</div>`;
            return;
        }

        if (obj.isEffect) {
            this.renderEffectProperties(obj, panel);
            return;
        }

        if (activeId === 'screen-gui') {
            this.renderScreenGuiProperties(obj, panel);
            return;
        }

        const dom = obj.dom;
        if (!dom) {
            panel.innerHTML = `<div style="padding:20px; color:#ff6666; text-align:center;">DOM элемент не найден</div>`;
            return;
        }

        const posX = parseInt(dom.style.left) || 0;
        const posY = parseInt(dom.style.top) || 0;
        const sizeX = parseInt(dom.style.width) || 100;
        const sizeY = parseInt(dom.style.height) || 100;

        let color = '#ffffff';
        const bgRaw = dom.style.backgroundColor;
        if (bgRaw && bgRaw.includes('rgb')) {
            const rgb = bgRaw.match(/\d+/g);
            if (rgb) color = '#' + rgb.slice(0,3).map(x => parseInt(x).toString(16).padStart(2,'0')).join('');
        }

        const bgTransparency = obj.props?.BackgroundTransparency !== undefined ? obj.props.BackgroundTransparency : 0;
        const clipsDescendants = obj.props?.ClipsDescendants || false;
        const isTextLabel = obj.type === 'TextLabel';

        let textFields = '';
        if (isTextLabel) {
            const textVal = obj.props?.Text || 'TextLabel';
            const textSize = obj.props?.TextSize || 14;
            const textColor = obj.props?.TextColor3 || '#ffffff';
            textFields = `
                <div style="margin-bottom:12px;">
                    <label style="display:block; color:#aaa; font-size:10px; margin-bottom:4px;">TEXT</label>
                    <input type="text" value="${textVal.replace(/"/g, '&quot;')}"
                           style="width:100%; background:#333; border:1px solid #555; color:#fff; padding:6px; border-radius:4px; box-sizing:border-box;"
                           onchange="PropertiesEngine.updateTextProp('Text', this.value)">
                </div>
                <div style="margin-bottom:12px;">
                    <label style="display:block; color:#aaa; font-size:10px; margin-bottom:4px;">TEXT COLOR</label>
                    <input type="color" value="${textColor}"
                           style="width:100%; background:#333; border:1px solid #555; border-radius:4px; height:36px; cursor:pointer;"
                           onchange="PropertiesEngine.updateTextProp('TextColor3', this.value)">
                </div>
                <div style="margin-bottom:12px;">
                    <label style="display:block; color:#aaa; font-size:10px; margin-bottom:4px;">TEXT SIZE (${textSize}px)</label>
                    <div style="display:flex; gap:8px; align-items:center;">
                        <input type="range" min="6" max="120" step="1" value="${textSize}"
                               style="flex:1; cursor:pointer;"
                               oninput="PropertiesEngine.updateTextProp('TextSize', this.value); this.nextElementSibling.value = this.value">
                        <input type="number" value="${textSize}" min="6" max="120"
                               style="width:60px; background:#333; border:1px solid #555; color:#fff; padding:6px; border-radius:4px; text-align:center;"
                               onchange="PropertiesEngine.updateTextProp('TextSize', this.value); this.previousElementSibling.value = this.value">
                    </div>
                </div>
            `;
        }

        panel.innerHTML = `
            <div style="background:#2a2a2a; padding:10px; border-bottom:2px solid #00a2ff;">
                <div style="color:#00a2ff; font-weight:bold; font-size:14px;">${obj.type}</div>
                <div style="color:#888; font-size:11px; margin-top:4px;">${obj.name}</div>
            </div>
            <div style="padding:12px;">
                <div style="margin-bottom:12px;">
                    <label style="display:block; color:#aaa; font-size:10px; margin-bottom:4px;">NAME</label>
                    <input type="text" value="${obj.name}"
                           style="width:100%; background:#333; border:1px solid #555; color:#fff; padding:6px; border-radius:4px; box-sizing:border-box;"
                           onchange="PropertiesEngine.updateName(this.value)">
                </div>
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
                <div style="margin-bottom:12px;">
                    <label style="display:block; color:#aaa; font-size:10px; margin-bottom:4px;">SIZE (W, H)</label>
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
                <div style="margin-bottom:12px;">
                    <label style="display:block; color:#aaa; font-size:10px; margin-bottom:4px;">BACKGROUND COLOR</label>
                    <input type="color" value="${color}"
                           style="width:100%; background:#333; border:1px solid #555; border-radius:4px; height:36px; cursor:pointer;"
                           onchange="PropertiesEngine.updateColor(this.value)">
                </div>
                <div style="margin-bottom:12px;">
                    <label style="display:block; color:#aaa; font-size:10px; margin-bottom:4px;">BACKGROUND TRANSPARENCY (${bgTransparency})</label>
                    <div style="display:flex; gap:8px; align-items:center;">
                        <input type="range" min="0" max="1" step="0.01" value="${bgTransparency}"
                               style="flex:1; cursor:pointer;"
                               oninput="PropertiesEngine.updateBackgroundTransparency(this.value); this.previousElementSibling.innerText = 'BACKGROUND TRANSPARENCY (' + parseFloat(this.value).toFixed(2) + ')'; this.nextElementSibling.value = parseFloat(this.value).toFixed(2)">
                        <input type="number" value="${bgTransparency}" min="0" max="1" step="0.01"
                               style="width:60px; background:#333; border:1px solid #555; color:#fff; padding:6px; border-radius:4px; text-align:center;"
                               onchange="PropertiesEngine.updateBackgroundTransparency(this.value); this.previousElementSibling.value = this.value">
                    </div>
                </div>
                ${textFields}
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

    renderScreenGuiProperties(obj, panel) {
        const props = obj.props || {};
        const dom = document.getElementById('screen-gui');
        const name = obj.name || 'ScreenGui';
        let bgColor = '#000000';
        if (props.BackgroundColor3) bgColor = props.BackgroundColor3;

        const bgTransparency = props.BackgroundTransparency !== undefined ? props.BackgroundTransparency : 0;
        const clipsDescendants = props.ClipsDescendants || false;

        panel.innerHTML = `
            <div style="background:#2a2a2a; padding:10px; border-bottom:2px solid #00a2ff;">
                <div style="color:#00a2ff; font-weight:bold; font-size:14px;">ScreenGui</div>
                <div style="color:#888; font-size:11px; margin-top:4px;">${name}</div>
            </div>
            <div style="padding:12px;">
                <div style="margin-bottom:12px;">
                    <label style="display:block; color:#aaa; font-size:10px; margin-bottom:4px;">NAME</label>
                    <input type="text" value="${name}"
                           style="width:100%; background:#333; border:1px solid #555; color:#fff; padding:6px; border-radius:4px; box-sizing:border-box;"
                           onchange="PropertiesEngine.updateScreenGuiProp('name', this.value)">
                </div>
                <div style="margin-bottom:12px;">
                    <label style="display:block; color:#aaa; font-size:10px; margin-bottom:4px;">BACKGROUND COLOR</label>
                    <input type="color" value="${bgColor}"
                           style="width:100%; background:#333; border:1px solid #555; border-radius:4px; height:36px; cursor:pointer;"
                           onchange="PropertiesEngine.updateScreenGuiProp('BackgroundColor3', this.value)">
                </div>
                <div style="margin-bottom:12px;">
                    <label style="display:block; color:#aaa; font-size:10px; margin-bottom:4px;">BACKGROUND TRANSPARENCY (${bgTransparency})</label>
                    <div style="display:flex; gap:8px; align-items:center;">
                        <input type="range" min="0" max="1" step="0.01" value="${bgTransparency}"
                               style="flex:1; cursor:pointer;"
                               oninput="PropertiesEngine.updateScreenGuiProp('BackgroundTransparency', this.value); this.previousElementSibling.innerText = 'BACKGROUND TRANSPARENCY (' + parseFloat(this.value).toFixed(2) + ')'; this.nextElementSibling.value = parseFloat(this.value).toFixed(2)">
                        <input type="number" value="${bgTransparency}" min="0" max="1" step="0.01"
                               style="width:60px; background:#333; border:1px solid #555; color:#fff; padding:6px; border-radius:4px; text-align:center;"
                               onchange="PropertiesEngine.updateScreenGuiProp('BackgroundTransparency', this.value); this.previousElementSibling.value = this.value">
                    </div>
                </div>
                <div style="margin-bottom:12px;">
                    <label style="display:flex; align-items:center; cursor:pointer;">
                        <input type="checkbox" ${clipsDescendants ? 'checked' : ''}
                               style="margin-right:8px; width:16px; height:16px; cursor:pointer;"
                               onchange="PropertiesEngine.updateScreenGuiProp('ClipsDescendants', this.checked)">
                        <span style="color:#aaa; font-size:11px;">CLIPS DESCENDANTS</span>
                    </label>
                </div>
                <div style="color:#555; font-size:10px; margin-top:8px; padding-top:8px; border-top:1px solid #333;">
                    Size: 800 × 450 px
                </div>
            </div>
        `;
    },

    updateScreenGuiProp(prop, value) {
        const obj = window.App.objects['screen-gui'];
        const dom = document.getElementById('screen-gui');
        if (!obj) return;
        if (!obj.props) obj.props = {};

        if (prop === 'name') {
            obj.name = value;
            if (window.ExplorerEngine) window.ExplorerEngine.render();
        } else if (prop === 'BackgroundColor3') {
            obj.props.BackgroundColor3 = value;
            const r = parseInt(value.slice(1,3), 16);
            const g = parseInt(value.slice(3,5), 16);
            const b = parseInt(value.slice(5,7), 16);
            const t = obj.props.BackgroundTransparency || 0;
            if (dom) dom.style.backgroundColor = `rgba(${r}, ${g}, ${b}, ${1 - t})`;
        } else if (prop === 'BackgroundTransparency') {
            const t = parseFloat(value);
            obj.props.BackgroundTransparency = t;
            const c = obj.props.BackgroundColor3 || '#000000';
            const r = parseInt(c.slice(1,3), 16);
            const g = parseInt(c.slice(3,5), 16);
            const b = parseInt(c.slice(5,7), 16);
            if (dom) dom.style.backgroundColor = `rgba(${r}, ${g}, ${b}, ${1 - t})`;
        } else if (prop === 'ClipsDescendants') {
            obj.props.ClipsDescendants = value;
            if (dom) dom.style.overflow = value ? 'hidden' : 'visible';
        }
    },

    renderEffectProperties(obj, panel) {
        const props = obj.props || {};
        const parentObj = window.App.objects[obj.parent];

        let html = `
            <div style="background:#2a2a2a; padding:10px; border-bottom:2px solid #ff9900;">
                <div style="color:#ff9900; font-weight:bold; font-size:14px;">✨ ${obj.type}</div>
                <div style="color:#888; font-size:11px; margin-top:4px;">${obj.name}</div>
                <div style="color:#666; font-size:10px; margin-top:4px;">→ ${parentObj?.name || obj.parent}</div>
            </div>
            <div style="padding:12px;">
                <div style="margin-bottom:12px;">
                    <label style="display:block; color:#aaa; font-size:10px; margin-bottom:4px;">NAME</label>
                    <input type="text" value="${obj.name}"
                           style="width:100%; background:#333; border:1px solid #555; color:#fff; padding:6px; border-radius:4px; box-sizing:border-box;"
                           onchange="PropertiesEngine.updateEffectName('${obj.id}', this.value)">
                </div>
        `;

        if (obj.type === 'UICorner') {
            const radius = props.CornerRadius !== undefined ? props.CornerRadius : 8;
            html += `
                <div style="margin-bottom:12px;">
                    <label style="display:block; color:#aaa; font-size:10px; margin-bottom:4px;">CORNER RADIUS (${radius}px)</label>
                    <div style="display:flex; gap:8px; align-items:center;">
                        <input type="range" min="0" max="200" step="1" value="${radius}"
                               style="flex:1; cursor:pointer;"
                               oninput="PropertiesEngine.updateEffectProp('${obj.id}', 'CornerRadius', this.value, 'number'); this.previousElementSibling.innerText = 'CORNER RADIUS (' + this.value + 'px)'; this.nextElementSibling.value = this.value">
                        <input type="number" value="${radius}" min="0" max="200"
                               style="width:60px; background:#333; border:1px solid #555; color:#fff; padding:6px; border-radius:4px; text-align:center;"
                               onchange="PropertiesEngine.updateEffectProp('${obj.id}', 'CornerRadius', this.value, 'number'); this.previousElementSibling.value = this.value">
                    </div>
                </div>
            `;
        }

        if (obj.type === 'UIStroke') {
            const thickness = props.Thickness !== undefined ? props.Thickness : 2;
            const color = props.Color || '#ffffff';
            const mode = props.ApplyStrokeMode || 'Frame';
            html += `
                <div style="margin-bottom:12px;">
                    <label style="display:block; color:#aaa; font-size:10px; margin-bottom:8px;">APPLY STROKE MODE</label>
                    <div style="display:flex; gap:8px;">
                        <button onclick="PropertiesEngine.updateEffectProp('${obj.id}', 'ApplyStrokeMode', 'Frame', 'string'); PropertiesEngine.render()"
                                style="flex:1; padding:8px; border-radius:6px; cursor:pointer; font-size:12px; border:2px solid ${mode === 'Frame' ? '#00a2ff' : '#555'}; background:${mode === 'Frame' ? 'rgba(0,162,255,0.2)' : '#333'}; color:${mode === 'Frame' ? '#00a2ff' : '#aaa'}; transition:all 0.15s;">
                            Frame
                        </button>
                        <button onclick="PropertiesEngine.updateEffectProp('${obj.id}', 'ApplyStrokeMode', 'Text', 'string'); PropertiesEngine.render()"
                                style="flex:1; padding:8px; border-radius:6px; cursor:pointer; font-size:12px; border:2px solid ${mode === 'Text' ? '#00a2ff' : '#555'}; background:${mode === 'Text' ? 'rgba(0,162,255,0.2)' : '#333'}; color:${mode === 'Text' ? '#00a2ff' : '#aaa'}; transition:all 0.15s;">
                            Text
                        </button>
                    </div>
                    <div style="color:#666; font-size:10px; margin-top:6px;">${mode === 'Frame' ? 'Обводка контура элемента' : 'Обводка текста (TextLabel)'}</div>
                </div>
                <div style="margin-bottom:12px;">
                    <label style="display:block; color:#aaa; font-size:10px; margin-bottom:4px;">THICKNESS (${thickness}px)</label>
                    <div style="display:flex; gap:8px; align-items:center;">
                        <input type="range" min="0" max="30" step="1" value="${thickness}"
                               style="flex:1; cursor:pointer;"
                               oninput="PropertiesEngine.updateEffectProp('${obj.id}', 'Thickness', this.value, 'number'); this.previousElementSibling.innerText = 'THICKNESS (' + this.value + 'px)'; this.nextElementSibling.value = this.value">
                        <input type="number" value="${thickness}" min="0" max="30"
                               style="width:60px; background:#333; border:1px solid #555; color:#fff; padding:6px; border-radius:4px; text-align:center;"
                               onchange="PropertiesEngine.updateEffectProp('${obj.id}', 'Thickness', this.value, 'number'); this.previousElementSibling.value = this.value">
                    </div>
                </div>
                <div style="margin-bottom:12px;">
                    <label style="display:block; color:#aaa; font-size:10px; margin-bottom:4px;">STROKE COLOR</label>
                    <input type="color" value="${color}"
                           style="width:100%; background:#333; border:1px solid #555; border-radius:4px; height:36px; cursor:pointer;"
                           onchange="PropertiesEngine.updateEffectProp('${obj.id}', 'Color', this.value, 'string')">
                </div>
            `;
        }

        if (obj.type === 'UIGradient') {
            const rotation = props.Rotation || 0;
            const color1 = props.Color1 || '#ff0000';
            const color2 = props.Color2 || '#0000ff';
            html += `
                <div style="margin-bottom:12px;">
                    <label style="display:block; color:#aaa; font-size:10px; margin-bottom:4px;">ROTATION (${rotation}°)</label>
                    <div style="display:flex; gap:8px; align-items:center;">
                        <input type="range" min="0" max="360" step="1" value="${rotation}"
                               style="flex:1; cursor:pointer;"
                               oninput="PropertiesEngine.updateEffectProp('${obj.id}', 'Rotation', this.value, 'number'); this.previousElementSibling.innerText = 'ROTATION (' + this.value + '°)'; this.nextElementSibling.value = this.value">
                        <input type="number" value="${rotation}" min="0" max="360"
                               style="width:60px; background:#333; border:1px solid #555; color:#fff; padding:6px; border-radius:4px; text-align:center;"
                               onchange="PropertiesEngine.updateEffectProp('${obj.id}', 'Rotation', this.value, 'number'); this.previousElementSibling.value = this.value">
                    </div>
                </div>
                <div style="margin-bottom:12px;">
                    <label style="display:block; color:#aaa; font-size:10px; margin-bottom:4px;">COLOR 1</label>
                    <input type="color" value="${color1}"
                           style="width:100%; background:#333; border:1px solid #555; border-radius:4px; height:36px; cursor:pointer;"
                           onchange="PropertiesEngine.updateEffectProp('${obj.id}', 'Color1', this.value, 'string')">
                </div>
                <div style="margin-bottom:12px;">
                    <label style="display:block; color:#aaa; font-size:10px; margin-bottom:4px;">COLOR 2</label>
                    <input type="color" value="${color2}"
                           style="width:100%; background:#333; border:1px solid #555; border-radius:4px; height:36px; cursor:pointer;"
                           onchange="PropertiesEngine.updateEffectProp('${obj.id}', 'Color2', this.value, 'string')">
                </div>
            `;
        }

        html += `</div>`;
        panel.innerHTML = html;
    },

    updateEffectName(effectId, newName) {
        const effect = window.App.objects[effectId];
        if (effect) {
            effect.name = newName;
            if (window.ExplorerEngine) window.ExplorerEngine.render();
        }
    },

    updateEffectProp(effectId, prop, value, type) {
        const effect = window.App.objects[effectId];
        if (!effect) return;

        let newValue = value;
        if (type === 'number') newValue = parseInt(value);
        if (type === 'float') newValue = parseFloat(value);

        effect.props[prop] = newValue;

        const parentObj = window.App.objects[effect.parent];
        if (parentObj && parentObj.dom) {
            const moduleData = window.RegistryP ? window.RegistryP[effect.type] : null;
            if (moduleData && moduleData.Apply) {
                moduleData.Apply(parentObj.dom, effect.props);
            }
        }
        console.log(`✨ ${effect.type}.${prop} =`, newValue);
    },

    updateTextProp(prop, value) {
        const obj = window.App.objects[window.App.activeId];
        if (!obj || !obj.dom || obj.type !== 'TextLabel') return;
        if (!obj.props) obj.props = {};

        if (prop === 'Text') {
            obj.props.Text = value;
            obj.dom.innerText = value;
        } else if (prop === 'TextColor3') {
            obj.props.TextColor3 = value;
            obj.dom.style.color = value;
        } else if (prop === 'TextSize') {
            const sz = parseInt(value);
            obj.props.TextSize = sz;
            obj.dom.style.fontSize = sz + 'px';
        }
    },

    updateName(val) {
        const obj = window.App.objects[window.App.activeId];
        if (obj && !obj.isEffect) {
            obj.name = val;
            if (window.ExplorerEngine) window.ExplorerEngine.render();
        }
    },

    updatePosition(prop, val) {
        const obj = window.App.objects[window.App.activeId];
        if (obj && obj.dom && !obj.isEffect) {
            obj.dom.style[prop] = val + 'px';
            if (!obj.props.Position) obj.props.Position = {};
            if (prop === 'left') obj.props.Position.X = parseInt(val);
            else if (prop === 'top') obj.props.Position.Y = parseInt(val);
        }
    },

    updateSize(prop, val) {
        const obj = window.App.objects[window.App.activeId];
        if (obj && obj.dom && !obj.isEffect) {
            obj.dom.style[prop] = val + 'px';
            if (!obj.props.Size) obj.props.Size = {};
            if (prop === 'width') obj.props.Size.X = parseInt(val);
            else if (prop === 'height') obj.props.Size.Y = parseInt(val);
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
            const t = obj.props.BackgroundTransparency || 0;
            obj.dom.style.backgroundColor = `rgba(${r}, ${g}, ${b}, ${1 - t})`;
        }
    },

    updateBackgroundTransparency(val) {
        const obj = window.App.objects[window.App.activeId];
        if (obj && obj.dom && !obj.isEffect) {
            const t = parseFloat(val);
            if (!obj.props) obj.props = {};
            obj.props.BackgroundTransparency = t;
            const color = obj.props.BackgroundColor3 || '#ffffff';
            const r = parseInt(color.slice(1,3), 16);
            const g = parseInt(color.slice(3,5), 16);
            const b = parseInt(color.slice(5,7), 16);
            obj.dom.style.backgroundColor = `rgba(${r}, ${g}, ${b}, ${1 - t})`;
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