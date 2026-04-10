const ExportEngine = {
    generateLua() {
        let code = "--[[ § Exported by ML Expert Editor v1.1 § ]]\n\n";
        const varMap = {}; // Маппинг id -> имя переменной

        // Сначала создаём ScreenGui
        code += `local ScreenGui = Instance.new("ScreenGui")\n`;
        code += `ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")\n\n`;
        varMap['screen-gui'] = 'ScreenGui';

        // Генерируем код для всех объектов
        Object.keys(App.objects).forEach(id => {
            if (id === 'screen-gui') return;
            
            const obj = App.objects[id];
            if (obj.isEffect) return; // Эффекты обработаем отдельно
            
            // Используем имя объекта вместо obj_N
            const safeName = obj.name.replace(/[^a-zA-Z0-9_]/g, '_');
            const varName = safeName || id.replace(/-/g, "_");
            varMap[id] = varName;

            code += `local ${varName} = Instance.new("${obj.type}")\n`;
            code += `${varName}.Name = "${obj.name}"\n`;

            const data = obj.props || {};

            Object.keys(data).forEach(prop => {
                const internalFields = ['type', 'name', 'parent', 'props', 'id', 'dom', 'effects'];
                if (internalFields.includes(prop)) return;

                let value = data[prop];
                if (value === undefined || value === null) return;

                // 🔥 1. Color3 HEX
                if (prop.includes('Color3') && typeof value === 'string' && value.startsWith('#')) {
                    const r = parseInt(value.slice(1, 3), 16);
                    const g = parseInt(value.slice(3, 5), 16);
                    const b = parseInt(value.slice(5, 7), 16);
                    code += `${varName}.${prop} = Color3.fromRGB(${r}, ${g}, ${b})\n`;
                }

                // 🔥 2. Size / Position (объект с X, Y)
                else if ((prop === 'Size' || prop === 'Position') && typeof value === 'object' && value.X !== undefined) {
                    const ox = value.X || 0;
                    const oy = value.Y || 0;
                    code += `${varName}.${prop} = UDim2.new(0, ${ox}, 0, ${oy})\n`;
                }

                // 🔥 3. ЛЮБОЙ UDim2 в строке (CanvasSize фикс)
                else if (typeof value === 'string' && value.includes(',')) {
                    const parts = value.split(',').map(v => Number(v.trim()));

                    if (parts.length === 4 && parts.every(v => !isNaN(v))) {
                        code += `${varName}.${prop} = UDim2.new(${parts.join(', ')})\n`;
                    } else {
                        code += `${varName}.${prop} = "${value}"\n`;
                    }
                }

                // 🔥 4. Image (пропускаем пустые или добавляем Base64)
                else if (prop === 'Image' && typeof value === 'string') {
                    if (value && value.trim() !== '') {
                        code += `${varName}.${prop} = "${value}"\n`;
                    }
                }

                // 🔥 5. обычные строки
                else if (typeof value === 'string') {
                    code += `${varName}.${prop} = "${value}"\n`;
                }

                // 🔥 6. числа / bool
                else if (typeof value === 'number' || typeof value === 'boolean') {
                    code += `${varName}.${prop} = ${value}\n`;
                }
            });

            // Parent
            if (obj.parent) {
                const pVar = varMap[obj.parent] || obj.parent.replace(/-/g, "_");
                code += `${varName}.Parent = ${pVar}\n`;
            }

            // Эффекты (UICorner, UIStroke, UIGradient)
            if (obj.effects && obj.effects.length > 0) {
                obj.effects.forEach(effect => {
                    const effectObj = App.objects[effect.id];
                    if (!effectObj) return;
                    
                    const effectVarName = `${varName}_${effectObj.type}`;
                    code += `\nlocal ${effectVarName} = Instance.new("${effectObj.type}")\n`;
                    code += `${effectVarName}.Name = "${effectObj.name}"\n`;
                    
                    const effectProps = effectObj.props || {};
                    Object.keys(effectProps).forEach(eProp => {
                        let eValue = effectProps[eProp];
                        if (eValue === undefined || eValue === null) return;
                        
                        if (eProp === 'CornerRadius' && effectObj.type === 'UICorner') {
                            code += `${effectVarName}.${eProp} = UDim.new(0, ${eValue})\n`;
                        } else if (eProp === 'Color' && typeof eValue === 'string' && eValue.startsWith('#')) {
                            const r = parseInt(eValue.slice(1, 3), 16);
                            const g = parseInt(eValue.slice(3, 5), 16);
                            const b = parseInt(eValue.slice(5, 7), 16);
                            code += `${effectVarName}.${eProp} = Color3.fromRGB(${r}, ${g}, ${b})\n`;
                        } else if ((eProp === 'Color1' || eProp === 'Color2') && typeof eValue === 'string' && eValue.startsWith('#')) {
                            const r = parseInt(eValue.slice(1, 3), 16);
                            const g = parseInt(eValue.slice(3, 5), 16);
                            const b = parseInt(eValue.slice(5, 7), 16);
                            // UIGradient использует ColorSequence, но для простоты выводим как Color3
                            code += `${effectVarName}.${eProp} = Color3.fromRGB(${r}, ${g}, ${b})\n`;
                        } else if (typeof eValue === 'number' || typeof eValue === 'boolean') {
                            code += `${effectVarName}.${eProp} = ${eValue}\n`;
                        } else if (typeof eValue === 'string') {
                            code += `${effectVarName}.${eProp} = "${eValue}"\n`;
                        }
                    });
                    
                    code += `${effectVarName}.Parent = ${varName}\n`;
                });
            }

            code += "\n";
        });

        this.showPopup(code);
    },

    showPopup(code) {
        const htmlContent = `
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <title>ML UI Creator - Export</title>
            <style>
                body {
                    margin: 0; padding: 0;
                    background-color: #1a1a1a;
                    background-image: radial-gradient(#333 1px, transparent 1px);
                    background-size: 20px 20px;
                    color: #e0e0e0;
                    font-family: 'Consolas', 'Monaco', monospace;
                    display: flex; flex-direction: column;
                    height: 100vh; overflow: hidden;
                }
                .header {
                    background: rgba(0, 0, 0, 0.6);
                    padding: 10px 20px;
                    border-bottom: 1px solid #333;
                    backdrop-filter: blur(5px);
                    font-size: 14px;
                }
                .container {
                    position: relative;
                    flex-grow: 1;
                    margin: 20px;
                    display: flex;
                    flex-direction: column;
                }
                pre {
                    margin: 0; 
                    padding: 20px;
                    background: rgba(30, 30, 30, 0.5);
                    border: 1px solid rgba(68, 68, 68, 0.3);
                    border-radius: 8px;
                    overflow: auto;
                    line-height: 1.5;
                    flex-grow: 1;
                    backdrop-filter: blur(5px); 
                    box-shadow: 0 10px 30px rgba(0,0,0,0.5);
                    white-space: pre-wrap;
                    word-break: break-all;
                    font-size: 14px;
                }
                .copy-btn {
                    position: absolute;
                    top: 10px; right: 10px;
                    background: #444;
                    border: 1px solid #666;
                    color: #fff;
                    padding: 8px 18px;
                    border-radius: 6px;
                    cursor: pointer;
                    font-size: 13px;
                    z-index: 100;
                    transition: 0.2s;
                }
                .copy-btn:hover { background: #00a2ff; border-color: #00a2ff; }
                ::-webkit-scrollbar { width: 8px; }
                ::-webkit-scrollbar-thumb { background: #444; border-radius: 4px; }
            </style>
        </head>
        <body>
            <div class="header">ML Expert Editor v1.1 (lua.mle)</div>
            <div class="container">
                <button class="copy-btn" id="copyBtn">Copy Code</button>
                <pre id="code-block">${code}</pre>
            </div>
            <script>
                document.getElementById('copyBtn').addEventListener('click', function() {
                    const code = document.getElementById('code-block').textContent;
                    navigator.clipboard.writeText(code).then(() => {
                        this.innerText = 'Copied!';
                        this.style.background = '#28a745';
                        setTimeout(() => {
                            this.innerText = 'Copy Code';
                            this.style.background = '#444';
                        }, 2000);
                    });
                });
            </script>
        </body>
        </html>`;

        const blob = new Blob([htmlContent], { type: 'text/html' });
        window.open(URL.createObjectURL(blob), "_blank");
    }
};