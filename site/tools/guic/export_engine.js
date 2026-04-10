const ExportEngine = {
generateLua() {
        let code = "--[[ § Exported by ML Expert Editor v1.1 § ]]\n\n";
        const varMap = {}; 

        // 1. Сначала подготавливаем имя для ScreenGui из данных приложения
        const rootObj = App.objects['screen-gui'];
        const rootSafeName = rootObj.name.replace(/[^a-zA-Z0-9_]/g, '_') || "ScreenGui";
        varMap['screen-gui'] = rootSafeName;

        // 2. Генерируем код создания ScreenGui (используем имя из редактора)
        code += `local ${rootSafeName} = Instance.new("ScreenGui")\n`;
        code += `${rootSafeName}.Name = "${rootObj.name}"\n`;
        code += `${rootSafeName}.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")\n\n`;

        // 3. Основной цикл по всем объектам
        Object.keys(App.objects).forEach(id => {
            const obj = App.objects[id];
            if (obj.isEffect) return;

            let varName;
            
            if (id === 'screen-gui') {
                // Для ScreenGui используем уже созданную выше переменную
                varName = rootSafeName;
            } else {
                // Создаем переменные для остальных объектов (Frame, TextLabel и т.д.)
                const safeName = obj.name.replace(/[^a-zA-Z0-9_]/g, '_');
                varName = safeName || id.replace(/-/g, "_");
                varMap[id] = varName;

                code += `local ${varName} = Instance.new("${obj.type}")\n`;
                code += `${varName}.Name = "${obj.name}"\n`;
            }

            const data = obj.props || {};

            // 4. Обработка свойств
            Object.keys(data).forEach(prop => {
                const internalFields = ['type', 'name', 'parent', 'props', 'id', 'dom', 'effects'];
                if (internalFields.includes(prop)) return;

                let value = data[prop];
                if (value === undefined || value === null) return;

                // --- ФИЛЬТР ДЛЯ SCREEN GUI ---
                // Убираем свойства, которые есть в вебе, но нет у ScreenGui в Roblox
                if (id === 'screen-gui') {
                    const invalidForRoblox = ['BackgroundColor3', 'BackgroundTransparency', 'ClipsDescendants', 'Size', 'Position', 'Image'];
                    if (invalidForRoblox.includes(prop)) return;
                }

                // --- ЛОГИКА КОНВЕРТАЦИИ ТИПОВ ---
                // Color3
                if (prop.includes('Color3') && typeof value === 'string' && value.startsWith('#')) {
                    const r = parseInt(value.slice(1, 3), 16);
                    const g = parseInt(value.slice(3, 5), 16);
                    const b = parseInt(value.slice(5, 7), 16);
                    code += `${varName}.${prop} = Color3.fromRGB(${r}, ${g}, ${b})\n`;
                }
                // UDim2 (Size/Position)
                else if ((prop === 'Size' || prop === 'Position') && typeof value === 'object' && value.X !== undefined) {
                    code += `${varName}.${prop} = UDim2.new(0, ${value.X || 0}, 0, ${value.Y || 0})\n`;
                }
                // UDim2 из строки (например, CanvasSize)
                else if (typeof value === 'string' && value.includes(',')) {
                    const parts = value.split(',').map(v => Number(v.trim()));
                    if (parts.length === 4) code += `${varName}.${prop} = UDim2.new(${parts.join(', ')})\n`;
                    else code += `${varName}.${prop} = "${value}"\n`;
                }
                // Numbers / Booleans (IgnoreGuiInset, Enabled и т.д.)
                else if (typeof value === 'number' || typeof value === 'boolean') {
                    code += `${varName}.${prop} = ${value}\n`;
                }
                // Обычные строки (Text, Font)
                else if (typeof value === 'string') {
                    code += `${varName}.${prop} = "${value}"\n`;
                }
            });

            // 5. Установка родителя (пропускаем для ScreenGui, т.к. он уже в PlayerGui)
            if (obj.parent && id !== 'screen-gui') {
                const pVar = varMap[obj.parent] || rootSafeName;
                code += `${varName}.Parent = ${pVar}\n`;
            }

            // 6. Эффекты (UICorner и прочее)
            if (obj.effects && obj.effects.length > 0) {
                obj.effects.forEach(effect => {
                    const effectObj = App.objects[effect.id];
                    if (!effectObj) return;
                    
                    const effectVarName = `${varName}_${effectObj.type}`;
                    code += `\nlocal ${effectVarName} = Instance.new("${effectObj.type}")\n`;
                    code += `${effectVarName}.Name = "${effectObj.name}"\n`;
                    
                    const eProps = effectObj.props || {};
                    Object.keys(eProps).forEach(eProp => {
                        let eVal = eProps[eProp];
                        if (eProp === 'CornerRadius') code += `${effectVarName}.${eProp} = UDim.new(0, ${eVal})\n`;
                        else if (typeof eVal === 'number' || typeof eVal === 'boolean') code += `${effectVarName}.${eProp} = ${eVal}\n`;
                        else if (typeof eVal === 'string') code += `${effectVarName}.${eProp} = "${eVal}"\n`;
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